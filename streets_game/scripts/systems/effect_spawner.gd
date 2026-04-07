extends Node
## 效果生成器 - 管理所有视觉和声音效果 | Effect Spawner - Manages all visual and sound effects

class_name EffectSpawner

# 预加载场景 | Preloaded scenes
var _hit_effect_scene: PackedScene
var _damage_number_scene: PackedScene
var _pickup_scenes: Dictionary = {}

# 效果容器 | Effect container
var _effect_container: Node2D


func _ready() -> void:
	# 这是一个自动加载脚本 | This is an autoload script
	# 预加载所有效果场景 | Preload all effect scenes
	_hit_effect_scene = load("res://scenes/effects/hit_effect.tscn")
	_damage_number_scene = load("res://scenes/effects/damage_number.tscn")

	# 创建效果容器 | Create effects container
	_effect_container = Node2D.new()
	_effect_container.name = "EffectContainer"
	_effect_container.z_index = 10
	get_tree().get_root().add_child(_effect_container)


## 生成命中效果 | Spawn hit effect
func spawn_hit_effect(position: Vector2) -> HitEffect:
	var effect: HitEffect

	if _hit_effect_scene:
		effect = _hit_effect_scene.instantiate() as HitEffect
	else:
		effect = HitEffect.new()

	effect.position = position
	_effect_container.add_child(effect)
	return effect


## 生成伤害数字 | Spawn damage number (floating damage text)
func spawn_damage_number(position: Vector2, amount: int) -> Node:
	# 创建标签 | Create label
	var label = Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 24)
	label.position = position
	label.z_index = 20
	label.add_theme_color_override("font_color", Color.RED)

	_effect_container.add_child(label)

	# 动画：向上移动并淡出 | Animate: move up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", position + Vector2(0, -50), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

	return label


## 生成拾取物品 | Spawn pickup item
func spawn_pickup(position: Vector2, pickup_type: int) -> Pickup:
	# 映射到Pickup.PickupType | Map to Pickup.PickupType
	var scene_path = ""

	match pickup_type:
		Pickup.PickupType.HEALTH:
			scene_path = "res://scenes/pickups/health_pickup.tscn"
		Pickup.PickupType.STAR:
			scene_path = "res://scenes/pickups/star_pickup.tscn"
		Pickup.PickupType.MONEY:
			scene_path = "res://scenes/pickups/money_pickup.tscn"

	if scene_path == "":
		push_error("EffectSpawner: Unknown pickup type: %d" % pickup_type)
		return null

	# 加载或使用缓存的场景 | Load or use cached scene
	if not _pickup_scenes.has(scene_path):
		var scene = load(scene_path)
		if not scene:
			push_error("EffectSpawner: Failed to load pickup scene: %s" % scene_path)
			return null
		_pickup_scenes[scene_path] = scene

	var pickup = _pickup_scenes[scene_path].instantiate() as Pickup
	pickup.global_position = position
	_effect_container.add_child(pickup)

	return pickup


## 生成粒子效果 | Spawn particle effect
func spawn_particles(position: Vector2, effect_type: String) -> Node:
	# 根据效果类型生成不同的粒子 | Generate different particles based on type
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.z_index = 15

	match effect_type:
		"blood":
			_setup_blood_particles(particles)
		"spark":
			_setup_spark_particles(particles)
		"dust":
			_setup_dust_particles(particles)

	_effect_container.add_child(particles)
	particles.emitting = true

	# 自动清理 | Auto cleanup
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

	return particles


## 设置血液粒子 | Setup blood particles
func _setup_blood_particles(particles: GPUParticles2D) -> void:
	var process_mat = StandardMaterial3D.new()
	process_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	process_mat.albedo_color = Color.RED

	# 配置粒子属性 | Configure particle properties
	particles.amount = 10
	particles.lifetime = 1.0


## 设置火花粒子 | Setup spark particles
func _setup_spark_particles(particles: GPUParticles2D) -> void:
	var process_mat = StandardMaterial3D.new()
	process_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	process_mat.albedo_color = Color.YELLOW

	particles.amount = 15
	particles.lifetime = 0.8


## 设置灰尘粒子 | Setup dust particles
func _setup_dust_particles(particles: GPUParticles2D) -> void:
	var process_mat = StandardMaterial3D.new()
	process_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	process_mat.albedo_color = Color.GRAY

	particles.amount = 20
	particles.lifetime = 1.2


## 播放声音效果 | Play sound effect
func play_sfx(sound_path: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0) -> AudioStreamPlayer:
	var audio = AudioStreamPlayer.new()
	audio.stream = load(sound_path)
	audio.bus = "SFX"
	audio.volume_db = volume_db

	if position != Vector2.ZERO:
		# 使用3D音频播放器获得位置效果 | Use 3D audio player for positional effect
		var audio_3d = AudioStreamPlayer2D.new()
		audio_3d.stream = audio.stream
		audio_3d.bus = "SFX"
		audio_3d.volume_db = volume_db
		audio_3d.global_position = position
		_effect_container.add_child(audio_3d)
		audio_3d.play()

		await audio_3d.finished
		audio_3d.queue_free()

		return audio_3d as AudioStreamPlayer
	else:
		# 2D音频 | 2D audio
		_effect_container.add_child(audio)
		audio.play()

		await audio.finished
		audio.queue_free()

		return audio


## 屏幕闪烁效果 | Screen flash effect
func screen_flash(duration: float = 0.2, color: Color = Color.WHITE) -> void:
	var flash_rect = ColorRect.new()
	flash_rect.color = color
	flash_rect.anchor_left = 0
	flash_rect.anchor_top = 0
	flash_rect.anchor_right = 1
	flash_rect.anchor_bottom = 1
	flash_rect.z_index = 999
	_effect_container.add_child(flash_rect)

	# 快速淡出 | Fade out quickly
	var tween = create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(flash_rect.queue_free)


## 清空所有效果 | Clear all effects
func clear_all_effects() -> void:
	_effect_container.queue_free()
	_effect_container = Node2D.new()
	_effect_container.name = "EffectContainer"
	_effect_container.z_index = 10
	get_tree().get_root().add_child(_effect_container)
