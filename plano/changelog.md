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
- ARBs criados: `app_en.arb`, `app_pt.arb`, `app_pt_BR.arb`, `app_es.arb`
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

## [Não iniciado] Etapa 3 — Motor da Calculadora

---

## [Não iniciado] Etapa 4 — Lógica do Histórico e Configurações

---

## [Não iniciado] Etapa 5 — UI da Calculadora

---

## [Não iniciado] Etapa 6 — UI do Histórico e Configurações

---

## [Não iniciado] Etapa 7 — Polimento, Integração e Revisão Final
