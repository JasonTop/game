## 玩家星星移动状态 / Player Star Move State
## 强大无敌攻击，消耗一个星星 / Powerful invincible attack, consumes one star
extends State
class_name PlayerStarMoveState

var star_anim_duration: float = 1.0
var star_progress: float = 0.0
var hitbox_window_start: float = 0.15
var hitbox_window_end: float = 0.75
var hitbox_active: bool = false
var hit_enemies: Array = []


func enter() -> void:
	"""进入星星移动状态 / Enter star move state"""
	if not character:
		return

	var player = character as Player

	star_progress = 0.0
	hit_enemies.clear()
	hitbox_active = false

	character.animation_player.play("star_move")

	# 启用无敌 / Enable invincibility
	character.set_invincible(true)

	# 重置输入 / Reset input
	player.wants_star_move = false


func process_physics(delta: float) -> void:
	"""处理星星移动逻辑 / Handle star move logic"""
	if not character:
		return

	var player = character as Player

	# 更新进度 / Update progress
	star_progress += delta / star_anim_duration

	# 命中箱逻辑 - 更宽的窗口 / Hitbox logic - wider window
	if star_progress >= hitbox_window_start and star_progress <= hitbox_window_end:
		if not hitbox_active:
			character.enable_hitbox()
			hitbox_active = true
	else:
		if hitbox_active:
			character.disable_hitbox()
			hitbox_active = false

	# 短暂冲刺 / Brief dash forward
	if star_progress < 0.5:
		character.velocity = Vector2(player.facing_direction * player.dash_speed, 0)
	else:
		character.velocity = Vector2.ZERO

	character.move_and_slide()

	# 检查星星移动是否完成 / Check if star move finished
	if star_progress >= 1.0:
		character.disable_hitbox()
		character.set_invincible(false)

		state_machine.transition_to("PlayerIdleState")
		return


## 跟踪被击中的敌人 / Track hit enemies
func on_hitbox_hit(enemy: Node) -> void:
	"""当命中箱击中敌人时调用 / Called when hitbox hits enemy"""
	if enemy is BaseCharacter and enemy not in hit_enemies:
		hit_enemies.append(enemy)
		# 星星移动的伤害更高 / Star move does more damage
		var knockback = Vector2(character.facing_direction * 300, -100)
		enemy.take_damage(80, knockback)
