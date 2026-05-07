extends Control

@onready var hp_bar: TextureProgressBar = %HPBar

@export var bar_size := Vector2(72, 10)
@export var minimum_head_gap := 8.0

var _agent: TurnBasedAgent
var _last_health := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 100
	custom_minimum_size = bar_size
	size = bar_size
	_agent = get_parent().get_node_or_null("TurnBasedAgent") as TurnBasedAgent
	_refresh()

func _process(_delta: float) -> void:
	_refresh_position()
	_refresh()

func _refresh() -> void:
	if _agent == null or _agent.character_resource == null:
		hide()
		return

	var current_health := _agent.character_resource.currentHealth
	if current_health == _last_health:
		return

	_last_health = current_health
	hp_bar.max_value = _agent.character_resource.maxHealth
	hp_bar.value = current_health
	visible = current_health > 0

func _refresh_position() -> void:
	var visual_node := _get_visual_node()
	if visual_node == null:
		return

	size = bar_size
	var visual_top := _get_visual_top(visual_node)
	position = Vector2(
		visual_node.position.x - (bar_size.x * 0.5),
		visual_top - minimum_head_gap - bar_size.y
	)

func _get_visual_node() -> Node2D:
	var parent_node := get_parent()
	if parent_node == null:
		return null

	var animated_sprite := parent_node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite != null and animated_sprite.visible:
		return animated_sprite

	var sprite := parent_node.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null and sprite.visible:
		return sprite

	return null

func _get_visual_top(visual_node: Node2D) -> float:
	var texture_height := _get_visual_texture_height(visual_node)
	var scaled_height := texture_height * absf(visual_node.scale.y)
	var centered := true

	if visual_node is Sprite2D:
		centered = (visual_node as Sprite2D).centered
	elif visual_node is AnimatedSprite2D:
		centered = (visual_node as AnimatedSprite2D).centered

	if centered:
		return visual_node.position.y - (scaled_height * 0.5)

	return visual_node.position.y

func _get_visual_texture_height(visual_node: Node2D) -> float:
	var texture: Texture2D

	if visual_node is AnimatedSprite2D:
		var animated_sprite := visual_node as AnimatedSprite2D
		if animated_sprite.sprite_frames == null:
			return 32.0

		var animation := animated_sprite.animation
		if not animated_sprite.sprite_frames.has_animation(animation):
			return 32.0

		var frame_count := animated_sprite.sprite_frames.get_frame_count(animation)
		if frame_count <= 0:
			return 32.0

		var frame_index := clampi(animated_sprite.frame, 0, frame_count - 1)
		texture = animated_sprite.sprite_frames.get_frame_texture(animation, frame_index)
	elif visual_node is Sprite2D:
		texture = (visual_node as Sprite2D).texture

	if texture == null:
		return 32.0

	return texture.get_height()
