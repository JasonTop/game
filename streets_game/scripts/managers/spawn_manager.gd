## 生成管理器 / Spawn Manager
## 管理敌人生成和攻击槽 / Manages enemy spawning and attack slots
extends Node
class_name SpawnManager

# 攻击槽管理 / Attack slot management
var attack_slots: int = 3  # 同时允许的攻击数 / Simultaneous attacks allowed
var active_attack_count: int = 0

# 敌人列表 / Enemy tracking
var active_enemies: Array[EnemyBase] = []
var spawn_points: Array[Node2D] = []

# 预制体 / Prefabs
@export var goon_scene: PackedScene
@export var heavy_scene: PackedScene
@export var slasher_scene: PackedScene
@export var thrower_scene: PackedScene

# 玩家引用 / Player reference
var player: Player = null


func _ready() -> void:
	"""初始化生成管理器 / Initialize spawn manager"""
	# 查找玩家 / Find player
	player = get_tree().get_first_child_in_group("player") as Player

	# 收集生成点 / Collect spawn points
	for child in get_children():
		if child is Node2D and child.name.contains("SpawnPoint"):
			spawn_points.append(child)


## 请求攻击槽 / Request attack slot
func request_attack_slot() -> bool:
	"""请求权限执行攻击 / Request permission to execute attack"""
	if active_attack_count < attack_slots:
		active_attack_count += 1
		return true
	return false


## 释放攻击槽 / Release attack slot
func release_attack_slot() -> void:
	"""释放攻击权限 / Release attack permission"""
	if active_attack_count > 0:
		active_attack_count -= 1


## 生成敌人 / Spawn enemy
func spawn_enemy(enemy_type: String, position: Vector2 = Vector2.ZERO) -> EnemyBase:
	"""生成一个敌人 / Spawn an enemy"""
	var scene: PackedScene = null
	var enemy: EnemyBase = null

	match enemy_type.to_lower():
		"goon":
			scene = goon_scene
		"heavy":
			scene = heavy_scene
		"slasher":
			scene = slasher_scene
		"thrower":
			scene = thrower_scene
		_:
			push_error("Unknown enemy type: %s" % enemy_type)
			return null

	if not scene:
		push_error("Enemy scene not set for type: %s" % enemy_type)
		return null

	enemy = scene.instantiate() as EnemyBase
	add_child(enemy)

	# 设置位置 / Set position
	if position != Vector2.ZERO:
		enemy.global_position = position
	elif spawn_points.size() > 0:
		var spawn_point = spawn_points[randi() % spawn_points.size()]
		enemy.global_position = spawn_point.global_position

	# 设置目标 / Set target
	if player:
		enemy.set_target(player)

	# 添加到活跃敌人列表 / Add to active enemies
	active_enemies.append(enemy)

	# 连接死亡信号 / Connect death signal
	if enemy.died.is_connected(_on_enemy_died):
		return enemy

	enemy.died.connect(_on_enemy_died.bindv([enemy]))

	return enemy


## 立即生成多个敌人 / Spawn multiple enemies at once
func spawn_wave(wave_config: Array) -> Array[EnemyBase]:
	"""生成一波敌人 / Spawn a wave of enemies
	wave_config format: [{"type": "goon", "count": 3, "offset": Vector2(50, 50)}, ...]
	"""
	var spawned: Array[EnemyBase] = []

	for config in wave_config:
		var enemy_type: String = config.get("type", "goon")
		var count: int = config.get("count", 1)
		var offset: Vector2 = config.get("offset", Vector2.ZERO)

		for i in range(count):
			var spawn_pos = get_random_spawn_position() + offset * i
			var enemy = spawn_enemy(enemy_type, spawn_pos)
			if enemy:
				spawned.append(enemy)

	return spawned


## 获取随机生成位置 / Get random spawn position
func get_random_spawn_position() -> Vector2:
	"""获取随机的生成位置 / Get a random spawn position"""
	if spawn_points.size() == 0:
		return Vector2(500, 300)

	return spawn_points[randi() % spawn_points.size()].global_position


## 敌人死亡回调 / Enemy death callback
func _on_enemy_died(enemy: EnemyBase) -> void:
	"""当敌人死亡时调用 / Called when an enemy dies"""
	if enemy in active_enemies:
		active_enemies.erase(enemy)

	# 释放它可能持有的攻击槽 / Release any attack slot it might hold
	if enemy.has_attack_slot:
		enemy.release_attack_slot()


## 获取活跃敌人数 / Get active enemy count
func get_active_enemy_count() -> int:
	"""获取当前活跃敌人数 / Get current active enemy count"""
	return active_enemies.size()


## 清除所有敌人 / Clear all enemies
func clear_all_enemies() -> void:
	"""清除所有敌人 / Clear all enemies"""
	for enemy in active_enemies:
		if enemy and not enemy.is_queued_for_deletion():
			enemy.queue_free()

	active_enemies.clear()
	active_attack_count = 0
