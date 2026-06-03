extends Resource
class_name SpellRecipeResource

@export var words: Array[WordResource] = []
@export var result_skill: SkillResource
@export_multiline var description: String = ""

func matches(input_words: Array) -> bool:
	if input_words.size() != words.size():
		return false
	var remaining := words.duplicate()
	for word in input_words:
		var idx := remaining.find(word)
		if idx == -1:
			return false
		remaining.remove_at(idx)
	return true

func get_known_word_count(known_words: Array) -> int:
	var count := 0
	for word in words:
		if word in known_words:
			count += 1
	return count

func is_fully_known(known_words: Array) -> bool:
	return get_known_word_count(known_words) == words.size()
