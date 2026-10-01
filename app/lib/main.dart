import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/app_state.dart';
import 'data/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The hospital's catalogue ships inside the app; everything after the first
  // launch is read back from the device.
  final bundled = Map<String, dynamic>.from(jsonDecode(
          await rootBundle.loadString('assets/seed/hospital_data.json'))
      as Map);
  final state = AppState(storage: PrefsStorage());
  await state.load(bundled: bundled);

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: DarElOmoumaApp(state: state),
    ),
  );
}

class DarElOmoumaApp extends StatefulWidget {
  const DarElOmoumaApp({required this.state, super.key});

  final AppState state;

  @override
  State<DarElOmoumaApp> createState() => _DarElOmoumaAppState();
}

class _DarElOmoumaAppState extends State<DarElOmoumaApp> {
  late final _router = buildRouter(state: widget.state);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp.router(
      title: 'دار الأمومة',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,

      // Arabic (ar-EG) is the default; RTL mirroring is handled by Flutter's
      // directionality, which every screen honours by using Directional
      // widgets rather than left/right ones (PROMPT.md section 12.1).
      locale: state.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Dynamic type is supported up to 200% (PROMPT.md section 12.2), but
      // clamped so an extreme system setting cannot break the theatre grid.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 2.0,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
