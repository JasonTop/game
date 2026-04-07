## 敌人：投掷敌人 / Enemy: Thrower
## 保持距离，投掷石块进行远程攻击 / Keep distance, throw stones for ranged attacks
extends EnemyBase
class_name EnemyThrower

# 投掷敌人属性 / Thrower attributes
@export var base_speed: float = 80.0
@export var throw_damage: int = 10
@export var throw_range: float = 300.0
@export var preferred_distance: float = 250.0

# 投掷物引用 / Projectile reference
@export var projectile_scene: PackedScene = null
var is_throwing: bool = false


func _ready() -> void:
	max_health = 45
	health = 45
	speed = base_speed

	super()


## 获取当前速度 / Get current speed
func get_current_speed() -> float:
	return speed


## 检查敌人是否应该后退 / Check if enemy should retreat
func should_retreat() -> bool:
	if not target:
		return false

	var distance = get_distance_to_target()
	return distance < preferred_distance


## 检查敌人是否应该向前 / Check if enemy should advance
func should_advance() -> bool:
	if not target:
		return false

	var distance = get_distance_to_target()
	return distance > preferred_distance


## 检查是否可以投掷 / Check if can throw
func can_throw() -> bool:
	if not target or is_throwing:
		return false

	return get_distance_to_target() <= throw_range


## 执行投掷攻击 / Execute throw attack
func perform_throw() -> void:
	if not target or not projectile_scene:
		return

	is_throwing = true

	# 计算投掷方向 / Calculate throw direction
	var throw_direction = (target.global_position - global_position).normalized()

	# 创建投掷物 / Create projectile
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(facing_direction * 20, -20)
	projectile.set_direction(throw_direction)
	projectile.set_damage(throw_damage)
	projectile.set_owner(self)

	is_throwing = false

	# 释放攻击槽 / Release attack slot
	release_attack_slot()
