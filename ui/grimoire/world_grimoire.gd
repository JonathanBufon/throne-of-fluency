extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("grimoire"):
		return

	get_viewport().set_input_as_handled()
	if WorldInventory.is_showing_grimoire():
		WorldInventory.close()
	else:
		WorldInventory.open_grimoire()

func open() -> void:
	WorldInventory.open_grimoire()

func close() -> void:
	if WorldInventory.is_showing_grimoire():
		WorldInventory.close()

func toggle() -> void:
	if WorldInventory.is_showing_grimoire():
		close()
	else:
		open()

func is_open() -> bool:
	return WorldInventory.is_showing_grimoire()
