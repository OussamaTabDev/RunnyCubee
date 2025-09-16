# AirDodgeState.gd

class_name AirDodgeState extends State

@export var dodge_velocity: float = 800.0
@export var dodge_duration: float = 0.4
@export var dodge_air_control: float = 0.0
@export var can_cancel_dodge: bool = true

var dodge_timer: float = 0.0
var dodge_started: bool = false
var jump_buffered: bool = false  # Local buffer — no need for character-wide if only used here

func _ready() -> void:
	state_name = "AirDodge"
	can_move = true
	has_gravity = false

func on_enter() -> void:
	print("Entering Air Dodge State")
	character.velocity.y = dodge_velocity
	character.velocity.x = 0
	dodge_timer = 0.0
	dodge_started = true
	jump_buffered = false  # Reset on enter

func on_exit() -> void:
	print("Exiting Air Dodge State")
	dodge_started = false

func state_physics_process(delta: float) -> void:
	dodge_timer += delta
	
	if dodge_started:
		character.velocity.y = dodge_velocity
	
	# Horizontal control
	var input_dir = character.get_input_direction()
	if can_move and input_dir != 0:
		var air_acceleration = character.acceleration * dodge_air_control
		character.velocity.x = move_toward(character.velocity.x, input_dir * character.move_speed * 0.3, air_acceleration * delta)
	
	# Buffer jump if pressed (even if not canceling)
	if character.is_jump_pressed():
		jump_buffered = true
	
	# Early cancel (optional)
	if can_cancel_dodge and jump_buffered:
		transition_to("Fall")
		return
	
	_check_transitions()

func _check_transitions() -> void:
	# Check if we landed
	if character.is_on_floor():
		character.reset_jumps()

	# 🚨 CRITICAL: On landing, immediately high jump if buffered
	if character.is_on_floor():
		if abs(character.get_input_direction()) > 0.1:
			transition_to("Run")
		else:
			transition_to("Idle")
		return
	
	# Check for coyote time jump
	if character.is_jump_pressed() or state_machine.is_jump_buffered():
		if state_machine.is_on_floor_buffered():
			if state_machine.is_jump_buffered():
				state_machine.consume_jump_buffer()
			transition_to("Jump")
			return

	# Timeout → fall
	if dodge_timer >= dodge_duration:
		transition_to("Fall")
		return



## Handles buffered jump from state machine
func handle_buffered_jump() -> void:
	if state_machine.coyote_timer < state_machine.COYOTE_TIME or character.can_jump():
		state_machine.consume_jump_buffer()
		transition_to("Jump")