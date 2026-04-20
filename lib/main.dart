import 'package:flutter/material.dart';

import 'package:wevacalc/config/dependencies.dart';
import 'package:wevacalc/config/routes.dart';
import 'package:wevacalc/data/database/app_database.dart';
import 'package:wevacalc/config/theme/app_colors.dart';
import 'package:wevacalc/config/theme/app_theme.dart';
import 'package:wevacalc/utils/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  await getIt<AppDatabase>().initialize();
  runApp(const WevaCalcApp());
}

class WevaCalcApp extends StatelessWidget {
  const WevaCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WevaCalc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seedColor: AppColors.defaultSeedColor),
      darkTheme: AppTheme.dark(seedColor: AppColors.defaultSeedColor),
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.calculator,
    );
  }
}
