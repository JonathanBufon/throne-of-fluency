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

var state: State = State.PATROL
var player: Node2D
var patrol_target: Vector2
var viu_player: bool = false
var last_direction: Vector2 = Vector2.RIGHT

@onready var icone_visao = $Icone_Visao
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	icone_visao.visible = false
	_pick_patrol_target()

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
