## 敌人冲刺攻击状态 / Enemy Dash Attack State
## 快速敌人的冲刺攻击 / Fast enemy's dash attack
extends State
class_name EnemyDashAttackState

var dash_progress: float = 0.0
var dash_duration: float = 0.4
var has_dealt_damage: bool = false
var y_speed_ratio: float = 0.6


func enter() -> void:
	## 进入冲刺攻击状态 / Enter dash attack state
	if character:
		character.animation_player.play("dash_attack")
		character.disable_hitbox()
		dash_progress = 0.0
		has_dealt_damage = false


func physics_process(delta: float) -> void:
	## 处理冲刺攻击逻辑 / Handle dash attack logic
	if not character:
		return

	var enemy = character as EnemyBase

	# 更新冲刺进度 / Update dash progress
	dash_progress += delta / dash_duration

	# 计算朝向目标的方向 / Calculate direction toward target
	var direction_to_target = Vector2.ZERO
	if enemy.target:
		direction_to_target = (enemy.target.global_position - enemy.global_position).normalized()
		direction_to_target.y *= y_speed_ratio
		direction_to_target = direction_to_target.normalized()

	# 应用冲刺速度 / Apply dash speed
	var dash_speed = 350.0
	if enemy is EnemySlasher:
		dash_speed = (enemy as EnemySlasher).dash_speed

	character.velocity = direction_to_target * dash_speed
	character.move_and_slide()

	# 在冲刺中途造成伤害 / Deal damage mid-dash
	if dash_progress > 0.2 and dash_progress < 0.7 and not has_dealt_damage:
		has_dealt_damage = true

		if enemy is EnemySlasher:
			(enemy as EnemySlasher).perform_slash()

	# 检查冲刺是否完成 / Check if dash finished
	if dash_progress >= 1.0:
		character.velocity = Vector2.ZERO

		if enemy is EnemySlasher:
			(enemy as EnemySlasher).end_dash_attack()

		state_machine.transition_to_by_name("ApproachState")
		return
