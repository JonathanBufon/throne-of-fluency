extends CharacterBody2D

const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")

@export var idle_animation: StringName = &"idle"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _nearby_player: Node2D
var _is_talking := false


func _unhandled_input(event: InputEvent) -> void:
	if (
		not _is_talking
		and is_instance_valid(_nearby_player)
		and event.is_action_pressed("interact")
	):
		get_viewport().set_input_as_handled()
		_show_npc_dialog(_nearby_player)


func _ready() -> void:
	animated_sprite.play(idle_animation)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_nearby_player = body
	if body.has_method("show_interaction_prompt"):
		body.call("show_interaction_prompt", self)
	else:
		var icon := body.get_node_or_null("Icone_interacao/Sprite2D")
		if icon != null:
			icon.visible = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body != _nearby_player:
		return

	if body.has_method("hide_interaction_prompt"):
		body.call("hide_interaction_prompt", self)
	else:
		var icon := body.get_node_or_null("Icone_interacao/Sprite2D")
		if icon != null:
			icon.visible = false
	_nearby_player = null


func _show_npc_dialog(player: Node2D) -> void:
	_is_talking = true
	_set_interaction_prompt(player, false)
	var was_paused := get_tree().paused
	var was_player_physics_processing := player.is_physics_processing()
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO
	player.set_physics_process(false)

	var dialog := DIALOG_SCENE.instantiate()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(dialog)
	get_tree().paused = true
	await dialog.start_dialog(_build_dialog_data())
	dialog.queue_free()
	get_tree().paused = was_paused

	if is_instance_valid(player):
		player.set_physics_process(was_player_physics_processing)
	_is_talking = false
	if is_instance_valid(_nearby_player):
		_set_interaction_prompt(_nearby_player, true)
	_after_dialog_finished()


func _after_dialog_finished() -> void:
	pass


func _build_dialog_data() -> Array[Dictionary]:
	var lines: Array[String] = ["......"]
	var gem_recovered := GameData.has_recovered_dialogue_gem()
	if gem_recovered:
		lines = _get_recovered_dialogue_lines()

	var data: Array[Dictionary] = []
	for line in lines:
		data.append({
			"name": "Morador da Vila",
			"text": line,
			"portrait_visible": false,
		})

	if not gem_recovered:
		var milestone := GameData.register_silent_npc_conversation(_get_dialogue_id())
		if milestone > 0:
			data.append({
				"name": "Lumen",
				"text": "Já tentamos conversar com %d moradores... nenhum deles consegue nos entender." % milestone,
				"speaker": "lumen",
			})
			data.append({
				"name": "Lumen",
				"text": "Precisamos encontrar a Gema do Diálogo para restaurar a escuta. Siga para o norte da vila.",
				"speaker": "lumen",
			})
	return data


func _get_dialogue_id() -> String:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return String(get_path())
	return "%s:%s" % [current_scene.scene_file_path, current_scene.get_path_to(self)]


func _get_recovered_dialogue_lines() -> Array[String]:
	var npc_name := String(name).to_lower()
	if npc_name.begins_with("cogu_grande_1"):
		return ["Durante a longa ausência da escuta, tentei manter a vila unida. Era difícil orientar alguém quando nenhuma palavra alcançava o outro."]
	return ["Eu havia me acostumado ao silêncio entre nós. Ouvir a vila novamente parece o despertar de um sonho muito longo."]


func _set_interaction_prompt(player: Node2D, visible: bool) -> void:
	if visible and player.has_method("show_interaction_prompt"):
		player.call("show_interaction_prompt", self)
		return
	if not visible and player.has_method("hide_interaction_prompt"):
		player.call("hide_interaction_prompt", self)
		return
	var icon := player.get_node_or_null("Icone_interacao/Sprite2D")
	if icon != null:
		icon.visible = visible


func _exit_tree() -> void:
	if is_instance_valid(_nearby_player):
		_set_interaction_prompt(_nearby_player, false)
