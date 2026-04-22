# Changelog — WevaCalc

Registro de todas as alterações realizadas no projeto, organizado por etapa.

---

## [Concluída] Etapa 1 — Fundação e Infraestrutura

### Dependências

- Atualizado `pubspec.yaml` com: `get_it`, `sqflite`, `path`, `shared_preferences`, `flutter_localizations`, `intl`
- Adicionadas dev_dependencies: `mocktail`, `sqflite_common_ffi`
- Removido `cupertino_icons` (não utilizado)

### Estrutura de Pastas

- Criados todos os diretórios: `config/`, `data/`, `domain/`, `ui/`, `utils/` com sub-pastas

### Tema e Layout

- `AppLayout` — constantes de spacing (`xs`→`xl`), padding (`xs`→`xl`), radius (`small`→`circular`)
- `AppColors` — 9 seed colors (Amber padrão, Blue, Green, Red, Purple, Orange, Cyan, Pink, Blue Grey)
- `AppTheme` — ThemeData claro e escuro via `ColorScheme.fromSeed()` com Material 3

### Configuração

- `dependencies.dart` — GetIt setup inicial (vazio, pronto para Etapa 2+)
- `routes.dart` — rotas nomeadas (`/`, `/history`, `/settings`) com placeholders

### Internacionalização

- `l10n.yaml` configurado com output em `lib/utils/l10n/`
- ARBs criados: `app_en.arb`, `app_pt_BR.arb`, `app_es.arb`
- Extension `context.l10n` em `lib/utils/extensions/l10n_extension.dart`
- Strings iniciais: `appTitle`, `calculator`, `history`, `settings`

### App Shell

- `main.dart` reescrito com `WevaCalcApp`: tema dark padrão, l10n, rotas, GetIt

### Testes

- `app_layout_test.dart` — 14 testes (spacing, padding, radius)
- `app_colors_test.dart` — 4 testes (seed colors, default)
- `app_theme_test.dart` — 9 testes (light/dark, brightness, Material 3, seed variation)
- **Total: 27 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 2 — Domínio e Camada de Dados (base)

### Entities

- `Calculation` — expression, result, timestamp com value equality
- `HistoryEntry` — id (nullable), expression, result, createdAt com value equality e copyWith

### Enums

- `OperationType` — add (+), subtract (−), multiply (×), divide (÷) com propriedade `symbol`
- `ThemeModeOption` — light, dark, system
- `DecimalSeparator` — dot (.), comma (,) com propriedade `character`

### Models

- `HistoryModel` — toMap, fromMap, toEntity, fromEntity (converte entre Map/Entity)
  - toMap omite `id` quando null (para INSERT sem id)

### Database

- `AppDatabase` — SQLite helper com migrations versionadas
  - Aceita `DatabaseFactory` injetável (para testes com FFI)
  - `initialize(inMemory: true)` para testes
  - Schema v1: tabela `history` (id, expression, result, created_at)

### Repository

- `HistoryRepository` (interface) — getAll, add, delete, clear
- `HistoryRepositoryImpl` — implementação com SQLite
  - `getAll()` retorna ordenado por created_at DESC
  - `add()` retorna entry com id atribuído

### Injeção de Dependência

- `AppDatabase` registrado como lazy singleton no GetIt
- `HistoryRepository` registrado como lazy singleton no GetIt

### Fixtures e Mocks

- `test/fixtures/history_fixtures.dart` — dados de teste reutilizáveis
- `test/mocks/mock_history_repository.dart` — mock com mocktail

### Testes

- `calculation_test.dart` — 6 testes (criação, equality, hashCode)
- `history_entry_test.dart` — 7 testes (criação, nullable id, equality, copyWith)
- `operation_type_test.dart` — 6 testes (valores, symbols)
- `theme_mode_option_test.dart` — 2 testes (valores)
- `decimal_separator_test.dart` — 4 testes (valores, characters)
- `history_model_test.dart` — 7 testes (toMap, fromMap, toEntity, fromEntity)
- `history_repository_test.dart` — 7 testes (add, getAll, delete, clear com SQLite em memória)
- **Total novos: 39 testes — Total geral: 66 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 2.1 — Evolução da Camada de Dados (nome, favorito, paginação)

### HistoryEntry

- Adicionado campo `name` (String?, opcional, default null)
- Adicionado campo `isFavorite` (bool, default false)
- Atualizado `copyWith` com suporte aos novos campos
- Atualizado `==` e `hashCode` incluindo `name` e `isFavorite`

### HistoryModel

- Adicionado campo `name` (String?, opcional)
- Adicionado campo `isFavorite` (bool, default false)
- `toMap()` serializa `name` e `is_favorite` (int 0/1)
- `fromMap()` deserializa `name` e `is_favorite`
- `toEntity()` e `fromEntity()` mapeiam os novos campos

### Schema SQLite

- Adicionada coluna `name TEXT` na tabela `history`
- Adicionada coluna `is_favorite INTEGER NOT NULL DEFAULT 0` na tabela `history`

### HistoryRepository (interface)

- Novo método `getById(id)` — buscar entrada individual
- Novo método `getPaginated(limit, offset)` — paginação com LIMIT/OFFSET
- Novo método `getFavorites(limit, offset)` — apenas favoritos, paginado
- Novo método `updateName(id, name)` — renomear entrada
- Novo método `toggleFavorite(id)` — alternar favorito

### HistoryRepositoryImpl

- Implementação de `getById` — query por id, retorna null se não existe
- Implementação de `getPaginated` — query com LIMIT/OFFSET ordenada por created_at DESC
- Implementação de `getFavorites` — filtra is_favorite = 1, paginado
- Implementação de `updateName` — UPDATE do campo name
- Implementação de `toggleFavorite` — toggle via CASE WHEN no SQL

### Fixtures e Mocks

- Adicionadas fixtures: `entryWithName`, `entryFavorite`, `entryWithNameAndFavorite`
- Adicionados models: `modelWithName`, `modelFavorite`
- Adicionados maps: `mapWithName`, `mapFavorite`
- Maps existentes (`map1`, `mapWithoutId`) atualizados com campos `name` e `is_favorite`

### Testes

- `history_entry_test.dart` — 15 testes (criação com novos campos, equality, copyWith com name/isFavorite)
- `history_model_test.dart` — 14 testes (toMap/fromMap/toEntity/fromEntity com novos campos)
- `history_repository_test.dart` — 17 testes (add com novos campos, getById, getPaginated, getFavorites, updateName, toggleFavorite)
- **Total novos: 32 testes — Total geral: 98 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 3 — Motor da Calculadora

### Add2Engine (`lib/domain/add2_engine.dart`)

- Entrada numérica com 2 casas decimais automáticas (conceito Add2)
- `inputDigit` — insere dígito com validação (apenas 0-9)
- `inputDoubleZero` / `inputTripleZero` — atalhos para `00` e `000`
- `deleteLastDigit` — backspace com reajuste automático
- `formattedValue` — valor formatado com separador decimal (ex: `12.50`)
- `doubleValue` / `intValue` — acesso ao valor numérico
- `setValue` — define valor a partir de centavos inteiros
- `reset` — limpa estado

### ExpressionEvaluator (`lib/domain/expression_evaluator.dart`)

- Avalia expressões com +, −, ×, ÷ respeitando precedência matemática
- Suporte a porcentagem (%) com comportamento contextual:
  - `+` e `−`: porcentagem sobre o valor base (100 + 10% = 110)
  - `×` e `÷`: conversão direta para fração (200 × 10% = 20)
- Tratamento de erros: divisão por zero, expressão vazia/inválida, operador trailing
- Resultado sempre formatado com 2 casas decimais

### NumberFormatter (`lib/utils/formatters/number_formatter.dart`)

- `format(cents, separator)` — formata centavos inteiros com separador configurável (ponto/vírgula)
- `formatDouble(value, separator)` — formata double com separador configurável
- Suporte a separador de milhar (ponto para vírgula e vice-versa)
- Suporte a valores negativos

### CalculatorViewModel (`lib/ui/calculator/calculator_view_model.dart`)

- Gerencia entrada Add2 para o número atual
- Monta expressão completa (números + operadores)
- Prévia do resultado em tempo real (`previewResult`)
- Confirma cálculo (`equals`) e adiciona à timeline + persiste no histórico
- Timeline com limite de entradas visíveis e `loadMoreTimelineEntries`
- Carregamento de sessão (`loadSession`) a partir do histórico
- Encadeamento de operações (resultado anterior como próximo operando)
- Substituição de operador sem perder o operando
- Suporte a porcentagem via `applyPercentage`

### Injeção de Dependência

- `CalculatorViewModel` registrado como factory no GetIt

### Testes

- `add2_engine_test.dart` — 39 testes (dígitos, 00, 000, backspace, reset, setValue, doubleValue, isEmpty)
- `expression_evaluator_test.dart` — 26 testes (operações, precedência, %, erros, formatação)
- `number_formatter_test.dart` — 18 testes (ponto, vírgula, milhar, negativos, formatDouble)
- `calculator_view_model_test.dart` — 43 testes (estado inicial, dígitos, operadores, =, C, ⌫, %, timeline, load more, loadSession)
- **Total novos: 126 testes — Total geral: 224 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 4 — Lógica do Histórico e Configurações

### HistoryViewModel (`lib/ui/history/history_view_model.dart`)

- Carregamento paginado de entradas (20 por página)
- `loadEntries()` — carrega primeira página e reseta paginação
- `loadMore()` — carrega próxima página e acrescenta à lista
- `hasMore` — indica se há mais páginas disponíveis
- `isLoading` — estado de carregamento para feedback visual
- `deleteEntry(id)` — deleta entrada individual e remove da lista local
- `clearAll()` — limpa todo o histórico e reseta paginação
- `updateName(id, name)` — renomeia entrada localmente e no banco
- `toggleFavorite(id)` — alterna favorito localmente e no banco
- `setShowFavoritesOnly(bool)` — alterna filtro e recarrega lista
- Proteção contra chamadas concorrentes de loadMore

### SettingsRepository (`lib/data/repositories/settings_repository.dart`)

- Interface com métodos get/set para:
  - `ThemeModeOption` (light, dark, system)
  - `seedColorIndex` (índice 0-8 das seed colors)
  - `DecimalSeparator` (dot, comma)
  - `locale` (String?, nullable)

### SettingsRepositoryImpl (`lib/data/repositories/settings_repository_impl.dart`)

- Implementação com SharedPreferences
- Valores padrão: system, 0, dot, null
- `setLocale(null)` remove a chave do SharedPreferences

### SettingsViewModel (`lib/ui/settings/settings_view_model.dart`)

- Gerencia estado reativo de todas as preferências
- `loadSettings()` — carrega todas as preferências do repository
- `setThemeMode()`, `setSeedColorIndex()`, `setDecimalSeparator()`, `setLocale()` — atualizam estado e persistem
- Notifica listeners em cada alteração

### Injeção de Dependência

- `SettingsRepository` registrado como lazy singleton no GetIt
- `HistoryViewModel` registrado como factory no GetIt
- `SettingsViewModel` registrado como factory no GetIt

### Mocks

- `MockSettingsRepository` criado em `test/mocks/mock_settings_repository.dart`

### Testes

- `history_view_model_test.dart` — 24 testes (estado inicial, loadEntries, loadMore, hasMore, isLoading, delete, clearAll, updateName, toggleFavorite, setShowFavoritesOnly, paginação de favoritos, notificações)
- `settings_repository_test.dart` — 11 testes (get/set ThemeMode, seedColorIndex, decimalSeparator, locale com defaults e persistência)
- `settings_view_model_test.dart` — 18 testes (estado inicial, loadSettings, setThemeMode, setSeedColorIndex, setDecimalSeparator, setLocale, notificações)
- **Total novos: 53 testes — Total geral: 277 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 5 — UI da Calculadora

### Design System — Atualização de Cores

- `AppColors` — Paleta de 9 seed colors atualizada:
  - Blue (#005CEE, padrão), Emerald (#10B981), Orange (#F97316), Cyan (#06B6D4), Pink (#EC4899), Amber (#F59E0B), Rose (#F43F5E), Slate (#94A3B8), Yellow (#F3DE2C)
- `AppColors` — Cores de superfície customizadas:
  - Dark: background (#181818), surface (#212121), surfaceContainer (#2D2D2D)
  - Light: background (#F4F4F5), surface (#FFFFFF), surfaceContainer (#E8E8EA)
- `AppTheme` — ThemeData claro/escuro com cores de superfície customizadas via `ColorScheme.fromSeed`

### CalculatorButton (`lib/ui/calculator/widgets/calculator_button.dart`)

- Botão circular com 4 variantes: `numeric`, `operator`, `action`, `equals`
- Efeito de toque: flash instantâneo na cor de fundo (tap down) com retorno suave (80ms)
- Efeito reactive typing: texto/ícone acende como LED no tap e apaga suavemente (500ms, `Curves.easeOutQuart`)
- Operadores em cor primary, numéricos em onSurface, ações em onSurface com opacidade, equals com fundo primary
- `AnimatedContainer` para feedback de fundo, `AnimationController` para glow do texto

### CalculatorKeypad (`lib/ui/calculator/widgets/calculator_keypad.dart`)

- Grid 5×4 com layout: C, %, ⌫, ÷ | 7, 8, 9, × | 4, 5, 6, − | 1, 2, 3, + | 000, 00, 0, =
- 20 botões `CalculatorButton` com variantes corretas
- Callbacks separados: `onDigit`, `onOperator`, `onEquals`, `onClear`, `onBackspace`, `onPercent`, `onDoubleZero`, `onTripleZero`

### TimelineDisplay (`lib/ui/calculator/widgets/timeline_display.dart`)

- ListView scrollável com auto-scroll para o final ao atualizar
- Entradas passadas em cor sutil (onSurface com baixa opacidade)
- Expressão atual em branco, valor atual em fonte grande (48px, w300)
- Prévia do resultado em cinza (28px, 35% opacidade)
- `AnimatedSwitcher` com `switchInCurve: Curves.easeOutQuart` para transições de valor
- Botão "load more" no topo com fundo surfaceContainerHighest

### CalculatorPage (`lib/ui/calculator/calculator_page.dart`)

- Layout vertical: Timeline (expanded) + barra de ícones + Keypad
- Barra de ícones: history (⏱) e settings (⚙) — navegação placeholder
- Integração com `CalculatorViewModel` via `addListener`/`setState`

### Rotas

- Rota `/` conectada ao `CalculatorPage` com ViewModel do GetIt

### Internacionalização

- Novas strings nos 3 ARBs: `loadMore`, `clear`, `backspace`, `equals`, `percent`

### Infraestrutura de Testes

- `test/helpers/pump_app.dart` — Extension `pumpApp` em `WidgetTester` com tema, l10n e dark mode

### Testes

- `calculator_button_test.dart` — 11 testes (renderização de variantes, ícone, interação, cores)
- `calculator_keypad_test.dart` — 13 testes (todos os botões, callbacks de dígitos/operadores/ações)
- `timeline_display_test.dart` — 9 testes (expressão, valor, preview, entradas passadas, load more)
- `calculator_page_test.dart` — 8 testes (renderização, integração teclado→display, =, C, ⌫)
- **Total novos: 41 testes — Total geral: 318 testes — 100% verde**
- `flutter analyze` — zero issues

### Extras (fora do plano original)

#### AnimatedInputDisplay (`lib/ui/calculator/widgets/animated_input_display.dart`)

Widget customizado que substituiu o `TextField` padrão no display da calculadora. Renderiza cada caractere individualmente com animações:

- **Pop-in**: Novos caracteres surgem com expansão de largura (0 → target), escala (0.5 → 1) e opacidade (0 → 1) em 250ms com `Curves.easeOutBack`
- **Rolling digit**: Caracteres que mudam de valor usam transição vertical — antigo sobe e desaparece, novo sobe por baixo — em 200ms com `Curves.easeOutCubic`
- **Diff algorithm**: `_diffAndBuildSlots()` calcula prefixo/sufixo comum para determinar tipo de animação por caractere (popIn, roll, none)
- **RichText**: Cada caractere usa `RichText` em vez de `Text` para evitar conflito com `find.text()` nos testes de widget
- **Operadores coloridos**: +, −, ×, ÷ renderizados na cor primary; dígitos na cor onSurface

#### Animação de redução de fonte

- `TweenAnimationBuilder<double>` no fontSize (200ms, `Curves.easeOutCubic`) — quando a expressão cresce e a fonte reduz (48 → 36 → 28), a transição é suave em vez de instantânea

#### Suporte multiline com token grouping

- Prop `multiline` no `AnimatedInputDisplay` — quando a expressão excede a largura mesmo com a menor fonte (28px), o display usa `Wrap` em vez de scroll horizontal
- `_groupIntoTokens()`: agrupa caracteres em tokens (números como Row inline) para que o `Wrap` só quebre entre operadores/espaços, nunca no meio de um número como "4.56"

#### Font scaling adaptativo no TimelineDisplay

- `_calculateFontLayout()`: calcula `({double fontSize, bool multiline})` com base na largura disponível
- Threshold de 88% da largura (`_shrinkThreshold = 0.88`) para disparar redução antes do texto encostar na borda
- Cascata: 48px → 36px → 28px → multiline

#### Reactive typing no CalculatorButton

- **LED glow effect**: ao pressionar um botão, texto/ícone acende na cor de destaque como um LED e apaga suavemente em 500ms (`Curves.easeOutQuart`) via `AnimationController`
- **Flash de fundo**: tap down causa flash instantâneo na cor de fundo, com retorno suave em 80ms
- Esses efeitos não estavam no plano, que previa apenas `AnimatedContainer` para feedback de toque

#### Entry animation no TimelineDisplay

- `SingleTickerProviderStateMixin` com `SlideTransition` + `FadeTransition` para animar a entrada mais recente na timeline (350ms, `Curves.easeOutCubic`)
- Novas entradas deslizam de baixo e aparecem gradualmente

#### Design System — Paleta de cores atualizada

- `AppColors` reformulado com nova paleta de 9 seed colors: Blue (#005CEE, padrão), Emerald, Orange, Cyan, Pink, Amber, Rose, Slate, Yellow
- Cores de superfície customizadas para dark (background #181818, surface #212121, surfaceContainer #2D2D2D) e light (background #F4F4F5, surface #FFFFFF, surfaceContainer #E8E8EA)
- `AppTheme` atualizado para aplicar cores de superfície customizadas no `ColorScheme.fromSeed`

#### Remoção do cursor

- Cursor piscante (`_BlinkingCursor`) removido temporariamente — será reimplementado como cursor editável com navegação por posição (planejado em "Futuro — Cursor Editável no Display" no plano)

#### Infraestrutura de testes

- `test/helpers/pump_app.dart` — Extension `pumpApp` em `WidgetTester` com setup completo (tema, l10n, dark mode) para testes de widget

---

## [Concluída] Etapa 6 — Exibição literal da porcentagem

### CalculatorViewModel

- Novo flag interno `_currentIsPercentage` indica que o operando atual está marcado como porcentagem literal
- `applyPercentage()` agora **não modifica** o valor do `Add2Engine` — apenas ativa o flag de porcentagem
  - Pré-condições: existe operador, há valor digitado, ainda não foi aplicado `%`
- `setOperator()` ao acumular o operando atual, anexa o sufixo `%` quando o flag está ativo
- `inputDigit/inputDoubleZero/inputTripleZero` (refatorados para `_prepareForDigitInput`): digitar após `%` cancela o flag e inicia novo valor para o mesmo operando
- `backspace()` remove primeiro o flag `%` (se ativo); ao restaurar partes anteriores, detecta sufixo `%` e reativa o flag
- `equals()`, `clear()` e `loadSession()` resetam o flag de porcentagem
- `_buildFullExpression()` anexa `%` ao valor atual quando flag ativo (para o evaluator)
- `_formatExpression()` e novo helper `_formatPart()` preservam o sufixo `%` literal ao formatar tokens (ex: `100.00 + 10.00%`)
- `fullDisplayText` exibe `%` literal grudado ao valor atual quando aplicável

### ExpressionEvaluator

- Sem alterações de código — o tokenizer já separava o caractere `%` automaticamente, então `10.00%` (sem espaço) é tokenizado igual a `10.00 %`
- Comportamento contextual de porcentagem mantido: `+/−` calcula percentual sobre o operando anterior; `×/÷` converte para fração

### Histórico

- A expressão persistida em `HistoryEntry` preserva o `%` literal (ex: `100.00 + 10.00%`)
- `loadSession` formata corretamente expressões persistidas com `%`

### Testes

- `calculator_view_model_test.dart` — grupo `percentage` reescrito com 8 testes (display literal em +, −, ×, ÷; sem operador; persistência no timeline; persistência no repository; encadeamento)
- `expression_evaluator_test.dart` — grupo `percentage` ampliado com 5 testes adicionais para `%` literal sem espaço (+, −, ×, ÷, encadeado)
- **Total novos: 13 testes — Total geral: 349 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 7 — Fila de processamento de toques (anti-perda em digitação rápida)

### CalculatorButton

- `onPressed` despachado no `onTapDown` (antes era no `onTap`/`tapUp`) — elimina a latência do reconhecedor de gestos e garante que o toque seja registrado **imediatamente** quando o dedo encosta no botão
- Animações (LED glow, background flash) permanecem nos handlers `tapDown`/`tapUp` e são **independentes** do despacho da ação
- `_handleTap` mantido como no-op para preservar a assinatura do `GestureDetector`
- Comportamento: tocar e arrastar para fora ainda dispara a ação (intencional — toda tecla pressionada conta)

### CalculatorViewModel

- Nova fila de ações `Queue<VoidCallback> _actionQueue` + flag `_isProcessingActions`
- Novo método privado `_runAction(action)`:
  - Se já existe ação em execução (cenário de reentrância síncrona via `notifyListeners`), enfileira e retorna
  - Caso contrário, marca como processando, executa a ação atual e drena a fila enquanto houver pendências, garantindo a ordem
- Métodos públicos do usuário envolvidos em `_runAction`: `inputDigit`, `inputDoubleZero`, `inputTripleZero`, `setOperator`, `applyPercentage`, `equals`, `clear`, `backspace`
- Nenhum `debounce`/`throttle` em qualquer ponto do pipeline

### Testes

- `calculator_view_model_test.dart` — novo grupo `action queue` com 4 testes (50 ações em rajada sem perda, ordem preservada em sequência mista, reentrância via listener síncrono, soma de 25× `1 +`)
- `calculator_keypad_test.dart` — novo grupo `rapid input` com 2 testes (rajada de dígitos sem `pumpAndSettle`, rajada mista de operadores+dígitos)
- `calculator_button_test.dart` — novo grupo `responsiveness` com 2 testes (`onPressed` no tap down via `startGesture`, 3 toques durante animação de glow são todos registrados)
- **Total novos: 8 testes — Total geral: 357 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Concluída] Etapa 8 — Reorganização do keypad: delete contextual e parênteses

### Ajuste pós-implementação — Botão de apagar (`⌫`) na barra de ícones

- Botão `⌫` adicionado à barra de ícones (entre ⏱ e ⚙) — restaura a função de apagar último caractere após a remoção do `⌫` do keypad
- Cor contextual animada: `onSurface` com alpha 0.5 quando não há conteúdo; `primary` (mesma cor dos operadores) quando há conteúdo
- Transição via `TweenAnimationBuilder<Color?>` com `Curves.fastOutSlowIn` (280ms)
- `onPressed` desativado (null) quando dimmed
- Aciona `CalculatorViewModel.backspace`
- 4 novos testes em `calculator_page_test.dart` (presença, dimmed inicial, primary com conteúdo, ação de apagar)
- **Total: 398 testes — 100% verde**

### ExpressionEvaluator (`lib/domain/expression_evaluator.dart`)

- Tokenizer reconhece `(` e `)` como tokens próprios
- Novo método `_resolveParens()` resolve sub-expressões parentizadas recursivamente do interior para o exterior
  - Encontra a innermost paren (último `(` antes do primeiro `)`), avalia o miolo e substitui por seu resultado
  - Suporte a aninhamento ilimitado
  - Validação ergonômica de erros: parênteses desbalanceados (abertos ou fechados sozinhos) e parênteses vazios retornam `null`
- Resolução de porcentagem agora preserva precisão completa (não passa pelo formatador de 2 casas) — corrige cálculos como `1.5%` que antes perdiam precisão
- Resultados intermediários de parênteses também preservam precisão antes de serem reinjetados na expressão pai
- Validação inicial atualizada: primeiro token pode ser `(` (além de número)

### CalculatorViewModel (`lib/ui/calculator/calculator_view_model.dart`)

- **Modelo de estado refatorado** para suportar parênteses como tokens de primeira classe
  - Antes: `_expressionParts` em pares value/operator
  - Agora: `_committed` lista plana de tokens (números, operadores, `(`, `)`) + `_pendingOperator` + `_engineActive`
- Novo método `inputParenthesis()` com toggle inteligente:
  - Insere `(` no início, após operador, ou após outro `(`
  - Insere `)` quando há `(` pendente E o último token é um operando completo (número, `%`, `)`)
  - Após `)`, dígitos são ignorados (sem multiplicação implícita) — usuário precisa pressionar operador primeiro
- Novo getter `openParenCount` — conta `(` menos `)` no expression committed
- Novo getter `hasContent` — true quando há qualquer conteúdo cancelável (committed, operando ativo, operador pendente, timeline com entradas, ou resultado pós-`=`)
- `equals()` agora auto-fecha parênteses não balanceados antes de avaliar
- `backspace()` reescrito para o novo modelo (preservado para uso futuro, sem botão na UI)
- Comportamento existente preservado: prévia de resultado, percentage literal, fila de ações, formatação com separador de milhar

### CalculatorButton (`lib/ui/calculator/widgets/calculator_button.dart`)

- Novo parâmetro `isDimmed: bool` (default false) para variante `functional`
- Quando `isDimmed = true`: cor `onSurface` com alpha 0.5 (mesma dos ícones de ação na barra)
- Quando `isDimmed = false`: cor `primary` (operadores)
- Transição animada via `TweenAnimationBuilder<double>` com curve `Curves.fastOutSlowIn` (280ms)

### CalculatorKeypad (`lib/ui/calculator/widgets/calculator_keypad.dart`)

- Removido botão `⌫` (backspace)
- Adicionado botão `( )` no slot antigo do `⌫`
- Botão `C` agora recebe `clearIsDimmed` para colorir contextualmente
- Assinatura atualizada: `onBackspace` removido, `onParenthesis` adicionado, `clearIsDimmed` adicionado

### CalculatorPage (`lib/ui/calculator/calculator_page.dart`)

- Wiring atualizado: `onParenthesis: vm.inputParenthesis`, `clearIsDimmed: !vm.hasContent`

### Internacionalização

- Novas chaves ARB: `clearAll` e `parenthesis` (en, pt_BR, es)

### Testes

- `expression_evaluator_test.dart` — 12 testes novos (parênteses simples, aninhados, deeply nested, com %, sem espaços, paren com `%` interno, desbalanceados, vazios, sequenciais)
- `calculator_view_model_test.dart` — 19 testes novos (`hasContent` em vários estados, `openParenCount`, `inputParenthesis` em vários contextos, equals com parênteses, auto-close, nested)
- `calculator_keypad_test.dart` — reescrito com helper `buildKeypad`, novos testes para `( )`, ausência do `⌫`, propagação de `clearIsDimmed`
- `calculator_button_test.dart` — novo grupo `isDimmed` (default e animação para primary)
- `calculator_page_test.dart` — substituído teste de backspace por testes de parênteses via teclado e cor contextual do `C`
- **Total: 394 testes — 100% verde**
- `flutter analyze` — zero issues

---

## [Não iniciado] Etapa 9 — UI do Histórico e Configurações

---

## [Não iniciado] Etapa 10 — Polimento, Integração e Revisão Final

---

## [Não iniciado] Etapa 11 — Copiar e Colar

---

## [Não iniciado] Etapa 12 — Cursor Editável no Display
