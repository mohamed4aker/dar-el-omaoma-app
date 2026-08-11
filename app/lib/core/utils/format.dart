import '../l10n/app_strings.dart';

abstract final class Fmt {
  static const _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdaysAr = [
    'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];
  static const _weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static String date(DateTime d, AppStrings s) {
    final months = s.localeName == 'en' ? _monthsEn : _monthsAr;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String shortDate(DateTime d, AppStrings s) {
    final months = s.localeName == 'en' ? _monthsEn : _monthsAr;
    return '${d.day} ${months[d.month - 1].substring(0, 3)}';
  }

  static String weekday(DateTime d, AppStrings s) {
    final days = s.localeName == 'en' ? _weekdaysEn : _weekdaysAr;
    return days[d.weekday - 1];
  }

  /// 24-hour clock. Egyptian hospital schedules are read in 24-hour form and
  /// AM/PM in Arabic invites mistakes on a theatre list.
  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String timeRange(DateTime start, DateTime end) =>
      '${time(start)} – ${time(end)}';

  static String duration(Duration d, AppStrings s) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (s.localeName == 'en') {
      if (hours == 0) return '$minutes ${s.commonMinutes}';
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    }

    if (hours == 0) return arabicUnit(minutes, _minuteForms);
    if (minutes == 0) return arabicUnit(hours, _hourForms);
    return '${arabicUnit(hours, _hourForms)} و${arabicUnit(minutes, _minuteForms)}';
  }

  static const _hourForms = ('ساعة', 'ساعتين', 'ساعات', 'ساعة');
  static const _minuteForms = ('دقيقة', 'دقيقتين', 'دقائق', 'دقيقة');

  /// Arabic counted-noun agreement.
  ///
  /// Arabic does not simply append a plural: 1 takes the singular with no
  /// number, 2 takes the dual, 3–10 take the plural, and 11 upward return to
  /// the singular. Writing "3 ساعة" reads as broken Arabic to a native
  /// speaker, which is not something a hospital's app can afford.
  ///
  /// [forms] is (singular, dual, plural, singularAfterTen).
  static String arabicUnit(
    int count,
    (String, String, String, String) forms,
  ) {
    final (singular, dual, plural, afterTen) = forms;
    if (count == 1) return singular;
    if (count == 2) return dual;
    if (count >= 3 && count <= 10) return '$count $plural';
    return '$count $afterTen';
  }

  static String money(int amount, AppStrings s) => '${group(amount)} ${s.commonEgp}';

  static String moneyRange(int min, int max, AppStrings s) =>
      '${group(min)} – ${group(max)} ${s.commonEgp}';

  static String group(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
