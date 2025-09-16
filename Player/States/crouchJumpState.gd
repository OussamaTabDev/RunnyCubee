# CrouchJumpState.gd
# Crouch jump state - handles higher jumps when moving while crouched
# This should be attached to a child node of StateMachine named "CrouchJump"

extends State
class_name CrouchJumpState

## Higher jump velocity for crouch jump
@export var crouch_jump_velocity: float = -500.0
## Forward momentum boost when jumping while moving
@export var forward_momentum_boost: float = 150.0
## Air control during crouch jump
@export var crouch_jump_air_control: float = 0.6
## Time window for variable jump height
@export var variable_jump_time: float = 0.25

var jump_timer: float = 0.0
var can_variable_jump: bool = true
var jump_direction: float = 0.0

func _ready() -> void:
	state_name = "CrouchJump"
	can_move = true

func on_enter() -> void:
	print("Entering Crouch Jump State")
	
	# Store the direction we were moving when we jumped
	jump_direction = character.get_input_direction()
	
	# Execute the higher crouch jump
	character.jump(crouch_jump_velocity)
	
	# Apply forward momentum boost if moving forward
	if jump_direction != 0:
		character.velocity.x += jump_direction * forward_momentum_boost
	
	# Reset jump timer for variable height
	jump_timer = 0.0
	can_variable_jump = true

func on_exit() -> void:
	print("Exiting Crouch Jump State")

func state_physics_process(delta: float) -> void:
	# Update jump timer
	jump_timer += delta
	
	# Apply gravity
	character.apply_gravity(delta)
	
	# Handle variable jump height
	_handle_variable_jump()
	
	# Handle horizontal movement with reduced air control
	var input_dir = character.get_input_direction()
	if can_move:
		var air_acceleration = character.acceleration * crouch_jump_air_control
		var air_friction = character.friction * crouch_jump_air_control
		
		if input_dir != 0:
			character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed, air_acceleration * delta)
		else:
			# Maintain momentum from the initial jump boost
			character.velocity.x = move_toward(character.velocity.x, character.velocity.x, air_friction * delta)
	
	# Check for state transitions
	_check_transitions()

func _handle_variable_jump() -> void:
	# Allow jump cutting for variable height (longer window than normal jump)
	if can_variable_jump and jump_timer < variable_jump_time:
		if character.is_jump_released() and character.velocity.y < 0:
			character.cut_jump()
			can_variable_jump = false

func _check_transitions() -> void:
	# Check for air dodge (down input while in crouch jump)
	if character.is_crouch_pressed() and character.velocity.y > -100:
		transition_to("AirDodge")
		return
	
	# Check if we've started falling
	if character.velocity.y > 0:
		transition_to("Fall")
		return
	
	# Check if we somehow landed (shouldn't happen in normal jump arc)
	if character.is_on_floor():
		# Determine next state based on input
		if abs(character.get_input_direction()) > 0.1:
			transition_to("Run")
		else:
			transition_to("Idle")
		return