extends CanvasLayer

const OVERWORLD_PATH_PREFIX := "res://world/"
const EXCLUDED_PATH_FRAGMENTS := ["tittle_screen", "troca_fase"]

@onready var grimoire_tabs: TabContainer = $Root/VBox/GrimoireTabs

var _is_open := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("grimoire"):
		get_viewport().set_input_as_handled()
		if _is_open:
			close()
		elif _can_open():
			open()
		return
	if _is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _can_open() -> bool:
	var current := get_tree().current_scene
	if current == null:
		return false
	if _is_inventory_open():
		return false
	if _has_visible_dialog(current):
		return false
	var path := current.scene_file_path
	if not path.begins_with(OVERWORLD_PATH_PREFIX):
		return false
	for fragment in EXCLUDED_PATH_FRAGMENTS:
		if path.contains(fragment):
			return false
	return true

func _has_visible_dialog(current: Node) -> bool:
	var dialog := current.find_child("Dialogo_Acao_Input", true, false)
	return dialog is CanvasItem and (dialog as CanvasItem).visible

func _is_inventory_open() -> bool:
	var inventory := get_node_or_null("/root/WorldInventory")
	if inventory == null:
		return false
	if inventory.has_method("is_open"):
		return inventory.is_open()
	return inventory is CanvasItem and (inventory as CanvasItem).visible

func open() -> void:
	if _is_open:
		return
	if not _can_open():
		return
	_is_open = true
	get_tree().paused = true
	_refresh_all_tabs()
	show()

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	get_tree().paused = false
	hide()

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func is_open() -> bool:
	return _is_open

func _refresh_all_tabs() -> void:
	if grimoire_tabs == null:
		return
	for tab in grimoire_tabs.get_children():
		if tab.has_method("refresh"):
			tab.refresh()
