import 'package:flutter/painting.dart' show Color;

import '../domain/models/booking.dart';
import '../domain/models/catalog.dart';
import '../domain/models/content.dart';
import '../domain/models/enums.dart';
import '../domain/models/governance.dart';
import '../domain/models/operations.dart';
import '../domain/models/patient.dart';
import '../domain/models/time_range.dart';

/// JSON for every model the app keeps.
///
/// One format serves two purposes: the hospital's catalogue shipped in
/// `assets/seed/hospital_data.json` (built from its own spreadsheets by
/// `tools/import_hospital_data.py`), and everything saved on the device
/// afterwards. Reading is tolerant — a missing optional field takes its
/// default — so older saves keep loading after the app is updated.
abstract final class Codec {
  // ------------------------------------------------------------- primitives

  static Map<String, dynamic> label(Label l) => {'ar': l.ar, 'en': l.en};

  static Label toLabel(Object? json, [String fallback = '']) {
    if (json is Map) {
      final ar = (json['ar'] as String?) ?? fallback;
      final en = json['en'] as String?;
      return Label(ar, (en == null || en.isEmpty) ? null : en);
    }
    if (json is String) return Label(json);
    return Label(fallback);
  }

  static Label? toLabelOrNull(Object? json) =>
      json == null ? null : toLabel(json);

  static String? date(DateTime? d) => d?.toIso8601String();

  static DateTime toDate(Object? s) =>
      s is String ? DateTime.parse(s) : DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime? toDateOrNull(Object? s) =>
      s is String ? DateTime.tryParse(s) : null;

  static T toEnum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  static List<String> toStrings(Object? json) =>
      json is List ? json.map((e) => '$e').toList() : const [];

  static List<int> toInts(Object? json) =>
      json is List ? json.map((e) => (e as num).toInt()).toList() : const [];

  static int toInt(Object? json, [int fallback = 0]) =>
      json is num ? json.toInt() : fallback;

  static List<T> list<T>(Object? json, T Function(Map<String, dynamic>) read) {
    if (json is! List) return [];
    return [
      for (final item in json)
        if (item is Map) read(Map<String, dynamic>.from(item)),
    ];
  }

  // ---------------------------------------------------------------- doctors

  static Map<String, dynamic> shift(DoctorShift s) => {
        'weekday': s.weekday,
        'startsAt': s.startsAt,
        'endsAt': s.endsAt,
        'maxPatients': s.maxPatients,
      };

  static DoctorShift toShift(Map<String, dynamic> j) => DoctorShift(
        weekday: toInt(j['weekday'], 1),
        startsAt: toInt(j['startsAt']),
        endsAt: toInt(j['endsAt']),
        maxPatients: toInt(j['maxPatients']),
      );

  static Map<String, dynamic> doctor(Doctor d) => {
        'id': d.id,
        'name': label(d.name),
        'title': label(d.title),
        'specialty': label(d.specialty),
        'seniority': d.seniority,
        'centreId': d.centreId,
        'scheduleNote': d.scheduleNote,
        'shifts': d.shifts.map(shift).toList(),
      };

  static Doctor toDoctor(Map<String, dynamic> j) => Doctor(
        id: j['id'] as String,
        name: toLabel(j['name']),
        title: toLabel(j['title']),
        specialty: toLabel(j['specialty']),
        seniority: toInt(j['seniority'], 2),
        centreId: j['centreId'] as String?,
        scheduleNote: j['scheduleNote'] as String?,
        shifts: list(j['shifts'], toShift),
      );

  static Map<String, dynamic> clinic(Clinic c) => {
        'id': c.id,
        'name': label(c.name),
        'note': c.note,
        'consultationFee': c.consultationFee,
        'followUpFee': c.followUpFee,
        'doctorIds': c.doctorIds,
        'workingDays': c.workingDays,
        'centreId': c.centreId,
        'paymentPolicy': c.paymentPolicy.name,
        'depositAmount': c.depositAmount,
        'slotMinutes': c.slotMinutes,
      };

  static Clinic toClinic(Map<String, dynamic> j) => Clinic(
        id: j['id'] as String,
        name: toLabel(j['name']),
        note: j['note'] as String?,
        consultationFee: toInt(j['consultationFee']),
        followUpFee: toInt(j['followUpFee']),
        doctorIds: toStrings(j['doctorIds']),
        workingDays: toInts(j['workingDays']),
        centreId: j['centreId'] as String?,
        paymentPolicy: toEnum(PaymentPolicy.values, j['paymentPolicy'],
            PaymentPolicy.payAtReception),
        depositAmount: toInt(j['depositAmount']),
        slotMinutes: toInt(j['slotMinutes'], 15),
      );

  // -------------------------------------------------------------------- lab

  static Map<String, dynamic> labTest(LabTest t) => {
        'id': t.id,
        'code': t.code,
        'name': label(t.name),
        'category': label(t.category),
        'price': t.price,
        'isActive': t.isActive,
      };

  static LabTest toLabTest(Map<String, dynamic> j) => LabTest(
        id: j['id'] as String,
        code: (j['code'] as String?) ?? '',
        name: toLabel(j['name']),
        category: toLabel(j['category'], 'تحاليل عامة'),
        price: toInt(j['price']),
        isActive: (j['isActive'] as bool?) ?? true,
      );

  static Map<String, dynamic> labPackage(LabPackage p) => {
        'id': p.id,
        'name': label(p.name),
        'tests': p.tests,
        'price': p.price,
        'priceBefore': p.priceBefore,
        'preparation': p.preparation == null ? null : label(p.preparation!),
        'isActive': p.isActive,
      };

  static LabPackage toLabPackage(Map<String, dynamic> j) => LabPackage(
        id: j['id'] as String,
        name: toLabel(j['name']),
        tests: toStrings(j['tests']),
        price: toInt(j['price']),
        priceBefore: toInt(j['priceBefore']),
        preparation: toLabelOrNull(j['preparation']),
        isActive: (j['isActive'] as bool?) ?? true,
      );

  // ---------------------------------------------------------------- theatre

  static Map<String, dynamic> classification(OperationClassification c) => {
        'id': c.id,
        'code': c.code,
        'name': label(c.name),
        'sortOrder': c.sortOrder,
        'colour': c.colour.toARGB32(),
        'defaultDuration': c.defaultDuration.inMinutes,
        'defaultTurnover': c.defaultTurnover.inMinutes,
        'priceMin': c.priceMin,
        'priceMax': c.priceMax,
        'requiredSeniority': c.requiredSeniority,
        'defaultAnaesthesia': label(c.defaultAnaesthesia),
        'defaultBloodUnits': c.defaultBloodUnits,
        'isActive': c.isActive,
      };

  static OperationClassification toClassification(Map<String, dynamic> j) =>
      OperationClassification(
        id: j['id'] as String,
        code: (j['code'] as String?) ?? '',
        name: toLabel(j['name']),
        sortOrder: toInt(j['sortOrder']),
        colour: Color(toInt(j['colour'], 0xFF6B7280)),
        defaultDuration: Duration(minutes: toInt(j['defaultDuration'], 60)),
        defaultTurnover: Duration(minutes: toInt(j['defaultTurnover'], 30)),
        priceMin: toInt(j['priceMin']),
        priceMax: toInt(j['priceMax']),
        requiredSeniority: toInt(j['requiredSeniority'], 1),
        defaultAnaesthesia: toLabel(j['defaultAnaesthesia']),
        defaultBloodUnits: toInt(j['defaultBloodUnits']),
        isActive: (j['isActive'] as bool?) ?? true,
      );

  static Map<String, dynamic> theatre(OperatingTheatre t) => {
        'id': t.id,
        'code': t.code,
        'name': label(t.name),
        'type': t.type.name,
        'opensAt': t.opensAt,
        'closesAt': t.closesAt,
        'defaultTurnover': t.defaultTurnover.inMinutes,
        'isActive': t.isActive,
      };

  static OperatingTheatre toTheatre(Map<String, dynamic> j) => OperatingTheatre(
        id: j['id'] as String,
        code: (j['code'] as String?) ?? '',
        name: toLabel(j['name']),
        type: toEnum(TheatreType.values, j['type'], TheatreType.general),
        opensAt: toInt(j['opensAt'], 8 * 60),
        closesAt: toInt(j['closesAt'], 20 * 60),
        defaultTurnover: Duration(minutes: toInt(j['defaultTurnover'], 30)),
        isActive: (j['isActive'] as bool?) ?? true,
      );

  static Map<String, dynamic> procedure(Procedure p) => {
        'id': p.id,
        'code': p.code,
        'name': label(p.name),
        'classificationId': p.classificationId,
        'typicalDuration': p.typicalDuration.inMinutes,
        'requiredTheatreType': p.requiredTheatreType.name,
        'price': p.price,
        'centreId': p.centreId,
        'requiredEquipment': p.requiredEquipment,
        'patientRequestable': p.patientRequestable,
      };

  static Procedure toProcedure(Map<String, dynamic> j) => Procedure(
        id: j['id'] as String,
        code: (j['code'] as String?) ?? '',
        name: toLabel(j['name']),
        classificationId: (j['classificationId'] as String?) ?? '',
        typicalDuration: Duration(minutes: toInt(j['typicalDuration'], 60)),
        requiredTheatreType: toEnum(TheatreType.values,
            j['requiredTheatreType'], TheatreType.general),
        price: toInt(j['price']),
        centreId: j['centreId'] as String?,
        requiredEquipment: toStrings(j['requiredEquipment']),
        patientRequestable: (j['patientRequestable'] as bool?) ?? true,
      );

  static Map<String, dynamic> range(TimeRange r) =>
      {'start': date(r.start), 'end': date(r.end)};

  static TimeRange toRange(Object? j) {
    final m = j is Map ? j : const {};
    final start = toDate(m['start']);
    final end = toDateOrNull(m['end']) ?? start.add(const Duration(minutes: 15));
    return end.isAfter(start)
        ? TimeRange(start, end)
        : TimeRange.fromDuration(start, const Duration(minutes: 15));
  }

  static Map<String, dynamic> surgeryCase(SurgeryCase c) => {
        'id': c.id,
        'patientId': c.patientId,
        'patientDisplayName': c.patientDisplayName,
        'procedureId': c.procedureId,
        'classificationId': c.classificationId,
        'theatreId': c.theatreId,
        'surgeonId': c.surgeonId,
        'range': range(c.range),
        'turnover': c.turnover.inMinutes,
        'origin': c.origin.name,
        'status': c.status.name,
        'centreId': c.centreId,
        'campaignId': c.campaignId,
        'equipment': c.equipment,
        'overrideReason': c.overrideReason,
      };

  static SurgeryCase toSurgeryCase(Map<String, dynamic> j) => SurgeryCase(
        id: j['id'] as String,
        patientId: (j['patientId'] as String?) ?? '',
        patientDisplayName: (j['patientDisplayName'] as String?) ?? '',
        procedureId: (j['procedureId'] as String?) ?? '',
        classificationId: (j['classificationId'] as String?) ?? '',
        theatreId: (j['theatreId'] as String?) ?? '',
        surgeonId: (j['surgeonId'] as String?) ?? '',
        range: toRange(j['range']),
        turnover: Duration(minutes: toInt(j['turnover'], 30)),
        origin: toEnum(
            BookingOrigin.values, j['origin'], BookingOrigin.doctorDirect),
        status: toEnum(CaseStatus.values, j['status'], CaseStatus.scheduled),
        centreId: j['centreId'] as String?,
        campaignId: j['campaignId'] as String?,
        equipment: toStrings(j['equipment']),
        overrideReason: j['overrideReason'] as String?,
      );

  static Map<String, dynamic> block(TheatreBlock b) =>
      {'theatreId': b.theatreId, 'range': range(b.range), 'reason': b.reason};

  static TheatreBlock toBlock(Map<String, dynamic> j) => TheatreBlock(
        theatreId: (j['theatreId'] as String?) ?? '',
        range: toRange(j['range']),
        reason: (j['reason'] as String?) ?? '',
      );

  static Map<String, dynamic> surgeryRequest(SurgeryRequest r) => {
        'id': r.id,
        'reference': r.reference,
        'patientId': r.patientId,
        'procedureId': r.procedureId,
        'classificationId': r.classificationId,
        'submittedAt': date(r.submittedAt),
        'estimatePriceSnapshot': r.estimatePriceSnapshot,
        'origin': r.origin.name,
        'requestedByDoctorId': r.requestedByDoctorId,
        'clinicalNote': r.clinicalNote,
        'scheduledTheatreId': r.scheduledTheatreId,
        'scheduledStart': date(r.scheduledStart),
        'confirmedPrice': r.confirmedPrice,
        'preferredSurgeonId': r.preferredSurgeonId,
        'preferredFrom': date(r.preferredFrom),
        'preferredTo': date(r.preferredTo),
        'status': r.status.name,
        'decidedAt': date(r.decidedAt),
        'decisionReason': r.decisionReason,
        'escalatedAt': date(r.escalatedAt),
        'scheduledCaseId': r.scheduledCaseId,
      };

  static SurgeryRequest toSurgeryRequest(Map<String, dynamic> j) =>
      SurgeryRequest(
        id: j['id'] as String,
        reference: (j['reference'] as String?) ?? '',
        patientId: (j['patientId'] as String?) ?? '',
        procedureId: (j['procedureId'] as String?) ?? '',
        classificationId: (j['classificationId'] as String?) ?? '',
        submittedAt: toDate(j['submittedAt']),
        estimatePriceSnapshot: (j['estimatePriceSnapshot'] as String?) ?? '',
        origin:
            toEnum(RequestOrigin.values, j['origin'], RequestOrigin.patient),
        requestedByDoctorId: j['requestedByDoctorId'] as String?,
        clinicalNote: j['clinicalNote'] as String?,
        scheduledTheatreId: j['scheduledTheatreId'] as String?,
        scheduledStart: toDateOrNull(j['scheduledStart']),
        confirmedPrice: j['confirmedPrice'] as int?,
        preferredSurgeonId: j['preferredSurgeonId'] as String?,
        preferredFrom: toDateOrNull(j['preferredFrom']),
        preferredTo: toDateOrNull(j['preferredTo']),
        status: toEnum(SurgeryRequestStatus.values, j['status'],
            SurgeryRequestStatus.submitted),
        decidedAt: toDateOrNull(j['decidedAt']),
        decisionReason: j['decisionReason'] as String?,
        escalatedAt: toDateOrNull(j['escalatedAt']),
        scheduledCaseId: j['scheduledCaseId'] as String?,
      );

  // --------------------------------------------------------------- bookings

  static Map<String, dynamic> appointment(Appointment a) => {
        'id': a.id,
        'patientId': a.patientId,
        'doctorId': a.doctorId,
        'clinicId': a.clinicId,
        'range': range(a.range),
        'status': a.status.name,
        'reference': a.reference,
        'fee': a.fee,
        'depositPaid': a.depositPaid,
        'cancelReason': a.cancelReason?.name,
        'cancelNote': a.cancelNote,
        'createdAt': date(a.createdAt),
      };

  static Appointment toAppointment(Map<String, dynamic> j) => Appointment(
        id: j['id'] as String,
        patientId: (j['patientId'] as String?) ?? '',
        doctorId: (j['doctorId'] as String?) ?? '',
        clinicId: (j['clinicId'] as String?) ?? '',
        range: toRange(j['range']),
        status: toEnum(AppointmentStatus.values, j['status'],
            AppointmentStatus.confirmed),
        reference: (j['reference'] as String?) ?? '',
        fee: toInt(j['fee']),
        depositPaid: toInt(j['depositPaid']),
        cancelReason: j['cancelReason'] == null
            ? null
            : toEnum(CancellationReason.values, j['cancelReason'],
                CancellationReason.other),
        cancelNote: j['cancelNote'] as String?,
        createdAt: toDateOrNull(j['createdAt']),
      );

  static Map<String, dynamic> labBooking(LabBooking b) => {
        'id': b.id,
        'reference': b.reference,
        'patientId': b.patientId,
        'visitAt': date(b.visitAt),
        'testIds': b.testIds,
        'packageIds': b.packageIds,
        'total': b.total,
        'createdAt': date(b.createdAt),
        'status': b.status.name,
        'cancelReason': b.cancelReason?.name,
      };

  static LabBooking toLabBooking(Map<String, dynamic> j) => LabBooking(
        id: j['id'] as String,
        reference: (j['reference'] as String?) ?? '',
        patientId: (j['patientId'] as String?) ?? '',
        visitAt: toDate(j['visitAt']),
        testIds: toStrings(j['testIds']),
        packageIds: toStrings(j['packageIds']),
        total: toInt(j['total']),
        createdAt: toDate(j['createdAt']),
        status: toEnum(AppointmentStatus.values, j['status'],
            AppointmentStatus.confirmed),
        cancelReason: j['cancelReason'] == null
            ? null
            : toEnum(CancellationReason.values, j['cancelReason'],
                CancellationReason.other),
      );

  // ----------------------------------------------------------------- people

  static Map<String, dynamic> patient(Patient p) => {
        'id': p.id,
        'mrn': p.mrn,
        'fullName': p.fullName,
        'phoneE164': p.phoneE164,
        'dateOfBirth': date(p.dateOfBirth),
        'isMale': p.isMale,
        'email': p.email,
        'companyName': p.companyName,
        'bloodGroup': p.bloodGroup,
        'allergies': p.allergies,
        'chronicConditions': p.chronicConditions,
        'nationalId': p.nationalId,
        'governorate': p.governorate,
        'createdAt': date(p.createdAt),
        'googleEmail': p.googleEmail,
      };

  static Patient toPatient(Map<String, dynamic> j) => Patient(
        id: j['id'] as String,
        mrn: (j['mrn'] as String?) ?? '',
        fullName: (j['fullName'] as String?) ?? '',
        phoneE164: (j['phoneE164'] as String?) ?? '',
        dateOfBirth: toDate(j['dateOfBirth']),
        isMale: (j['isMale'] as bool?) ?? false,
        email: j['email'] as String?,
        companyName: j['companyName'] as String?,
        bloodGroup: j['bloodGroup'] as String?,
        allergies: toStrings(j['allergies']),
        chronicConditions: toStrings(j['chronicConditions']),
        nationalId: j['nationalId'] as String?,
        governorate: j['governorate'] as String?,
        createdAt: toDateOrNull(j['createdAt']),
        googleEmail: j['googleEmail'] as String?,
      );

  static Map<String, dynamic> staff(StaffUser u) => {
        'id': u.id,
        'name': u.name,
        'phone': u.phone,
        'roles': u.roles.map((r) => r.name).toList(),
        'doctorId': u.doctorId,
        'isActive': u.isActive,
        'username': u.username,
        'passwordHash': u.passwordHash,
      };

  static StaffUser toStaff(Map<String, dynamic> j) => StaffUser(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        roles: {
          for (final r in toStrings(j['roles']))
            toEnum(UserRole.values, r, UserRole.doctor),
        },
        doctorId: j['doctorId'] as String?,
        isActive: (j['isActive'] as bool?) ?? true,
        username: (j['username'] as String?) ?? '',
        passwordHash: (j['passwordHash'] as String?) ?? '',
      );

  // ---------------------------------------------------------------- content

  static Map<String, dynamic> offer(Offer o) => {
        'id': o.id,
        'title': label(o.title),
        'description': label(o.description),
        'priceBefore': o.priceBefore,
        'priceAfter': o.priceAfter,
        'validUntil': date(o.validUntil),
        'isEvent': o.isEvent,
      };

  static Offer toOffer(Map<String, dynamic> j) => Offer(
        id: j['id'] as String,
        title: toLabel(j['title']),
        description: toLabel(j['description']),
        priceBefore: toInt(j['priceBefore']),
        priceAfter: toInt(j['priceAfter']),
        validUntil: toDate(j['validUntil']),
        isEvent: (j['isEvent'] as bool?) ?? false,
      );

  static Map<String, dynamic> tip(MedicalTip t) => {
        'id': t.id,
        'category': label(t.category),
        'body': label(t.body),
        'reviewerName': t.reviewerName,
        'reviewedAt': date(t.reviewedAt),
      };

  static MedicalTip toTip(Map<String, dynamic> j) => MedicalTip(
        id: j['id'] as String,
        category: toLabel(j['category']),
        body: toLabel(j['body']),
        reviewerName: (j['reviewerName'] as String?) ?? '',
        reviewedAt: toDate(j['reviewedAt']),
      );

  static Map<String, dynamic> complaint(Complaint c) => {
        'id': c.id,
        'reference': c.reference,
        'category': c.category.name,
        'body': c.body,
        'submittedAt': date(c.submittedAt),
        'isAnonymous': c.isAnonymous,
        'response': c.response,
        'resolvedAt': date(c.resolvedAt),
        'patientId': c.patientId,
      };

  static Complaint toComplaint(Map<String, dynamic> j) => Complaint(
        id: j['id'] as String,
        reference: (j['reference'] as String?) ?? '',
        category: toEnum(
            ComplaintCategory.values, j['category'], ComplaintCategory.other),
        body: (j['body'] as String?) ?? '',
        submittedAt: toDate(j['submittedAt']),
        isAnonymous: (j['isAnonymous'] as bool?) ?? false,
        response: j['response'] as String?,
        resolvedAt: toDateOrNull(j['resolvedAt']),
        patientId: j['patientId'] as String?,
      );

  // ------------------------------------------------------------- governance

  static Map<String, dynamic> policy(HospitalPolicy p) => {
        'doctorsBookTheatreDirectly': p.doctorsBookTheatreDirectly,
        'approvalWindow': p.approvalWindow.inMinutes,
        'clinicCancellationCutoff': p.clinicCancellationCutoff.inMinutes,
        'notifyPatientsOnScheduleChange': p.notifyPatientsOnScheduleChange,
        'defaultPaymentPolicy': p.defaultPaymentPolicy.name,
      };

  static HospitalPolicy toPolicy(Object? json) {
    if (json is! Map) return const HospitalPolicy();
    return HospitalPolicy(
      doctorsBookTheatreDirectly:
          (json['doctorsBookTheatreDirectly'] as bool?) ?? true,
      approvalWindow: Duration(minutes: toInt(json['approvalWindow'], 240)),
      clinicCancellationCutoff:
          Duration(minutes: toInt(json['clinicCancellationCutoff'], 240)),
      notifyPatientsOnScheduleChange:
          (json['notifyPatientsOnScheduleChange'] as bool?) ?? true,
      defaultPaymentPolicy: toEnum(PaymentPolicy.values,
          json['defaultPaymentPolicy'], PaymentPolicy.payAtReception),
    );
  }

  static Map<String, dynamic> audit(AuditEntry a) => {
        'id': a.id,
        'actor': a.actor,
        'action': a.action,
        'entity': a.entity,
        'entityId': a.entityId,
        'at': date(a.at),
        'detail': a.detail,
      };

  static AuditEntry toAudit(Map<String, dynamic> j) => AuditEntry(
        id: j['id'] as String,
        actor: (j['actor'] as String?) ?? '',
        action: (j['action'] as String?) ?? '',
        entity: (j['entity'] as String?) ?? '',
        entityId: j['entityId'] as String?,
        at: toDate(j['at']),
        detail: j['detail'] as String?,
      );

  static Map<String, dynamic> notification(AppNotification n) => {
        'id': n.id,
        'channel': n.channel.name,
        'audience': n.audience.name,
        'templateCode': n.templateCode,
        'title': n.title,
        'body': n.body,
        'sentAt': date(n.sentAt),
        'entityId': n.entityId,
        'deepLink': n.deepLink,
        'recipientId': n.recipientId,
      };

  static AppNotification toNotification(Map<String, dynamic> j) =>
      AppNotification(
        id: j['id'] as String,
        channel: toEnum(NotifyChannel.values, j['channel'], NotifyChannel.inApp),
        audience: toEnum(
            NotifyAudience.values, j['audience'], NotifyAudience.patient),
        templateCode: (j['templateCode'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        sentAt: toDate(j['sentAt']),
        entityId: j['entityId'] as String?,
        deepLink: j['deepLink'] as String?,
        recipientId: j['recipientId'] as String?,
      );
}
