# Calculadora

## Visão Geral

A calculadora é a tela principal do WevaCalc. Utiliza o conceito **Add2** — entrada automática de 2 casas decimais sem necessidade de pressionar ponto — com suporte a todas as operações básicas.

## Conceito Add2

O diferencial do WevaCalc é a entrada numérica com **2 casas decimais automáticas**. O usuário digita apenas números e o sistema posiciona o separador decimal automaticamente conforme os dígitos são inseridos:

- Digitar `1` → `0.01`
- Digitar `12` → `0.12`
- Digitar `125` → `1.25`
- Digitar `1250` → `12.50`
- Digitar `12500` → `125.00`

O separador decimal é **sempre implícito** — as 2 últimas posições são sempre a parte decimal. Isso torna a entrada de valores monetários extremamente rápida.

### Exemplo de Uso Completo

```
12.50 × 3.00 − 4.45
```

O usuário digita: `1250`, `×`, `300`, `−`, `445`

## Funcionalidades

- **Operações básicas**: Soma (+), subtração (−), multiplicação (×), divisão (÷)
- **Porcentagem (%)**: Cálculo de porcentagem com exibição literal na expressão (ex: `100.00 + 10.00%`). Comportamento contextual: em `+`/`−` aplica percentual sobre o operando anterior; em `×`/`÷` converte para fração.
- **Parênteses inteligentes ( )**: Botão único que decide entre abrir e fechar com base no contexto. Suporte a aninhamento ilimitado. Parênteses não fechados ao pressionar `=` são auto-fechados.
- **Duplo zero (00) e triplo zero (000)**: Atalhos para entrada rápida de zeros
- **Limpar (C)**: Reseta o display e a expressão. Cor contextual: dimmed quando não há conteúdo, primary quando há conteúdo (transição animada).
- **Backspace (⌫)**: Disponível na barra de ícones (não no keypad). Remove o último caractere/token. Cor contextual igual ao botão `C`.
- **Igual (=)**: Avalia a expressão, exibe o resultado, persiste no histórico e prepara nova linha

## Layout

### Display — Timeline

A tela funciona como uma **timeline vertical** com scroll:

- **Linhas superiores** (cor secundária/sutil): Cálculos anteriores da sessão. O usuário pode rolar para cima para ver o que já saiu da tela.
- **Penúltima linha** (texto branco): Cálculo atual sendo digitado pelo usuário.
- **Última linha** (texto cinza): Prévia do resultado em tempo real, exibida apenas quando a expressão forma um cálculo válido.

Conforme o usuário confirma um cálculo (pressiona `=`), a linha atual sobe para o histórico da timeline e uma nova linha de entrada aparece.

#### Performance — Load More

Para sessões longas com muitos cálculos, a timeline exibe apenas as últimas N linhas por padrão. Um botão "load more" no topo permite carregar os cálculos anteriores da sessão sob demanda. Isso evita renderizar centenas de widgets simultaneamente.

### Barra de Ícones

Localizada entre a timeline e o keypad:

- **Ícone de relógio (⏱)**: Abre o histórico salvo. Ao retornar com uma entrada selecionada, a sessão é carregada na timeline.
- **Ícone de backspace (⌫)**: Apaga o último caractere/token. Cor contextual (dimmed sem conteúdo, primary com conteúdo).
- **Ícone de configurações (⚙)**: Abre as configurações

### Keypad

- **Linha 1**: C, %, ( ), ÷
- **Linha 2**: 7, 8, 9, ×
- **Linha 3**: 4, 5, 6, −
- **Linha 4**: 1, 2, 3, +
- **Linha 5**: 000, 00, 0, =

Botões numéricos são neutros. Operadores e o botão `=` usam a cor `primary` (acento). Os botões `C`, `%` e `( )` são botões de ação com cor contextual.

## Regras do Add2

- As 2 últimas posições do número são **sempre** a parte decimal
- O separador decimal é exibido automaticamente — o usuário nunca o digita manualmente
- O botão `⌫` remove o último dígito e reajusta o valor (ex: `12.50` → `1.25`)
- O display respeita a configuração de separador (ponto ou vírgula) definida nas configurações
- Valores são formatados com separador de milhar quando aplicável

## Persistência

Toda operação avaliada (ao pressionar `=`) é salva no histórico (SQLite) com:

- Expressão completa (preserva o `%` literal e parênteses)
- Resultado
- Timestamp

## Fila de Toques

Todo toque em qualquer botão é enfileirado e processado em ordem, mesmo durante animações de feedback. O `onPressed` é despachado no `onTapDown` (sem aguardar `tapUp`), eliminando latência. Não há `debounce`/`throttle` — toques nunca são descartados. Animações (LED glow, flash de fundo) são independentes do despacho da ação.

## Copiar e Colar

O display da calculadora suporta copiar e colar via menu de contexto, ativado por **toque longo** sobre a área da timeline. As opções aparecem condicionalmente conforme o estado atual:

- **Copiar cálculo**: visível quando há expressão na entrada atual; copia o texto completo do display (ex: `1000.00 + 10.00%`)
- **Copiar resultado**: visível quando há prévia ou resultado pós-`=`; copia o valor numérico
- **Copiar histórico**: visível quando a timeline da sessão tem entradas; copia todas no formato `<expressão> = <resultado>` (uma por linha)
- **Colar**: sempre visível; desabilitado quando a área de transferência está vazia

### Validação e Normalização do Colar

A entrada colada passa por um parser que aceita:

- **Inteiros**: padded com `.00` (face value, ex: `1250` → `1250.00`)
- **Decimais com ponto**: preservam as casas decimais (ex: `12.50`, `12.5` → `12.50`)
- **Decimais com vírgula**: vírgula tratada como separador decimal (ex: `12,50`)
- **Separador de milhar**: ignorado (ex: `1.000,00` → `1000.00`, `1,000.00` → `1000.00`)
- **Operadores**: aceita variantes (`*`, `x`, `X` → `×`; `/` → `÷`; `-` → `−`)
- **Expressões**: parsed por completo (ex: `10 + 5`, `(10 + 5) × 2`, `100 + 10%`)

Conteúdo inválido exibe um snackbar com mensagem localizada (`pasteInvalid`). Operações bem-sucedidas exibem o snackbar `copied`.

### Implementação

- `ClipboardService` (interface em `lib/data/services/`) abstrai o `Clipboard` do Flutter, permitindo mock nos testes
- `PasteInputParser` (em `lib/utils/`) converte texto bruto em tokens normalizados (`x.yy`, operadores, parênteses, `%`)
- `CalculatorViewModel` expõe `copyExpression()`, `copyResult()`, `copyHistory()`, `pasteFromClipboard()` e os getters `hasExpression`, `hasResult`, `hasHistory` para a UI
- `CalculatorContextMenu` (widget) renderiza o menu via `showMenu`, ancorado na posição global do toque longo
