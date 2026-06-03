extends CanvasLayer

const OVERWORLD_PATH_PREFIX := "res://world/"
const EXCLUDED_PATH_FRAGMENTS := ["tittle_screen", "troca_fase"]
const GRIMOIRE_TABS_SCENE := preload("res://ui/grimoire/grimoire_tabs.tscn")

@onready var root_panel: PanelContainer = $Root
@onready var item_list: VBoxContainer = %ItemList
@onready var feedback_label: Label = %FeedbackLabel
@onready var empty_label: Label = %EmptyLabel
@onready var grimoire_content: Control = %GrimoireContent

var _embedded_grimoire_tabs: TabContainer

var _is_open := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_grimoire_tab()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		if _is_open:
			_close()
		elif _can_open():
			_open()
		return
	if _is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _can_open() -> bool:
	var current := get_tree().current_scene
	if current == null:
		return false
	if WorldGrimoire.is_open():
		return false
	var path := current.scene_file_path
	if not path.begins_with(OVERWORLD_PATH_PREFIX):
		return false
	for fragment in EXCLUDED_PATH_FRAGMENTS:
		if path.contains(fragment):
			return false
	return true

func _open() -> void:
	_is_open = true
	get_tree().paused = true
	feedback_label.text = ""
	_refresh_items()
	_refresh_grimoire_tabs()
	show()

func _setup_grimoire_tab() -> void:
	_embedded_grimoire_tabs = GRIMOIRE_TABS_SCENE.instantiate() as TabContainer
	if _embedded_grimoire_tabs == null:
		return
	_embedded_grimoire_tabs.set_anchors_preset(Control.PRESET_FULL_RECT)
	_embedded_grimoire_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_embedded_grimoire_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grimoire_content.add_child(_embedded_grimoire_tabs)

func _refresh_grimoire_tabs() -> void:
	if _embedded_grimoire_tabs == null:
		return
	for tab in _embedded_grimoire_tabs.get_children():
		if tab.has_method("refresh"):
			tab.refresh()

func _close() -> void:
	_is_open = false
	get_tree().paused = false
	hide()

func is_open() -> bool:
	return _is_open

func _refresh_items() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var items := GameData.get_inventory_items()
	empty_label.visible = items.is_empty()

	for item in items:
		var button := Button.new()
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.text = _format_item_label(item)
		button.tooltip_text = item.description
		button.disabled = not GameData.can_use_world_item(item)
		button.focus_mode = Control.FOCUS_ALL
		if not button.disabled:
			button.pressed.connect(_on_item_pressed.bind(item))
		item_list.add_child(button)

	await get_tree().process_frame
	_focus_first_enabled_button()

func _focus_first_enabled_button() -> void:
	for child in item_list.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return

func _format_item_label(item: ItemResource) -> String:
	var qty := GameData.get_item_quantity(item)
	var effect := ""
	match item.effectType:
		ItemResource.Effect_Type.HEAL_HP:
			effect = "HP +%d" % item.power
		ItemResource.Effect_Type.RESTORE_MP:
			effect = "MP +%d" % item.power
		ItemResource.Effect_Type.DAMAGE:
			effect = "DMG %d" % item.power
	return "%s x%d  -  %s" % [item.name, qty, effect]

func _on_item_pressed(item: ItemResource) -> void:
	if not GameData.can_use_world_item(item):
		return

	var party := GameData.party_resources
	if party.is_empty() or party[0] == null:
		feedback_label.text = "Nenhum personagem disponível."
		return

	var target: CharacterResource = party[0]
	item.apply_to(target)
	GameData.consume_world_item(item)
	feedback_label.text = "Usou %s em %s." % [item.name, target.name]
	_refresh_items()
