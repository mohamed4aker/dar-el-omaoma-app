import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';

/// Opens the phone dialler, WhatsApp or the map. Falls back to a message
/// rather than failing silently when the device cannot handle it.
abstract final class Launch {
  static Future<void> call(BuildContext context, String number) =>
      _open(context, Uri(scheme: 'tel', path: number));

  /// Egyptian local numbers are rewritten to international form for wa.me.
  static Future<void> whatsapp(BuildContext context, String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final intl = digits.startsWith('0') ? '20${digits.substring(1)}' : digits;
    return _open(context, Uri.parse('https://wa.me/$intl'));
  }

  static Future<void> url(BuildContext context, String url) =>
      _open(context, Uri.parse(url));

  static Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.tr('تعذر فتح ${uri.path.isEmpty ? uri : uri.path}',
        'Could not open ${uri.path.isEmpty ? uri : uri.path}');
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }
}
