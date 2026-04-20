# Plano de Implementação — WevaCalc

## Resumo

O projeto está dividido em **8 etapas** sequenciais. As **etapas 1-4** cobrem toda a lógica de negócio, dados e infraestrutura (sem UI). As **etapas 5-8** cobrem toda a interface visual, integração e polimento. Cada etapa cabe na janela de contexto de 172k tokens. Todas seguem o fluxo TDD obrigatório (Red → Green → Refactor).

---

## Etapa 1 — Fundação e Infraestrutura

**Objetivo**: Estabelecer a base do projeto — dependências, estrutura de pastas, tema, layout, injeção de dependência, rotas e internacionalização.

**Escopo**:

- Atualizar `pubspec.yaml` com todas as dependências (get_it, sqflite, shared_preferences, mocktail, etc.)
- Criar estrutura de pastas (`config/`, `data/`, `domain/`, `ui/`, `utils/`)
- `AppLayout` — constantes de spacing, padding, radius
- `AppColors` — 9 seed colors disponíveis
- `AppTheme` — ThemeData claro e escuro com `ColorScheme.fromSeed()`
- `dependencies.dart` — configuração inicial do GetIt
- `routes.dart` — configuração de rotas (Calculator, History, Settings)
- Setup de internacionalização (l10n.yaml, ARB pt/en, extension `context.l10n`)
- `main.dart` — entry point limpo usando a infraestrutura criada (tela placeholder)

**Testes**:

- Unitários: `AppLayout` (valores de spacing/padding/radius)
- Unitários: `AppColors` (lista de seed colors)
- Unitários: `AppTheme` (geração de ThemeData claro/escuro)

**Entregável**: App compila e roda com tela placeholder, tema funcional, l10n configurado, `flutter test` e `flutter analyze` passando.

---

## Etapa 2 — Domínio e Camada de Dados (base)

**Objetivo**: Criar as entidades de negócio, enums, models de banco, database helper e o HistoryRepository com CRUD básico.

**Escopo**:

- **Entities**: `Calculation` (expression, result, timestamp)
- **Entities**: `HistoryEntry` (id, expression, result, createdAt)
- **Enums**: `OperationType` (add, subtract, multiply, divide)
- **Enums**: `ThemeModeOption` (light, dark, system)
- **Enums**: `DecimalSeparator` (dot, comma)
- **Models**: `HistoryModel` (toMap, fromMap, toEntity)
- **Database**: `AppDatabase` (SQLite helper)
- **Repository**: `HistoryRepository` (interface) — getAll, add, delete, clear
- **Repository**: `HistoryRepositoryImpl` (implementação com SQLite)
- Registrar database e repository no GetIt

**Testes**:

- Unitários: Criação e propriedades das entities
- Unitários: Valores dos enums
- Unitários: `HistoryModel` (serialização/deserialização toMap/fromMap/toEntity)
- Unitários: `HistoryRepositoryImpl` (CRUD com banco em memória)

**Entregável**: Camada de dados base completa e testada.

---

## Etapa 2.1 — Evolução da Camada de Dados (nome, favorito, paginação)

**Objetivo**: Estender a camada de dados com suporte a nome customizado, favoritos e paginação no histórico. Como não há usuários ainda, o schema do banco é alterado diretamente (sem migration versionada).

**Escopo**:

- **HistoryEntry**: Adicionar campos `name` (String?, opcional) e `isFavorite` (bool, default false)
- **HistoryModel**: Adicionar campos `name` e `isFavorite` com serialização
- **Schema SQLite**: Adicionar colunas `name TEXT` e `is_favorite INTEGER NOT NULL DEFAULT 0`
- **HistoryRepository** (interface): Novos métodos:
  - `getPaginated(limit, offset)` — paginação com LIMIT/OFFSET
  - `getFavorites(limit, offset)` — apenas favoritos, paginado
  - `updateName(id, name)` — renomear entrada
  - `toggleFavorite(id)` — alternar favorito
  - `getById(id)` — buscar entrada individual
- **HistoryRepositoryImpl**: Implementação dos novos métodos
- Atualizar fixtures e testes existentes para incluir os novos campos

**Testes**:

- Unitários: `HistoryEntry` com name e isFavorite (criação, copyWith, equality)
- Unitários: `HistoryModel` com novos campos (toMap, fromMap, toEntity, fromEntity)
- Unitários: `HistoryRepositoryImpl` — getPaginated, getFavorites, updateName, toggleFavorite, getById

**Entregável**: Camada de dados completa com suporte a nome, favorito e paginação. Pronta para ser consumida pelos ViewModels.

---

## Etapa 3 — Motor da Calculadora (Add2 + Avaliação de Expressões)

**Objetivo**: Implementar toda a lógica de negócio da calculadora — entrada Add2, parsing e avaliação de expressões, e o CalculatorViewModel.

**Escopo**:

- **Add2Engine**: Lógica de entrada com 2 casas decimais automáticas
  - Inserção de dígitos (`inputDigit`)
  - Backspace com reajuste (`deleteLastDigit`)
  - Formatação do valor atual (`formattedValue`)
  - Reset
- **ExpressionEvaluator**: Parser e avaliador de expressões matemáticas
  - Operações básicas (+, −, ×, ÷)
  - Porcentagem (%)
  - Tratamento de erros (divisão por zero, expressão inválida)
- **NumberFormatter**: Formatação de números com separador configurável (ponto/vírgula) e separador de milhar
- **CalculatorViewModel**:
  - Gerencia a entrada Add2 para o número atual
  - Monta a expressão completa (números + operadores)
  - Exibe prévia do resultado em tempo real
  - Confirma cálculo (`=`) e adiciona ao histórico
  - Timeline de cálculos da sessão atual com "load more" para sessões longas
  - Controle de quantidade visível na timeline (ex: últimas 20 linhas) com carregamento sob demanda
  - Integração com `HistoryRepository` para persistir resultados
  - Carregamento de sessão a partir do histórico

**Testes**:

- Unitários: `Add2Engine` (todos os cenários de entrada, backspace, zeros, 00)
- Unitários: `ExpressionEvaluator` (operações, precedência, %, erros)
- Unitários: `NumberFormatter` (ponto, vírgula, milhar)
- Unitários: `CalculatorViewModel` (estado inicial, inputDigit, operações, =, C, ⌫, timeline, load more na timeline, persistência)

**Entregável**: Toda a lógica da calculadora funcional e testada, sem nenhuma dependência de UI.

---

## Etapa 4 — Lógica do Histórico e Configurações

**Objetivo**: Implementar os ViewModels e repositórios restantes — toda a lógica de histórico e configurações, sem nenhuma UI.

**Escopo**:

- **HistoryViewModel**:
  - Carrega lista de histórico do repository **paginada** (ex: 20 por página)
  - Método `loadMore()` para carregar próxima página
  - Controle de `hasMore` para saber se há mais páginas
  - Deleta entrada individual
  - Limpa todo o histórico com reset de paginação
  - Renomear entrada (`updateName`)
  - Favoritar/desfavoritar entrada (`toggleFavorite`)
  - Filtro: todos / apenas favoritos
  - Notifica listeners sobre mudanças
- **SettingsRepository**: Interface + implementação com SharedPreferences
  - Salvar/carregar: ThemeMode, seedColor, decimalSeparator, locale
- **SettingsViewModel**:
  - Gerencia estado das preferências
  - Notifica listeners sobre mudanças
  - Persiste alterações via repository
- Registrar SettingsRepository e ViewModels no GetIt

**Testes**:

- Unitários: `HistoryViewModel` (carregamento paginado, loadMore, hasMore, deleção, limpeza, rename, toggleFavorite, filtro favoritos, notificações)
- Unitários: `SettingsRepository` (CRUD de preferências)
- Unitários: `SettingsViewModel` (estado inicial, alteração de preferências, persistência)

**Entregável**: Toda a lógica de negócio do app completa e testada. A partir daqui, só resta a UI.

---

## Etapa 5 — UI da Calculadora

**Objetivo**: Construir a interface da tela principal — timeline, keypad e botões com animações e design One UI.

**Escopo**:

- **CalculatorButton**: Botão circular com `AnimatedContainer` para feedback de toque
  - Variantes: numérico (neutro), operador (cor de acento), ação (C, ⌫, =)
- **CalculatorKeypad**: Grid de botões (5 linhas × 4 colunas)
  - Layout: C, %, ⌫, ÷ | 7, 8, 9, × | 4, 5, 6, − | 1, 2, 3, + | 000, 00, 0, =
- **TimelineDisplay**: Widget scrollável mostrando histórico da sessão
  - Exibe apenas as últimas N linhas por padrão
  - Botão "load more" no topo para carregar cálculos anteriores da sessão
  - Linhas anteriores (cor secundária/sutil)
  - Linha atual (branco) — expressão sendo digitada
  - Última linha (cinza) — prévia do resultado
  - Auto-scroll ao adicionar nova linha
  - **AnimatedSwitcher** no display de valores
- **CalculatorPage**: Scaffold principal com layout vertical (timeline + barra de ícones + keypad)
- **Barra de ícones**: ⏱ (histórico) e ⚙ (configurações) — navegação ainda sem destino funcional
- Todas as strings via `context.l10n`
- Todos os valores de layout via `AppLayout`

**Testes**:

- Widget: `CalculatorButton` responde a toque e exibe variantes
- Widget: `CalculatorKeypad` exibe todos os botões
- Widget: `TimelineDisplay` exibe linhas, faz scroll e exibe "load more"
- Widget: `CalculatorPage` renderiza corretamente
- Widget: Integração teclado → display (digitar e ver resultado)

**Entregável**: Tela da calculadora funcional com design One UI, animações suaves e testes de widget passando.

---

## Etapa 6 — UI do Histórico e Configurações

**Objetivo**: Construir as telas de histórico e configurações, conectar toda a navegação e integrar com a calculadora.

**Escopo**:

- **HistoryPage**: Tela com lista de sessões salvas
  - Lista **paginada** em ordem cronológica inversa (mais recente primeiro)
  - Botão/indicador "load more" no final da lista para carregar mais entradas
  - Cada item mostra: nome (se houver), expressão (truncada se muito longa), resultado e data/hora
  - Ícone de favorito (★) em cada item — toque para alternar
  - Filtro: Todos / Favoritos (tabs ou toggle)
  - Toque longo ou menu: renomear entrada (campo de texto para dar nome)
  - Expressões longas exibidas em formato compacto (truncadas com "..." expandível)
  - Animação de entrada para cada item da lista
  - Botão/ação para limpar histórico com diálogo de confirmação
- **Integração Timeline ↔ Histórico**:
  - Ao tocar em uma entrada, a timeline carrega aquela sessão
  - Navegação de volta à calculadora com contexto carregado
- **SettingsPage**:
  - Seção **Tema**: Toggle claro/escuro/sistema + 9 círculos de cor com prévia visual
  - Seção **Formato de número**: Toggle ponto/vírgula
  - Seção **Idioma**: Seletor de idioma
  - Toda mudança reflete imediatamente com animação suave
- **Integração com o App**:
  - `main.dart` carrega preferências antes de iniciar
  - Tema, separador e idioma se propagam para toda a aplicação
  - Troca de tema animada globalmente
- Conectar navegação completa: ⏱ → HistoryPage, ⚙ → SettingsPage
- Atualizar ARBs com strings do histórico e configurações (incluindo favoritos, renomear, load more, etc.)

**Testes**:

- Widget: `HistoryPage` renderiza lista paginada
- Widget: Load more carrega mais entradas
- Widget: Toque em item navega/carrega na timeline
- Widget: Favoritar/desfavoritar atualiza ícone
- Widget: Filtro favoritos mostra apenas favoritos
- Widget: Renomear entrada atualiza nome exibido
- Widget: Confirmação antes de limpar histórico
- Widget: Expressão longa truncada corretamente
- Widget: `SettingsPage` renderiza todas as seções
- Widget: Seleção de cor atualiza tema
- Widget: Toggle de separador atualiza formato

**Entregável**: Todas as telas implementadas, navegação completa e funcional.

---

## Etapa 7 — Polimento, Integração e Revisão Final

**Objetivo**: Refinamento de animações, transições entre telas, revisão geral de qualidade e documentação.

**Escopo**:

- **Animações**:
  - Revisar e refinar todas as animações (curvas, durações)
  - Transição animada entre telas (Hero, page transitions)
  - Animação de troca de tema global suave
- **Integração Final**:
  - Fluxo completo: calculadora → histórico → carregar sessão → continuar cálculo
  - Fluxo completo: configurações → mudar tema/separador → reflexo imediato na calculadora
  - Verificar que preferências persistem ao fechar e reabrir
  - Fluxo: sessão longa na timeline → load more carrega cálculos anteriores
  - Fluxo: histórico paginado → load more → favoritar → filtrar → renomear
- **Qualidade**:
  - `flutter analyze` — zero warnings
  - `flutter test` — 100% verde
  - Revisar cobertura de testes
  - Verificar que nenhuma string está hardcoded
  - Verificar que nenhum valor de layout está hardcoded
- **Documentação**:
  - Atualizar docs se houve desvio da arquitetura planejada

**Testes**:

- Revisão e complementação de testes de widget para fluxos completos
- Testes de integração dos fluxos principais

**Entregável**: App completo, polido, testado e pronto para uso.

---

## Diagrama de Dependências entre Etapas

```
Etapa 1 (Fundação)
    │
    ▼
Etapa 2 (Domínio/Dados base)
    │
    ▼
Etapa 2.1 (Dados: nome, favorito, paginação)
    │
    ▼
Etapa 3 (Motor Calculadora)
    │
    ▼
Etapa 4 (Lógica Histórico/Config)     ← Toda lógica pronta
    │
    ▼
Etapa 5 (UI Calculadora)
    │
    ▼
Etapa 6 (UI Histórico/Config)
    │
    ▼
Etapa 7 (Polimento)
```

## Resumo da Divisão

| Foco | Etapas |
|------|--------|
| **Lógica e Dados** | 1, 2, 2.1, 3, 4 |
| **Interface Visual** | 5, 6, 7 |

## Estimativa de Complexidade por Etapa

| Etapa | Complexidade | Arquivos novos (aprox.) | Testes (aprox.) |
|-------|-------------|------------------------|-----------------|
| 1 — Fundação | Baixa | ~12 | ~6 |
| 2 — Domínio/Dados base | Média | ~10 | ~8 |
| 2.1 — Dados (nome, favorito, paginação) | Baixa-Média | ~0 (edições) | ~10 |
| 3 — Motor Calculadora | Alta | ~6 | ~12 |
| 4 — Lógica Histórico/Config | Média | ~6 | ~8 |
| 5 — UI Calculadora | Alta | ~8 | ~8 |
| 6 — UI Histórico/Config | Alta | ~10 | ~12 |
| 7 — Polimento | Baixa | ~2 | ~4 |
| **Total** | | **~54** | **~68** |

---

## Futuro — Cursor Editável no Display

**Objetivo**: Implementar um cursor navegável no display da calculadora, permitindo ao usuário mover a posição de inserção e editar valores em qualquer ponto da expressão.

**Motivação**: Atualmente a entrada só acontece no final da expressão. Com um cursor editável, o usuário pode corrigir erros no meio do cálculo sem precisar apagar tudo.

**Escopo**:

- **Modelo de posição do cursor**:
  - `cursorPosition` (int) no CalculatorViewModel indicando o índice de inserção na expressão
  - Mover cursor para esquerda/direita (botões ou gesto de toque)
  - Toque direto em um caractere do display posiciona o cursor naquele ponto
  - Cursor sempre entre caracteres (não sobrepõe)

- **Visual do cursor**:
  - Barra vertical piscante (blinking) na posição atual, usando Timer (não AnimationController) para não bloquear `pumpAndSettle`
  - Altura proporcional ao fontSize animado atual
  - Cor: `colorScheme.primary`
  - Animação suave ao mover de posição (slide horizontal com `TweenAnimationBuilder`)

- **Integração com AnimatedInputDisplay**:
  - Novo prop `cursorPosition` (int?) — se null, sem cursor visível
  - Novo prop `cursorColor` (Color)
  - O cursor é inserido entre os widgets de caractere na posição indicada
  - GestureDetector em cada caractere para detectar toque e callback `onCharTap(int index)`

- **Integração com CalculatorViewModel**:
  - `inputDigit()` insere na `cursorPosition` em vez de sempre no final
  - `deleteLastDigit()` (backspace) apaga o caractere antes do cursor
  - `selectOperator()` insere operador na posição do cursor
  - Após inserção/deleção, cursor avança/recua automaticamente
  - `moveCursorLeft()` e `moveCursorRight()` com bounds checking

- **UX no keypad**:
  - Dois novos botões (◀ ▶) ou gesto de swipe horizontal no display para mover o cursor
  - Alternativa: long-press no display ativa modo de edição com cursor

- **Testes**:
  - Unitários: ViewModel com cursorPosition (inserção no meio, backspace no meio, mover cursor, bounds)
  - Widget: AnimatedInputDisplay com cursor visível na posição correta
  - Widget: Toque em caractere posiciona cursor
  - Widget: Integração keypad → edição no meio da expressão
