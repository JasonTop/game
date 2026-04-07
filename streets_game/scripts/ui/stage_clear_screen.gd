extends Control
## 关卡完成屏幕脚本
## Stage clear screen script
##
## 显示关卡完成画面，分数详解，等级评分

class_name StageClearScreen

# 信号 / Signals
signal next_stage_pressed
signal menu_pressed

# 常量 / Constants
const ANIMATION_SPEED: float = 2.0  # 分数计数速度 / Score counting speed
const MIN_DISPLAY_TIME: float = 2.0  # 最少显示时间 / Minimum display time

# 计分变量 / Score Variables
var combat_score: int = 0
var combo_bonus: int = 0
var time_bonus: int = 0
var health_bonus: int = 0

var displayed_combat: int = 0
var displayed_combo: int = 0
var displayed_time: int = 0
var displayed_health: int = 0

var total_score: int = 0
var displayed_total: int = 0

# 动画状态 / Animation State
var animation_phase: int = 0  # 0:combat, 1:combo, 2:time, 3:health, 4:total, 5:done
var animation_timer: float = 0.0
var input_allowed: bool = false
var fade_in_complete: bool = false

# 节点 / Nodes
@onready var root_control = Control.new()
@onready var transition_rect = ColorRect.new()


func _ready() -> void:
	## 初始化关卡完成屏幕
	## Initialize stage clear screen

	# 创建根控制节点 / Create root control
	add_child(root_control)
	root_control.anchor_left = 0.0
	root_control.anchor_top = 0.0
	root_control.anchor_right = 1.0
	root_control.anchor_bottom = 1.0

	# 添加淡入过渡 / Add fade in transition
	add_child(transition_rect)
	transition_rect.color = Color.BLACK
	transition_rect.anchor_left = 0.0
	transition_rect.anchor_top = 0.0
	transition_rect.anchor_right = 1.0
	transition_rect.anchor_bottom = 1.0

	# 淡入动画 / Fade in animation
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		transition_rect.queue_free()
		fade_in_complete = true
	)

	# 计算总分数 / Calculate total score
	total_score = combat_score + combo_bonus + time_bonus + health_bonus

	# 连接绘制 / Connect draw
	root_control.draw.connect(Callable(self, "_draw_stage_clear"))
	root_control.queue_redraw()


func _process(delta: float) -> void:
	## 处理分数计数动画
	## Handle score counting animation

	if not fade_in_complete:
		return

	# 更新动画 / Update animation
	animation_timer += delta

	var update_needed = false

	match animation_phase:
		0:  # 战斗得分 / Combat score
			if _animate_value(delta, combat_score, displayed_combat):
				update_needed = true
			else:
				animation_phase = 1
				animation_timer = 0.0

		1:  # 连击奖励 / Combo bonus
			if _animate_value(delta, combo_bonus, displayed_combo):
				update_needed = true
			else:
				animation_phase = 2
				animation_timer = 0.0

		2:  # 时间奖励 / Time bonus
			if _animate_value(delta, time_bonus, displayed_time):
				update_needed = true
			else:
				animation_phase = 3
				animation_timer = 0.0

		3:  # 生命值奖励 / Health bonus
			if _animate_value(delta, health_bonus, displayed_health):
				update_needed = true
			else:
				animation_phase = 4
				animation_timer = 0.0

		4:  # 总分 / Total score
			if _animate_value(delta, total_score, displayed_total):
				update_needed = true
			else:
				animation_phase = 5
				animation_timer = 0.0
				input_allowed = true

	if update_needed:
		root_control.queue_redraw()


func _animate_value(delta: float, target: int, current: var) -> bool:
	## 动画显示数值，返回是否完成
	## Animate value display, return if complete

	if current >= target:
		return false

	var increment = int(target * ANIMATION_SPEED * delta)
	if increment == 0:
		increment = 1

	current += increment
	if current > target:
		current = target

	# 更新对应的显示变量 / Update corresponding display variable
	match animation_phase:
		0:
			displayed_combat = current
		1:
			displayed_combo = current
		2:
			displayed_time = current
		3:
			displayed_health = current
		4:
			displayed_total = current

	return current < target


func _input(event: InputEvent) -> void:
	## 处理用户输入
	## Handle user input

	if not fade_in_complete or not input_allowed:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_go_to_menu()
		else:
			_go_to_next_stage()
		get_tree().set_input_as_handled()


func _draw_stage_clear() -> void:
	## 绘制关卡完成屏幕
	## Draw stage clear screen

	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2

	# 背景 / Background
	root_control.draw_rect(
		Rect2(Vector2.ZERO, viewport_size),
		Color(0, 0.2, 0, 0.8)
	)

	# 背景效果 / Background effect
	_draw_background_effect(viewport_size, center)

	# 标题 / Title
	_draw_title(center)

	# 分数详解 / Score breakdown
	_draw_score_breakdown(center)

	# 等级显示 / Rank display
	_draw_grade(center)

	# 提示文本 / Hint text
	if input_allowed:
		_draw_hint_text(center)


func _draw_background_effect(viewport_size: Vector2, center: Vector2) -> void:
	## 绘制背景视觉效果
	## Draw background visual effects

	# 放射状线条 / Radiating lines
	var line_color = Color(0, 0.5, 0, 0.2)
	for angle in range(0, 360, 30):
		var rad = deg_to_rad(angle)
		var end_x = center.x + cos(rad) * 500
		var end_y = center.y + sin(rad) * 500
		root_control.draw_line(
			center,
			Vector2(end_x, end_y),
			line_color,
			2.0
		)

	# 背景圆 / Background circles
	var circle_color = Color(0, 0.3, 0, 0.1)
	for radius in range(100, 500, 50):
		root_control.draw_circle(center, float(radius), circle_color)


func _draw_title(center: Vector2) -> void:
	## 绘制"关卡完成"标题
	## Draw "STAGE CLEAR" title

	var font = ThemeDB.fallback_font
	var title_color = Color.GREEN
	var title_size = 100

	root_control.draw_string(
		font,
		center + Vector2(0, -300),
		"STAGE CLEAR!",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		title_size,
		title_color
	)


func _draw_score_breakdown(center: Vector2) -> void:
	## 绘制分数详解
	## Draw score breakdown

	var font = ThemeDB.fallback_font
	var start_y = center.y - 100
	var line_height = 50
	var label_x = center.x - 200
	var value_x = center.x + 200

	# 战斗得分 / Combat score
	if animation_phase >= 0:
		root_control.draw_string(
			font,
			Vector2(label_x, start_y),
			"战斗分数 / COMBAT:",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color.WHITE
		)
		root_control.draw_string(
			font,
			Vector2(value_x, start_y),
			"%d" % displayed_combat,
			HORIZONTAL_ALIGNMENT_RIGHT,
			-1,
			24,
			Color.YELLOW
		)

	# 连击奖励 / Combo bonus
	if animation_phase >= 1:
		root_control.draw_string(
			font,
			Vector2(label_x, start_y + line_height),
			"连击奖励 / COMBO BONUS:",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color.WHITE
		)
		root_control.draw_string(
			font,
			Vector2(value_x, start_y + line_height),
			"%d" % displayed_combo,
			HORIZONTAL_ALIGNMENT_RIGHT,
			-1,
			24,
			Color.YELLOW
		)

	# 时间奖励 / Time bonus
	if animation_phase >= 2:
		root_control.draw_string(
			font,
			Vector2(label_x, start_y + line_height * 2),
			"时间奖励 / TIME BONUS:",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color.WHITE
		)
		root_control.draw_string(
			font,
			Vector2(value_x, start_y + line_height * 2),
			"%d" % displayed_time,
			HORIZONTAL_ALIGNMENT_RIGHT,
			-1,
			24,
			Color.YELLOW
		)

	# 生命值奖励 / Health bonus
	if animation_phase >= 3:
		root_control.draw_string(
			font,
			Vector2(label_x, start_y + line_height * 3),
			"生命值奖励 / HEALTH BONUS:",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color.WHITE
		)
		root_control.draw_string(
			font,
			Vector2(value_x, start_y + line_height * 3),
			"%d" % displayed_health,
			HORIZONTAL_ALIGNMENT_RIGHT,
			-1,
			24,
			Color.YELLOW
		)

	# 分隔线 / Separator line
	if animation_phase >= 4:
		root_control.draw_line(
			Vector2(label_x - 50, start_y + line_height * 4),
			Vector2(value_x + 50, start_y + line_height * 4),
			Color(0.5, 0.5, 0.5),
			2.0
		)

		# 总分 / Total score
		root_control.draw_string(
			font,
			Vector2(label_x, start_y + line_height * 4 + 20),
			"总分 / TOTAL:",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			28,
			Color.WHITE
		)
		root_control.draw_string(
			font,
			Vector2(value_x, start_y + line_height * 4 + 20),
			"%d" % displayed_total,
			HORIZONTAL_ALIGNMENT_RIGHT,
			-1,
			28,
			Color.LIME
		)


func _draw_grade(center: Vector2) -> void:
	## 绘制评分等级
	## Draw grade rank

	if animation_phase < 5:
		return

	var font = ThemeDB.fallback_font
	var grade = _calculate_grade(displayed_total)
	var grade_color = _get_grade_color(grade)

	root_control.draw_string(
		font,
		center + Vector2(0, 250),
		"RANK: %s" % grade,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		80,
		grade_color
	)


func _draw_hint_text(center: Vector2) -> void:
	## 绘制提示文本
	## Draw hint text

	var font = ThemeDB.fallback_font

	root_control.draw_string(
		font,
		center + Vector2(0, 350),
		"按任意键继续 / PRESS ANY KEY TO CONTINUE",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		20,
		Color(0, 1, 0, 0.7)
	)

	root_control.draw_string(
		font,
		center + Vector2(0, 380),
		"(按 ESC 返回菜单 / Press ESC to return to menu)",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		16,
		Color(0.5, 1, 0.5, 0.5)
	)


func _calculate_grade(score: int) -> String:
	## 根据总分计算等级
	## Calculate grade based on total score

	if score >= 5000:
		return "S"
	elif score >= 3500:
		return "A"
	elif score >= 2000:
		return "B"
	else:
		return "C"


func _get_grade_color(grade: String) -> Color:
	## 根据等级返回颜色
	## Get color based on grade

	match grade:
		"S":
			return Color.YELLOW
		"A":
			return Color(0, 1, 0)  # 绿色 / Green
		"B":
			return Color.CYAN
		"C":
			return Color(1, 1, 1)  # 白色 / White
		_:
			return Color.WHITE


func _go_to_next_stage() -> void:
	## 进入下一关
	## Go to next stage

	next_stage_pressed.emit()

	# 淡出过渡 / Fade out transition
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func() -> void:
		# 尝试加载下一关 / Try to load next stage
		var next_level_path = "res://scenes/levels/level_02.tscn"
		if ResourceLoader.exists(next_level_path):
			get_tree().change_scene_to_file(next_level_path)
		else:
			# 没有下一关，返回菜单 / No next level, return to menu
			get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
	)


func _go_to_menu() -> void:
	## 返回主菜单
	## Return to main menu

	menu_pressed.emit()

	# 淡出过渡 / Fade out transition
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
	)


# 配置方法 / Configuration Methods

func set_scores(combat: int, combo: int, time: int, health: int) -> void:
	## 设置所有分数组成部分
	## Set all score components

	combat_score = combat
	combo_bonus = combo
	time_bonus = time
	health_bonus = health
	total_score = combat + combo + time + health

	root_control.queue_redraw()


func set_combat_score(score: int) -> void:
	## 设置战斗得分
	## Set combat score

	combat_score = score
	_recalculate_total()


func set_combo_bonus(bonus: int) -> void:
	## 设置连击奖励
	## Set combo bonus

	combo_bonus = bonus
	_recalculate_total()


func set_time_bonus(bonus: int) -> void:
	## 设置时间奖励
	## Set time bonus

	time_bonus = bonus
	_recalculate_total()


func set_health_bonus(bonus: int) -> void:
	## 设置生命值奖励
	## Set health bonus

	health_bonus = bonus
	_recalculate_total()


func _recalculate_total() -> void:
	## 重新计算总分
	## Recalculate total

	total_score = combat_score + combo_bonus + time_bonus + health_bonus
