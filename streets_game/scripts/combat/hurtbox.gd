## Hurtbox component for receiving damage
## 伤害判定盒 - 用于接收伤害
##
## This Area2D-based component represents the hittable area of a character.
## It detects collisions with hitboxes and notifies observers of damage.
class_name Hurtbox extends Area2D

## Signal emitted when this hurtbox is hit by a hitbox
## 当此伤害判定盒被伤害判定盒击中时发出的信号
signal hurt(hitbox: Hitbox, damage: int, knockback: Vector2, hit_stun: float)

## Whether this hurtbox is currently invincible
## 此伤害判定盒当前是否无敌
var is_invincible: bool = false

## Timer for tracking invincibility duration
## 用于追踪无敌持续时间的计时器
var _invincibility_timer: float = 0.0

## Parent character (usually set in _ready)
## 父角色（通常在_ready中设置）
var _character: Node


func _ready() -> void:
	## Initialize the hurtbox
	# Get the parent character
	# 获取父角色
	_character = get_parent()

	# Set up area detection
	# 设置区域检测
	monitorable = true
	monitoring = false  # We only need to detect when hitboxes enter us
	# 我们只需要检测伤害判定盒何时进入我们


## Called every frame to update invincibility duration
## 每帧调用以更新无敌持续时间
func _process(delta: float) -> void:
	if is_invincible and _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			set_invincible(false)


## Apply damage to this hurtbox
## 对此伤害判定盒造成伤害
##
## This method is called by hitboxes when they collide with this hurtbox.
## It emits the hurt signal with damage information.
##
## @param hitbox - The hitbox that hit this hurtbox
## @param damage - Amount of damage to deal
## @param knockback - Knockback force vector
## @param hit_stun - Duration of hit stun to apply
func hurt(
	hitbox: Hitbox,
	damage: int,
	knockback: Vector2,
	hit_stun: float
) -> void:
	if is_invincible:
		return

	# Emit the hurt signal with all damage information
	# 发出包含所有伤害信息的hurt信号
	hurt.emit(hitbox, damage, knockback, hit_stun)


## Set invincibility state with optional duration
## 设置无敌状态，可选持续时间
##
## When invincible, this hurtbox will not receive damage.
## Pass a duration > 0 to automatically end invincibility after that time.
##
## @param invincible - Whether to set invincible
## @param duration - Optional duration in seconds (0 = indefinite)
func set_invincible(invincible: bool, duration: float = 0.0) -> void:
	is_invincible = invincible

	if invincible and duration > 0.0:
		# Set a timer for automatic invincibility end
		# 设置计时器以自动结束无敌
		_invincibility_timer = duration
		set_process(true)
	elif not invincible:
		_invincibility_timer = 0.0
		set_process(_needs_process())


## Determine if _process is needed
## 确定是否需要_process
func _needs_process() -> bool:
	return is_invincible and _invincibility_timer > 0.0


## Flash the hurtbox to indicate invincibility
## 闪烁伤害判定盒以指示无敌状态
##
## This is a helper method that can be called when setting invincibility.
## It modulates the modulate property for a visual feedback effect.
##
## @param duration - How long to show the invincibility effect
func flash_invincibility(duration: float = 0.3) -> void:
	# Get the character's modulate if available
	# 如果可用，获取角色的调制
	if _character and _character.has_method("get_modulate"):
		var original_modulate = _character.modulate

		# Create a quick flash effect
		# 创建快速闪现效果
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)

		# Flash white
		# 闪现白色
		tween.tween_property(_character, "modulate", Color.WHITE, duration * 0.5)

		# Return to original
		# 返回原始颜色
		tween.tween_property(_character, "modulate", original_modulate, duration * 0.5)


## Get the center position of this hurtbox
## 获取此伤害判定盒的中心位置
func get_center() -> Vector2:
	if has_meta("shape_cache"):
		var shape = get_meta("shape_cache")
		if shape:
			return global_position + shape.get_rect().get_center()

	return global_position
