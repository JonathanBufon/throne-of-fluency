extends Control
class_name CommandMenu

signal command_selected(command: Resource)

@onready var attack_button: Button = %AttackButton
@onready var skills_button: Button = %SkillsButton
@onready var run_button: Button = %RunButton

@onready var main_commands: VBoxContainer = %MainCommands
@onready var skill_container: GridContainer = $MarginContainer/ScrollContainer/SkillsContainer

const COMMAND_BUTTON := preload("res://battleSystem/command_button.tscn")

# Stores the current character's basic attack to avoid multiple signal connections
var _current_basic_attack: Resource = preload("res://battleSystem/Attack.tres")

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
		_set_command_options(character)
	main_commands.show()
	skill_container.hide()
	show()
	main_commands.get_children()[0].grab_focus()

func _on_attack_button_pressed() -> void:
	_on_command_pressed(_current_basic_attack)

func _on_command_pressed(command: Resource) -> void:
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
	# TODO: replace with actual escape/flee logic
	get_tree().quit()

func _set_command_options(character: TurnBasedAgent) -> void:
	if character.basicAttack:
		_current_basic_attack = character.basicAttack
		attack_button.show()
	else:
		attack_button.hide()

	if character.skills.is_empty():
		skills_button.hide()
	else:
		skills_button.show()
		for skill in skill_container.get_children():
			skill.queue_free()
		for skill in character.skills:
			var btn := COMMAND_BUTTON.instantiate()
			btn.text = skill.name
			btn.pressed.connect(_on_command_pressed.bind(skill))
			skill_container.add_child(btn)
