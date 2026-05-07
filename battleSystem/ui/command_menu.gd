extends Control
class_name CommandMenu

signal command_selected(command: Resource)
signal run_requested()

@onready var attack_button: Button = %AttackButton
@onready var skills_button: Button = %SkillsButton
@onready var run_button: Button = %RunButton

@onready var main_commands: GridContainer = %MainCommands
@onready var skill_container: GridContainer = $MarginContainer/ScrollContainer/SkillsContainer

const COMMAND_BUTTON := preload("res://battleSystem/ui/command_button.tscn")

# Stores the current character's basic attack to avoid multiple signal connections
var _current_basic_attack: Resource = preload("res://battleSystem/data/skills/Attack.tres")
var _current_character: TurnBasedAgent

func _ready() -> void:
	add_to_group("commandMenu")
	_set_late_signals()

	attack_button.pressed.connect(_on_attack_button_pressed)
	skills_button.pressed.connect(_on_skill_button_pressed)
	run_button.pressed.connect(_on_run_button_pressed)

	skill_container.hide()
	hide()

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
		and command is SkillResource
		and not command.can_pay_cost(_current_character.character_resource)
	):
		return
	hide()
	command_selected.emit(command)
	main_commands.show()
	skill_container.hide()
	attack_button.grab_focus()

func _on_skill_button_pressed() -> void:
	main_commands.hide()
	skill_container.show()
	var children := skill_container.get_children()
	if not children.is_empty():
		children[0].grab_focus()

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
	if available_skills.is_empty():
		skills_button.hide()
		skills_button.disabled = true
	else:
		skills_button.show()
		skills_button.disabled = false
		for skill in skill_container.get_children():
			skill.queue_free()
		for skill in available_skills:
			var btn := COMMAND_BUTTON.instantiate()
			btn.text = _get_skill_button_text(skill)
			btn.disabled = not _can_character_use_skill(character, skill)
			btn.tooltip_text = _get_skill_tooltip(character, skill)
			if not btn.disabled:
				btn.pressed.connect(_on_command_pressed.bind(skill))
			skill_container.add_child(btn)

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

func _can_character_use_skill(character: TurnBasedAgent, skill: Resource) -> bool:
	if not (skill is SkillResource):
		return true
	return skill.can_pay_cost(character.character_resource)

func _get_skill_tooltip(character: TurnBasedAgent, skill: Resource) -> String:
	if not (skill is SkillResource):
		return ""
	if skill.manaCost <= 0:
		return skill.name
	if _can_character_use_skill(character, skill):
		return "%s - costs %d MP" % [skill.name, skill.manaCost]
	return "%s - needs %d MP" % [skill.name, skill.manaCost]
