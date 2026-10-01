#!/usr/bin/env python3
"""Builds the app's initial catalogue from the hospital's own spreadsheets.

    python3 tools/import_hospital_data.py \
        --doctors  "path/to/مواعيد العيادات.xlsx" \
        --lab      "path/to/قائمة أسعار فحوص المعمل.xls" \
        --out      app/assets/seed/hospital_data.json \
        --report   tools/import_report.txt

The doctors sheet is free-form: a clinic heading, then each doctor's name with
their title on the next row, and their timetable written as Arabic prose that
can run over several rows ("الاحد والثلاثاء والخميس" / "4 مساءً"). This script
turns that prose into weekday shifts, and keeps the original wording on every
doctor so the patient always sees exactly what the hospital published.

Anything that cannot be booked online is still imported — it just gets no
shifts, so the app shows the timetable and a call button instead of slots:
  * "(حالاته فقط)"           the doctor only sees their own patients
  * "يتم التحديد بموعد مسبق"  by prior arrangement
  * "استدعاء"                 on call
  * a day with no hour       e.g. "الاربعاء مساء"

The lab offers come from the hospital's printed flyers, which are images, so
they are transcribed by hand in LAB_PACKAGES below.

Requires: pip install openpyxl xlrd
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass, field

import openpyxl
import xlrd

# ----------------------------------------------------------------- normalise

_DIACRITICS = re.compile(r'[ً-ْٰـ]')  # tashkeel + tatweel
_EASTERN = str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789')


def norm(text: str) -> str:
    """Spelling-insensitive form, for matching only — never displayed."""
    t = _DIACRITICS.sub('', text or '').translate(_EASTERN)
    t = re.sub('[أإآ]', 'ا', t)
    t = t.replace('ى', 'ي').replace('ة', 'ه')
    return re.sub(r'\s+', ' ', t).strip()


def tidy(text: str) -> str:
    """Display form: collapse whitespace, drop bullets, keep the spelling."""
    t = (text or '').replace('·', ' ').replace(' ', ' ')
    return re.sub(r'\s+', ' ', t).strip()


# ----------------------------------------------------------------- weekdays

# ISO weekday numbers, as Dart's DateTime.weekday uses: Monday 1 … Sunday 7.
SAT, SUN, MON, TUE, WED, THU, FRI = 6, 7, 1, 2, 3, 4, 5
HOSPITAL_WEEK = [SAT, SUN, MON, TUE, WED, THU]

_DAY_WORDS = [
    ('السبت', SAT), ('سبت', SAT),
    ('الاحد', SUN), ('احد', SUN),
    ('الاثنين', MON), ('الاتنين', MON), ('اثنين', MON),
    ('الثلاثاء', TUE), ('ثلاثاء', TUE),
    ('الاربعاء', WED), ('اربعاء', WED),
    ('الخميس', THU), ('خميس', THU),
    ('الجمعه', FRI), ('جمعه', FRI),
]
_DAY_RE = '|'.join(re.escape(w) for w, _ in _DAY_WORDS)
_DAY_OF = dict(_DAY_WORDS)

AR_DAY = {SAT: 'السبت', SUN: 'الأحد', MON: 'الإثنين', TUE: 'الثلاثاء',
          WED: 'الأربعاء', THU: 'الخميس', FRI: 'الجمعة'}

# ------------------------------------------------------------------- times

_NUM = r'\d{1,2}(?:\.\d{1,2}|:\d{2}(?!\d))?'
_PERIOD = r'(?:صباحا|صباح|مساءا|مساء|ظهرا|ظهر|عصرا|عصر|ص|م|ظ|ع)'
_SEP = r'(?:الي|الى|ل|-|:)'

_TOKEN = re.compile(
    rf'(?P<span>من\s*(?P<d1>{_DAY_RE})\s*(?:الي|الى|-)\s*(?P<d2>{_DAY_RE}))'
    rf'|(?P<daily>يوميا)'
    rf'|(?P<day>{_DAY_RE})'
    rf'|(?P<time>(?:من\s*)?(?:الساعه\s*)?(?P<a>{_NUM})\s*(?P<pa>{_PERIOD})?'
    rf'(?:\s*{_SEP}\s*(?P<b>{_NUM})\s*(?P<pb>{_PERIOD})?)?)'
)


def _minutes(num: str) -> tuple[int, int]:
    if ':' in num:
        h, m = num.split(':')
    elif '.' in num:
        h, m = num.split('.')
        m = m.ljust(2, '0')
    else:
        h, m = num, '0'
    return int(h), int(m)


def _to_24h(num: str, period: str | None) -> int:
    """Minutes from midnight. Egyptian clinic usage: ظهرا covers 11 to 3."""
    h, m = _minutes(num)
    p = period or ''
    if p.startswith(('م', 'ع')):            # مساء / م / عصر / ع
        if h < 12:
            h += 12
    elif p.startswith('ظ'):                 # ظهرا / ظ
        if h <= 6:
            h += 12
    elif p.startswith('ص'):                 # صباحا / ص
        pass
    else:                                   # no period written at all
        if 1 <= h <= 7:
            h += 12
    return h * 60 + m


DEFAULT_SESSION = 120   # minutes, where only a start time is published
SLOT = 15               # minutes per patient


@dataclass
class Shift:
    weekday: int
    starts: int
    ends: int

    @property
    def cap(self) -> int:
        return max(1, (self.ends - self.starts) // SLOT)


def parse_timetable(lines: list[str]) -> tuple[dict[int, Shift], list[str]]:
    """Returns {weekday: Shift} and a list of problems for the report."""
    shifts: dict[int, Shift] = {}
    problems: list[str] = []
    pending: list[int] = []

    for raw in lines:
        line = norm(raw).replace('/', ' ')
        own_cases_only = 'حالاته' in line
        produced: list[int] = []
        last_group: list[int] = []

        for m in _TOKEN.finditer(line):
            if m.group('span'):
                a, b = _DAY_OF[m.group('d1')], _DAY_OF[m.group('d2')]
                week = HOSPITAL_WEEK + [FRI]
                i, j = week.index(a), week.index(b)
                pending += week[i:j + 1]
            elif m.group('daily'):
                pending += HOSPITAL_WEEK
            elif m.group('day'):
                pending.append(_DAY_OF[m.group('day')])
            elif m.group('time'):
                start = _to_24h(m.group('a'), m.group('pa') or m.group('pb'))
                if m.group('b'):
                    end = _to_24h(m.group('b'), m.group('pb') or m.group('pa'))
                    # A start with its own period ("9 صباحا : 12 مساء") is
                    # taken as written; otherwise the shared period is
                    # assumed and the pair is ordered ("8:7 مساء" = 7 to 8,
                    # the way Arabic is read right to left).
                    if start > end and not m.group('pa'):
                        start, end = end, start
                    if start >= end:
                        problems.append(f'وقت غير مفهوم: {raw}')
                        continue
                else:
                    end = min(start + DEFAULT_SESSION, 24 * 60)
                days = pending or []
                if not days:
                    # A second hour on the same day ("12 ظهرا و 10 مساء").
                    # The app holds one window per weekday; the note keeps
                    # the rest.
                    if last_group:
                        problems.append(
                            f'جلسة ثانية في نفس اليوم (محفوظة في النص فقط): {raw}')
                    continue
                for d in days:
                    produced.append(d)
                    if own_cases_only:
                        continue
                    if d in shifts:
                        if (shifts[d].starts, shifts[d].ends) != (start, end):
                            problems.append(
                                f'{AR_DAY[d]}: أكثر من ميعاد، تم اعتماد الأول')
                        continue
                    shifts[d] = Shift(d, start, end)
                last_group, pending = days, []

        if own_cases_only and produced:
            problems.append(f'حالاته فقط (غير متاح للحجز): {raw}')
        if own_cases_only:
            pending = []

    if pending:
        problems.append('أيام بدون ساعة: '
                        + '، '.join(AR_DAY[d] for d in dict.fromkeys(pending)))
    return shifts, problems


# ------------------------------------------------------------------ doctors

_TITLE_WORDS = ('استشاري', 'استشارى', 'اخصائي', 'أخصائي', 'استاذ دكتور',
                'أستاذ دكتور', 'خارج التعاقد', 'داخل التعاقد', 'ايكو فقط',
                'كشوفات')


def _is_doctor_name(cell: str) -> bool:
    c = norm(cell).lstrip('· ').strip()
    return bool(re.match(r'^(ا\.?د\s*/|د\s*/|دكتور\s*/)', c))


def _is_clinic_heading(cell: str, timetable: str) -> bool:
    return norm(cell).startswith('عياد') and not timetable


def _title_and_specialty(text: str) -> tuple[str | None, str | None, int]:
    """'(استشاري امراض الباطنة والقلب)' -> ('استشاري', 'امراض الباطنة والقلب', 3)."""
    t = tidy(text).strip('() ')
    n = norm(t)
    if 'استاذ دكتور' in n:
        title, rank = 'أستاذ دكتور', 4
    elif 'استشار' in n:
        title, rank = 'استشاري', 3
    elif 'اخصائ' in n:
        title, rank = 'أخصائي', 2
    else:
        return None, None, 0
    rest = re.sub(r'^\s*(أ?استاذ دكتور|استشار[يى]|[أا]خصائي)(\s+ا(?=\s|$))?\s*', '', t).strip(' ()')
    return title, (rest or None), rank


@dataclass
class DoctorEntry:
    clinic: str
    name: str
    title_lines: list[str] = field(default_factory=list)
    timetable: list[str] = field(default_factory=list)
    flags: list[str] = field(default_factory=list)


def _clean_name(raw: str) -> tuple[str, list[str]]:
    """Display name without the parenthesised extras, plus the extras."""
    t = tidy(raw)
    extras = re.findall(r'\(([^)]*)\)', t)
    name = re.sub(r'\([^)]*\)', '', t)
    # Anything after the name that is not in brackets ("امراض قلب فقط").
    m = re.search(r'\s+(اطفال|امراض|كشف|جهاز|حالات)(?=\s|$)', name)
    if m and any(k in name[m.start():] for k in ('فقط', 'سونار', 'كشف')):
        extras.append(name[m.start():].strip())
        name = name[:m.start()]
    name = re.sub(r'^(أ\.?د|ا\.?د)\s*/\s*', 'أ.د/ ', name.strip())
    name = re.sub(r'^دكتور\s*/\s*', 'د/ ', name)
    name = re.sub(r'^د\s*/\s*', 'د/ ', name)
    return tidy(name), [tidy(e) for e in extras if tidy(e)]


def doctor_key(display_name: str) -> str:
    n = norm(display_name)
    n = re.sub(r'^(ا\.د|د)/\s*', '', n)
    return n.replace(' ', '')


def read_doctor_sheet(path: str):
    ws = openpyxl.load_workbook(path, data_only=True).worksheets[0]
    clinics: list[dict] = []
    current_clinic: dict | None = None
    current: DoctorEntry | None = None
    section_flags: list[str] = []

    def close():
        nonlocal current
        if current and current_clinic is not None:
            current_clinic['entries'].append(current)
        current = None

    for row in ws.iter_rows(values_only=True):
        name_cell = tidy(str(row[2])) if len(row) > 2 and row[2] is not None else ''
        time_cell = tidy(str(row[3])) if len(row) > 3 and row[3] is not None else ''
        if not name_cell and not time_cell:
            continue
        if name_cell == 'اسم الطبيب':
            continue

        if name_cell and _is_clinic_heading(name_cell, time_cell):
            close()
            heading = name_cell
            notes = re.findall(r'\(([^)]*)\)', heading)
            keep_in_name = [n for n in notes if 'مركز' in n or 'اطفال' in norm(n)]
            for n in notes:
                if n not in keep_in_name:
                    heading = heading.replace(f'({n})', '')
            heading = re.sub(r'\(\s*([^)]*?)\s*\)', r'(\1)', tidy(heading))
            heading = re.sub(r'^عياده', 'عيادة', heading)
            heading = re.sub(r'^عيادة(?=\S)', 'عيادة ', heading)
            current_clinic = {
                'name': tidy(heading),
                'note': '، '.join(tidy(n) for n in notes if n not in keep_in_name) or None,
                'entries': [],
            }
            clinics.append(current_clinic)
            section_flags = []
            continue

        if name_cell and _is_doctor_name(name_cell):
            close()
            name, extras = _clean_name(name_cell)
            current = DoctorEntry(clinic=current_clinic['name'], name=name)
            current.flags += section_flags
            for e in extras:
                if _title_and_specialty(e)[0]:
                    current.title_lines.append(e)
                else:
                    current.flags.append(e)
            if time_cell:
                current.timetable.append(time_cell)
            continue

        if name_cell and current is None and 'خارج التعاقد' in name_cell:
            section_flags = ['خارج التعاقد']
            continue

        if name_cell and norm(name_cell) == norm('خارج التعاقد') and current is not None:
            # A standalone divider between doctors: everyone after it.
            close()
            section_flags = ['خارج التعاقد']
            if time_cell:
                pass
            continue

        if current is None:
            continue
        if name_cell:
            if _title_and_specialty(name_cell)[0] or any(w in name_cell for w in _TITLE_WORDS):
                current.title_lines.append(name_cell)
            else:
                current.flags.append(name_cell.strip('() '))
        if time_cell:
            current.timetable.append(time_cell)

    close()
    return clinics


# ----------------------------------------------------------------------- lab

LAB_CATEGORY_AR = {
    'Drugs': 'مستوى الأدوية',
    'ادوية': 'مستوى الأدوية',
    'Cardiac Enzymes': 'إنزيمات القلب',
    'Chemistry': 'الكيمياء',
    'Electrolytes': 'الأملاح والمعادن',
    'Coagulation': 'تجلط الدم',
    'fertility Hormones': 'هرمونات الخصوبة',
    'electrophoresis': 'الفصل الكهربائي',
    'Haematology': 'أمراض الدم',
    'Hormones': 'الهرمونات',
    'Immunology': 'المناعة',
    'Immnulogy': 'المناعة',
    'lab test': 'تحاليل عامة',
    'Microbiology': 'الميكروبيولوجي',
    'parasitology': 'الطفيليات',
    'PCR': 'PCR',
    'Tumer Marker': 'دلالات الأورام',
    'Virology': 'الفيروسات',
    'Semen Analysis': 'تحليل السائل المنوي',
    'بائولوجى': 'الباثولوجي',
    'باثولوجى': 'الباثولوجي',
    'Specific Panels': 'باقات متخصصة',
    'ELISA': 'ELISA',
}
LAB_CATEGORY_EN = {
    'مستوى الأدوية': 'Drug levels', 'إنزيمات القلب': 'Cardiac enzymes',
    'الكيمياء': 'Chemistry', 'الأملاح والمعادن': 'Electrolytes',
    'تجلط الدم': 'Coagulation', 'هرمونات الخصوبة': 'Fertility hormones',
    'الفصل الكهربائي': 'Electrophoresis', 'أمراض الدم': 'Haematology',
    'الهرمونات': 'Hormones', 'المناعة': 'Immunology',
    'تحاليل عامة': 'General tests', 'الميكروبيولوجي': 'Microbiology',
    'الطفيليات': 'Parasitology', 'PCR': 'PCR', 'دلالات الأورام': 'Tumour markers',
    'الفيروسات': 'Virology', 'تحليل السائل المنوي': 'Semen analysis',
    'الباثولوجي': 'Pathology', 'باقات متخصصة': 'Specialised panels',
    'ELISA': 'ELISA',
}


def read_lab_sheet(path: str) -> list[dict]:
    sheet = xlrd.open_workbook(path, logfile=open('/dev/null', 'w')).sheets()[0]
    tests, category, seen = [], None, set()
    for r in range(sheet.nrows):
        row = [sheet.cell_value(r, c) for c in range(sheet.ncols)]
        cells = [str(v).strip() for v in row]
        if not any(cells) or cells[0] == 'السعر':
            continue
        price = row[0]
        name = tidy(cells[4] or cells[1])
        if isinstance(price, float) and name:
            if category is None:
                continue
            code = cells[5].replace('.0', '') if cells[5] else ''
            key = (norm(name).lower(), int(price))
            if key in seen:                     # listed twice in the sheet
                continue
            seen.add(key)
            ar = LAB_CATEGORY_AR.get(category, category)
            tests.append({
                'id': f'lab-{len(tests) + 1:03d}',
                'code': code,
                'name': {'ar': name, 'en': name},
                'category': {'ar': ar, 'en': LAB_CATEGORY_EN.get(ar, ar)},
                'price': int(round(price)),
            })
        elif cells[0] and not any(cells[1:]) and r > 4:
            category = cells[0]
    return tests


# The four flyers "عروض التحاليل بمعمل دار الأمومة", transcribed.
LAB_PACKAGES = [
    ('تحاليل صحة المرأة', "Women's health", 'صيام 8 - 10 ساعات',
     'CBC - VIT D - HOMA IR - FERRITIN - TSH - Total testosterone - Free testosterone - ZINC', 1790, 2100),
    ('تحاليل وظائف الكلى', 'Kidney function', 'ثاني عينة بول صباحي',
     'Urine analysis - Uric acid - Albumin/Creat ratio - Urea - Creatinine', 300, 350),
    ('تحاليل ما قبل العمليات (POP)', 'Pre-operative profile', None,
     'CBC - Urea - Creatinine - SGPT - SGOT - PT - PTT - INR - Bleeding & clotting time - HBsAg - HCV Ab - HIV - TSH - HbA1c', 1260, 1530),
    ('تحاليل الفحوص الأساسية', 'Basic check-up', 'صيام 10 ساعات',
     'FBS - Cholesterol - TGs - HbA1c - ALT - Creat - CBC - TSH', 570, 700),
    ('تحاليل الخصوبة ودلالات الأورام للسيدات', "Women's fertility & tumour markers", None,
     'E2 - PRL - AMH - TSH - FSH - LH - CA 15.3 - CA 125 - CEA - AFP', 2150, 2440),
    ('تحاليل تنظيم الوزن والعناية بالشعر', 'Weight management & hair care', 'صيام 10 ساعات',
     'CBC - VIT D - TSH - HOMA IR - Ferritin - Lipid profile - Zinc', 1400, 1600),
    ('تحاليل صحة الطفل — شاملة', "Child health — full", None,
     'CBC - CRP - RBS - Urine analysis - Stool analysis - Calcium - Ferritin', 535, 630),
    ('تحاليل صحة الطفل — متوسطة', "Child health — standard", None,
     'CBC - CRP - RBS - Urine analysis - Stool analysis', 290, 340),
    ('تحاليل صحة الطفل — أساسية', "Child health — basic", None,
     'CBC - CRP - RBS', 245, 275),
    ('تحاليل فحص الغدة الدرقية', 'Thyroid check', None,
     'TSH - Free T3 - Free T4', 345, 400),
    ('تحاليل الخصوبة للرجال', "Men's fertility", None,
     'CASA - FSH - LH - PRL - Free testosterone - Total testosterone', 1200, 1420),
    ('تحاليل صحة الرجال ودلالات الأورام', "Men's health & tumour markers", 'صيام 12 ساعة',
     'CBC - PSA total - PSA free - CEA - AFP - CA19.9 - ALT - AST - Lipid profile - Urea - Creat - HbA1c', 1420, 1660),
    ('تحاليل حقن بديل التكميم', 'Gastric-sleeve alternative injection', None,
     'CBC - Urea - Creatinine - SGPT - SGOT - Lipid profile - Ferritin - Amylase - Lipase - TSH - HbA1c - Calcitonin - Vit D', 2500, 3050),
    ('تحاليل د/ محمد مختار', 'Dr Mohamed Mokhtar panel', None,
     'CBC - Urea - Creatinine - SGPT - SGOT - PT - RBS - TSH - T3 - T4 - HbA1c', 850, 1020),
]


def lab_packages() -> list[dict]:
    out = []
    for i, (ar, en, prep, tests, price, before) in enumerate(LAB_PACKAGES, 1):
        out.append({
            'id': f'pkg-{i:02d}',
            'name': {'ar': ar, 'en': en},
            'tests': [t.strip() for t in tests.split(' - ')],
            'price': price,
            'priceBefore': before,
            'preparation': {'ar': prep} if prep else None,
        })
    return out


# ------------------------------------------------------------------- assemble

def build(doctors_path: str, lab_path: str):
    sheet = read_doctor_sheet(doctors_path)
    report: list[str] = []

    doctors: dict[str, dict] = {}
    clinics: list[dict] = []
    for ci, clinic in enumerate(sheet, 1):
        clinic_id = f'clinic-{ci:02d}'
        specialty = re.sub(r'^عياد(?:ة|ه|ات)\s*', '', clinic['name'])
        doctor_ids: list[str] = []
        report.append(f'\n=== {clinic["name"]}'
                      + (f'  [{clinic["note"]}]' if clinic['note'] else ''))

        for entry in clinic['entries']:
            key = doctor_key(entry.name)
            title, detail, rank = None, None, 0
            for line in entry.title_lines:
                t, d, r = _title_and_specialty(line)
                if t and not title:
                    title, detail, rank = t, d, r
                elif not t:
                    entry.flags.append(line.strip('() '))
            if entry.name.startswith('أ.د'):
                title, rank = 'أستاذ دكتور', 4
            if not title:
                clinic_n = norm(clinic['name'])
                if 'الاستشاري' in clinic_n:
                    title, rank = 'استشاري', 3
                elif 'الاخصائي' in clinic_n:
                    title, rank = 'أخصائي', 2

            name_flags = ' '.join(norm(f) for f in entry.flags)
            no_online = ('حالاته' in name_flags
                         or any(w in norm(' '.join(entry.timetable))
                                for w in ('يتم تحديد', 'يتم التحديد', 'استدعاء')))
            shifts, problems = ({}, []) if no_online else parse_timetable(entry.timetable)
            if no_online:
                problems = ['غير متاح للحجز أونلاين — يظهر الميعاد ورقم الحجز']

            note_lines = list(entry.timetable)
            flags = [f for f in entry.flags if f]
            if flags:
                note_lines.append(' — '.join(dict.fromkeys(flags)))
            note = '\n'.join(note_lines) or None

            if key in doctors:
                doc = doctors[key]
                if not doc['title']['ar'] and title:
                    doc['title'] = {'ar': title}
                    doc['seniority'] = rank or doc['seniority']
                for wd, sh in shifts.items():
                    if wd not in {s['weekday'] for s in doc['shifts']}:
                        doc['shifts'].append(_shift_json(sh))
                    elif not any(s['weekday'] == wd and s['startsAt'] == sh.starts
                                 for s in doc['shifts']):
                        problems.append(f'{AR_DAY[wd]}: ميعاد مختلف عن عيادة أخرى، تم اعتماد الأول')
                if note and note not in (doc['scheduleNote'] or ''):
                    doc['scheduleNote'] = ((doc['scheduleNote'] + '\n') if doc['scheduleNote'] else '') \
                        + f'{clinic["name"]}: ' + note.replace('\n', ' · ')
            else:
                doc = {
                    'id': f'doc-{len(doctors) + 1:03d}',
                    'name': {'ar': entry.name},
                    'title': {'ar': title or ''},
                    'specialty': {'ar': detail or specialty},
                    'seniority': rank or 2,
                    'scheduleNote': note,
                    'shifts': [_shift_json(sh) for sh in shifts.values()],
                }
                doctors[key] = doc
            doctor_ids.append(doc['id'])

            shown = ', '.join(f'{AR_DAY[s.weekday]} {_hm(s.starts)}-{_hm(s.ends)}'
                              for s in sorted(shifts.values(), key=lambda s: HOSPITAL_WEEK.index(s.weekday) if s.weekday in HOSPITAL_WEEK else 9))
            report.append(f'  {entry.name}  |  {title or "?"}{" · " + detail if detail else ""}')
            report.append(f'      المصدر: {" / ".join(entry.timetable) or "—"}')
            report.append(f'      الحجز: {shown or "لا يوجد"}')
            for p in problems:
                report.append(f'      ⚠ {p}')

        days = sorted({s['weekday'] for d in doctor_ids
                       for doc in doctors.values() if doc['id'] == d
                       for s in doc['shifts']})
        clinics.append({
            'id': clinic_id,
            'name': {'ar': clinic['name']},
            'note': clinic['note'],
            'consultationFee': 0,
            'followUpFee': 0,
            'doctorIds': list(dict.fromkeys(doctor_ids)),
            'workingDays': days,
            'slotMinutes': SLOT,
        })

    for doc in doctors.values():
        doc['shifts'].sort(key=lambda s: s['weekday'])

    lab = read_lab_sheet(lab_path)
    data = {
        'schema': 1,
        'clinics': clinics,
        'doctors': list(doctors.values()),
        'labTests': lab,
        'labPackages': lab_packages(),
    }

    bookable = sum(1 for d in doctors.values() if d['shifts'])
    summary = (f'عيادات: {len(clinics)} · أطباء: {len(doctors)} '
               f'(متاح حجزهم أونلاين: {bookable}) · تحاليل: {len(lab)} · '
               f'عروض معمل: {len(LAB_PACKAGES)}')
    return data, [summary] + report


def _shift_json(sh: Shift) -> dict:
    return {'weekday': sh.weekday, 'startsAt': sh.starts, 'endsAt': sh.ends,
            'maxPatients': sh.cap}


def _hm(m: int) -> str:
    return f'{m // 60:02d}:{m % 60:02d}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--doctors', required=True)
    ap.add_argument('--lab', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--report')
    args = ap.parse_args()

    data, report = build(args.doctors, args.lab)
    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    if args.report:
        with open(args.report, 'w', encoding='utf-8') as f:
            f.write('\n'.join(report) + '\n')
    print(report[0])


if __name__ == '__main__':
    main()
