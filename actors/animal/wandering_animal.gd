extends CharacterBody2D

@export var movement_speed: float = 45.0
@export var wander_radius: float = 140.0
@export var minimum_idle_time: float = 1.5
@export var maximum_idle_time: float = 4.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _origin: Vector2
var _target: Vector2
var _idle_time_left: float = 0.0


func _ready() -> void:
	_origin = global_position
	_pick_new_target()


func _physics_process(delta: float) -> void:
	if _idle_time_left > 0.0:
		_idle_time_left -= delta
		velocity = Vector2.ZERO
		animated_sprite.play(&"idle")
		return

	if global_position.distance_to(_target) <= 8.0:
		_begin_idle()
		return

	var direction := global_position.direction_to(_target)
	velocity = direction * movement_speed
	if absf(direction.x) > 0.05:
		animated_sprite.flip_h = direction.x > 0.0
	animated_sprite.play(&"walk")
	move_and_slide()

	if get_slide_collision_count() > 0:
		_begin_idle()


func _pick_new_target() -> void:
	var offset := Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	_target = _origin + offset.limit_length(wander_radius)


func _begin_idle() -> void:
	velocity = Vector2.ZERO
	_idle_time_left = randf_range(minimum_idle_time, maximum_idle_time)
	_pick_new_target()
	animated_sprite.play(&"idle")
