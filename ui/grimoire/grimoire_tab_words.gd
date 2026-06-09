extends Control

@onready var word_list: VBoxContainer = %WordList
@onready var empty_label: Label = %EmptyLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh()

func refresh() -> void:
	_clear_word_list()

	var words := GameData.known_words
	empty_label.visible = words.is_empty()

	for word in words:
		if word == null:
			continue
		var label := Label.new()
		label.process_mode = Node.PROCESS_MODE_ALWAYS
		label.text = _format_word_label(word)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		word_list.add_child(label)

func _clear_word_list() -> void:
	for child in word_list.get_children():
		word_list.remove_child(child)
		child.queue_free()

func _format_word_label(word: WordResource) -> String:
	var pos := word.get_part_of_speech_label()
	if pos.is_empty():
		return "%s — %s" % [word.text_en, word.text_pt]
	return "%s — %s (%s)" % [word.text_en, word.text_pt, pos]
