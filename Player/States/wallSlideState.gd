# WallSlideState.gd
# Wall slide state - handles sliding down walls with friction
# This should be attached to a child node of StateMachine named "WallSlide"

extends State
class_name WallSlideState

## Maximum wall slide speed (terminal velocity on wall)
@export var max_wall_slide_speed: float = 150.0
## sniping wall speed (terminal velocity on wall)
@export var snip_speed: float = 250.0
## Wall slide acceleration (how quickly you reach max slide speed)
@export var wall_slide_acceleration: float = 300.0
## Wall slide gravity multiplier (lighter than normal falling)
@export var wall_slide_gravity: float = 0.4

## Automatically falling
@export var enable_falling: bool = true
## How long you can wall slide before automatically falling
@export var max_wall_slide_time: float = 3.0
## Minimum time before you can transition away from wall slide
@export var min_wall_slide_time: float = 0.1

var wall_slide_timer: float = 0.0
var wall_direction: int = 0

func _ready() -> void:
	state_name = "WallSlide"
	can_move = true
	has_gravity = false  # We control gravity manually

func on_enter() -> void:
	print("Entering Wall Slide State")
	if character.velocity.y < 0:
		character.velocity.y /= 3  # Reset downward velocity when starting wall slide

	# Apply initial snip speed away from wall
	# Store which wall we're sliding on
	wall_direction = character.get_wall_direction()
	wall_slide_timer = 0.0
	character.velocity.x = snip_speed * wall_direction
	# Reset jump count (wall sliding refreshes jumps)
	character.reset_jumps()

func on_exit() -> void:
	print("Exiting Wall Slide State")

func state_physics_process(delta: float) -> void:
	# Update timer
	wall_slide_timer += delta
	
	# Apply wall slide physics
	_apply_wall_slide_physics(delta)
	
	# Limited horizontal movement while wall sliding
	_handle_horizontal_movement(delta)
	
	# Check for state transitions
	_check_transitions()

func _apply_wall_slide_physics(delta: float) -> void:
	# Apply reduced gravity for wall slide effect
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	character.velocity.y += gravity * wall_slide_gravity * delta
	
	# Clamp to max wall slide speed
	character.velocity.y = min(character.velocity.y, max_wall_slide_speed)

func _handle_horizontal_movement(delta: float) -> void:
	var input_dir = character.get_input_direction()
	
	# Allow limited movement away from wall
	if input_dir != 0:
		# If pushing away from wall, allow more movement
		if sign(input_dir) != wall_direction:
			var acceleration = character.acceleration * 0.5
			character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed * 0.3, acceleration * delta)
		else:
			# If pushing into wall, very limited movement
			# var acceleration = character.acceleration * 0.1
			# character.velocity.x = move_toward(character.velocity.x, 0, acceleration * delta)
			character.velocity.x = snip_speed * wall_direction
	else:
		# No input, slowly reduce horizontal velocity
		# pass
		# character.velocity.x = snip_speed * wall_direction
		character.velocity.x = move_toward(character.velocity.x, 0, character.friction * 0.5 * delta)

func _check_transitions() -> void:
	# Check for wall jump
	# if character.is_jump_pressed() and wall_slide_timer >= min_wall_slide_time:
	if (character.is_jump_pressed() or state_machine.is_jump_buffered()):
		transition_to("WallJump")
		return
	
	# Check if we're no longer on a wall or if down is pressed
	if not character._is_on_wall() or character.is_down_pressed():
		transition_to("Fall")
		return
	
	# Check if we hit the ground
	if character.is_on_floor():
		# Determine next state based on input
		if abs(character.get_input_direction()) > 0.1:
			transition_to("Run")
		else:
			transition_to("Idle")
		return
	
	# Check if we've been wall sliding too long (auto-fall)
	if wall_slide_timer >= max_wall_slide_time and enable_falling:
		transition_to("Fall")
		return
	
	# Check for air dodge
	if character.is_crouch_pressed():
		transition_to("AirDodge")
		return

## Gets the direction of the wall being slid on
func get_wall_slide_direction() -> int:
	return wall_direction