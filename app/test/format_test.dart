import 'package:dar_el_omouma/core/l10n/app_strings.dart';
import 'package:dar_el_omouma/core/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ar = AppStrings.ar;
  const en = AppStrings.en;

  group('Arabic counted-noun agreement', () {
    test('1 takes the singular with no number', () {
      expect(Fmt.duration(const Duration(hours: 1), ar), 'ساعة');
      expect(Fmt.duration(const Duration(minutes: 1), ar), 'دقيقة');
    });

    test('2 takes the dual, not "2 ساعة"', () {
      expect(Fmt.duration(const Duration(hours: 2), ar), 'ساعتين');
      expect(Fmt.duration(const Duration(minutes: 2), ar), 'دقيقتين');
    });

    test('3 to 10 take the plural', () {
      expect(Fmt.duration(const Duration(hours: 3), ar), '3 ساعات');
      expect(Fmt.duration(const Duration(hours: 10), ar), '10 ساعات');
      expect(Fmt.duration(const Duration(minutes: 45), ar), '45 دقيقة');
      expect(Fmt.duration(const Duration(minutes: 5), ar), '5 دقائق');
    });

    test('11 and above return to the singular', () {
      expect(Fmt.duration(const Duration(hours: 11), ar), '11 ساعة');
      expect(Fmt.duration(const Duration(minutes: 20), ar), '20 دقيقة');
    });

    test('mixed durations join with the Arabic conjunction', () {
      expect(
        Fmt.duration(const Duration(hours: 1, minutes: 15), ar),
        'ساعة و15 دقيقة',
      );
      expect(
        Fmt.duration(const Duration(hours: 2, minutes: 30), ar),
        'ساعتين و30 دقيقة',
      );
      expect(
        Fmt.duration(const Duration(hours: 3, minutes: 5), ar),
        '3 ساعات و5 دقائق',
      );
    });

    test('the real catalogue durations read correctly', () {
      // The values shown on the surgery catalogue screen.
      expect(Fmt.duration(const Duration(minutes: 180), ar), '3 ساعات');
      expect(Fmt.duration(const Duration(minutes: 120), ar), 'ساعتين');
      expect(Fmt.duration(const Duration(minutes: 75), ar), 'ساعة و15 دقيقة');
      expect(Fmt.duration(const Duration(minutes: 60), ar), 'ساعة');
      expect(Fmt.duration(const Duration(minutes: 150), ar), 'ساعتين و30 دقيقة');
    });
  });

  group('English durations stay compact', () {
    test('hours and minutes', () {
      expect(Fmt.duration(const Duration(hours: 3), en), '3h');
      expect(Fmt.duration(const Duration(hours: 1, minutes: 15), en), '1h 15m');
      expect(Fmt.duration(const Duration(minutes: 45), en), '45 min');
    });
  });

  group('money grouping', () {
    test('inserts thousands separators', () {
      expect(Fmt.group(95000), '95,000');
      expect(Fmt.group(120000), '120,000');
      expect(Fmt.group(500), '500');
      expect(Fmt.group(0), '0');
    });

    test('formats with the currency', () {
      expect(Fmt.money(45000, ar), '45,000 جنيه');
      expect(Fmt.money(45000, en), '45,000 EGP');
    });
  });

  group('time', () {
    test('renders a zero-padded 24-hour clock', () {
      expect(Fmt.time(DateTime(2026, 9, 1, 9, 5)), '09:05');
      expect(Fmt.time(DateTime(2026, 9, 1, 18, 30)), '18:30');
    });

    test('isSameDay ignores the time of day', () {
      expect(
        Fmt.isSameDay(DateTime(2026, 9, 1, 8), DateTime(2026, 9, 1, 23)),
        isTrue,
      );
      expect(
        Fmt.isSameDay(DateTime(2026, 9, 1), DateTime(2026, 9, 2)),
        isFalse,
      );
    });
  });
}
