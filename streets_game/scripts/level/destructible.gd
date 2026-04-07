extends StaticBody2D
## 可破坏对象 - 桶、箱子等 | Destructible Objects - Barrels, crates, etc.

class_name Destructible

# 最大生命值 | Maximum health
@export var max_health: int = 3
# 破坏时掉落的物品 | Item to drop when destroyed
@export var drop_scene: PackedScene
# 掉落概率 | Chance to drop item (0.0-1.0)
@export var drop_chance: float = 0.5
# Sprite精灵 | Sprite reference
@export var sprite: Sprite2D
# 伤害数字颜色 | Damage number color
@export var damage_color: Color = Color.RED

# 内部状态 | Internal state
var current_health: int
var _hurtbox: Area2D
var _hit_effect_scene: PackedScene

signal destroyed
signal health_changed(new_health: int)


func _ready() -> void:
	current_health = max_health

	# 查找或创建Hurtbox | Find or create Hurtbox
	_hurtbox = find_child("Hurtbox", true, false) as Area2D
	if not _hurtbox:
		_hurtbox = Area2D.new()
		_hurtbox.name = "Hurtbox"
		_hurtbox.position = Vector2.ZERO
		add_child(_hurtbox)

		# 添加碰撞形状 | Add collision shape
		var shape = CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		if sprite:
			(shape.shape as RectangleShape2D).size = sprite.texture.get_size()
		_hurtbox.add_child(shape)

	# 连接Hurtbox信号 | Connect Hurtbox signals
	if _hurtbox.has_signal("area_entered"):
		_hurtbox.area_entered.connect(_on_hurtbox_hit)

	# 查找效果场景 | Find hit effect scene
	_hit_effect_scene = load("res://scenes/effects/hit_effect.tscn")


## 接受伤害 | Take damage
func take_damage(amount: int = 1) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)

	# 更新精灵帧显示破坏进度 | Update sprite frame to show damage
	if sprite:
		# 计算破坏百分比 | Calculate damage percentage
		var damage_percent = float(max_health - current_health) / float(max_health)

		# 根据损伤程度更新帧 | Update frame based on damage
		if current_health <= 0:
			sprite.frame = 2  # 破碎 | Broken
		elif damage_percent > 0.33:
			sprite.frame = 1  # 开裂 | Cracked
		else:
			sprite.frame = 0  # 完整 | Intact

	# 生成命中效果 | Spawn hit effect
	if EffectSpawner:
		EffectSpawner.spawn_hit_effect(global_position)

	# 播放命中声音 | Play hit sound
	_play_hit_sound()

	# 检查是否已破坏 | Check if destroyed
	if current_health <= 0:
		destroy()


## 破坏对象 | Destroy object
func destroy() -> void:
	# 播放破坏动画 | Play break animation
	_play_break_animation()

	# 根据概率掉落物品 | Drop item based on chance
	if drop_scene and randf() < drop_chance:
		var pickup = drop_scene.instantiate() as Node2D
		if pickup:
			pickup.global_position = global_position
			get_parent().add_child(pickup)
			# 添加轻微的随机偏移 | Add slight random offset
			pickup.global_position += Vector2(
				randf_range(-20, 20),
				randf_range(-20, 20)
			)

	destroyed.emit()

	# 等待动画后删除 | Queue free after animation
	await get_tree().create_timer(0.3).timeout
	queue_free()


## 播放命中声音 | Play hit sound
func _play_hit_sound() -> void:
	# 创建AudioStreamPlayer进行单次命中音效 | Create temp audio player for hit sound
	var audio = AudioStreamPlayer.new()
	audio.stream = load("res://sounds/sfx/hit_object.ogg")
	audio.bus = "SFX"
	audio.volume_db = -5.0
	add_child(audio)
	audio.play()

	# 音效播放完后删除 | Remove after playback
	await audio.finished
	audio.queue_free()


## 播放破坏动画 | Play break animation
func _play_break_animation() -> void:
	if not sprite:
		return

	# 缩放+淡出动画 | Scale and fade animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(sprite, "modulate:a", 0.5, 0.2)

	await tween.finished

	# 快速缩小和消失 | Quick shrink and disappear
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.1)
	tween2.tween_property(sprite, "modulate:a", 0.0, 0.1)


## Hurtbox命中处理 | Hurtbox hit handler
func _on_hurtbox_hit(area: Area2D) -> void:
	# 检查是否是玩家的攻击box | Check if it's a player attack box
	if area.is_in_group("player_attack"):
		take_damage(1)


## 重置对象 | Reset object (for respawning)
func reset() -> void:
	current_health = max_health
	if sprite:
		sprite.frame = 0
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
	health_changed.emit(current_health)
