extends Resource
class_name CharacterResource

@export var name := "Name"

@export var maxHealth := 100
@export var currentHealth := 100
@export var maxMana := 50
@export var currentMana := 50
@export var speed := 50
@export var overDriveValue := 0

func take_damage(damage: int) -> void:
	currentHealth -= damage
	if currentHealth < 0:
		currentHealth = 0

func heal(amount: int) -> void:
	currentHealth += amount
	if currentHealth > maxHealth:
		currentHealth = maxHealth

func is_dead() -> bool:
	return currentHealth <= 0
