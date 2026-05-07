extends Resource
class_name SkillResource

@export var name: String
@export var targetType: Target_Type
@export var skillType: Skill_Type = Skill_Type.DAMAGE
@export var power: int = 10
@export var manaCost := 0
@export var targetScope: Target_Scope = Target_Scope.SINGLE_TARGET
@export var hitCount := 1
@export var element: Element = Element.NONE
@export var statusEffects: Array[StringName] = []
@export var animationKey := ""
@export var requiresAliveTarget := true

enum Target_Type { ENEMIES, PLAYERS }
enum Skill_Type { DAMAGE, HEAL }
enum Target_Scope { SINGLE_TARGET, ALL_TARGETS, SELF }
enum Element { NONE, PHYSICAL, FIRE, ICE, LIGHTNING, LIGHT, SHADOW }

func can_pay_cost(user: CharacterResource) -> bool:
	if user == null:
		return false
	return user.currentMana >= manaCost

func pay_cost(user: CharacterResource) -> bool:
	if user == null:
		return false
	return user.spend_mana(manaCost)
