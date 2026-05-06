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

## Cursor Editável

O display suporta um cursor de edição que permite navegar e modificar a expressão em qualquer ponto, não apenas no final.

### Movimentação do cursor

- **Toque em um caractere**: posiciona o cursor imediatamente antes do caractere tocado (`onCharTap` → `setCursorPosition`)
- **Swipe horizontal no display**: arrastar para a esquerda move o cursor à direita; arrastar para a direita move à esquerda (threshold ±200 px/s)
- **Apagar do teclado** (⌫) sempre opera relativo à posição atual do cursor
- Ao mover o cursor para fora do final, a calculadora entra em **modo de edição mid-expression**; ao retornar ao final, volta ao modo normal automaticamente

### Modo de edição

No modo de edição o display permanece **consciente do bloco numérico** sob o cursor — toda inserção ou remoção de dígito reaplica a formatação Add2 ao bloco circundante (separador decimal, separador de milhar e o `%` opcional são preservados). Uma vez ativado (cursor movido para fora do final), o modo de edição **persiste** até `=`, `C`, carregamento de histórico ou colagem.

- **Dígitos** (`0`–`9`, `00`, `000`) são inseridos na posição do cursor dentro do bloco numérico atual; o bloco inteiro é reformatado via Add2 (`23.71` em vez de `2,371` quando se digita `1` após `2,37`)
- **Operadores** (`+`, `−`, `×`, `÷`) **partem o bloco em duas metades** quando há dígitos em ambos os lados do cursor (`12.50` cursor entre `2` e `.` + `+` → `0.12 + 0.50`); nas bordas (cursor sem dígitos antes ou sem dígitos depois) o operador é inserido literalmente como ` op `
- **`%`** é anexado ao final do bloco numérico atual (no-op quando o bloco já termina em `%`)
- **`( )`** salta para o fim do bloco numérico e então decide entre `(` e `)` com base no caractere imediatamente à esquerda do cursor
- **⌫** dentro de um bloco numérico remove um dígito e reformata o bloco via Add2; quando o caractere imediatamente antes do cursor é parte de um operador-com-espaços (` op ` entre dois blocos), o operador é removido inteiro e os blocos vizinhos são **mesclados** via Add2 (raws normalizados via `int.parse` para descartar zeros de padding); fora dos blocos remove o caractere literal
- **`=`** avalia o texto editado, normalizando separadores de milhar e o separador decimal configurado, e grava o resultado na timeline
- **C** sai do modo de edição e limpa toda a sessão

A prévia de resultado (`previewResult`) é recalculada em tempo real a partir do texto editado. O `ExpressionEvaluator` retorna `null` para expressões malformadas (operador pendurado, parêntese vazio etc.), mantendo a UI segura contra exceções durante a edição.

### Visual do cursor

O cursor é uma barra vertical fina (2 px de largura) na cor `colorScheme.primary`, com altura proporcional ao `fontSize` atual do display. O blink usa `Timer.periodic(530ms)` em vez de `AnimationController`, evitando que widget tests com `pumpAndSettle` fiquem bloqueados.

Em modo **multiline** (quando a expressão estoura a largura e o display usa `Wrap`), o cursor continua sendo renderizado: ele é injetado no fluxo de tokens de modo a ficar preso ao grupo numérico atual (impede quebra de linha entre dígito e cursor) ou como token próprio em fronteiras (espaço/operador, ponto natural de quebra).

### Implementação

- `CalculatorViewModel` mantém `cursorPosition` (int), `_editText` (String?) e `_atEnd` (bool)
- O bloco numérico sob o cursor é detectado pela faixa máxima de caracteres `[0-9.,%]` contígua (`_findNumberBlock`); inserções e remoções operam sobre os dígitos brutos do bloco e o resultado é re-formatado via `NumberFormatter.format` aplicando Add2
- **Ancoragem do cursor por dígitos-à-direita**: após cada reformatação Add2, o cursor é restaurado de modo a preservar exatamente o mesmo número de dígitos à sua direita dentro do bloco. Como Add2 padroniza com zero à esquerda (raw `20` → `0.20`), o lado direito é a referência estável; ancorar pela esquerda faria o cursor pular a cada padding/depadding
- `_normalizeForEvaluator` converte o texto formatado para a forma canônica esperada pelo `ExpressionEvaluator`
- `AnimatedInputDisplay` recebe `cursorPosition`, `cursorColor` e `onCharTap` e renderiza o cursor entre os widgets de caractere
- `TimelineDisplay` envolve o display em `GestureDetector.onHorizontalDragEnd` para o swipe
