import 'catalog.dart';
import 'enums.dart';

class MedicalTip {
  const MedicalTip({
    required this.id,
    required this.category,
    required this.body,
    required this.reviewerName,
    required this.reviewedAt,
  });

  final String id;
  final Label category;
  final Label body;

  /// Content without a named medical reviewer must never be publishable
  /// (PROMPT.md section 6.12).
  final String reviewerName;
  final DateTime reviewedAt;
}

class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.priceBefore,
    required this.priceAfter,
    required this.validUntil,
    this.isEvent = false,
  });

  final String id;
  final Label title;
  final Label description;
  final int priceBefore;
  final int priceAfter;
  final DateTime validUntil;
  final bool isEvent;

  int get discountPercent =>
      priceBefore == 0 ? 0 : (100 * (priceBefore - priceAfter) ~/ priceBefore);
}

class Complaint {
  const Complaint({
    required this.id,
    required this.reference,
    required this.category,
    required this.body,
    required this.submittedAt,
    required this.isAnonymous,
    this.response,
    this.resolvedAt,
  });

  final String id;
  final String reference;
  final ComplaintCategory category;
  final String body;
  final DateTime submittedAt;
  final bool isAnonymous;
  final String? response;
  final DateTime? resolvedAt;

  /// Acknowledgement target from PROMPT.md section 6.5.
  static const Duration acknowledgementTarget = Duration(hours: 24);

  DateTime get slaDueAt => submittedAt.add(acknowledgementTarget);
}

/// A visiting-expert campaign (PROMPT.md section 6.15).
class VisitingCampaign {
  const VisitingCampaign({
    required this.id,
    required this.expertName,
    required this.expertCountry,
    required this.expertInstitution,
    required this.expertBio,
    required this.specialty,
    required this.hostDoctorId,
    required this.arrivesAt,
    required this.departsAt,
    required this.capacity,
    required this.registered,
    required this.minimumViableCohort,
    required this.procedureIds,
    required this.licenceReference,
    required this.licenceValidUntil,
  });

  final String id;
  final String expertName;
  final Label expertCountry;
  final Label expertInstitution;
  final Label expertBio;
  final Label specialty;
  final String hostDoctorId;
  final DateTime arrivesAt;
  final DateTime departsAt;
  final int capacity;
  final int registered;
  final int minimumViableCohort;
  final List<String> procedureIds;

  /// Egyptian Medical Syndicate / Ministry of Health authorisation for a
  /// visiting foreign practitioner (PROMPT.md section 6.15.4).
  final String? licenceReference;
  final DateTime? licenceValidUntil;

  int get seatsRemaining => (capacity - registered).clamp(0, capacity);

  bool get meetsMinimumCohort => registered >= minimumViableCohort;

  /// A campaign must not be visible to patients while the visiting expert's
  /// authorisation to practise is missing or expired. This gate is the whole
  /// reason the licence fields exist; publishing without it would let the
  /// hospital advertise a surgeon who is not cleared to operate.
  bool isPublishableAt(DateTime now) {
    final reference = licenceReference;
    final validUntil = licenceValidUntil;
    if (reference == null || reference.isEmpty) return false;
    if (validUntil == null) return false;
    return validUntil.isAfter(now) && departsAt.isBefore(validUntil);
  }
}
