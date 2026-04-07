## 敌人攻击状态 / Enemy Attack State
## 执行攻击动画，造成伤害 / Execute attack animation, deal damage
extends State
class_name EnemyAttackState

var attack_anim_name: String = "attack"
var attack_progress: float = 0.0
var attack_duration: float = 0.6
var has_dealt_damage: bool = false


func enter() -> void:
	## 进入攻击状态 / Enter attack state
	if not character:
		return

	var enemy = character as EnemyBase

	attack_progress = 0.0
	has_dealt_damage = false
	character.animation_player.play(attack_anim_name)
	character.disable_hitbox()


func physics_process(delta: float) -> void:
	## 处理攻击逻辑 / Handle attack logic
	if not character:
		return

	var enemy = character as EnemyBase

	# 更新攻击进度 / Update attack progress
	attack_progress += delta / attack_duration

	# 在攻击中途造成伤害 / Deal damage mid-attack
	if attack_progress > 0.3 and not has_dealt_damage:
		has_dealt_damage = true

		# 调用特定敌人的攻击方法 / Call specific enemy's attack method
		if enemy is EnemyGoon:
			(enemy as EnemyGoon).perform_punch()
		elif enemy is EnemyHeavy:
			(enemy as EnemyHeavy).perform_heavy_punch()
		elif enemy is EnemySlasher:
			(enemy as EnemySlasher).perform_slash()
		elif enemy is EnemyThrower:
			(enemy as EnemyThrower).perform_throw()

	# 保持位置不动 / Stay in place
	character.velocity = Vector2.ZERO
	character.move_and_slide()

	# 检查攻击是否完成 / Check if attack finished
	if attack_progress >= 1.0:
		character.disable_hitbox()

		# 返回靠近状态 / Return to approach state
		state_machine.transition_to_by_name("ApproachState")
		return
