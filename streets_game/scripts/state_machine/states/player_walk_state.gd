## 玩家行走状态 / Player Walk State
## 8方向移动 / 8-directional movement
extends State
class_name PlayerWalkState


func enter() -> void:
	## 进入行走状态 / Enter walk state
	if character:
		character.animation_player.play("walk")
		character.disable_hitbox()


func physics_process(delta: float) -> void:
	## 处理移动和输入 / Handle movement and input
	if not character:
		return

	var player = character as Player

	# 检查是否停止移动 / Check if movement stopped
	if player.input_direction == Vector2.ZERO:
		state_machine.transition_to_by_name("IdleState")
		return

	# 计算速度，Y轴速度是X轴的60% / Calculate velocity with Y-axis ratio
	var direction = player.input_direction
	direction.y *= player.y_speed_ratio
	direction = direction.normalized()

	character.velocity = direction * player.speed

	# 更新面向方向 / Update facing direction
	if player.input_direction.x != 0:
		player.face_direction(player.input_direction.x)

	# 应用移动 / Apply movement
	character.move_and_slide()

	# 检查动作按键 / Check action buttons
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
