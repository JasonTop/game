## 玩家控制器 - Player Controller
## 处理玩家输入和动作 / Handles player input and actions
extends BaseCharacter
class_name Player

# 运动参数 / Movement parameters
@export var dash_speed: float = 400.0
@export var jump_height: float = 100.0
@export var y_speed_ratio: float = 0.6  # Y轴速度是X轴的60% / Y axis speed is 60% of X axis

# 攻击参数 / Attack parameters
@export var special_damage: int = 60
@export var combo_window: float = 0.5  # 秒 / seconds
var combo_step: int = 0
var combo_window_timer: float = 0.0

# 抓取 / Grab mechanics
var grab_target: BaseCharacter = null
var is_grabbing: bool = false

# 星星计数 (超必杀) / Star count (for super move)
var star_count: int = 0

# 输入缓冲 / Input buffering
var input_direction: Vector2 = Vector2.ZERO
var is_attacking: bool = false
var wants_jump: bool = false
var wants_dash: bool = false
var wants_grab: bool = false
var wants_special: bool = false
var wants_star_move: bool = false

# 状态跟踪 / State tracking
var is_jumping: bool = false
var jump_apex: float = 0.0
var jump_start_y: float = 0.0

# 特殊 / Special move recovery
var special_health_cost: int = 25
var special_health_recovery: int = 5  # 每次击中恢复的HP / HP recovered per hit


func _ready() -> void:
	super()
	health = max_health
	disable_hitbox()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# 更新输入 / Update input
	_update_input()

	# 更新组合窗口 / Update combo window
	if combo_window_timer > 0:
		combo_window_timer -= delta
	else:
		combo_step = 0

	# 应用速度 / Apply velocity
	velocity = _calculate_movement_direction() * get_current_speed()
	move_and_slide()


## 更新输入检测 / Update input detection
func _update_input() -> void:
	input_direction = Vector2.ZERO

	# 8方向移动 / 8-directional movement
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
		face_direction(1.0)
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
		face_direction(-1.0)
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1

	input_direction = input_direction.normalized()

	# 动作按键 / Action buttons
	is_attacking = Input.is_action_just_pressed("attack")
	wants_jump = Input.is_action_just_pressed("jump")
	wants_dash = Input.is_action_just_pressed("dash")
	wants_grab = Input.is_action_just_pressed("grab")
	wants_special = Input.is_action_just_pressed("special")
	wants_star_move = Input.is_action_just_pressed("star_move")


## 计算移动方向 / Calculate movement direction
func _calculate_movement_direction() -> Vector2:
	if input_direction == Vector2.ZERO:
		return Vector2.ZERO

	var direction = input_direction
	# Y轴速度降低以模拟透视 / Reduce Y speed to simulate perspective
	direction.y *= y_speed_ratio

	return direction.normalized()


## 开始攻击组合 / Start attack combo
func start_attack() -> void:
	if not is_alive:
		return

	combo_step += 1
	if combo_step > 3:
		combo_step = 3

	combo_window_timer = combo_window

	# 过渡到攻击状态 / Transition to attack state
	if state_machine:
		state_machine.transition_to_by_name("AttackState")


## 开始跳跃 / Start jump
func start_jump() -> void:
	if not is_alive or is_grabbing:
		return

	is_jumping = true
	jump_start_y = sprite_2d.position.y

	if state_machine:
		state_machine.transition_to_by_name("JumpState")


## 开始冲刺 / Start dash
func start_dash() -> void:
	if not is_alive:
		return

	if state_machine:
		state_machine.transition_to_by_name("DashState")


## 抓取敌人 / Grab enemy
func grab_enemy(enemy: BaseCharacter) -> void:
	if not is_alive or is_grabbing:
		return

	grab_target = enemy
	is_grabbing = true

	if state_machine:
		state_machine.transition_to_by_name("GrabState")


## 释放抓取 / Release grab
func release_grab() -> void:
	if grab_target and is_grabbing:
		grab_target = null
		is_grabbing = false


## 投掷敌人 / Throw grabbed enemy
func throw_enemy(direction: Vector2) -> void:
	if not grab_target or not is_grabbing:
		return

	# 传递方向和伤害给敌人 / Pass direction and damage to enemy
	var knockback = direction.normalized() * 400.0
	grab_target.take_damage(15, knockback)

	release_grab()
	state_machine.transition_to_by_name("IdleState")


## 使用特殊技能 / Use special move
func use_special() -> void:
	if not is_alive or health < special_health_cost:
		return

	# 消耗HP / Cost HP
	health -= special_health_cost

	if state_machine:
		state_machine.transition_to_by_name("SpecialState")


## 星星移动 / Star move (invincible powerup attack)
func use_star_move() -> void:
	if not is_alive or star_count <= 0:
		return

	star_count -= 1

	if state_machine:
		state_machine.transition_to_by_name("StarMoveState")


## 获得星星 / Gain star
func gain_star() -> void:
	star_count += 1


## 特殊技能恢复生命 / Recover health from special move hits
func recover_from_special(amount: int = 0) -> void:
	var recovery = amount if amount > 0 else special_health_recovery
	health += recovery


## 被击中 / Take hit
func take_hit(knockback_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or is_grabbing:
		return

	if state_machine:
		state_machine.transition_to_by_name("HitState")

	if knockback_direction != Vector2.ZERO:
		velocity = knockback_direction


## 被击倒 / Get knocked down
func take_knockdown(knockback_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or is_grabbing:
		return

	if state_machine:
		state_machine.transition_to_by_name("KnockdownState")

	if knockback_direction != Vector2.ZERO:
		velocity = knockback_direction


## 获取当前速度 / Get current speed
func get_current_speed() -> float:
	return speed
