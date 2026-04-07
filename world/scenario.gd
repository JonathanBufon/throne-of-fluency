extends Node2D

func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_button_pressed():
	get_tree().change_scene_to_file("res://world/cenario1.tscn")
