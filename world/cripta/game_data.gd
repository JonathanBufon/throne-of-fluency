extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const DISABLE_PERSISTENCE_IN_DEBUG := true

const DEFAULT_PLAYER_1 = preload("res://battleSystem/data/characters/player1.tres")
const DEFAULT_POTION = preload("res://battleSystem/data/items/potion.tres")
const MUSHROOM_GLASSES = preload("res://battleSystem/data/items/mushroom_glasses.tres")
const PULL_WORD = preload("res://battleSystem/data/words/pull.tres")
const OPEN_WORD = preload("res://battleSystem/data/words/open.tres")
const TALK_WORD = preload("res://battleSystem/data/words/talk.tres")

const STORY_GRIMOIRE_WORDS: Array[WordResource] = [
	PULL_WORD,
	OPEN_WORD,
	TALK_WORD,
]

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
var porta_final_aberta := false
var play_intro_crypt_sequence := false
var dialogue_gem_recovered := false
var mushroom_guard_glasses_returned := false
var pending_world_event := ""
var defeated_encounters: Array[String] = []
var party_resources: Array[CharacterResource] = []
var battle_inventory: Dictionary = {}
var gold := 0
var last_battle_reward: Dictionary = {}
var known_words: Array[WordResource] = []
var prepared_spells: Array[SpellRecipeResource] = []
var opened_world_chests: Array[String] = []
var completed_world_events: Array[String] = []
var silent_npcs_spoken: Array[String] = []
var collected_gems: Array[String] = []

func _ready() -> void:
	if not load_game():
		if party_resources.is_empty():
			reset_default_party()
		if battle_inventory.is_empty():
			reset_default_inventory()

func _is_persistence_enabled() -> bool:
	return not (DISABLE_PERSISTENCE_IN_DEBUG and OS.is_debug_build())

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

func grant_world_item(item: ItemResource, quantity: int = 1) -> void:
	add_battle_item(item, quantity)
	save_game()

func mark_world_chest_opened(chest_id: String) -> void:
	if chest_id.is_empty() or opened_world_chests.has(chest_id):
		return
	opened_world_chests.append(chest_id)
	save_game()

func is_world_chest_opened(chest_id: String) -> bool:
	return not chest_id.is_empty() and opened_world_chests.has(chest_id)

func mark_world_event_completed(event_id: String) -> void:
	if event_id.is_empty() or completed_world_events.has(event_id):
		return
	completed_world_events.append(event_id)
	save_game()

func is_world_event_completed(event_id: String) -> bool:
	return not event_id.is_empty() and completed_world_events.has(event_id)

func recover_dialogue_gem() -> void:
	if not dialogue_gem_recovered:
		dialogue_gem_recovered = true
	discover_word(TALK_WORD)
	save_game()

func has_recovered_dialogue_gem() -> bool:
	return dialogue_gem_recovered

func grant_mushroom_glasses() -> void:
	if mushroom_guard_glasses_returned or get_item_quantity(MUSHROOM_GLASSES) > 0:
		return
	add_battle_item(MUSHROOM_GLASSES, 1)
	save_game()

func has_mushroom_glasses() -> bool:
	return get_item_quantity(MUSHROOM_GLASSES) > 0

func return_mushroom_glasses() -> bool:
	if mushroom_guard_glasses_returned or not has_mushroom_glasses():
		return false
	battle_inventory[MUSHROOM_GLASSES] = get_item_quantity(MUSHROOM_GLASSES) - 1
	mushroom_guard_glasses_returned = true
	save_game()
	return true

func has_returned_mushroom_glasses() -> bool:
	return mushroom_guard_glasses_returned

func register_silent_npc_conversation(npc_id: String) -> int:
	if dialogue_gem_recovered or npc_id.is_empty() or silent_npcs_spoken.has(npc_id):
		return 0
	silent_npcs_spoken.append(npc_id)
	save_game()
	var total := silent_npcs_spoken.size()
	return total if total % 5 == 0 else 0

func grant_battle_rewards(enemy_resources: Array[CharacterResource]) -> Dictionary:
	var summary: Dictionary = {
		"experience": 0,
		"gold": 0,
		"drops": {},
		"level_results": [],
		"new_words": [],
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

		for word in reward.word_drops:
			if word == null:
				continue
			if discover_word(word):
				var new_words := summary["new_words"] as Array
				new_words.append(word.text_en)

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

func collect_gem(gem_id: String) -> bool:
	if gem_id.is_empty() or collected_gems.has(gem_id):
		return false
	collected_gems.append(gem_id)
	save_game()
	return true

func has_gem(gem_id: String) -> bool:
	return not gem_id.is_empty() and collected_gems.has(gem_id)

func has_word(word: WordResource) -> bool:
	return word != null and known_words.has(word)

func discover_word(word: WordResource) -> bool:
	if word == null or known_words.has(word):
		return false
	known_words.append(word)
	return true

func get_grimoire_words() -> Array[WordResource]:
	var words: Array[WordResource] = []
	for word in STORY_GRIMOIRE_WORDS:
		if word != null:
			words.append(word)
	for word in known_words:
		if word != null and not words.has(word):
			words.append(word)
	return words

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
	if not _is_persistence_enabled():
		return true

	var data := {
		"version": SAVE_VERSION,
		"gold": gold,
		"cripta_porta_aberta": cripta_porta_aberta,
		"dialogue_gem_recovered": dialogue_gem_recovered,
		"mushroom_guard_glasses_returned": mushroom_guard_glasses_returned,
		"defeated_encounters": defeated_encounters.duplicate(),
		"party": _serialize_party(),
		"inventory": _serialize_inventory(),
		"known_words": _serialize_resource_paths(known_words),
		"prepared_spells": _serialize_resource_paths(prepared_spells),
		"opened_world_chests": opened_world_chests.duplicate(),
		"completed_world_events": completed_world_events.duplicate(),
		"silent_npcs_spoken": silent_npcs_spoken.duplicate(),
		"collected_gems": collected_gems.duplicate(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Falha ao abrir save para escrita: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data))
	return true

func load_game() -> bool:
	if not _is_persistence_enabled():
		return false

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
	dialogue_gem_recovered = bool(save_data.get("dialogue_gem_recovered", false))
	mushroom_guard_glasses_returned = bool(save_data.get("mushroom_guard_glasses_returned", false))

	defeated_encounters.clear()
	for encounter_id in save_data.get("defeated_encounters", []):
		defeated_encounters.append(String(encounter_id))

	opened_world_chests.clear()
	for chest_id in save_data.get("opened_world_chests", []):
		opened_world_chests.append(String(chest_id))

	completed_world_events.clear()
	for event_id in save_data.get("completed_world_events", []):
		completed_world_events.append(String(event_id))

	silent_npcs_spoken.clear()
	for npc_id in save_data.get("silent_npcs_spoken", []):
		silent_npcs_spoken.append(String(npc_id))

	_deserialize_party(save_data.get("party", []))
	_deserialize_inventory(save_data.get("inventory", {}))
	_deserialize_known_words(save_data.get("known_words", []))
	if dialogue_gem_recovered:
		discover_word(TALK_WORD)
	_deserialize_prepared_spells(save_data.get("prepared_spells", []))

	collected_gems.clear()
	for gem_id in save_data.get("collected_gems", []):
		collected_gems.append(String(gem_id))

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
