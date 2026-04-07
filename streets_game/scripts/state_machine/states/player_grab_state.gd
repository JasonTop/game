## 玩家抓取状态 / Player Grab State
## 抓住敌人，可以挥拳或投掷 / Hold enemy, can punch or throw
extends State
class_name PlayerGrabState

var grab_hold_timer: float = 0.0
var grab_hold_duration: float = 0.1
var can_act: bool = false


func enter() -> void:
	## 进入抓取状态 / Enter grab state
	if not character:
		return

	var player = character as Player

	if not player.grab_target:
		state_machine.transition_to_by_name("IdleState")
		return

	character.animation_player.play("grab")
	character.disable_hitbox()
	grab_hold_timer = 0.0
	can_act = false

	# 移动到被抓取敌人的位置 / Move to grabbed enemy position
	character.global_position = player.grab_target.global_position


func physics_process(delta: float) -> void:
	## 处理抓取逻辑 / Handle grab logic
	if not character:
		return

	var player = character as Player

	# 检查抓取目标是否还活着 / Check if grab target is still alive
	if not player.grab_target or not player.grab_target.is_alive:
		player.release_grab()
		state_machine.transition_to_by_name("IdleState")
		return

	# 保持与被抓取目标在一起 / Stay with grabbed target
	character.velocity = Vector2.ZERO
	character.move_and_slide()

	# 抓取保持时间 / Grab hold time
	grab_hold_timer += delta
	if grab_hold_timer >= grab_hold_duration:
		can_act = true

	# 可以进行动作 / Can perform actions
	if can_act:
		# 攻击 - 挥拳敌人 / Attack - punch grabbed enemy
		if player.is_attacking:
			player.grab_target.take_damage(10, Vector2.ZERO)
			character.animation_player.play("grab_punch")
			grab_hold_timer = 0.0
			return

		# 投掷 / Throw
		if player.input_direction != Vector2.ZERO:
			# 获取投掷方向 / Get throw direction
			var throw_direction = player.input_direction.normalized()
			if throw_direction.y != 0:
				# 垂直投掷 / Vertical throw
				throw_direction.y *= player.y_speed_ratio

			player.throw_enemy(throw_direction)
			state_machine.transition_to_by_name("IdleState")
			return

	# 检查释放条件 / Check release conditions
	if Input.is_action_just_pressed("grab"):
		player.release_grab()
		state_machine.transition_to_by_name("IdleState")
		return
