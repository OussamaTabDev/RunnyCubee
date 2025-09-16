# CrouchIdleJumpState.gd
# Crouch idle jump state - handles small vertical jump when jumping while stationary and crouched
# This should be attached to a child node of StateMachine named "CrouchIdleJump"

extends State
class_name CrouchIdleJumpState

## Small jump velocity for stationary crouch jump
@export var crouch_idle_jump_velocity: float = -200.0
## Normal air control for this small jump
@export var crouch_idle_air_control: float = 0.8
## Variable jump time
@export var variable_jump_time: float = 0.1

var jump_timer: float = 0.0
var can_variable_jump: bool = true

func _ready() -> void:
	state_name = "CrouchIdleJump"
	can_move = true

func on_enter() -> void:
	print("Entering Crouch Idle Jump State")
	
	# Execute the small vertical jump
	character.jump(crouch_idle_jump_velocity)
	
	# No horizontal momentum boost for idle crouch jump
	
	# Reset jump timer
	jump_timer = 0.0
	can_variable_jump = true

func on_exit() -> void:
	print("Exiting Crouch Idle Jump State")

func state_physics_process(delta: float) -> void:
	# Update jump timer
	jump_timer += delta
	
	# Apply gravity
	character.apply_gravity(delta)
	
	# Handle variable jump height (very short window)
	_handle_variable_jump()
	
	# Handle horizontal movement with normal air control
	var input_dir = character.get_input_direction()
	if can_move:
		var air_acceleration = character.acceleration * crouch_idle_air_control
		var air_friction = character.friction * crouch_idle_air_control
		
		if input_dir != 0:
			character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed, air_acceleration * delta)
		else:
			character.velocity.x = move_toward(character.velocity.x, 0, air_friction * delta)
	
	# Check for state transitions
	_check_transitions()

func _handle_variable_jump() -> void:
	# Very short variable jump window for small jump
	if can_variable_jump and jump_timer < variable_jump_time:
		if character.is_jump_released() and character.velocity.y < 0:
			character.cut_jump()
			can_variable_jump = false

func _check_transitions() -> void:
	# Check for air dodge (down input while in crouch idle jump)
	if character.is_crouch_pressed() and character.velocity.y > -50:
		transition_to("AirDodge")
		return
	
	# Check if we've started falling
	if character.velocity.y > 0:
		transition_to("Fall")
		return
	
	# Check if we landed
	if character.is_on_floor():
		# Determine next state based on input
		if abs(character.get_input_direction()) > 0.1:
			transition_to("Run")
		else:
			transition_to("Idle")
		return