extends Resource
class_name SkillResource

@export var name: String
@export var targetType: Target_Type
@export var skillType: Skill_Type = Skill_Type.DAMAGE
@export var power: int = 10

enum Target_Type { ENEMIES, PLAYERS }
enum Skill_Type { DAMAGE, HEAL }
