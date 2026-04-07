## Combo system manager
## 连击系统管理器
##
## Tracks ongoing combos, accumulates damage, and manages combo timeouts.
## A combo ends if no new hits are registered within the timeout period.
class_name ComboManager extends Node

## Current combo counter
## 当前连击计数器
var combo_count: int = 0

## Total damage accumulated in current combo
## 当前连击中累积的总伤害
var combo_damage: int = 0

## Timeout before combo resets (in seconds)
## 连击重置前的超时时间（秒）
@export var combo_timeout: float = 2.0

## Score bonus multiplier per hit
## Combo Score = count * COMBO_SCORE_BONUS
## 每次击中的得分奖励乘数
## 连击得分 = 计数 * COMBO_SCORE_BONUS
const COMBO_SCORE_BONUS: int = 100

## Timer for tracking combo timeout
## 用于追踪连击超时的计时器
var _timeout_timer: float = 0.0

## Signal emitted when a hit is added to the combo
## 当击中被添加到连击时发出的信号
signal combo_updated(count: int, total_damage: int)

## Signal emitted when the combo ends
## 当连击结束时发出的信号
signal combo_ended(final_count: int, final_damage: int, bonus_score: int)


func _ready() -> void:
	"""Initialize the combo manager."""
	reset_combo()


func _process(delta: float) -> void:
	"""Update combo timeout timer."""
	if combo_count > 0 and _timeout_timer > 0.0:
		_timeout_timer -= delta

		if _timeout_timer <= 0.0:
			end_combo()


## Add a hit to the current combo
## 添加击中到当前连击
##
## This method should be called whenever a hit lands on an enemy.
## It resets the combo timeout and increments the combo counter.
##
## @param damage - Amount of damage dealt in this hit
func add_hit(damage: int) -> void:
	"""
	Add a hit to the current combo.
	添加击中到当前连击。
	"""
	# Initialize combo if this is the first hit
	# 如果这是第一次击中，初始化连击
	if combo_count == 0:
		_start_combo()

	# Increment combo and add damage
	# 增加连击计数和伤害
	combo_count += 1
	combo_damage += damage

	# Reset the timeout timer
	# 重置超时计时器
	_timeout_timer = combo_timeout

	# Emit update signal
	# 发出更新信号
	combo_updated.emit(combo_count, combo_damage)

	# Debug output
	# 调试输出
	if OS.is_debug_build():
		print("Combo: %d | Damage: %d | Total Bonus: %d" % [combo_count, combo_damage, get_combo_bonus()])


## Get the current combo score bonus
## 获取当前连击得分奖励
##
## @returns The bonus score from the current combo
func get_combo_bonus() -> int:
	"""
	Calculate the combo bonus score.
	连击奖励 = 连击计数 * 100点
	"""
	return combo_count * COMBO_SCORE_BONUS


## Manually end the combo
## 手动结束连击
func end_combo() -> void:
	"""
	End the current combo and emit the combo_ended signal.
	结束当前连击并发出combo_ended信号。
	"""
	if combo_count == 0:
		return

	# Calculate bonus before clearing
	# 在清除之前计算奖励
	var final_count = combo_count
	var final_damage = combo_damage
	var bonus_score = get_combo_bonus()

	# Reset combo
	# 重置连击
	reset_combo()

	# Emit the end signal
	# 发出结束信号
	combo_ended.emit(final_count, final_damage, bonus_score)

	# Debug output
	# 调试输出
	if OS.is_debug_build():
		print("Combo Ended: %d hits, %d damage, %d bonus points" % [final_count, final_damage, bonus_score])


## Reset the combo to initial state
## 将连击重置为初始状态
func reset_combo() -> void:
	"""
	Reset the combo counter and damage.
	重置连击计数器和伤害。
	"""
	combo_count = 0
	combo_damage = 0
	_timeout_timer = 0.0
	set_process(false)


## Called when a combo starts (first hit)
## 当连击开始时调用（第一次击中）
func _start_combo() -> void:
	"""Internal method called when a combo begins."""
	# Enable process to track timeout
	# 启用处理以追踪超时
	set_process(true)

	if OS.is_debug_build():
		print("Combo started!")


## Get formatted combo string for UI display
## 获取格式化的连击字符串以供UI显示
##
## @returns A formatted string like "5 Hit Combo - 250 Damage"
func get_combo_string() -> String:
	"""
	Get a formatted string representation of the current combo.
	获取当前连击的格式化字符串表示。
	"""
	if combo_count == 0:
		return ""

	if combo_count == 1:
		return "%d Hit - %d Damage" % [combo_count, combo_damage]
	else:
		return "%d Hit Combo - %d Damage" % [combo_count, combo_damage]


## Get remaining combo timeout time
## 获取剩余的连击超时时间
##
## @returns The time in seconds until the combo resets
func get_remaining_timeout() -> float:
	"""
	Get the remaining time before combo resets.
	获取连击重置前的剩余时间。
	"""
	return max(0.0, _timeout_timer)
