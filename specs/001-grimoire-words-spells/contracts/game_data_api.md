# Contract — `GameData` (autoload)

Mudanças públicas em `world/cripta/game_data.gd`. **Nenhuma assinatura existente é alterada.** Apenas extensão de comportamento e do schema do summary.

## Métodos existentes consumidos por esta feature (sem mudança)

```gdscript
GameData.discover_word(word: WordResource) -> bool
GameData.has_word(word: WordResource) -> bool
GameData.get_known_recipes() -> Array[SpellRecipeResource]
GameData.is_spell_prepared(recipe: SpellRecipeResource) -> bool
GameData.can_prepare(recipe: SpellRecipeResource) -> bool
GameData.prepare_spell(recipe: SpellRecipeResource) -> bool   # auto-saves
GameData.find_recipe_for_words(input_words: Array) -> SpellRecipeResource
GameData.save_game() -> bool
GameData.load_game() -> bool
```

## Estado público lido pela UI

```gdscript
GameData.known_words: Array[WordResource]
GameData.prepared_spells: Array[SpellRecipeResource]
GameData.ALL_SPELL_RECIPES: Array[SpellRecipeResource]   # constante
GameData.last_battle_reward: Dictionary
```

## Mudança de comportamento — `grant_battle_rewards`

**Assinatura inalterada**:

```gdscript
GameData.grant_battle_rewards(enemy_resources: Array[CharacterResource]) -> Dictionary
```

**Schema do `Dictionary` retornado** (chave nova destacada):

```gdscript
{
    "experience":    int,
    "gold":          int,
    "drops":         Dictionary,           # name → quantity
    "level_results": Array[Dictionary],
    "new_words":     Array[String],        # NOVO — text_en das palavras recém-aprendidas
}
```

**Pós-condições**:
- Para cada `enemy.battleReward.word_drops`, palavras ainda desconhecidas são adicionadas a `GameData.known_words` (via `discover_word`).
- `new_words` contém **apenas** as palavras de fato aprendidas nesta vitória (não as que o jogador já conhecia).
- `save_game()` continua sendo chamado ao final (já existente).
- `last_battle_reward` é atualizado com o novo schema.

**Invariantes** (não devem regredir):
- `known_words` nunca tem duplicatas.
- `null` em `word_drops` é silenciosamente ignorado.
- Falha em load → defaults aplicados sem crash.
