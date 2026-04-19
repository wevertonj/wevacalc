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

## [Não iniciado] Etapa 2 — Domínio e Camada de Dados

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
