extends Node2D

func _ready() -> void:
	if GameData.spawn_id == "":
		return
	call_deferred("_apply_spawn")

func _apply_spawn() -> void:
	var spawn_name = GameData.spawn_id.trim_prefix("../")
	var current_scene = get_tree().current_scene

	var spawn: Node = null
	for child in current_scene.get_children():
		if child.name == spawn_name:
			spawn = child
			break

	if spawn == null:
		push_warning("Spawn nao encontrado: " + spawn_name)
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("Player nao encontrado!")
		return

	player.global_position = spawn.global_position

	# Posiciona a Lumen ao lado do player no spawn
	var lumen = get_tree().get_first_node_in_group("lumen")
	if lumen:
		lumen.global_position = spawn.global_position + Vector2(-40, -20)

	GameData.spawn_id = ""
