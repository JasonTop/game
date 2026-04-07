## 玩家特殊技能状态 / Player Special State
## 闪亮攻击，消耗HP但击中敌人可恢复 / Flashy attack, costs HP but recovers on hits
extends State
class_name PlayerSpecialState

var special_anim_duration: float = 0.8
var special_progress: float = 0.0
var hitbox_window_start: float = 0.2
var hitbox_window_end: float = 0.6
var hitbox_active: bool = false
var hit_enemies: Array = []


func enter() -> void:
	## 进入特殊技能状态 / Enter special state
	if not character:
		return

	var player = character as Player

	special_progress = 0.0
	hit_enemies.clear()
	hitbox_active = false

	character.animation_player.play("special_move")

	# 启用无敌 / Enable invincibility
	character.set_invincible(true)

	# 重置输入 / Reset input
	player.wants_special = false


func physics_process(delta: float) -> void:
	## 处理特殊技能逻辑 / Handle special move logic
	if not character:
		return

	var player = character as Player

	# 更新进度 / Update progress
	special_progress += delta / special_anim_duration

	# 命中箱逻辑 / Hitbox logic
	if special_progress >= hitbox_window_start and special_progress <= hitbox_window_end:
		if not hitbox_active:
			character.enable_hitbox()
			hitbox_active = true
	else:
		if hitbox_active:
			character.disable_hitbox()
			hitbox_active = false

	# 保持位置不动 / Stay in place
	character.velocity = Vector2.ZERO
	character.move_and_slide()

	# 检查特殊技能是否完成 / Check if special finished
	if special_progress >= 1.0:
		character.disable_hitbox()
		character.set_invincible(false)

		# 如果击中了敌人，恢复HP / If hit enemies, recover HP
		if hit_enemies.size() > 0:
			player.recover_from_special(hit_enemies.size() * 5)

		state_machine.transition_to_by_name("IdleState")
		return


## 跟踪被击中的敌人 / Track hit enemies
func on_hitbox_hit(enemy: Node) -> void:
	## 当命中箱击中敌人时调用 / Called when hitbox hits enemy
	if enemy is BaseCharacter and enemy not in hit_enemies:
		hit_enemies.append(enemy)
		var knockback = Vector2(character.facing_direction * 200, -50)
		var player = character as Player
		enemy.take_damage(player.special_damage, knockback)
