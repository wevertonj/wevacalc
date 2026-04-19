# Plano de Implementação — WevaCalc

## Resumo

O projeto está dividido em **7 etapas** sequenciais. As **etapas 1-4** cobrem toda a lógica de negócio, dados e infraestrutura (sem UI). As **etapas 5-7** cobrem toda a interface visual, integração e polimento. Cada etapa cabe na janela de contexto de 172k tokens. Todas seguem o fluxo TDD obrigatório (Red → Green → Refactor).

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

## Etapa 2 — Domínio e Camada de Dados

**Objetivo**: Criar as entidades de negócio, enums, models de banco, database helper com migrations e o HistoryRepository.

**Escopo**:

- **Entities**: `Calculation` (expression, result, timestamp)
- **Entities**: `HistoryEntry` (id, expression, result, createdAt)
- **Enums**: `OperationType` (add, subtract, multiply, divide)
- **Enums**: `ThemeModeOption` (light, dark, system)
- **Enums**: `DecimalSeparator` (dot, comma)
- **Models**: `HistoryModel` (toMap, fromMap, toEntity)
- **Database**: `AppDatabase` (SQLite helper, migrations versionadas)
- **Repository**: `HistoryRepository` (interface) — getAll, add, delete, clear
- **Repository**: `HistoryRepositoryImpl` (implementação com SQLite)
- Registrar database e repository no GetIt

**Testes**:

- Unitários: Criação e propriedades das entities
- Unitários: Valores dos enums
- Unitários: `HistoryModel` (serialização/deserialização toMap/fromMap/toEntity)
- Unitários: `HistoryRepositoryImpl` (CRUD com banco em memória)

**Entregável**: Camada de dados completa e testada, pronta para ser consumida pelos ViewModels.

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
  - Parênteses com precedência correta
  - Tratamento de erros (divisão por zero, expressão inválida)
- **NumberFormatter**: Formatação de números com separador configurável (ponto/vírgula) e separador de milhar
- **CalculatorViewModel**:
  - Gerencia a entrada Add2 para o número atual
  - Monta a expressão completa (números + operadores + parênteses)
  - Exibe prévia do resultado em tempo real
  - Confirma cálculo (`=`) e adiciona ao histórico
  - Timeline de cálculos da sessão atual
  - Integração com `HistoryRepository` para persistir resultados
  - Carregamento de sessão a partir do histórico

**Testes**:

- Unitários: `Add2Engine` (todos os cenários de entrada, backspace, zeros, 00)
- Unitários: `ExpressionEvaluator` (operações, precedência, parênteses, %, erros)
- Unitários: `NumberFormatter` (ponto, vírgula, milhar)
- Unitários: `CalculatorViewModel` (estado inicial, inputDigit, operações, =, C, ⌫, timeline, persistência)

**Entregável**: Toda a lógica da calculadora funcional e testada, sem nenhuma dependência de UI.

---

## Etapa 4 — Lógica do Histórico e Configurações

**Objetivo**: Implementar os ViewModels e repositórios restantes — toda a lógica de histórico e configurações, sem nenhuma UI.

**Escopo**:

- **HistoryViewModel**:
  - Carrega lista de histórico do repository
  - Deleta entrada individual
  - Limpa todo o histórico
  - Notifica listeners sobre mudanças
- **SettingsRepository**: Interface + implementação com SharedPreferences
  - Salvar/carregar: ThemeMode, seedColor, decimalSeparator, locale
- **SettingsViewModel**:
  - Gerencia estado das preferências
  - Notifica listeners sobre mudanças
  - Persiste alterações via repository
- Registrar SettingsRepository e ViewModels no GetIt

**Testes**:

- Unitários: `HistoryViewModel` (carregamento, deleção, limpeza, notificações)
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
  - Layout: C, %, ⌫, ÷ | 7, 8, 9, × | 4, 5, 6, − | 1, 2, 3, + | 00, 0, (), =
- **TimelineDisplay**: Widget scrollável mostrando histórico da sessão
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
- Widget: `TimelineDisplay` exibe linhas e faz scroll
- Widget: `CalculatorPage` renderiza corretamente
- Widget: Integração teclado → display (digitar e ver resultado)

**Entregável**: Tela da calculadora funcional com design One UI, animações suaves e testes de widget passando.

---

## Etapa 6 — UI do Histórico e Configurações

**Objetivo**: Construir as telas de histórico e configurações, conectar toda a navegação e integrar com a calculadora.

**Escopo**:

- **HistoryPage**: Tela com lista de sessões salvas
  - Lista em ordem cronológica inversa (mais recente primeiro)
  - Cada item mostra expressão, resultado e data/hora
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
- Atualizar ARBs com strings do histórico e configurações

**Testes**:

- Widget: `HistoryPage` renderiza lista
- Widget: Toque em item navega/carrega na timeline
- Widget: Confirmação antes de limpar histórico
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
Etapa 2 (Domínio/Dados)
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
| **Lógica e Dados** | 1, 2, 3, 4 |
| **Interface Visual** | 5, 6, 7 |

## Estimativa de Complexidade por Etapa

| Etapa | Complexidade | Arquivos novos (aprox.) | Testes (aprox.) |
|-------|-------------|------------------------|-----------------|
| 1 — Fundação | Baixa | ~12 | ~6 |
| 2 — Domínio/Dados | Média | ~10 | ~8 |
| 3 — Motor Calculadora | Alta | ~6 | ~12 |
| 4 — Lógica Histórico/Config | Média | ~6 | ~6 |
| 5 — UI Calculadora | Alta | ~8 | ~8 |
| 6 — UI Histórico/Config | Média | ~8 | ~8 |
| 7 — Polimento | Baixa | ~2 | ~4 |
| **Total** | | **~52** | **~52** |
