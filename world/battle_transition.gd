extends Node

# Canal de dados entre overworld e cena de batalha.
# Populado pela DangerBox do inimigo antes de trocar para battle_scene.tscn,
# lido pela cena de batalha no _ready e pela cena de origem ao retornar.

enum Result { IDLE, WON, LOST, FLED }

var enemy_resources: Array[CharacterResource] = []
var return_scene: String = ""
var return_position: Vector2 = Vector2.ZERO
var encounter_id: String = ""
var last_result: Result = Result.IDLE
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _scene_change_in_progress := false

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

func change_scene_with_fade(scene_path: String, fade_out_duration := 0.2, fade_in_duration := 0.2) -> void:
	if scene_path.is_empty() or _scene_change_in_progress:
		return

	_scene_change_in_progress = true
	_ensure_fade_overlay()

	_fade_rect.show()
	_fade_rect.modulate.a = 0.0
	var fade_out := create_tween()
	fade_out.tween_property(_fade_rect, "modulate:a", 1.0, fade_out_duration)
	await fade_out.finished

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Falha ao trocar cena para '%s': %s" % [scene_path, error])
		_fade_rect.hide()
		_scene_change_in_progress = false
		return

	await get_tree().process_frame

	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "modulate:a", 0.0, fade_in_duration)
	await fade_in.finished

	_fade_rect.hide()
	_scene_change_in_progress = false

func _ensure_fade_overlay() -> void:
	if _fade_layer != null and is_instance_valid(_fade_layer):
		return

	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 128
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.hide()
	_fade_layer.add_child(_fade_rect)
