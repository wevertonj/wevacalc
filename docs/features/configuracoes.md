# Configurações

## Visão Geral

Tela de configurações acessada pelo ícone de engrenagem (⚙) na tela principal da calculadora.

## Funcionalidades

### Tema

- **Modo**: Claro, Escuro ou Sistema
- **Seed Color**: 9 opções de cor base para gerar a paleta via `ColorScheme.fromSeed()`
- A troca de tema e cor deve ser animada suavemente em tempo real

### Formato de Número

- **Separador decimal**: Opção de exibir como ponto (`12.50`) ou vírgula (`12,50`)
- O separador de milhar se ajusta de acordo (ponto → vírgula de milhar; vírgula → ponto de milhar)
- A mudança é aplicada imediatamente no display da calculadora

### Idioma

- Seleção do idioma do app
- Suporte multi-idioma via arquivos ARB
- Mudança aplicada imediatamente

## Persistência

As preferências do usuário (modo de tema, seed color, separador decimal, idioma) são armazenadas localmente usando SharedPreferences ou similar, para que sejam restauradas ao reabrir o app.

## UI

- Seções organizadas com títulos claros
- Seleção de cor com prévia visual (círculos coloridos)
- Toggle de tema com transição animada
- Toda mudança reflete imediatamente no app com animação suave
