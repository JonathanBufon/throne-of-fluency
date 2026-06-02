extends CanvasLayer

const OVERWORLD_PATH_PREFIX := "res://world/"
const EXCLUDED_PATH_FRAGMENTS := ["tittle_screen", "troca_fase"]

@onready var grimoire_tabs: TabContainer = %GrimoireTabs

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
	var path := current.scene_file_path
	if not path.begins_with(OVERWORLD_PATH_PREFIX):
		return false
	for fragment in EXCLUDED_PATH_FRAGMENTS:
		if path.contains(fragment):
			return false
	return true

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
