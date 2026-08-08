/// Egyptian National ID parsing and validation.
///
/// Layout of the 14 digits (PROMPT.md section 6.2):
///
/// ```
///  0        century   2 = 1900-1999, 3 = 2000-2099
///  1  -  2  year      YY
///  3  -  4  month     MM
///  5  -  6  day       DD
///  7  -  8  governorate code
///  9  - 12  serial    digit 12 odd = male, even = female
/// 13        check digit
/// ```
///
/// Structural validation — century, embedded date, governorate, gender — is
/// authoritative and always applied.
///
/// The trailing check digit is a different matter. Egypt does not publish the
/// checksum algorithm, and the weighted mod-11 variant implemented in
/// [checksumMatches] is the one most commonly reproduced in the wild rather
/// than a specification. It is therefore **off by default**: rejecting a real
/// patient's genuine ID at the registration screen is a far worse failure than
/// accepting a malformed one, which reception will catch anyway.
///
/// Before enabling [strictChecksum] in production, validate the algorithm
/// against a sample of real IDs supplied by the hospital. See PROMPT.md
/// section 19.
library;

class NationalIdInfo {
  const NationalIdInfo({
    required this.dateOfBirth,
    required this.governorateCode,
    required this.governorateAr,
    required this.governorateEn,
    required this.isMale,
  });

  final DateTime dateOfBirth;
  final String governorateCode;
  final String governorateAr;
  final String governorateEn;
  final bool isMale;
}

enum NationalIdError {
  empty,
  notFourteenDigits,
  badCentury,
  badDate,
  unknownGovernorate,
  badChecksum,
}

class NationalIdResult {
  const NationalIdResult.valid(this.info)
      : error = null,
        isValid = true;
  const NationalIdResult.invalid(this.error)
      : info = null,
        isValid = false;

  final bool isValid;
  final NationalIdInfo? info;
  final NationalIdError? error;
}

abstract final class NationalId {
  /// Governorate codes embedded in positions 8-9.
  static const Map<String, (String ar, String en)> governorates = {
    '01': ('القاهرة', 'Cairo'),
    '02': ('الإسكندرية', 'Alexandria'),
    '03': ('بورسعيد', 'Port Said'),
    '04': ('السويس', 'Suez'),
    '11': ('دمياط', 'Damietta'),
    '12': ('الدقهلية', 'Dakahlia'),
    '13': ('الشرقية', 'Sharqia'),
    '14': ('القليوبية', 'Qalyubia'),
    '15': ('كفر الشيخ', 'Kafr El Sheikh'),
    '16': ('الغربية', 'Gharbia'),
    '17': ('المنوفية', 'Monufia'),
    '18': ('البحيرة', 'Beheira'),
    '19': ('الإسماعيلية', 'Ismailia'),
    '21': ('الجيزة', 'Giza'),
    '22': ('بني سويف', 'Beni Suef'),
    '23': ('الفيوم', 'Fayoum'),
    '24': ('المنيا', 'Minya'),
    '25': ('أسيوط', 'Assiut'),
    '26': ('سوهاج', 'Sohag'),
    '27': ('قنا', 'Qena'),
    '28': ('أسوان', 'Aswan'),
    '29': ('الأقصر', 'Luxor'),
    '31': ('البحر الأحمر', 'Red Sea'),
    '32': ('الوادي الجديد', 'New Valley'),
    '33': ('مطروح', 'Matrouh'),
    '34': ('شمال سيناء', 'North Sinai'),
    '35': ('جنوب سيناء', 'South Sinai'),
    '88': ('مولود خارج مصر', 'Born abroad'),
  };

  /// Normalises Eastern Arabic numerals (٠-٩) to Western digits and strips
  /// spaces, so a patient typing on an Arabic keyboard is not rejected.
  static String normalise(String input) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final easternIndex = eastern.indexOf(char);
      if (easternIndex >= 0) {
        buffer.write(easternIndex);
      } else if (RegExp(r'\d').hasMatch(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static NationalIdResult parse(String raw, {bool strictChecksum = false}) {
    final id = normalise(raw);
    if (id.isEmpty) {
      return const NationalIdResult.invalid(NationalIdError.empty);
    }
    if (id.length != 14) {
      return const NationalIdResult.invalid(NationalIdError.notFourteenDigits);
    }

    final centuryDigit = int.parse(id[0]);
    final int centuryBase;
    switch (centuryDigit) {
      case 2:
        centuryBase = 1900;
      case 3:
        centuryBase = 2000;
      default:
        return const NationalIdResult.invalid(NationalIdError.badCentury);
    }

    final year = centuryBase + int.parse(id.substring(1, 3));
    final month = int.parse(id.substring(3, 5));
    final day = int.parse(id.substring(5, 7));

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return const NationalIdResult.invalid(NationalIdError.badDate);
    }
    final dob = DateTime(year, month, day);
    // Rejects impossible dates such as 31 February, which DateTime rolls over.
    if (dob.year != year || dob.month != month || dob.day != day) {
      return const NationalIdResult.invalid(NationalIdError.badDate);
    }
    if (dob.isAfter(DateTime.now())) {
      return const NationalIdResult.invalid(NationalIdError.badDate);
    }

    final governorateCode = id.substring(7, 9);
    final governorate = governorates[governorateCode];
    if (governorate == null) {
      return const NationalIdResult.invalid(NationalIdError.unknownGovernorate);
    }

    if (strictChecksum && !checksumMatches(id)) {
      return const NationalIdResult.invalid(NationalIdError.badChecksum);
    }

    return NationalIdResult.valid(
      NationalIdInfo(
        dateOfBirth: dob,
        governorateCode: governorateCode,
        governorateAr: governorate.$1,
        governorateEn: governorate.$2,
        isMale: int.parse(id[12]).isOdd,
      ),
    );
  }

  /// Weighted mod-11 check over the first 13 digits.
  ///
  /// See the library comment: unverified against an official specification,
  /// so callers must opt in via `strictChecksum`.
  static bool checksumMatches(String id) {
    if (id.length != 14) return false;
    const weights = [2, 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    var sum = 0;
    for (var i = 0; i < 13; i++) {
      sum += int.parse(id[i]) * weights[i];
    }
    final remainder = sum % 11;
    final expected = switch (remainder) {
      0 => 0,
      1 => -1, // No valid check digit exists for this remainder.
      _ => 11 - remainder,
    };
    if (expected < 0) return false;
    return expected == int.parse(id[13]);
  }
}

/// Egyptian mobile numbers: 010/011/012/015 followed by 8 digits.
abstract final class PhoneNumber {
  static final _pattern = RegExp(r'^01[0125]\d{8}$');

  static bool isValid(String raw) =>
      _pattern.hasMatch(NationalId.normalise(raw));

  /// Normalises to E.164 for storage, per PROMPT.md section 6.2.
  static String? toE164(String raw) {
    final local = NationalId.normalise(raw);
    if (!_pattern.hasMatch(local)) return null;
    return '+20${local.substring(1)}';
  }
}

abstract final class NameValidator {
  /// The hospital requires a four-part name (الاسم رباعي).
  static bool hasFourParts(String raw) =>
      raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length >= 4;
}

abstract final class EmailValidator {
  static final _pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static bool isValid(String raw) => _pattern.hasMatch(raw.trim());
}
