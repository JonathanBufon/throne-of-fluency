extends CanvasLayer

@onready var bg_overlay: ColorRect = $bg_overlay
@onready var menu_holder: VBoxContainer = $bg_overlay/menu_holder
@onready var resume_button: TextureButton = $bg_overlay/menu_holder/resume_button
@onready var quit_button: TextureButton = $bg_overlay/menu_holder/quit_button

var _is_open := false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_apply_visual_state(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_open:
		get_viewport().set_input_as_handled()
		_close()
		return
	if not _can_open():
		return
	get_viewport().set_input_as_handled()
	_open()


func _can_open() -> bool:
	return not _is_other_overlay_open()


func _is_other_overlay_open() -> bool:
	var grimoire := get_node_or_null("/root/WorldGrimoire")
	if grimoire and grimoire.has_method("is_open") and grimoire.is_open():
		return true
	var inventory := get_node_or_null("/root/WorldInventory")
	if inventory and inventory.has_method("is_open") and inventory.is_open():
		return true
	return false


func _open() -> void:
	_is_open = true
	visible = true
	_apply_visual_state(true)
	get_tree().paused = true
	resume_button.grab_focus()


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	_apply_visual_state(false)
	visible = false
	get_tree().paused = false


func _apply_visual_state(open: bool) -> void:
	if menu_holder:
		menu_holder.modulate.a = 1.0 if open else 0.0
	if bg_overlay and bg_overlay.material is ShaderMaterial:
		(bg_overlay.material as ShaderMaterial).set_shader_parameter("lod", 1.0 if open else 0.0)


func is_open() -> bool:
	return _is_open


func _on_resume_button_pressed() -> void:
	_close()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
