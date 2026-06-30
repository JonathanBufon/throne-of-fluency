extends Control

@onready var word_list: VBoxContainer = %WordList
@onready var empty_label: Label = %EmptyLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh()

func refresh() -> void:
	_clear_word_list()

	var words := GameData.get_grimoire_words()
	empty_label.visible = words.is_empty()

	for word in words:
		if word == null:
			continue
		_add_word_card(word, GameData.has_word(word))

func _add_word_card(word: WordResource, learned: bool) -> void:
	var card := PanelContainer.new()
	card.process_mode = Node.PROCESS_MODE_ALWAYS
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.content_margin_left = 10.0
	style.content_margin_top = 7.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 7.0
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	if learned:
		style.bg_color = Color(0, 0, 0, 0)
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.16, 0.08, 0.45)
	else:
		style.bg_color = Color(0.055, 0.045, 0.04, 0.94)
	card.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	label.text = _format_word_label(word, learned)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override(
		"font_color",
		Color(0.25, 0.13, 0.07, 1.0) if learned else Color(0.82, 0.76, 0.66, 1.0)
	)
	card.add_child(label)
	word_list.add_child(card)

func _clear_word_list() -> void:
	for child in word_list.get_children():
		word_list.remove_child(child)
		child.queue_free()

func _format_word_label(word: WordResource, learned: bool) -> String:
	if not learned:
		return "????  —  ????????"

	var pos := word.get_part_of_speech_label()
	if pos.is_empty():
		return "%s  —  %s" % [word.text_en.to_upper(), word.text_pt]
	return "%s  —  %s (%s)" % [word.text_en.to_upper(), word.text_pt, pos]
