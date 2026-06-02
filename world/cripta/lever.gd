extends Node2D

const LOWERED_SPIKE_FRAME := 4
const RAISED_SPIKE_FRAME := 0
const TUTORIAL_SPIKES := [
	"Spikes/spike_1",
	"Spikes/spike_2",
	"Spikes/spike_3",
	"Spikes/spike_4",
]
const SEQUENCE_SPIKES := [
	"Spikes/spike_5",
	"Spikes/spike_6",
	"Spikes/spike_7",
	"Spikes/spike_8",
	"Spikes/spike_9",
	"Spikes/spike_10",
]
const SEQUENCE_WALLS := [
	"Paredes/parede_1",
	"Paredes/parede_2",
	"Paredes/parede_3",
	"Paredes/parede_4",
]
const LEVER_SEQUENCE := [
	"lever_2",
	"lever_5",
	"lever_3",
	"lever_4",
]
const TUTORIAL_LEVER_NAME := "lever_1"

static var sequence_progress := 0
static var sequence_completed := false

var player_near := false
var pulled := false
var waiting_input := false

@onready var lever_esquerda: Sprite2D = $lever_esquerda
@onready var lever_direita: Sprite2D = $lever_direita

var _initial_texture: Texture2D
var _pulled_texture: Texture2D


func _ready() -> void:
	_initial_texture = lever_esquerda.texture
	_pulled_texture = lever_direita.texture
	_set_pulled(false)


func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("interact"):
		try_pull()


func try_pull() -> void:
	if pulled or waiting_input:
		return

	waiting_input = true
	var correct := await _ask_pull_action()
	waiting_input = false

	if correct and not _is_sequence_lever():
		_set_pulled(true)
		var player := get_tree().get_first_node_in_group("player")
		if player:
			_set_player_interaction_icon(player, false)


func _ask_pull_action() -> bool:
	var dialog := _get_action_dialog()
	if dialog == null or not dialog.has_method("ask"):
		return false

	var previous_hint: String = dialog.hint_text
	var previous_answer: String = dialog.correct_answer
	var previous_success: String = dialog.success_feedback
	var previous_failure: String = dialog.failure_feedback

	dialog.hint_text = "What is the action to pull the lever?"
	dialog.correct_answer = "pull"
	dialog.success_feedback = _get_pull_success_feedback()
	dialog.failure_feedback = "Wrong Action"

	if not dialog.answered.is_connected(_on_action_dialog_answered):
		dialog.answered.connect(_on_action_dialog_answered)

	var correct: bool = await dialog.ask()

	if dialog.answered.is_connected(_on_action_dialog_answered):
		dialog.answered.disconnect(_on_action_dialog_answered)

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


func _set_pulled(value: bool) -> void:
	pulled = value
	lever_esquerda.texture = _pulled_texture if pulled else _initial_texture
	lever_esquerda.visible = true
	lever_direita.visible = false
	if name == TUTORIAL_LEVER_NAME:
		if pulled:
			_set_spikes_frame(TUTORIAL_SPIKES, LOWERED_SPIKE_FRAME)
		else:
			_set_spikes_frame(TUTORIAL_SPIKES, RAISED_SPIKE_FRAME)


func _set_spikes_frame(spike_paths: Array, target_frame: int) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	for spike_path in spike_paths:
		var spike := scene.get_node_or_null(NodePath(spike_path)) as AnimatedSprite2D
		if spike == null:
			continue
		spike.stop()
		spike.frame = target_frame
		spike.frame_progress = 0.0
		_set_spike_collision_enabled(spike, target_frame != LOWERED_SPIKE_FRAME)


func _set_spike_collision_enabled(spike: AnimatedSprite2D, enabled: bool) -> void:
	var collision := spike.get_node_or_null("SpikeBody/CollisionShape2D") as CollisionShape2D
	if collision:
		collision.disabled = not enabled


func _on_action_dialog_answered(_text: String, correct: bool) -> void:
	if correct:
		_set_pulled(true)
		_handle_sequence_pull()
		var player := get_tree().get_first_node_in_group("player")
		if player:
			_set_player_interaction_icon(player, false)


func _get_pull_success_feedback() -> String:
	if not _is_sequence_lever():
		return "The lever moves."
	if sequence_completed:
		return "A passagem ja esta aberta."
	if name == LEVER_SEQUENCE[sequence_progress]:
		if sequence_progress == LEVER_SEQUENCE.size() - 1:
			return "Sequencia correta! A passagem abriu."
		return "Alavanca correta."
	return "Alavanca errada. Comece de novo."


func _handle_sequence_pull() -> void:
	if not _is_sequence_lever() or sequence_completed:
		return

	if name != LEVER_SEQUENCE[sequence_progress]:
		_reset_sequence_puzzle()
		return

	sequence_progress += 1
	if sequence_progress >= LEVER_SEQUENCE.size():
		sequence_completed = true
		_open_sequence_puzzle()


func _is_sequence_lever() -> bool:
	return LEVER_SEQUENCE.has(name)


func _open_sequence_puzzle() -> void:
	_set_spikes_frame(SEQUENCE_SPIKES, LOWERED_SPIKE_FRAME)
	_set_walls_open(true)


func _reset_sequence_puzzle() -> void:
	sequence_progress = 0
	sequence_completed = false
	_set_spikes_frame(SEQUENCE_SPIKES, RAISED_SPIKE_FRAME)
	_set_walls_open(false)
	_reset_sequence_levers()


func _set_walls_open(open: bool) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	for wall_path in SEQUENCE_WALLS:
		var wall := scene.get_node_or_null(NodePath(wall_path))
		if wall and wall.has_method("set_open"):
			wall.set_open(open)


func _reset_sequence_levers() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	for lever_name in LEVER_SEQUENCE:
		var lever := scene.get_node_or_null(NodePath("Scenario/Alavancas/" + lever_name))
		if lever and lever.has_method("reset_pulled_state"):
			lever.reset_pulled_state()


func reset_pulled_state() -> void:
	_set_pulled(false)


func _on_area_lever_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true
		if not pulled:
			_set_player_interaction_icon(body, true)


func _on_area_lever_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false
		_set_player_interaction_icon(body, false)


func _set_player_interaction_icon(player: Node, visible: bool) -> void:
	var icon := player.get_node_or_null("Icone_interacao/Sprite2D")
	if icon:
		icon.visible = visible
