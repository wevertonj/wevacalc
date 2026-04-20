import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wevacalc/config/theme/app_colors.dart';
import 'package:wevacalc/config/theme/app_theme.dart';
import 'package:wevacalc/utils/l10n/app_localizations.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(seedColor: AppColors.defaultSeedColor),
        darkTheme:
            darkTheme ?? AppTheme.dark(seedColor: AppColors.defaultSeedColor),
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget,
      ),
    );
    await pumpAndSettle();
  }
}
