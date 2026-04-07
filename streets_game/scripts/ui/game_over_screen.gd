extends Control
## 游戏结束屏幕脚本
## Game over screen script
##
## 显示游戏结束界面，最终分数和继续/返回菜单选项

# 信号 / Signals
signal continue_pressed
signal quit_pressed

# 常量 / Constants
const CONTINUE_TIMEOUT: float = 10.0
const BLINK_SPEED: float = 0.3

# 变量 / Variables
var final_score: int = 0
var current_level: String = "level_01"
var countdown_timer: float = CONTINUE_TIMEOUT
var show_continue_text: bool = true
var blink_timer: float = 0.0
var fade_in_complete: bool = false
var allow_input: bool = false

# 节点 / Nodes
@onready var root_control = Control.new()
@onready var transition_rect = ColorRect.new()


func _ready() -> void:
	## 初始化游戏结束屏幕
	## Initialize game over screen

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
		allow_input = true
	)

	# 获取当前分数 / Get current score
	var game_manager = get_tree().root.get_node_or_null("GameManager")
	if game_manager and game_manager.has_method("get_score"):
		final_score = game_manager.get_score()

	# 连接绘制 / Connect draw
	root_control.draw.connect(Callable(self, "_draw_game_over_screen"))
	root_control.queue_redraw()


func _process(delta: float) -> void:
	## 处理倒计时和输入
	## Handle countdown and input

	if not fade_in_complete:
		return

	# 更新倒计时 / Update countdown
	if countdown_timer > 0:
		countdown_timer -= delta
		if countdown_timer <= 0:
			countdown_timer = 0
			_on_timeout_continue()

	# 更新闪烁 / Update blinking
	blink_timer += delta
	if blink_timer >= BLINK_SPEED:
		blink_timer = 0.0
		show_continue_text = not show_continue_text
		root_control.queue_redraw()

	# 处理输入 / Handle input
	if allow_input:
		if Input.is_action_just_pressed("ui_accept"):
			_on_continue()
		elif Input.is_action_just_pressed("ui_cancel"):
			_on_quit()


func _draw_game_over_screen() -> void:
	## 绘制游戏结束屏幕
	## Draw game over screen

	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2

	# 背景 / Background
	root_control.draw_rect(
		Rect2(Vector2.ZERO, viewport_size),
		Color(0, 0, 0, 0.8)
	)

	# 绘制背景效果 / Draw background effect
	_draw_background_effect(viewport_size, center)

	# 绘制"游戏结束"文本 / Draw "GAME OVER" text
	_draw_game_over_text(center)

	# 绘制分数 / Draw score
	_draw_score_display(center)

	# 绘制继续选项 / Draw continue option
	_draw_continue_option(center)

	# 绘制倒计时 / Draw countdown
	_draw_countdown(center)


func _draw_background_effect(viewport_size: Vector2, center: Vector2) -> void:
	## 绘制背景视觉效果
	## Draw background visual effects

	# 绘制闪烁条纹 / Draw flashing stripes
	var stripe_height = 20
	var stripe_color = Color(0.8, 0, 0, 0.2)

	for i in range(0, int(viewport_size.y), stripe_height * 2):
		root_control.draw_rect(
			Rect2(0, i, viewport_size.x, stripe_height),
			stripe_color
		)

	# 绘制中心圆形背景 / Draw center circle background
	var circle_color = Color(0.2, 0, 0, 0.3)
	for radius in range(200, 0, 20):
		root_control.draw_circle(center, float(radius), circle_color)


func _draw_game_over_text(center: Vector2) -> void:
	## 绘制"游戏结束"大字
	## Draw "GAME OVER" large text

	var font = ThemeDB.fallback_font
	var game_over_color = Color.RED
	var game_over_size = 120

	root_control.draw_string(
		font,
		center + Vector2(0, -200),
		"GAME OVER",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		game_over_size,
		game_over_color
	)


func _draw_score_display(center: Vector2) -> void:
	## 绘制最终分数
	## Draw final score

	var font = ThemeDB.fallback_font

	# 分数标签 / Score label
	root_control.draw_string(
		font,
		center + Vector2(0, -50),
		"FINAL SCORE",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		32,
		Color.YELLOW
	)

	# 分数数值 / Score value
	root_control.draw_string(
		font,
		center + Vector2(0, 20),
		"%d" % final_score,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		72,
		Color.WHITE
	)

	# 分数等级 / Score rank
	var rank = _calculate_rank(final_score)
	var rank_color = _get_rank_color(rank)

	root_control.draw_string(
		font,
		center + Vector2(0, 110),
		"RANK: %s" % rank,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		40,
		rank_color
	)


func _draw_continue_option(center: Vector2) -> void:
	## 绘制继续选项
	## Draw continue option

	var font = ThemeDB.fallback_font

	if show_continue_text:
		var continue_color = Color.GREEN if countdown_timer > 3 else Color.YELLOW if countdown_timer > 1 else Color.RED

		root_control.draw_string(
			font,
			center + Vector2(0, 200),
			"按任意键继续 / PRESS ANY KEY TO CONTINUE",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			24,
			continue_color
		)


func _draw_countdown(center: Vector2) -> void:
	## 绘制倒计时数字
	## Draw countdown number

	var font = ThemeDB.fallback_font
	var countdown_int = int(countdown_timer) + 1
	var countdown_color = Color.RED if countdown_int <= 3 else Color.YELLOW

	root_control.draw_string(
		font,
		center + Vector2(250, 200),
		"(%d)" % countdown_int,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		32,
		countdown_color
	)


func _calculate_rank(score: int) -> String:
	## 根据分数计算等级
	## Calculate rank based on score

	if score >= 5000:
		return "S"
	elif score >= 3000:
		return "A"
	elif score >= 1500:
		return "B"
	else:
		return "C"


func _get_rank_color(rank: String) -> Color:
	## 根据等级返回颜色
	## Get color based on rank

	match rank:
		"S":
			return Color.RED
		"A":
			return Color.YELLOW
		"B":
			return Color.CYAN
		"C":
			return Color(0.8, 0.8, 0.8)
		_:
			return Color.WHITE


func _on_continue() -> void:
	## 继续游戏（重启关卡）
	## Continue game (restart level)

	allow_input = false
	continue_pressed.emit()

	# 淡出并重启关卡 / Fade out and restart level
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func() -> void:
		# 重新加载当前关卡 / Reload current level
		var current_scene = get_tree().current_scene
		if current_scene:
			var scene_path = current_scene.scene_file_path
			if scene_path:
				get_tree().reload_current_scene()
			else:
				# 加载默认关卡 / Load default level
				get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")
	)


func _on_quit() -> void:
	## 返回标题屏幕
	## Return to title screen

	allow_input = false
	quit_pressed.emit()

	# 淡出并返回标题 / Fade out and return to title
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
	)


func _on_timeout_continue() -> void:
	## 超时自动继续
	## Auto continue on timeout

	_on_continue()


func set_final_score(score: int) -> void:
	## 设置最终分数
	## Set final score

	final_score = score
	root_control.queue_redraw()


func set_current_level(level: String) -> void:
	## 设置当前关卡名称
	## Set current level name

	current_level = level


func reset_countdown() -> void:
	## 重置倒计时
	## Reset countdown

	countdown_timer = CONTINUE_TIMEOUT
