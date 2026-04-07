## Hitbox component for dealing damage
## 伤害判定盒 - 用于造成伤害
##
## This Area2D-based component is attached to attack animations and deals
## damage to enemies when it overlaps with their hurtboxes.
## It is disabled by default and should be enabled during attack animations.
class_name Hitbox extends Area2D

## Amount of damage this hitbox deals
## 此伤害判定盒造成的伤害值
@export var damage: int = 10

## Knockback force applied to hit targets
## Vector2(horizontal, vertical) - positive vertical for upward knockback
## 应用于被击中目标的击退力
## Vector2(水平, 竖直) - 正的竖直值表示向上击退
@export var knockback_force: Vector2 = Vector2(200.0, -100.0)

## Duration of hit stun applied to the hurtbox after being hit
## 被击中后应用于伤害判定盒的僵直持续时间
@export var hit_stun_duration: float = 0.3

## Reference to the owner character (usually set by the attack state)
## 所有者角色的引用（通常由攻击状态设置）
var owner_character: CharacterBody2D

## Signal emitted when this hitbox successfully hits a hurtbox
## 当此伤害判定盒成功击中伤害判定盒时发出的信号
signal hit_landed(hurtbox: Hurtbox)

## Track which hurtboxes we've already hit in this attack
## Prevents the same hurtbox from being hit multiple times in one activation
## 追踪在此攻击中已经击中的伤害判定盒
## 防止同一伤害判定盒在一次激活中被击中多次
var _hit_hurtboxes: Array[Hurtbox] = []


func _ready() -> void:
	"""Initialize the hitbox."""
	# Set up area collision signals
	# 设置区域碰撞信号
	area_entered.connect(_on_area_entered)

	# Disable by default - will be enabled during attack animations
	# 默认禁用 - 将在攻击动画期间启用
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


## Called when the hitbox activates (during attack animation)
## 伤害判定盒激活时调用（在攻击动画期间）
func activate() -> void:
	"""Enable this hitbox for collision detection."""
	_hit_hurtboxes.clear()  # Reset hit tracking
	# 重置击中追踪
	monitoring = true
	monitorable = true


## Called when the hitbox deactivates (attack animation ends)
## 伤害判定盒停用时调用（攻击动画结束）
func deactivate() -> void:
	"""Disable this hitbox and clear hit tracking."""
	monitoring = false
	monitorable = false
	_hit_hurtboxes.clear()


## Get the knockback direction based on target position
## 根据目标位置获取击退方向
##
## @param target - The target to knockback
## @returns The knockback force vector adjusted for direction
func get_knockback_force(target: Node2D) -> Vector2:
	"""
	Calculate knockback force adjusted for hit direction.
	Knockback always pushes away from the hitbox owner.
	击退力总是从伤害判定盒所有者推开。
	"""
	if not owner_character:
		return knockback_force

	var direction = 1.0 if target.global_position.x > owner_character.global_position.x else -1.0
	return Vector2(knockback_force.x * direction, knockback_force.y)


## Handle area collision with hurtboxes
## 处理与伤害判定盒的区域碰撞
##
## @param area - The Area2D that entered the hitbox's collision area
func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with a hurtbox."""
	# Check if the collided area is a Hurtbox
	# 检查碰撞区域是否为伤害判定盒
	if not area is Hurtbox:
		return

	var hurtbox = area as Hurtbox

	# Don't hit the same hurtbox twice in one activation
	# 在一次激活中不要击中同一伤害判定盒两次
	if hurtbox in _hit_hurtboxes:
		return

	# Don't hit invincible targets
	# 不要击中无敌目标
	if hurtbox.is_invincible:
		return

	# Track this hit
	# 追踪这个击中
	_hit_hurtboxes.append(hurtbox)

	# Calculate knockback force
	# 计算击退力
	var kb_force = get_knockback_force(hurtbox.get_parent())

	# Apply damage to the hurtbox
	# 对伤害判定盒造成伤害
	hurtbox.hurt(self, damage, kb_force, hit_stun_duration)

	# Emit the signal
	# 发出信号
	hit_landed.emit(hurtbox)
