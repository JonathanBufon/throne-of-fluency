extends CanvasLayer

const OVERWORLD_PATH_PREFIX := "res://world/"
const EXCLUDED_PATH_FRAGMENTS := ["tittle_screen", "troca_fase"]
const GRIMOIRE_TABS_SCENE := preload("res://ui/grimoire/grimoire_tabs.tscn")

enum BookPage { INVENTORY, GRIMOIRE }

@onready var root_panel: Control = $Root
@onready var page_content: Control = %PageContent
@onready var book_visual: Node2D = $Root/BookVisual
@onready var inventory_tab_sprite: Sprite2D = $Root/BookVisual/mini_aba_vermelho
@onready var grimoire_tab_sprite: Sprite2D = $Root/BookVisual/mini_aba_azul
@onready var item_list: VBoxContainer = %ItemList
@onready var feedback_label: Label = %FeedbackLabel
@onready var empty_label: Label = %EmptyLabel
@onready var character_status: Label = %CharacterStatus
@onready var grimoire_content: Control = %GrimoireContent
@onready var inventory_tabs: TabContainer = $Root/PageContent/InventoryTabs
@onready var items_tab: Button = %ItemsTab
@onready var grimoire_tab: Button = %GrimoireTab

var _embedded_grimoire_tabs: TabContainer

var _is_open := false
var _is_animating := false
var _current_page: BookPage = BookPage.INVENTORY

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_grimoire_tab()
	items_tab.pressed.connect(show_inventory_page)
	grimoire_tab.pressed.connect(show_grimoire_page)
	root_panel.pivot_offset = root_panel.size * 0.5
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		if _is_open and _current_page == BookPage.INVENTORY:
			_close()
		elif _is_open:
			show_inventory_page()
		elif can_open():
			_open(BookPage.INVENTORY)
		return
	if _is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func can_open() -> bool:
	var current := get_tree().current_scene
	if current == null:
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

func _open(page: BookPage) -> void:
	if _is_animating:
		return
	_is_open = true
	get_tree().paused = true
	feedback_label.text = ""
	_refresh_items()
	_refresh_grimoire_tabs()
	show()
	_set_page(page)
	_play_open_animation()

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
	if not _is_open or _is_animating:
		return
	_is_open = false
	_is_animating = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(root_panel, "scale:x", 0.04, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(root_panel, "modulate:a", 0.25, 0.16)
	await tween.finished
	hide()
	root_panel.scale = Vector2.ONE
	root_panel.modulate = Color.WHITE
	get_tree().paused = false
	_is_animating = false

func is_open() -> bool:
	return _is_open

func open() -> void:
	if not _is_open and can_open():
		_open(BookPage.INVENTORY)
	elif _is_open:
		show_inventory_page()

func open_grimoire() -> void:
	if not _is_open and can_open():
		_open(BookPage.GRIMOIRE)
	elif _is_open:
		show_grimoire_page()

func close() -> void:
	_close()

func is_showing_grimoire() -> bool:
	return _is_open and _current_page == BookPage.GRIMOIRE

func show_inventory_page() -> void:
	if not _is_open:
		return
	_refresh_items()
	_set_page(BookPage.INVENTORY)

func show_grimoire_page() -> void:
	if not _is_open:
		return
	_refresh_grimoire_tabs()
	_set_page(BookPage.GRIMOIRE)

func _set_page(page: BookPage) -> void:
	_current_page = page
	inventory_tabs.current_tab = int(page)
	inventory_tab_sprite.modulate = Color.WHITE if page == BookPage.INVENTORY else Color(0.48, 0.48, 0.48, 0.82)
	grimoire_tab_sprite.modulate = Color.WHITE if page == BookPage.GRIMOIRE else Color(0.48, 0.48, 0.48, 0.82)

func _play_open_animation() -> void:
	_is_animating = true
	root_panel.scale = Vector2(0.04, 1.0)
	root_panel.modulate = Color(1, 1, 1, 0.25)
	page_content.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(root_panel, "scale:x", 1.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(root_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(page_content, "modulate:a", 1.0, 0.2).set_delay(0.12)
	await tween.finished
	_is_animating = false

func _refresh_items() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var items := GameData.get_inventory_items()
	empty_label.visible = items.is_empty()
	_refresh_character_status()

	for item in items:
		var button := Button.new()
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.text = _format_item_label(item)
		button.tooltip_text = item.description
		button.disabled = not GameData.can_use_world_item(item)
		button.focus_mode = Control.FOCUS_ALL
		_style_item_button(button)
		if not button.disabled:
			button.pressed.connect(_on_item_pressed.bind(item))
		item_list.add_child(button)

	await get_tree().process_frame
	_focus_first_enabled_button()

func _style_item_button(button: Button) -> void:
	var transparent_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", transparent_style)
	button.add_theme_stylebox_override("hover", transparent_style)
	button.add_theme_stylebox_override("pressed", transparent_style)
	button.add_theme_stylebox_override("disabled", transparent_style)
	button.add_theme_stylebox_override("focus", transparent_style)
	button.add_theme_color_override("font_color", Color(0.25, 0.13, 0.07, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.42, 0.2, 0.07, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.12, 0.34, 0.16, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.46, 0.38, 0.31, 0.8))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _refresh_character_status() -> void:
	var party := GameData.party_resources
	if party.is_empty() or party[0] == null:
		character_status.text = "Nenhum personagem disponível."
		return

	var character: CharacterResource = party[0]
	character_status.text = "%s\n\nHP  %d / %d\nMP  %d / %d" % [
		character.name,
		character.currentHealth,
		character.maxHealth,
		character.currentMana,
		character.maxMana,
	]

func _focus_first_enabled_button() -> void:
	for child in item_list.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return

func _format_item_label(item: ItemResource) -> String:
	var qty := GameData.get_item_quantity(item)
	var effect := ""
	if not item.usableInWorld and not item.usableInBattle:
		effect = "Item-chave"
	else:
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
