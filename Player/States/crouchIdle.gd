# CrouchState.gd
# Player crouch state - handles crouching, sliding, and low-profile movement
# This should be attached to a child node of StateMachine named "Crouch"

extends State
class_name CrouchState

## Movement speed while crouching
@export var crouch_speed_multiplier: float = 0.5
## Friction while sliding
@export var slide_friction: float = 100.0
## Minimum speed to maintain slide
@export var min_slide_speed: float = 100.0
## Whether we're currently sliding
var is_sliding: bool = false

func _ready() -> void:
	state_name = "Crouch"
	can_move = true

func on_enter() -> void:
	print("Entering Crouch State")
	
	# Determine if we should slide based on current speed
	if abs(character.velocity.x) > min_slide_speed:
		is_sliding = true
	else:
		is_sliding = false
	
	# TODO: Adjust collision shape for crouching
	# You would typically make the collision shape shorter here

func on_exit() -> void:
	print("Exiting Crouch State")
	is_sliding = false
	
	# TODO: Reset collision shape to normal size
	# Check if there's enough room to stand up before actually transitioning

func state_physics_process(delta: float) -> void:
	# Apply gravity
	character.apply_gravity(delta)
	
	# Handle movement based on whether we're sliding or crouching
	if is_sliding:
		_handle_sliding(delta)
	else:
		_handle_crouching(delta)
	
	# Check for state transitions
	_check_transitions()

func _handle_sliding(delta: float) -> void:
	# Apply slide friction
	if abs(character.velocity.x) > min_slide_speed:
		var friction_direction = -sign(character.velocity.x)
		character.velocity.x += friction_direction * slide_friction * delta
	else:
		# Stop sliding when speed gets too low
		is_sliding = false

func _handle_crouching(delta: float) -> void:
	# Handle slow crouched movement
	var input_dir = character.get_input_direction()
	var crouch_speed = character.move_speed * crouch_speed_multiplier
	var crouch_acceleration = character.acceleration * crouch_speed_multiplier
	
	if input_dir != 0:
		character.velocity.x = move_toward(character.velocity.x, input_dir * crouch_speed, crouch_acceleration * delta)
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, character.friction * delta)

func _check_transitions() -> void:
	# Check for crouch jumping with different behaviors
	if character.is_jump_pressed() and character.can_jump():
		if is_sliding:
			# Sliding jump: small jump with forward momentum
			transition_to("SlideJump")
			return
		else:
			# Idle crouch jump: small vertical jump
			transition_to("CrouchIdleJump")
			return
	
	# Check if we should stop crouching
	if not character.is_crouch_pressed():
		# TODO: Check if there's room to stand up
		if _can_stand_up():
			# Determine next state
			if abs(character.get_input_direction()) > 0.1:
				transition_to("Run")
			else:
				transition_to("Idle")
		return
	
	# Check if we're falling
	if character.velocity.y > 50 and not character.is_on_floor():
		transition_to("Fall")
		return
	
	# If we were sliding and stopped, transition to regular crouch behavior
	if is_sliding and abs(character.velocity.x) <= min_slide_speed:
		is_sliding = false

## Checks if the player can stand up (no obstacles above)
## TODO: Implement actual collision checking
func _can_stand_up() -> bool:
	# This should do a collision check above the player
	# For now, always return true
	return true

## Gets whether the player is currently sliding
func get_is_sliding() -> bool:
	return is_sliding