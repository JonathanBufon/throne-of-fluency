extends Node

const DEFAULT_PLAYER_1 = preload("res://battleSystem/data/characters/player1.tres")
const DEFAULT_PLAYER_2 = preload("res://battleSystem/data/characters/player2.tres")
const DEFAULT_POTION = preload("res://battleSystem/data/items/potion.tres")

var _spawn_id: String = ""
var spawn_id: String:
	get:
		return _spawn_id
	set(value):
		print("GameData.spawn_id mudou para: '", value, "'")
		_spawn_id = value

var cripta_porta_aberta := false
var defeated_encounters: Array[String] = []
var party_resources: Array[CharacterResource] = []
var battle_inventory: Dictionary = {}

func _ready() -> void:
	if party_resources.is_empty():
		reset_default_party()
	if battle_inventory.is_empty():
		reset_default_inventory()

func reset_default_party() -> void:
	party_resources.clear()
	party_resources.append(DEFAULT_PLAYER_1 as CharacterResource)
	party_resources.append(DEFAULT_PLAYER_2 as CharacterResource)

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

	if resources.is_empty():
		reset_default_party()
		resources.append_array(party_resources)

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
