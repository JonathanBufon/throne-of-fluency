extends PanelContainer

@onready var name_label: Label = %Name
@onready var hp_2_label: Label = %HP2
@onready var mana_2_label: Label = %Mana2
@onready var over_drive_bar: ProgressBar = %OverDriveBar

var focusStyleBox = preload("res://battleSystem/data/characters/focus_player_stats.tres")
var normalStyleBox :StyleBox = StyleBoxEmpty.new()
var deadStyleBox := StyleBoxFlat.new()
var characterResource: Resource
var oldCharacterResource: Resource

func _ready() -> void:
	deadStyleBox.bg_color = Color(0.22, 0.22, 0.26, 0.78)
	deadStyleBox.border_width_left = 2
	deadStyleBox.border_width_top = 2
	deadStyleBox.border_width_right = 2
	deadStyleBox.border_width_bottom = 2
	deadStyleBox.border_color = Color(0.55, 0.1, 0.1, 1.0)
	
func _process(delta: float) -> void:
	var refreshed = _check_change_data()
	
	if refreshed: 
		_update_stats()
		oldCharacterResource = characterResource.duplicate()
		_refresh_life_state()

func _check_change_data():
	var healthChanged = characterResource["currentHealth"] != oldCharacterResource["currentHealth"]
	var manaChanged = characterResource["currentMana"] != oldCharacterResource["currentMana"]
	var overDriveChanged = characterResource["overDriveValue"] != oldCharacterResource["overDriveValue"]
	
	if healthChanged or manaChanged or overDriveChanged:
		return true
	
	return false

func _update_stats() -> void:
	_refresh_animation(hp_2_label, characterResource["currentHealth"])
	_refresh_animation(mana_2_label, characterResource["currentMana"])
	_refresh_animation(over_drive_bar, characterResource["overDriveValue"])

func _refresh_animation(node: Control, newValue: int) -> void:
	var tween = get_tree().create_tween()
	
	if node is Label:
		var oldValue = int(node.text)
		tween.tween_method(tween_label.bind(node), oldValue, newValue, 0.3)
	elif node is ProgressBar:
		var oldValue = node.value
		tween.tween_method(tween_progress_bar.bind(node), oldValue, newValue, 0.3)
		
func tween_label(value: int, labelNode: Label):
	labelNode.text = str(value)
	
func tween_progress_bar(value: int, progressBarNode: ProgressBar):
	progressBarNode.value = value
	
func activate_focus() -> void:
	if characterResource != null and characterResource.is_dead():
		add_theme_stylebox_override("panel", deadStyleBox)
		return
	add_theme_stylebox_override("panel", focusStyleBox)
	
func deactivate_focus() -> void:
	if characterResource != null and characterResource.is_dead():
		add_theme_stylebox_override("panel", deadStyleBox)
		return
	add_theme_stylebox_override("panel", normalStyleBox)

func set_player_stats(newCharacterResource: Resource) -> void:
	characterResource = newCharacterResource

	name_label.text = characterResource["name"]
	hp_2_label.text = str(characterResource["currentHealth"])
	mana_2_label.text = str(characterResource["currentMana"])
	over_drive_bar.value = characterResource["overDriveValue"]

	oldCharacterResource = characterResource.duplicate()
	_refresh_life_state()

func _refresh_life_state() -> void:
	var is_dead := characterResource != null and characterResource.is_dead()
	modulate = Color(0.62, 0.62, 0.68, 1.0) if is_dead else Color.WHITE
	if is_dead:
		add_theme_stylebox_override("panel", deadStyleBox)
