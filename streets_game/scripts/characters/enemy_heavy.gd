## 敌人：重型敌人 / Enemy: Heavy
## 缓慢移动，高HP，强力打击，具有超级护甲（弱攻击不会击倒） / Slow, high HP, strong hits, super armor
extends EnemyBase
class_name EnemyHeavy

# 重型敌人属性 / Heavy attributes
@export var base_speed: float = 60.0
@export var punch_damage: int = 20
@export var super_armor_threshold: int = 10  # 低于此伤害的不会被击倒 / Below this damage doesn't cause knockdown

var damage_accumulator: int = 0  # 累积伤害以检查超级护甲 / Accumulate damage to check super armor


func _ready() -> void:
	max_health = 150
	health = 150
	speed = base_speed

	super()


## 获取当前速度 / Get current speed
func get_current_speed() -> float:
	return speed


## 受伤处理（超级护甲）/ Take damage with super armor
func take_damage(amount: int, knockback_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or not is_alive:
		return

	health -= amount
	took_damage.emit(amount)
	flash_white()

	# 检查超级护甲 / Check super armor
	if amount < super_armor_threshold:
		# 低伤害不会造成击退 / Low damage doesn't cause knockback
		return

	# 高伤害才会造成击退 / High damage causes knockback
	if knockback_direction != Vector2.ZERO:
		velocity = knockback_direction

	if health <= 0:
		die()


## 执行强力挥拳攻击 / Execute heavy punch attack
func perform_heavy_punch() -> void:
	if not target:
		return

	# 造成更多伤害 / Deal more damage
	var knockback = Vector2(facing_direction * 250, -100)
	target.take_damage(punch_damage, knockback)

	# 释放攻击槽 / Release attack slot
	release_attack_slot()
