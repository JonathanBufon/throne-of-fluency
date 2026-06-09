extends Node

const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")

const PLAYER_START := Vector2(326.0, 416.0)
const LUMEN_START := Vector2(510.0, 347.0)
const PLAYER_STOP_UP := Vector2(326.0, 347.0)
const PLAYER_DIALOG_OFFSET_FROM_LUMEN := Vector2(-70.0, 0.0)
const PLAYER_MOVE_DURATION := 1.0
const LUMEN_APPEAR_TIME := 0.65
const LUMEN_BEFORE_PLAYER_DELAY := 0.85

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
	_player.global_position = PLAYER_START
	_lumen.global_position = LUMEN_START
	_lumen.modulate.a = 0.0
	_play_lumen_idle_left()
	_play_player_idle_right()

	await _show_lumen_before_player_exits()
	await _move_player_to_dialog_position()
	await _show_intro_dialog()

	_set_actor_control(true)


func _show_lumen_before_player_exits() -> void:
	var tween := create_tween()
	tween.tween_property(_lumen, "modulate:a", 1.0, LUMEN_APPEAR_TIME)
	await tween.finished
	await get_tree().create_timer(LUMEN_BEFORE_PLAYER_DELAY).timeout


func _move_player_to_dialog_position() -> void:
	var player_dialog_position: Vector2 = LUMEN_START + PLAYER_DIALOG_OFFSET_FROM_LUMEN

	_play_player_walk_animation(PLAYER_STOP_UP - PLAYER_START)
	var step_up := create_tween()
	step_up.tween_property(_player, "global_position", PLAYER_STOP_UP, PLAYER_MOVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await step_up.finished

	_play_player_walk_animation(player_dialog_position - PLAYER_STOP_UP)
	var step_right := create_tween()
	step_right.tween_property(_player, "global_position", player_dialog_position, PLAYER_MOVE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await step_right.finished
	_play_player_idle_right()


func _show_intro_dialog() -> void:
	var dialog := DIALOG_SCENE.instantiate()
	add_child(dialog)
	await dialog.start_dialog([
		{
			"name": "Lumen",
			"text": "Você acordou!!",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "Consegui alcançar você.",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "A gema do diálogo foi destruida,",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "E o mundo perdeu significado nas palavras.",
			"speaker": "lumen",
		},
		{
			"name": "Cavaleiro",
			"text": "#$@#$#%@",
			"speaker": "cavaleiro",
		},
		{
			"name": "Lumen",
			"text": "Os mortais perderam a capacidade de comunicar, mas você é o único capaz de aprender as palavras novamente!!",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "Vamos reunir os fragmentos e restaurar nosso mundo novamente.",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "Os antigos deixaram inscrições nas paredes para nos auxiliar.",
			"speaker": "lumen",
		},
	])
	dialog.queue_free()


func _set_actor_control(enabled: bool) -> void:
	if _player:
		_player.set_physics_process(enabled)
	if _lumen:
		_lumen.set_physics_process(enabled)


func _play_actor_animation(actor: Node2D, animation_name: String) -> void:
	var sprite := actor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)


func _play_player_walk_animation(direction: Vector2) -> void:
	var sprite := _player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	if absf(direction.x) > absf(direction.y):
		sprite.flip_h = direction.x < 0.0
		_play_actor_animation(_player, "run_right")
	elif direction.y < 0.0:
		sprite.flip_h = false
		_play_actor_animation(_player, "run_up")
	else:
		sprite.flip_h = false
		_play_actor_animation(_player, "run_down")


func _play_player_idle_right() -> void:
	var sprite := _player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	sprite.flip_h = false
	_play_actor_animation(_player, "idle_right")


func _play_lumen_idle_left() -> void:
	var sprite := _lumen.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	sprite.flip_h = true
	_play_actor_animation(_lumen, "idle_right")
