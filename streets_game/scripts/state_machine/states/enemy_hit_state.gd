## 敌人被击状态 / Enemy Hit State
## 被攻击击中时的眩晕状态 / Stun state when hit by attack
extends State
class_name EnemyHitState

var hit_duration: float = 0.3
var hit_progress: float = 0.0


func enter() -> void:
	"""进入被击状态 / Enter hit state"""
	if character:
		character.animation_player.play("hit")
		character.disable_hitbox()

		var enemy = character as EnemyBase
		# 释放攻击槽 / Release attack slot
		if enemy.has_attack_slot:
			enemy.release_attack_slot()

		# 短暂无敌 / Brief invincibility
		character.set_invincible(True)
		hit_progress = 0.0


func process_physics(delta: float) -> void:
	"""处理被击逻辑 / Handle hit logic"""
	if not character:
		return

	# 更新被击进度 / Update hit progress
	hit_progress += delta / hit_duration

	# 应用击退速度（由take_damage设置）/ Apply knockback velocity (set by take_damage)
	character.move_and_slide()

	# 检查被击是否完成 / Check if hit finished
	if hit_progress >= 1.0:
		character.set_invincible(false)
		state_machine.transition_to("EnemyApproachState")
		return
