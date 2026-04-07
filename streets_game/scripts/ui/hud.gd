extends CanvasLayer
## HUD 系统 - 游戏中的界面显示
## HUD System - In-game UI display

# 信号 / Signals
signal health_changed(current: int, max_health: int)
signal combo_updated(combo_count: int)

# 节点引用 / Node References
var player: Node2D
var game_manager: Node
var combo_manager: Node

# 健康条数据 / Health Bar Data
var current_health: int = 100
var max_health: int = 100
var recoverable_health: int = 0  # 特殊技能恢复的绿色部分 / Green recoverable section

# 分数和生命 / Score and Lives
var current_score: int = 0
var lives_remaining: int = 3
var star_count: int = 0

# 连击数据 / Combo Data
var current_combo: int = 0
var combo_timer: float = 0.0
var combo_fade_timer: float = 0.0
var show_combo: bool = false

# BOSS 健康条 / Boss Health Bar
var boss_health: int = 0
var max_boss_health: int = 0
var show_boss_bar: bool = false

# GO 箭头 / GO Arrow
var show_go_arrow: bool = false
var go_arrow_blink_timer: float = 0.0

# 样式常量 / Style Constants
const HEALTH_BAR_WIDTH: int = 200
const HEALTH_BAR_HEIGHT: int = 20
const HEALTH_BAR_MARGIN: int = 10

const SCORE_FONT_SIZE: int = 32
const COMBO_FONT_SIZE: int = 64
const COMBO_MAX_SCALE: float = 1.3

const COMBO_DISPLAY_TIME: float = 0.5  # 每次连击显示时间 / Display time per hit
const COMBO_FADE_TIME: float = 1.0  # 淡出时间 / Fade out time
const COMBO_RESET_TIME: float = 3.0  # 连击重置时间 / Combo reset time

# 颜色 / Colors
const COLOR_HEALTH_GOOD: Color = Color.GREEN
const COLOR_HEALTH_WARNING: Color = Color.YELLOW
const COLOR_HEALTH_DANGER: Color = Color.RED
const COLOR_RECOVERABLE: Color = Color(0.5, 1.0, 0.5, 0.6)  # 浅绿色 / Light green
const COLOR_COMBO: Color = Color.WHITE
const COLOR_BOSS_BAR: Color = Color(1.0, 0.2, 0.2)  # 红色 / Red
const COLOR_STAR: Color = Color.YELLOW

# @onready 变量 / @onready Variables
@onready var root_control = Control.new()

func _ready() -> void:
	## 初始化 HUD 系统
	## Initialize HUD system

	# 添加根控制节点 / Add root control node
	add_child(root_control)
	root_control.anchor_left = 0.0
	root_control.anchor_top = 0.0
	root_control.anchor_right = 1.0
	root_control.anchor_bottom = 1.0

	# 获取管理器和玩家引用 / Get manager and player references
	game_manager = get_tree().root.get_node_or_null("GameManager")
	combo_manager = get_tree().root.get_node_or_null("ComboManager")

	# 寻找玩家 / Find player
	player = get_tree().get_first_node_in_group("player")

	# 连接信号 / Connect signals
	if game_manager:
		game_manager.connect("score_changed", Callable(self, "_on_score_changed"))
		game_manager.connect("lives_changed", Callable(self, "_on_lives_changed"))

	if player:
		player.connect("health_changed", Callable(self, "_on_player_health_changed"))

	if combo_manager:
		combo_manager.connect("combo_updated", Callable(self, "_on_combo_updated"))
		combo_manager.connect("combo_ended", Callable(self, "_on_combo_ended"))

	# 设置初始值 / Set initial values
	current_health = max_health

	# 设置自定义绘制 / Setup custom drawing
	root_control.draw.connect(Callable(self, "_draw_hud"))
	root_control.queue_redraw()


func _process(delta: float) -> void:
	## 每帧更新 / Update every frame

	# 更新连击显示 / Update combo display
	if show_combo:
		combo_fade_timer += delta
		if combo_fade_timer >= COMBO_FADE_TIME:
			show_combo = false
			combo_fade_timer = 0.0
			root_control.queue_redraw()

	# 更新连击计时器 / Update combo timer
	if current_combo > 0:
		combo_timer += delta
		if combo_timer >= COMBO_RESET_TIME:
			current_combo = 0
			combo_timer = 0.0
			show_combo = false
			root_control.queue_redraw()

	# 更新 GO 箭头闪烁 / Update GO arrow blinking
	if show_go_arrow:
		go_arrow_blink_timer += delta
		if go_arrow_blink_timer >= 0.5:
			go_arrow_blink_timer = 0.0
		root_control.queue_redraw()


func _draw_hud() -> void:
	## 绘制所有 HUD 元素 / Draw all HUD elements

	var viewport_size = get_viewport_rect().size

	# 绘制生命值条 / Draw health bar
	_draw_health_bar(Vector2(HEALTH_BAR_MARGIN, HEALTH_BAR_MARGIN))

	# 绘制分数 / Draw score
	_draw_score(Vector2(viewport_size.x - 200, HEALTH_BAR_MARGIN))

	# 绘制星星计数 / Draw star count
	_draw_stars(Vector2(HEALTH_BAR_MARGIN, HEALTH_BAR_MARGIN + HEALTH_BAR_HEIGHT + 10))

	# 绘制生命剩余 / Draw lives remaining
	_draw_lives(Vector2(HEALTH_BAR_MARGIN, viewport_size.y - 50))

	# 绘制 BOSS 血条（如果显示） / Draw boss health bar (if visible)
	if show_boss_bar:
		_draw_boss_bar(Vector2(viewport_size.x / 2 - 150, 30))

	# 绘制连击计数器 / Draw combo counter
	if show_combo or current_combo > 0:
		_draw_combo(Vector2(viewport_size.x / 2, viewport_size.y / 2 - 100))

	# 绘制 GO 箭头 / Draw GO arrow
	if show_go_arrow:
		_draw_go_arrow(Vector2(viewport_size.x / 2, viewport_size.y / 2))


func _draw_health_bar(position: Vector2) -> void:
	## 绘制生命值条和恢复部分
	## Draw health bar with recoverable section

	# 计算百分比 / Calculate percentages
	var health_percent = float(current_health) / float(max_health)
	var recoverable_percent = float(recoverable_health) / float(max_health)

	# 背景 / Background
	root_control.draw_rect(
		Rect2(position, Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)),
		Color.BLACK
	)

	# 选择颜色 / Choose color
	var health_color = COLOR_HEALTH_GOOD
	if health_percent < 0.25:
		health_color = COLOR_HEALTH_DANGER
	elif health_percent < 0.5:
		health_color = COLOR_HEALTH_WARNING

	# 主生命条 / Main health bar
	var health_width = HEALTH_BAR_WIDTH * health_percent
	root_control.draw_rect(
		Rect2(position, Vector2(health_width, HEALTH_BAR_HEIGHT)),
		health_color
	)

	# 可恢复部分（绿色叠加）/ Recoverable section (green overlay)
	if recoverable_health > 0:
		var recoverable_width = HEALTH_BAR_WIDTH * recoverable_percent
		var recoverable_start = position.x + health_width
		root_control.draw_rect(
			Rect2(
				Vector2(recoverable_start, position.y),
				Vector2(min(recoverable_width - health_width, HEALTH_BAR_WIDTH - health_width), HEALTH_BAR_HEIGHT)
			),
			COLOR_RECOVERABLE
		)

	# 边框 / Border
	root_control.draw_rect(
		Rect2(position, Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)),
		Color.WHITE,
		false,
		2.0
	)

	# 数值文字 / Health text
	var font = ThemeDB.fallback_font
	var font_size = 16
	var health_text = "%d/%d" % [current_health, max_health]
	root_control.draw_string(
		font,
		position + Vector2(HEALTH_BAR_WIDTH + 10, HEALTH_BAR_HEIGHT),
		health_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.WHITE
	)


func _draw_score(position: Vector2) -> void:
	## 绘制分数显示
	## Draw score display

	var font = ThemeDB.fallback_font
	var score_text = "SCORE\n%d" % current_score

	root_control.draw_string(
		font,
		position,
		score_text,
		HORIZONTAL_ALIGNMENT_RIGHT,
		-1,
		SCORE_FONT_SIZE,
		Color.YELLOW
	)


func _draw_stars(position: Vector2) -> void:
	## 绘制星星计数
	## Draw star count

	var font = ThemeDB.fallback_font
	var star_text = "STARS: %d" % star_count

	root_control.draw_string(
		font,
		position,
		star_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		COLOR_STAR
	)


func _draw_lives(position: Vector2) -> void:
	## 绘制剩余生命
	## Draw lives remaining

	var font = ThemeDB.fallback_font
	var lives_text = "LIVES: %d" % lives_remaining

	root_control.draw_string(
		font,
		position,
		lives_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		24,
		Color.WHITE
	)

	# 绘制小图标 / Draw small icons
	var icon_y = position.y - 30
	for i in range(lives_remaining):
		var icon_x = position.x + i * 30
		root_control.draw_rect(
			Rect2(Vector2(icon_x, icon_y), Vector2(20, 20)),
			Color.RED
		)
		root_control.draw_rect(
			Rect2(Vector2(icon_x, icon_y), Vector2(20, 20)),
			Color.WHITE,
			false,
			1.0
		)


func _draw_boss_bar(position: Vector2) -> void:
	## 绘制 BOSS 血条
	## Draw boss health bar

	var boss_bar_width: int = 300
	var boss_bar_height: int = 30

	var health_percent = float(boss_health) / float(max_boss_health) if max_boss_health > 0 else 0.0

	# 背景 / Background
	root_control.draw_rect(
		Rect2(position, Vector2(boss_bar_width, boss_bar_height)),
		Color.BLACK
	)

	# 血条 / Health bar
	root_control.draw_rect(
		Rect2(position, Vector2(boss_bar_width * health_percent, boss_bar_height)),
		COLOR_BOSS_BAR
	)

	# 边框 / Border
	root_control.draw_rect(
		Rect2(position, Vector2(boss_bar_width, boss_bar_height)),
		Color.WHITE,
		false,
		2.0
	)

	# BOSS 标签 / BOSS label
	var font = ThemeDB.fallback_font
	root_control.draw_string(
		font,
		position + Vector2(-60, boss_bar_height / 2),
		"BOSS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color.RED
	)


func _draw_combo(position: Vector2) -> void:
	## 绘制连击计数器（中心大文字）
	## Draw combo counter (large center text)

	if current_combo <= 0:
		return

	# 计算淡出效果 / Calculate fade effect
	var fade_alpha = 1.0
	if combo_fade_timer > 0:
		fade_alpha = max(0.0, 1.0 - (combo_fade_timer / COMBO_FADE_TIME))

	# 计算缩放效果 / Calculate scale effect
	var scale_amount = 1.0 + (COMBO_MAX_SCALE - 1.0) * (1.0 - (combo_fade_timer / COMBO_FADE_TIME))

	var font = ThemeDB.fallback_font
	var combo_text = "%d HITS!" % current_combo

	# 创建字符串以获取大小 / Create string to get size
	var text_size = font.get_string_size(combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, COMBO_FONT_SIZE)

	# 计算缩放后的位置 / Calculate scaled position
	var scaled_size = text_size * scale_amount
	var draw_pos = position - (scaled_size / 2)

	# 设置颜色并应用淡出 / Set color and apply fade
	var combo_color = COLOR_COMBO
	combo_color.a = fade_alpha

	root_control.draw_string(
		font,
		draw_pos,
		combo_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		int(COMBO_FONT_SIZE * scale_amount),
		combo_color
	)

	# 绘制总伤害（可选）/ Draw total combo damage (optional)
	var damage_text = "x%d DMG" % (current_combo * 10)  # 假设每击 10 伤害 / Assume 10 damage per hit
	var damage_color = COLOR_COMBO
	damage_color.a = fade_alpha * 0.7

	root_control.draw_string(
		font,
		position + Vector2(0, COMBO_FONT_SIZE),
		damage_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		20,
		damage_color
	)


func _draw_go_arrow(position: Vector2) -> void:
	## 绘制 GO 箭头（战斗区清空时显示）
	## Draw GO arrow (shown when combat zone cleared)

	# 闪烁效果 / Blinking effect
	if go_arrow_blink_timer < 0.25:
		var alpha = go_arrow_blink_timer / 0.25
		var arrow_color = Color.GREEN
		arrow_color.a = alpha

		# 绘制向右的箭头 / Draw arrow pointing right
		var arrow_size = 50
		var arrow_pos = position

		# 箭头头部 / Arrow head
		var points = PackedVector2Array([
			arrow_pos + Vector2(arrow_size, 0),
			arrow_pos + Vector2(arrow_size - 20, -20),
			arrow_pos + Vector2(arrow_size - 20, 20),
		])
		root_control.draw_colored_polygon(points, arrow_color)

		# 箭头杆 / Arrow shaft
		root_control.draw_line(
			arrow_pos + Vector2(-arrow_size, 0),
			arrow_pos + Vector2(arrow_size, 0),
			arrow_color,
			3.0
		)

		# 文字 / Text
		var font = ThemeDB.fallback_font
		root_control.draw_string(
			font,
			position + Vector2(0, arrow_size + 20),
			"GO!",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			40,
			arrow_color
		)


# 公开方法 / Public Methods

func set_health(health: int, max_hp: int) -> void:
	## 设置玩家生命值
	## Set player health
	current_health = health
	max_health = max_hp
	root_control.queue_redraw()


func set_recoverable_health(amount: int) -> void:
	## 设置可恢复生命值（绿色部分）
	## Set recoverable health (green section)
	recoverable_health = amount
	root_control.queue_redraw()


func set_score(score: int) -> void:
	## 设置分数
	## Set score
	current_score = score
	root_control.queue_redraw()


func add_score(amount: int) -> void:
	## 增加分数
	## Add to score
	current_score += amount
	root_control.queue_redraw()


func set_stars(count: int) -> void:
	## 设置星星数
	## Set star count
	star_count = count
	root_control.queue_redraw()


func add_star() -> void:
	## 添加一颗星星
	## Add one star
	star_count += 1
	root_control.queue_redraw()


func set_lives(lives: int) -> void:
	## 设置剩余生命数
	## Set remaining lives
	lives_remaining = lives
	root_control.queue_redraw()


func set_boss_health(health: int, max_hp: int) -> void:
	## 设置 BOSS 血条
	## Set boss health bar
	boss_health = health
	max_boss_health = max_hp
	show_boss_bar = true
	root_control.queue_redraw()


func hide_boss_bar() -> void:
	## 隐藏 BOSS 血条
	## Hide boss health bar
	show_boss_bar = false
	root_control.queue_redraw()


func show_go_marker() -> void:
	## 显示 GO 箭头（战斗区已清空）
	## Show GO arrow (combat zone cleared)
	show_go_arrow = true
	go_arrow_blink_timer = 0.0
	root_control.queue_redraw()

	# 3 秒后隐藏 / Hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	show_go_arrow = false
	root_control.queue_redraw()


# 信号处理方法 / Signal Handler Methods

func _on_score_changed(new_score: int) -> void:
	## 分数更改信号处理
	## Score changed signal handler
	set_score(new_score)


func _on_lives_changed(new_lives: int) -> void:
	## 生命数更改信号处理
	## Lives changed signal handler
	set_lives(new_lives)


func _on_player_health_changed(current: int, max_hp: int) -> void:
	## 玩家生命值更改信号处理
	## Player health changed signal handler
	set_health(current, max_hp)


func _on_combo_updated(combo_count: int) -> void:
	## 连击更新信号处理
	## Combo updated signal handler
	current_combo = combo_count
	combo_timer = 0.0  # 重置连击计时器 / Reset combo timer
	combo_fade_timer = 0.0
	show_combo = true
	root_control.queue_redraw()


func _on_combo_ended() -> void:
	## 连击结束信号处理
	## Combo ended signal handler
	current_combo = 0
	show_combo = false
	combo_timer = 0.0
	root_control.queue_redraw()
