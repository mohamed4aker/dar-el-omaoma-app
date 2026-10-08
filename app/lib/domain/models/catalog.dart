import 'package:flutter/widgets.dart' show Color;

import 'enums.dart';

/// A doctor's working window on one weekday, as minutes from midnight.
///
/// This is what actually generates a clinic's bookable slots: the clinic says
/// which days it opens, the doctor says which hours they are in it, and
/// [maxPatients] caps how many people can be booked into that window.
class DoctorShift {
  const DoctorShift({
    required this.weekday,
    required this.startsAt,
    required this.endsAt,
    this.maxPatients = 0,
  });

  /// ISO weekday: 1 = Monday … 7 = Sunday.
  final int weekday;
  final int startsAt;
  final int endsAt;

  /// 0 means "no cap" — bounded only by the length of the window.
  final int maxPatients;

  Duration get length => Duration(minutes: endsAt - startsAt);

  bool get isValid => endsAt > startsAt;

  /// Minutes each patient gets, once the window is divided by the cap.
  int slotMinutes(int fallback) {
    if (maxPatients <= 0) return fallback;
    final each = (endsAt - startsAt) ~/ maxPatients;
    return each < 5 ? 5 : each;
  }
}

/// A bilingual label. Arabic is authoritative; English falls back to Arabic
/// when a translation has not been supplied (PROMPT.md section 12.1).
class Label {
  const Label(this.ar, [String? en]) : _en = en;
  final String ar;
  final String? _en;
  String get en => _en ?? ar;
  String call(String localeCode) => localeCode == 'en' ? en : ar;
}

/// Operation classification — صغرى / متوسطة / كبرى / ذات مهارة.
///
/// This is **data owned by the administrator, not an enum** (PROMPT.md
/// section 6.13.2). New classifications, renames, recolours and deactivations
/// must be possible without a code change or an app release, so the app must
/// never switch on a hard-coded classification code.
class OperationClassification {
  const OperationClassification({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.colour,
    required this.defaultDuration,
    required this.defaultTurnover,
    required this.priceMin,
    required this.priceMax,
    required this.requiredSeniority,
    required this.defaultAnaesthesia,
    required this.defaultBloodUnits,
    this.theatreFee = 0,
    this.overtimeFee = 0,
    this.isActive = true,
  });

  final String id;
  final String code;
  final Label name;
  final int sortOrder;
  final Color colour;
  final Duration defaultDuration;
  final Duration defaultTurnover;
  final int priceMin;
  final int priceMax;

  /// Higher is more senior. Compared against [Doctor.seniority].
  final int requiredSeniority;
  final Label defaultAnaesthesia;
  final int defaultBloodUnits;

  /// The hospital's operating-room charge for this class, and the charge for
  /// each hour beyond it ("خدمات العمليات").
  final int theatreFee;
  final int overtimeFee;
  final bool isActive;
}

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.seniority,
    this.centreId,
    this.languages = const ['ar'],
    this.shifts = const [],
    this.scheduleNote,
  });

  final String id;
  final Label name;
  final Label title;
  final Label specialty;
  final int seniority;
  final String? centreId;
  final List<String> languages;

  /// The timetable in the hospital's own words ("السبت والثلاثاء 6 مساء").
  ///
  /// Always shown to patients beside the bookable slots, because it carries
  /// what slots cannot: "حالاته فقط", "بموعد مسبق", "كشف بدون سونار".
  final String? scheduleNote;

  /// Online booking needs at least one configured working window. A doctor
  /// without one (by appointment, own patients only, on call) is listed with
  /// their timetable and a call button instead.
  bool get isBookableOnline => shifts.any((s) => s.isValid);

  /// Working windows, set by the administrator (one per weekday at most).
  final List<DoctorShift> shifts;

  DoctorShift? shiftOn(int weekday) {
    for (final shift in shifts) {
      if (shift.weekday == weekday) return shift;
    }
    return null;
  }

  bool worksOn(int weekday) => shiftOn(weekday) != null;

  /// Total cases this doctor accepts across the week. 0 where any shift is
  /// uncapped, since the week is then not meaningfully bounded.
  int get weeklyCapacity {
    var total = 0;
    for (final shift in shifts) {
      if (shift.maxPatients <= 0) return 0;
      total += shift.maxPatients;
    }
    return total;
  }
}

class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    required this.consultationFee,
    required this.followUpFee,
    required this.doctorIds,
    required this.workingDays,
    this.centreId,
    this.icon = 0xe3f3,
    this.paymentPolicy = PaymentPolicy.payAtReception,
    this.depositAmount = 0,
    this.slotMinutes = 20,
    this.note,
  });

  final String id;
  final Label name;

  /// Shown under the clinic name — e.g. "خارج التعاقد" (not covered by the
  /// hospital's insurance contracts).
  final String? note;
  final int consultationFee;
  final int followUpFee;
  final List<String> doctorIds;

  /// ISO weekday numbers (1 = Monday … 7 = Sunday).
  final List<int> workingDays;
  final String? centreId;
  final int icon;

  /// Booking is never blocked by payment. This only decides whether the app
  /// offers to take money, and whether a deposit holds the slot.
  final PaymentPolicy paymentPolicy;

  /// Amount held to secure a slot when [paymentPolicy] requires a deposit.
  final int depositAmount;

  /// Fallback appointment length, used where the doctor's shift sets no cap.
  final int slotMinutes;
}

class OperatingTheatre {
  const OperatingTheatre({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.opensAt,
    required this.closesAt,
    this.defaultTurnover = const Duration(minutes: 30),
    this.isActive = true,
  });

  final String id;
  final String code;
  final Label name;
  final TheatreType type;

  /// Normal operating hours, as minutes from midnight.
  final int opensAt;
  final int closesAt;
  final Duration defaultTurnover;
  final bool isActive;
}

class Procedure {
  const Procedure({
    required this.id,
    required this.code,
    required this.name,
    required this.classificationId,
    required this.typicalDuration,
    required this.requiredTheatreType,
    required this.price,
    this.centreId,
    this.departmentId,
    this.requiredEquipment = const [],
    this.patientRequestable = true,
    this.followUpIntervalDays = 14,
  });

  final String id;
  final String code;
  final Label name;
  final String classificationId;
  final Duration typicalDuration;
  final TheatreType requiredTheatreType;
  final int price;
  final String? centreId;
  final String? departmentId;
  final List<String> requiredEquipment;

  /// Whether patients may request this procedure from the app (PROMPT.md 6.13.3).
  final bool patientRequestable;
  final int followUpIntervalDays;
}

/// A specialty centre — "programme within a programme" (PROMPT.md section 6.14).
///
/// Deliberately generic: the Surgery Centre is the first instance, not a
/// special case, so the hospital can launch further centres from the admin
/// console with no development work.
class SpecialtyCentre {
  const SpecialtyCentre({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.specialties,
    required this.accent,
    this.isPublished = true,
  });

  final String id;
  final String slug;
  final Label name;
  final Label description;
  final List<Label> specialties;
  final Color accent;
  final bool isPublished;
}

class LabTest {
  const LabTest({
    required this.id,
    required this.name,
    required this.price,
    this.code = '',
    this.category = const Label('تحاليل عامة', 'General tests'),
    this.sample,
    this.turnaround,
    this.preparation,
    this.isActive = true,
  });

  final String id;

  /// The laboratory's own code from its price list.
  final String code;
  final Label name;
  final Label category;
  final int price;
  final Label? sample;
  final Label? turnaround;
  final Label? preparation;
  final bool isActive;
}

/// A priced bundle of tests — the laboratory's printed offers
/// ("عروض التحاليل بمعمل دار الأمومة").
class LabPackage {
  const LabPackage({
    required this.id,
    required this.name,
    required this.tests,
    required this.price,
    this.priceBefore = 0,
    this.preparation,
    this.isActive = true,
  });

  final String id;
  final Label name;

  /// Test names as printed on the offer.
  final List<String> tests;
  final int price;

  /// The undiscounted price; 0 when the package is not on offer.
  final int priceBefore;

  /// "صيام 10 ساعات", "ثاني عينة بول صباحي".
  final Label? preparation;
  final bool isActive;

  int get saving => priceBefore > price ? priceBefore - price : 0;
}

class HomeCareService {
  const HomeCareService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
  });

  final String id;
  final Label name;
  final Label description;
  final int price;
  final Label duration;
}

/// The departments a [PriceSection] can belong to. Strings, not an enum, so a
/// saved catalogue with a department this build does not know still loads.
abstract final class PriceService {
  static const outpatient = 'outpatient';
  static const radiology = 'radiology';
  static const physio = 'physio';
  static const inpatient = 'inpatient';
  static const emergency = 'emergency';
  static const ambulance = 'ambulance';
  static const homecare = 'homecare';
  static const surgery = 'surgery';
}

/// One line of the hospital's price list.
class PriceItem {
  const PriceItem({
    required this.id,
    required this.name,
    required this.price,
    this.code = '',
    this.note,
    this.isActive = true,
  });

  final String id;
  final Label name;
  final int price;

  /// The hospital's own service code.
  final String code;
  final String? note;
  final bool isActive;
}

/// A titled group of [PriceItem]s within one department — "أشعة مقطعية (CT)",
/// "العناية المركزة".
class PriceSection {
  const PriceSection({
    required this.id,
    required this.service,
    required this.title,
    required this.items,
    this.note,
  });

  final String id;
  final String service;
  final Label title;
  final String? note;
  final List<PriceItem> items;

  PriceSection withItems(List<PriceItem> items) => PriceSection(
      id: id, service: service, title: title, note: note, items: items);
}

/// Who operates, which decides what an all-inclusive surgery price covers.
abstract final class SurgeryTier {
  /// The hospital's charges only; the surgeon is paid separately.
  static const hospital = 'hospital';
  static const specialist = 'specialist';
  static const consultant = 'consultant';

  static const all = [hospital, specialist, consultant];
}

/// An all-inclusive operation price ("الصفقات الشاملة"): one price per room
/// type, for each [SurgeryTier] the hospital offers it at.
class SurgeryPackage {
  const SurgeryPackage({
    required this.id,
    required this.specialty,
    required this.category,
    required this.name,
    required this.rooms,
    required this.prices,
    this.classification = '',
    this.note,
    this.isActive = true,
  });

  final String id;
  final Label specialty;
  final Label category;
  final Label name;

  /// Classification name as the hospital writes it (كبرى، مهارة…).
  final String classification;

  /// Room types, in the order of every list in [prices].
  final List<String> rooms;

  /// [SurgeryTier] → price per room; null where the hospital quotes none.
  final Map<String, List<int?>> prices;
  final Label? note;
  final bool isActive;

  bool get hasPrices =>
      prices.values.any((row) => row.any((p) => p != null && p > 0));

  int? priceFor(String tier, int room) {
    final row = prices[tier];
    if (row == null || room < 0 || room >= row.length) return null;
    return row[room];
  }

  /// The cheapest price quoted anywhere in the package.
  int? get from {
    int? best;
    for (final row in prices.values) {
      for (final p in row) {
        if (p != null && p > 0 && (best == null || p < best)) best = p;
      }
    }
    return best;
  }

  SurgeryPackage withPrices(Map<String, List<int?>> prices) => SurgeryPackage(
        id: id,
        specialty: specialty,
        category: category,
        name: name,
        rooms: rooms,
        prices: prices,
        classification: classification,
        note: note,
        isActive: isActive,
      );
}
