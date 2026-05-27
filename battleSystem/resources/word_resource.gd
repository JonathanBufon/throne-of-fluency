extends Resource
class_name WordResource

@export var text_en: String = ""
@export var text_pt: String = ""
@export var part_of_speech: Part_Of_Speech = Part_Of_Speech.OTHER
@export var icon: Texture2D

enum Part_Of_Speech { NOUN, VERB, ADJECTIVE, OTHER }

func get_part_of_speech_label() -> String:
	match part_of_speech:
		Part_Of_Speech.NOUN:
			return "substantivo"
		Part_Of_Speech.VERB:
			return "verbo"
		Part_Of_Speech.ADJECTIVE:
			return "adjetivo"
		_:
			return ""
