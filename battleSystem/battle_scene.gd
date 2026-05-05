extends Node2D

# Cena de batalha parametrizável: lê BattleTransition.enemy_resources
# no _ready, instancia inimigos nos spawn points e devolve o controle
# ao overworld via change_scene_to_file ao final.

const ENEMY_TEMPLATE := preload("res://battleSystem/core/enemy_battle_template.tscn")

@onready var spawn_points: Node2D = $EnemySpawnPoints
@onready var controller: TurnBasedController = $TurnBasedController
@onready var command_menu: CommandMenu = $CanvasLayer/CommandMenu
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	_spawn_enemies_from_transition()
	controller.battle_won.connect(_on_battle_won)
	controller.battle_lost.connect(_on_battle_lost)
	command_menu.run_requested.connect(_on_run_requested)

func _spawn_enemies_from_transition() -> void:
	var resources := BattleTransition.enemy_resources
	if resources.is_empty():
		push_warning("battle_scene carregada sem inimigos em BattleTransition.enemy_resources")
		return

	var spawns := spawn_points.get_children()
	for i in resources.size():
		if i >= spawns.size():
			push_warning("Mais inimigos (%d) do que spawn points (%d); excedentes ignorados" % [resources.size(), spawns.size()])
			break
		var spawn := spawns[i] as Node2D
		var enemy := ENEMY_TEMPLATE.instantiate()
		var agent: TurnBasedAgent = enemy.get_node("TurnBasedAgent")
		agent.character_resource = resources[i]
		enemy.position = spawn.position
		add_child(enemy)

func _on_battle_won() -> void:
	GameData.mark_encounter_defeated(BattleTransition.encounter_id)
	BattleTransition.finish_battle(BattleTransition.Result.WON)
	await _show_result_message("Victory")
	await _return_to_overworld()

func _on_battle_lost() -> void:
	BattleTransition.finish_battle(BattleTransition.Result.LOST)
	await _show_result_message("Defeat")
	await _return_to_game_over()

func _on_run_requested() -> void:
	BattleTransition.finish_battle(BattleTransition.Result.FLED)
	await _show_result_message("Escaped")
	await _return_to_overworld()

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
