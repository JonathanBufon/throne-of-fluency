extends Control
class_name CommandMenu

signal command_selected(command: Resource)

@onready var attack_button: Button = %AttackButton
@onready var skills_button: Button = %SkillsButton
@onready var run_button: Button = %RunButton

@onready var main_commands: VBoxContainer = %MainCommands
@onready var skill_container: GridContainer = $MarginContainer/ScrollContainer/SkillContainer

const COMMAND_BUTTON = preload("res://battleSystem/command_button.tscn")

const ATTACK = preload("res://battleSystem/Attack.tres")
var skills = [preload("res://battleSystem/Heal.tres"), preload("res://battleSystem/Slash.tres")]

func _ready() -> void:
	add_to_group("commandMenu")
		
	attack_button.pressed.connect(_on_command_pressed.bind(ATTACK))
	
func _on_command_pressed(command: Resource):
	#hide()
	
	command_selected.emit(command)
	main_commands.show()
	skill_container.hide()
	
	attack_button.grab_focus()