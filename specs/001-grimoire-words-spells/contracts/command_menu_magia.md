# Contract — `CommandMenu` Magia button

Mudanças em `battleSystem/ui/command_menu.tscn` e `battleSystem/ui/command_menu.gd`.

## Estrutura de cena

```text
%MainCommands (GridContainer)
├── AttackButton    (existente)
├── SkillsButton    (existente)
├── MagicButton     ⟵ NOVO (entre Skills e Combo, FR-020)
├── ComboButton     (existente)
├── ItemButton      (existente)
└── RunButton       (existente)
```

`MagicButton.text = "Magia"`.

## Script — adições mínimas

```gdscript
@onready var magic_button: Button = %MagicButton

var _current_spells: Array[SkillResource] = []

func _ready() -> void:
    # ... existente ...
    magic_button.pressed.connect(_on_magic_button_pressed)

func _set_command_options(character: TurnBasedAgent) -> void:
    # ... existente ...
    _set_spell_options()

func _set_spell_options() -> void:
    _current_spells.clear()
    for recipe in GameData.prepared_spells:
        if recipe != null and recipe.result_skill != null:
            _current_spells.append(recipe.result_skill)
    if _current_spells.is_empty():
        magic_button.disabled = true
    else:
        magic_button.disabled = false

func _on_magic_button_pressed() -> void:
    main_commands.hide()
    _populate_command_list(_current_spells)
    skill_container.show()
    var children := skill_container.get_children()
    if not children.is_empty():
        children[0].grab_focus()
```

## Comportamento

- `MagicButton` aparece sempre (não esconde). `disabled = true` quando `prepared_spells` está vazio (FR-023) — consistente com o tratamento atual de `skills_button` quando o personagem não tem skills disponíveis ou MP suficiente.
- Submenu de magias usa exatamente `_populate_command_list` + `_on_command_pressed` — mesma pipeline de Skills/Combo/Item.
- Cast respeita MP via `_can_character_use_skill` já existente (a magia é `SkillResource` e tem `manaCost`).

## Sinais existentes (sem mudança)

```gdscript
signal command_selected(command: Resource)   # emitido para SkillResource via pipeline normal
signal run_requested()                        # inalterado
```

`command_selected` recebe a `SkillResource` resultante da receita — o resto do `battle_scene.gd` não precisa distinguir "magia preparada" de "skill comum".

## Edge cases cobertos

| Cenário | Comportamento |
|---|---|
| `prepared_spells` vazio | `MagicButton.disabled = true`; jogador pode escolher outro comando. |
| MP insuficiente para uma magia | `_can_character_use_skill` retorna `false`; botão da magia no submenu fica `disabled` com tooltip "needs N MP". |
| `recipe.result_skill == null` | Magia é pulada na construção de `_current_spells`. |
| Personagem em turno enquanto `prepared_spells` muda em runtime | `_set_command_options` é chamado a cada `_on_player_turn`; lista é re-derivada por turno. |
