extends Area2D
## 战斗区域 - 敌人生成和摄像机锁定 | Combat Zone - Enemy spawning and camera locking

class_name CombatZone

# 要生成的敌人场景 | Enemy scenes to spawn
@export var enemy_scenes: Array[PackedScene] = []
# 敌人生成延迟 | Delay between enemy spawns (seconds)
@export var spawn_delay: float = 0.5
# 锁定区域宽度 | Width of locked zone
@export var zone_width: float = 640.0
# 是否只触发一次 | Only trigger once
@export var one_time_trigger: bool = true

# 内部状态 | Internal state
var activated: bool = false
var enemies_alive: int = 0
var _spawn_timer: float = 0.0
var _spawn_index: int = 0
var _player: Node2D = null
var _camera_controller: CameraController = null

signal zone_cleared
signal zone_activated
signal enemy_spawned(enemy: Node2D)


func _ready() -> void:
	# 连接到Area2D信号 | Connect to Area2D signals
	body_entered.connect(_on_body_entered)

	# 查找玩家和摄像机控制器 | Find player and camera controller
	_player = get_tree().get_first_node_in_group("player")
	_camera_controller = get_tree().get_first_node_in_group("camera")

	if not _camera_controller:
		push_error("CombatZone: CameraController not found in 'camera' group!")


func _process(delta: float) -> void:
	# 处理敌人生成延迟 | Handle enemy spawn delay
	if activated and _spawn_index < enemy_scenes.size():
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_enemy()
			_spawn_timer = spawn_delay


## 处理玩家进入区域 | Handle player entering zone
func _on_body_entered(body: Node2D) -> void:
	# 检查是否是玩家 | Check if it's the player
	if not body.is_in_group("player"):
		return

	# 如果已激活且只触发一次，则返回 | Return if already activated and one_time_trigger
	if activated and one_time_trigger:
		return

	# 激活区域 | Activate zone
	activate()


## 激活战斗区域 | Activate combat zone
func activate() -> void:
	if activated:
		return

	activated = true
	zone_activated.emit()

	# 锁定摄像机到此区域 | Lock camera to this zone
	if _camera_controller:
		var zone_left = global_position.x - zone_width / 2.0
		var zone_right = global_position.x + zone_width / 2.0
		_camera_controller.lock_to_zone(zone_left, zone_right)

	# 开始生成敌人 | Start spawning enemies
	_spawn_index = 0
	_spawn_timer = spawn_delay


## 生成单个敌人 | Spawn a single enemy
func _spawn_enemy() -> void:
	if _spawn_index >= enemy_scenes.size():
		return

	var enemy_scene = enemy_scenes[_spawn_index]
	if not enemy_scene:
		push_error("CombatZone: Enemy scene at index %d is null!" % _spawn_index)
		_spawn_index += 1
		return

	var enemy = enemy_scene.instantiate() as Node2D
	if not enemy:
		push_error("CombatZone: Failed to instantiate enemy at index %d" % _spawn_index)
		_spawn_index += 1
		return

	# 随机生成位置（在区域内） | Random spawn position within zone
	var spawn_x = global_position.x + randf_range(-zone_width / 4.0, zone_width / 4.0)
	var spawn_y = global_position.y + randf_range(-50.0, 50.0)
	enemy.global_position = Vector2(spawn_x, spawn_y)

	# 添加到场景树 | Add to scene tree
	get_parent().add_child(enemy)

	# 如果敌人有died信号，连接它 | Connect death signal if exists
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

	enemies_alive += 1
	_spawn_index += 1
	enemy_spawned.emit(enemy)


## 处理敌人死亡 | Handle enemy death
func _on_enemy_died() -> void:
	enemies_alive -= 1

	# 检查是否所有敌人都已死亡 | Check if all enemies are dead
	if enemies_alive <= 0 and _spawn_index >= enemy_scenes.size():
		zone_clear()


## 清除区域 | Clear zone
func zone_clear() -> void:
	# 解锁摄像机 | Unlock camera
	if _camera_controller:
		_camera_controller.unlock_zone()

	zone_cleared.emit()

	# 禁用Area2D，防止重新触发 | Disable Area2D to prevent re-trigger
	if one_time_trigger:
		area_entered.disconnect(_on_body_entered)
		monitorable = false


## 检查区域是否已完成 | Check if zone is complete
func is_complete() -> bool:
	return enemies_alive <= 0 and _spawn_index >= enemy_scenes.size()


## 获取剩余敌人数 | Get remaining enemy count
func get_remaining_enemies() -> int:
	return enemies_alive + (enemy_scenes.size() - _spawn_index)
