extends Control

signal spell_prepared(recipe: SpellRecipeResource)

const MIN_SELECTION := 2
const MAX_SELECTION := 3

@onready var word_list: VBoxContainer = %WordList
@onready var prepare_button: Button = %PrepareButton
@onready var feedback_label: Label = %FeedbackLabel
@onready var empty_label: Label = %EmptyLabel

var _toggles: Array[CheckBox] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	prepare_button.pressed.connect(_on_prepare_pressed)
	refresh()

func refresh() -> void:
	for child in word_list.get_children():
		child.queue_free()
	_toggles.clear()
	feedback_label.text = ""

	var words := GameData.known_words
	empty_label.visible = words.is_empty()
	prepare_button.disabled = words.is_empty()

	for word in words:
		var toggle := CheckBox.new()
		toggle.process_mode = Node.PROCESS_MODE_ALWAYS
		toggle.text = _format_word_label(word)
		toggle.set_meta("word", word)
		toggle.toggled.connect(_on_toggle_changed)
		word_list.add_child(toggle)
		_toggles.append(toggle)

func _format_word_label(word: WordResource) -> String:
	var pos := word.get_part_of_speech_label()
	if pos.is_empty():
		return "%s — %s" % [word.text_en, word.text_pt]
	return "%s — %s (%s)" % [word.text_en, word.text_pt, pos]

func _on_toggle_changed(_pressed: bool) -> void:
	feedback_label.text = ""

func _collect_selected_words() -> Array[WordResource]:
	var selected: Array[WordResource] = []
	for toggle in _toggles:
		if toggle.button_pressed:
			var word := toggle.get_meta("word") as WordResource
			if word != null:
				selected.append(word)
	return selected

func _on_prepare_pressed() -> void:
	var selected := _collect_selected_words()
	if selected.size() < MIN_SELECTION or selected.size() > MAX_SELECTION:
		feedback_label.text = "Selecione entre %d e %d palavras." % [MIN_SELECTION, MAX_SELECTION]
		return

	var recipe := GameData.find_recipe_for_words(selected)
	if recipe == null:
		feedback_label.text = "Essas palavras não formam uma magia conhecida."
		return

	if GameData.is_spell_prepared(recipe):
		feedback_label.text = "%s já está preparada." % recipe.result_skill.name
		return

	if not GameData.prepare_spell(recipe):
		feedback_label.text = "Não foi possível preparar essa magia."
		return

	feedback_label.text = "%s preparada!" % recipe.result_skill.name
	spell_prepared.emit(recipe)
	for toggle in _toggles:
		toggle.set_pressed_no_signal(false)
