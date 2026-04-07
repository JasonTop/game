## Global game state manager
## 全局游戏状态管理器
##
## This autoload script manages global game state including score, lives,
## game over state, and game-wide effects like hit stops and screen shake.
## Can be accessed from anywhere as GameManager.
##
## 此自动加载脚本管理全局游戏状态，包括得分、生命值、
## 游戏结束状态和全局效果如僵直和屏幕震动。
## 可以从任何地方作为GameManager访问。
extends Node

## Current game score
## 当前游戏得分
var score: int = 0

## Number of lives remaining
## 剩余生命数
var lives: int = 3

## Whether the game is currently over
## 游戏当前是否结束
var is_game_over: bool = false

## Current level number
## 当前关卡编号
var current_level: int = 1

## Maximum lives per game
## 每个游戏的最大生命值
@export var max_lives: int = 3

## Signal emitted when score changes
## 当得分变化时发出的信号
signal score_changed(new_score: int)

## Signal emitted when lives change
## 当生命值变化时发出的信号
signal lives_changed(remaining_lives: int)

## Signal emitted when game over
## 当游戏结束时发出的信号
signal game_over(final_score: int)

## Signal emitted for screen shake effects
## 为屏幕震动效果发出的信号
signal request_screen_shake(intensity: float, duration: float)

## Track active hit stop to prevent overlapping
## 追踪活跃僵直以防止重叠
var _hit_stop_active: bool = false
var _hit_stop_timer: float = 0.0


func _ready() -> void:
	## Initialize the game manager
	# Don't pause the game manager during hit stops
	# 在僵直期间不要暂停游戏管理器
	process_mode = PROCESS_MODE_ALWAYS

	# Reset to initial state
	# 重置为初始状态
	reset_game()


func _process(delta: float) -> void:
	## Update hit stop duration
	if _hit_stop_active and _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta

		if _hit_stop_timer <= 0.0:
			_end_hit_stop()


## Add points to the current score
## 添加点数到当前得分
##
## @param points - Amount of points to add
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

	if OS.is_debug_build():
		print("Score: +%d (Total: %d)" % [points, score])


## Subtract points from the score
## 从得分中减去点数
##
## @param points - Amount of points to subtract
func subtract_score(points: int) -> void:
	score = max(0, score - points)
	score_changed.emit(score)


## Lose a life and check for game over
## 失去一条生命并检查游戏是否结束
func lose_life() -> void:
	if lives > 0:
		lives -= 1
		lives_changed.emit(lives)

		if lives <= 0:
			trigger_game_over()
		else:
			if OS.is_debug_build():
				print("Lives: %d" % lives)


## Gain a life up to max_lives
## 获得一条生命直到max_lives
func gain_life() -> void:
	if lives < max_lives:
		lives += 1
		lives_changed.emit(lives)

		if OS.is_debug_build():
			print("Lives: %d" % lives)


## Trigger game over state
## 触发游戏结束状态
func trigger_game_over() -> void:
	if is_game_over:
		return  # Already game over

	is_game_over = true
	game_over.emit(score)

	# Pause the game
	# 暂停游戏
	get_tree().paused = true

	if OS.is_debug_build():
		print("GAME OVER! Final Score: %d" % score)


## Reset the game to initial state
## 将游戏重置为初始状态
func reset_game() -> void:
	score = 0
	lives = max_lives
	is_game_over = false
	current_level = 1
	_hit_stop_active = false
	_hit_stop_timer = 0.0

	# Unpause if paused
	# 如果暂停，则取消暂停
	if get_tree().paused:
		get_tree().paused = false

	score_changed.emit(score)
	lives_changed.emit(lives)


## Apply a hit stop effect (brief game freeze)
## 应用僵直效果（短暂游戏冻结）
##
## Hit stop freezes the game briefly when a hit lands, creating impact feeling.
## It pauses all physics and animations except the game manager itself.
##
## @param duration - How long to freeze in seconds
func hit_stop(duration: float = 0.1) -> void:
	if _hit_stop_active:
		# If already in hit stop, extend it
		# 如果已经在僵直，延长它
		_hit_stop_timer = max(_hit_stop_timer, duration)
		return

	_hit_stop_active = true
	_hit_stop_timer = duration

	# Pause the game tree
	# 暂停游戏树
	get_tree().paused = true


## Internal method to end the hit stop effect
## 内部方法以结束僵直效果
func _end_hit_stop() -> void:
	_hit_stop_active = false
	_hit_stop_timer = 0.0

	# Resume the game tree
	# 恢复游戏树
	get_tree().paused = false


## Emit screen shake effect signal
## 发出屏幕震动效果信号
##
## This emits the request_screen_shake signal that camera listens to.
## 此方法发出 request_screen_shake 信号，相机会监听。
##
## @param intensity - How intense the shake is (0-1 typically)
## @param duration - How long the shake lasts in seconds
func emit_screen_shake(intensity: float = 0.5, duration: float = 0.2) -> void:
	request_screen_shake.emit(intensity, duration)

	if OS.is_debug_build():
		print("Screen shake requested: intensity=%.2f, duration=%.2f" % [intensity, duration])


## Add stars (for pickup system)
## 增加星星（拾取系统用）
func add_stars(amount: int) -> void:
	# 星星直接转为分数 / Stars convert to score
	add_score(amount * 500)


## Add money (for pickup system)
## 增加金钱（拾取系统用）
func add_money(amount: int) -> void:
	add_score(amount)


## Set the current level
## 设置当前关卡
##
## @param level - The level number
func set_level(level: int) -> void:
	current_level = level


## Get the current game state as a dictionary
## 获取当前游戏状态作为字典
##
## @returns A dictionary containing all relevant game state
func get_state() -> Dictionary:
	return {
		"score": score,
		"lives": lives,
		"is_game_over": is_game_over,
		"current_level": current_level,
		"max_lives": max_lives
	}


## Load game state from a dictionary
## 从字典加载游戏状态
##
## @param state - Dictionary containing game state
func load_state(state: Dictionary) -> void:
	if state.has("score"):
		score = state["score"]
	if state.has("lives"):
		lives = state["lives"]
	if state.has("is_game_over"):
		is_game_over = state["is_game_over"]
	if state.has("current_level"):
		current_level = state["current_level"]

	score_changed.emit(score)
	lives_changed.emit(lives)
