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

### Por que 7 etapas?

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
- **Etapa 6** (UI Histórico/Config) conecta todas as telas e navegação
- **Etapa 7** (Polimento) é a revisão final

### Divisão Lógica vs UI

- **Etapas 1-4**: Toda a lógica de negócio, dados, ViewModels e infraestrutura — sem nenhuma UI
- **Etapas 5-7**: Toda a interface visual, integração e polimento
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
- Casos especiais: `0`, `00`, backspace até vazio, overflow de dígitos
- O botão `()` substitui o ponto decimal — não existe botão `.`

### ExpressionEvaluator

- Precisa respeitar precedência matemática correta (× e ÷ antes de + e −)
- Parênteses podem ser aninhados
- O `%` tem comportamento contextual (pode ser porcentagem de um valor)
- Decidir se usamos uma lib de parsing ou implementamos do zero

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

---

## Riscos

| Risco | Mitigação |
|-------|-----------|
| ExpressionEvaluator complexo demais | Avaliar uso de lib como `math_expressions` se necessário |
| Animações impactando performance | Usar `const` widgets e `RepaintBoundary` onde necessário |
| L10n setup complexo com gen_l10n | Seguir a doc oficial do Flutter para l10n |
| Testes de SQLite em CI | Garantir que `sqflite_common_ffi` funciona no ambiente |
