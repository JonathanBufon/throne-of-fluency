extends Node

const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")
const LUMEN_PORTRAIT := "res://assets/sprites/characters/Angels/Angel_1.png"

const PLAYER_START_FALLBACK := Vector2(597.0, 238.0)
const LUMEN_START := Vector2(597.0, -110.0)
const LUMEN_END := Vector2(536.0, 146.0)
const PLAYER_EXIT_OFFSET := Vector2(0.0, -82.0)

var _player: Node2D
var _lumen: Node2D


func _ready() -> void:
	if not GameData.play_intro_crypt_sequence:
		return

	GameData.play_intro_crypt_sequence = false
	call_deferred("_play_sequence")


func _play_sequence() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_lumen = get_tree().get_first_node_in_group("lumen") as Node2D

	if _player == null or _lumen == null:
		push_warning("Intro da cripta nao encontrou player ou Lumen.")
		return

	_set_actor_control(false)
	var coffin_center := _get_coffin_center()
	_player.global_position = coffin_center
	_lumen.global_position = LUMEN_START
	_lumen.modulate.a = 0.0

	await get_tree().create_timer(0.35).timeout
	await _move_player_out_of_coffin(coffin_center + PLAYER_EXIT_OFFSET)
	await _bring_lumen_to_player()
	await _show_intro_dialog()

	_set_actor_control(true)


func _move_player_out_of_coffin(exit_position: Vector2) -> void:
	_play_actor_animation(_player, "run_up")
	var tween := create_tween()
	tween.tween_property(_player, "global_position", exit_position, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_play_actor_animation(_player, "idle_up")


func _bring_lumen_to_player() -> void:
	_play_actor_animation(_lumen, "run_down")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_lumen, "modulate:a", 1.0, 0.45)
	tween.tween_property(_lumen, "global_position", LUMEN_END, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_play_actor_animation(_lumen, "idle_down")


func _show_intro_dialog() -> void:
	var dialog := DIALOG_SCENE.instantiate()
	add_child(dialog)
	await dialog.start_dialog([
		{
			"name": "Lumen",
			"text": "A gema do Dialogo foi quebrada",
			"portrait_visible": false,
		},
		{
			"name": "Lumen",
			"text": "Precisamos reunir as partes novamente para restaurar o nosso mundo mais uma vez",
			"portrait_visible": false,
		},
		{
			"name": "Lumen",
			"text": "Você está comigo?",
			"portrait_visible": false,
		},
	])
	dialog.queue_free()


func _set_actor_control(enabled: bool) -> void:
	if _player:
		_player.set_physics_process(enabled)
	if _lumen:
		_lumen.set_physics_process(enabled)


func _get_coffin_center() -> Vector2:
	var coffin_layer := get_tree().current_scene.get_node_or_null("Scenario/Caixao") as TileMapLayer
	if coffin_layer == null:
		return PLAYER_START_FALLBACK

	var used_rect := coffin_layer.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return PLAYER_START_FALLBACK

	var center_cell := Vector2i(
		used_rect.position.x + int(floor(float(used_rect.size.x) * 0.5)),
		used_rect.position.y + int(floor(float(used_rect.size.y) * 0.5))
	)
	return coffin_layer.to_global(coffin_layer.map_to_local(center_cell))


func _play_actor_animation(actor: Node2D, animation_name: String) -> void:
	var sprite := actor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
