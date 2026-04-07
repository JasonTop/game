## 敌人基类 / Enemy Base Class
## 所有敌人类型都继承此类 / All enemy types inherit from this
extends BaseCharacter
class_name EnemyBase

# AI参数 / AI parameters
@export var detection_range: float = 300.0
@export var attack_range: float = 60.0
@export var score_value: int = 100

# 目标 / Target
var target: Node2D = null

# 状态跟踪 / State tracking
var can_attack: bool = true
var attack_cooldown: float = 0.0
var attack_cooldown_time: float = 1.5

# 跟踪攻击槽是否被占用 / Track if attack slot is taken
var has_attack_slot: bool = false


func _ready() -> void:
	super()
	health = max_health
	disable_hitbox()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# 更新攻击冷却 / Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	else:
		can_attack = true


## 请求权限进行攻击 / Request permission to attack
func request_attack_slot() -> bool:
	if not can_attack or has_attack_slot:
		return false

	has_attack_slot = true
	can_attack = false
	attack_cooldown = attack_cooldown_time
	return true


## 释放攻击权限 / Release attack permission
func release_attack_slot() -> void:
	has_attack_slot = false


## 设置AI目标 / Set AI target
func set_target(new_target: Node2D) -> void:
	target = new_target


## 获取到目标的距离 / Get distance to target
func get_distance_to_target() -> float:
	if not target:
		return 999.0
	return global_position.distance_to(target.global_position)


## 检查目标是否在检测范围内 / Check if target in detection range
func is_target_in_range() -> bool:
	return get_distance_to_target() <= detection_range


## 检查目标是否在攻击范围内 / Check if target in attack range
func is_target_in_attack_range() -> bool:
	return get_distance_to_target() <= attack_range


## 朝向目标 / Face the target
func face_target() -> void:
	if not target:
		return

	var direction_to_target = target.global_position.x - global_position.x
	if direction_to_target != 0:
		face_direction(sign(direction_to_target))


## 死亡时随机掉落物品 / Randomly drop items on death
func drop_items() -> void:
	# 这个方法由SpawnManager或GameManager调用 / Called by SpawnManager or GameManager
	# 子类可以覆盖此方法添加特定的掉落物 / Subclasses can override to add specific drops
	pass


## 死亡处理 / Handle death
func die() -> void:
	if not is_alive:
		return

	super.die()
	drop_items()

	# 释放攻击槽 / Release attack slot
	if has_attack_slot:
		release_attack_slot()

	# 过渡到死亡状态 / Transition to death state
	if state_machine:
		state_machine.transition_to_by_name("DeathState")
