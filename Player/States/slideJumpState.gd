# SlideJumpState.gd
# Slide jump state - handles small jump with forward momentum when jumping while sliding
# This should be attached to a child node of StateMachine named "SlideJump"

extends State
class_name SlideJumpState

## Small jump velocity for slide jump
@export var slide_jump_velocity: float = -250.0
## Strong forward momentum boost
@export var forward_momentum_boost: float = 300.0
## Backward momentum penalty (less control going backward)
@export var backward_momentum_penalty: float = 0.3
## Very limited air control during slide jump
@export var slide_jump_air_control: float = 0.3
## Shorter variable jump time
@export var variable_jump_time: float = 0.15

var jump_timer: float = 0.0
var can_variable_jump: bool = true
var slide_direction: float = 0.0

func _ready() -> void:
	state_name = "SlideJump"
	can_move = true

func on_enter() -> void:
	print("Entering Slide Jump State")
	
	# Store the direction we were sliding
	slide_direction = sign(character.velocity.x)
	
	# Execute the small slide jump
	character.jump(slide_jump_velocity)
	
	# Apply momentum based on slide direction
	if slide_direction != 0:
		character.velocity.x += slide_direction * forward_momentum_boost
	
	# Reset jump timer
	jump_timer = 0.0
	can_variable_jump = true

func on_exit() -> void:
	print("Exiting Slide Jump State")

func state_physics_process(delta: float) -> void:
	# Update jump timer
	jump_timer += delta
	
	# Apply gravity
	character.apply_gravity(delta)
	
	# Handle variable jump height (shorter window)
	_handle_variable_jump()
	
	# Handle horizontal movement with very limited control
	var input_dir = character.get_input_direction()
	if can_move:
		var air_acceleration = character.acceleration * slide_jump_air_control
		var air_friction = character.friction * slide_jump_air_control
		
		if input_dir != 0:
			# Check if trying to go backward against slide momentum
			if sign(input_dir) != slide_direction and slide_direction != 0:
				# Heavily penalize backward movement
				air_acceleration *= backward_momentum_penalty
			
			character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed, air_acceleration * delta)
		else:
			# Maintain slide momentum
			character.velocity.x = move_toward(character.velocity.x, character.velocity.x * 0.95, air_friction * delta)
	
	# Check for state transitions
	_check_transitions()

func _handle_variable_jump() -> void:
	# Very limited variable jump height for slide jump
	if can_variable_jump and jump_timer < variable_jump_time:
		if character.is_jump_released() and character.velocity.y < 0:
			character.cut_jump()
			can_variable_jump = false

func _check_transitions() -> void:
	# Check for air dodge (down input while in slide jump)
	if character.is_crouch_pressed() and character.velocity.y > -50:  # Earlier dodge for slide jump
		transition_to("AirDodge")
		return
	
	# Check if we've started falling
	if character.velocity.y > 0:
		transition_to("Fall")
		return
	
	# Check if we landed
	if character.is_on_floor():
		# Determine next state based on momentum and input
		if abs(character.velocity.x) > 100:
			transition_to("Run")
		elif abs(character.get_input_direction()) > 0.1:
			transition_to("Run")
		else:
			transition_to("Idle")
		return