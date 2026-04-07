extends Label
## 浮动伤害数字脚本
## Floating damage number script
##
## 在敌人被击中时生成，显示伤害数量，向上浮动同时淡出

class_name DamageNumber

# 常量 / Constants
const FLOAT_SPEED: float = 100.0  # 像素/秒 / pixels per second
const FLOAT_DURATION: float = 1.0  # 显示持续时间 / Display duration
const FLOAT_DISTANCE: float = 80.0  # 向上浮动距离 / Float distance upward

# 枚举 / Enums
enum DamageType {
	NORMAL,
	COMBO_FINISHER,
	CRITICAL,
	HEAL,
}

# 变量 / Variables
var damage_type: DamageType = DamageType.NORMAL
var start_position: Vector2 = Vector2.ZERO
var elapsed_time: float = 0.0
var tween: Tween = null


func _ready() -> void:
	## 初始化伤害数字
	## Initialize damage number

	# 设置标签样式 / Set label style
	add_theme_font_size_override("font_size", 32)
	add_theme_color_override("font_color", _get_color_for_type())

	# 添加描边效果 / Add outline effect
	add_theme_color_override("font_outline_color", Color.BLACK)

	start_position = global_position

	# 启动动画 / Start animation
	_start_animation()


func _process(delta: float) -> void:
	## 更新伤害数字位置和不透明度
	## Update damage number position and opacity

	elapsed_time += delta

	if elapsed_time >= FLOAT_DURATION:
		# 动画完成，删除此节点 / Animation complete, remove this node
		queue_free()
		return

	# 计算进度 / Calculate progress
	var progress = elapsed_time / FLOAT_DURATION

	# 计算上浮高度 / Calculate float height
	var float_offset = FLOAT_DISTANCE * progress

	# 更新位置 / Update position
	global_position = start_position - Vector2(0, float_offset)

	# 计算淡出透明度 / Calculate fade alpha
	var alpha = 1.0 - progress
	modulate.a = alpha


func set_damage(amount: int, damage_type_param: DamageType = DamageType.NORMAL) -> void:
	## 设置伤害数值和类型
	## Set damage value and type

	damage_type = damage_type_param

	# 格式化文本 / Format text
	match damage_type:
		DamageType.NORMAL:
			text = str(amount)
		DamageType.COMBO_FINISHER:
			text = "%d!!" % amount
		DamageType.CRITICAL:
			text = "CRIT! %d" % amount
		DamageType.HEAL:
			text = "+%d" % amount

	# 更新颜色 / Update color
	add_theme_color_override("font_color", _get_color_for_type())


func _get_color_for_type() -> Color:
	## 根据伤害类型返回颜色
	## Return color based on damage type

	match damage_type:
		DamageType.NORMAL:
			return Color.WHITE
		DamageType.COMBO_FINISHER:
			return Color.YELLOW
		DamageType.CRITICAL:
			return Color.RED
		DamageType.HEAL:
			return Color.GREEN
		_:
			return Color.WHITE


func _start_animation() -> void:
	## 启动数字浮起和淡出动画
	## Start number float and fade animation

	# 如果有旧的 tween，杀死它 / Kill old tween if exists
	if tween:
		tween.kill()

	# 创建新的 tween / Create new tween
	tween = create_tween()
	tween.set_parallel(true)  # 并行运行动画 / Run animations in parallel
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	# 动画位置 / Animate position
	tween.tween_property(
		self,
		"global_position",
		start_position - Vector2(0, FLOAT_DISTANCE),
		FLOAT_DURATION
	)

	# 淡出 / Fade out
	tween.tween_property(self, "modulate:a", 0.0, FLOAT_DURATION)

	# 完成后删除 / Remove when complete
	tween.tween_callback(func() -> void:
		queue_free()
	)


# 工厂方法 / Factory Methods

static func create_at_position(
	position: Vector2,
	damage: int,
	type: DamageType = DamageType.NORMAL,
	parent: Node = null
) -> DamageNumber:
	## 在指定位置创建伤害数字
	## Create damage number at specified position

	var damage_number = DamageNumber.new()

	# 将节点添加到父节点 / Add to parent node
	if parent:
		parent.add_child(damage_number)
	else:
		# 添加到场景根 / Add to scene root
		get_tree().get_root().add_child(damage_number)

	# 设置位置 / Set position
	damage_number.global_position = position

	# 设置伤害值 / Set damage value
	damage_number.set_damage(damage, type)

	return damage_number


# 辅助方法 / Helper Methods

func set_float_speed(speed: float) -> void:
	## 设置浮动速度
	## Set float speed
	# 注：当前实现不使用速度，而是使用时间
	# Note: Current implementation uses duration, not speed
	pass


func set_float_duration(duration: float) -> void:
	## 设置浮动持续时间
	## Set float duration
	FLOAT_DURATION = duration


func set_float_distance(distance: float) -> void:
	## 设置浮动距离
	## Set float distance
	FLOAT_DISTANCE = distance
