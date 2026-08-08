import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const DarElOmoumaApp(),
    ),
  );
}

class DarElOmoumaApp extends StatefulWidget {
  const DarElOmoumaApp({super.key});

  @override
  State<DarElOmoumaApp> createState() => _DarElOmoumaAppState();
}

class _DarElOmoumaAppState extends State<DarElOmoumaApp> {
  final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp.router(
      title: 'Dar El Omouma',
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
