extends Node2D
class_name DamageNumber

@onready var label: Label = $Label

func show_value(text_value: String, is_heal: bool) -> void:
	label.text = text_value
	label.modulate = Color(0.48, 1.0, 0.58, 1.0) if is_heal else Color(1.0, 0.25, 0.25, 1.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -34), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()
