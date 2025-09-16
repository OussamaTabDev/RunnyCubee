# FallState.gd
# Player fall state - handles falling mechanics, air control, and coyote time
# This should be attached to a child node of StateMachine named "Fall"

extends State
class_name FallState

## Air control multiplier while falling
@export var fall_air_control: float = 0.9
## Gravity multiplier for faster falling
@export var fall_gravity_multiplier: float = 1.2

@export var fall_max_speed_multiplier: float = 0.8
func _ready() -> void:
	state_name = "Fall"
	can_move = true

func on_enter() -> void:
	print("Entering Fall State")

func on_exit() -> void:
	print("Exiting Fall State")

func state_physics_process(delta: float) -> void:
	# Apply gravity (slightly stronger while falling)
	character.apply_gravity(delta, fall_gravity_multiplier)
	
	# Handle horizontal movement with air control
	var input_dir = character.get_input_direction()
	if can_move:
		# Apply air control
		var air_acceleration = character.acceleration * fall_air_control
		var air_friction = character.friction * fall_air_control
		
		if input_dir != 0:
			character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed * fall_max_speed_multiplier, air_acceleration * delta)
		else:
			# Less friction in air to maintain momentum
			character.velocity.x = move_toward(character.velocity.x, character.velocity.x * 0.98, air_friction * delta)
	
	# Check for state transitions
	_check_transitions()

func _check_transitions() -> void:
	if  character.is_down_pressed():
		transition_to("FastFall")
	# Check if we landed
	if character.is_on_floor():
		character.reset_jumps()
		
		# Determine next state based on input and velocity
		if abs(character.get_input_direction()) > 0.1:
			transition_to("Run")
		else:
			transition_to("Idle")
		return
	
	
	
	# Check for air jump/double jump
	if character.is_jump_pressed() and character.can_jump():
		transition_to("Jump")
		return

## Handles buffered jump from state machine
func handle_buffered_jump() -> void:
	if state_machine.coyote_timer < state_machine.COYOTE_TIME or character.can_jump():
		state_machine.consume_jump_buffer()
		transition_to("Jump")
