extends StaticBody2D

const DAMAGE_NUMBER := preload("res://battleSystem/ui/damage_number.tscn")

@onready var turn_based_agent: TurnBasedAgent = $TurnBasedAgent

func _ready() -> void:
	turn_based_agent.target_selected.connect(_on_target_selected)

func _on_target_selected(target: TurnBasedAgent, command: Resource) -> void:
	if target == null or command == null:
		turn_based_agent.command_done()
		return

	if command is SkillResource and not command.pay_cost(turn_based_agent.character_resource):
		turn_based_agent.command_done()
		return

	await _animation_example(target)

	var previous_health := target.character_resource.currentHealth
	var previous_mana := target.character_resource.currentMana
	_apply_command_effect(target, command)
	target._refresh_character_state_visual()
	_show_command_feedback(target, previous_health, previous_mana)

	turn_based_agent.command_done()

func _apply_command_effect(target: TurnBasedAgent, command: Resource) -> void:
	if command is ItemResource:
		command.apply_to(target.character_resource)
	elif command is SkillResource and command.skillType == SkillResource.Skill_Type.HEAL:
		target.character_resource.heal(command.power)
	elif command is SkillResource:
		target.character_resource.take_damage(command.power)

func _show_command_feedback(target: TurnBasedAgent, previous_health: int, previous_mana: int) -> void:
	var health_delta := target.character_resource.currentHealth - previous_health
	var mana_delta := target.character_resource.currentMana - previous_mana
	if health_delta != 0:
		_spawn_damage_number(target, health_delta)
		target.play_feedback_flash(health_delta > 0)
	elif mana_delta > 0:
		_spawn_damage_number(target, mana_delta, "MP")
		target.play_feedback_flash(true)

func _spawn_damage_number(target: TurnBasedAgent, amount: int, suffix := "") -> void:
	var damage_number := DAMAGE_NUMBER.instantiate() as DamageNumber
	damage_number.global_position = target.get_global_position() + Vector2(0, -72)
	get_tree().current_scene.add_child(damage_number)

	var prefix := "+" if amount > 0 else ""
	var text := "%s%d" % [prefix, amount]
	if not suffix.is_empty():
		text = "%s %s" % [text, suffix]
	damage_number.show_value(text, amount > 0)

func _animation_example(target: TurnBasedAgent) -> void:
	var start_position := global_position
	var target_position := target.get_global_position()

	turn_based_agent.play_attack_towards(target_position)

	var tween := get_tree().create_tween()
	tween.tween_property(self, "global_position", target_position, 0.3)
	tween.tween_property(self, "global_position", start_position, 0.3)

	await tween.finished
	turn_based_agent.play_idle_towards(target_position)
