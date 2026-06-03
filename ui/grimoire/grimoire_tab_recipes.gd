extends Control

@onready var recipe_list: VBoxContainer = %RecipeList
@onready var empty_label: Label = %EmptyLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh()

func refresh() -> void:
	_clear_recipe_list()

	var rendered_count := 0
	for recipe in GameData.ALL_SPELL_RECIPES:
		if recipe == null:
			continue
		if recipe.get_known_word_count(GameData.known_words) <= 0:
			continue
		var label := Label.new()
		label.process_mode = Node.PROCESS_MODE_ALWAYS
		label.text = _format_recipe_label(recipe)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		recipe_list.add_child(label)
		rendered_count += 1

	empty_label.visible = rendered_count == 0

func _clear_recipe_list() -> void:
	for child in recipe_list.get_children():
		recipe_list.remove_child(child)
		child.queue_free()

func _format_recipe_label(recipe: SpellRecipeResource) -> String:
	var recipe_name := _get_recipe_name(recipe)
	var word_parts := PackedStringArray()
	for word in recipe.words:
		if word != null and GameData.has_word(word):
			word_parts.append(word.text_en)
		else:
			word_parts.append("???")

	var status := "Disponível"
	if GameData.is_spell_prepared(recipe):
		status = "Preparada ✓"

	var description := recipe.description.strip_edges()
	if description.is_empty():
		return "%s: %s — %s" % [recipe_name, " + ".join(word_parts), status]
	return "%s: %s — %s\n%s" % [recipe_name, " + ".join(word_parts), status, description]

func _get_recipe_name(recipe: SpellRecipeResource) -> String:
	if recipe.resource_path.is_empty():
		if recipe.result_skill != null and not recipe.result_skill.name.is_empty():
			return recipe.result_skill.name
		return "Receita"
	return recipe.resource_path.get_file().get_basename()
