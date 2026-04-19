import 'package:flutter/material.dart';

/// Configuração centralizada de rotas do app.
class AppRoutes {
  AppRoutes._();

  static const String calculator = '/';
  static const String history = '/history';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    // Rotas serão conectadas às páginas nas Etapas 5 e 6.
    // Por enquanto, usam placeholders.
    calculator: (_) => const _PlaceholderPage(title: 'Calculator'),
    history: (_) => const _PlaceholderPage(title: 'History'),
    settings: (_) => const _PlaceholderPage(title: 'Settings'),
  };
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
