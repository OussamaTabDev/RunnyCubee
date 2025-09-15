# IdleState.gd
# Player idle state - handles standing still and transitions to other states
# This should be attached to a child node of StateMachine named "Idle"

extends State
class_name CrashDownState

@export var transition_time:float = 0.7
var time = 0
func _ready() -> void:
	state_name = "CrashDown"
	time = 0

func on_enter() -> void:
	print("Entering Idle State")
	# Reset any idle-specific properties
	character.can_crashDown = true	
	character.reset_jumps()

func on_exit() -> void:
	print("Exiting Idle State")

func state_physics_process(delta: float) -> void:
	time += delta
	# Apply gravity
	character.apply_gravity(delta)
	if time > transition_time :
		transition_to("Idle")
	# Handle horizontal movement
	# var input_dir = character.get_input_direction()
	# character.apply_movement(input_dir, delta)
	
	# Check for state transitions
	_check_transitions()

func _check_transitions() -> void:
	# Check if we should jump
	if character.is_jump_pressed() and character.can_jump():
		transition_to("Jump")
		return
	
	
	# Check if we're moving
	# if abs(character.get_input_direction()) > 0.1:
	# 	transition_to("Run")
	# 	return
	
	# Check if we're crouching
	# if character.is_crouch_pressed():
	# 	transition_to("Crouch")
	# 	return
	
	# Check if we're falling
	# if character.velocity.y > 50 and not character.is_on_floor():
	# 	transition_to("Fall")
	# 	return

## Handles buffered jump from state machine
func handle_buffered_jump() -> void:
	if character.can_jump():
		state_machine.consume_jump_buffer()
		transition_to("Jump")