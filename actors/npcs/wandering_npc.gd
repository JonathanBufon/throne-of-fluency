extends CharacterBody2D

const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")

@export var movement_speed: float = 70.0
@export var patrol_radius: float = 180.0
@export var minimum_idle_time: float = 1.0
@export var maximum_idle_time: float = 3.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _origin: Vector2
var _target: Vector2
var _idle_time_left: float = 0.0
var _last_direction: Vector2 = Vector2.DOWN
var _nearby_player: Node2D
var _is_talking := false


func _unhandled_input(event: InputEvent) -> void:
	if (
		not _is_talking
		and is_instance_valid(_nearby_player)
		and event.is_action_pressed("interact")
	):
		get_viewport().set_input_as_handled()
		_show_npc_dialog(_nearby_player)


func _ready() -> void:
	_origin = global_position
	_pick_new_target()


func _physics_process(delta: float) -> void:
	if is_instance_valid(_nearby_player):
		velocity = Vector2.ZERO
		_play_idle_animation()
		return

	if _idle_time_left > 0.0:
		_idle_time_left -= delta
		velocity = Vector2.ZERO
		_play_idle_animation()
		return

	if global_position.distance_to(_target) <= 8.0:
		_begin_idle()
		return

	var direction := global_position.direction_to(_target)
	velocity = direction * movement_speed
	_last_direction = direction
	move_and_slide()
	_play_walk_animation()

	if get_slide_collision_count() > 0:
		_begin_idle()


func _pick_new_target() -> void:
	var offset := Vector2(
		randf_range(-patrol_radius, patrol_radius),
		randf_range(-patrol_radius, patrol_radius)
	)
	_target = _origin + offset.limit_length(patrol_radius)


func _begin_idle() -> void:
	velocity = Vector2.ZERO
	_idle_time_left = randf_range(minimum_idle_time, maximum_idle_time)
	_pick_new_target()
	_play_idle_animation()


func _play_walk_animation() -> void:
	if absf(_last_direction.x) > absf(_last_direction.y):
		animated_sprite.flip_h = _last_direction.x < 0.0
		animated_sprite.play(&"walk_right")
	elif _last_direction.y < 0.0:
		animated_sprite.flip_h = false
		animated_sprite.play(&"walk_up")
	else:
		animated_sprite.flip_h = false
		animated_sprite.play(&"walk_down")


func _play_idle_animation() -> void:
	if absf(_last_direction.x) > absf(_last_direction.y):
		animated_sprite.flip_h = _last_direction.x < 0.0
		animated_sprite.play(&"idle_right")
	elif _last_direction.y < 0.0:
		animated_sprite.flip_h = false
		animated_sprite.play(&"idle_up")
	else:
		animated_sprite.flip_h = false
		animated_sprite.play(&"idle")


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_nearby_player = body
	if body.has_method("show_interaction_prompt"):
		body.call("show_interaction_prompt", self)
	else:
		var icon := body.get_node_or_null("Icone_interacao/Sprite2D")
		if icon != null:
			icon.visible = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body != _nearby_player:
		return

	if body.has_method("hide_interaction_prompt"):
		body.call("hide_interaction_prompt", self)
	else:
		var icon := body.get_node_or_null("Icone_interacao/Sprite2D")
		if icon != null:
			icon.visible = false
	_nearby_player = null


func _show_npc_dialog(player: Node2D) -> void:
	_is_talking = true
	_set_interaction_prompt(player, false)
	var was_paused := get_tree().paused
	var was_player_physics_processing := player.is_physics_processing()
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO
	player.set_physics_process(false)

	var dialog := DIALOG_SCENE.instantiate()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(dialog)
	get_tree().paused = true
	await dialog.start_dialog(_build_dialog_data())
	dialog.queue_free()
	get_tree().paused = was_paused

	if is_instance_valid(player):
		player.set_physics_process(was_player_physics_processing)
	_is_talking = false
	if is_instance_valid(_nearby_player):
		_set_interaction_prompt(_nearby_player, true)


func _build_dialog_data() -> Array[Dictionary]:
	var lines: Array[String] = ["......"]
	var gem_recovered := GameData.has_recovered_dialogue_gem()
	if gem_recovered:
		lines = _get_recovered_dialogue_lines()

	var data: Array[Dictionary] = []
	for line in lines:
		data.append({
			"name": "Morador da Vila",
			"text": line,
			"portrait_visible": false,
		})

	if not gem_recovered:
		var milestone := GameData.register_silent_npc_conversation(_get_dialogue_id())
		if milestone > 0:
			data.append({
				"name": "Lumen",
				"text": "Parece que nenhum dos moradores estão muito confusos para nos entender.",
				"speaker": "lumen",
			})
			data.append({
				"name": "Lumen",
				"text": "Precisamos encontrar a gema de outra forma, mas como?",
				"speaker": "lumen",
			})
			data.append({
				"name": "Lumen",
				"text": "Sinto uma energia ao norte daqui, será que pode ser a gema?",
				"speaker": "lumen",
			})
	return data


func _get_dialogue_id() -> String:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return String(get_path())
	return "%s:%s" % [current_scene.scene_file_path, current_scene.get_path_to(self)]


func _get_recovered_dialogue_lines() -> Array[String]:
	var npc_name := String(name).to_lower()
	if npc_name.begins_with("cogu_azul"):
		return ["Por tanto tempo eu via todos falando, mas não conseguia realmente escutá-los. É bom ouvir sua voz."]
	if npc_name.begins_with("cogu_roxo"):
		return ["O silêncio nos deixou desconfiados e isolados. Agora as vozes da vila estão voltando a se encontrar."]
	return ["Passei tanto tempo sem compreender o que chegava aos meus ouvidos... Obrigado por devolver a escuta ao nosso povo."]


func _set_interaction_prompt(player: Node2D, visible: bool) -> void:
	if visible and player.has_method("show_interaction_prompt"):
		player.call("show_interaction_prompt", self)
		return
	if not visible and player.has_method("hide_interaction_prompt"):
		player.call("hide_interaction_prompt", self)
		return
	var icon := player.get_node_or_null("Icone_interacao/Sprite2D")
	if icon != null:
		icon.visible = visible


func _exit_tree() -> void:
	if is_instance_valid(_nearby_player):
		_set_interaction_prompt(_nearby_player, false)
