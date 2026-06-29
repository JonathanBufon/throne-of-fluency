extends Area2D

const PHASE_TRANSITION_OVERLAY := preload("res://world/phase_transition_overlay.gd")

@export var proxima_fase: String = ""
@export var spawn_id: String = ""
@export var proxima_fase_completa: String = ""
@export var fade_out_duration := 0.45
@export var fade_in_duration := 0.45

var _transitioning := false


func _on_body_entered(body: Node2D) -> void:
	if _transitioning:
		return
	if not body.is_in_group("player"):
		return

	_transitioning = true

	if proxima_fase_completa != "" and GameData.has_gem("gema_conversacao"):
		GameData.spawn_id = ""
		_mudar_cena(proxima_fase_completa)
	else:
		GameData.spawn_id = spawn_id
		_mudar_cena(proxima_fase)


func _mudar_cena(destino: String) -> void:
	var overlay := PHASE_TRANSITION_OVERLAY.new()
	get_tree().root.add_child(overlay)
	overlay.change_scene(destino, fade_out_duration, fade_in_duration)
