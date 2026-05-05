extends Node2D

# Cena de batalha parametrizável: lê BattleTransition.enemy_resources
# no _ready, instancia inimigos nos spawn points e devolve o controle
# ao overworld via change_scene_to_file ao final.

const ENEMY_TEMPLATE := preload("res://battleSystem/core/enemy_battle_template.tscn")

@onready var spawn_points: Node2D = $EnemySpawnPoints
@onready var controller: TurnBasedController = $TurnBasedController

func _ready() -> void:
	_spawn_enemies_from_transition()
	controller.battle_won.connect(_on_battle_won)
	controller.battle_lost.connect(_on_battle_lost)

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
	BattleTransition.finish_battle(BattleTransition.Result.WON)
	_return_to_overworld()

func _on_battle_lost() -> void:
	BattleTransition.finish_battle(BattleTransition.Result.LOST)
	_return_to_overworld()

func _return_to_overworld() -> void:
	if BattleTransition.return_scene.is_empty():
		return
	get_tree().change_scene_to_file(BattleTransition.return_scene)
