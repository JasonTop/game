## Base state class for all game states
## 状态机基类 - 所有游戏状态都继承自此
##
## This class provides the foundation for implementing states in a hierarchical
## state machine. Subclasses override virtual methods to define state behavior.
class_name State extends Node

## Reference to the character this state belongs to
## 此状态所属的角色引用
var character: CharacterBody2D

## Reference to the state machine that manages this state
## 管理此状态的状态机引用
var state_machine: StateMachine


func _ready() -> void:
	"""Initialize state references when the node enters the scene tree."""
	# Get the parent StateMachine node
	# 获取父节点状态机
	state_machine = get_parent()

	# Get the character from the state machine's parent
	# 从状态机的父节点获取角色
	if state_machine and state_machine.get_parent():
		character = state_machine.get_parent() as CharacterBody2D


## Called when entering this state
## 进入此状态时调用
func enter() -> void:
	"""Override this method to handle state entry logic."""
	pass


## Called when exiting this state
## 退出此状态时调用
func exit() -> void:
	"""Override this method to handle state exit logic."""
	pass


## Called for input event processing
## 处理输入事件
##
## @param event - The input event to process
func input_process(event: InputEvent) -> void:
	"""Override this method to handle input in this state."""
	pass


## Called every frame for non-physics updates
## 每帧调用用于非物理更新
##
## @param delta - Time elapsed since last frame in seconds
func process_frame(delta: float) -> void:
	"""Override this method for per-frame updates (animations, timers, etc)."""
	pass


## Called every physics frame for movement and physics updates
## 每个物理帧调用用于移动和物理更新
##
## @param delta - Physics frame time in seconds
func physics_process(delta: float) -> void:
	"""Override this method for physics updates (velocity changes, collision checks)."""
	pass


## Aliases for backwards compatibility
## 向后兼容的别名
func process_input_deprecated(event: InputEvent) -> void:
	input_process(event)

func process_physics_deprecated(delta: float) -> void:
	physics_process(delta)
