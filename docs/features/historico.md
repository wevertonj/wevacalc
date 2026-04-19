# Histórico

## Visão Geral

Todas as operações realizadas na calculadora são persistidas localmente em banco SQLite. O histórico é acessado pelo ícone de relógio (⏱) na tela principal.

## Funcionalidades

- **Listagem paginada**: Exibe as sessões de cálculos salvas em ordem cronológica (mais recente primeiro), carregadas em blocos (ex: 20 por vez) com "load more"
- **Detalhes**: Cada entrada mostra nome (se houver), expressão (truncada se longa), resultado e data/hora
- **Nome customizado**: O usuário pode dar um nome a qualquer entrada do histórico (ex: "Compras do mês", "Orçamento reforma")
- **Favoritos**: Entradas podem ser favoritadas (★) para acesso rápido. Filtro disponível: Todos / Favoritos
- **Expressões longas**: Exibidas em formato compacto (truncadas com "..."), expandíveis ao toque
- **Carregar na timeline**: Ao tocar em uma entrada do histórico, a timeline da calculadora é carregada até aquela linha, exibindo todo o contexto da sessão. O usuário pode continuar o cálculo a partir dali.
- **Limpar histórico**: Opção para apagar todo o histórico com confirmação

## Interação com a Timeline

O histórico se integra diretamente com a timeline da calculadora:

1. O usuário toca no ícone de relógio (⏱)
2. A lista de sessões do histórico aparece (paginada)
3. Ao tocar em uma entrada, a timeline carrega todas as linhas daquela sessão
4. O usuário pode rolar pelas linhas e continuar o cálculo a partir daquele ponto

## Performance

### Paginação

O histórico é carregado em páginas para evitar problemas de performance:

- Cada página carrega N entradas (ex: 20)
- "Load more" no final da lista carrega a próxima página
- O filtro de favoritos também é paginado
- Nunca carrega todo o histórico de uma vez

### Expressões longas

Expressões muito extensas são truncadas na listagem para evitar impacto na renderização. O usuário pode expandir para ver a expressão completa.

## Banco de Dados (SQLite)

### Schema

```sql
CREATE TABLE history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  expression TEXT NOT NULL,
  result TEXT NOT NULL,
  name TEXT,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);
```

### Queries de paginação

```sql
-- Página de histórico
SELECT * FROM history ORDER BY created_at DESC LIMIT ? OFFSET ?

-- Apenas favoritos
SELECT * FROM history WHERE is_favorite = 1 ORDER BY created_at DESC LIMIT ? OFFSET ?
```

## Acesso a Dados

O acesso é feito exclusivamente via **Repository Pattern**:

```
UI → ViewModel → HistoryRepository (interface) → HistoryRepositoryImpl → SQLite
```

A UI nunca acessa o banco diretamente.

### Métodos do Repository

- `getAll()` — todos os registros (uso interno)
- `getPaginated(limit, offset)` — página de registros
- `getFavorites(limit, offset)` — favoritos paginados
- `add(entry)` — adicionar entrada
- `delete(id)` — remover entrada
- `clear()` — limpar tudo
- `updateName(id, name)` — renomear entrada
- `toggleFavorite(id)` — alternar favorito
- `getById(id)` — buscar entrada individual

## UI

- Lista paginada com "load more" no final
- Animações de entrada para cada item
- Ícone de favorito (★) em cada item
- Filtro: Todos / Favoritos
- Ação de renomear via toque longo ou menu
- Expressões longas truncadas, expandíveis
- Ação de limpar com confirmação
- Transição animada entre lista de histórico e timeline carregada
- Scroll suave com comportamento natural
