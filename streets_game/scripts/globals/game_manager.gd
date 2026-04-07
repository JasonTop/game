extends Node
## 全域遊戲管理器（Autoload）
## 在 Project Settings → Autoload 中將此腳本加入

var score: int = 0
var lives: int = 3
var is_game_over: bool = false

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_over

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		is_game_over = true
		game_over.emit()

func reset_game() -> void:
	score = 0
	lives = 3
	is_game_over = false
