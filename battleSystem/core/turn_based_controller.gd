extends Node
class_name TurnBasedController

signal turn_order_refreshed(characterTurnOrder: Array[TurnBasedAgent])
signal battle_won()
signal battle_lost()

enum Battle_State { FILLING, PLAYER_COMMAND, TARGETING, RESOLVING_ACTION, BATTLE_END }

@export var action_gauge_fill_multiplier := 0.45
@export var pause_gauges_during_player_command := false
@export var pause_gauges_during_action := true

var characterTurnOrder: Array[TurnBasedAgent] = []
var activeCharacter: TurnBasedAgent
var battle_state: Battle_State = Battle_State.FILLING
var _battle_ended := false
var _initialized := false
var _agents: Array[TurnBasedAgent] = []

func _ready() -> void:
	add_to_group("turnBasedController")
	_set_after_all_ready()

func _process(delta: float) -> void:
	if not _initialized:
		return
	if _battle_ended or battle_state == Battle_State.BATTLE_END:
		return
	if pause_gauges_during_action and battle_state == Battle_State.RESOLVING_ACTION:
		return
	if pause_gauges_during_player_command and activeCharacter != null:
		return
	if _check_battle_end():
		return

	_fill_action_gauges(delta)
	_activate_next_ready_character()

func _set_after_all_ready() -> void:
	await get_tree().create_timer(0.1).timeout
	_set_late_signals()
	_set_turn_order()
	_initialize_action_gauges()
	_initialized = true
	turn_order_refreshed.emit(characterTurnOrder)

func _set_late_signals() -> void:
	for agent: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedAgents"):
		if not agent.turn_finished.is_connected(_on_turn_done):
			agent.turn_finished.connect(_on_turn_done)
		var targeting_started_callback := _on_targeting_started.bind(agent)
		if not agent.targeting_started.is_connected(targeting_started_callback):
			agent.targeting_started.connect(targeting_started_callback)
		var targeting_cancelled_callback := _on_targeting_cancelled.bind(agent)
		if not agent.targeting_cancelled.is_connected(targeting_cancelled_callback):
			agent.targeting_cancelled.connect(targeting_cancelled_callback)
		var action_resolving_callback := _on_action_resolving_started.bind(agent)
		if not agent.action_resolving_started.is_connected(action_resolving_callback):
			agent.action_resolving_started.connect(action_resolving_callback)

func _on_turn_done() -> void:
	if _battle_ended:
		return
	if activeCharacter != null:
		activeCharacter.consume_action_gauge()
		activeCharacter = null
	if _check_battle_end():
		return
	battle_state = Battle_State.FILLING
	_activate_next_ready_character()

func _on_targeting_started(agent: TurnBasedAgent) -> void:
	if agent == activeCharacter and battle_state == Battle_State.PLAYER_COMMAND:
		battle_state = Battle_State.TARGETING

func _on_targeting_cancelled(agent: TurnBasedAgent) -> void:
	if agent == activeCharacter and battle_state == Battle_State.TARGETING:
		battle_state = Battle_State.PLAYER_COMMAND

func _on_action_resolving_started(agent: TurnBasedAgent) -> void:
	if agent == activeCharacter:
		battle_state = Battle_State.RESOLVING_ACTION

func _set_turn_order() -> void:
	characterTurnOrder.clear()
	_agents.clear()
	var players := get_tree().get_nodes_in_group("player")
	var enemies := get_tree().get_nodes_in_group("enemy")
	for node in players + enemies:
		var agent := node as TurnBasedAgent
		if agent != null:
			_agents.append(agent)
			characterTurnOrder.append(agent)

func _initialize_action_gauges() -> void:
	for agent in _agents:
		agent.set_active(false)
		agent.reset_action_gauge()

func _fill_action_gauges(delta: float) -> void:
	for agent in _get_alive_agents():
		if agent == activeCharacter or agent.is_action_ready():
			continue
		agent.add_action_gauge(agent.character_resource.speed * action_gauge_fill_multiplier * delta)

func _activate_next_ready_character() -> void:
	if activeCharacter != null:
		return

	var ready_agents := _get_alive_agents().filter(
		func(a: TurnBasedAgent): return a.is_action_ready()
	)
	if ready_agents.is_empty():
		return

	ready_agents.sort_custom(Callable(self, "_sort_ready_agents"))
	activeCharacter = ready_agents[0]
	if activeCharacter == null:
		return

	battle_state = (
		Battle_State.PLAYER_COMMAND
		if activeCharacter.character_type == TurnBasedAgent.Character_Type.PLAYER
		else Battle_State.RESOLVING_ACTION
	)
	activeCharacter.set_active(true)
	_refresh_turn_order_preview()

func _refresh_turn_order_preview() -> void:
	characterTurnOrder = _get_alive_agents()
	characterTurnOrder.sort_custom(Callable(self, "_sort_ready_agents"))
	turn_order_refreshed.emit(characterTurnOrder)

func _get_alive_agents() -> Array[TurnBasedAgent]:
	var alive_agents: Array[TurnBasedAgent] = []
	for agent in _agents:
		if agent.character_resource != null and not agent.character_resource.is_dead():
			alive_agents.append(agent)
	return alive_agents

func _sort_ready_agents(a: TurnBasedAgent, b: TurnBasedAgent) -> bool:
	if a.actionGauge == b.actionGauge:
		return a.character_resource.speed > b.character_resource.speed
	return a.actionGauge > b.actionGauge

func _check_battle_end() -> bool:
	var alive_players := get_tree().get_nodes_in_group("player").filter(
		func(a: TurnBasedAgent): return not a.character_resource.is_dead()
	)
	var alive_enemies := get_tree().get_nodes_in_group("enemy").filter(
		func(a: TurnBasedAgent): return not a.character_resource.is_dead()
	)

	if alive_enemies.is_empty():
		_battle_ended = true
		battle_state = Battle_State.BATTLE_END
		battle_won.emit()
		return true

	if alive_players.is_empty():
		_battle_ended = true
		battle_state = Battle_State.BATTLE_END
		battle_lost.emit()
		return true

	return false
