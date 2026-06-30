extends CanvasLayer

var _arrow: Label


func _ready() -> void:
	layer = 15
	_build_objective_ui()


func _process(_delta: float) -> void:
	visible = not GameData.has_recovered_dialogue_gem()


func _build_objective_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-210, 18)
	panel.custom_minimum_size = Vector2(420, 86)
	add_child(panel)

	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	_arrow = Label.new()
	_arrow.text = "↑"
	_arrow.add_theme_font_size_override("font_size", 42)
	content.add_child(_arrow)

	var objective_text := Label.new()
	objective_text.text = "SIGA PARA O NORTE\nEncontre a Gema do Diálogo"
	objective_text.add_theme_font_size_override("font_size", 17)
	content.add_child(objective_text)

	var pulse := create_tween().set_loops()
	pulse.tween_property(_arrow, "position:y", -6.0, 0.45)
	pulse.tween_property(_arrow, "position:y", 3.0, 0.45)
