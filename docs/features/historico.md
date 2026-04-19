# Histórico

## Visão Geral

Todas as operações realizadas na calculadora são persistidas localmente em banco SQLite. O histórico é acessado pelo ícone de relógio (⏱) na tela principal.

## Funcionalidades

- **Listagem**: Exibe as sessões de cálculos salvas em ordem cronológica (mais recente primeiro)
- **Detalhes**: Cada entrada mostra a expressão, resultado e data/hora
- **Carregar na timeline**: Ao tocar em uma entrada do histórico, a timeline da calculadora é carregada até aquela linha, exibindo todo o contexto da sessão. O usuário pode continuar o cálculo a partir dali.
- **Limpar histórico**: Opção para apagar todo o histórico

## Interação com a Timeline

O histórico se integra diretamente com a timeline da calculadora:

1. O usuário toca no ícone de relógio (⏱)
2. A lista de sessões do histórico aparece
3. Ao tocar em uma entrada, a timeline carrega todas as linhas daquela sessão
4. O usuário pode rolar pelas linhas e tocar em uma para continuar o cálculo a partir daquele ponto

## Banco de Dados (SQLite)

### Schema

```sql
CREATE TABLE history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  expression TEXT NOT NULL,
  result TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
```

### Migrations

Migrations versionadas para evolução segura do schema:

```dart
await db.execute('CREATE TABLE history (...)'); // v1
```

## Acesso a Dados

O acesso é feito exclusivamente via **Repository Pattern**:

```
UI → ViewModel → HistoryRepository (interface) → HistoryRepositoryImpl → SQLite
```

A UI nunca acessa o banco diretamente.

## UI

- Lista com animações de entrada para cada item
- Ação de limpar com confirmação
- Transição animada entre lista de histórico e timeline carregada
- Scroll suave com comportamento natural
