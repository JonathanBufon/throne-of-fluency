extends CharacterBody2D

# Distância ideal para flutuar atrás do player
@export var distancia_ideal: float = 40.0
# Só começa a se mover se estiver mais longe que isso
@export var distancia_minima: float = 20.0
# Velocidade de acompanhamento
@export var speed: float = 200.0

var player: Node2D
var last_direction: Vector2 = Vector2.DOWN

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("lumen")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	_seguir_player(delta)
	move_and_slide()
	_process_animation()

# =========================
# 💫 SEGUIR PLAYER
# =========================
func _seguir_player(_delta):
	var _dist = global_position.distance_to(player.global_position)

	# Posição alvo: um pouco atrás e ao lado do player
	var offset = Vector2(-distancia_ideal, -distancia_ideal * 0.5)
	var alvo = player.global_position + offset

	var dir = (alvo - global_position).normalized()
	var distancia_alvo = global_position.distance_to(alvo)

	if distancia_alvo > distancia_minima:
		# Quanto mais longe, mais rápido ela corre para alcançar
		var velocidade = speed * clamp(distancia_alvo / distancia_ideal, 0.5, 2.0)
		velocity = dir * velocidade
		last_direction = dir
	else:
		# Perto o suficiente, flutua levemente no lugar
		velocity = velocity.lerp(Vector2.ZERO, 0.2)

# =========================
# 🎬 ANIMAÇÃO
# =========================
func _process_animation() -> void:
	if velocity.length() > 10:
		_lumen_animation("run", last_direction)
	else:
		_lumen_animation("idle", last_direction)

func _lumen_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")
