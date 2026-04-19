/// Constantes de layout do app — spacing, padding e radius.
///
/// Nunca use valores hardcoded de layout nos widgets.
/// Sempre utilize [AppLayout] para manter consistência.
class AppLayout {
  AppLayout._();

  static const spacing = AppSpacing();
  static const padding = AppPadding();
  static const radius = AppRadius();
}

class AppSpacing {
  const AppSpacing();

  double get xs => 4.0;
  double get small => 8.0;
  double get medium => 16.0;
  double get large => 24.0;
  double get xl => 32.0;
}

class AppPadding {
  const AppPadding();

  double get xs => 4.0;
  double get small => 8.0;
  double get medium => 16.0;
  double get large => 24.0;
  double get xl => 32.0;
}

class AppRadius {
  const AppRadius();

  double get small => 8.0;
  double get medium => 16.0;
  double get large => 24.0;
  double get circular => 100.0;
}
