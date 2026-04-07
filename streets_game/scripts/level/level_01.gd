extends Node2D
## 01关卡 - 城市街道 (夜间都市街道) | Level 01 - City Streets

class_name Level01

# 等级配置 | Level configuration
@export var player_spawn_position: Vector2 = Vector2(200, 360)
@export var total_width: float = 4000.0
@export var walkable_y_min: float = 280.0
@export var walkable_y_max: float = 450.0
@export var num_zones: int = 5

# 敌人场景预加载 | Enemy scene references
var _goon_scene: PackedScene
var _slasher_scene: PackedScene
var _thrower_scene: PackedScene
var _heavy_scene: PackedScene

# 关卡元素 | Level elements
var _player: Node2D
var _camera_controller: CameraController
var _combat_zones: Array[CombatZone] = []
var _zones_completed: int = 0
var _level_complete: bool = false

signal level_complete
signal zone_cleared(zone_index: int)


func _ready() -> void:
	# 加载敌人场景 | Load enemy scenes
	_goon_scene = load("res://scenes/enemies/goon.tscn")
	_slasher_scene = load("res://scenes/enemies/slasher.tscn")
	_thrower_scene = load("res://scenes/enemies/thrower.tscn")
	_heavy_scene = load("res://scenes/enemies/heavy.tscn")

	# 在缺少敌人时给出警告但继续 | Warn if enemy scenes missing but continue
	if not _goon_scene:
		push_warning("Level01: Goon scene not found at res://scenes/enemies/goon.tscn")
	if not _slasher_scene:
		push_warning("Level01: Slasher scene not found at res://scenes/enemies/slasher.tscn")
	if not _thrower_scene:
		push_warning("Level01: Thrower scene not found at res://scenes/enemies/thrower.tscn")
	if not _heavy_scene:
		push_warning("Level01: Heavy scene not found at res://scenes/enemies/heavy.tscn")

	# 设置摄像机 | Setup camera
	_setup_camera()

	# 设置玩家 | Setup player
	_setup_player()

	# 设置背景 | Setup background
	_setup_background()

	# 设置战斗区域 | Setup combat zones
	_setup_combat_zones()

	# 设置可破坏对象 | Setup destructibles
	_setup_destructibles()

	# 打印关卡信息 | Print level info
	print("Level 01: City Streets initialized")
	print("  Total width: %.0f px" % total_width)
	print("  Combat zones: %d" % num_zones)
	print("  Walkable Y range: %.0f - %.0f" % [walkable_y_min, walkable_y_max])


## 设置摄像机 | Setup camera
func _setup_camera() -> void:
	# 查找或创建摄像机控制器 | Find or create camera controller
	_camera_controller = get_tree().get_first_node_in_group("camera") as CameraController

	if not _camera_controller:
		_camera_controller = CameraController.new()
		_camera_controller.name = "CameraController"
		_camera_controller.add_to_group("camera")
		add_child(_camera_controller)

	# 配置摄像机 | Configure camera
	_camera_controller.follow_target = null  # Will be set when player is found
	_camera_controller.smoothing = 0.15
	_camera_controller.walkable_y_min = walkable_y_min
	_camera_controller.walkable_y_max = walkable_y_max


## 设置玩家 | Setup player
func _setup_player() -> void:
	# 查找现有玩家或使用生成位置 | Find existing player or use spawn position
	_player = get_tree().get_first_node_in_group("player")

	if _player:
		# 玩家已存在，移动到生成位置 | Player exists, move to spawn position
		_player.global_position = player_spawn_position
	else:
		# 创建占位符玩家（实际游戏中应该加载玩家场景）| Create placeholder player
		_player = Node2D.new()
		_player.name = "Player"
		_player.global_position = player_spawn_position
		_player.add_to_group("player")
		add_child(_player)
		push_warning("Level01: No player found, created placeholder")

	# 设置摄像机跟随 | Setup camera following
	if _camera_controller:
		_camera_controller.follow_target = _player


## 设置背景 | Setup background
func _setup_background() -> void:
	# 创建简单的背景 | Create simple background
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.15)
	background.anchor_left = 0
	background.anchor_top = 0
	background.anchor_right = 1
	background.anchor_bottom = 1
	background.z_index = -10
	add_child(background)

	# 添加视差背景（可选）| Add parallax background (optional)
	# 在实际游戏中，这会是带有建筑物和街道细节的动画背景
	# In a real game, this would be animated background with buildings and street details
	_create_parallax_layers()


## 创建视差背景层 | Create parallax background layers
func _create_parallax_layers() -> void:
	# 远距离建筑 | Distant buildings
	var far_buildings = ColorRect.new()
	far_buildings.color = Color(0.15, 0.15, 0.2)
	far_buildings.position = Vector2(0, 100)
	far_buildings.size = Vector2(total_width * 2, 150)
	far_buildings.z_index = -9
	add_child(far_buildings)

	# 中距离建筑 | Mid-distance buildings
	var mid_buildings = ColorRect.new()
	mid_buildings.color = Color(0.2, 0.2, 0.25)
	mid_buildings.position = Vector2(0, 250)
	mid_buildings.size = Vector2(total_width * 2, 100)
	mid_buildings.z_index = -8
	add_child(mid_buildings)


## 设置战斗区域 | Setup combat zones
func _setup_combat_zones() -> void:
	var zone_spacing = total_width / num_zones
	var zone_y = 350.0  # 中间Y位置 | Middle Y position

	# 区域配置 | Zone configurations
	var zone_configs = [
		# 区域1：教程区 | Zone 1: Tutorial
		{
			"name": "Zone 1: Tutorial",
			"enemies": [_goon_scene, _goon_scene, _goon_scene]
		},
		# 区域2：标准 | Zone 2: Standard
		{
			"name": "Zone 2: Standard",
			"enemies": [_goon_scene, _goon_scene, _goon_scene, _goon_scene, _slasher_scene]
		},
		# 区域3：混合 | Zone 3: Mixed
		{
			"name": "Zone 3: Mixed",
			"enemies": [
				_goon_scene, _goon_scene,
				_thrower_scene, _thrower_scene,
				_heavy_scene
			]
		},
		# 区域4：困难 | Zone 4: Hard
		{
			"name": "Zone 4: Hard",
			"enemies": [
				_goon_scene, _goon_scene, _goon_scene,
				_slasher_scene, _slasher_scene,
				_thrower_scene
			]
		},
		# 区域5：BOSS战 | Zone 5: Boss fight
		{
			"name": "Zone 5: Boss",
			"enemies": [
				_heavy_scene, _goon_scene, _goon_scene,
				_heavy_scene, _heavy_scene
			]
		}
	]

	# 创建战斗区域 | Create combat zones
	for i in range(num_zones):
		var zone_x = (i + 0.5) * zone_spacing
		var zone = _create_combat_zone(
			zone_x,
			zone_y,
			zone_configs[i]["name"],
			zone_configs[i]["enemies"]
		)
		_combat_zones.append(zone)


## 创建单个战斗区域 | Create single combat zone
func _create_combat_zone(
	x: float,
	y: float,
	name: String,
	enemy_scenes: Array
) -> CombatZone:
	var zone = CombatZone.new()
	zone.name = name
	zone.global_position = Vector2(x, y)
	zone.enemy_scenes = enemy_scenes
	zone.spawn_delay = 0.5
	zone.zone_width = 640.0
	zone.one_time_trigger = true

	# 添加Area2D形状 | Add Area2D collision shape
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(zone.zone_width, 200)
	zone.add_child(shape)

	# 连接信号 | Connect signals
	zone.zone_cleared.connect(_on_zone_cleared.bindv([_combat_zones.size()]))
	zone.zone_activated.connect(_on_zone_activated.bindv([_combat_zones.size()]))

	add_child(zone)
	return zone


## 设置可破坏对象 | Setup destructibles
func _setup_destructibles() -> void:
	var zone_spacing = total_width / num_zones

	# 在每个区域之间放置可破坏物体 | Place destructibles between zones
	for i in range(num_zones - 1):
		var x = (i + 1) * zone_spacing
		var y = walkable_y_min + (walkable_y_max - walkable_y_min) / 2.0

		# 随机放置多个可破坏物体 | Randomly place multiple destructibles
		for j in range(2):
			var offset_x = x + randf_range(-100, 100)
			var offset_y = y + randf_range(-50, 50)
			_create_destructible(Vector2(offset_x, offset_y))


## 创建可破坏物体 | Create destructible object
func _create_destructible(position: Vector2) -> void:
	var destructible = Destructible.new()
	destructible.name = "Destructible"
	destructible.global_position = position
	destructible.max_health = randi_range(2, 4)

	# 添加精灵 | Add sprite
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/barrel.png")
	if not sprite.texture:
		# 创建占位符精灵 | Create placeholder sprite
		var canvas = CanvasItem.new()
		sprite = Sprite2D.new()
		var rect = ColorRect.new()
		rect.color = Color.BROWN
		rect.size = Vector2(32, 48)
		destructible.add_child(rect)
	else:
		destructible.sprite = sprite
		destructible.add_child(sprite)

	# 添加静态物理体 | Add static physics body
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = RectangleShape2D.new()
	(collision_shape.shape as RectangleShape2D).size = Vector2(32, 48)
	static_body.add_child(collision_shape)

	destructible.add_child(static_body)
	add_child(destructible)


## 区域激活处理 | Zone activation handler
func _on_zone_activated(zone_index: int) -> void:
	print("Zone %d activated: %s" % [zone_index, _combat_zones[zone_index].name])


## 区域清除处理 | Zone cleared handler
func _on_zone_cleared(zone_index: int) -> void:
	_zones_completed += 1
	zone_cleared.emit(zone_index)
	print("Zone %d cleared: %s (%d/%d)" % [
		zone_index,
		_combat_zones[zone_index].name,
		_zones_completed,
		num_zones
	])

	# 检查是否关卡完成 | Check if level complete
	if _zones_completed >= num_zones:
		_on_level_complete()


## 关卡完成处理 | Level complete handler
func _on_level_complete() -> void:
	_level_complete = true
	print("Level 01 complete!")

	# 显示完成信息 | Show completion message
	var label = Label.new()
	label.text = "LEVEL COMPLETE"
	label.add_theme_font_size_override("font_size", 72)
	label.position = _player.global_position - Vector2(144, -150)
	label.z_index = 100
	add_child(label)

	# 动画 | Animate
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(2.0, 2.0), 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(1.5)
	tween.tween_callback(label.queue_free)

	level_complete.emit()


## 获取关卡统计 | Get level statistics
func get_level_stats() -> Dictionary:
	return {
		"level": 1,
		"name": "City Streets",
		"zones": num_zones,
		"completed_zones": _zones_completed,
		"is_complete": _level_complete,
		"total_width": total_width
	}


## 重置关卡 | Reset level
func reset_level() -> void:
	_zones_completed = 0
	_level_complete = false

	# 重置所有区域 | Reset all zones
	for zone in _combat_zones:
		zone.activated = false
		zone.enemies_alive = 0
		zone._spawn_index = 0

	# 重置玩家位置 | Reset player position
	if _player:
		_player.global_position = player_spawn_position


## 暂停/恢复关卡 | Pause/Resume level
func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	print("Level 01 paused: %s" % paused)
