extends Area2D

const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")

@export var lines: Array[String] = []
@export var one_shot := true
@export var pause_player := true
@export var persist_id: String = ""
@export var deactivate_if_all_defeated: Array[String] = []

var _has_played := false
var _is_playing := false
var _deactivated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not persist_id.is_empty() and GameData.is_encounter_defeated(persist_id):
		deactivate()
		return
	if not deactivate_if_all_defeated.is_empty():
		var all_defeated := true
		for enc_id in deactivate_if_all_defeated:
			if not GameData.is_encounter_defeated(enc_id):
				all_defeated = false
				break
		if all_defeated:
			deactivate()
			return
	if name == "LumenDialogArea3" and GameData.cripta_porta_aberta:
		deactivate()


func deactivate() -> void:
	_deactivated = true
	_has_played = true
	_is_playing = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for child in find_children("*", "CollisionShape2D", true, false):
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)


func _on_body_entered(body: Node2D) -> void:
	if _deactivated:
		return

	if _is_playing:
		return

	if one_shot and _has_played:
		return

	if not body.is_in_group("player"):
		return

	if lines.is_empty():
		push_warning("Area de dialogo da Lumen sem falas: " + name)
		return

	_play_lumen_dialog(body)


func _play_lumen_dialog(player: Node2D) -> void:
	if _deactivated:
		return

	_is_playing = true
	_has_played = true

	if pause_player:
		player.set_physics_process(false)

	var dialog := DIALOG_SCENE.instantiate()
	get_tree().current_scene.add_child(dialog)
	await dialog.start_dialog(_build_dialog_data())
	dialog.queue_free()

	if not persist_id.is_empty():
		GameData.mark_encounter_defeated(persist_id)

	if pause_player and is_instance_valid(player):
		player.set_physics_process(true)

	_is_playing = false


func _build_dialog_data() -> Array[Dictionary]:
	var dialog_data: Array[Dictionary] = []
	for line in lines:
		dialog_data.append({
			"name": "Lumen",
			"text": line,
			"speaker": "lumen",
		})
	return dialog_data
