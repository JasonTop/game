## 敌人：快速敌人 / Enemy: Slasher
## 快速敌人，从远处冲向玩家 / Fast enemy, dashes at player from distance
extends EnemyBase
class_name EnemySlasher

# 快速敌人属性 / Slasher attributes
@export var base_speed: float = 200.0
@export var dash_speed: float = 350.0
@export var slash_damage: int = 12
@export var dash_attack_range: float = 150.0

var is_dashing: bool = false


func _ready() -> void:
	max_health = 40
	health = 40
	speed = base_speed

	super()


## 获取当前速度 / Get current speed
func get_current_speed() -> float:
	if is_dashing:
		return dash_speed
	return speed


## 检查敌人是否应该冲刺 / Check if enemy should dash
func should_dash() -> bool:
	if not target or is_dashing:
		return false

	var distance = get_distance_to_target()
	return distance > attack_range and distance <= dash_attack_range


## 开始冲刺攻击 / Start dash attack
func start_dash_attack() -> void:
	is_dashing = true
	if state_machine:
		state_machine.transition_to_by_name("DashAttackState")


## 结束冲刺攻击 / End dash attack
func end_dash_attack() -> void:
	is_dashing = false


## 执行斜线攻击 / Execute slash attack
func perform_slash() -> void:
	if not target:
		return

	# 造成伤害 / Deal damage
	var knockback = Vector2(facing_direction * 200, -75)
	target.take_damage(slash_damage, knockback)

	# 释放攻击槽 / Release attack slot
	release_attack_slot()

	end_dash_attack()
