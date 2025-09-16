# JumpState.gd
# Player jump state - handles jumping mechanics, variable height, and air control
# This should be attached to a child node of StateMachine named "Jump"

extends State
class_name JumpState

## Air control multiplier (how much control player has in air)
@export var air_control: float = 0.8
## Time window for variable jump height
@export var variable_jump_time: float = 0.2

var jump_timer: float = 0.0
var can_variable_jump: bool = true

func _ready() -> void:
	state_name = "Jump"
	# Usually can't move as much in air, but still some control
	can_move = true

func on_enter() -> void:
	print("Entering Jump State")
	
	# Execute the jump
	character.jump()
	
	# Reset jump timer for variable height
	jump_timer = 0.0
	can_variable_jump = true

func on_exit() -> void:
	print("Exiting Jump State")

func state_physics_process(delta: float) -> void:
	# Update jump timer
	jump_timer += delta
	
	# Apply gravity
	character.apply_gravity(delta)
	
	# Handle variable jump height
	_handle_variable_jump()
	
	# Handle horizontal movement with air control
	var input_dir = character.get_input_direction()
	if can_move:
		# Apply reduced acceleration in air
		var air_acceleration = character.acceleration * air_control
		var air_friction = character.friction * air_control
		
		if input_dir != 0:
			character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed, air_acceleration * delta)
		else:
			character.velocity.x = move_toward(character.velocity.x, character.velocity.x, air_friction * delta)
	
	# Check for state transitions
	_check_transitions()

func _handle_variable_jump() -> void:
	# Allow jump cutting for variable height
	if can_variable_jump and jump_timer < variable_jump_time:
		if character.is_jump_released() and character.velocity.y < 0:
			character.cut_jump()
			can_variable_jump = false

func _check_transitions() -> void:
	# Check for air dodge (down input while in air)
	# if character.is_crouch_pressed() and character.velocity.y > -100:  # Don't dodge at peak of jump
	if character.is_crouch_pressed() and state_machine.can_CrashDown() :  # Don't dodge at peak of jump
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
	
	# Check for double jump or multi-jump
	if character.is_jump_pressed() and character.can_jump():
		# Stay in jump state but execute another jump
		character.jump()
		jump_timer = 0.0
		can_variable_jump = true
