# GroundPoundState.gd

extends State
class_name GroundPoundState

@export var ground_pound_duration: float = 0.2  # Shorter = snappier
@export var bounce_velocity: float = -150.0
@export var simple_jump_velocity: float = -400.0  # Optional: weaker than high jump

var ground_pound_timer: float = 0.0
var has_bounced: bool = false

func _ready() -> void:
	state_name = "GroundPound"
	can_move = false
	has_gravity = false

func on_enter() -> void:
	print("Entering Ground Pound State")
	character.velocity = Vector2.ZERO
	ground_pound_timer = 0.0
	has_bounced = false
	print("GROUND POUND IMPACT!")

	# TODO: Add screen shake, particles, sound

func on_exit() -> void:
	print("Exiting Ground Pound State")

func state_physics_process(delta: float) -> void:
	ground_pound_timer += delta
	character.velocity = Vector2.ZERO  # Keep grounded
	
	_check_transitions()

func _check_transitions() -> void:
	# Optional: Allow simple jump during pound (not buffered — real-time only)
	if not has_bounced and character.is_jump_pressed():
		_execute_simple_jump()
		return
	
	# After duration → bounce
	if ground_pound_timer >= ground_pound_duration and not has_bounced:
		_execute_bounce()
		return

func _execute_simple_jump() -> void:
	print("Simple jump from Ground Pound")
	character.jump(simple_jump_velocity)
	has_bounced = true
	transition_to("Jump")

func _execute_bounce() -> void:
	print("Small bounce from Ground Pound")
	character.jump(bounce_velocity)
	has_bounced = true
	transition_to("Fall")  # Go to fall immediately — no timer