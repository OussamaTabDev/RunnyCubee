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
@export_group("Spin")
@export var spin_cooldown_time: float = 1.5

## Wall detection configuration
@export_group("Wall Detection")
@export var wall_check_distance: float = 20.0
@export var wall_check_offset_top: float = -10.0
@export var wall_check_offset_bottom: float = 10.0
@export var wall_collider: Array[RayCast2D]
@export var wall_shape_colliders: Array[ShapeCast2D]

## Debug configuration
@export_group("Debugs")
@export var enable_debug: bool = false
@export var debug_label_character: Label 
@export var debug_label_stateMachine: Label 

## State machine reference
@onready var state_machine: StateMachine = $StateMachine

## collision shape reference
@onready var EdgeCollision: CollisionShape2D = $EdgeCollision
## Input tracking
var input_direction: float = 0.0
var jump_count: int = 0
var is_in_floor:bool = true
var was_on_floor: bool = false
var can_crashDown: bool = true
var is_on_wall_left: bool = false
var is_on_wall_right: bool = false
var is_on_edge: bool = false
var edge_grap_enabled: bool = false:
	get:
		return not EdgeCollision.disabled
	set(value):
		EdgeCollision.disabled = not value
		EdgeCollision.visible = value
		

var can_spin: bool = true
var spin_cooldown: float = 0.0

func _ready() -> void:
	# Ensure the state machine has a reference to this player
	if state_machine:
		state_machine.character = self
	
	if enable_debug:
		debug_print_info()

func _physics_process(delta: float) -> void:
	# Update input
	_handle_input()
	
	# Update wall detection
	_update_wall_detection()

	
		
	# handle spin cooldown
	_handle_spin_cooldown(delta)

	# Track floor state for coyote time
	_track_floor_state()
	
	# Move the character (velocity is set by states)
	move_and_slide()
	
	# Update debug labels if enabled
	if enable_debug:
		_update_debug_labels()
	

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

## Checks if up key input is pressed
func is_up_pressed() -> bool:
	return Input.is_action_pressed("move_up")

## Checks if crouch input is pressed
func is_crouch_pressed() -> bool:
	return Input.is_action_pressed("crouch")

## Checks if crouch input is pressed
func is_spin_pressed() -> bool:
	return Input.is_action_pressed("spin")

## Checks if spin input is being held
func is_spin_held() -> bool:
	return Input.is_action_pressed("spin")

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


## Updates wall detection using raycasts
func _update_wall_detection() -> void:
	# var space_state = get_world_2d().direct_space_state
	
	#  wall detection
	is_on_wall_left = wall_collider[0].is_colliding() 
	is_on_wall_right = wall_collider[1].is_colliding() 
	is_in_floor = wall_collider[4].is_colliding()
	is_on_edge = wall_collider[2].is_colliding() and not wall_collider[3].is_colliding() and not is_in_floor
	
	# wall_normal = Vector2.ZERO
	
	# # Check left wall
	# var left_query_top = PhysicsRayQueryParameters2D.create(
	# 	global_position + Vector2(0, wall_check_offset_top),
	# 	global_position + Vector2(-wall_check_distance, wall_check_offset_top)
	# )
	# left_query_top.exclude = [self]
	
	# var left_query_bottom = PhysicsRayQueryParameters2D.create(
	# 	global_position + Vector2(0, wall_check_offset_bottom),
	# 	global_position + Vector2(-wall_check_distance, wall_check_offset_bottom)
	# )
	# left_query_bottom.exclude = [self]
	
	# var left_result_top = space_state.intersect_ray(left_query_top)
	# var left_result_bottom = space_state.intersect_ray(left_query_bottom)
	
	# if left_result_top or left_result_bottom:
	# 	is_on_wall_left = true
	# 	if left_result_top:
	# 		wall_normal = left_result_top.normal
	# 	elif left_result_bottom:
	# 		wall_normal = left_result_bottom.normal

## Checks if player is touching any wall
func _is_on_wall() -> bool:
	return is_on_wall_left or is_on_wall_right

## Gets which wall the player is touching (-1 for left, 1 for right, 0 for none)
func get_wall_direction() -> int:
	if is_on_wall_left:
		return -1
	elif is_on_wall_right:
		return 1
	else:
		return 0

## Checks if player can wall slide (touching wall and falling)
func can_wall_slide() -> bool:
	# return _is_on_wall() and velocity.y > 0 and not is_on_floor()
	return is_on_wall() and not is_on_floor() and not is_down_pressed() and sign(input_direction) == get_wall_direction()

## Checks if the player can perform a wall jump
func can_wall_jump() -> bool:
	# Allow wall jump if touching wall, not on floor, and hasn't used all jumps (including wall jump)
	return _is_on_wall() and not is_on_floor() and jump_count <= max_jumps

func _handle_spin_cooldown(delta):
	if spin_cooldown > 0:
		spin_cooldown -= delta
		if spin_cooldown <= 0:
			can_spin = true
			
func try_spin() -> bool:
	if can_spin:
		can_spin = false
		spin_cooldown = spin_cooldown_time
		return true
	return false
	
## Debug function to print player state
func debug_print_info() -> void:
	print("=== Player Debug ===")
	print("Position: ", global_position)
	print("Velocity: ", velocity)
	print("On Floor: ", is_on_floor())
	print("On Wall: ", is_on_wall(), " Left: ", is_on_wall_left, " Right: ", is_on_wall_right)
	print("Wall Direction: ", get_wall_direction())
	print("Jump Count: ", jump_count)
	print("Input Direction: ", input_direction)
	print("ground above :" , get_ground_distance())
	if state_machine:
		state_machine.debug_print_state_info()

## Updates debug labels with current player and state info
func _update_debug_labels() -> void:
	if !enable_debug:
		return
	
	if debug_label_character:
		var ground_dist = get_ground_distance()
		debug_label_character.text = """
		Player Debug:
		Pos: {global_position}
		Vel: {velocity}
		OnFloor: {is_on_floor()}
		OnWall: {is_on_wall()} B / {_is_on_wall()} C
		OnWall: {is_on_wall_left}L / {is_on_wall_right}R
		JumpCount: {jump_count}/{max_jumps}
		InputDir: {input_direction}
		GroundDist: {ground_dist}
		CanCrash: {can_crashDown}
		""".format({
			"global_position": global_position,
			"velocity": velocity,
			"is_on_floor()": is_on_floor(),
			"is_on_wall()": is_on_wall(),
			"_is_on_wall()": _is_on_wall(),
			"is_on_wall_left": is_on_wall_left,
			"is_on_wall_right": is_on_wall_right,
			"jump_count": jump_count,
			"max_jumps": max_jumps,
			"input_direction": input_direction,
			"ground_dist": "%.2f" % ground_dist if ground_dist != INF else "INF",
			"can_crashDown": can_crashDown
		})
	
	if debug_label_stateMachine and state_machine:
		var current_state_name = state_machine.get_current_state_name()
		var previous_state_name = state_machine.get_previous_state_name()
		var coyote_timer = state_machine.coyote_timer
		var jump_buffered = state_machine.is_jump_buffered()
		debug_label_stateMachine.text = """
		State Machine Debug:
		Current: {current_state_name}
		previous: {previous_state_name}
		edge_grap_enabled: {edge_grap_enabled}
		Coyote: {coyote_timer}
		JumpBuffer: {jump_buffered}
		CanJump: {can_jump}
		CanCrashDown: {can_crash_down}
		""".format({
			"current_state_name": current_state_name if current_state_name != "" else "None",
			"previous_state_name": previous_state_name if previous_state_name != "" else "None",
			"edge_grap_enabled": edge_grap_enabled,
			"coyote_timer": coyote_timer,
			"jump_buffered": jump_buffered,
			"can_jump": can_jump(),
			"can_crash_down": state_machine.can_CrashDown()
		})
