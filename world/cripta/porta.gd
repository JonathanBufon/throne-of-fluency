extends Node2D

var player_near = false
var aberta = false
var esperando_input = false

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("abrir")
	anim.stop()
	anim.frame = 0
	if GameData.cripta_porta_aberta:
		_aplicar_porta_aberta(false)
	# Garante que o ícone começa escondido ao carregar a cena
	call_deferred("_esconder_icone_inicial")

func _esconder_icone_inicial():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var icon = player.get_node_or_null("Icone_interacao/Sprite2D")
		if icon:
			icon.visible = false

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
	GameData.cripta_porta_aberta = true
	_aplicar_porta_aberta(true)

func _aplicar_porta_aberta(tocar_animacao: bool = true):
	aberta = true
	if tocar_animacao:
		anim.play("abrir")
	else:
		anim.frame = anim.sprite_frames.get_frame_count("abrir") - 1
	var colisao_fechada = get_node_or_null("Colisao_Porta_Fechada")
	var colisao_aberta = get_node_or_null("Colisao_Porta_Aberta")
	if colisao_fechada:
		colisao_fechada.disabled = true
	if colisao_aberta:
		colisao_aberta.visible = true

func _on_area_porta_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		# Só mostra o ícone se a porta ainda estiver fechada
		if not aberta:
			var icon = body.get_node_or_null("Icone_interacao/Sprite2D")
			if icon:
				icon.visible = true

func _on_area_porta_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		var icon = body.get_node_or_null("Icone_interacao/Sprite2D")
		if icon:
			icon.visible = false
