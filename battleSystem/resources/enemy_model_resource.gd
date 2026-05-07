extends Resource
class_name EnemyModelResource

@export var baseCharacter: CharacterResource
@export var displayName := ""
@export var enemyAI: EnemyAIResource
@export var battleSpriteFrames: SpriteFrames
@export var battleAnimation := ""
@export var battleFrameIndex := 0
@export var battleFlipH := false
@export var battleScale := Vector2.ZERO

func create_character_instance() -> CharacterResource:
	if baseCharacter == null:
		return null

	var character := baseCharacter.duplicate(true) as CharacterResource
	if character == null:
		return null

	if not displayName.is_empty():
		character.name = displayName
	if enemyAI != null:
		character.enemyAI = enemyAI
	if battleSpriteFrames != null:
		character.battleSpriteFrames = battleSpriteFrames
	if battleScale != Vector2.ZERO:
		character.battleScale = battleScale

	character.currentHealth = character.maxHealth
	character.currentMana = character.maxMana
	character.overDriveValue = 0
	return character
