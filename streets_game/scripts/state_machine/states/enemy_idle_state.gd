## 敌人闲置状态 / Enemy Idle State
## 等待状态，稍后靠近目标 / Wait state, then approach target
extends State
class_name EnemyIdleState

var idle_timer: float = 0.0
var idle_duration: float = 1.0


func enter() -> void:
	"""进入闲置状态 / Enter idle state"""
	if character:
		character.animation_player.play("idle")
		character.reset_velocity()
		character.disable_hitbox()
		idle_timer = 0.0


func process_physics(delta: float) -> void:
	"""处理闲置逻辑 / Handle idle logic"""
	if not character:
		return

	var enemy = character as EnemyBase

	# 更新闲置计时 / Update idle timer
	idle_timer += delta

	# 保持不动 / Stay still
	character.velocity = Vector2.ZERO
	character.move_and_slide()

	# 检查是否应该靠近目标 / Check if should approach target
	if idle_timer >= idle_duration and enemy.is_target_in_range():
		state_machine.transition_to("EnemyApproachState")
		return

	# 始终检查目标是否在范围内 / Always check if target in range
	if enemy.is_target_in_range():
		state_machine.transition_to("EnemyApproachState")
		return
