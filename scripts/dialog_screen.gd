extends Control


enum Mode { DIALOG, INPUT }

var _step: float = 0.05
var _animating: bool = false
var _id: int = 0
var _mode: Mode = Mode.DIALOG
var _expected_answer: String = ""

signal input_submitted(text: String)
signal dialog_finished

@export_category("objects")
@export var _name: Label = null
@export var _dialog: RichTextLabel = null
@export var _faceset: TextureRect = null
@export var _input_field: LineEdit = null

var data: Array = []


func _ready() -> void:
	if _input_field:
		_input_field.visible = false
		_input_field.text_submitted.connect(_on_input_submitted)
	hide()


func _process(_delta: float) -> void:
	if _mode == Mode.INPUT:
		return

	if _animating:
		if Input.is_action_pressed("ui_accept"):
			_step = 0.01
		else:
			_step = 0.05
		return

	if Input.is_action_just_pressed("ui_accept"):
		_id += 1
		if _id == data.size():
			_close()
			return
		_initialize_dialog()


# --------------------------------
# MODO DIÁLOGO
# Exemplo de uso:
#   var dialog = DialogScreenScene.instantiate()
#   add_child(dialog)
#   dialog.start_dialog([
#       {"title": "Guarda", "dialog": "Quem vai lá?", "faceset": "res://icon.svg"},
#       {"title": "Guarda", "dialog": "Diga a senha!", "faceset": "res://icon.svg"},
#   ])
# --------------------------------
func start_dialog(dialog_data: Array) -> void:
	_mode = Mode.DIALOG
	data = dialog_data
	_id = 0
	if _input_field:
		_input_field.visible = false
	get_tree().paused = true
	show()
	_initialize_dialog()


# --------------------------------
# MODO INPUT
# Exemplo de uso:
#   var dialog = DialogScreenScene.instantiate()
#   add_child(dialog)
#   var resposta = await dialog.start_input(
#       "Guarda", "Digite a senha:", "res://icon.svg", "push to open"
#   )
#   if resposta:
#       abrir_porta()
# --------------------------------
func start_input(speaker: String, prompt: String, faceset_path: String, expected: String) -> bool:
	_mode = Mode.INPUT
	_expected_answer = expected.to_lower()

	if _name:
		_name.text = speaker
	if _dialog:
		_dialog.text = prompt
		_dialog.visible_characters = -1
	if _faceset and faceset_path != "":
		_faceset.texture = load(faceset_path)
	if _input_field:
		_input_field.visible = true
		_input_field.text = ""

	get_tree().paused = true
	show()

	if _input_field:
		_input_field.grab_focus()

	var answer = await input_submitted
	return answer.to_lower() == _expected_answer


func _initialize_dialog() -> void:
	_animating = true

	if _name:
		_name.text = data[_id].get("title", "")
	if _dialog:
		_dialog.text = data[_id].get("dialog", "")
	if _faceset:
		var path = data[_id].get("faceset", "")
		if path != "":
			_faceset.texture = load(path)

	if _dialog:
		_dialog.visible_characters = 0
		while _dialog.visible_ratio < 1:
			await get_tree().process_frame
			await get_tree().create_timer(_step).timeout
			_dialog.visible_characters += 1

	_animating = false


func _on_input_submitted(text: String) -> void:
	if _input_field:
		_input_field.visible = false
	input_submitted.emit(text)
	_close()


func _close() -> void:
	get_tree().paused = false
	dialog_finished.emit()
	queue_free()
