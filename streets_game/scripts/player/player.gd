extends CharacterBody2D
## 玩家角色控制腳本
## 包含移動、跳躍、射擊的基本功能

# === 可在 Inspector 調整的參數 ===
@export var speed: float = 300.0          # 移動速度
@export var jump_force: float = -500.0    # 跳躍力道（負值 = 向上）
@export var gravity: float = 1200.0       # 重力加速度

# === Coyote Time（土狼時間）與 Jump Buffer（跳躍緩衝）===
@export var coyote_time: float = 0.1      # 離開地面後仍可跳躍的寬限時間
@export var jump_buffer_time: float = 0.1 # 落地前按跳躍的緩衝時間

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# 子彈場景（需要自行建立 bullet.tscn）
# @export var bullet_scene: PackedScene

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump(delta)
	_handle_movement()
	_handle_shoot()
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
		velocity.y += gravity * delta

func _handle_jump(delta: float) -> void:
	# Jump Buffer: 記錄玩家按跳躍的時機
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# 如果在 Coyote Time 內且有 Jump Buffer，就跳
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_force
		coyote_timer = 0.0
		jump_buffer_timer = 0.0

func _handle_movement() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	# 翻轉角色面向
	if direction != 0:
		$AnimatedSprite2D.flip_h = direction < 0

	# 播放動畫（需要在 AnimatedSprite2D 中設定好 "idle", "run", "jump" 動畫）
	# if is_on_floor():
	# 	if direction == 0:
	# 		$AnimatedSprite2D.play("idle")
	# 	else:
	# 		$AnimatedSprite2D.play("run")
	# else:
	# 	$AnimatedSprite2D.play("jump")

func _handle_shoot() -> void:
	if Input.is_action_just_pressed("shoot"):
		# 實作射擊邏輯
		# var bullet = bullet_scene.instantiate()
		# bullet.position = $Muzzle.global_position
		# bullet.direction = -1.0 if $AnimatedSprite2D.flip_h else 1.0
		# get_tree().current_scene.add_child(bullet)
		pass
