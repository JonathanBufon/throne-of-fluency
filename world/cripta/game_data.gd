extends Node

var _spawn_id: String = ""
var spawn_id: String:
	get:
		return _spawn_id
	set(value):
		print("GameData.spawn_id mudou para: '", value, "'")
		_spawn_id = value

var cripta_porta_aberta := false
