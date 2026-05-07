extends SkillResource
class_name ComboResource

@export var participantNames: Array[StringName] = []
@export var requiredTechs: Array[Resource] = []
@export var participantManaCosts: Array[int] = []

func get_participant_mana_cost(index: int) -> int:
	if index < 0 or index >= participantManaCosts.size():
		return 0
	return participantManaCosts[index]

func can_pay_cost(_user: CharacterResource) -> bool:
	return true

func pay_cost(_user: CharacterResource) -> bool:
	return true
