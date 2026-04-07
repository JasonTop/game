## 敌人撤退状态 / Enemy Retreat State
## 远程敌人的后退状态，保持距离 / Ranged enemy's retreat state, maintain distance
extends State
class_name EnemyRetreatState

var y_speed_ratio: float = 0.6


func enter() -> void:
	## 进入撤退状态 / Enter retreat state
	if character:
		character.animation_player.play("walk")
		character.disable_hitbox()


func physics_process(delta: float) -> void:
	## 处理撤退逻辑 / Handle retreat logic
	if not character:
		return

	var enemy = character as EnemyBase

	# 检查目标是否仍在范围内 / Check if target still in range
	if not enemy.is_target_in_range():
		state_machine.transition_to_by_name("IdleState")
		return

	# 朝向目标 / Face target
	enemy.face_target()

	# 计算远离目标的方向 / Calculate direction away from target
	var direction_from_target = (enemy.global_position - enemy.target.global_position).normalized()
	direction_from_target.y *= y_speed_ratio
	direction_from_target = direction_from_target.normalized()

	# 应用速度 / Apply velocity
	character.velocity = direction_from_target * enemy.get_current_speed()
	character.move_and_slide()

	# 特定敌人行为 / Specific enemy behavior
	if enemy is EnemyThrower:
		var thrower = enemy as EnemyThrower

		# 检查是否应该停止撤退 / Check if should stop retreating
		if not thrower.should_retreat() and thrower.can_throw():
			# 回到靠近状态进行投掷 / Return to approach state to throw
			if thrower.request_attack_slot():
				state_machine.transition_to_by_name("AttackState")
				return
			else:
				state_machine.transition_to_by_name("ApproachState")
				return
