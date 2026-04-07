## 玩家跳跃状态 / Player Jump State
## 视觉跳跃效果（精灵向上移动，阴影保持在地面） / Visual jump effect (sprite moves up, shadow stays on ground)
extends State
class_name PlayerJumpState

var jump_progress: float = 0.0
var jump_duration: float = 0.5
var jump_start_y: float = 0.0
var original_shadow_y: float = 0.0


func enter() -> void:
	"""进入跳跃状态 / Enter jump state"""
	if not character:
		return

	var player = character as Player

	jump_progress = 0.0
	jump_start_y = character.sprite_2d.position.y
	original_shadow_y = character.shadow.position.y

	character.animation_player.play("jump")
	character.is_jumping = true
	player.disable_hitbox()  # 跳跃时无法抓取 / Cannot grab while jumping


func process_physics(delta: float) -> void:
	"""处理跳跃物理 / Handle jump physics"""
	if not character:
		return

	var player = character as Player

	# 更新跳跃进度 / Update jump progress
	jump_progress += delta / jump_duration

	# 计算抛物线 / Calculate parabolic arc
	var parabola = sin(jump_progress * PI)
	var jump_offset = parabola * player.jump_height

	# 更新精灵Y位置 / Update sprite Y position
	character.sprite_2d.position.y = jump_start_y - jump_offset

	# 应用水平移动 / Apply horizontal movement
	var direction = player.input_direction
	direction.y *= player.y_speed_ratio
	direction = direction.normalized()

	character.velocity = direction * player.speed
	character.move_and_slide()

	# 更新面向方向 / Update facing direction
	if player.input_direction.x != 0:
		player.face_direction(player.input_direction.x)

	# 检查跳跃是否结束 / Check if jump finished
	if jump_progress >= 1.0:
		# 恢复精灵位置 / Restore sprite position
		character.sprite_2d.position.y = jump_start_y
		character.is_jumping = false

		# 检查是否着地时进行攻击 / Check if attacking while landing
		if player.is_attacking:
			player.start_attack()
			return
		else:
			state_machine.transition_to("PlayerIdleState")
			return

	# 跳跃期间的攻击 / Attack during jump
	if player.is_attacking:
		player.start_attack()
		return
