extends Node2D

@export var letter := "O"

@onready var parede_fechada: Sprite2D = $parede_fechada
@onready var parede_aberta: Sprite2D = $parede_aberta
@onready var letra: Label = $Letra


func _ready() -> void:
	letra.text = letter
	set_open(false)


func set_open(value: bool) -> void:
	parede_fechada.visible = not value
	parede_aberta.visible = value
	letra.visible = value
