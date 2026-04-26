extends Area2D

@export var proxima_fase: String = ""
@export var spawn_id: String = ""

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if proxima_fase != "":
			GameData.spawn_id = spawn_id  # salva primeiro
			await get_tree().process_frame # espera um frame
			get_tree().change_scene_to_file(proxima_fase) # troca sem call_deferred
