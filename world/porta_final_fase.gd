extends Node2D

const PHASE_TRANSITION_OVERLAY := preload("res://world/phase_transition_overlay.gd")

var player_near := false
var aberta := false
var esperando_input := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.play("abrir")
	anim.stop()
	anim.frame = 0
	if GameData.porta_final_aberta:
		_aplicar_porta_aberta(false)
	call_deferred("_esconder_icone_inicial")

func _esconder_icone_inicial() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var icon = player.get_node_or_null("Icone_interacao/Sprite2D")
		if icon:
			icon.visible = false

func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("interact"):
		tentar_abrir()

func tentar_abrir() -> void:
	if aberta or esperando_input:
		return
	mostrar_input()

func mostrar_input() -> void:
	esperando_input = true
	var dialog = get_tree().current_scene.get_node_or_null("UI/Dialogo_Acao_Input")
	var correto := false
	if dialog and dialog.has_method("ask"):
		correto = await dialog.ask()
	esperando_input = false
	if correto:
		abrir_porta()

func abrir_porta() -> void:
	GameData.porta_final_aberta = true
	_aplicar_porta_aberta(true)
	await get_tree().create_timer(0.6).timeout
	_entrar_fase_final()

func _entrar_fase_final() -> void:
	var overlay := PHASE_TRANSITION_OVERLAY.new()
	get_tree().root.add_child(overlay)
	overlay.change_scene("res://world/final_phase/final_phase.tscn", 0.45, 0.45)

func _aplicar_porta_aberta(tocar_animacao: bool = true) -> void:
	aberta = true
	if tocar_animacao:
		anim.play("abrir")
	else:
		anim.frame = anim.sprite_frames.get_frame_count("abrir") - 1
	var colisao_fechada = get_node_or_null("Colisao_Porta_Fechada")
	if colisao_fechada:
		colisao_fechada.disabled = true

func _on_area_porta_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		if not aberta:
			var icon = body.get_node_or_null("Icone_interacao/Sprite2D")
			if icon:
				icon.visible = true

func _on_area_porta_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		var icon = body.get_node_or_null("Icone_interacao/Sprite2D")
		if icon:
			icon.visible = false
