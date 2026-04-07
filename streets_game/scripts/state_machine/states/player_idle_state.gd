## 玩家闲置状态 / Player Idle State
## 默认状态，等待输入 / Default state, waiting for input
extends State
class_name PlayerIdleState


func enter() -> void:
	"""进入闲置状态 / Enter idle state"""
	if character:
		character.animation_player.play("idle")
		character.reset_velocity()
		character.disable_hitbox()


func process_physics(delta: float) -> void:
	"""处理物理帧 / Handle physics processing"""
	if not character:
		return

	var player = character as Player

	# 检查是否需要切换状态 / Check if we need to transition
	# 移动 / Movement
	if player.input_direction != Vector2.ZERO:
		state_machine.transition_to("PlayerWalkState")
		return

	# 攻击 / Attack
	if player.is_attacking:
		player.start_attack()
		return

	# 跳跃 / Jump
	if player.wants_jump:
		player.start_jump()
		return

	# 冲刺 / Dash
	if player.wants_dash:
		player.start_dash()
		return

	# 特殊技能 / Special move
	if player.wants_special:
		player.use_special()
		return

	# 星星移动 / Star move
	if player.wants_star_move:
		player.use_star_move()
		return

	# 应用零速度 / Apply zero velocity
	character.velocity = Vector2.ZERO
	character.move_and_slide()
