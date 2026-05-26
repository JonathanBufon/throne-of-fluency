extends Resource
class_name EnemyAIResource

@export var targetStrategy: Target_Strategy = Target_Strategy.RANDOM_PLAYER
@export var preferSkillWhenAffordable := false
@export var healAllyHealthRatio := 0.35
@export var actionWindupSeconds := 0.45
@export var preferredSkillFirstTurn := 0
@export var preferredSkillCooldownTurns := 0
@export var actionPattern: Array[Resource] = []

enum Target_Strategy { RANDOM_PLAYER, LOWEST_HP_PLAYER }

func get_pattern_command(turn_count: int) -> Resource:
	if actionPattern.is_empty():
		return null
	var index := turn_count % actionPattern.size()
	return actionPattern[index]

func can_use_preferred_skill(turn_count: int) -> bool:
	if turn_count < preferredSkillFirstTurn:
		return false
	if preferredSkillCooldownTurns <= 0:
		return true
	return (turn_count - preferredSkillFirstTurn) % preferredSkillCooldownTurns == 0
