extends Node

const DEFAULT_PLAYER_1 = preload("res://battleSystem/data/characters/player1.tres")
const DEFAULT_POTION = preload("res://battleSystem/data/items/potion.tres")

var _spawn_id: String = ""
var spawn_id: String:
	get:
		return _spawn_id
	set(value):
		print("GameData.spawn_id mudou para: '", value, "'")
		_spawn_id = value

var cripta_porta_aberta := false
var play_intro_crypt_sequence := false
var defeated_encounters: Array[String] = []
var party_resources: Array[CharacterResource] = []
var battle_inventory: Dictionary = {}
var gold := 0
var last_battle_reward: Dictionary = {}

func _ready() -> void:
	if party_resources.is_empty():
		reset_default_party()
	if battle_inventory.is_empty():
		reset_default_inventory()

func reset_default_party() -> void:
	party_resources.clear()
	party_resources.append(DEFAULT_PLAYER_1 as CharacterResource)

func reset_default_inventory() -> void:
	battle_inventory.clear()
	battle_inventory[DEFAULT_POTION] = 3

func mark_encounter_defeated(encounter_id: String) -> void:
	if encounter_id.is_empty() or defeated_encounters.has(encounter_id):
		return
	defeated_encounters.append(encounter_id)

func is_encounter_defeated(encounter_id: String) -> bool:
	return not encounter_id.is_empty() and defeated_encounters.has(encounter_id)

func get_battle_party_resources() -> Array[CharacterResource]:
	if party_resources.is_empty():
		reset_default_party()

	var resources: Array[CharacterResource] = []
	for resource in party_resources:
		if resource != null:
			resources.append(resource)
			break

	if resources.is_empty():
		reset_default_party()
		resources.append(party_resources[0])

	return resources

func get_battle_items() -> Array[ItemResource]:
	if battle_inventory.is_empty():
		reset_default_inventory()

	var items: Array[ItemResource] = []
	for item in battle_inventory.keys():
		var item_resource := item as ItemResource
		if item_resource != null and item_resource.can_use_in_battle():
			items.append(item_resource)
	return items

func get_item_quantity(item: ItemResource) -> int:
	if item == null:
		return 0
	if not battle_inventory.has(item):
		return 0
	return int(battle_inventory[item])

func can_use_battle_item(item: ItemResource) -> bool:
	return item != null and item.can_use_in_battle() and get_item_quantity(item) > 0

func consume_battle_item(item: ItemResource) -> bool:
	if not can_use_battle_item(item):
		return false

	battle_inventory[item] = get_item_quantity(item) - 1
	return true

func get_inventory_items() -> Array[ItemResource]:
	if battle_inventory.is_empty():
		reset_default_inventory()

	var items: Array[ItemResource] = []
	for item in battle_inventory.keys():
		var item_resource := item as ItemResource
		if item_resource != null and get_item_quantity(item_resource) > 0:
			items.append(item_resource)
	return items

func can_use_world_item(item: ItemResource) -> bool:
	return item != null and item.can_use_in_world() and get_item_quantity(item) > 0

func consume_world_item(item: ItemResource) -> bool:
	if not can_use_world_item(item):
		return false

	battle_inventory[item] = get_item_quantity(item) - 1
	return true

func add_battle_item(item: ItemResource, quantity: int) -> void:
	if item == null or quantity <= 0:
		return
	battle_inventory[item] = get_item_quantity(item) + quantity

func grant_battle_rewards(enemy_resources: Array[CharacterResource]) -> Dictionary:
	var summary: Dictionary = {
		"experience": 0,
		"gold": 0,
		"drops": {},
		"level_results": [],
	}

	for enemy in enemy_resources:
		if enemy == null or enemy.battleReward == null:
			continue
		var reward := enemy.battleReward as BattleRewardResource
		if reward == null:
			continue

		summary["experience"] = int(summary["experience"]) + reward.experience
		summary["gold"] = int(summary["gold"]) + reward.gold
		for i in reward.drops.size():
			var item := reward.drops[i]
			if item == null:
				continue
			var quantity := reward.get_drop_quantity(i)
			add_battle_item(item, quantity)
			var drops := summary["drops"] as Dictionary
			drops[item.name] = int(drops.get(item.name, 0)) + quantity

	gold += int(summary["gold"])

	for party_member in get_battle_party_resources():
		if party_member == null:
			continue
		var level_result := party_member.add_experience(int(summary["experience"]))
		if int(level_result["levels_gained"]) > 0:
			var level_results := summary["level_results"] as Array
			level_results.append(level_result)

	last_battle_reward = summary
	return summary
