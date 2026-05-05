extends Node

var _spawn_id: String = ""
var spawn_id: String:
	get:
		return _spawn_id
	set(value):
		print("GameData.spawn_id mudou para: '", value, "'")
		_spawn_id = value

var cripta_porta_aberta := false
var defeated_encounters: Array[String] = []

func mark_encounter_defeated(encounter_id: String) -> void:
	if encounter_id.is_empty() or defeated_encounters.has(encounter_id):
		return
	defeated_encounters.append(encounter_id)

func is_encounter_defeated(encounter_id: String) -> bool:
	return not encounter_id.is_empty() and defeated_encounters.has(encounter_id)
