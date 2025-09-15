# Player.gd
# Main player controller that handles physics and delegates behavior to states
# This should be attached to a CharacterBody2D node

extends CharacterBody2D
class_name Player

## Movement configuration
@export_group("Movement")
@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 2000.0

## Jump configuration
@export_group("Jump")
@export var jump_velocity: float = -400.0
@export var jump_cut_multiplier: float = 0.5
@export var max_jumps: int = 1

## Physics configuration
@export_group("Physics")
@export var gravity_scale: float = 1.0
@export var max_fall_speed: float = 1000.0


## Debug configuration
@export_group("Crouch")
@export var crash_dist: float = 120

## Debug configuration
@export_group("Debugs")
@export var enable_debug: bool = false
# @export var max_fall_speed: float = 1000.0

## State machine reference
@onready var state_machine: StateMachine = $StateMachine
@onready var ground_ray: RayCast2D = $Raycasts/GroundCounter
## Input tracking
var input_direction: float = 0.0
var jump_count: int = 0
var was_on_floor: bool = false
var can_crashDown: bool = true

func _ready() -> void:
	# Ensure the state machine has a reference to this player
	if state_machine:
		state_machine.character = self
	
	if enable_debug:
		debug_print_info()

func _physics_process(delta: float) -> void:
	# Update input
	_handle_input()
	
	# Track floor state for coyote time
	_track_floor_state()
	
	# Move the character (velocity is set by states)
	move_and_slide()
	
	if enable_debug:
		print("ground above :" , get_ground_distance())
	

## Handles input detection and caching
func _handle_input() -> void:
	input_direction = Input.get_axis("move_left", "move_right")

## Tracks whether we were on floor last frame (for coyote time)
func _track_floor_state() -> void:
	if is_on_floor() and not was_on_floor:
		# Just landed
		jump_count = 0
	
	was_on_floor = is_on_floor()

## Gets the current horizontal input direction
## @return: -1 for left, 1 for right, 0 for no input
func get_input_direction() -> float:
	return input_direction

## Checks if jump input is pressed this frame
func is_jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump")

## Checks if jump input is being held
func is_jump_held() -> bool:
	return Input.is_action_pressed("jump")

## Checks if jump input was just released
func is_jump_released() -> bool:
	return Input.is_action_just_released("jump")

## Checks if down key input is pressed
func is_down_pressed() -> bool:
	return Input.is_action_pressed("move_down")

## Checks if crouch input is pressed
func is_crouch_pressed() -> bool:
	return Input.is_action_pressed("crouch")

## Executes a jump with the configured velocity
## @param custom_velocity: Optional custom jump velocity, uses default if not provided
func jump(custom_velocity: float = 0.0) -> void:
	var jump_vel = custom_velocity if custom_velocity != 0.0 else jump_velocity
	velocity.y = jump_vel
	jump_count += 1

## Cuts the jump short (for variable height jumping)
func cut_jump() -> void:
	if velocity.y < 0:
		velocity.y *= jump_cut_multiplier

## Checks if the player can perform another jump
## @return: True if jump is available
func can_jump() -> bool:
	return jump_count < max_jumps or state_machine.is_on_floor_buffered()

## Resets jump count (typically called when landing)
func reset_jumps() -> void:
	jump_count = 0

## Gets current jump count
func get_jump_count() -> int:
	return jump_count

## Applies movement with the configured parameters
## @param direction: Movement direction (-1 to 1)
## @param delta: Time step
func apply_movement(direction: float, delta: float) -> void:
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

## Applies gravity with the configured parameters
## @param delta: Time step
## @param gravity_multiplier: Optional gravity multiplier
func apply_gravity(delta: float, gravity_multiplier: float = 1.0) -> void:
	if not is_on_floor():
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		velocity.y += gravity * gravity_scale * gravity_multiplier * delta
		velocity.y = min(velocity.y, max_fall_speed)




func get_ground_distance(max_depth: float = 1000.0) -> float:
	var space_state = get_world_2d().direct_space_state
	var initial_value = 0.0
	
		
	# Create ray parameters
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, max_depth))
	query.exclude = [self]  # ignore the player itself
	
	var result = space_state.intersect_ray(query)

	

	if result:
		if is_on_floor():
			initial_value = global_position.distance_to(result.position)
		return global_position.distance_to(result.position) - initial_value
	return INF



## Debug function to print player state
func debug_print_info() -> void:
	print("=== Player Debug ===")
	print("Position: ", global_position)
	print("Velocity: ", velocity)
	print("On Floor: ", is_on_floor())
	print("Jump Count: ", jump_count)
	print("Input Direction: ", input_direction)
	print("ground above :" , get_ground_distance())
	if state_machine:
		state_machine.debug_print_state_info()
