extends Node2D

# Cena de batalha parametrizável: lê BattleTransition.enemy_resources
# no _ready, instancia inimigos nos slots fixos e devolve o controle
# ao overworld via change_scene_to_file ao final.

const ENEMY_TEMPLATE := preload("res://battleSystem/core/enemy_battle_template.tscn")
const PLAYER_TEMPLATE := preload("res://battleSystem/core/player_battle_template.tscn")
const DEFAULT_PLAYER_RESOURCE := preload("res://battleSystem/data/characters/player1.tres")
const MAX_VISIBLE_ENEMIES := 3
const MAX_VISIBLE_PLAYERS := 3

@onready var enemy_slots: Node2D = $EnemySlots
@onready var player_slots: Node2D = $PlayerSlots
@onready var controller: TurnBasedController = $TurnBasedController
@onready var command_menu: CommandMenu = $CanvasLayer/BattleUI/CommandMenu
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var player_characters: Array[Node2D] = []

func _ready() -> void:
	_spawn_player_party()
	_apply_player_visuals()
	_spawn_enemies_from_transition()
	controller.battle_won.connect(_on_battle_won)
	controller.battle_lost.connect(_on_battle_lost)
	command_menu.run_requested.connect(_on_run_requested)

func _spawn_player_party() -> void:
	var resources := _get_player_party_resources()
	var spawns := _get_player_slots_for_count(resources.size())
	if spawns.is_empty():
		return

	for i in resources.size():
		if i >= spawns.size():
			push_warning("Mais jogadores (%d) do que slots visiveis (%d); excedentes ignorados" % [resources.size(), MAX_VISIBLE_PLAYERS])
			break

		var spawn := spawns[i] as Node2D
		var player := PLAYER_TEMPLATE.instantiate() as Node2D
		player.name = "Player%d" % (i + 1)
		player.position = spawn.position

		var agent: TurnBasedAgent = player.get_node("TurnBasedAgent")
		agent.character_resource = resources[i]

		add_child(player)
		player_characters.append(player)

func _get_player_party_resources() -> Array[CharacterResource]:
	var resources: Array[CharacterResource] = []
	for resource in BattleTransition.player_resources:
		if resource != null:
			resources.append(resource)

	if resources.is_empty() and GameData.has_method("get_battle_party_resources"):
		for resource in GameData.get_battle_party_resources():
			if resource != null:
				resources.append(resource)

	if resources.is_empty():
		resources.append(DEFAULT_PLAYER_RESOURCE)

	return resources

func _spawn_enemies_from_transition() -> void:
	var resources := BattleTransition.enemy_resources
	var sprite_frames := BattleTransition.enemy_sprite_frames
	var animations := BattleTransition.enemy_animations
	var frame_indices := BattleTransition.enemy_frame_indices
	var frame_progresses := BattleTransition.enemy_frame_progresses
	var flip_hs := BattleTransition.enemy_flip_hs
	var scales := BattleTransition.enemy_scales
	if resources.is_empty():
		push_warning("battle_scene carregada sem inimigos em BattleTransition.enemy_resources")
		return

	var spawns := _get_enemy_slots_for_count(resources.size())
	for i in resources.size():
		if i >= spawns.size():
			push_warning("Mais inimigos (%d) do que slots visiveis (%d); excedentes ignorados" % [resources.size(), MAX_VISIBLE_ENEMIES])
			break
		var spawn := spawns[i] as Node2D
		var enemy := ENEMY_TEMPLATE.instantiate()
		var agent: TurnBasedAgent = enemy.get_node("TurnBasedAgent")
		agent.character_resource = resources[i]
		_apply_animated_visual(enemy, sprite_frames, animations, frame_indices, frame_progresses, flip_hs, scales, i)
		enemy.position = spawn.position
		add_child(enemy)

func _apply_player_visuals() -> void:
	if BattleTransition.player_sprite_frames == null or player_characters.is_empty():
		return

	var sprite_frames: Array[SpriteFrames] = [BattleTransition.player_sprite_frames]
	var animations: Array[String] = [BattleTransition.player_animation]
	var frame_indices: Array[int] = [BattleTransition.player_frame_index]
	var frame_progresses: Array[float] = [BattleTransition.player_frame_progress]
	var flip_hs: Array[bool] = [BattleTransition.player_flip_h]
	var player := player_characters[0]
	var sprite := player.get_node_or_null("Sprite2D") as Sprite2D
	var fallback_scale := Vector2.ZERO if sprite == null else sprite.scale
	var scales: Array[Vector2] = [fallback_scale]

	_apply_animated_visual(
		player,
		sprite_frames,
		animations,
		frame_indices,
		frame_progresses,
		flip_hs,
		scales,
		0
	)

	var agent := player.get_node_or_null("TurnBasedAgent") as TurnBasedAgent
	if agent != null:
		agent.refresh_visual_node()

func _apply_animated_visual(
	enemy: Node,
	sprite_frames: Array[SpriteFrames],
	animations: Array[String],
	frame_indices: Array[int],
	frame_progresses: Array[float],
	flip_hs: Array[bool],
	scales: Array[Vector2],
	index: int
) -> void:
	if index >= sprite_frames.size() or sprite_frames[index] == null:
		return

	var fallback_sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	var animated_sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite == null:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		enemy.add_child(animated_sprite)

	if fallback_sprite != null:
		animated_sprite.position = fallback_sprite.position
		animated_sprite.scale = fallback_sprite.scale
		fallback_sprite.hide()

	animated_sprite.sprite_frames = sprite_frames[index]
	if index < animations.size() and not animations[index].is_empty():
		animated_sprite.animation = animations[index]
	if index < frame_indices.size():
		var frame_count := animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation)
		var frame_index := clampi(frame_indices[index], 0, maxi(frame_count - 1, 0))
		var frame_progress := 0.0
		if index < frame_progresses.size():
			frame_progress = frame_progresses[index]
		animated_sprite.set_frame_and_progress(frame_index, frame_progress)
	if index < flip_hs.size():
		animated_sprite.flip_h = flip_hs[index]
	if index < scales.size() and scales[index] != Vector2.ZERO:
		animated_sprite.scale = scales[index]
	animated_sprite.play()

func _get_enemy_slots_for_count(enemy_count: int) -> Array[Node2D]:
	var left_slot := enemy_slots.get_node_or_null("EnemySlot1") as Node2D
	var center_slot := enemy_slots.get_node_or_null("EnemySlot2") as Node2D
	var right_slot := enemy_slots.get_node_or_null("EnemySlot3") as Node2D
	var selected_slots: Array[Node2D] = []

	if left_slot == null or center_slot == null or right_slot == null:
		push_warning("EnemySlots precisa conter EnemySlot1, EnemySlot2 e EnemySlot3")
		return selected_slots

	if enemy_count == 1:
		selected_slots.append(center_slot)
	elif enemy_count == 2:
		selected_slots.append(left_slot)
		selected_slots.append(right_slot)
	else:
		selected_slots.append(left_slot)
		selected_slots.append(center_slot)
		selected_slots.append(right_slot)

	return selected_slots

func _get_player_slots_for_count(player_count: int) -> Array[Node2D]:
	var left_slot := player_slots.get_node_or_null("PlayerSlot1") as Node2D
	var center_slot := player_slots.get_node_or_null("PlayerSlot2") as Node2D
	var right_slot := player_slots.get_node_or_null("PlayerSlot3") as Node2D
	var selected_slots: Array[Node2D] = []

	if left_slot == null or center_slot == null or right_slot == null:
		push_warning("PlayerSlots precisa conter PlayerSlot1, PlayerSlot2 e PlayerSlot3")
		return selected_slots

	if player_count == 1:
		selected_slots.append(center_slot)
	elif player_count == 2:
		selected_slots.append(left_slot)
		selected_slots.append(right_slot)
	else:
		selected_slots.append(left_slot)
		selected_slots.append(center_slot)
		selected_slots.append(right_slot)

	return selected_slots

func _on_battle_won() -> void:
	var reward_summary := GameData.grant_battle_rewards(_get_enemy_reward_sources())
	GameData.mark_encounter_defeated(BattleTransition.encounter_id)
	BattleTransition.finish_battle(BattleTransition.Result.WON)
	await _play_dying_animations_for_group("enemy")
	await _show_result_message(_format_victory_message(reward_summary))
	await _return_to_overworld()

func _on_battle_lost() -> void:
	BattleTransition.finish_battle(BattleTransition.Result.LOST)
	await _play_dying_animations_for_group("player")
	await _show_result_message("Defeat")
	await _return_to_game_over()

func _on_run_requested() -> void:
	BattleTransition.finish_battle(BattleTransition.Result.FLED)
	GameData.save_game()
	await _play_player_escape_animation()
	await _show_result_message("Escaped")
	await _return_to_overworld()

func _play_dying_animations_for_group(group_name: String) -> void:
	var dead_agents := get_tree().get_nodes_in_group(group_name).filter(
		func(a: TurnBasedAgent): return a.character_resource != null and a.character_resource.is_dead()
	)
	if dead_agents.is_empty():
		return

	for agent: TurnBasedAgent in dead_agents:
		await agent.play_dying_and_wait()

func _get_enemy_reward_sources() -> Array[CharacterResource]:
	var resources: Array[CharacterResource] = []
	for agent: TurnBasedAgent in get_tree().get_nodes_in_group("enemy"):
		if agent.character_resource != null:
			resources.append(agent.character_resource)
	return resources

func _format_victory_message(reward_summary: Dictionary) -> String:
	var lines: Array[String] = ["Victory"]
	var experience := int(reward_summary.get("experience", 0))
	var reward_gold := int(reward_summary.get("gold", 0))
	if experience > 0:
		lines.append("+%d XP" % experience)
	if reward_gold > 0:
		lines.append("+%d Gold" % reward_gold)

	var drops := reward_summary.get("drops", {}) as Dictionary
	for item_name in drops.keys():
		lines.append("+%d %s" % [int(drops[item_name]), item_name])

	var level_results := reward_summary.get("level_results", []) as Array
	for result in level_results:
		lines.append("%s Lv %d" % [result["character"], int(result["end_level"])])

	return "\n".join(PackedStringArray(lines))

func _play_player_escape_animation() -> void:
	var escaping_players := player_characters.filter(
		func(player: Node2D):
			var agent := player.get_node_or_null("TurnBasedAgent") as TurnBasedAgent
			return agent != null and agent.character_resource != null and not agent.character_resource.is_dead()
	)
	if escaping_players.is_empty():
		await get_tree().create_timer(0.25).timeout
		return

	command_menu.hide()
	var tween := create_tween()
	for i in escaping_players.size():
		var player := escaping_players[i] as Node2D
		var player_agent := player.get_node_or_null("TurnBasedAgent") as TurnBasedAgent
		if player_agent != null:
			player_agent.play_run_down()

		var escape_position := player.position + Vector2(0, 96)
		if i == 0:
			tween.tween_property(player, "position", escape_position, 0.45)
		else:
			tween.parallel().tween_property(player, "position", escape_position, 0.45)
	await tween.finished

func _return_to_overworld() -> void:
	if BattleTransition.return_scene.is_empty():
		BattleTransition.clear()
		return
	await BattleTransition.change_scene_with_fade(BattleTransition.return_scene)

func _return_to_game_over() -> void:
	BattleTransition.clear()
	await BattleTransition.change_scene_with_fade("res://main.tscn")

func _show_result_message(message: String) -> void:
	command_menu.hide()

	var overlay := Control.new()
	overlay.name = "BattleResultOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.modulate.a = 0.0

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.65)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	center.add_child(label)

	canvas_layer.add_child(overlay)

	var fade_in := create_tween()
	fade_in.tween_property(overlay, "modulate:a", 1.0, 0.15)
	await fade_in.finished

	await get_tree().create_timer(0.65).timeout

	var fade_out := create_tween()
	fade_out.tween_property(overlay, "modulate:a", 0.0, 0.15)
	await fade_out.finished
	overlay.queue_free()
