extends Node2D
class_name MagicProjectile

const TRAVEL_TIME := 0.32
const IMPACT_TIME := 0.08
const PIXEL_SIZE := 6.0
const PIXEL_OFFSETS := [
	Vector2(0, 0),
	Vector2(-1, 0),
	Vector2(1, 0),
	Vector2(0, -1),
	Vector2(0, 1),
	Vector2(-1, -1),
	Vector2(1, 1),
]
const SPARK_OFFSETS := [
	Vector2(-2, 0),
	Vector2(2, 0),
	Vector2(0, -2),
	Vector2(0, 2),
]

var _target_position := Vector2.ZERO
var _projectile_color := Color(1.0, 0.15, 0.05, 1.0)
var _pixels: Array[Polygon2D] = []
var _sparks: Array[Polygon2D] = []

func _ready() -> void:
	_build_pixels()
	_apply_color()

func setup(start_position: Vector2, target_position: Vector2, projectile_color: Color) -> void:
	global_position = start_position
	_target_position = target_position
	_projectile_color = projectile_color
	_apply_color()

func play() -> void:
	look_at(_target_position)
	var base_scale := Vector2.ONE
	scale = base_scale * 0.85

	var travel := create_tween()
	travel.set_parallel(true)
	travel.tween_property(self, "global_position", _target_position, TRAVEL_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	travel.tween_property(self, "rotation", rotation + TAU, TRAVEL_TIME)
	travel.tween_property(self, "scale", base_scale * 1.15, TRAVEL_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await travel.finished

	var impact := create_tween()
	impact.set_parallel(true)
	impact.tween_property(self, "scale", base_scale * 1.8, IMPACT_TIME)
	impact.tween_property(self, "modulate:a", 0.0, IMPACT_TIME)
	await impact.finished
	queue_free()

func _build_pixels() -> void:
	if not _pixels.is_empty():
		return
	for offset in PIXEL_OFFSETS:
		var pixel := _create_pixel(offset, PIXEL_SIZE)
		add_child(pixel)
		_pixels.append(pixel)
	for offset in SPARK_OFFSETS:
		var spark := _create_pixel(offset, PIXEL_SIZE * 0.65)
		add_child(spark)
		_sparks.append(spark)

func _create_pixel(offset: Vector2, size: float) -> Polygon2D:
	var half := size * 0.5
	var center := offset * PIXEL_SIZE
	var pixel := Polygon2D.new()
	pixel.polygon = PackedVector2Array([
		center + Vector2(-half, -half),
		center + Vector2(half, -half),
		center + Vector2(half, half),
		center + Vector2(-half, half),
	])
	return pixel

func _apply_color() -> void:
	var highlight := _projectile_color.lerp(Color.WHITE, 0.35)
	var spark_color := _projectile_color.lerp(Color.WHITE, 0.6)
	for i in _pixels.size():
		_pixels[i].color = highlight if i == 0 else _projectile_color
	for spark in _sparks:
		spark.color = spark_color
