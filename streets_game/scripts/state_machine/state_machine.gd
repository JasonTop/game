## State machine manager
## 状态机管理器
##
## Manages transitions between states and coordinates state lifecycle.
## All input, process, and physics updates are forwarded to the current state.
class_name StateMachine extends Node

## Initial state to enter when the state machine is ready
## 状态机就绪时进入的初始状态
@export var initial_state: State

## Currently active state
## 当前活跃状态
var current_state: State

## Reference to the character this state machine controls
## 此状态机控制的角色引用
var character: BaseCharacter

## Dictionary to cache state nodes for quick lookup
## 缓存状态节点以供快速查找的字典
var _states: Dictionary = {}


func _ready() -> void:
	## Initialize the state machine and enter the initial state.
	# Get character reference from parent
	# 从父节点获取角色引用
	character = get_parent() as BaseCharacter

	# Cache all child states in a dictionary for O(1) lookup
	# 缓存所有子状态到字典中用于快速查找
	for child in get_children():
		if child is State:
			_states[child.name] = child
			# Ensure character reference is set
			# 确保设置了角色引用
			if child.character == null:
				child.character = character
			if child.state_machine == null:
				child.state_machine = self

	# Enter the initial state
	# 进入初始状态
	if initial_state:
		transition_to(initial_state)
	elif _states.size() > 0:
		# Fallback to first available state if initial_state not set
		# 如果未设置初始状态，则回退到第一个可用状态
		var first_state = _states.values()[0]
		transition_to(first_state)


func _unhandled_input(event: InputEvent) -> void:
	## Forward input events to the current state.
	if current_state:
		current_state.input_process(event)


func _process(delta: float) -> void:
	## Forward frame updates to the current state.
	if current_state:
		current_state.process_frame(delta)


func _physics_process(delta: float) -> void:
	## Forward physics updates to the current state.
	if current_state:
		current_state.physics_process(delta)


## Transition to a new state
## 转换到新状态
##
## This method handles the exit of the current state and entry into the new state.
## It ensures proper cleanup and initialization of state transitions.
##
## @param new_state - The State node to transition to
## @returns true if transition was successful, false otherwise
func transition_to(new_state: State) -> bool:
	# Validate the new state
	# 验证新状态
	if not new_state:
		push_error("StateMachine: Attempted to transition to null state")
		return false

	# Check if the new state is a valid child of this state machine
	# 检查新状态是否是此状态机的有效子节点
	if new_state.get_parent() != self:
		push_error("StateMachine: State '%s' is not a child of this state machine" % new_state.name)
		return false

	# Exit the current state
	# 退出当前状态
	if current_state:
		current_state.exit()

	# Update current state reference
	# 更新当前状态引用
	current_state = new_state

	# Enter the new state
	# 进入新状态
	current_state.enter()

	return true


## Overloaded transition_to that accepts both State and String
## 接受State和String的重载transition_to
func transition_to_variant(state_or_name) -> bool:
	# If it's a string name
	if state_or_name is String or state_or_name is StringName:
		if state_or_name not in _states:
			push_error("StateMachine: State '%s' not found" % state_or_name)
			return false
		state_or_name = _states[state_or_name]

	# Now handle as State reference
	if state_or_name is State:
		# Validate the new state
		if not state_or_name:
			push_error("StateMachine: Attempted to transition to null state")
			return false

		# Check if the new state is a valid child of this state machine
		if state_or_name.get_parent() != self:
			push_error("StateMachine: State '%s' is not a child of this state machine" % state_or_name.name)
			return false

		# Exit the current state
		if current_state:
			current_state.exit()

		# Update current state reference
		current_state = state_or_name

		# Enter the new state
		current_state.enter()

		return true

	return false


## Transition to a state by name
## 通过名称转换到状态
func transition_to_by_name(state_name: StringName) -> bool:
	if state_name not in _states:
		push_error("StateMachine: State '%s' not found" % state_name)
		return false

	return transition_to(_states[state_name])


## Get a state by name
## 通过名称获取状态
##
## @param state_name - The name of the state node
## @returns The State node, or null if not found
func get_state(state_name: StringName) -> State:
	return _states.get(state_name)


## Check if a specific state is currently active
## 检查特定状态是否当前活跃
##
## @param state - The state to check
## @returns true if the state is the current state
func is_state_active(state: State) -> bool:
	return current_state == state


## Check if a state is active by name
## 按名称检查状态是否活跃
##
## @param state_name - The name of the state to check
## @returns true if the named state is currently active
func is_state_active_by_name(state_name: StringName) -> bool:
	return current_state and current_state.name == state_name
