extends CanvasLayer

var _fade_rect: ColorRect


func _ready() -> void:
	_ensure_fade_rect()


func _ensure_fade_rect() -> void:
	if _fade_rect:
		return

	layer = 128
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_rect.modulate.a = 0.0
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)


func change_scene(scene_path: String, fade_out_duration: float, fade_in_duration: float) -> void:
	_ensure_fade_rect()
	var tree := get_tree()
	var fade_out := create_tween()
	fade_out.tween_property(_fade_rect, "modulate:a", 1.0, fade_out_duration)
	await fade_out.finished

	var error := tree.change_scene_to_file(scene_path)
	if error != OK:
		push_warning("Nao foi possivel trocar para a fase: " + scene_path)
		queue_free()
		return

	await tree.process_frame
	await tree.process_frame

	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "modulate:a", 0.0, fade_in_duration)
	await fade_in.finished

	queue_free()
