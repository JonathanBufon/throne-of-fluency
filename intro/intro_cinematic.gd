extends Control

const CRYPT_SCENE := "res://world/cripta/cripta.tscn"
const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")
const ANGEL_SHEET := preload("res://assets/sprites/characters/Angels/Angel_1.png")

const LUMEN_REGION := Rect2(23.0, 272.0, 17.0, 21.0)
const GEM_POSITION := Vector2(400.0, 270.0)
const SECONDARY_GEM_POSITIONS := {
	"gema_conversacao": Vector2(310.0, 275.0),
	"gema_escuta": Vector2(400.0, 275.0),
	"gema_escrita": Vector2(490.0, 275.0),
}

var _dialog
var _background: ColorRect
var _gem_dialogo: Node2D
var _secondary_gems: Array[Node2D] = []
var _explosion: Node2D
var _lumen: Sprite2D
var _fade: ColorRect
var _is_transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_scene()
	_play_intro()


func _build_scene() -> void:
	_background = ColorRect.new()
	_background.color = Color.BLACK
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_background)
	move_child(_background, 0)

	_gem_dialogo = _get_canvas_item("gema_dialogo")
	_gem_dialogo.position = GEM_POSITION
	_gem_dialogo.modulate.a = 0.0

	_secondary_gems.clear()
	for gem_name in SECONDARY_GEM_POSITIONS.keys():
		var gem := _get_canvas_item(gem_name)
		gem.position = SECONDARY_GEM_POSITIONS[gem_name]
		gem.modulate.a = 0.0
		_secondary_gems.append(gem)

	_explosion = _find_explosion_node()
	if _explosion:
		_explosion.position = GEM_POSITION
		_explosion.modulate.a = 0.0
		_explosion.hide()

	_lumen = _create_lumen_sprite()
	_lumen.position = Vector2(400.0, 300.0)
	_lumen.scale = Vector2.ZERO
	_lumen.modulate.a = 0.0
	add_child(_lumen)

	_dialog = DIALOG_SCENE.instantiate()
	add_child(_dialog)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func _play_intro() -> void:
	await get_tree().create_timer(0.3).timeout
	await _say_verbum("Antes das espadas... vieram as palavras.")
	await _say_verbum("Antes das guerras... existia o entendimento.")
	await _say_verbum("Eu sou Verbum...")
	await _show_gem_scene()
	await _say_verbum("Mas a voz do mundo foi quebrada.")
	await _explode_gem()
	await _show_secondary_gems()
	await _say_verbum("E... com elas o mundo se perdeu.")
	await _show_lumen_scene()
	await _say_verbum("Lumen...")
	await _say_verbum("Encontre aquele que ainda pode aprender.")
	_go_to_crypt()


func _say_verbum(text: String) -> void:
	await _dialog.start_dialog([
		{
			"name": "Verbum",
			"text": text,
			"portrait_visible": false,
		},
	], true)


func _show_gem_scene() -> void:
	_play_canvas_animation(_gem_dialogo)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_gem_dialogo, "modulate:a", 1.0, 0.75)
	tween.tween_property(_gem_dialogo, "position:y", _gem_dialogo.position.y - 18.0, 0.9).set_trans(Tween.TRANS_SINE)
	await tween.finished

	var float_tween := create_tween().set_loops(2)
	float_tween.tween_property(_gem_dialogo, "position:y", _gem_dialogo.position.y + 18.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(_gem_dialogo, "position:y", _gem_dialogo.position.y - 18.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await float_tween.finished


func _explode_gem() -> void:
	await _prepare_dialog_gem_break()

	var gem_tween := create_tween().set_parallel(true)
	gem_tween.tween_property(_gem_dialogo, "scale", _gem_dialogo.scale * 1.25, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	gem_tween.tween_property(_gem_dialogo, "modulate:a", 0.0, 0.18)
	await gem_tween.finished

	if _explosion:
		_explosion.show()
		_explosion.modulate.a = 1.0
		_play_canvas_animation(_explosion)
		await get_tree().create_timer(minf(_get_animation_length(_explosion, 0.45), 0.45)).timeout
		var explosion_tween := create_tween()
		explosion_tween.tween_property(_explosion, "modulate:a", 0.0, 0.16)
		await explosion_tween.finished
		_explosion.hide()
	else:
		await get_tree().create_timer(0.22).timeout


func _prepare_dialog_gem_break() -> void:
	var original_position := _gem_dialogo.position
	var original_scale := _gem_dialogo.scale
	var pulse := create_tween()
	pulse.tween_property(_gem_dialogo, "scale", original_scale * 1.12, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_gem_dialogo, "scale", original_scale * 0.94, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	pulse.tween_property(_gem_dialogo, "scale", original_scale * 1.18, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pulse.finished

	var shake := create_tween()
	for offset in [Vector2(-8.0, 0.0), Vector2(7.0, -3.0), Vector2(-5.0, 4.0), Vector2(4.0, 0.0)]:
		shake.tween_property(_gem_dialogo, "position", original_position + offset, 0.035)
	shake.tween_property(_gem_dialogo, "position", original_position, 0.04)
	await shake.finished


func _show_secondary_gems() -> void:
	var appear := create_tween().set_parallel(true)
	for index in _secondary_gems.size():
		var gem := _secondary_gems[index]
		var target_position: Vector2 = SECONDARY_GEM_POSITIONS[String(gem.name)]
		var target_scale: Vector2 = gem.scale
		var midpoint: Vector2 = GEM_POSITION.lerp(target_position, 0.58) + Vector2(0.0, -46.0 - float(index) * 8.0)
		gem.position = GEM_POSITION
		gem.scale = target_scale * 0.28
		gem.rotation = -0.45 + float(index) * 0.45
		_play_canvas_animation(gem)
		appear.tween_property(gem, "modulate:a", 1.0, 0.18).set_delay(index * 0.06)
		appear.tween_property(gem, "position", midpoint, 0.28).set_delay(index * 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		appear.tween_property(gem, "position", target_position, 0.34).set_delay(0.28 + index * 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		appear.tween_property(gem, "scale", target_scale * 1.18, 0.28).set_delay(index * 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		appear.tween_property(gem, "scale", target_scale, 0.22).set_delay(0.3 + index * 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		appear.tween_property(gem, "rotation", 0.0, 0.52).set_delay(index * 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await appear.finished

	await get_tree().create_timer(0.8).timeout

	var leave := create_tween().set_parallel(true)
	for gem in _secondary_gems:
		leave.tween_property(gem, "modulate:a", 0.0, 0.28)
		leave.tween_property(gem, "position:y", gem.position.y + 8.0, 0.28).set_trans(Tween.TRANS_SINE)
	await leave.finished


func _show_lumen_scene() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_lumen, "modulate:a", 1.0, 0.7)
	tween.tween_property(_lumen, "scale", Vector2(3.4, 3.4), 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_lumen, "position:y", _lumen.position.y - 50.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	var pulse := create_tween().set_loops(3)
	pulse.tween_property(_lumen, "scale", Vector2(3.8, 3.8), 0.28)
	pulse.tween_property(_lumen, "scale", Vector2(3.4, 3.4), 0.28)
	await pulse.finished


func _go_to_crypt() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	GameData.play_intro_crypt_sequence = true
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, 0.55)
	await tween.finished
	get_tree().change_scene_to_file(CRYPT_SCENE)


func _get_canvas_item(node_name: String) -> Node2D:
	var node := get_node_or_null(node_name) as Node2D
	if node:
		return node

	var fallback := Sprite2D.new()
	fallback.name = node_name
	add_child(fallback)
	return fallback


func _find_explosion_node() -> Node2D:
	for node_name in ["explosao_1", "explosão_1", "AnimatedSprite2D"]:
		var node := get_node_or_null(node_name) as Node2D
		if node:
			return node
	return null


func _play_canvas_animation(node: Node2D) -> void:
	if node is AnimatedSprite2D:
		var animated_sprite := node as AnimatedSprite2D
		animated_sprite.frame = 0
		animated_sprite.play()


func _get_animation_length(node: Node2D, fallback: float) -> float:
	if not node is AnimatedSprite2D:
		return fallback

	var animated_sprite := node as AnimatedSprite2D
	if animated_sprite.sprite_frames == null:
		return fallback

	var animation_name := animated_sprite.animation
	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	var speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or speed <= 0.0:
		return fallback

	return float(frame_count) / speed


func _create_lumen_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = ANGEL_SHEET
	sprite.region_enabled = true
	sprite.region_rect = LUMEN_REGION
	return sprite
