## 玩家攻击状态 / Player Attack State
## 处理组合拳 / Handle punch combo chain
extends State
class_name PlayerAttackState

var attack_anim_name: String = ""
var hitbox_active: bool = false


func enter() -> void:
	## 进入攻击状态 / Enter attack state
	if not character:
		return

	var player = character as Player

	# 根据组合步数播放动画 / Play animation based on combo step
	match player.combo_step:
		1:
			attack_anim_name = "punch1"
		2:
			attack_anim_name = "punch2"
		3:
			attack_anim_name = "punch3"
		_:
			attack_anim_name = "punch1"
			player.combo_step = 1

	character.animation_player.play(attack_anim_name)
	character.disable_hitbox()
	hitbox_active = false

	# 重置输入 / Reset input
	player.is_attacking = false


func physics_process(delta: float) -> void:
	## 处理攻击逻辑 / Handle attack logic
	if not character:
		return

	var player = character as Player

	# 检查动画是否播放完成 / Check if attack animation finished
	var anim = character.animation_player
	if anim.is_playing() and anim.current_animation == attack_anim_name:
		# 动画仍在播放 / Animation still playing
		# 在动画中间启用命中箱 / Enable hitbox during animation
		var anim_progress = anim.current_animation_position / anim.current_animation_length

		# 在前50%时启用命中箱 / Enable hitbox in first 50% of animation
		if anim_progress < 0.5 and not hitbox_active:
			character.enable_hitbox()
			hitbox_active = true
		elif anim_progress >= 0.5 and hitbox_active:
			character.disable_hitbox()
			hitbox_active = false
	else:
		# 动画播放完成 / Animation finished
		character.disable_hitbox()

		# 检查是否继续组合 / Check if continuing combo
		if player.is_attacking and player.combo_window_timer > 0:
			# 继续组合 / Continue combo
			player.start_attack()
			return
		else:
			# 组合结束，返回闲置 / Combo finished, return to idle
			state_machine.transition_to_by_name("IdleState")
			return

	# 攻击期间保持位置 / Maintain position during attack
	character.velocity = Vector2.ZERO
	character.move_and_slide()

	# 检查跳跃 / Check for jump
	if player.wants_jump:
		player.start_jump()
		return
