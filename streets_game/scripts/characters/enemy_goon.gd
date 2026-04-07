## 敌人：小混混 / Enemy: Goon
## 基础小兵，走向玩家并挥拳 / Basic thug, walks toward player and punches
extends EnemyBase
class_name EnemyGoon

# 小混混属性 / Goon attributes
@export var base_speed: float = 120.0
@export var punch_damage: int = 8


func _ready() -> void:
	max_health = 60
	health = 60
	speed = base_speed

	super()


func get_current_speed() -> float:
	"""获取当前速度 / Get current speed"""
	return speed


## 执行普通攻击 / Perform basic punch attack
func perform_punch() -> void:
	"""执行挥拳攻击 / Execute punch attack"""
	if not target:
		return

	# 造成伤害 / Deal damage
	var knockback = Vector2(facing_direction * 150, -50)
	target.take_damage(punch_damage, knockback)

	# 释放攻击槽 / Release attack slot
	release_attack_slot()
