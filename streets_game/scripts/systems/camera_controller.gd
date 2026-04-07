extends Camera2D
## 摄像机控制器 - 跟随玩家并处理屏幕锁定
## Camera Controller - Follows player and handles screen locking

class_name CameraController

# 跟随目标 | Follow target
@export var follow_target: Node2D
# 跟随平滑度 | Smoothing factor (0-1, higher = faster)
@export var smoothing: float = 0.15
# Y轴可走动范围 | Walkable Y band
@export var walkable_y_min: float = 280.0
@export var walkable_y_max: float = 450.0
# 屏幕震动强度 | Screen shake amplitude
@export var shake_amplitude: float = 10.0
# 屏幕震动衰减 | Screen shake decay per frame
@export var shake_decay: float = 0.9

# 内部状态 | Internal state
var _target_position: Vector2 = Vector2.ZERO
var _zone_locked: bool = false
var _zone_left_bound: float = 0.0
var _zone_right_bound: float = 0.0
var _current_shake: float = 0.0
var _shake_timer: float = 0.0

signal zone_entered
signal zone_exited


func _ready() -> void:
	if not follow_target:
		push_error("CameraController: No follow_target assigned!")
		return

	# 连接到游戏管理器屏幕震动信号 | Connect to GameManager screen shake signal
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		if game_manager.has_signal("screen_shake_requested"):
			game_manager.screen_shake_requested.connect(_on_screen_shake_requested)

	_target_position = follow_target.global_position
	global_position = _target_position
	make_current()


func _process(delta: float) -> void:
	if not follow_target:
		return

	# 更新目标位置 | Update target position
	var target_pos = follow_target.global_position

	# 如果区域已锁定，限制X坐标 | If zone locked, clamp X position
	if _zone_locked:
		target_pos.x = clamp(target_pos.x, _zone_left_bound, _zone_right_bound)

	# 限制Y到可走动范围 | Clamp Y to walkable band
	target_pos.y = clamp(target_pos.y, walkable_y_min, walkable_y_max)

	# 平滑跟随 | Smooth follow
	_target_position = _target_position.lerp(target_pos, smoothing)
	global_position = _target_position

	# 更新屏幕震动 | Update screen shake
	if _current_shake > 0.1:
		var shake_offset = Vector2(
			randf_range(-_current_shake, _current_shake),
			randf_range(-_current_shake, _current_shake)
		)
		global_position += shake_offset
		_current_shake *= shake_decay
	else:
		_current_shake = 0.0


## 锁定摄像机到指定区域 | Lock camera to specified zone bounds
func lock_to_zone(left_bound: float, right_bound: float) -> void:
	_zone_locked = true
	_zone_left_bound = left_bound
	_zone_right_bound = right_bound
	zone_entered.emit()


## 解锁摄像机区域限制 | Unlock zone boundaries
func unlock_zone() -> void:
	_zone_locked = false
	zone_exited.emit()
	show_go_arrow()


## 显示"GO!"提示 | Display "GO!" prompt when zone cleared
func show_go_arrow() -> void:
	# 创建"GO!"标签 | Create "GO!" label
	var label = Label.new()
	label.text = "GO!"
	label.add_theme_font_size_override("font_size", 72)
	label.position = global_position - Vector2(144, -100)
	label.z_index = 100
	get_parent().add_child(label)

	# 动画：缩放并淡出 | Animate: scale and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(2.0, 2.0), 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


## 请求屏幕震动 | Request screen shake
func screen_shake(strength: float = 1.0) -> void:
	_current_shake = shake_amplitude * strength


## 屏幕震动信号处理 | Screen shake signal handler
func _on_screen_shake_requested(strength: float = 1.0) -> void:
	screen_shake(strength)
