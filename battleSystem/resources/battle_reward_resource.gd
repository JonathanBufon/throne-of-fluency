extends Resource
class_name BattleRewardResource

@export var experience := 0
@export var gold := 0
@export var drops: Array[ItemResource] = []
@export var dropQuantities: Array[int] = []
@export var word_drops: Array[WordResource] = []

func get_drop_quantity(index: int) -> int:
	if index < 0 or index >= dropQuantities.size():
		return 1
	return maxi(dropQuantities[index], 0)
