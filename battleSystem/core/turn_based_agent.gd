extends Node
class_name TurnBasedAgent

signal target_selected(target: TurnBasedAgent, command: Resource)
signal undo_command_selected()
signal turn_finished()
signal player_turn_started()

@export var character_resource: CharacterResource
@export var character_type: Character_Type
@export var basicAttack: Resource
@export var skills: Array[Resource]

@export var onTurnIconOffSet: Vector2 = Vector2(0, -50)
@export var targetIconOffSet: Vector2 = Vector2(50, 0)
@export var active_modulate := Color(1.25, 1.25, 1.05, 1.0)
@export var target_modulate := Color(1.2, 0.78, 0.78, 1.0)
@export var dead_modulate := Color(0.35, 0.35, 0.42, 1.0)

@onready var on_turn_icon_node: TextureRect = $onTurnIconNode
@onready var target_icon_node: TextureRect = $targetIconNode

enum Character_Type { PLAYER, ENEMY }

@export var isActive := false
var selectedCommand: Resource
var target: TurnBasedAgent
var _base_modulate := Color.WHITE
var _visual_node: CanvasItem
var _animated_sprite: AnimatedSprite2D
var _last_facing_direction := Vector2.DOWN

func get_global_position() -> Vector2:
	return get_parent().global_position

func command_done() -> void:
	turn_finished.emit()

func _input(event: InputEvent) -> void:
	if not isActive or not target:
		return

	var enemies := get_tree().get_nodes_in_group("enemy")
	var players := get_tree().get_nodes_in_group("player")

	if target in enemies:
		_select_between_targets(event, enemies)
	else:
		_select_between_targets(event, players)

	if event.is_action_pressed("ui_accept"):
		_select_target()
	elif event.is_action_pressed("ui_cancel"):
		_undo_command()

func _undo_command() -> void:
	target = null
	_deselect_all_targets()
	undo_command_selected.emit()

func _select_target() -> void:
	target_selected.emit(target, selectedCommand)
	_deselect_all_targets()
	set_active(false)
	target = null

func set_active(boolean: bool) -> void:
	if boolean and character_resource.is_dead():
		turn_finished.emit()
		return

	isActive = boolean

	if isActive:
		on_turn_icon_node.show()
		_apply_character_modulate(active_modulate)
	else:
		on_turn_icon_node.hide()
		_refresh_character_state_visual()

	if character_type == Character_Type.PLAYER and isActive:
		player_turn_started.emit()
	elif character_type == Character_Type.ENEMY and isActive:
		on_turn_icon_node.hide()
		var alive_players := get_tree().get_nodes_in_group("player").filter(
			func(a: TurnBasedAgent): return not a.character_resource.is_dead()
		)
		if alive_players.is_empty():
			turn_finished.emit()
			return
		target_selected.emit(alive_players.pick_random(), basicAttack)
		set_active(false)

func _select_between_targets(event: InputEvent, targets: Array) -> void:
	var alive_targets := targets.filter(
		func(a: TurnBasedAgent): return not a.character_resource.is_dead()
	)
	if alive_targets.is_empty():
		return

	var current_index := alive_targets.find(target)
	if current_index == -1:
		current_index = 0

	var go_left := event.is_action_pressed("ui_left")
	var go_right := event.is_action_pressed("ui_right")

	if not go_left and not go_right:
		return

	if go_left:
		current_index = (current_index - 1 + alive_targets.size()) % alive_targets.size()
	elif go_right:
		current_index = (current_index + 1) % alive_targets.size()

	_deselect_all_targets()
	target = alive_targets[current_index]
	target.set_target()

func _deselect_all_targets() -> void:
	var all_targets := get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("player")
	for t in all_targets:
		t.target_icon_node.hide()
		t._refresh_character_state_visual()

func _ready() -> void:
	_set_default_facing_direction()
	_set_visual_node()
	_set_group()
	_set_on_turn_icon()
	_set_target_icon()
	_refresh_character_state_visual()
	play_idle_current_direction()
	_set_late_signals()

func _set_visual_node() -> void:
	_animated_sprite = get_parent().get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_visual_node = _animated_sprite as CanvasItem
	if _visual_node == null:
		_visual_node = get_parent().get_node_or_null("Sprite2D") as CanvasItem
	if _visual_node:
		_base_modulate = _visual_node.modulate

func refresh_visual_node() -> void:
	_set_visual_node()
	_refresh_character_state_visual()
	play_idle_current_direction()

func play_idle_current_direction() -> void:
	_play_directional_animation("idle", _last_facing_direction)

func play_idle_towards(target_global_position: Vector2) -> void:
	_play_directional_animation("idle", target_global_position - get_global_position())

func play_attack_towards(target_global_position: Vector2) -> void:
	_play_directional_animation("attack", target_global_position - get_global_position())

func play_dying_and_wait() -> void:
	on_turn_icon_node.hide()
	target_icon_node.hide()

	if _animated_sprite == null or _animated_sprite.sprite_frames == null:
		_refresh_character_state_visual()
		await get_tree().create_timer(0.25).timeout
		return

	if not _animated_sprite.sprite_frames.has_animation("dying"):
		_refresh_character_state_visual()
		await get_tree().create_timer(0.25).timeout
		return

	var frame_count := _animated_sprite.sprite_frames.get_frame_count("dying")
	if frame_count <= 0:
		_refresh_character_state_visual()
		await get_tree().create_timer(0.25).timeout
		return

	_apply_character_modulate(_base_modulate)
	_animated_sprite.flip_h = false
	_animated_sprite.animation = "dying"
	_animated_sprite.set_frame_and_progress(0, 0.0)
	_animated_sprite.play()

	var animation_speed := _animated_sprite.sprite_frames.get_animation_speed("dying")
	var duration := 0.7
	if animation_speed > 0.0:
		duration = float(frame_count) / animation_speed

	await get_tree().create_timer(duration).timeout
	_animated_sprite.stop()
	_animated_sprite.set_frame_and_progress(frame_count - 1, 0.0)
	_refresh_character_state_visual()

func play_run_down() -> void:
	_play_named_animation("run_down")

func _set_default_facing_direction() -> void:
	if character_type == Character_Type.PLAYER:
		_last_facing_direction = Vector2.UP
	else:
		_last_facing_direction = Vector2.DOWN

func _play_directional_animation(prefix: String, direction: Vector2) -> void:
	if _animated_sprite == null or _animated_sprite.sprite_frames == null:
		return

	if direction == Vector2.ZERO:
		direction = _last_facing_direction
	else:
		_last_facing_direction = direction.normalized()

	var suffix := "down"
	var flip_h := false
	if absf(direction.x) > absf(direction.y):
		suffix = "right"
		flip_h = direction.x < 0
	elif direction.y < 0:
		suffix = "up"
	else:
		suffix = "down"

	var animation_name := "%s_%s" % [prefix, suffix]
	if not _animated_sprite.sprite_frames.has_animation(animation_name):
		animation_name = "idle_%s" % suffix
	if not _animated_sprite.sprite_frames.has_animation(animation_name):
		animation_name = "idle_right"
	if not _animated_sprite.sprite_frames.has_animation(animation_name):
		return

	_animated_sprite.flip_h = flip_h
	_animated_sprite.play(animation_name)

func _play_named_animation(animation_name: String) -> void:
	if _animated_sprite == null or _animated_sprite.sprite_frames == null:
		return
	if not _animated_sprite.sprite_frames.has_animation(animation_name):
		return

	_animated_sprite.flip_h = false
	_animated_sprite.play(animation_name)

func _set_group() -> void:
	add_to_group("turnBasedAgents")
	if character_type == Character_Type.PLAYER:
		add_to_group("player")
	elif character_type == Character_Type.ENEMY:
		add_to_group("enemy")

func _set_on_turn_icon() -> void:
	on_turn_icon_node.hide()
	on_turn_icon_node.global_position = (
		get_parent().global_position
		- (on_turn_icon_node.get_global_rect().size / 2)
		+ onTurnIconOffSet
	)

func _set_target_icon() -> void:
	target_icon_node.hide()
	target_icon_node.global_position = (
		get_parent().global_position
		- (target_icon_node.get_global_rect().size / 2)
		+ targetIconOffSet
	)
	if character_type == Character_Type.ENEMY:
		target_icon_node.modulate = Color(1, 0, 0)
	elif character_type == Character_Type.PLAYER:
		target_icon_node.modulate = Color(0, 1, 0)

func _set_late_signals() -> void:
	await get_tree().current_scene.ready
	var command_menu: CommandMenu = get_tree().get_first_node_in_group("commandMenu")
	command_menu.command_selected.connect(_on_command_selected)

func _on_command_selected(command: Resource) -> void:
	if not isActive:
		return

	selectedCommand = command

	var alive_enemies := get_tree().get_nodes_in_group("enemy").filter(
		func(a: TurnBasedAgent): return not a.character_resource.is_dead()
	)
	var alive_players := get_tree().get_nodes_in_group("player").filter(
		func(a: TurnBasedAgent): return not a.character_resource.is_dead()
	)

	if command.targetType == SkillResource.Target_Type.ENEMIES:
		if alive_enemies.is_empty():
			return
		target = alive_enemies[0]
	elif command.targetType == SkillResource.Target_Type.PLAYERS:
		if alive_players.is_empty():
			return
		target = alive_players[0]

	target.set_target()

func set_target() -> void:
	target_icon_node.show()
	_apply_character_modulate(target_modulate)

func _refresh_character_state_visual() -> void:
	if _visual_node == null:
		return
	if character_resource != null and character_resource.is_dead():
		_apply_character_modulate(dead_modulate)
	else:
		_apply_character_modulate(_base_modulate)

func _apply_character_modulate(color: Color) -> void:
	if _visual_node:
		_visual_node.modulate = color
