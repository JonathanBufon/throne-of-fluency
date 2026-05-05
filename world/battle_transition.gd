extends Node

# Canal de dados entre overworld e cena de batalha.
# Populado pela DangerBox do inimigo antes de trocar para battle_scene.tscn,
# lido pela cena de batalha no _ready e pela cena de origem ao retornar.

enum Result { IDLE, WON, LOST }

var enemy_resources: Array[CharacterResource] = []
var return_scene: String = ""
var return_position: Vector2 = Vector2.ZERO
var encounter_id: String = ""
var last_result: Result = Result.IDLE

func request_battle(
	enemies: Array[CharacterResource],
	origin_scene: String,
	player_position: Vector2,
	id: String = ""
) -> void:
	enemy_resources = enemies
	return_scene = origin_scene
	return_position = player_position
	encounter_id = id
	last_result = Result.IDLE

func finish_battle(result: Result) -> void:
	last_result = result

func clear() -> void:
	enemy_resources = []
	return_scene = ""
	return_position = Vector2.ZERO
	encounter_id = ""
	last_result = Result.IDLE

func has_pending_return() -> bool:
	return return_scene != "" and last_result != Result.IDLE
