# SpinningState.gd
# Rayman/Crash-style spinning state - provides speed boost, extended air time, and special abilities
# Allows jump to CANCEL spin mid-air (like Crash Twinsanity)
# Respects jump buffer and coyote time for maximum responsiveness
# This should be attached to a child node of StateMachine named "Spinning"

extends State
class_name SpinningState

## Duration of the spin in seconds
@export var spin_duration: float = 0.4
## Speed multiplier during spin (ground movement)
@export var ground_speed_multiplier: float = 1.8
## Air speed multiplier during spin
@export var air_speed_multiplier: float = 1.5
## Reduced gravity during spin for extended air time
@export var spin_gravity_multiplier: float = 0.6
## Maximum fall speed during spin (slower than normal)
@export var max_spin_fall_speed: float = 200.0
## Horizontal momentum boost when spin starts
@export var initial_momentum_boost: float = 100.0
## Whether spin can be extended by holding the button
@export var can_extend_spin: bool = true
## Maximum extended spin duration
@export var max_extended_duration: float = 0.8

var spin_timer: float = 0.0
var was_airborne_on_enter: bool = false
var initial_direction: float = 0.0
var momentum_applied: bool = false

func _ready() -> void:
	state_name = "Spinning"
	can_move = true
	has_gravity = true  # We handle gravity manually with multiplier

func on_enter() -> void:
	print("🌀 Entering Spinning State")
	
	# Store initial state
	was_airborne_on_enter = not character.is_on_floor()
	initial_direction = character.get_input_direction()
	spin_timer = 0.0
	momentum_applied = false
	
	# Apply initial momentum boost in current movement direction
	if abs(character.velocity.x) > 50 or abs(initial_direction) > 0.1:
		var boost_direction = initial_direction if abs(initial_direction) > 0.1 else sign(character.velocity.x)
		character.velocity.x += boost_direction * initial_momentum_boost
		momentum_applied = true
	
	print("Spin started - Airborne: ", was_airborne_on_enter, " Direction: ", initial_direction)

func on_exit() -> void:
	print("🌀 Exiting Spinning State")
	spin_timer = 0.0

func state_physics_process(delta: float) -> void:
	spin_timer += delta
	
	# Apply modified gravity for extended air time
	if not character.is_on_floor():
		character.apply_gravity(delta, spin_gravity_multiplier)
		# Cap fall speed for floaty feeling
		character.velocity.y = min(character.velocity.y, max_spin_fall_speed)
	
	# Handle horizontal movement with speed boost
	_handle_spin_movement(delta)
	
	# Check for state transitions — including jump cancel!
	_check_transitions()

func _handle_spin_movement(delta: float) -> void:
	var input_dir = character.get_input_direction()
	
	# Choose speed multiplier based on ground/air state
	var speed_mult = ground_speed_multiplier if character.is_on_floor() else air_speed_multiplier
	var boosted_speed = character.move_speed * speed_mult
	var boosted_acceleration = character.acceleration * speed_mult
	
	if input_dir != 0:
		# Apply movement with speed boost
		character.velocity.x = move_toward(character.velocity.x, input_dir * boosted_speed, boosted_acceleration * delta)
	else:
		# Reduce friction during spin to maintain momentum
		var reduced_friction = character.friction * 0.3
		character.velocity.x = move_toward(character.velocity.x, character.velocity.x, reduced_friction * delta)

func _check_transitions() -> void:
	# Allow jump to interrupt spin at ANY TIME while airborne
	# Respects jump buffer and coyote time for maximum responsiveness
	if not character.is_on_floor() and _can_jump_now():
		character.jump()  # ✅ Use standardized jump (handles velocity + jump count)
		transition_to("Jump")
		return  # Exit early — spin is canceled!

	if character.is_on_floor() and character.is_jump_pressed() :
		character.jump()  # ✅ Use standardized jump (handles velocity + jump count)
		transition_to("Jump")
		return  # Exit early — spin is canceled!
	
	# Check for extended spin duration (if holding spin button)
	var current_max_duration = spin_duration
	if can_extend_spin and character.is_spin_held():
		current_max_duration = max_extended_duration
	
	# End spin after full duration
	if spin_timer >= current_max_duration:
		_end_spin()
		return
	
	# Allow early spin end by releasing button (must hold at least half duration)
	if not character.is_spin_held() and spin_timer >= spin_duration * 0.5:
		_end_spin()
		return
	
	# Update airborne/grounded tracking for transitions
	if was_airborne_on_enter and character.is_on_floor() and spin_timer > 0.1:
		was_airborne_on_enter = false  # Landed during spin
	
	if not was_airborne_on_enter and not character.is_on_floor():
		was_airborne_on_enter = true   # Left ground during spin

## Ends spin naturally (not interrupted by jump)
func _end_spin() -> void:
	if character.is_on_floor():
		# Transition to ground states
		if _can_jump_now():
			character.jump()
			transition_to("Jump")
			return
		if abs(character.get_input_direction()) > 0.1:
			character.velocity.x /= 3  # Reduce speed for smoother transition
			transition_to("Run")
			return
		else:
			transition_to("Idle")
			return
	else:
		# In air — check if we can jump via buffer/coyote/current press
		if _can_jump_now():
			character.jump()  # ✅ Again, use standardized jump
			transition_to("Jump")
			return
		else:
			transition_to("Fall")
			return

## Helper: Returns true if jump can be performed NOW
## (current press, jump buffer, or coyote time)
## Automatically consumes jump buffer if used
func _can_jump_now() -> bool:
	# Direct jump input
	if character.is_jump_pressed():
		return true
	
	# Buffered jump (pressed just before or during spin)
	if state_machine.is_jump_buffered():
		state_machine.consume_jump_buffer()  # Prevent reuse
		return true
	
	# Coyote time (just left ground)
	if state_machine.is_on_floor_buffered():
		return true
	
	return false

## Gets the remaining spin time
func get_remaining_spin_time() -> float:
	var max_time = max_extended_duration if (can_extend_spin and character.is_spin_held()) else spin_duration
	return max(0.0, max_time - spin_timer)

## Checks if the spin is in extended mode
func is_extended_spin() -> bool:
	return can_extend_spin and character.is_spin_held() and spin_timer > spin_duration