extends Node

const EVENT_ID := "shroomlands_battle_tutorial"
const RESUME_EVENT_ID := "shroomlands_battle_tutorial_resume"
const VICTORY_EVENT_ID := "shroomlands_battle_tutorial_victory"
const ENCOUNTER_ID := "shroomlands_battle_tutorial_goblin"
const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")

@export var goblin_path: NodePath
@export var entrance_offset := Vector2(0, -360)
@export var entrance_speed := 140.0
@export var approach_speed := 350.0
@export var battle_distance := 42.0

var _player: CharacterBody2D
var _lumen: Node2D
var _goblin: CharacterBody2D
var _goblin_sprite: AnimatedSprite2D
var _goblin_stop_position := Vector2.ZERO
var _sequence_running := false


func _ready() -> void:
	_goblin = get_node_or_null(goblin_path) as CharacterBody2D
	if _goblin != null:
		_goblin_stop_position = _goblin.global_position
		_goblin.global_position = _goblin_stop_position + entrance_offset
		_goblin_sprite = _goblin.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		_goblin.hide()
		_goblin.process_mode = Node.PROCESS_MODE_DISABLED
	call_deferred("_prepare_event")


func _prepare_event() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	if GameData.pending_world_event == VICTORY_EVENT_ID:
		GameData.pending_world_event = ""
		await _run_post_victory_event()
		return

	if GameData.is_encounter_defeated(ENCOUNTER_ID):
		GameData.pending_world_event = ""
		if is_instance_valid(_goblin):
			_goblin.queue_free()
		return

	if GameData.pending_world_event == RESUME_EVENT_ID:
		GameData.pending_world_event = ""
		await _resume_after_flee()
		return

	if GameData.pending_world_event != EVENT_ID:
		return

	GameData.pending_world_event = ""
	await _run_tutorial_sequence()


func _run_tutorial_sequence() -> void:
	if _sequence_running or not _resolve_actors():
		return

	_sequence_running = true
	_set_player_locked(true)

	await _show_dialog([
		{
			"name": "Lumen",
			"text": "Espere... alguém esta aproximando.",
			"speaker": "lumen",
		},
	])

	_reveal_goblin()
	await _walk_goblin_to_stop()
	await get_tree().create_timer(0.35).timeout

	await _show_dialog([
		{
			"name": "Goblin",
			"text": "........",
			"speaker": "goblin",
			"portrait_visible": false,
		},
		{
			"name": "Goblin",
			"text": "Grrr.....",
			"speaker": "goblin",
			"portrait_visible": false,
		},
		{
			"name": "Lumen",
			"text": "Parece que ele não gostou da nossa presença",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "Está vindo em nossa direção! Prepare-se!",
			"speaker": "lumen",
		},
	])

	await _approach_player_and_start_battle()


func _run_post_victory_event() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _player == null:
		return

	if is_instance_valid(_goblin):
		_goblin.queue_free()

	_sequence_running = true
	_set_player_locked(true)
	await _show_dialog([
		{
			"name": "Lumen",
			"text": "Essa batalha foi difícil... você sofreu alguns ferimentos.",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "Vamos cuidar disso. Pressione I para acessar o inventário.",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "Na aba Itens, selecione uma Poção e confirme para recuperar seu HP.",
			"speaker": "lumen",
		},
	])
	_set_player_locked(false)
	_sequence_running = false
	WorldInventory.open()


func _resume_after_flee() -> void:
	if not _resolve_actors():
		return
	_sequence_running = true
	_set_player_locked(true)
	_goblin.global_position = _goblin_stop_position
	_reveal_goblin()
	await _approach_player_and_start_battle()


func _resolve_actors() -> bool:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	_lumen = get_tree().get_first_node_in_group("lumen") as Node2D
	return _player != null and _goblin != null


func _set_player_locked(locked: bool) -> void:
	if not is_instance_valid(_player):
		return
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(not locked)
	_player.set_process_input(not locked)


func _show_dialog(lines: Array[Dictionary]) -> void:
	var dialog := DIALOG_SCENE.instantiate()
	get_tree().current_scene.add_child(dialog)
	await dialog.start_dialog(lines)
	dialog.queue_free()


func _reveal_goblin() -> void:
	if not is_instance_valid(_goblin):
		return
	_goblin.show()
	if _goblin_sprite != null:
		_goblin_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		_goblin_sprite.speed_scale = 1.35
		_goblin_sprite.play(&"idle_down")


func _walk_goblin_to_stop() -> void:
	if not is_instance_valid(_goblin):
		return

	while _goblin.global_position.distance_to(_goblin_stop_position) > 2.0:
		var direction := _goblin.global_position.direction_to(_goblin_stop_position)
		var step := entrance_speed * get_physics_process_delta_time()
		_goblin.global_position = _goblin.global_position.move_toward(_goblin_stop_position, step)
		_play_goblin_run(direction)
		await get_tree().physics_frame

	_goblin.global_position = _goblin_stop_position
	_play_goblin_idle(Vector2.DOWN)


func _approach_player_and_start_battle() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_goblin):
		_set_player_locked(false)
		return

	while _goblin.global_position.distance_to(_player.global_position) > battle_distance:
		var direction := _goblin.global_position.direction_to(_player.global_position)
		_goblin.global_position += direction * approach_speed * get_physics_process_delta_time()
		_play_goblin_run(direction)
		await get_tree().physics_frame

	if _goblin.has_method("_on_danger_box_body_entered"):
		GameData.pending_world_event = RESUME_EVENT_ID
		_goblin.call("_on_danger_box_body_entered", _player)
	else:
		_set_player_locked(false)


func _play_goblin_run(direction: Vector2) -> void:
	if _goblin_sprite == null:
		return
	if absf(direction.x) > absf(direction.y):
		_goblin_sprite.flip_h = direction.x < 0.0
		_goblin_sprite.play(&"run_right")
	elif direction.y < 0.0:
		_goblin_sprite.flip_h = false
		_goblin_sprite.play(&"run_up")
	else:
		_goblin_sprite.flip_h = false
		_goblin_sprite.play(&"run_down")


func _play_goblin_idle(direction: Vector2) -> void:
	if _goblin_sprite == null:
		return
	if absf(direction.x) > absf(direction.y):
		_goblin_sprite.flip_h = direction.x < 0.0
		_goblin_sprite.play(&"idle_right")
	elif direction.y < 0.0:
		_goblin_sprite.flip_h = false
		_goblin_sprite.play(&"idle_up")
	else:
		_goblin_sprite.flip_h = false
		_goblin_sprite.play(&"idle_down")
