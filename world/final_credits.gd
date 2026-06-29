extends CanvasLayer

@onready var obrigado_label: Label = $Obrigado
@onready var tbc_label: Label = $ToBeContinued


func _ready() -> void:
	obrigado_label.modulate.a = 0.0
	tbc_label.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(obrigado_label, "modulate:a", 1.0, 1.2)
	tween.tween_interval(0.6)
	tween.tween_property(tbc_label, "modulate:a", 1.0, 1.0)
	tween.tween_interval(10.0)
	tween.tween_callback(func(): get_tree().quit())
