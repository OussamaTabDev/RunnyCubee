# RunState.gd
# Player running state - handles horizontal movement and maintains momentum
# This should be attached to a child node of StateMachine named "Run"

extends State
class_name RunState

## Speed multiplier for running animation
@export var run_animation_speed: float = 1.2

func _ready() -> void:
	state_name = "Run"
	animation_speed = run_animation_speed

func on_enter() -> void:
	print("Entering Run State")

func on_exit() -> void:
	print("Exiting Run State")

func state_physics_process(delta: float) -> void:
	# Apply gravity
	character.apply_gravity(delta)
	
	# Handle horizontal movement
	var input_dir = character.get_input_direction()
	character.apply_movement(input_dir, delta)
	
	# Check for state transitions
	_check_transitions()

func _check_transitions() -> void:
	# Check if we should jump
	if character.is_jump_pressed() and character.can_jump():
		transition_to("Jump")
		return
	
	# Check for spin input: hold jump while moving on ground
	if character.is_spin_pressed() and character.is_on_floor() and abs(character.get_input_direction()) > 0.1 and character.try_spin():
		transition_to("Spinning")
		return
		
	# Check if we stopped moving
	if abs(character.get_input_direction()) < 0.1:
		# Also check if we have minimal horizontal velocity
		if abs(character.velocity.x) < 50:
			transition_to("Idle")
			return
	
	# Check if we're crouching while moving (slide or crouch-run)
	if character.is_crouch_pressed():
		transition_to("Crouch")
		return
	
	# Check if we're falling
	if character.velocity.y > 50 and not character.is_on_floor():
		transition_to("Fall")
		return

## Handles buffered jump from state machine
func handle_buffered_jump() -> void:
	if character.can_jump():
		state_machine.consume_jump_buffer()
		transition_to("Jump")