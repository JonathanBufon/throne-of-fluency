extends Node2D

const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")

var _is_playing := false
var _nearby_player: Node2D


func _unhandled_input(event: InputEvent) -> void:
	if (
		not _is_playing
		and is_instance_valid(_nearby_player)
		and event.is_action_pressed("interact")
	):
		get_viewport().set_input_as_handled()
		_show_sign_dialog(_nearby_player)


func _on_reading_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_nearby_player = body
	_set_interaction_prompt(body, true)


func _on_reading_area_body_exited(body: Node2D) -> void:
	if body != _nearby_player:
		return
	_set_interaction_prompt(body, false)
	_nearby_player = null


func _show_sign_dialog(player: Node2D) -> void:
	_is_playing = true
	_set_interaction_prompt(player, false)
	var was_paused := get_tree().paused
	var was_player_physics_processing := player.is_physics_processing()
	player.set_physics_process(false)
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO

	var dialog := DIALOG_SCENE.instantiate()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(dialog)
	get_tree().paused = true
	await dialog.start_dialog([
		{
			"name": "Placa",
			"text": "[font_size=34]↓[/font_size] Cripta     [font_size=34]↑[/font_size] Cidade Cogumelo",
			"portrait_visible": false,
		},
	])
	dialog.queue_free()
	get_tree().paused = was_paused

	if is_instance_valid(player):
		player.set_physics_process(was_player_physics_processing)
	_is_playing = false
	if is_instance_valid(_nearby_player):
		_set_interaction_prompt(_nearby_player, true)


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
