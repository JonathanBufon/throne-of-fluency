extends Area2D

const DIALOG_SCENE := preload("res://ui/dialog/dialogo_npc.tscn")

@export var gem_id: String = "gema_conversacao"
@export var required_encounters: Array[String] = []
@export var collect_dialog_lines: Array[String] = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _visible_set := false
var _collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = false

	if GameData.has_gem(gem_id):
		_collected = true
		queue_free()
		return

	_check_visibility()


func _process(_delta: float) -> void:
	if _visible_set or _collected:
		return
	_check_visibility()


func _check_visibility() -> void:
	for enc_id in required_encounters:
		if not GameData.is_encounter_defeated(enc_id):
			return
	visible = true
	_visible_set = true
	sprite.play()
	_start_float_animation()


func _start_float_animation() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -8.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", 8.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collect(body)


func _collect(player: Node2D) -> void:
	_collected = true
	monitoring = false
	GameData.collect_gem(gem_id)

	player.set_physics_process(false)

	if not collect_dialog_lines.is_empty():
		var dialog := DIALOG_SCENE.instantiate()
		get_tree().current_scene.add_child(dialog)
		var dialog_data: Array[Dictionary] = []
		for line in collect_dialog_lines:
			dialog_data.append({"name": "Lumen", "text": line, "speaker": "lumen"})
		await dialog.start_dialog(dialog_data)
		dialog.queue_free()

	if is_instance_valid(player):
		player.set_physics_process(true)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_property(sprite, "scale", sprite.scale * 2.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	queue_free()
