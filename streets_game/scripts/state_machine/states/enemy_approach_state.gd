## 敌人靠近状态 / Enemy Approach State
## 移动朝向目标 / Move toward target
extends State
class_name EnemyApproachState

var y_speed_ratio: float = 0.6  # 与玩家相同的比例 / Same ratio as player


func enter() -> void:
	## 进入靠近状态 / Enter approach state
	if character:
		character.animation_player.play("walk")
		character.disable_hitbox()


func physics_process(delta: float) -> void:
	## 处理靠近逻辑 / Handle approach logic
	if not character:
		return

	var enemy = character as EnemyBase

	# 检查目标是否仍在范围内 / Check if target still in range
	if not enemy.is_target_in_range():
		state_machine.transition_to_by_name("IdleState")
		return

	# 朝向目标 / Face target
	enemy.face_target()

	# 计算朝向目标的方向 / Calculate direction toward target
	var direction_to_target = enemy.target.global_position - enemy.global_position
	direction_to_target = direction_to_target.normalized()

	# 应用Y轴比例 / Apply Y-axis ratio
	var adjusted_direction = direction_to_target
	adjusted_direction.y *= y_speed_ratio
	adjusted_direction = adjusted_direction.normalized()

	# 应用速度 / Apply velocity
	character.velocity = adjusted_direction * enemy.get_current_speed()
	character.move_and_slide()

	# 检查是否在攻击范围内 / Check if in attack range
	if enemy.is_target_in_attack_range():
		# 请求攻击槽 / Request attack slot
		if enemy.request_attack_slot():
			state_machine.transition_to_by_name("AttackState")
			return
		else:
			# 等待攻击槽 / Wait for attack slot
			state_machine.transition_to_by_name("IdleState")
			return

	# 特殊敌人类型的特殊行为 / Special behavior for specific enemy types
	_handle_special_enemy_behavior(enemy)


## 处理特殊敌人行为 / Handle special enemy behavior
func _handle_special_enemy_behavior(enemy: EnemyBase) -> void:
	## 为特定敌人类型处理特殊逻辑 / Handle special logic for specific enemy types
	if enemy is EnemySlasher:
		var slasher = enemy as EnemySlasher
		if slasher.should_dash():
			slasher.start_dash_attack()
			state_machine.transition_to_by_name("DashAttackState")

	elif enemy is EnemyThrower:
		var thrower = enemy as EnemyThrower
		if thrower.should_retreat():
			state_machine.transition_to_by_name("RetreatState")
		elif thrower.can_throw() and thrower.request_attack_slot():
			state_machine.transition_to_by_name("AttackState")
