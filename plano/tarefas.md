# Tarefas — WevaCalc

Checklist detalhado de cada etapa. Marque `[x]` conforme concluir.

---

## Etapa 1 — Fundação e Infraestrutura

### Dependências

- [ ] Atualizar `pubspec.yaml` com: `get_it`, `sqflite`, `path`, `shared_preferences`, `flutter_localizations`, `intl`
- [ ] Adicionar dev_dependencies: `mocktail`, `sqflite_common_ffi` (para testes)
- [ ] Rodar `flutter pub get`

### Estrutura de Pastas

- [ ] Criar `lib/config/`
- [ ] Criar `lib/config/theme/`
- [ ] Criar `lib/data/database/`
- [ ] Criar `lib/data/repositories/`
- [ ] Criar `lib/data/models/`
- [ ] Criar `lib/domain/entities/`
- [ ] Criar `lib/domain/enums/`
- [ ] Criar `lib/ui/calculator/widgets/`
- [ ] Criar `lib/ui/history/widgets/`
- [ ] Criar `lib/ui/settings/widgets/`
- [ ] Criar `lib/ui/core/widgets/`
- [ ] Criar `lib/utils/extensions/`
- [ ] Criar `lib/utils/formatters/`
- [ ] Criar `lib/utils/l10n/`

### Tema e Layout

- [ ] Implementar `AppLayout` (spacing, padding, radius) — `lib/config/theme/app_layout.dart`
- [ ] Implementar `AppColors` (9 seed colors) — `lib/config/theme/app_colors.dart`
- [ ] Implementar `AppTheme` (ThemeData claro/escuro) — `lib/config/theme/app_theme.dart`

### Configuração

- [ ] Criar `lib/config/dependencies.dart` (GetIt setup inicial)
- [ ] Criar `lib/config/routes.dart` (rotas nomeadas: /, /history, /settings)

### Internacionalização

- [ ] Criar `l10n.yaml` na raiz
- [ ] Criar `lib/utils/l10n/app_br.arb` (português Brasileiro)
- [ ] Criar `lib/utils/l10n/app_es.arb` (espanhol)
- [ ] Criar `lib/utils/l10n/app_en.arb` (inglês)
- [ ] Criar extension `context.l10n` em `lib/utils/extensions/l10n_extension.dart`
- [ ] Configurar `flutter generate: true` se necessário

### App Shell

- [ ] Reescrever `lib/main.dart` com MaterialApp usando AppTheme, rotas e l10n

### Testes — Etapa 1

- [ ] Criar `test/unit/config/theme/app_layout_test.dart`
- [ ] Criar `test/unit/config/theme/app_colors_test.dart`
- [ ] Criar `test/unit/config/theme/app_theme_test.dart`
- [ ] `flutter test` — 100% verde
- [ ] `flutter analyze` — zero warnings

---

## Etapa 2 — Domínio e Camada de Dados

### Testes PRIMEIRO (TDD Red)

- [ ] Criar `test/fixtures/` com dados de teste reutilizáveis
- [ ] Criar `test/mocks/` com mocks centralizados
- [ ] Criar `test/unit/domain/entities/calculation_test.dart`
- [ ] Criar `test/unit/domain/entities/history_entry_test.dart`
- [ ] Criar `test/unit/domain/enums/operation_type_test.dart`
- [ ] Criar `test/unit/data/models/history_model_test.dart`
- [ ] Criar `test/unit/data/repositories/history_repository_test.dart`

### Implementação (TDD Green)

- [ ] Implementar `Calculation` — `lib/domain/entities/calculation.dart`
- [ ] Implementar `HistoryEntry` — `lib/domain/entities/history_entry.dart`
- [ ] Implementar `OperationType` — `lib/domain/enums/operation_type.dart`
- [ ] Implementar `ThemeModeOption` — `lib/domain/enums/theme_mode_option.dart`
- [ ] Implementar `DecimalSeparator` — `lib/domain/enums/decimal_separator.dart`
- [ ] Implementar `HistoryModel` — `lib/data/models/history_model.dart`
- [ ] Implementar `AppDatabase` — `lib/data/database/app_database.dart`
- [ ] Implementar `HistoryRepository` (interface) — `lib/data/repositories/history_repository.dart`
- [ ] Implementar `HistoryRepositoryImpl` — `lib/data/repositories/history_repository_impl.dart`
- [ ] Registrar database e repository no GetIt

### Validação

- [ ] `flutter test` — 100% verde
- [ ] `flutter analyze` — zero warnings

---

## Etapa 3 — Motor da Calculadora

### Testes PRIMEIRO (TDD Red)

- [ ] Criar `test/unit/domain/add2_engine_test.dart`
  - Cenários: dígitos simples, sequência de dígitos, backspace, 00, reset, valores limite
- [ ] Criar `test/unit/domain/expression_evaluator_test.dart`
  - Cenários: soma, subtração, multiplicação, divisão, precedência, parênteses, %, divisão por zero, expressão inválida
- [ ] Criar `test/unit/utils/formatters/number_formatter_test.dart`
  - Cenários: ponto, vírgula, milhar, sem decimais, negativos
- [ ] Criar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenários: estado inicial, inputDigit, operação, =, C, ⌫, timeline, prévia resultado, persistência no histórico, carregamento de sessão

### Implementação (TDD Green)

- [ ] Implementar `Add2Engine` — `lib/domain/add2_engine.dart`
- [ ] Implementar `ExpressionEvaluator` — `lib/domain/expression_evaluator.dart`
- [ ] Implementar `NumberFormatter` — `lib/utils/formatters/number_formatter.dart`
- [ ] Implementar `CalculatorViewModel` — `lib/ui/calculator/calculator_view_model.dart`
- [ ] Registrar CalculatorViewModel no GetIt

### Validação

- [ ] `flutter test` — 100% verde
- [ ] `flutter analyze` — zero warnings

---

## Etapa 4 — Lógica do Histórico e Configurações

### Testes PRIMEIRO (TDD Red)

- [ ] Criar `test/unit/ui/history/history_view_model_test.dart`
  - Cenários: carregamento de lista, deleção individual, limpar tudo, notificações
- [ ] Criar `test/unit/data/repositories/settings_repository_test.dart`
  - Cenários: salvar/carregar ThemeMode, seedColor, decimalSeparator, locale
- [ ] Criar `test/unit/ui/settings/settings_view_model_test.dart`
  - Cenários: estado inicial, alteração de cada preferência, persistência via repository

### Implementação (TDD Green)

- [ ] Implementar `HistoryViewModel` — `lib/ui/history/history_view_model.dart`
  - Carrega lista, deleta, limpa, notifica listeners
- [ ] Implementar `SettingsRepository` (interface) — `lib/data/repositories/settings_repository.dart`
- [ ] Implementar `SettingsRepositoryImpl` — `lib/data/repositories/settings_repository_impl.dart`
  - SharedPreferences para ThemeMode, seedColor, decimalSeparator, locale
- [ ] Implementar `SettingsViewModel` — `lib/ui/settings/settings_view_model.dart`
  - Gerencia preferências, persiste via repository, notifica listeners
- [ ] Registrar SettingsRepository, HistoryViewModel e SettingsViewModel no GetIt

### Validação

- [ ] `flutter test` — 100% verde
- [ ] `flutter analyze` — zero warnings
- [ ] Verificar: nenhum ViewModel importa Flutter (exceto foundation.dart)

---

## Etapa 5 — UI da Calculadora

### Testes PRIMEIRO (TDD Red)

- [ ] Criar `test/widget/calculator/calculator_button_test.dart`
- [ ] Criar `test/widget/calculator/calculator_keypad_test.dart`
- [ ] Criar `test/widget/calculator/timeline_display_test.dart`
- [ ] Criar `test/widget/calculator/calculator_page_test.dart`

### Implementação (TDD Green)

- [ ] Implementar `CalculatorButton` — `lib/ui/calculator/widgets/calculator_button.dart`
  - AnimatedContainer com feedback de toque, variantes (numérico, operador, ação)
- [ ] Implementar `CalculatorKeypad` — `lib/ui/calculator/widgets/calculator_keypad.dart`
  - Grid 5×4 com layout documentado
- [ ] Implementar `TimelineDisplay` — `lib/ui/calculator/widgets/timeline_display.dart`
  - ListView scrollável, linhas com cores diferenciadas, auto-scroll
  - AnimatedSwitcher para prévia de resultado
- [ ] Implementar `CalculatorPage` — `lib/ui/calculator/calculator_page.dart`
  - Scaffold com timeline + barra de ícones + keypad
- [ ] Barra de ícones: ⏱ (histórico) e ⚙ (configurações) — navegação sem destino por enquanto
- [ ] Atualizar strings nos arquivos ARB (botões, labels)

### Validação

- [ ] `flutter test` — 100% verde
- [ ] `flutter analyze` — zero warnings
- [ ] Teste manual: app roda e calcula corretamente

---

## Etapa 6 — UI do Histórico e Configurações

### Testes PRIMEIRO (TDD Red)

- [ ] Criar `test/widget/history/history_page_test.dart`
- [ ] Criar `test/widget/settings/settings_page_test.dart`

### Implementação (TDD Green)

- [ ] Implementar `HistoryPage` — `lib/ui/history/history_page.dart`
  - Lista em ordem cronológica inversa (mais recente primeiro)
  - Cada item mostra expressão, resultado e data/hora
  - Animação de entrada para cada item da lista
  - Ação limpar com diálogo de confirmação
- [ ] Implementar widgets auxiliares em `lib/ui/history/widgets/`
- [ ] Implementar `SettingsPage` — `lib/ui/settings/settings_page.dart`
  - Seção tema (modo + seed color com círculos coloridos)
  - Seção formato de número (toggle ponto/vírgula)
  - Seção idioma (seletor)
  - Toda mudança reflete imediatamente com animação suave
- [ ] Implementar widgets auxiliares em `lib/ui/settings/widgets/`
- [ ] Integrar navegação completa: ⏱ → HistoryPage, ⚙ → SettingsPage
- [ ] Integrar Timeline ↔ Histórico: tocar item → carrega sessão → volta à calculadora
- [ ] Integrar com `main.dart`: carregar preferências no startup, propagar tema/locale
- [ ] Atualizar ARBs com strings do histórico e configurações

### Validação

- [ ] `flutter test` — 100% verde
- [ ] `flutter analyze` — zero warnings
- [ ] Teste manual: navegação e fluxos funcionam corretamente

---

## Etapa 7 — Polimento, Integração e Revisão Final

### Animações e Transições

- [ ] Revisar animações de todos os botões (curvas, durações)
- [ ] Implementar transição de página animada (Calculator ↔ History ↔ Settings)
- [ ] Animação de troca de tema global suave (AnimatedTheme ou wrap)
- [ ] Verificar AnimatedSwitcher no display da timeline

### Fluxos de Integração

- [ ] Testar fluxo: calculadora → = → resultado aparece na timeline
- [ ] Testar fluxo: calculadora → ⏱ → histórico → tocar item → timeline carregada
- [ ] Testar fluxo: calculadora → ⚙ → mudar tema → reflexo imediato
- [ ] Testar fluxo: calculadora → ⚙ → mudar separador → reflexo no display
- [ ] Testar fluxo: fechar app → reabrir → preferências mantidas

### Qualidade

- [ ] `flutter analyze` — zero warnings
- [ ] `flutter test` — 100% verde
- [ ] Verificar: nenhuma string hardcoded na UI
- [ ] Verificar: nenhum valor de layout hardcoded
- [ ] Verificar: nenhum `print()` no código
- [ ] Verificar: ViewModels não importam Flutter
- [ ] Revisar cobertura de testes

### Documentação

- [ ] Atualizar docs se houve desvios da arquitetura
- [ ] Atualizar changelog
