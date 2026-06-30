extends Node

const EVENT_ID := "mushroom_village_intro"
const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")

@export var spawn_path: NodePath


func _ready() -> void:
	call_deferred("_prepare_intro")


func _prepare_intro() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	if GameData.pending_world_event != EVENT_ID:
		return
	GameData.pending_world_event = ""

	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		push_warning("Player não encontrado para a introdução da Vila Cogumelo")
		return
	_move_party_to_village_entrance(player)

	if GameData.is_world_event_completed(EVENT_ID):
		return

	# Aguarda o fade de entrada terminar antes de pausar o mundo para o diálogo.
	await get_tree().create_timer(0.7).timeout

	await _play_intro_dialog(player)
	GameData.mark_world_event_completed(EVENT_ID)


func _move_party_to_village_entrance(player: CharacterBody2D) -> void:
	var spawn := get_node_or_null(spawn_path) as Marker2D
	if spawn == null:
		push_warning("Spawn_4 não encontrado na Vila Cogumelo")
		return

	player.global_position = spawn.global_position
	var lumen := get_tree().get_first_node_in_group("lumen") as Node2D
	if lumen != null:
		lumen.global_position = spawn.global_position + Vector2(-40, -20)


func _play_intro_dialog(player: CharacterBody2D) -> void:
	var was_paused := get_tree().paused
	var was_player_physics_processing := player.is_physics_processing()
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	var dialog := DIALOG_SCENE.instantiate()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(dialog)
	get_tree().paused = true

	await dialog.start_dialog([
		{
			"name": "Lumen",
			"text": "Chegamos à Vila Cogumelos! Os shroomlings fizeram deste lugar um refúgio em meio à floresta.",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "Desde que a Gema do Diálogo foi destruida, os povos de Lexicon deixaram de se entender e o mundo mergulhou em confusão.",
			"speaker": "lumen",
		},
		{
			"name": "Lumen",
			"text": "Vamos procurar por pistas de onde está a gema da escuta",
			"speaker": "lumen",
		},
	])

	dialog.queue_free()
	get_tree().paused = was_paused
	if is_instance_valid(player):
		player.set_physics_process(was_player_physics_processing)
