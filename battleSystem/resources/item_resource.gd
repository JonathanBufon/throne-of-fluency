extends Resource
class_name ItemResource

@export var name := "Item"
@export_multiline var description := ""
@export var effectType: Effect_Type = Effect_Type.HEAL_HP
@export var power := 25
@export var targetType: Target_Type = Target_Type.PLAYERS
@export var targetScope: Target_Scope = Target_Scope.SINGLE_TARGET
@export var usableInBattle := true
@export var usableInWorld := false

enum Effect_Type { HEAL_HP, RESTORE_MP, DAMAGE }
enum Target_Type { ENEMIES, PLAYERS }
enum Target_Scope { SINGLE_TARGET, ALL_TARGETS, SELF }

func can_use_in_battle() -> bool:
	return usableInBattle

func can_use_in_world() -> bool:
	return usableInWorld

func apply_to(target: CharacterResource) -> void:
	if target == null:
		return

	match effectType:
		Effect_Type.HEAL_HP:
			target.heal(power)
		Effect_Type.RESTORE_MP:
			target.restore_mana(power)
		Effect_Type.DAMAGE:
			target.take_damage(power)
