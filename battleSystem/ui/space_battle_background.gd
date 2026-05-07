extends Node2D

@export var viewport_size := Vector2(800, 760)
@export var star_count := 72
@export var shooting_star_count := 4

const SHOOTING_STAR_TRAVEL := Vector2(-260, 118)

var _stars: Array[Dictionary] = []
var _shooting_star_starts: Array[Vector2] = [
	Vector2(760, 86),
	Vector2(690, 186),
	Vector2(820, 292),
	Vector2(612, 52),
]

func _ready() -> void:
	z_index = -100
	_build_star_field()
	_create_shooting_stars()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.012, 0.01, 0.035, 1.0))
	draw_rect(Rect2(0, 132, viewport_size.x, 318), Color(0.11, 0.045, 0.20, 0.34))
	draw_rect(Rect2(0, 420, viewport_size.x, 170), Color(0.015, 0.035, 0.08, 0.30))
	for star in _stars:
		draw_circle(star["position"], star["radius"], star["color"])

func _build_star_field() -> void:
	_stars.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4607
	for i in range(star_count):
		var star := {
			"position": Vector2(rng.randf_range(24.0, viewport_size.x - 24.0), rng.randf_range(28.0, viewport_size.y - 230.0)),
			"radius": rng.randf_range(0.75, 2.1),
			"color": Color(
				rng.randf_range(0.72, 1.0),
				rng.randf_range(0.80, 1.0),
				1.0,
				rng.randf_range(0.45, 0.95)
			),
		}
		_stars.append(star)

func _create_shooting_stars() -> void:
	for i in range(shooting_star_count):
		var line := Line2D.new()
		line.name = "ShootingStar%d" % (i + 1)
		line.width = 2.0
		line.default_color = Color(0.78, 0.92, 1.0, 0.92)
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(76, -32)])
		line.modulate.a = 0.0
		add_child(line)
		_animate_shooting_star(line, i)

func _animate_shooting_star(line: Line2D, index: int) -> void:
	var start := _shooting_star_starts[index % _shooting_star_starts.size()]
	while is_inside_tree():
		await get_tree().create_timer(1.1 + (index * 0.62)).timeout
		if not is_inside_tree():
			return
		line.position = start
		line.modulate.a = 0.0

		var tween := create_tween()
		tween.tween_property(line, "modulate:a", 1.0, 0.08)
		tween.parallel().tween_property(line, "position", start + SHOOTING_STAR_TRAVEL, 0.82)
		tween.tween_property(line, "modulate:a", 0.0, 0.16)
		await tween.finished
