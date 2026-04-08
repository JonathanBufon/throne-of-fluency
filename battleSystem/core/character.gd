extends StaticBody2D

@onready var turn_based_agent: TurnBasedAgent = $TurnBasedAgent

func _ready() -> void:
	turn_based_agent.target_selected.connect(_on_target_selected)

func _on_target_selected(target: TurnBasedAgent, command: SkillResource) -> void:
	await _animation_example(target)

	if command.skillType == SkillResource.Skill_Type.HEAL:
		target.character_resource.heal(command.power)
	else:
		target.character_resource.take_damage(command.power)

	turn_based_agent.character_resource.overDriveValue = mini(
		turn_based_agent.character_resource.overDriveValue + 10, 100
	)

	turn_based_agent.command_done()

func _animation_example(target: TurnBasedAgent) -> void:
	var start_position := global_position
	var target_position := target.get_global_position()

	var tween := get_tree().create_tween()
	tween.tween_property(self, "global_position", target_position, 0.3)
	tween.tween_property(self, "global_position", start_position, 0.3)

	await tween.finished
