## 玩家击倒状态 / Player Knockdown State
## 被击倒到地面，起身时无敌 / Knocked to ground, invincible during getup
extends State
class_name PlayerKnockdownState

var knockdown_duration: float = 1.0
var knockdown_progress: float = 0.0
var getup_invincibility_duration: float = 0.6


func enter() -> void:
	## 进入击倒状态 / Enter knockdown state
	if not character:
		return

	var player = character as Player

	knockdown_progress = 0.0
	character.animation_player.play("knockdown")
	character.disable_hitbox()
	player.disable_hitbox()

	# 启用无敌（保持到起身完成） / Enable invincibility (until getup completes)
	character.set_invincible(true)

	# 重置精灵位置（防止跳跃高度残留） / Reset sprite position (prevent jump height residue)
	character.sprite_2d.position.y = 0


func physics_process(delta: float) -> void:
	## 处理击倒逻辑 / Handle knockdown logic
	if not character:
		return

	# 更新击倒进度 / Update knockdown progress
	knockdown_progress += delta / knockdown_duration

	# 应用击退速度衰减 / Apply knockback speed decay
	character.velocity *= 0.95
	character.move_and_slide()

	# 检查起身无敌是否结束 / Check if getup invincibility ended
	if knockdown_progress > getup_invincibility_duration:
		character.set_invincible(false)

	# 检查击倒是否完成 / Check if knockdown finished
	if knockdown_progress >= 1.0:
		character.velocity = Vector2.ZERO
		state_machine.transition_to_by_name("IdleState")
		return
