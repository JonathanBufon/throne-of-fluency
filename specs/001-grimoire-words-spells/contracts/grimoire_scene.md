# Contract — Grimoire scene + `WorldGrimoire` autoload

Define a superfície pública da nova cena `ui/grimoire/world_grimoire.tscn` e do autoload `WorldGrimoire`.

## Autoload

```text
project.godot:
  [autoload]
  WorldGrimoire = "*res://ui/grimoire/world_grimoire.gd"
```

## Input action

```text
project.godot:
  [input]
  grimoire = { events = [ InputEventKey(KEY_G) ] }
```

## `WorldGrimoire` (autoload script — `ui/grimoire/world_grimoire.gd`)

Espelha o contrato de `WorldInventory`:

```gdscript
extends CanvasLayer

# Constantes herdadas do padrão WorldInventory.
const OVERWORLD_PATH_PREFIX := "res://world/"
const EXCLUDED_PATH_FRAGMENTS := ["tittle_screen", "troca_fase"]

# Estado interno.
var _is_open: bool

# API pública (consumida pelo botão da HUD e pela tab do inventário).
func open() -> void           # idempotente; ignora se !_can_open()
func close() -> void          # idempotente
func toggle() -> void
func is_open() -> bool

# Internos análogos a WorldInventory.
func _unhandled_input(event: InputEvent) -> void   # consome action "grimoire" + "ui_cancel" quando aberto
func _can_open() -> bool                            # mesmas regras do inventário
```

**Comportamento garantido**:
- `open()` faz `get_tree().paused = true` e mostra o `CanvasLayer`.
- `close()` faz `get_tree().paused = false` e esconde.
- `_unhandled_input` consome o evento (`set_input_as_handled`) para não vazar para o overworld.
- Não abre se o cenário atual não está em `res://world/` ou contém `tittle_screen`/`troca_fase`.
- Não abre se outra UI bloqueante (diálogo, batalha) estiver consumindo o tree antes.

## Cena raiz (`ui/grimoire/world_grimoire.tscn`)

```text
WorldGrimoire (CanvasLayer, layer=20, process=ALWAYS)
└── Root (PanelContainer)
    └── GrimoireTabs (TabContainer)
        ├── Words   (cena: grimoire_tab_words.tscn)
        ├── Recipes (cena: grimoire_tab_recipes.tscn)
        └── Prepare (cena: grimoire_tab_prepare.tscn)
```

## Cenas-tabs reutilizáveis

Cada aba é uma cena própria (`Control`), permitindo embedding tanto no autoload quanto na tab do inventário.

### `grimoire_tab_words.tscn` — aba Palavras

Renderiza `GameData.known_words` em uma lista vertical. Cada item: `text_en`, `text_pt`, classe gramatical (se definida).

Estado vazio: `%EmptyLabel.text = "Você ainda não conhece nenhuma palavra. Vença batalhas para aprender."`

Lê dados em `_ready` e em um signal `refresh()` público que o autoload chama no `open()`.

### `grimoire_tab_recipes.tscn` — aba Receitas

Renderiza cada `recipe` em `GameData.ALL_SPELL_RECIPES` filtrada por `recipe.get_known_word_count(GameData.known_words) > 0`. Palavras desconhecidas viram `"???"`. Marca como `"Preparada ✓"` se `GameData.is_spell_prepared(recipe)`.

Estado vazio: `"Sem palavras, sem receitas conhecidas."`

### `grimoire_tab_prepare.tscn` — aba Preparar

Layout: lista de checkboxes/toggle buttons (uma por palavra em `known_words`) + botão `Preparar` + `%FeedbackLabel`.

**Signal emitido**:

```gdscript
signal spell_prepared(recipe: SpellRecipeResource)
```

Emitido após `GameData.prepare_spell(recipe)` retornar `true`. Autoload escuta para opcionalmente disparar SFX ou refresh global.

**Pressed handler** segue o pseudocódigo de R7 (research.md).

Estado vazio (sem palavras): botão Preparar desabilitado + label `"Aprenda palavras antes de preparar magias."`

## Contrato de embedding (inventário)

A tab "Grimório" no `WorldInventory` instancia **a mesma cena `GrimoireTabs` (TabContainer)** como filho da tab. Pseudocódigo:

```gdscript
# ui/hud/world_inventory.gd  (modificado)
@onready var tab_container: TabContainer = %TabContainer
@onready var grimoire_tab: Control = %GrimoireTab

const GRIMOIRE_TABS_SCENE := preload("res://ui/grimoire/grimoire_tabs.tscn")

func _ready() -> void:
    # ... existente ...
    var embedded := GRIMOIRE_TABS_SCENE.instantiate()
    grimoire_tab.add_child(embedded)
```

A cena embarcada NÃO instancia o `CanvasLayer` raiz e NÃO consome `_unhandled_input` — apenas o conteúdo do `TabContainer{Words, Recipes, Prepare}` é instanciado.

## Padrão de pause

Idêntico ao `WorldInventory`:
- `get_tree().paused = true` quando aberto.
- Todos os nós da cena têm `process_mode = PROCESS_MODE_ALWAYS` para continuar respondendo a input enquanto o tree está pausado.
