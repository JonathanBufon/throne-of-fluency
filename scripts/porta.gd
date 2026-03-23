extends Node2D

var player_near = false
var aberta = false
var esperando_input = false

@onready var anim = $AnimatedSprite2D
@export var input_ui: LineEdit

func _process(delta):
	if player_near and Input.is_action_just_pressed("interact"):
		tentar_abrir()

func tentar_abrir():
	if aberta:
		return
	
	if esperando_input:
		return

	mostrar_input()

func mostrar_input():
	esperando_input = true
	input_ui.visible = true
	input_ui.text = ""
	input_ui.grab_focus()

func _on_line_edit_text_submitted(text):
	input_ui.visible = false
	esperando_input = false

	if text.to_lower() == "push to open":
		abrir_porta()
	else:
		print("Senha incorreta")

func abrir_porta():
	aberta = true
	anim.play("abrir")

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_near = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		
func _ready():
	anim.play("abrir")
	anim.stop()
	anim.frame = 0		
