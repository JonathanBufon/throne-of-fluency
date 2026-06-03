# Phase 1 — Data Model

**Feature**: Grimório — Coletar Palavras, Preparar e Lançar Magias
**Date**: 2026-06-02

Esta seção documenta as entidades de dados envolvidas, com diferenciação entre **existentes na foundation** (commit `4aab1fd`) e **novas/modificadas** nesta fase.

---

## Entidades

### `WordResource` *(existente — sem mudança)*

`battleSystem/resources/word_resource.gd`

| Campo | Tipo | Origem | Notas |
|---|---|---|---|
| `text_en` | `String` | foundation | Palavra ensinada (ex: "fire"). Identidade conceitual. |
| `text_pt` | `String` | foundation | Tradução exibida na UI. |
| `part_of_speech` | `int` (enum NOUN/VERB/ADJECTIVE/OTHER) | foundation | Opcional; exibido na aba Palavras quando definido. |
| `icon` | `Texture2D` | foundation | Opcional; **não usado nesta fase** (P2/futuro). |

**Igualdade**: por referência de `Resource` (mesma `.tres` carregada). `GameData.known_words.has(word)` funciona com instâncias preloaded.

---

### `SpellRecipeResource` *(existente — sem mudança)*

`battleSystem/resources/spell_recipe_resource.gd`

| Campo | Tipo | Origem | Notas |
|---|---|---|---|
| `words` | `Array[WordResource]` | foundation | 2-3 palavras (foundation valida via `matches`). |
| `result_skill` | `SkillResource` | foundation | A skill que será executada quando a magia for cast em batalha. |
| `description` | `String` | foundation | Lore/dica. Exibido como tooltip ou linha abaixo do nome na aba Receitas. |

**Helpers existentes (não duplicar)**:
- `matches(input_words: Array) -> bool` — multiset, ordem-independente.
- `is_fully_known(known: Array[WordResource]) -> bool`.
- `get_known_word_count(known: Array[WordResource]) -> int`.

---

### `SkillResource` *(existente — sem mudança)*

`battleSystem/resources/skillResource.gd`

Reaproveitado como `result_skill` de cada receita. Nenhum campo novo. Cast em batalha passa pela mesma pipeline de qualquer outra skill (custo de MP, animação, dano/cura).

---

### `BattleRewardResource` *(MODIFICAR)*

`battleSystem/resources/battle_reward_resource.gd`

| Campo | Tipo | Status | Notas |
|---|---|---|---|
| `experience` | `int` | existente | — |
| `gold` | `int` | existente | — |
| `drops` | `Array[ItemResource]` | existente | — |
| `dropQuantities` | `Array[int]` | existente | — |
| `word_drops` | `Array[WordResource]` | **NOVO** | Palavras dropadas quando o inimigo é derrotado. Sem campo de quantidade (palavra é booleana). |

**Validação**: `null` entries em `word_drops` são silenciosamente puladas em `grant_battle_rewards` (consistente com tratamento atual de `drops`).

---

### `GameData` *(estender comportamento — API atual mantida)*

`world/cripta/game_data.gd` (autoload)

**Estado relevante (todo existente)**:

| Campo | Tipo | Origem | Notas |
|---|---|---|---|
| `known_words` | `Array[WordResource]` | foundation | Sem duplicatas (garantido por `discover_word`). |
| `prepared_spells` | `Array[SpellRecipeResource]` | foundation | Sem duplicatas (garantido por `can_prepare` + `is_spell_prepared`). |
| `last_battle_reward` | `Dictionary` | existente | Summary da última batalha. Schema ganha `new_words`. |

**Métodos existentes usados (sem mudança de assinatura)**:
- `discover_word(word: WordResource) -> bool` — retorna `true` se aprendeu agora, `false` se já conhecia.
- `has_word(word: WordResource) -> bool`
- `get_known_recipes() -> Array[SpellRecipeResource]`
- `is_spell_prepared(recipe: SpellRecipeResource) -> bool`
- `can_prepare(recipe: SpellRecipeResource) -> bool`
- `prepare_spell(recipe: SpellRecipeResource) -> bool` — auto-saves.
- `find_recipe_for_words(input_words: Array) -> SpellRecipeResource`

**Métodos modificados**:
- `grant_battle_rewards(enemy_resources)` — adicionar bloco que itera `reward.word_drops`, chama `discover_word`, e popula `summary["new_words"]: Array[String]` com os `text_en` de palavras recém-aprendidas. Auto-save ao final já existe.

**Schema do `summary` (retornado por `grant_battle_rewards`)**:

| Chave | Tipo | Status | Notas |
|---|---|---|---|
| `experience` | `int` | existente | — |
| `gold` | `int` | existente | — |
| `drops` | `Dictionary[String, int]` | existente | Nome do item → quantidade. |
| `level_results` | `Array[Dictionary]` | existente | — |
| `new_words` | `Array[String]` | **NOVO** | `text_en` das palavras recém-aprendidas nesta vitória. Vazio se nada novo. |

---

## Relacionamentos

```text
BattleRewardResource
  ├── drops:       Array[ItemResource]       (existente)
  └── word_drops:  Array[WordResource]       (NOVO)

CharacterResource.battleReward → BattleRewardResource

GameData
  ├── known_words:     Array[WordResource]
  └── prepared_spells: Array[SpellRecipeResource]
                         └── result_skill → SkillResource
                         └── words[]      → WordResource ⊆ known_words

SpellRecipeResource.matches(known_words) → bool
SpellRecipeResource.is_fully_known(known_words) → bool
```

---

## Ciclo de vida

### Palavra (`WordResource`)

1. **Definida** em `battleSystem/data/words/*.tres` (5 palavras na foundation).
2. **Atribuída** a um `BattleRewardResource.word_drops` (1 ou mais encontros para validação).
3. **Descoberta** quando o jogador vence o encontro: `GameData.discover_word(w)` retorna `true` na primeira vitória; `false` em vitórias subsequentes.
4. **Persistida** em `save.json` como path do resource.
5. **Consumida** (em modo leitura) pela aba Palavras do grimório e pela aba Preparar.

Não há remoção. Palavra aprendida fica aprendida (até `reset` futuro fora desta spec).

### Receita (`SpellRecipeResource`)

1. **Registrada** em `GameData.ALL_SPELL_RECIPES` (lista hardcoded, 2 receitas na foundation).
2. **Filtrada** dinamicamente na aba Receitas:
   - oculta se `get_known_word_count(known_words) == 0`;
   - parcial (palavras desconhecidas mascaradas como "???") se `0 < count < total`;
   - disponível se `is_fully_known(known_words)`.
3. **Avaliada** na aba Preparar via `find_recipe_for_words(selecionadas)`.
4. **Promovida** a `prepared_spells` via `prepare_spell(recipe)` (auto-save).
5. **Cast** em batalha como `result_skill` (pipeline normal de `SkillResource`).

Receita não é "consumida" no cast — fica preparada para reuso (até futura mecânica de slots/fade, fora desta spec).

### Magia preparada (entrada em `prepared_spells`)

1. **Adicionada** por `prepare_spell` se `can_prepare` aprova (não duplica).
2. **Exibida** no submenu Magia em batalha.
3. **Cast** via `command_selected.emit(recipe.result_skill)` no `CommandMenu`.
4. **Persistida** em `save.json` (paths das receitas).
5. **Nunca removida** nesta spec (edit/excluir é non-objective).

### `last_battle_reward` (transient + last summary)

1. Sobrescrito a cada `grant_battle_rewards`.
2. Lido pela tela de vitória em `battle_scene._format_victory_message`.
3. `new_words` é a única chave nova nesta spec.
4. Não persistido em save (só vive em memória; é só o sumário da última batalha).

---

## Regras de validação

| Regra | Onde é aplicada | Erro/comportamento |
|---|---|---|
| Word duplicada não entra em `known_words` | `GameData.discover_word` (já existe) | retorna `false`; nada acontece. |
| Receita só prepara se todas as palavras conhecidas | `GameData.can_prepare` (já existe) | retorna `false`. UI mostra feedback "Combinação não forma magia". |
| Receita não duplica em `prepared_spells` | `GameData.is_spell_prepared` (já existe) | UI mostra "Magia já preparada". |
| `word_drops` com `null` entries | `grant_battle_rewards` (novo bloco) | pula silenciosamente (consistente com `drops`). |
| Save corrompido cai pros defaults | `GameData.load_game` (já existe) | retorna `false`; `_ready` chama `reset_default_*`. |
| Combinação tem 2-3 palavras | UI da aba Preparar | feedback "Selecione entre 2 e 3 palavras." (não chama `find_recipe_for_words`). |
