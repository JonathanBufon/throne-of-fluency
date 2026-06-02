extends CanvasLayer

signal dialog_finished

const DEFAULT_STEP := 0.04
const AUTO_ADVANCE_DELAY := 1.65

var _dialog_data: Array = []
var _index := 0
var _is_typing := false
var _typing_id := 0
var _auto_advance := false

@onready var _portrait: TextureRect = $Painel/MarginContainer/HBox/Retrato
@onready var _name_label: Label = $Painel/MarginContainer/HBox/Vbox/Nome
@onready var _text_label: RichTextLabel = $Painel/MarginContainer/HBox/Vbox/Texto
@onready var _advance_icon: Label = $Painel/MarginContainer/HBox/Vbox/Icone_Avancar


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if _auto_advance:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		if _is_typing:
			_finish_typing()
		else:
			_next_line()


func start_dialog(dialog_data: Array, auto_advance := false) -> void:
	if dialog_data.is_empty():
		return

	_dialog_data = dialog_data
	_index = 0
	_auto_advance = auto_advance
	show()
	_show_current_line()
	await dialog_finished


func _show_current_line() -> void:
	var line: Dictionary = _dialog_data[_index]
	_name_label.text = line.get("name", line.get("title", ""))
	_text_label.text = line.get("text", line.get("dialog", ""))
	_text_label.visible_characters = 0
	_advance_icon.visible = false
	_apply_portrait(line)
	_type_text()


func _apply_portrait(line: Dictionary) -> void:
	var portrait_visible := bool(line.get("portrait_visible", true))
	var portrait_path := String(line.get("portrait", line.get("faceset", "")))

	if not portrait_visible or portrait_path.is_empty():
		_portrait.hide()
		return

	var portrait_texture := load(portrait_path)
	if portrait_texture:
		_portrait.texture = portrait_texture
	_portrait.show()


func _type_text() -> void:
	_is_typing = true
	_typing_id += 1
	var current_typing_id := _typing_id

	while _text_label.visible_ratio < 1.0 and _is_typing and current_typing_id == _typing_id:
		await get_tree().create_timer(DEFAULT_STEP).timeout
		_text_label.visible_characters += 1

	if current_typing_id == _typing_id:
		_finish_typing()


func _finish_typing() -> void:
	_is_typing = false
	_typing_id += 1
	_text_label.visible_characters = -1
	_advance_icon.visible = not _auto_advance

	if _auto_advance:
		_auto_go_next()


func _auto_go_next() -> void:
	var current_index := _index
	await get_tree().create_timer(AUTO_ADVANCE_DELAY).timeout
	if visible and _auto_advance and current_index == _index and not _is_typing:
		_next_line()


func _next_line() -> void:
	_index += 1

	if _index >= _dialog_data.size():
		hide()
		_auto_advance = false
		dialog_finished.emit()
		return

	_show_current_line()
