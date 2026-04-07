extends Area2D
## 拾取物品 - 血瓶、星星等 | Pickup Items - Health, Stars, etc.

class_name Pickup

enum PickupType { HEALTH, STAR, MONEY }

# 物品类型 | Pickup type
@export var pickup_type: PickupType = PickupType.HEALTH
# 数值 | Value (health amount or star count)
@export var value: int = 30
# 浮动动画速度 | Float animation speed
@export var bob_speed: float = 2.0
# 浮动幅度 | Float amplitude
@export var bob_amplitude: float = 10.0
# 旋转速度 | Rotation speed
@export var rotation_speed: float = 2.0

# 内部状态 | Internal state
var _time_elapsed: float = 0.0
var _initial_position: Vector2
var _collected: bool = false

signal collected(type: PickupType, value: int)


func _ready() -> void:
	_initial_position = position

	# 连接Area2D信号 | Connect Area2D signals
	body_entered.connect(_on_body_entered)

	# 创建初始动画 | Create initial spawn animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# 开启闪烁效果 | Start glow effect
	_start_glow_animation()


func _process(delta: float) -> void:
	if _collected:
		return

	_time_elapsed += delta

	# 上下浮动动画 | Bob up and down
	var bob_offset = sin(_time_elapsed * bob_speed) * bob_amplitude
	position = _initial_position + Vector2(0, bob_offset)

	# 缓慢旋转 | Slow rotation
	rotation += rotation_speed * delta


## 处理玩家接触 | Handle player contact
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)


## 收集物品 | Collect pickup
func collect(player: Node2D) -> void:
	if _collected:
		return

	_collected = true

	# 应用效果 | Apply effect
	_apply_effect(player)

	# 播放收集声音 | Play collection sound
	_play_collect_sound()

	# 播放收集动画 | Play collection animation
	_play_collect_animation()


## 应用物品效果 | Apply pickup effect
func _apply_effect(player: Node2D) -> void:
	match pickup_type:
		PickupType.HEALTH:
			# 恢复玩家生命值 | Restore player health
			if player.has_method("heal"):
				player.heal(value)
			elif "health" in player and "max_health" in player:
				player.health = min(
					player.health + value,
					player.max_health
				)

		PickupType.STAR:
			# 增加星星计数 | Increase star count
			if has_node("/root/GameManager"):
				var game_manager = get_node("/root/GameManager")
				if game_manager.has_method("add_stars"):
					game_manager.add_stars(value)

		PickupType.MONEY:
			# 增加金钱 | Increase money
			if has_node("/root/GameManager"):
				var game_manager = get_node("/root/GameManager")
				if game_manager.has_method("add_money"):
					game_manager.add_money(value)

	collected.emit(pickup_type, value)


## 播放收集声音 | Play collection sound
func _play_collect_sound() -> void:
	# 检查音效文件是否存在 / Check if sound file exists
	var sound_path = "res://sounds/sfx/pickup.ogg"
	if not ResourceLoader.exists(sound_path):
		return

	var audio = AudioStreamPlayer.new()
	audio.stream = load(sound_path)
	audio.volume_db = 0.0
	add_child(audio)
	audio.play()

	await audio.finished
	audio.queue_free()


## 播放闪烁动画 | Play glow animation
func _start_glow_animation() -> void:
	# 循环闪烁 | Loop glow
	while not _collected:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)

		tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.3)

		await get_tree().create_timer(0.6).timeout


## 播放收集动画 | Play collection animation
func _play_collect_animation() -> void:
	# 向上飞行并淡出 | Fly up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -50), 0.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.4)

	await tween.finished
	queue_free()


## 获取物品类型名称 | Get pickup type name
func get_type_name() -> String:
	match pickup_type:
		PickupType.HEALTH:
			return "Health"
		PickupType.STAR:
			return "Star"
		PickupType.MONEY:
			return "Money"
		_:
			return "Unknown"
