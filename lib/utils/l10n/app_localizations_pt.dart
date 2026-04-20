// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'WevaCalc';

  @override
  String get calculator => 'Calculadora';

  @override
  String get history => 'Histórico';

  @override
  String get settings => 'Configurações';

  @override
  String get loadMore => 'Carregar mais';

  @override
  String get clear => 'C';

  @override
  String get backspace => 'Apagar';

  @override
  String get equals => '=';

  @override
  String get percent => '%';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'WevaCalc';

  @override
  String get calculator => 'Calculadora';

  @override
  String get history => 'Histórico';

  @override
  String get settings => 'Configurações';

  @override
  String get loadMore => 'Carregar mais';

  @override
  String get clear => 'C';

  @override
  String get backspace => 'Apagar';

  @override
  String get equals => '=';

  @override
  String get percent => '%';
}
