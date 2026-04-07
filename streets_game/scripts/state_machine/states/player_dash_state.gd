## 玩家冲刺状态 / Player Dash State
## 快速冲刺，启动时短暂无敌 / Quick dash with brief invincibility during startup
extends State
class_name PlayerDashState

var dash_progress: float = 0.0
var dash_duration: float = 0.3
var invincibility_duration: float = 0.2


func enter() -> void:
	"""进入冲刺状态 / Enter dash state"""
	if not character:
		return

	var player = character as Player

	dash_progress = 0.0
	character.animation_player.play("dash")
	character.disable_hitbox()

	# 启用无敌 / Enable invincibility
	character.set_invincible(true)

	# 重置输入 / Reset input
	player.wants_dash = false


func process_physics(delta: float) -> void:
	"""处理冲刺物理 / Handle dash physics"""
	if not character:
		return

	var player = character as Player

	# 更新冲刺进度 / Update dash progress
	dash_progress += delta / dash_duration

	# 计算速度衰减 / Calculate speed decay
	var speed_factor = 1.0 - (dash_progress / dash_duration) * 0.5
	var dash_velocity = Vector2(player.facing_direction, 0) * player.dash_speed * speed_factor

	character.velocity = dash_velocity
	character.move_and_slide()

	# 检查无敌时间是否结束 / Check if invincibility time ended
	if dash_progress > invincibility_duration:
		character.set_invincible(false)

	# 检查冲刺是否结束 / Check if dash finished
	if dash_progress >= 1.0:
		character.velocity = Vector2.ZERO
		state_machine.transition_to("PlayerIdleState")
		return

	# 冲刺期间可以攻击 / Can attack during dash
	if player.is_attacking:
		player.start_attack()
		return
