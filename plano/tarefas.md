# Tarefas — WevaCalc

Checklist detalhado de cada etapa. Marque `[x]` conforme concluir.

---

## Etapa 1 — Fundação e Infraestrutura ✅

### Dependências

- [x] Atualizar `pubspec.yaml` com: `get_it`, `sqflite`, `path`, `shared_preferences`, `flutter_localizations`, `intl`
- [x] Adicionar dev_dependencies: `mocktail`, `sqflite_common_ffi` (para testes)
- [x] Rodar `flutter pub get`

### Estrutura de Pastas

- [x] Criar `lib/config/`
- [x] Criar `lib/config/theme/`
- [x] Criar `lib/data/database/`
- [x] Criar `lib/data/repositories/`
- [x] Criar `lib/data/models/`
- [x] Criar `lib/domain/entities/`
- [x] Criar `lib/domain/enums/`
- [x] Criar `lib/ui/calculator/widgets/`
- [x] Criar `lib/ui/history/widgets/`
- [x] Criar `lib/ui/settings/widgets/`
- [x] Criar `lib/ui/core/widgets/`
- [x] Criar `lib/utils/extensions/`
- [x] Criar `lib/utils/formatters/`
- [x] Criar `lib/utils/l10n/`

### Tema e Layout

- [x] Implementar `AppLayout` (spacing, padding, radius) — `lib/config/theme/app_layout.dart`
- [x] Implementar `AppColors` (9 seed colors) — `lib/config/theme/app_colors.dart`
- [x] Implementar `AppTheme` (ThemeData claro/escuro) — `lib/config/theme/app_theme.dart`

### Configuração

- [x] Criar `lib/config/dependencies.dart` (GetIt setup inicial)
- [x] Criar `lib/config/routes.dart` (rotas nomeadas: /, /history, /settings)

### Internacionalização

- [x] Criar `l10n.yaml` na raiz
- [x] Criar `lib/utils/l10n/app_pt.arb` (português base) + `app_pt_BR.arb` (brasileiro)
- [x] Criar `lib/utils/l10n/app_es.arb` (espanhol)
- [x] Criar `lib/utils/l10n/app_en.arb` (inglês)
- [x] Criar extension `context.l10n` em `lib/utils/extensions/l10n_extension.dart`
- [x] Configurar `flutter generate: true` no pubspec.yaml

### App Shell

- [x] Reescrever `lib/main.dart` com MaterialApp usando AppTheme, rotas e l10n

### Testes — Etapa 1

- [x] Criar `test/unit/config/theme/app_layout_test.dart`
- [x] Criar `test/unit/config/theme/app_colors_test.dart`
- [x] Criar `test/unit/config/theme/app_theme_test.dart`
- [x] `flutter test` — 100% verde (27 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 2 — Domínio e Camada de Dados (base) ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/fixtures/` com dados de teste reutilizáveis
- [x] Criar `test/mocks/` com mocks centralizados
- [x] Criar `test/unit/domain/entities/calculation_test.dart`
- [x] Criar `test/unit/domain/entities/history_entry_test.dart`
- [x] Criar `test/unit/domain/enums/operation_type_test.dart`
- [x] Criar `test/unit/data/models/history_model_test.dart`
- [x] Criar `test/unit/data/repositories/history_repository_test.dart`

### Implementação (TDD Green)

- [x] Implementar `Calculation` — `lib/domain/entities/calculation.dart`
- [x] Implementar `HistoryEntry` — `lib/domain/entities/history_entry.dart`
- [x] Implementar `OperationType` — `lib/domain/enums/operation_type.dart`
- [x] Implementar `ThemeModeOption` — `lib/domain/enums/theme_mode_option.dart`
- [x] Implementar `DecimalSeparator` — `lib/domain/enums/decimal_separator.dart`
- [x] Implementar `HistoryModel` — `lib/data/models/history_model.dart`
- [x] Implementar `AppDatabase` — `lib/data/database/app_database.dart`
- [x] Implementar `HistoryRepository` (interface) — `lib/data/repositories/history_repository.dart`
- [x] Implementar `HistoryRepositoryImpl` — `lib/data/repositories/history_repository_impl.dart`
- [x] Registrar database e repository no GetIt

### Validação

- [x] `flutter test` — 100% verde (66 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 2.1 — Evolução da Camada de Dados (nome, favorito, paginação) ✅

### Testes PRIMEIRO (TDD Red)

- [x] Atualizar `test/unit/domain/entities/history_entry_test.dart`
  - Cenários: criação com name e isFavorite, copyWith com novos campos, equality com novos campos
- [x] Atualizar `test/unit/data/models/history_model_test.dart`
  - Cenários: toMap/fromMap/toEntity/fromEntity com name e isFavorite
- [x] Atualizar `test/unit/data/repositories/history_repository_test.dart`
  - Cenários: getPaginated, getFavorites, updateName, toggleFavorite, getById
- [x] Atualizar `test/fixtures/history_fixtures.dart` com novos campos

### Implementação (TDD Green)

- [x] Adicionar `name` (String?) e `isFavorite` (bool) em `HistoryEntry`
- [x] Atualizar `HistoryEntry.copyWith` com novos campos
- [x] Atualizar `HistoryModel` com novos campos (toMap, fromMap, toEntity, fromEntity)
- [x] Atualizar schema SQLite: adicionar colunas `name TEXT` e `is_favorite INTEGER NOT NULL DEFAULT 0`
- [x] Adicionar novos métodos à interface `HistoryRepository`:
  - `getPaginated(limit, offset)`
  - `getFavorites(limit, offset)`
  - `updateName(id, name)`
  - `toggleFavorite(id)`
  - `getById(id)`
- [x] Implementar novos métodos em `HistoryRepositoryImpl`

### Validação

- [x] `flutter test` — 100% verde (98 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 3 — Motor da Calculadora ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/unit/domain/add2_engine_test.dart`
  - Cenários: dígitos simples, sequência de dígitos, backspace, 00, 000, reset, valores limite
- [x] Criar `test/unit/domain/expression_evaluator_test.dart`
  - Cenários: soma, subtração, multiplicação, divisão, precedência, %, divisão por zero, expressão inválida
- [x] Criar `test/unit/utils/formatters/number_formatter_test.dart`
  - Cenários: ponto, vírgula, milhar, sem decimais, negativos
- [x] Criar `test/unit/ui/calculator/calculator_view_model_test.dart`
  - Cenários: estado inicial, inputDigit, operação, =, C, ⌫, timeline, load more na timeline, prévia resultado, persistência no histórico, carregamento de sessão

### Implementação (TDD Green)

- [x] Implementar `Add2Engine` — `lib/domain/add2_engine.dart`
- [x] Implementar `ExpressionEvaluator` — `lib/domain/expression_evaluator.dart`
- [x] Implementar `NumberFormatter` — `lib/utils/formatters/number_formatter.dart`
- [x] Implementar `CalculatorViewModel` — `lib/ui/calculator/calculator_view_model.dart`
  - Timeline com limite visível e load more
- [x] Registrar CalculatorViewModel no GetIt

### Validação

- [x] `flutter test` — 100% verde (224 testes)
- [x] `flutter analyze` — zero warnings

---

## Etapa 4 — Lógica do Histórico e Configurações ✅

### Testes PRIMEIRO (TDD Red)

- [x] Criar `test/unit/ui/history/history_view_model_test.dart`
  - Cenários: carregamento paginado, loadMore, hasMore, deleção individual, limpar tudo, rename, toggleFavorite, filtro favoritos, notificações
- [x] Criar `test/unit/data/repositories/settings_repository_test.dart`
  - Cenários: salvar/carregar ThemeMode, seedColor, decimalSeparator, locale
- [x] Criar `test/unit/ui/settings/settings_view_model_test.dart`
  - Cenários: estado inicial, alteração de cada preferência, persistência via repository

### Implementação (TDD Green)

- [x] Implementar `HistoryViewModel` — `lib/ui/history/history_view_model.dart`
  - Carregamento paginado (loadMore, hasMore)
  - Deleta, limpa, rename, toggleFavorite
  - Filtro: todos / favoritos
  - Notifica listeners
- [x] Implementar `SettingsRepository` (interface) — `lib/data/repositories/settings_repository.dart`
- [x] Implementar `SettingsRepositoryImpl` — `lib/data/repositories/settings_repository_impl.dart`
  - SharedPreferences para ThemeMode, seedColor, decimalSeparator, locale
- [x] Implementar `SettingsViewModel` — `lib/ui/settings/settings_view_model.dart`
  - Gerencia preferências, persiste via repository, notifica listeners
- [x] Registrar SettingsRepository, HistoryViewModel e SettingsViewModel no GetIt

### Validação

- [x] `flutter test` — 100% verde (277 testes)
- [x] `flutter analyze` — zero warnings
- [x] Verificar: nenhum ViewModel importa Flutter (exceto foundation.dart)

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
  - Botão "load more" no topo para carregar cálculos anteriores da sessão
  - AnimatedSwitcher para prévia de resultado
- [ ] Implementar `CalculatorPage` — `lib/ui/calculator/calculator_page.dart`
  - Scaffold com timeline + barra de ícones + keypad
- [ ] Barra de ícones: ⏱ (histórico) e ⚙ (configurações) — navegação sem destino por enquanto
- [ ] Atualizar strings nos arquivos ARB (botões, labels, "load more")

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
  - Lista paginada em ordem cronológica inversa (mais recente primeiro)
  - Botão "load more" no final da lista
  - Cada item mostra: nome (se houver), expressão (truncada se longa), resultado e data/hora
  - Ícone de favorito (★) em cada item — toque para alternar
  - Filtro: Todos / Favoritos (tabs ou toggle)
  - Toque longo ou menu: renomear entrada
  - Expressões longas truncadas com "..." (expandível)
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
- [ ] Atualizar ARBs com strings do histórico e configurações (favoritos, renomear, load more, etc.)

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
- [ ] Testar fluxo: sessão longa → load more na timeline carrega anteriores
- [ ] Testar fluxo: histórico → load more → favoritar → filtrar → renomear

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
