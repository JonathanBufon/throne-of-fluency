extends Control
class_name CommandMenu

signal command_selected(command: Resource)
signal run_requested()

@onready var attack_button: Button = %AttackButton
@onready var skills_button: Button = %SkillsButton
@onready var magic_button: Button = %MagicButton
@onready var combo_button: Button = %ComboButton
@onready var item_button: Button = %ItemButton
@onready var run_button: Button = %RunButton

@onready var main_commands: GridContainer = %MainCommands
@onready var skill_container: GridContainer = $MarginContainer/ScrollContainer/SkillsContainer

const COMMAND_BUTTON := preload("res://battleSystem/ui/command_button.tscn")
const DEFAULT_COMBOS := [
	preload("res://battleSystem/data/combos/focus_strike.tres"),
]

# Stores the current character's basic attack to avoid multiple signal connections
var _current_basic_attack: Resource = preload("res://battleSystem/data/skills/Attack.tres")
var _current_character: TurnBasedAgent
var _current_skills: Array[Resource] = []
var _current_spells: Array[Resource] = []
var _current_combos: Array[ComboResource] = []
var _current_items: Array[ItemResource] = []

func _ready() -> void:
	add_to_group("commandMenu")
	_set_late_signals()

	attack_button.pressed.connect(_on_attack_button_pressed)
	skills_button.pressed.connect(_on_skill_button_pressed)
	magic_button.pressed.connect(_on_magic_button_pressed)
	combo_button.pressed.connect(_on_combo_button_pressed)
	item_button.pressed.connect(_on_item_button_pressed)
	run_button.pressed.connect(_on_run_button_pressed)

	skill_container.hide()
	hide()

func _process(_delta: float) -> void:
	if visible and main_commands.visible and _current_character != null:
		_set_combo_options(_current_character)
		_set_item_options()

func _unhandled_input(event: InputEvent) -> void:
	if visible and skill_container.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_show_main_commands()

func _set_late_signals() -> void:
	await get_tree().current_scene.ready
	for character: TurnBasedAgent in get_tree().get_nodes_in_group("player"):
		character.player_turn_started.connect(_on_player_turn.bind(character))
		character.undo_command_selected.connect(_on_player_turn.bind(null))

func _on_player_turn(character: TurnBasedAgent) -> void:
	if character:
		_current_character = character
		_set_command_options(character)
	main_commands.show()
	skill_container.hide()
	show()
	main_commands.get_children()[0].grab_focus()

func _on_attack_button_pressed() -> void:
	_on_command_pressed(_current_basic_attack)

func _on_command_pressed(command: Resource) -> void:
	if (
		_current_character != null
		and not (command is ComboResource)
		and command is SkillResource
		and not command.can_pay_cost(_current_character.character_resource)
	):
		return
	if (
		_current_character != null
		and command is ComboResource
		and not ComboDiscovery.can_use_combo(command, _current_character, get_tree().get_nodes_in_group("player"))
	):
		return
	if command is ItemResource and not GameData.can_use_battle_item(command):
		return
	hide()
	command_selected.emit(command)
	_show_main_commands()
	attack_button.grab_focus()

func _on_skill_button_pressed() -> void:
	_refresh_current_options()
	_populate_command_list(_current_skills)
	_show_command_list()

func _on_magic_button_pressed() -> void:
	_refresh_current_options()
	_populate_command_list(_current_spells)
	_show_command_list()

func _on_combo_button_pressed() -> void:
	_refresh_current_options()
	_populate_command_list(_current_combos)
	_show_command_list()

func _on_item_button_pressed() -> void:
	_refresh_current_options()
	_populate_command_list(_current_items)
	_show_command_list()

func _on_run_button_pressed() -> void:
	hide()
	run_requested.emit()

func _set_command_options(character: TurnBasedAgent) -> void:
	var basic_attack := _get_basic_attack(character)
	if basic_attack:
		_current_basic_attack = basic_attack
		attack_button.show()
	else:
		attack_button.hide()

	var available_skills := _get_character_skills(character)
	_current_skills = available_skills
	if available_skills.is_empty():
		skills_button.hide()
		skills_button.disabled = true
	else:
		skills_button.show()
		skills_button.disabled = false

	_set_spell_options()
	_set_combo_options(character)
	_set_item_options()

func _set_spell_options() -> void:
	_current_spells.clear()
	for recipe in GameData.prepared_spells:
		if recipe != null and recipe.result_skill != null:
			_current_spells.append(recipe.result_skill)
	magic_button.disabled = _current_spells.is_empty()

func _set_combo_options(character: TurnBasedAgent) -> void:
	_current_combos = ComboDiscovery.get_available_combos(
		character,
		get_tree().get_nodes_in_group("player"),
		DEFAULT_COMBOS
	)
	if _current_combos.is_empty():
		combo_button.hide()
		combo_button.disabled = true
	else:
		combo_button.show()
		combo_button.disabled = false

func _set_item_options() -> void:
	_current_items = GameData.get_battle_items()
	var has_usable_item := false
	for item in _current_items:
		if GameData.can_use_battle_item(item):
			has_usable_item = true
			break

	item_button.visible = not _current_items.is_empty()
	item_button.disabled = not has_usable_item

func _refresh_current_options() -> void:
	if _current_character != null:
		_set_command_options(_current_character)

func _show_command_list() -> void:
	main_commands.hide()
	skill_container.show()
	var children := skill_container.get_children()
	for child in children:
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return

func _show_main_commands() -> void:
	_refresh_current_options()
	skill_container.hide()
	main_commands.show()
	for child in main_commands.get_children():
		if child is Button and (child as Button).visible and not (child as Button).disabled:
			(child as Button).grab_focus()
			return

func _populate_command_list(commands: Array) -> void:
	for child in skill_container.get_children():
		skill_container.remove_child(child)
		child.queue_free()

	for command in commands:
		var btn := COMMAND_BUTTON.instantiate()
		btn.text = _get_command_button_text(command)
		btn.disabled = not _can_character_use_command(_current_character, command)
		btn.tooltip_text = _get_command_tooltip(_current_character, command)
		if not btn.disabled:
			btn.pressed.connect(_on_command_pressed.bind(command))
		skill_container.add_child(btn)

	var back_button := COMMAND_BUTTON.instantiate()
	back_button.text = "Voltar"
	back_button.pressed.connect(_show_main_commands)
	skill_container.add_child(back_button)

func _get_basic_attack(character: TurnBasedAgent) -> Resource:
	if character.basicAttack:
		return character.basicAttack
	if character.character_resource != null and character.character_resource.basicAttack:
		return character.character_resource.basicAttack
	return null

func _get_character_skills(character: TurnBasedAgent) -> Array[Resource]:
	if not character.skills.is_empty():
		return character.skills
	if character.character_resource != null:
		return character.character_resource.techs
	return []

func _get_skill_button_text(skill: Resource) -> String:
	if skill is SkillResource and skill.manaCost > 0:
		return "%s %dMP" % [skill.name, skill.manaCost]
	return skill.name

func _get_command_button_text(command: Resource) -> String:
	if command is ComboResource:
		return command.name
	if command is ItemResource:
		return "%s x%d" % [command.name, GameData.get_item_quantity(command)]
	return _get_skill_button_text(command)

func _can_character_use_command(character: TurnBasedAgent, command: Resource) -> bool:
	if command is ComboResource:
		return ComboDiscovery.can_use_combo(
			command,
			character,
			get_tree().get_nodes_in_group("player")
		)
	if command is ItemResource:
		return GameData.can_use_battle_item(command)
	return _can_character_use_skill(character, command)

func _can_character_use_skill(character: TurnBasedAgent, skill: Resource) -> bool:
	if not (skill is SkillResource):
		return true
	if character == null or character.character_resource == null:
		return false
	return skill.can_pay_cost(character.character_resource)

func _get_skill_tooltip(character: TurnBasedAgent, skill: Resource) -> String:
	if not (skill is SkillResource):
		return ""
	if skill.manaCost <= 0:
		return skill.name
	if _can_character_use_skill(character, skill):
		return "%s - costs %d MP" % [skill.name, skill.manaCost]
	return "%s - needs %d MP" % [skill.name, skill.manaCost]

func _get_command_tooltip(character: TurnBasedAgent, command: Resource) -> String:
	if command is ComboResource:
		if _can_character_use_command(character, command):
			return _get_combo_cost_text(command)
		return "%s - needs ready participants, techs and MP" % command.name
	if command is ItemResource:
		if GameData.can_use_battle_item(command):
			return command.description
		return "%s - none left" % command.name
	return _get_skill_tooltip(character, command)

func _get_combo_cost_text(combo: ComboResource) -> String:
	var cost_parts: Array[String] = []
	for i in combo.participantNames.size():
		cost_parts.append("%s %dMP" % [
			String(combo.participantNames[i]),
			combo.get_participant_mana_cost(i),
		])
	return "%s - %s" % [combo.name, ", ".join(PackedStringArray(cost_parts))]
