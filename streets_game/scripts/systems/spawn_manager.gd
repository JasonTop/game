## Enemy spawn and attack slot manager
## 敌人生成和攻击槽管理器
##
## This system manages enemy spawning, tracks active enemies, and controls
## how many enemies can attack simultaneously. This prevents the player from
## being overwhelmed by too many simultaneous attacks.
##
## 此系统管理敌人生成，追踪活跃敌人，并控制
## 有多少敌人可以同时攻击。这防止玩家
## 被太多同时攻击所淹没。
extends Node
## NOTE: class_name removed to avoid conflict with scripts/managers/spawn_manager.gd (autoloaded version)
## 注意: 移除class_name以避免与autoload版本冲突

## Maximum number of enemies allowed in the scene at once
## 场景中一次允许的最大敌人数
@export var max_active_enemies: int = 5

## Maximum number of enemies that can attack simultaneously
## 可以同时攻击的最大敌人数
@export var max_simultaneous_attackers: int = 2

## Dictionary of active enemies tracked by their node path
## 通过节点路径追踪的活跃敌人字典
var _active_enemies: Dictionary = {}

## Array of enemies currently attacking
## 当前攻击的敌人数组
var _attacking_enemies: Array[Node] = []

## Signal emitted when all enemies in the scene are defeated
## 当场景中所有敌人都被击败时发出的信号
signal all_enemies_defeated

## Signal emitted when an enemy is registered
## 当注册敌人时发出的信号
signal enemy_registered(enemy: Node)

## Signal emitted when an enemy is unregistered
## 当注销敌人时发出的信号
signal enemy_unregistered(enemy: Node)

## Signal emitted when attack slot status changes
## 当攻击槽状态变化时发出的信号
signal attack_slot_changed(available_slots: int, max_slots: int)


## Register a newly spawned enemy with the spawn manager
## 向生成管理器注册新生成的敌人
##
## Call this when a new enemy enters the scene.
## 当新敌人进入场景时调用此方法。
##
## @param enemy - The enemy node to register
## @returns true if registration was successful
func register_enemy(enemy: Node) -> bool:
	# Check if we've reached max enemy limit
	# 检查我们是否已达到最大敌人限制
	if _active_enemies.size() >= max_active_enemies:
		if OS.is_debug_build():
			print("SpawnManager: Max enemies reached, cannot register %s" % enemy.name)
		return false

	# Check if already registered
	# 检查是否已注册
	if enemy in _active_enemies:
		return true

	# Register the enemy
	# 注册敌人
	_active_enemies[enemy] = true

	# Connect to death signal if available
	# 如果可用，连接到死亡信号
	if enemy.is_connected("death", Callable(self, "_on_enemy_died")):
		# Already connected
		pass
	elif enemy.has_signal("death"):
		enemy.death.connect(Callable(self, "_on_enemy_died").bind(enemy))

	# Connect to attack state change if available
	# 如果可用，连接到攻击状态变化
	if enemy.has_signal("attack_started"):
		enemy.attack_started.connect(Callable(self, "_on_enemy_attack_started").bind(enemy))

	if enemy.has_signal("attack_ended"):
		enemy.attack_ended.connect(Callable(self, "_on_enemy_attack_ended").bind(enemy))

	enemy_registered.emit(enemy)

	if OS.is_debug_build():
		print("SpawnManager: Enemy registered (%d/%d)" % [_active_enemies.size(), max_active_enemies])

	return true


## Unregister a defeated or removed enemy
## 注销被击败或移除的敌人
##
## Call this when an enemy leaves the scene or is defeated.
## 当敌人离开场景或被击败时调用此方法。
##
## @param enemy - The enemy node to unregister
func unregister_enemy(enemy: Node) -> void:
	if enemy not in _active_enemies:
		return

	# Remove from active enemies
	# 从活跃敌人中移除
	_active_enemies.erase(enemy)

	# Remove from attacking enemies if present
	# 如果存在，从攻击敌人中移除
	if enemy in _attacking_enemies:
		_attacking_enemies.erase(enemy)
		attack_slot_changed.emit(
			max_simultaneous_attackers - _attacking_enemies.size(),
			max_simultaneous_attackers
		)

	# Disconnect signals
	# 断开信号
	if enemy.has_signal("death"):
		enemy.death.disconnect(Callable(self, "_on_enemy_died"))
	if enemy.has_signal("attack_started"):
		enemy.attack_started.disconnect(Callable(self, "_on_enemy_attack_started"))
	if enemy.has_signal("attack_ended"):
		enemy.attack_ended.disconnect(Callable(self, "_on_enemy_attack_ended"))

	enemy_unregistered.emit(enemy)

	if OS.is_debug_build():
		print("SpawnManager: Enemy unregistered (%d remaining)" % _active_enemies.size())

	# Check if all enemies are defeated
	# 检查所有敌人是否都被击败
	if _active_enemies.is_empty():
		all_enemies_defeated.emit()


## Request an attack slot for an enemy
## 为敌人请求攻击槽
##
## Enemies should call this before starting an attack animation.
## If this returns false, the enemy should wait before attacking.
##
## @param enemy - The enemy requesting the attack slot
## @returns true if the slot was granted, false if slots are full
func request_attack_slot(enemy: Node) -> bool:
	# Check if enemy is already attacking
	# 检查敌人是否已经在攻击
	if enemy in _attacking_enemies:
		return true

	# Check if we have available slots
	# 检查我们是否有可用的槽
	if _attacking_enemies.size() >= max_simultaneous_attackers:
		if OS.is_debug_build():
			print("SpawnManager: Attack slots full (%d/%d)" % [_attacking_enemies.size(), max_simultaneous_attackers])
		return false

	# Grant the attack slot
	# 批准攻击槽
	_attacking_enemies.append(enemy)

	attack_slot_changed.emit(
		max_simultaneous_attackers - _attacking_enemies.size(),
		max_simultaneous_attackers
	)

	if OS.is_debug_build():
		print("SpawnManager: Attack slot granted to %s (%d/%d)" % [enemy.name, _attacking_enemies.size(), max_simultaneous_attackers])

	return true


## Release an attack slot from an enemy
## 从敌人释放攻击槽
##
## Enemies should call this when their attack animation completes.
##
## @param enemy - The enemy releasing the attack slot
func release_attack_slot(enemy: Node) -> void:
	if enemy not in _attacking_enemies:
		return

	_attacking_enemies.erase(enemy)

	attack_slot_changed.emit(
		max_simultaneous_attackers - _attacking_enemies.size(),
		max_simultaneous_attackers
	)

	if OS.is_debug_build():
		print("SpawnManager: Attack slot released (%d/%d available)" % [max_simultaneous_attackers - _attacking_enemies.size(), max_simultaneous_attackers])


## Check how many attack slots are currently available
## 检查当前有多少攻击槽可用
##
## @returns The number of available attack slots
func get_available_attack_slots() -> int:
	return max_simultaneous_attackers - _attacking_enemies.size()


## Check if an enemy is currently attacking
## 检查敌人当前是否在攻击
##
## @param enemy - The enemy to check
## @returns true if the enemy is in the attacking list
func is_enemy_attacking(enemy: Node) -> bool:
	return enemy in _attacking_enemies


## Get the count of currently active enemies
## 获取当前活跃敌人的计数
##
## @returns The number of registered active enemies
func get_active_enemy_count() -> int:
	return _active_enemies.size()


## Internal signal handler for enemy death
## 敌人死亡的内部信号处理程序
func _on_enemy_died(enemy: Node) -> void:
	unregister_enemy(enemy)


## Internal signal handler for attack start
## 攻击开始的内部信号处理程序
func _on_enemy_attack_started(enemy: Node) -> void:
	request_attack_slot(enemy)


## Internal signal handler for attack end
## 攻击结束的内部信号处理程序
func _on_enemy_attack_ended(enemy: Node) -> void:
	release_attack_slot(enemy)


## Get spawn manager statistics
## 获取生成管理器统计信息
##
## @returns A dictionary with spawn manager status
func get_stats() -> Dictionary:
	return {
		"active_enemies": _active_enemies.size(),
		"max_enemies": max_active_enemies,
		"attacking_enemies": _attacking_enemies.size(),
		"max_attackers": max_simultaneous_attackers,
		"available_slots": get_available_attack_slots()
	}
