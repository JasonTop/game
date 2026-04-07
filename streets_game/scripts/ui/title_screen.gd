extends Control
## 标题屏幕脚本
## Title screen script
##
## 游戏开始界面，显示标题、菜单和开始提示

# 信号 / Signals
signal game_started

# 常量 / Constants
const GAME_TITLE: String = "STREETS OF FURY"
const BLINK_SPEED: float = 0.5
const MENU_ITEM_SPACING: int = 60

# 变量 / Variables
var selected_menu_item: int = 0  # 0: Start, 1: Options, 2: Quit
var press_start_visible: bool = true
var blink_timer: float = 0.0
var menu_active: bool = false
var fade_in_complete: bool = false

var menu_items: PackedStringArray = ["START GAME", "OPTIONS", "QUIT"]

# 节点 / Nodes
@onready var root_control = Control.new()
@onready var transition_rect = ColorRect.new()


func _ready() -> void:
	## 初始化标题屏幕
	## Initialize title screen

	# 创建淡入效果 / Create fade in effect
	add_child(root_control)
	root_control.anchor_left = 0.0
	root_control.anchor_top = 0.0
	root_control.anchor_right = 1.0
	root_control.anchor_bottom = 1.0

	# 添加背景色 / Add background color
	root_control.modulate = Color(0, 0, 0, 1)

	# 添加淡入动画 / Add fade in animation
	add_child(transition_rect)
	transition_rect.color = Color.BLACK
	transition_rect.anchor_left = 0.0
	transition_rect.anchor_top = 0.0
	transition_rect.anchor_right = 1.0
	transition_rect.anchor_bottom = 1.0

	# 淡入 / Fade in
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		transition_rect.queue_free()
		fade_in_complete = true
	)

	# 连接绘制信号 / Connect draw signal
	root_control.draw.connect(Callable(self, "_draw_title_screen"))
	root_control.queue_redraw()

	# 设置焦点 / Set focus
	grab_focus()


func _process(delta: float) -> void:
	## 处理输入和动画更新
	## Handle input and animation updates

	if not fade_in_complete:
		return

	# 更新闪烁计时器 / Update blink timer
	blink_timer += delta
	if blink_timer >= BLINK_SPEED:
		blink_timer = 0.0
		press_start_visible = not press_start_visible
		root_control.queue_redraw()

	# 处理菜单选择 / Handle menu selection
	if menu_active:
		_handle_menu_input()
	else:
		_handle_start_input()


func _handle_start_input() -> void:
	## 处理按下开始时的输入
	## Handle input for press start screen

	if Input.is_action_just_pressed("ui_accept"):
		menu_active = true
		selected_menu_item = 0
		root_control.queue_redraw()
		_play_menu_sound()


func _handle_menu_input() -> void:
	## 处理菜单导航输入
	## Handle menu navigation input

	if Input.is_action_just_pressed("ui_up"):
		selected_menu_item = (selected_menu_item - 1) % menu_items.size()
		root_control.queue_redraw()
		_play_menu_sound()

	elif Input.is_action_just_pressed("ui_down"):
		selected_menu_item = (selected_menu_item + 1) % menu_items.size()
		root_control.queue_redraw()
		_play_menu_sound()

	elif Input.is_action_just_pressed("ui_accept"):
		_select_menu_item()


func _select_menu_item() -> void:
	## 处理菜单项选择
	## Handle menu item selection

	match selected_menu_item:
		0:  # 开始游戏 / Start Game
			_start_game()
		1:  # 选项 / Options
			_show_options()
		2:  # 退出 / Quit
			get_tree().quit()


func _start_game() -> void:
	## 开始游戏，加载第一关
	## Start game, load first level

	# 淡出并加载场景 / Fade out and load scene
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, 0.5)
	tween.tween_callback(func() -> void:
		game_started.emit()
		# 等待加载场景 / Wait for scene to load
		await get_tree().create_timer(0.2).timeout
		# 尝试加载第一关，如果不存在则使用占位符 / Try to load level 1, use placeholder if missing
		var level_path = "res://scenes/levels/level_01.tscn"
		if ResourceLoader.exists(level_path):
			get_tree().change_scene_to_file(level_path)
		else:
			# 创建一个测试场景 / Create a test scene
			print("警告：level_01.tscn 不存在。创建测试场景。 / Warning: level_01.tscn not found. Creating test scene.")
			var test_scene = Node2D.new()
			test_scene.name = "TestLevel"
			get_tree().root.add_child(test_scene)
			get_tree().root.remove_child(self)
	)


func _show_options() -> void:
	## 显示选项菜单（占位符）
	## Show options menu (placeholder)

	# 简单地打印消息 / Just print message
	print("选项菜单尚未实现 / Options menu not yet implemented")
	# 重置菜单 / Reset menu
	menu_active = false
	root_control.queue_redraw()


func _play_menu_sound() -> void:
	## 播放菜单选择音效（占位符）
	## Play menu selection sound (placeholder)

	# 可以在这里添加音效播放 / Add sound effect here
	pass


func _draw_title_screen() -> void:
	## 绘制标题屏幕所有元素
	## Draw all title screen elements

	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2

	# 背景 / Background (gradient effect simulated with multiple rectangles)
	root_control.draw_rect(
		Rect2(Vector2.ZERO, viewport_size),
		Color(0.1, 0.1, 0.2)
	)

	# 绘制背景花纹 / Draw background pattern
	_draw_background_pattern(viewport_size)

	# 绘制标题 / Draw title
	_draw_title(center)

	# 绘制菜单 / Draw menu
	if menu_active:
		_draw_menu(center)
	else:
		_draw_press_start(center)

	# 绘制底部信息 / Draw bottom info
	_draw_footer(viewport_size)


func _draw_background_pattern(viewport_size: Vector2) -> void:
	## 绘制背景装饰图案
	## Draw background decoration pattern

	# 简单的对角线花纹 / Simple diagonal pattern
	var line_spacing = 40
	var line_color = Color(0.3, 0.3, 0.4, 0.3)

	for i in range(0, int(viewport_size.x + viewport_size.y), line_spacing):
		root_control.draw_line(
			Vector2(i, 0),
			Vector2(i - viewport_size.y, viewport_size.y),
			line_color,
			1.0
		)


func _draw_title(center: Vector2) -> void:
	## 绘制游戏标题
	## Draw game title

	var font = ThemeDB.fallback_font
	var title_color = Color.RED
	var title_size = 80

	# 主标题 / Main title
	root_control.draw_string(
		font,
		center + Vector2(0, -200),
		GAME_TITLE,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		title_size,
		title_color
	)

	# 副标题 / Subtitle
	var subtitle_color = Color.YELLOW
	root_control.draw_string(
		font,
		center + Vector2(0, -100),
		"BEAT 'EM UP ACTION",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		24,
		subtitle_color
	)


func _draw_press_start(center: Vector2) -> void:
	## 绘制"按开始"文本（带闪烁效果）
	## Draw "Press Start" text (with blinking effect)

	var font = ThemeDB.fallback_font

	if press_start_visible:
		var text_color = Color.WHITE
		root_control.draw_string(
			font,
			center + Vector2(0, 150),
			"PRESS START",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			48,
			text_color
		)


func _draw_menu(center: Vector2) -> void:
	## 绘制菜单选项
	## Draw menu options

	var font = ThemeDB.fallback_font
	var start_y = center.y + 50

	for i in range(menu_items.size()):
		var menu_text = menu_items[i]
		var menu_y = start_y + (i * MENU_ITEM_SPACING)

		# 选中项颜色 / Selected item color
		var text_color = Color.YELLOW if i == selected_menu_item else Color.WHITE
		var x_offset = 50.0 if i == selected_menu_item else 0.0

		# 绘制选中指示器 / Draw selection indicator
		if i == selected_menu_item:
			var arrow_pos = center + Vector2(-150, menu_y - 25)
			root_control.draw_string(
				font,
				arrow_pos,
				"► ",
				HORIZONTAL_ALIGNMENT_CENTER,
				-1,
				32,
				Color.RED
			)

		# 绘制菜单文本 / Draw menu text
		root_control.draw_string(
			font,
			center + Vector2(x_offset, menu_y),
			menu_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			36,
			text_color
		)


func _draw_footer(viewport_size: Vector2) -> void:
	## 绘制底部信息
	## Draw footer information

	var font = ThemeDB.fallback_font
	var footer_text = "© 2024 Beat 'Em Up Studio"
	var footer_y = viewport_size.y - 40

	root_control.draw_string(
		font,
		Vector2(20, footer_y),
		footer_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.5, 0.5, 0.5)
	)

	# 绘制提示文本 / Draw hint text
	if menu_active:
		var hint_text = "按 ↑↓ 选择，按 ENTER 确认 / Use ↑↓ to select, ENTER to confirm"
		root_control.draw_string(
			font,
			Vector2(viewport_size.x - 20, footer_y),
			hint_text,
			HORIZONTAL_ALIGNMENT_RIGHT,
			-1,
			14,
			Color(0.5, 0.7, 0.5)
		)


func exit_to_menu() -> void:
	## 返回标题屏幕
	## Return to title screen

	menu_active = false
	selected_menu_item = 0
	root_control.queue_redraw()
