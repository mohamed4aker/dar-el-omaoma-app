"""Reads the hospital's master price workbook into the app's catalogue.

The workbook (one sheet per department) is the hospital's internal price
list. What patients may see is taken from it; what they must not — the
surgical team's fee split and the doctors' net shares ("صافي") — is never
read at all.

Sheets and where they go in the app:

  الداخلي            inpatient: rooms, ward services, rounds, ICU, nursery
  خدمات العمليات     theatre classifications, device and gas charges
  العيادات الخارجية  outpatient procedures; physiotherapy, emergency,
                      ambulance and home-care items are split out
  فحوص الاشعه        radiology, by modality
  فحوص المعمل        laboratory tests (replaces the older price list)
  الصفقات الشاملة    surgery packages: price by room and by who operates

Cells the workbook itself gets wrong (#REF!, a stray extra digit, a suite
cheaper than a VIP room) are left out and listed in the report rather than
shown to a patient.
"""

from __future__ import annotations

import re
import statistics

import openpyxl

from import_hospital_data import norm, tidy, LAB_CATEGORY_AR, LAB_CATEGORY_EN

SHEETS = {
    'inpatient': 'الداخلي',
    'theatre': 'خدمات العمليات',
    'outpatient': 'العيادات الخارجية',
    'radiology': 'فحوص الاشعه',
    'lab': 'فحوص المعمل',
    'packages': 'الصفقات الشاملة',
}


def _sheet(wb, key):
    want = norm(SHEETS[key])
    for ws in wb.worksheets:
        if norm(ws.title) == want:
            return ws
    raise KeyError(SHEETS[key])


def _rows(ws):
    for row in ws.iter_rows(values_only=True):
        yield [c for c in row]


def _text(v) -> str:
    return tidy(str(v)) if v is not None else ''


def _num(v):
    """A price, or None for anything that is not one (#REF!, '-', text)."""
    if isinstance(v, bool) or v is None:
        return None
    if isinstance(v, (int, float)):
        return int(round(v)) if v > 0 else None
    s = str(v).strip().replace(',', '')
    try:
        f = float(s)
    except ValueError:
        return None
    return int(round(f)) if f > 0 else None


class Builder:
    def __init__(self):
        self.sections: list[dict] = []
        self.report: list[str] = []
        self._ids = 0

    def item_id(self, prefix):
        self._ids += 1
        return f'{prefix}-{self._ids:04d}'

    def section(self, service, title, items, note=None, sid=None):
        if not items:
            return
        self.sections.append({
            'id': sid or f'sec-{service}-{len(self.sections) + 1:02d}',
            'service': service,
            'title': {'ar': title},
            'note': note,
            'items': items,
        })

    def item(self, name, price, code='', note=None):
        return {'id': self.item_id('itm'), 'name': {'ar': tidy(name)},
                'price': price, 'code': code, 'note': note}


# ---------------------------------------------------------------- inpatient

def read_inpatient(ws, b: Builder):
    rows = list(_rows(ws))
    title, items, note = None, [], None

    def flush():
        nonlocal items, note
        if title:
            b.section('inpatient', title, items, note=note)
        items, note = [], None

    for r in rows:
        cells = [_text(c) for c in r]
        if not any(cells):
            continue
        # Room table: name in C, then lodging, medical care, nursing, total.
        if cells[2] and _num(r[6]) and _num(r[3]) and not cells[0]:
            if title != 'أسعار الإقامة اليومية':
                flush()
                title = 'أسعار الإقامة اليومية'
            items.append(b.item(
                cells[2], _num(r[6]),
                note=f'إقامة {_num(r[3])} + رعاية طبية {_num(r[4])} + تمريض {_num(r[5])} — لليلة'))
            continue
        nums = [_num(c) for c in r]
        texts = [c for c in cells if c and _num(c) is None]
        if texts and not any(nums) and len(texts) == 1:
            t = texts[0]
            if t in ('م', 'الخدمة') or 'نوع الغرفة' in t:
                continue
            if t.startswith('فى حاله') or t.startswith('في حالة'):
                note = t
                continue
            flush()
            title = 'أسعار الإقامة' if 'اسعار الاقامه' in norm(t) else t
            continue
        price = next((n for n in reversed(nums) if n), None)
        if price is None:
            continue
        name_parts = [c for c in cells[1:] if c and _num(c) is None]
        if not name_parts:
            continue
        name = ' — '.join(name_parts) if title == 'مرور الاطباء' else name_parts[0]
        items.append(b.item(name, price))
    flush()


# ------------------------------------------------------------------ theatre

CLASS_NAMES = {
    'بسيطه': 'بسيطة', 'صغري': 'صغرى', 'صغرى': 'صغرى', 'متوسطه': 'متوسطة',
    'متوسطة': 'متوسطة', 'كبري': 'كبرى', 'كبرى': 'كبرى', 'مهاره': 'مهارة',
    'مهارة': 'مهارة', 'ذات طابع خاص': 'ذات طابع خاص', 'متقدمه': 'متقدمة',
    'متقدمة': 'متقدمة',
}
CLASS_COLOURS = [0xFF64748B, 0xFF0E9F6E, 0xFF2563EB, 0xFFD97706, 0xFFC93A72,
                 0xFF7C3AED, 0xFF111827]
CLASS_CODES = ['simple', 'minor', 'intermediate', 'major', 'skilled',
               'special', 'advanced']


def class_name(raw: str) -> str:
    n = norm(raw)
    for k, v in CLASS_NAMES.items():
        if norm(k) == n:
            return v
    return tidy(raw)


def read_theatre(ws, b: Builder):
    rows = list(_rows(ws))
    classes = []
    for r in rows[2:12]:
        name, fee, extra = _text(r[0]), _num(r[1]), _num(r[2])
        if name and fee and extra:
            classes.append((class_name(name), fee, extra))

    title, items = None, []
    in_charges = False
    for r in rows:
        cells = [_text(c) for c in r]
        if not any(cells):
            continue
        b_cell, c_cell = cells[1], cells[2]
        if 'الغازات' in b_cell or 'أجهزه العمليات' in b_cell or 'اجهزه العمليات' in norm(b_cell):
            in_charges = True
            if items:
                b.section('surgery', title, items)
            title = 'رسوم الغازات' if 'الغازات' in b_cell else None
            items = []
            continue
        if not in_charges:
            continue
        if b_cell == 'الخدمة':
            continue
        if b_cell and not c_cell:
            if items:
                b.section('surgery', title, items)
            items = []
            title = f'رسوم أجهزة العمليات — {b_cell}'
            continue
        price = _num(r[2])
        if b_cell and price:
            items.append(b.item(b_cell, price))
    if items:
        b.section('surgery', title, items)
    return classes


# --------------------------------------------------------------- outpatient

# Items that belong to another service as well as (or instead of) their
# outpatient department, by the hospital's own procedure code.
AMBULANCE_CODES = {'149', '151'}
HOME_CARE_CODES = {'32', '728'}


def read_outpatient(ws, b: Builder):
    title, items = None, []
    ambulance, home = [], []

    def flush():
        nonlocal items
        if not title:
            return
        n = norm(title)
        if 'العلاج الطبيعي' in n:
            b.section('physio', 'جلسات العلاج الطبيعي', items)
        elif 'الطوارئ' in n:
            b.section('emergency', 'أسعار خدمات الطوارئ', items)
        else:
            b.section('outpatient', title, items)
        items = []

    for r in _rows(ws):
        cells = [_text(c) for c in r]
        if not any(cells):
            continue
        if cells[0] and not any(cells[1:]):
            if cells[0].startswith('أسعار'):
                continue
            flush()
            title = cells[0]
            continue
        if cells[0] == 'م':
            continue
        name, price = cells[2], _num(r[4])
        if not name or not price:
            continue
        code = cells[1].replace('.0', '')
        it = b.item(name, price, code=code)
        if code in AMBULANCE_CODES:
            ambulance.append(b.item(name, price, code=code))
        if code in HOME_CARE_CODES:
            home.append(b.item(name, price, code=code))
        if code in AMBULANCE_CODES:
            continue          # shown under ambulance, not in the ER list
        items.append(it)
    flush()
    b.section('ambulance', 'أسعار الإسعاف', ambulance)
    b.section('homecare', 'الرعاية المنزلية', home)


# ---------------------------------------------------------------- radiology

MODALITY_TITLES = {
    'سونار': 'أشعة تليفزيونية (سونار ودوبلر)',
    'MRI': 'رنين مغناطيسي (MRI)',
    'X-Ray': 'أشعة عادية (X-Ray)',
    'CT': 'أشعة مقطعية (CT)',
}


def read_radiology(ws, b: Builder):
    title, items = None, []
    for r in _rows(ws):
        cells = [_text(c) for c in r]
        if not any(cells):
            continue
        if cells[0].startswith('متوسط'):
            continue        # the sheet's per-modality summary row
        if 'إجمالي' in ''.join(cells):
            break
        if cells[0] and not any(cells[1:]):
            if 'قائمة' in cells[0]:
                continue
            if title and items:
                b.section('radiology', title, items)
            items = []
            title = next((v for k, v in MODALITY_TITLES.items() if k in cells[0]), cells[0])
            continue
        if cells[0] == 'م':
            continue
        name, price = cells[2], _num(r[3])
        if name and price and title:
            items.append(b.item(name, price, code=cells[1].replace('.0', '')))
    if title and items:
        b.section('radiology', title, items)


# ---------------------------------------------------------------------- lab

def read_lab(ws, old_codes: dict[str, str]):
    tests, category, seen = [], None, set()
    for r in _rows(ws):
        cells = [_text(c) for c in r]
        if not any(cells):
            continue
        if cells[0] and not cells[1] and not cells[2]:
            if 'قائمة' in cells[0]:
                continue
            category = re.sub(r'\s*\(.*\)\s*', '', cells[0]).strip()
            continue
        if cells[0] == 'م' or category is None:
            continue
        name, price = cells[1], _num(r[2])
        if not name or not price:
            continue
        key = (norm(name).lower(), price)
        if key in seen:
            continue
        seen.add(key)
        ar = LAB_CATEGORY_AR.get(category, category)
        tests.append({
            # A fresh id space: bookings made against the older list keep
            # pointing at what they booked.
            'id': f'lt-{len(tests) + 1:03d}',
            'code': old_codes.get(norm(name).lower(), ''),
            'name': {'ar': name, 'en': name},
            'category': {'ar': ar, 'en': LAB_CATEGORY_EN.get(ar, ar)},
            'price': price,
        })
    return tests


# ----------------------------------------------------------------- packages

CASE_TYPES = {
    'خاصه': 'hospital', 'خاصة': 'hospital',
    'اخصائى': 'specialist', 'اخصائي': 'specialist', 'أخصائي': 'specialist',
    'استشاري': 'consultant', 'استشارى': 'consultant',
}
ROOM_NAMES = {'جونيور': 'جناح جونيور', 'ملكي': 'جناح ملكي'}


def _clean_row(values, rooms, label, report):
    """Drops cells the workbook gets wrong; reports each one."""
    nums = [v for v in values if v]
    if len(nums) >= 3:
        med = statistics.median(nums)
        for i, v in enumerate(values):
            if v and (v > med * 3 or v < med / 3):
                report.append(f'  ⚠ {label} — {rooms[i]}: {v} (بعيد جدًا عن باقي الصف، تم استبعاده)')
                values[i] = None
    # A suite is never cheaper than the VIP room in the same row.
    if 'VIP' in rooms:
        vip = values[rooms.index('VIP')]
        for i, room in enumerate(rooms):
            if room.startswith('جناح') and values[i] and vip and values[i] < vip:
                report.append(f'  ⚠ {label} — {room}: {values[i]} أقل من VIP {vip} (تم استبعاده)')
                values[i] = None
    return values


def read_packages(ws, b: Builder):
    packages, extras = [], []
    specialty, category = None, None
    rooms, room_cols, case_col, hospital_only = [], [], None, False
    current = None
    extra_mode = False

    for r in _rows(ws):
        cells = [_text(c) for c in r]
        if not any(cells):
            continue
        joined = ' '.join(cells)
        if 'لائحة الأسعار الشاملة' in joined:
            parts = [p.strip() for p in cells[0].split('—')]
            specialty = parts[1] if len(parts) > 2 else cells[0]
            category, current, extra_mode = None, None, False
            hospital_only = False
            continue
        if cells[1] == 'رسوم اضافية':
            extra_mode = True
            continue
        if extra_mode:
            if cells[1] and _num(r[2]):
                extras.append(b.item(cells[1], _num(r[2])))
            continue
        if cells[0] == 'م':
            case_col = next((i for i, c in enumerate(cells) if c in ('نوع الحالة', 'النوع')), None)
            hospital_only = 'بدون أتعاب' in joined
            continue
        if 'ثلاثي' in cells:
            first = cells.index('ثلاثي')
            room_cols = [i for i, c in enumerate(cells) if c and i >= first]
            rooms = [ROOM_NAMES.get(cells[i].replace('جناح ', ''), cells[i]) for i in room_cols]
            continue
        if cells[0] and not cells[1] and not any(cells[2:]):
            category = cells[0]
            continue
        is_op = cells[1] and _num(r[0]) is not None
        if is_op:
            current = {
                'id': b.item_id('pkg'),
                'specialty': {'ar': specialty},
                'category': {'ar': category or ''},
                'name': {'ar': cells[1]},
                'classification': class_name(cells[2]) if cells[2] else '',
                'rooms': rooms,
                'prices': {},
                'note': ({'ar': 'السعر لا يشمل أتعاب الفريق الجراحي'}
                         if hospital_only else None),
            }
            packages.append(current)
        if current is None:
            continue
        kind_text = cells[case_col] if case_col is not None else ''
        if hospital_only or (is_op and not kind_text):
            kind = 'hospital'   # no case-type column: the hospital's own price
        else:
            kind = CASE_TYPES.get(kind_text)
        if kind is None:
            continue        # "ط/طبيب" — the doctor's own patient; internal
        values = [_num(r[i]) if i < len(r) else None for i in room_cols]
        values = _clean_row(values, rooms, f'{specialty} / {current["name"]["ar"]} / {kind_text or "رسوم المستشفى"}', b.report)
        if any(values):
            current['prices'][kind] = values

    b.section('surgery', 'رسوم إضافية للعمليات', extras)
    return packages


# -------------------------------------------------------------------- main

def build_prices(path: str, old_lab_codes: dict[str, str]):
    wb = openpyxl.load_workbook(path, data_only=True)
    b = Builder()
    read_inpatient(_sheet(wb, 'inpatient'), b)
    classes = read_theatre(_sheet(wb, 'theatre'), b)
    read_outpatient(_sheet(wb, 'outpatient'), b)
    read_radiology(_sheet(wb, 'radiology'), b)
    lab = read_lab(_sheet(wb, 'lab'), old_lab_codes)
    packages = read_packages(_sheet(wb, 'packages'), b)

    classifications = [{
        'id': f'cls-{CLASS_CODES[i] if i < len(CLASS_CODES) else i}',
        'code': CLASS_CODES[i] if i < len(CLASS_CODES) else f'c{i}',
        'name': {'ar': name},
        'sortOrder': i + 1,
        'colour': CLASS_COLOURS[i % len(CLASS_COLOURS)],
        'defaultDuration': [30, 45, 90, 150, 180, 240, 300][min(i, 6)],
        'defaultTurnover': [15, 20, 30, 45, 60, 60, 60][min(i, 6)],
        'priceMin': 0, 'priceMax': 0,
        'requiredSeniority': [1, 1, 2, 3, 3, 4, 4][min(i, 6)],
        'defaultAnaesthesia': {'ar': 'موضعي' if i < 2 else 'كلي'},
        'defaultBloodUnits': [0, 0, 1, 2, 2, 4, 4][min(i, 6)],
        'theatreFee': fee,
        'overtimeFee': extra,
    } for i, (name, fee, extra) in enumerate(classes)]

    for p in packages:
        if not p['prices']:
            b.report.append(f'  • {p["specialty"]["ar"]} / {p["name"]["ar"]}: بدون سعر في الملف — يظهر «اسأل عن السعر»')

    counts = {}
    for s in b.sections:
        counts[s['service']] = counts.get(s['service'], 0) + len(s['items'])
    summary = ('أسعار: ' + ' · '.join(f'{k} {v}' for k, v in counts.items())
               + f' · عمليات {len(packages)} · تصنيفات {len(classifications)} · تحاليل {len(lab)}')
    return {
        'priceSections': b.sections,
        'surgeryPackages': packages,
        'classifications': classifications,
        'labTests': lab,
    }, [summary] + b.report
