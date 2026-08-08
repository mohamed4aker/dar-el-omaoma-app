import 'package:dar_el_omouma/core/validation/national_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NationalId.parse — structure', () {
    test('accepts a well-formed 1900s ID and derives the birth date', () {
      // 2 95 04 12 01 2345 6 → born 12 April 1995, Cairo, serial digit 5 (odd).
      final result = NationalId.parse('29504120123456');
      expect(result.isValid, isTrue);
      final info = result.info!;
      expect(info.dateOfBirth, DateTime(1995, 4, 12));
      expect(info.governorateCode, '01');
      expect(info.governorateEn, 'Cairo');
      expect(info.isMale, isTrue);
    });

    test('derives female from an even serial digit', () {
      final result = NationalId.parse('29504120123446');
      expect(result.isValid, isTrue);
      expect(result.info!.isMale, isFalse);
    });

    test('accepts a 2000s ID', () {
      final result = NationalId.parse('30501010212345');
      expect(result.isValid, isTrue);
      expect(result.info!.dateOfBirth, DateTime(2005, 1, 1));
    });

    test('rejects the wrong length', () {
      expect(
        NationalId.parse('2950412012345').error,
        NationalIdError.notFourteenDigits,
      );
      expect(
        NationalId.parse('295041201234567').error,
        NationalIdError.notFourteenDigits,
      );
    });

    test('rejects an unsupported century digit', () {
      expect(
        NationalId.parse('19504120123456').error,
        NationalIdError.badCentury,
      );
    });

    test('rejects an impossible calendar date', () {
      // 31 February.
      expect(
        NationalId.parse('29502310123456').error,
        NationalIdError.badDate,
      );
      // Month 13.
      expect(
        NationalId.parse('29513010123456').error,
        NationalIdError.badDate,
      );
    });

    test('rejects a future date of birth', () {
      final future = DateTime.now().add(const Duration(days: 400));
      final yy = (future.year % 100).toString().padLeft(2, '0');
      final mm = future.month.toString().padLeft(2, '0');
      final dd = future.day.toString().padLeft(2, '0');
      expect(
        NationalId.parse('3$yy$mm${dd}010123456'.substring(0, 14)).error,
        NationalIdError.badDate,
      );
    });

    test('rejects an unknown governorate code', () {
      expect(
        NationalId.parse('29504129923456').error,
        NationalIdError.unknownGovernorate,
      );
    });

    test('accepts Eastern Arabic numerals', () {
      final result = NationalId.parse('٢٩٥٠٤١٢٠١٢٣٤٥٦');
      expect(result.isValid, isTrue);
      expect(result.info!.dateOfBirth, DateTime(1995, 4, 12));
    });

    test('ignores spaces and separators', () {
      expect(NationalId.parse('2950 4120 1234 56').isValid, isTrue);
      expect(NationalId.parse('295-0412-0123456').isValid, isTrue);
    });

    test('counts digits after stripping, so a 15th digit still fails', () {
      expect(
        NationalId.parse('2950-4120-1234-567').error,
        NationalIdError.notFourteenDigits,
      );
    });
  });

  group('NationalId — checksum opt-in', () {
    test('is not applied unless strictChecksum is set', () {
      // Whatever the trailing digit, structural parsing succeeds by default.
      // The checksum algorithm is unverified against an official spec, so it
      // must never silently reject a real patient (see the library comment).
      for (var digit = 0; digit <= 9; digit++) {
        expect(NationalId.parse('2950412012345$digit').isValid, isTrue);
      }
    });

    test('strict mode rejects at most nine of the ten trailing digits', () {
      final accepted = [
        for (var digit = 0; digit <= 9; digit++)
          if (NationalId.parse('2950412012345$digit', strictChecksum: true)
              .isValid)
            digit,
      ];
      expect(accepted.length, lessThanOrEqualTo(1));
    });
  });

  group('PhoneNumber', () {
    test('accepts the four Egyptian mobile prefixes', () {
      for (final prefix in ['010', '011', '012', '015']) {
        expect(PhoneNumber.isValid('${prefix}12345678'), isTrue,
            reason: prefix);
      }
    });

    test('rejects landlines and wrong lengths', () {
      expect(PhoneNumber.isValid('0223456789'), isFalse);
      expect(PhoneNumber.isValid('0131234567'), isFalse);
      expect(PhoneNumber.isValid('0101234567'), isFalse);
      expect(PhoneNumber.isValid('010123456789'), isFalse);
    });

    test('normalises to E.164', () {
      expect(PhoneNumber.toE164('01013009936'), '+201013009936');
      expect(PhoneNumber.toE164('not a number'), isNull);
    });
  });

  group('NameValidator', () {
    test('requires four parts', () {
      expect(NameValidator.hasFourParts('سارة محمود عبد الرحمن حسين'), isTrue);
      expect(NameValidator.hasFourParts('سارة محمود حسين'), isFalse);
      expect(NameValidator.hasFourParts('  '), isFalse);
    });

    test('tolerates repeated whitespace', () {
      expect(NameValidator.hasFourParts('أ  ب   ج    د'), isTrue);
    });
  });
}
