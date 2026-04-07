## 基础角色类 - Base Character Class
## 玩家和敌人都继承此类 / Both player and enemies inherit from this
extends CharacterBody2D
class_name BaseCharacter

# 基础属性 / Basic Properties
@export var max_health: int = 100
var health: int:
	get:
		return _health
	set(value):
		_health = clampi(value, 0, max_health)
		health_changed.emit(_health, max_health)

var _health: int = 100

@export var speed: float = 150.0
@export var acceleration: float = 800.0

# 方向控制 / Direction Control
var facing_direction: float = 1.0  # 1 = right, -1 = left
var is_alive: bool = true
var is_invincible: bool = false

# 节点引用 / Node References
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine = $StateMachine

# 信号 / Signals
signal died
signal health_changed(new_health: int, max_health: int)
signal took_damage(amount: int)

func _ready() -> void:
	_health = max_health

	# 连接伤害信号 / Connect damage signals
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)


## 受伤处理 / Take damage
func take_damage(amount: int, knockback_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or not is_alive:
		return

	health -= amount
	took_damage.emit(amount)
	flash_white()

	# 应用击退 / Apply knockback
	if knockback_direction != Vector2.ZERO:
		velocity = knockback_direction

	if health <= 0:
		die()


## 死亡处理 / Handle death
func die() -> void:
	if not is_alive:
		return

	is_alive = false
	died.emit()


## 短暂白色闪光效果 / Brief white flash effect when hit
func flash_white() -> void:
	if not sprite_2d:
		return

	var original_modulate = sprite_2d.modulate
	sprite_2d.modulate = Color.WHITE

	await get_tree().create_timer(0.1).timeout
	sprite_2d.modulate = original_modulate


## 方向转向 / Face a direction
func face_direction(dir: float) -> void:
	if dir != 0:
		facing_direction = sign(dir)
		sprite_2d.scale.x = facing_direction


## 获取速度 / Get speed (可以被覆盖) / Can be overridden
func get_current_speed() -> float:
	return speed


## 重置速度 / Reset velocity
func reset_velocity() -> void:
	velocity = Vector2.ZERO


## 启用/禁用命中箱 / Enable/Disable hitbox
func enable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = true


func disable_hitbox() -> void:
	if hitbox:
		hitbox.monitoring = false


## 启用/禁用无敌 / Enable/Disable invincibility
func set_invincible(invincible: bool) -> void:
	is_invincible = invincible
	if sprite_2d:
		sprite_2d.modulate.a = 0.7 if invincible else 1.0


## 获取位置与方向 / Get position and direction
func get_position_ahead(distance: float = 0.0) -> Vector2:
	var offset = Vector2(facing_direction * distance, 0)
	return global_position + offset


func _on_hurtbox_area_entered(area: Area2D) -> void:
	# 伤害处理逻辑由子类实现 / Damage handling logic implemented by subclasses
	pass
