extends CharacterBody2D

const SPEED = 300.0
var last_direction: Vector2 = Vector2.RIGHT

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var icone_interacao: Node2D = $Icone_interacao

func _ready() -> void:
	add_to_group("player") # Necessário para que fim_da_fase e porta detectem o player
	$Icone_interacao/Sprite2D.visible = false

func _physics_process(_delta: float) -> void:
	process_movement()
	process_animation()
	move_and_slide()

#                        #
# MOVIMENT AND ANIMATION #
#                        #
func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if (direction != Vector2.ZERO):
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO

func process_animation() -> void:
	if (velocity != Vector2.ZERO):
		player_animation("run", last_direction)
	else: 
		player_animation("idle", last_direction)	

func player_animation(prefix: String, dir: Vector2) -> void:
	if (dir.x != 0):
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif (dir.y < 0):
		animated_sprite_2d.play(prefix + "_up")
	elif (dir.y > 0):
		animated_sprite_2d.play(prefix + "_down")

# Estes callbacks foram removidos do player pois a lógica de detecção
# de proximidade da porta está corretamente implementada no porta.gd.
# No editor, garanta que os sinais body_entered/body_exited da Area_Porta
# estejam conectados ao porta.gd, e NÃO ao player.
