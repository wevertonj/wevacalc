# Observações — WevaCalc

Notas importantes, decisões tomadas e pontos de atenção durante a implementação.

---

## Estado Inicial do Projeto

- O projeto foi gerado com `flutter create` e contém o app counter padrão
- O `pubspec.yaml` só tem `flutter`, `cupertino_icons`, `flutter_test` e `flutter_lints`
- O `main.dart` tem o código padrão do counter — será completamente reescrito na Etapa 1
- O `test/widget_test.dart` testa o counter — será removido e substituído pelos testes do WevaCalc
- Dart SDK: `^3.11.4`

---

## Decisões de Arquitetura

### Por que 11 etapas?

Cada etapa foi dimensionada para caber confortavelmente na janela de contexto de 172k tokens da IA, incluindo:

- Leitura dos docs relevantes
- Leitura do código existente das etapas anteriores
- Escrita de testes + implementação
- Execução de `flutter test` e `flutter analyze`

### Ordem das etapas

- **Etapas 1-2** (Fundação + Dados) são pré-requisitos de tudo
- **Etapa 3** (Motor) depende de 1-2 e implementa o core da calculadora
- **Etapa 4** (Lógica Histórico/Config) completa todos os ViewModels e repositories — sem UI
- **Etapa 5** (UI Calculadora) é a primeira tela visual
- **Etapa 6** (Porcentagem literal) ajusta a exibição do `%` na expressão
- **Etapa 7** (Fila de toques) elimina perda de toques em digitação rápida
- **Etapa 8** (Delete contextual + parênteses) reorganiza o keypad
- **Etapa 9** (UI Histórico/Config) conecta as demais telas e navegação
- **Etapa 10** (Polimento) é a revisão final
- **Etapa 11** (Cursor editável) — futuro, não prioritário

### Divisão Lógica vs UI

- **Etapas 1-4**: Toda a lógica de negócio, dados, ViewModels e infraestrutura — sem nenhuma UI
- **Etapas 5-10**: Toda a interface visual, ajustes de comportamento, integração e polimento
- **Etapa 11**: Futuro
- Isso permite que toda a lógica seja testada unitariamente antes de qualquer widget ser criado

### Dependência de pacotes planejada

| Pacote | Uso |
|--------|-----|
| `get_it` | Service locator / DI |
| `sqflite` | Banco de dados local SQLite |
| `path` | Construção de path para o banco |
| `shared_preferences` | Persistência de configurações |
| `flutter_localizations` | Suporte a internacionalização |
| `intl` | Formatação e l10n |
| `mocktail` (dev) | Mocking em testes |
| `sqflite_common_ffi` (dev) | SQLite em memória para testes |

---

## Pontos de Atenção

### Add2Engine

- A lógica Add2 é o diferencial do app e precisa de cobertura de testes extensiva
- Casos especiais: `0`, `00`, `000`, backspace até vazio, overflow de dígitos
- Não existe botão `.` — o separador decimal é sempre implícito (Add2)

### ExpressionEvaluator

- Precisa respeitar precedência matemática correta (× e ÷ antes de + e −)
- O `%` tem comportamento contextual (pode ser porcentagem de um valor)
- Decidir se usamos uma lib de parsing ou implementamos do zero

### Timeline — Performance com sessões longas

- A timeline da calculadora mantém todos os cálculos da sessão em memória
- Para sessões muito longas, apenas as últimas N linhas ficam visíveis
- Um botão "load more" no topo carrega os cálculos anteriores sob demanda
- Isso evita renderizar centenas de widgets em sessões extensas

### Histórico — Paginação e performance

- O histórico pode crescer indefinidamente com o uso do app
- Carregamento paginado (ex: 20 por página) com "load more" no final da lista
- Expressões muito longas são truncadas na lista, com possibilidade de expandir
- Filtro por favoritos também paginado
- Nunca carregar todo o histórico de uma vez

### Histórico — Nome e Favoritos

- O usuário pode dar um nome customizado a qualquer entrada do histórico (opcional, nullable)
- Entradas podem ser favoritadas (★) para acesso rápido
- Favoritos aparecem primeiro na listagem (ordenação: favoritos primeiro, depois por data DESC)
- Filtro: Todos / Apenas favoritos
- Esses campos impactam a entity `HistoryEntry`, o model, o schema SQLite e o repository

### Porcentagem literal na expressão (Etapa 6)

- O `%` deve aparecer **literalmente** na expressão exibida (ex: `1000.00 + 10.00%`)
- A prévia e o resultado final continuam numéricos (ex: `1100.00`)
- O `ExpressionEvaluator` já resolve `%` corretamente — a mudança é apenas na construção da string da expressão no `CalculatorViewModel`
- O histórico persiste a expressão literal com `%`, mantendo `loadSession` compatível

### Fila de toques (Etapa 7)

- Toques nunca devem ser descartados — cada toque é enfileirado e processado em ordem
- Animações de feedback (flash de fundo, glow LED) são **independentes** do despacho da ação
- Despachar a ação no `onTapDown` ou no callback do `Listener`, sem aguardar a animação
- Evitar `IgnorePointer` durante animações e `GestureDetector` reconstruído a cada frame
- Sem `debounce`/`throttle` que descarte eventos

### Parênteses inteligentes (Etapa 8)

- Botão `( )` único que decide entre abrir e fechar com base no contexto:
  - Sem parêntese aberto pendente → abre `(`
  - Com parêntese aberto e último token sendo número/`%`/`)` → fecha `)`
  - Após operador → abre novo `(`
- `ExpressionEvaluator` precisa suportar aninhamento ilimitado respeitando precedência
- Definir comportamento ao pressionar `=` com parênteses não fechados (auto-fechar ou bloquear)

### Botão `C` contextual (Etapa 8)

- Cor padrão (ação) quando não há conteúdo para apagar
- Cor `primary` (mesma dos operadores) quando há conteúdo
- Transição de cor **animada** — nunca mudança "seca"

### ViewModels sem Flutter

- ViewModels usam `ChangeNotifier` que vem de `package:flutter/foundation.dart`
- A doc diz "nunca importam Flutter" — mas `ChangeNotifier` requer import de `foundation.dart`
- Solução possível: importar apenas `dart:core` + `package:flutter/foundation.dart` (foundation não é UI)
- Alternativa: usar `ValueNotifier` que também requer foundation

### Testes de Widget

- Testes de widget precisam de um `MaterialApp` wrapper com tema e l10n configurados
- Criar um helper de teste (`test/helpers/pump_app.dart`) para encapsular esse setup

### SQLite em Testes

- Usar `sqflite_common_ffi` para rodar SQLite em testes unitários (sem device/emulador)
- Configurar `databaseFactory` no setUp dos testes

### Schema SQLite — Sem versionamento por enquanto

- Como não há usuários ainda, o schema pode ser alterado diretamente sem migrations versionadas
- Quando houver versão publicada, migrations serão necessárias para preservar dados dos usuários

---

## Riscos

| Risco | Mitigação |
|-------|-----------|
| ExpressionEvaluator complexo demais | Avaliar uso de lib como `math_expressions` se necessário |
| Animações impactando performance | Usar `const` widgets e `RepaintBoundary` onde necessário |
| L10n setup complexo com gen_l10n | Seguir a doc oficial do Flutter para l10n |
| Testes de SQLite em CI | Garantir que `sqflite_common_ffi` funciona no ambiente |
| Timeline com muitos itens | Limitar itens visíveis + load more para evitar jank |
| Histórico muito grande | Paginação via LIMIT/OFFSET no SQLite |
