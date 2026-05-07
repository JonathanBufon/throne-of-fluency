extends Resource
class_name EnemyAIResource

@export var targetStrategy: Target_Strategy = Target_Strategy.RANDOM_PLAYER
@export var preferSkillWhenAffordable := false
@export var healAllyHealthRatio := 0.35
@export var actionPattern: Array[Resource] = []

enum Target_Strategy { RANDOM_PLAYER, LOWEST_HP_PLAYER }

func get_pattern_command(turn_count: int) -> Resource:
	if actionPattern.is_empty():
		return null
	var index := turn_count % actionPattern.size()
	return actionPattern[index]
