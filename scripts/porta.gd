extends Node2D

var player_near = false
var aberta = false
var esperando_input = false

@onready var anim = $AnimatedSprite2D

# Arraste a cena do DialogScreen aqui no Inspetor
@export var dialog_screen_scene: PackedScene


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
	if not dialog_screen_scene:
		print("ERRO: dialog_screen_scene não está atribuído no Inspetor!")
		return

	esperando_input = true

	var dialog = dialog_screen_scene.instantiate()
	get_tree().root.add_child(dialog)

	# Mostra um diálogo antes de pedir a senha
	await dialog.start_dialog([
		{"title": "Guarda", "dialog": "Alto lá! Esta porta está trancada.", "faceset": ""},
		{"title": "Guarda", "dialog": "Diga a senha para passar.", "faceset": ""},
	])

	# Cria nova instância para o input
	var dialog2 = dialog_screen_scene.instantiate()
	get_tree().root.add_child(dialog2)

	var acertou = await dialog2.start_input(
		"Guarda",
		"Digite a senha:",
		"",
		"push to open"
	)

	esperando_input = false

	if acertou:
		abrir_porta()
	else:
		print("Senha incorreta")


func abrir_porta():
	aberta = true
	anim.play("abrir")


func _on_area_port_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		body.get_node("Icone_interacao/Sprite2D").visible = true


func _on_area_port_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		body.get_node("Icone_interacao/Sprite2D").visible = false
