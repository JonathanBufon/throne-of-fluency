extends Node2D

const PARTY_OFFSET := Vector2(-40, -20)

func _ready() -> void:
	call_deferred("_apply_scene_entry_state")

func _apply_scene_entry_state() -> void:
	_cleanup_defeated_encounters()

	if BattleTransition.has_pending_return():
		if BattleTransition.last_result in [BattleTransition.Result.WON, BattleTransition.Result.FLED]:
			_move_party_to(BattleTransition.return_position)
		BattleTransition.clear()
		return

	if GameData.spawn_id != "":
		_apply_spawn()

func _apply_spawn() -> void:
	var spawn_name = GameData.spawn_id.trim_prefix("../")
	var current_scene = get_tree().current_scene

	var spawn: Node2D = null
	for child in current_scene.get_children():
		if child is Node2D and child.name == spawn_name:
			spawn = child
			break

	if spawn == null:
		push_warning("Spawn nao encontrado: " + spawn_name)
		return

	_move_party_to(spawn.global_position)
	GameData.spawn_id = ""

func _move_party_to(target_position: Vector2) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		push_warning("Player nao encontrado!")
		return

	player.global_position = target_position

	var lumen = get_tree().get_first_node_in_group("lumen") as Node2D
	if lumen:
		lumen.global_position = target_position + PARTY_OFFSET

func _cleanup_defeated_encounters() -> void:
	if GameData.defeated_encounters.is_empty():
		return

	var current_scene = get_tree().current_scene
	if current_scene == null:
		return

	_queue_defeated_enemies(current_scene)

func _queue_defeated_enemies(root: Node) -> void:
	for child in root.get_children():
		var encounter_id := _get_node_encounter_id(child)
		if GameData.is_encounter_defeated(encounter_id):
			child.queue_free()
			continue

		_queue_defeated_enemies(child)

func _get_node_encounter_id(node: Node) -> String:
	if node.has_method("get_effective_encounter_id"):
		var effective_id = node.call("get_effective_encounter_id")
		if effective_id is String:
			return effective_id

	var exported_id = node.get("encounter_id")
	if exported_id is String:
		return exported_id

	return ""
