extends Control

@onready var player_container: VBoxContainer = %PlayerContainer

const PLAYER_STATS_CONTAINER := preload("res://battleSystem/player_stats_container.tscn")

# Resources must match the CharacterResources assigned to the player TurnBasedAgents in the scene
var playerList: Array = [
	preload("res://battleSystem/resource/player1.tres"),
	preload("res://battleSystem/resource/player2.tres"),
]

func _ready() -> void:
	_reset_player_container()
	_set_player_stats_ui()
	_connect_player_signals.call_deferred()

func _reset_player_container() -> void:
	for node in player_container.get_children():
		node.queue_free()

func _set_player_stats_ui() -> void:
	for player_resource in playerList:
		var stat_display := PLAYER_STATS_CONTAINER.instantiate()
		player_container.add_child(stat_display)
		stat_display.set_player_stats(player_resource)

func _connect_player_signals() -> void:
	for agent: TurnBasedAgent in get_tree().get_nodes_in_group("player"):
		agent.player_turn_started.connect(_on_player_turn_started.bind(agent))

func _on_player_turn_started(agent: TurnBasedAgent) -> void:
	_deactivate_all_player_focus()
	var index := playerList.find(agent.character_resource)
	if index >= 0:
		var children := player_container.get_children()
		if index < children.size():
			children[index].activate_focus()

func _deactivate_all_player_focus() -> void:
	for node in player_container.get_children():
		node.deactivate_focus()
