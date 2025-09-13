# State.gd
# Base class for all player states in the state machine system
# Provides common functionality and interface for all states

extends Node
class_name State

## Whether the character can move horizontally in this state
@export var can_move: bool = true
## Whether gravity should be applied in this state
@export var has_gravity: bool = true
## Animation speed multiplier for this state
@export var animation_speed: float = 1.0

## Name identifier for this state
var state_name: String
## Reference to the character controller
var character: CharacterBody2D
## Reference to the state machine managing this state
var state_machine: StateMachine

## Called when the state becomes active
func on_enter() -> void:
	pass

## Called when the state becomes inactive
func on_exit() -> void:
	pass

## Called every frame while the state is active
## @param delta: Time elapsed since last frame
func state_process(delta: float) -> void:
	pass

## Called every physics frame while the state is active
## @param delta: Physics time step
func state_physics_process(delta: float) -> void:
	pass

## Transitions to a new state by name
## @param new_state_name: Name of the state to transition to
func transition_to(new_state_name: String) -> void:
	if state_machine:
		state_machine.change_state(new_state_name)

## Helper function to check if character is on floor with coyote time
## @param coyote_buffer: Time in seconds to allow jump after leaving ground
func is_on_floor_buffered(coyote_buffer: float = 0.1) -> bool:
	return character.is_on_floor() or state_machine.coyote_timer < coyote_buffer

## Helper function to apply horizontal movement
## @param direction: Movement direction (-1 for left, 1 for right, 0 for none)
## @param speed: Movement speed
## @param acceleration: How quickly to reach target speed
## @param friction: How quickly to slow down when no input
## @param delta: Time step
func apply_horizontal_movement(direction: float, speed: float, acceleration: float, friction: float, delta: float) -> void:
	if not can_move:
		return
		
	if direction != 0:
		character.velocity.x = move_toward(character.velocity.x, direction * speed, acceleration * delta)
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, friction * delta)

## Helper function to apply gravity
## @param gravity_scale: Multiplier for gravity strength
## @param max_fall_speed: Terminal velocity
## @param delta: Time step
func apply_gravity(gravity_scale: float, max_fall_speed: float, delta: float) -> void:
	if not has_gravity:
		return
		
	if not character.is_on_floor():
		character.velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale * delta
		character.velocity.y = min(character.velocity.y, max_fall_speed)

func get_previous_state() -> String:
	return state_machine.previous_state.state_name if state_machine.previous_state else "None"
