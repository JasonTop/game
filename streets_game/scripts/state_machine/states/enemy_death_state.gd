## 敌人死亡状态 / Enemy Death State
## 执行死亡动画并清除敌人 / Execute death animation and remove enemy
extends State
class_name EnemyDeathState

var death_duration: float = 1.0
var death_progress: float = 0.0


func enter() -> void:
	"""进入死亡状态 / Enter death state"""
	if character:
		character.animation_player.play("death")
		character.disable_hitbox()

		var enemy = character as EnemyBase
		# 释放攻击槽 / Release attack slot
		if enemy.has_attack_slot:
			enemy.release_attack_slot()

		death_progress = 0.0


func process_physics(delta: float) -> void:
	"""处理死亡逻辑 / Handle death logic"""
	if not character:
		return

	# 更新死亡进度 / Update death progress
	death_progress += delta / death_duration

	# 速度衰减 / Speed decay
	character.velocity *= 0.90
	character.move_and_slide()

	# 检查死亡是否完成 / Check if death finished
	if death_progress >= 1.0:
		# 移除敌人 / Remove enemy
		if character:
			character.queue_free()
		return
