extends Node2D

var player_near = false
var aberta = false
var esperando_input = false

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("abrir")
	anim.stop()
	anim.frame = 0

func _process(_delta):
	if player_near and Input.is_action_just_pressed("interact"):
		tentar_abrir()

func tentar_abrir():
	if aberta or esperando_input:
		return
	mostrar_input()

func mostrar_input():
	esperando_input = true
	var dialog = get_parent().get_parent().get_node_or_null("UI/Dialogo_Acao_Input")
	var correto = false
	if dialog and dialog.has_method("ask"):
		correto = await dialog.ask()
	esperando_input = false
	if correto:
		abrir_porta()

func abrir_porta():
	aberta = true
	anim.play("abrir")
	var colisao_fechada = get_node_or_null("Colisao_Porta_Fechada")
	var colisao_aberta = get_node_or_null("Colisao_Porta_Aberta")
	if colisao_fechada:
		colisao_fechada.disabled = true
	if colisao_aberta:
		colisao_aberta.visible = true

func _on_area_porta_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		var icon = body.get_node_or_null("Icone_interacao/Sprite2D")
		if icon:
			icon.visible = true

func _on_area_porta_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		var icon = body.get_node_or_null("Icone_interacao/Sprite2D")
		if icon:
			icon.visible = false
