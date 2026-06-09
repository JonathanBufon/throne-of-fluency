# Contract — `BattleRewardResource.word_drops` + victory screen anuncio

## Resource — `BattleRewardResource`

`battleSystem/resources/battle_reward_resource.gd`

```gdscript
extends Resource
class_name BattleRewardResource

@export var experience := 0
@export var gold := 0
@export var drops: Array[ItemResource] = []
@export var dropQuantities: Array[int] = []
@export var word_drops: Array[WordResource] = []   # NOVO

func get_drop_quantity(index: int) -> int: ...     # existente, sem mudança
```

Sem `wordDropQuantities` — palavra é booleana (sabe / não sabe).

## Integração em `GameData.grant_battle_rewards`

Bloco novo a adicionar dentro do loop `for enemy in enemy_resources`, depois do bloco de `drops`:

```gdscript
for word in reward.word_drops:
    if word == null:
        continue
    if GameData.discover_word(word):
        var new_words := summary.get("new_words", []) as Array
        new_words.append(word.text_en)
        summary["new_words"] = new_words
```

`summary["new_words"]` é inicializado como array vazio no início da função (junto com `drops`, `level_results`).

## Tela de vitória — `battle_scene._format_victory_message`

Adicionar **após** o bloco de drops e **antes** do bloco de `level_results`:

```gdscript
var new_words := reward_summary.get("new_words", []) as Array
if not new_words.is_empty():
    lines.append("Palavras aprendidas: %s" % ", ".join(PackedStringArray(new_words)))
```

Resultado renderizado (exemplo com fireball + 2 palavras novas):

```text
Victory
+10 XP
+5 Gold
+1 Poção
Palavras aprendidas: fire, ball
Hero Lv 2
```

## Configuração de exemplo (validação)

Para validar manualmente, configurar (ou criar) ao menos um `BattleRewardResource.tres` com `word_drops` populado:

```text
battleSystem/data/rewards/echo_shade_reward.tres
  experience = ...
  gold = ...
  drops = [...]
  word_drops = [ res://battleSystem/data/words/fire.tres ]
```

E garantir que algum encontro existente referencia esse reward via `CharacterResource.battleReward`.

## Invariantes preservadas

- `null` em `word_drops` é pulado silenciosamente (igual a `null` em `drops`).
- Palavra já conhecida não entra em `new_words` (graças ao retorno de `discover_word`).
- `save_game()` continua sendo chamado ao final de `grant_battle_rewards`.
- Sem `word_drops` configurado em qualquer encontro do mundo atual, o comportamento de vitória é idêntico ao de hoje (linha "Palavras aprendidas" não aparece quando `new_words` está vazio).
