extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

const DEFAULT_PLAYER_1 = preload("res://battleSystem/data/characters/player1.tres")
const DEFAULT_POTION = preload("res://battleSystem/data/items/potion.tres")

const ALL_SPELL_RECIPES: Array[SpellRecipeResource] = [
	preload("res://battleSystem/data/spells/fireball_recipe.tres"),
	preload("res://battleSystem/data/spells/holy_light_recipe.tres"),
]

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
var gold := 0
var last_battle_reward: Dictionary = {}
var known_words: Array[WordResource] = []
var prepared_spells: Array[SpellRecipeResource] = []

func _ready() -> void:
	if not load_game():
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
	save_game()
	return summary

func has_word(word: WordResource) -> bool:
	return word != null and known_words.has(word)

func discover_word(word: WordResource) -> bool:
	if word == null or known_words.has(word):
		return false
	known_words.append(word)
	return true

func get_known_recipes() -> Array[SpellRecipeResource]:
	var ready: Array[SpellRecipeResource] = []
	for recipe in ALL_SPELL_RECIPES:
		if recipe != null and recipe.is_fully_known(known_words):
			ready.append(recipe)
	return ready

func is_spell_prepared(recipe: SpellRecipeResource) -> bool:
	return recipe != null and prepared_spells.has(recipe)

func can_prepare(recipe: SpellRecipeResource) -> bool:
	if recipe == null or is_spell_prepared(recipe):
		return false
	return recipe.is_fully_known(known_words)

func prepare_spell(recipe: SpellRecipeResource) -> bool:
	if not can_prepare(recipe):
		return false
	prepared_spells.append(recipe)
	save_game()
	return true

func find_recipe_for_words(input_words: Array) -> SpellRecipeResource:
	for recipe in ALL_SPELL_RECIPES:
		if recipe != null and recipe.matches(input_words):
			return recipe
	return null

func save_game() -> bool:
	var data := {
		"version": SAVE_VERSION,
		"gold": gold,
		"cripta_porta_aberta": cripta_porta_aberta,
		"defeated_encounters": defeated_encounters.duplicate(),
		"party": _serialize_party(),
		"inventory": _serialize_inventory(),
		"known_words": _serialize_resource_paths(known_words),
		"prepared_spells": _serialize_resource_paths(prepared_spells),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Falha ao abrir save para escrita: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var content := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(content)
	if error != OK:
		push_warning("Save corrompido: %s" % json.get_error_message())
		return false

	var data: Variant = json.data
	if not (data is Dictionary):
		push_warning("Save mal-formado (não é Dictionary)")
		return false

	var save_data: Dictionary = data
	gold = int(save_data.get("gold", 0))
	cripta_porta_aberta = bool(save_data.get("cripta_porta_aberta", false))

	defeated_encounters.clear()
	for encounter_id in save_data.get("defeated_encounters", []):
		defeated_encounters.append(String(encounter_id))

	_deserialize_party(save_data.get("party", []))
	_deserialize_inventory(save_data.get("inventory", {}))
	_deserialize_known_words(save_data.get("known_words", []))
	_deserialize_prepared_spells(save_data.get("prepared_spells", []))

	return true

func _serialize_party() -> Array:
	var result: Array = []
	for member in party_resources:
		if member == null or member.resource_path.is_empty():
			continue
		result.append({
			"path": member.resource_path,
			"currentHealth": member.currentHealth,
			"currentMana": member.currentMana,
			"level": member.level,
			"experience": member.experience,
			"overDriveValue": member.overDriveValue,
		})
	return result

func _deserialize_party(party_data: Array) -> void:
	party_resources.clear()
	for entry in party_data:
		if not (entry is Dictionary):
			continue
		var path := String(entry.get("path", ""))
		if path.is_empty():
			continue
		var resource := load(path) as CharacterResource
		if resource == null:
			continue
		resource.level = int(entry.get("level", resource.level))
		resource.experience = int(entry.get("experience", resource.experience))
		resource.currentHealth = int(entry.get("currentHealth", resource.maxHealth))
		resource.currentMana = int(entry.get("currentMana", resource.maxMana))
		resource.overDriveValue = int(entry.get("overDriveValue", 0))
		party_resources.append(resource)

	if party_resources.is_empty():
		reset_default_party()

func _serialize_inventory() -> Dictionary:
	var result: Dictionary = {}
	for item in battle_inventory.keys():
		var item_resource := item as ItemResource
		if item_resource == null or item_resource.resource_path.is_empty():
			continue
		result[item_resource.resource_path] = int(battle_inventory[item_resource])
	return result

func _deserialize_inventory(inventory_data: Dictionary) -> void:
	battle_inventory.clear()
	for path in inventory_data.keys():
		var item := load(String(path)) as ItemResource
		if item == null:
			continue
		battle_inventory[item] = int(inventory_data[path])

func _serialize_resource_paths(resources: Array) -> Array:
	var result: Array = []
	for resource in resources:
		if resource != null and not resource.resource_path.is_empty():
			result.append(resource.resource_path)
	return result

func _deserialize_known_words(paths: Array) -> void:
	known_words.clear()
	for path in paths:
		var word := load(String(path)) as WordResource
		if word != null:
			known_words.append(word)

func _deserialize_prepared_spells(paths: Array) -> void:
	prepared_spells.clear()
	for path in paths:
		var recipe := load(String(path)) as SpellRecipeResource
		if recipe != null:
			prepared_spells.append(recipe)
