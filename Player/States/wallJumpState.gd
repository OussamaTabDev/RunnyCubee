# WallJumpState.gd
# Wall jump state - handles jumping off walls with directional momentum
# This should be attached to a child node of StateMachine named "WallJump"

extends State
class_name WallJumpState

## Wall jump vertical velocity
@export var wall_jump_velocity: float = -450.0
## Wall jump horizontal velocity (push away from wall)
@export var wall_jump_horizontal_velocity: float = 250.0
## Time before player can control horizontal movement after wall jump
@export var wall_jump_lock_time: float = 0.15
## Air control multiplier during wall jump lock period
@export var wall_jump_lock_air_control: float = 0.1
## Air control after lock period
@export var wall_jump_air_control: float = 0.7
## Variable jump time window
@export var variable_jump_time: float = 0.2

var wall_jump_timer: float = 0.0
var wall_jump_direction: int = 0
var can_variable_jump: bool = true
var movement_locked: bool = true

func _ready() -> void:
	state_name = "WallJump"
	can_move = true

func on_enter() -> void:
	print("Entering Wall Jump State")
	
	# Get the wall direction and jump away from it
	wall_jump_direction = character.get_wall_direction()
	
	# Execute wall jump with both vertical and horizontal velocity
	character.velocity.y = wall_jump_velocity
	character.velocity.x = -wall_jump_direction * wall_jump_horizontal_velocity
	
	# Reset timers and flags
	wall_jump_timer = 0.0
	can_variable_jump = true
	movement_locked = true
	
	print("Wall jumped away from wall direction: ", wall_jump_direction)

func on_exit() -> void:
	print("Exiting Wall Jump State")
	movement_locked = false

func state_physics_process(delta: float) -> void:
	# Update timer
	wall_jump_timer += delta
	
	# Check if movement lock period is over
	if movement_locked and wall_jump_timer >= wall_jump_lock_time:
		movement_locked = false
		character.edge_grap_enabled = true
		print("Wall jump movement unlocked")
	
	# Apply gravity
	character.apply_gravity(delta)
	
	# Handle variable jump height
	_handle_variable_jump()
	
	# Handle horizontal movement based on lock state
	_handle_horizontal_movement(delta)
	
	# Check for state transitions
	_check_transitions()

func _handle_variable_jump() -> void:
	# Allow jump cutting for variable height
	if can_variable_jump and wall_jump_timer < variable_jump_time:
		if character.is_jump_released() and character.velocity.y < 0:
			character.cut_jump()
			can_variable_jump = false

func _handle_horizontal_movement(delta: float) -> void:
	var input_dir = character.get_input_direction()
	
	if movement_locked:
		# During lock period, very limited air control
		if input_dir != 0:
			var air_acceleration = character.acceleration * wall_jump_lock_air_control
			character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed, air_acceleration * delta)
	else:
		# After lock period, normal air control
		if input_dir != 0:
			var air_acceleration = character.acceleration * wall_jump_air_control
			character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed, air_acceleration * delta)
		else:
			# Maintain momentum when no input
			var air_friction = character.friction * wall_jump_air_control
			character.velocity.x = move_toward(character.velocity.x, character.velocity.x * 0.95, air_friction * delta)

func _check_transitions() -> void:
	# Check for air dodge
	if character.is_on_edge:
		transition_to("EdgeGrap")
		return
		
	character.edge_grap_enabled = false
	if character.is_crouch_pressed() and character.velocity.y > -100:
		transition_to("AirDodge")
		return
	
	# Check if we hit another wall (allow immediate wall slide)
	if character.can_wall_slide() and wall_jump_timer > wall_jump_lock_time:
		transition_to("WallSlide")
		return
	

	# Check if we've started falling
	if character.velocity.y > 0:
		transition_to("Fall")
		return
	
	# Check if we landed
	if character.is_on_floor():
		# Determine next state based on input and velocity
		if abs(character.get_input_direction()) > 0.1 or abs(character.velocity.x) > 100:
			transition_to("Run")
		else:
			transition_to("Idle")
		return
	
	# Check for another wall jump (if touching a different wall)
	if character.is_jump_pressed() and character._is_on_wall() and wall_jump_timer > wall_jump_lock_time:
		var current_wall_dir = character.get_wall_direction()
		if current_wall_dir != wall_jump_direction:  # Different wall
			# Reset to wall jump off the new wall
			wall_jump_direction = current_wall_dir
			character.velocity.y = wall_jump_velocity
			character.velocity.x = -wall_jump_direction * wall_jump_horizontal_velocity
			wall_jump_timer = 0.0
			can_variable_jump = true
			movement_locked = true
			return