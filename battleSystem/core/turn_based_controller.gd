extends Node
class_name TurnBasedController

signal turn_order_refreshed(characterTurnOrder: Array[TurnBasedAgent])
signal battle_won()
signal battle_lost()

var characterTurnOrder: Array[TurnBasedAgent] = []
var activeCharacter: TurnBasedAgent
var _battle_ended := false

func _ready() -> void:
	add_to_group("turnBasedController")
	_set_after_all_ready()

func _set_after_all_ready() -> void:
	await get_tree().create_timer(0.1).timeout
	_set_late_signals()
	_set_turn_order()
	_set_next_active_character()

func _set_late_signals() -> void:
	for agent: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedAgents"):
		agent.turn_finished.connect(_on_turn_done)

func _on_turn_done() -> void:
	if _battle_ended:
		return
	if _check_battle_end():
		return
	_set_next_active_character()

func _set_turn_order() -> void:
	var players := get_tree().get_nodes_in_group("player")
	var enemies := get_tree().get_nodes_in_group("enemy")
	for node in players + enemies:
		characterTurnOrder.append(node)

func _set_next_active_character() -> void:
	if activeCharacter:
		characterTurnOrder.pop_front()

	# Remove dead characters from queue; rebuild if empty
	characterTurnOrder = characterTurnOrder.filter(
		func(a: TurnBasedAgent): return not a.character_resource.is_dead()
	)

	if characterTurnOrder.is_empty():
		_set_turn_order()
		characterTurnOrder = characterTurnOrder.filter(
			func(a: TurnBasedAgent): return not a.character_resource.is_dead()
		)

	if characterTurnOrder.is_empty():
		return

	activeCharacter = characterTurnOrder[0]
	activeCharacter.set_active(true)

	turn_order_refreshed.emit(characterTurnOrder)

func _check_battle_end() -> bool:
	var alive_players := get_tree().get_nodes_in_group("player").filter(
		func(a: TurnBasedAgent): return not a.character_resource.is_dead()
	)
	var alive_enemies := get_tree().get_nodes_in_group("enemy").filter(
		func(a: TurnBasedAgent): return not a.character_resource.is_dead()
	)

	if alive_enemies.is_empty():
		_battle_ended = true
		battle_won.emit()
		return true

	if alive_players.is_empty():
		_battle_ended = true
		battle_lost.emit()
		return true

	return false
