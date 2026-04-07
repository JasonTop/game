## 玩家被击状态 / Player Hit State
## 被敌人攻击击中时的眩晕状态 / Stun state when hit by enemy attack
extends State
class_name PlayerHitState

var hit_duration: float = 0.4
var hit_progress: float = 0.0


func enter() -> void:
	## 进入被击状态 / Enter hit state
	if not character:
		return

	var player = character as Player

	hit_progress = 0.0
	character.animation_player.play("hit")
	character.disable_hitbox()
	player.disable_hitbox()  # 被击中时无法攻击 / Cannot attack while hit

	# 短暂无敌 / Brief invincibility
	character.set_invincible(true)


func physics_process(delta: float) -> void:
	## 处理被击逻辑 / Handle hit logic
	if not character:
		return

	# 更新被击进度 / Update hit progress
	hit_progress += delta / hit_duration

	# 应用现有速度（由take_hit设置的击退） / Apply existing velocity (knockback from take_hit)
	character.move_and_slide()

	# 检查被击是否完成 / Check if hit finished
	if hit_progress >= 1.0:
		character.set_invincible(false)
		state_machine.transition_to_by_name("IdleState")
		return
