extends CharacterBody2D

enum State {
	PATROL,
	CHASE
}

@export var speed: float = 60.0
@export var chase_speed: float = 150.0
@export var detection_range: float = 120.0
@export var patrol_radius: float = 100.0

# =========================
# ⚔️ DADOS DE BATALHA
# =========================
# battle_party tem prioridade; se vazia, usa [battle_resource] como encontro de 1 inimigo.
# encounter_id identifica unicamente a instância para marcar como derrotada e não respawnar.
@export var battle_resource: CharacterResource
@export var battle_party: Array[CharacterResource] = []
@export var encounter_id: String = ""
@export var battle_sprite_scale := Vector2(5, 5)

var state: State = State.PATROL
var player: Node2D
var patrol_target: Vector2
var viu_player: bool = false
var last_direction: Vector2 = Vector2.RIGHT
var _battle_triggered: bool = false
var _wait_player_exit_before_retrigger := false

@onready var icone_visao = $Icone_Visao
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	icone_visao.visible = false
	_pick_patrol_target()
	_set_flee_retrigger_guard()
	_set_danger_box_exit_signal()

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	match state:
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase(delta)

	move_and_slide()
	_process_animation()

# =========================
# 🟡 PATROL
# =========================
func _do_patrol(_delta):
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	# Detectou player
	if dist <= detection_range:
		if not viu_player:
			viu_player = true
			mostrar_icone_visao()

		_change_state(State.CHASE)
		return

	# Movimento de patrulha
	var dir = (patrol_target - global_position).normalized()
	velocity = dir * speed

	if velocity != Vector2.ZERO:
		last_direction = velocity.normalized()

	if global_position.distance_to(patrol_target) < 10:
		_pick_patrol_target()

# =========================
# 🔴 CHASE
# =========================
func _do_chase(_delta):
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	# Perdeu o player
	if dist > detection_range:
		viu_player = false
		_change_state(State.PATROL)
		_pick_patrol_target()
		return

	# Perseguir
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * chase_speed

	if velocity != Vector2.ZERO:
		last_direction = velocity.normalized()

# =========================
# 🎬 ANIMAÇÃO
# =========================
func _process_animation() -> void:
	if velocity != Vector2.ZERO:
		_enemy_animation("run", last_direction)
	else:
		_enemy_animation("idle", last_direction)

func _enemy_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")

# =========================
# 🎯 UTIL
# =========================
func _change_state(new_state: State):
	state = new_state

func _pick_patrol_target():
	var random_offset = Vector2(
		randf_range(-patrol_radius, patrol_radius),
		randf_range(-patrol_radius, patrol_radius)
	)
	patrol_target = global_position + random_offset

func get_effective_encounter_id() -> String:
	if not encounter_id.is_empty():
		return encounter_id

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return ""

	return "%s:%s" % [current_scene.scene_file_path, current_scene.get_path_to(self)]

func _set_flee_retrigger_guard() -> void:
	if BattleTransition.last_result != BattleTransition.Result.FLED:
		return
	if BattleTransition.encounter_id != get_effective_encounter_id():
		return

	_battle_triggered = true
	_wait_player_exit_before_retrigger = true

func _set_danger_box_exit_signal() -> void:
	var danger_box := get_node_or_null("DangerBox") as Area2D
	if danger_box == null:
		return
	if not danger_box.body_exited.is_connected(_on_danger_box_body_exited):
		danger_box.body_exited.connect(_on_danger_box_body_exited)

# =========================
# ❗ ICONE DE VISÃO
# =========================
func mostrar_icone_visao():
	icone_visao.visible = true
	icone_visao.modulate.a = 1.0
	icone_visao.position = Vector2(0, -5)

	var tween = create_tween()

	icone_visao.scale = Vector2(0.5, 0.5)
	tween.tween_property(icone_visao, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(icone_visao, "scale", Vector2(1.0, 1.0), 0.1)

	tween.parallel().tween_property(icone_visao, "position:y", icone_visao.position.y - 20, 0.3)
	tween.parallel().tween_property(icone_visao, "modulate:a", 0.0, 0.3)

	tween.tween_callback(self._esconder_icone)

func _esconder_icone():
	icone_visao.visible = false

# =========================
# ⚔️ DANGER BOX → BATALHA
# =========================
func _on_danger_box_body_entered(body: Node2D) -> void:
	if _battle_triggered:
		return
	if not body.is_in_group("player"):
		return

	var party: Array[CharacterResource] = []
	if not battle_party.is_empty():
		party = battle_party
	elif battle_resource != null:
		party.append(battle_resource)
	else:
		push_warning("Enemy '%s' tocou o player sem battle_resource ou battle_party configurados" % name)
		return

	var enemy_sprite_frames: Array[SpriteFrames] = []
	var enemy_animations: Array[String] = []
	var enemy_frame_indices: Array[int] = []
	var enemy_frame_progresses: Array[float] = []
	var enemy_flip_hs: Array[bool] = []
	var battle_scales: Array[Vector2] = []
	_append_battle_animation_data(
		animated_sprite_2d,
		battle_sprite_scale,
		enemy_sprite_frames,
		enemy_animations,
		enemy_frame_indices,
		enemy_frame_progresses,
		enemy_flip_hs,
		battle_scales
	)

	_battle_triggered = true
	BattleTransition.request_battle(
		party,
		get_tree().current_scene.scene_file_path,
		body.global_position,
		get_effective_encounter_id()
	)
	BattleTransition.set_enemy_visuals(
		enemy_sprite_frames,
		enemy_animations,
		enemy_frame_indices,
		enemy_frame_progresses,
		enemy_flip_hs,
		battle_scales
	)
	_set_player_battle_visual(body)
	await BattleTransition.change_scene_with_fade("res://battleSystem/battle_scene.tscn")

func _on_danger_box_body_exited(body: Node2D) -> void:
	if not _wait_player_exit_before_retrigger or not body.is_in_group("player"):
		return

	_battle_triggered = false
	_wait_player_exit_before_retrigger = false

func _append_battle_animation_data(
	animated_sprite: AnimatedSprite2D,
	battle_scale: Vector2,
	sprite_frames_list: Array[SpriteFrames],
	animations: Array[String],
	frame_indices: Array[int],
	frame_progresses: Array[float],
	flip_hs: Array[bool],
	scales: Array[Vector2]
) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	var animation_name := _get_battle_animation_name(animated_sprite)
	if animation_name.is_empty():
		return

	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return

	sprite_frames_list.append(animated_sprite.sprite_frames)
	animations.append(animation_name)
	frame_indices.append(clampi(animated_sprite.frame, 0, frame_count - 1))
	frame_progresses.append(animated_sprite.frame_progress)
	flip_hs.append(animated_sprite.flip_h)
	scales.append(battle_scale)

func _set_player_battle_visual(body: Node2D) -> void:
	var player_sprite := body.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if player_sprite == null:
		return

	var animation_name := _get_battle_animation_name(player_sprite)
	if animation_name.is_empty():
		return

	var frame_count := player_sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return

	BattleTransition.set_player_visual(
		player_sprite.sprite_frames,
		animation_name,
		clampi(player_sprite.frame, 0, frame_count - 1),
		player_sprite.frame_progress,
		player_sprite.flip_h
	)

func _get_battle_animation_name(animated_sprite: AnimatedSprite2D) -> String:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return ""

	var animation_name := String(animated_sprite.animation)
	if animation_name.is_empty() or not animated_sprite.sprite_frames.has_animation(animation_name):
		return ""

	if animation_name.begins_with("run_"):
		var idle_animation := "idle_" + animation_name.substr("run_".length())
		if animated_sprite.sprite_frames.has_animation(idle_animation):
			return idle_animation

	return animation_name
