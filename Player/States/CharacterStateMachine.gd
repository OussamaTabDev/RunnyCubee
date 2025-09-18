# StateMachine.gd
# Manages all player states and handles transitions between them
# Automatically discovers child states and provides easy state switching

extends Node
class_name StateMachine

## Reference to the character this state machine controls
@export var character: CharacterBody2D
## Name of the initial state to start with
@export var initial_state_name: String = "Idle"

## Dictionary storing all available states by name
var states: Dictionary = {}
## Currently active state
var current_state: State
## Previous state (useful for state-specific logic)
var previous_state: State

## Coyote time timer - allows jumping shortly after leaving ground
var coyote_timer: float = 0.0
## Jump buffer timer - allows jump input to register before landing
var jump_buffer_timer: float = 0.0
## Whether jump was buffered
var jump_buffered: bool = false
## Whether ground pound was buffered
var ground_pound_jump_buffered: bool = false
## Ground pound buffer timer - allows jump input to register before landing
var ground_pound_buffer_timer: float = 0.0
## Coyote time duration in seconds
const COYOTE_TIME: float = 0.15
## Jump buffer duration in seconds
const JUMP_BUFFER_TIME: float = 0.1

signal state_changed(old_state: State, new_state: State)

func _ready() -> void:
	# Discover and register all child states
	_discover_states()
	
	# Set up state references
	_setup_states()
	
	# Start with initial state
	call_deferred("change_state", initial_state_name)

func _process(delta: float) -> void:
	if current_state:
		current_state.state_process(delta)
	
	_update_timers(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.state_physics_process(delta)
	
	# Handle jump buffering
	_handle_jump_buffer()

## Discovers all child nodes that inherit from State
func _discover_states() -> void:
	states.clear()
	
	for child in get_children():
		if child is State:
			var state_name = child.name
			states[state_name] = child
			print("Discovered state: ", state_name)

## Sets up references for all discovered states
func _setup_states() -> void:
	for state_name in states:
		var state: State = states[state_name]
		state.state_name = state_name
		state.character = character
		state.state_machine = self

## Changes to a new state by name
## @param new_state_name: Name of the target state
func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		print("Error: State '", new_state_name, "' not found!")
		return
	
	var new_state: State = states[new_state_name]
	
	if current_state == new_state:
		return
	
	# Exit current state
	if current_state:
		current_state.on_exit()
		previous_state = current_state
	
	# Enter new state
	current_state = new_state
	current_state.on_enter()
	
	print("State changed: ", previous_state.state_name if previous_state else "None", " -> ", current_state.state_name)
	state_changed.emit(previous_state, current_state)

## Gets a state by name
## @param state_name: Name of the state to retrieve
## @return: The State object or null if not found
func get_state(state_name: String) -> State:
	return states.get(state_name, null)

## Checks if a specific state exists
## @param state_name: Name of the state to check
## @return: True if the state exists
func has_state(state_name: String) -> bool:
	return states.has(state_name)

## Gets the name of the current state
## @return: Current state name or empty string if none
func get_current_state_name() -> String:
	return current_state.state_name if current_state else ""

func get_previous_state_name() -> String:
	return previous_state.state_name if previous_state else ""

## Adds a new state dynamically (useful for runtime state addition)
## @param state_name: Name for the new state
## @param state_scene: Packed scene containing the state
func add_state_from_scene(state_name: String, state_scene: PackedScene) -> void:
	var state_instance = state_scene.instantiate()
	if state_instance is State:
		add_child(state_instance)
		state_instance.name = state_name
		states[state_name] = state_instance
		state_instance.state_name = state_name
		state_instance.character = character
		state_instance.state_machine = self
		print("Added state dynamically: ", state_name)

## Buffers a jump input for a short time
func buffer_jump() -> void:
	jump_buffered = true
	jump_buffer_timer = JUMP_BUFFER_TIME

## Consumes the jump buffer (call when jump is executed)
func consume_jump_buffer() -> void:
	jump_buffered = false
	jump_buffer_timer = 0.0

## Checks if jump is buffered and still valid
func is_jump_buffered() -> bool:
	return jump_buffered and jump_buffer_timer > 0.0

## Updates internal timers
func _update_timers(delta: float) -> void:
	# Update coyote timer
	if character and character.is_on_floor():
		coyote_timer = 0.0
	else:
		coyote_timer += delta
	
	# Update jump buffer timer
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
		if jump_buffer_timer <= 0.0:
			jump_buffered = false

## Handles jump buffering logic
func _handle_jump_buffer() -> void:
	if Input.is_action_just_pressed("jump"):
		buffer_jump()
	
	# If we have a buffered jump and we're on ground, try to jump
	if is_jump_buffered() and character and character.is_on_floor():
		# Let the current state handle the buffered jump
		if current_state and current_state.has_method("handle_buffered_jump"):
			current_state.handle_buffered_jump()

func is_on_floor_buffered():
	return coyote_timer < COYOTE_TIME

func can_CrashDown():
	if character.get_ground_distance() > character.crash_dist and character.can_crashDown:
		return true
	return false
	
## Debug function to print current state info
func debug_print_state_info() -> void:
	print("=== State Machine Debug ===")
	print("Current State: ", get_current_state_name())
	print("Previous State: ",get_previous_state_name())
	print("Available States: ", states.keys())
	print("Coyote Timer: ", coyote_timer)
	print("Jump Buffer Timer: ", jump_buffer_timer)
	print("Jump Buffered: ", jump_buffered)
	print("Ground Pound Buffer Timer: ", ground_pound_buffer_timer)
	print("Ground Pound Jump Buffered: ", ground_pound_jump_buffered)
