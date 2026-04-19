import 'package:flutter/foundation.dart';

import 'package:wevacalc/data/repositories/settings_repository.dart';
import 'package:wevacalc/domain/enums/decimal_separator.dart';
import 'package:wevacalc/domain/enums/theme_mode_option.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required SettingsRepository settingsRepository})
    : _settingsRepository = settingsRepository;

  final SettingsRepository _settingsRepository;

  ThemeModeOption _themeMode = ThemeModeOption.system;
  int _seedColorIndex = 0;
  DecimalSeparator _decimalSeparator = DecimalSeparator.dot;
  String? _locale;

  ThemeModeOption get themeMode => _themeMode;

  int get seedColorIndex => _seedColorIndex;

  DecimalSeparator get decimalSeparator => _decimalSeparator;

  String? get locale => _locale;

  Future<void> loadSettings() async {
    _themeMode = await _settingsRepository.getThemeMode();
    _seedColorIndex = await _settingsRepository.getSeedColorIndex();
    _decimalSeparator = await _settingsRepository.getDecimalSeparator();
    _locale = await _settingsRepository.getLocale();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    _themeMode = mode;
    await _settingsRepository.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setSeedColorIndex(int index) async {
    _seedColorIndex = index;
    await _settingsRepository.setSeedColorIndex(index);
    notifyListeners();
  }

  Future<void> setDecimalSeparator(DecimalSeparator separator) async {
    _decimalSeparator = separator;
    await _settingsRepository.setDecimalSeparator(separator);
    notifyListeners();
  }

  Future<void> setLocale(String? locale) async {
    _locale = locale;
    await _settingsRepository.setLocale(locale);
    notifyListeners();
  }
}
