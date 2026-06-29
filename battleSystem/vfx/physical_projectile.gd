extends Node2D
class_name PhysicalProjectile

const TRAVEL_TIME := 0.32
const IMPACT_TIME := 0.06

var _target_position := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func setup(
	start_position: Vector2,
	target_position: Vector2,
	texture: Texture2D,
	visual_scale: Vector2
) -> void:
	global_position = start_position
	_target_position = target_position
	sprite.texture = texture
	scale = visual_scale
	look_at(_target_position)

func play() -> void:
	var travel := create_tween()
	travel.tween_property(self, "global_position", _target_position, TRAVEL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await travel.finished

	var impact := create_tween()
	impact.set_parallel(true)
	impact.tween_property(self, "scale", scale * 1.25, IMPACT_TIME)
	impact.tween_property(self, "modulate:a", 0.0, IMPACT_TIME)
	await impact.finished
	queue_free()
