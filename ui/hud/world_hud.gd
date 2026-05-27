extends CanvasLayer

const OVERWORLD_PATH_PREFIX := "res://world/"
const EXCLUDED_PATH_FRAGMENTS := ["tittle_screen", "troca_fase"]

@onready var root_panel: PanelContainer = $Root
@onready var name_level_label: Label = %NameLevelLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_text: Label = %HpText
@onready var mp_bar: ProgressBar = %MpBar
@onready var mp_text: Label = %MpText
@onready var gold_label: Label = %GoldLabel

func _ready() -> void:
	layer = 10
	hide()

func _process(_delta: float) -> void:
	if not _should_display():
		hide()
		return
	show()
	_refresh()

func _should_display() -> bool:
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

func _refresh() -> void:
	var party := GameData.party_resources
	if party.is_empty() or party[0] == null:
		root_panel.hide()
		return
	root_panel.show()

	var character: CharacterResource = party[0]
	name_level_label.text = "%s  Nv.%d" % [character.name, character.level]

	hp_bar.max_value = max(1, character.maxHealth)
	hp_bar.value = character.currentHealth
	hp_text.text = "%d/%d" % [character.currentHealth, character.maxHealth]

	mp_bar.max_value = max(1, character.maxMana)
	mp_bar.value = character.currentMana
	mp_text.text = "%d/%d" % [character.currentMana, character.maxMana]

	gold_label.text = "$ %d" % GameData.gold
