extends Node

const DEFAULT_PLAYER_1 = preload("res://battleSystem/data/characters/player1.tres")
const DEFAULT_PLAYER_2 = preload("res://battleSystem/data/characters/player2.tres")

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

func _ready() -> void:
	if party_resources.is_empty():
		reset_default_party()

func reset_default_party() -> void:
	party_resources.clear()
	party_resources.append(DEFAULT_PLAYER_1 as CharacterResource)
	party_resources.append(DEFAULT_PLAYER_2 as CharacterResource)

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
