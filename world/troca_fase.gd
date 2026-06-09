extends Area2D

const PHASE_TRANSITION_OVERLAY := preload("res://world/phase_transition_overlay.gd")

@export var proxima_fase: String = ""
@export var spawn_id: String = ""
@export var fade_out_duration := 0.45
@export var fade_in_duration := 0.45

var _transitioning := false

func _on_body_entered(body: Node2D) -> void:
	if _transitioning:
		return

	if body.is_in_group("player") and proxima_fase != "":
		_transitioning = true
		GameData.spawn_id = spawn_id
		await _change_scene_with_fade()


func _change_scene_with_fade() -> void:
	var overlay := PHASE_TRANSITION_OVERLAY.new()
	get_tree().root.add_child(overlay)
	overlay.change_scene(proxima_fase, fade_out_duration, fade_in_duration)
