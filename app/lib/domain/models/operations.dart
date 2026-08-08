import 'enums.dart';

/// Delivery channel for an outbound notification (PROMPT.md §12.3–12.4).
enum NotifyChannel { push, whatsapp, sms, inApp }

/// Who a notification was addressed to.
enum NotifyAudience { patient, approvers, surgeon, coordinator, homeCareTeam }

/// A single outbound notification, as it would be handed to FCM/APNs, the
/// WhatsApp Business Cloud API, or the SMS gateway.
///
/// The **hard rule** this class exists to make testable: WhatsApp and SMS
/// bodies carry a reference and a deep link, never a patient name, diagnosis
/// or clinical value (PROMPT.md §12.4, rule 1). WhatsApp is an alerting
/// channel — "something needs you, open the app" — not a content channel.
/// [AppNotification.staffAlert] is the only way to build one, and it refuses
/// to accept a body that has not been through that discipline.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.channel,
    required this.audience,
    required this.templateCode,
    required this.title,
    required this.body,
    required this.sentAt,
    this.entityId,
    this.deepLink,
    this.carriesPhi = false,
  });

  /// A staff alert. Free of protected health information by construction.
  factory AppNotification.staffAlert({
    required String id,
    required NotifyChannel channel,
    required NotifyAudience audience,
    required String templateCode,
    required String title,
    required String reference,
    required String context,
    required DateTime sentAt,
    String? entityId,
    String? deepLink,
  }) {
    return AppNotification(
      id: id,
      channel: channel,
      audience: audience,
      templateCode: templateCode,
      title: title,
      body: '$reference · $context',
      sentAt: sentAt,
      entityId: entityId,
      deepLink: deepLink,
    );
  }

  final String id;
  final NotifyChannel channel;
  final NotifyAudience audience;

  /// The Meta-approved template this maps to. WhatsApp permits only
  /// pre-approved templates outside a 24-hour session window, so templates are
  /// registered at build time and only their variables change.
  final String templateCode;
  final String title;
  final String body;
  final DateTime sentAt;
  final String? entityId;
  final String? deepLink;

  /// True only for in-app content, which is behind authentication.
  final bool carriesPhi;

  bool get isExternalChannel =>
      channel == NotifyChannel.whatsapp || channel == NotifyChannel.sms;
}

enum HomeCareStatus {
  submitted,
  scheduled,
  enRoute,
  inProgress,
  completed,
  cancelled,
}

class HomeCareRequest {
  const HomeCareRequest({
    required this.id,
    required this.reference,
    required this.serviceId,
    required this.patientId,
    required this.address,
    required this.preferredFrom,
    required this.preferredTo,
    required this.submittedAt,
    this.notes,
    this.status = HomeCareStatus.submitted,
  });

  final String id;
  final String reference;
  final String serviceId;
  final String patientId;
  final String address;
  final DateTime preferredFrom;
  final DateTime preferredTo;
  final DateTime submittedAt;
  final String? notes;
  final HomeCareStatus status;

  /// Free cancellation is available until the team is dispatched
  /// (PROMPT.md §6.4).
  bool get isCancellableFreeOfCharge =>
      status == HomeCareStatus.submitted || status == HomeCareStatus.scheduled;

  HomeCareRequest copyWith({HomeCareStatus? status}) => HomeCareRequest(
        id: id,
        reference: reference,
        serviceId: serviceId,
        patientId: patientId,
        address: address,
        preferredFrom: preferredFrom,
        preferredTo: preferredTo,
        submittedAt: submittedAt,
        notes: notes,
        status: status ?? this.status,
      );
}

class BloodRequest {
  const BloodRequest({
    required this.id,
    required this.reference,
    required this.bloodGroup,
    required this.component,
    required this.units,
    required this.requiredBy,
    required this.submittedAt,
  });

  final String id;
  final String reference;
  final String bloodGroup;
  final String component;
  final int units;
  final DateTime requiredBy;
  final DateTime submittedAt;
}

class DonorProfile {
  const DonorProfile({
    required this.bloodGroup,
    required this.lastDonation,
    required this.acceptsAppeals,
  });

  final String bloodGroup;
  final DateTime? lastDonation;

  /// Urgent appeals may target a donor only on blood group and eligibility,
  /// and only with the donor's opt-in (PROMPT.md §6.9).
  final bool acceptsAppeals;

  /// Whole-blood donation interval. Confirm the hospital's own policy before
  /// release — 90 days is the common Egyptian practice, not a rule this app
  /// should be inventing (PROMPT.md §19.10).
  static const Duration donationInterval = Duration(days: 90);

  DateTime? get nextEligibleDate => lastDonation?.add(donationInterval);

  bool isEligibleAt(DateTime now) {
    final next = nextEligibleDate;
    return next == null || !now.isBefore(next);
  }
}

/// A patient inside a visiting-expert campaign pipeline (PROMPT.md §6.15.2).
///
/// There is **one list**, whether the patient registered themselves or the
/// host doctor added them — [addedByDoctor] records which, and nothing else
/// about the pipeline branches on it.
class CampaignPatient {
  const CampaignPatient({
    required this.id,
    required this.campaignId,
    required this.patientId,
    required this.patientDisplayName,
    required this.stage,
    required this.addedByDoctor,
    required this.addedAt,
    this.screeningAt,
    this.note,
    this.waitlistRank,
  });

  final String id;
  final String campaignId;
  final String patientId;
  final String patientDisplayName;
  final VisitingStage stage;
  final bool addedByDoctor;
  final DateTime addedAt;
  final DateTime? screeningAt;
  final String? note;
  final int? waitlistRank;

  CampaignPatient copyWith({
    VisitingStage? stage,
    DateTime? screeningAt,
    String? note,
    int? waitlistRank,
  }) =>
      CampaignPatient(
        id: id,
        campaignId: campaignId,
        patientId: patientId,
        patientDisplayName: patientDisplayName,
        stage: stage ?? this.stage,
        addedByDoctor: addedByDoctor,
        addedAt: addedAt,
        screeningAt: screeningAt ?? this.screeningAt,
        note: note ?? this.note,
        waitlistRank: waitlistRank ?? this.waitlistRank,
      );

  /// Counts towards the campaign's minimum viable cohort only once the
  /// patient has actually been shortlisted or scheduled — registering
  /// interest is not a commitment.
  bool get countsTowardsCohort =>
      stage == VisitingStage.shortlisted ||
      stage == VisitingStage.surgeryScheduled ||
      stage == VisitingStage.completed;
}
