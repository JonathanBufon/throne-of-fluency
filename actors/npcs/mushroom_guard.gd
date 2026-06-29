extends "res://actors/npcs/stationary_npc.gd"

@export var exit_offset := Vector2(180, 0)
@export var exit_duration := 1.0

var _blocking_position: Vector2
var _should_leave_block := false
var _is_leaving := false


func _ready() -> void:
	super()
	_blocking_position = position
	if GameData.has_returned_mushroom_glasses():
		position = _blocking_position + exit_offset


func _build_dialog_data() -> Array[Dictionary]:
	if not GameData.has_recovered_dialogue_gem():
		return super._build_dialog_data()

	if GameData.has_returned_mushroom_glasses():
		return [_dialog_line("Obrigado novamente pelos meus óculos. Agora o caminho está livre.")]

	if GameData.has_mushroom_glasses():
		GameData.return_mushroom_glasses()
		_should_leave_block = true
		return [
			_dialog_line("Meus óculos! Você os encontrou!"),
			_dialog_line("Agora consigo enxergar o caminho. Pode passar, vou sair da frente."),
		]

	return [
		_dialog_line("Não posso deixar você passar por este caminho."),
		_dialog_line("Esqueci meus óculos e não consigo verificar se é seguro. Se encontrá-los, traga-os para mim."),
	]


func _dialog_line(text: String) -> Dictionary:
	return {
		"name": "Guarda Cogumelo",
		"text": text,
		"portrait_visible": false,
	}


func _after_dialog_finished() -> void:
	if _should_leave_block and not _is_leaving:
		_should_leave_block = false
		_leave_blocking_position()


func _leave_blocking_position() -> void:
	_is_leaving = true
	_is_talking = true
	if is_instance_valid(_nearby_player):
		_set_interaction_prompt(_nearby_player, false)
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null:
		sprite.flip_h = exit_offset.x < 0.0
		sprite.play(&"walk_right")

	var tween := create_tween()
	tween.tween_property(self, "position", _blocking_position + exit_offset, exit_duration)
	await tween.finished

	if sprite != null:
		sprite.play(&"idle_right")
	_is_leaving = false
	_is_talking = false
	if is_instance_valid(_nearby_player):
		_set_interaction_prompt(_nearby_player, true)
