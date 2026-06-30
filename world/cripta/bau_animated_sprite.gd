extends AnimatedSprite2D

@export var chest_id := "bau_1"
@export var required_word := "open"
@export var reward_item: ItemResource = preload("res://battleSystem/data/items/potion.tres")
@export var reward_quantity := 1
@export var open_animation := "abrir"
@export var closed_frame := 0
@export var interaction_radius := 70.0
@export var prompt_text := "What is the action to open the chest?"
@export var success_feedback := "The chest opens. You found an item!"
@export var failure_feedback := "Wrong Action"

var player_near := false
var opened := false
var waiting_input := false
var interaction_area: Area2D


func _ready() -> void:
	_setup_interaction_area()
	_prepare_closed_visual()
	if GameData.is_world_chest_opened(chest_id):
		_apply_opened_state(false)


func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("interact"):
		try_open()


func try_open() -> void:
	if opened or waiting_input:
		return

	waiting_input = true
	var correct := await _ask_open_action()
	waiting_input = false

	if correct:
		open_chest()


func open_chest() -> void:
	if opened:
		return

	_apply_opened_state(true)
	GameData.grant_world_item(reward_item, reward_quantity)
	GameData.mark_world_chest_opened(chest_id)
	_set_player_interaction_icon(false)


func _ask_open_action() -> bool:
	var dialog := _get_action_dialog()
	if dialog == null or not dialog.has_method("ask"):
		push_warning("Dialogo_Acao_Input nao encontrado na cena atual.")
		return false

	var previous_hint: String = dialog.hint_text
	var previous_answer: String = dialog.correct_answer
	var previous_success: String = dialog.success_feedback
	var previous_failure: String = dialog.failure_feedback

	dialog.hint_text = prompt_text
	dialog.correct_answer = required_word
	dialog.success_feedback = success_feedback
	dialog.failure_feedback = failure_feedback

	var correct: bool = await dialog.ask()

	dialog.hint_text = previous_hint
	dialog.correct_answer = previous_answer
	dialog.success_feedback = previous_success
	dialog.failure_feedback = previous_failure

	return correct


func _get_action_dialog() -> Dialogo_Acao_Input:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("Dialogo_Acao_Input", true, false) as Dialogo_Acao_Input


func _setup_interaction_area() -> void:
	interaction_area = get_node_or_null("InteractionArea") as Area2D
	if interaction_area == null:
		interaction_area = Area2D.new()
		interaction_area.name = "InteractionArea"
		add_child(interaction_area)

		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = interaction_radius
		collision.shape = shape
		interaction_area.add_child(collision)

	interaction_area.collision_layer = 0
	interaction_area.collision_mask = 2

	if not interaction_area.body_entered.is_connected(_on_interaction_area_body_entered):
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	if not interaction_area.body_exited.is_connected(_on_interaction_area_body_exited):
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)


func _prepare_closed_visual() -> void:
	if sprite_frames == null:
		return
	if sprite_frames.has_animation(open_animation):
		animation = open_animation
		stop()
		frame = closed_frame
		frame_progress = 0.0


func _apply_opened_state(play_animation: bool) -> void:
	opened = true
	if sprite_frames == null or not sprite_frames.has_animation(open_animation):
		return

	animation = open_animation
	if play_animation:
		play(open_animation)
	else:
		stop()
		frame = sprite_frames.get_frame_count(open_animation) - 1
		frame_progress = 0.0


func _set_player_interaction_icon(icon_visible: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var icon := player.get_node_or_null("Icone_interacao/Sprite2D")
	if icon:
		icon.visible = icon_visible


func _on_interaction_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true
		if not opened:
			_set_player_interaction_icon(true)


func _on_interaction_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false
		_set_player_interaction_icon(false)
