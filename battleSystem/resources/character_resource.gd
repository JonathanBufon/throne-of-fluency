extends Resource
class_name CharacterResource

@export var name := "Name"

@export var level := 1
@export var experience := 0
@export var maxHealth := 100
@export var currentHealth := 100
@export var maxMana := 50
@export var currentMana := 50
@export var speed := 50
@export var overDriveValue := 0
@export var basicAttack: Resource
@export var techs: Array[Resource] = []
@export var battleSpriteFrames: SpriteFrames
@export var battleScale := Vector2.ONE
@export var battleOffset := Vector2.ZERO
@export var isBoss := false

func take_damage(damage: int) -> void:
	currentHealth -= damage
	if currentHealth < 0:
		currentHealth = 0

func heal(amount: int) -> void:
	currentHealth += amount
	if currentHealth > maxHealth:
		currentHealth = maxHealth

func spend_mana(amount: int) -> bool:
	if amount <= 0:
		return true
	if currentMana < amount:
		return false
	currentMana -= amount
	return true

func restore_mana(amount: int) -> void:
	currentMana += amount
	if currentMana > maxMana:
		currentMana = maxMana

func is_dead() -> bool:
	return currentHealth <= 0
