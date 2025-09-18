# SpinningState.gd
# Player spinning state - gives temporary speed boost, like Rayman's dash/spin
# Attach to a child node named "Spinning" under StateMachine

extends State
class_name SpinningStatek

## Duration of the spin in seconds
@export var spin_duration: float = 0.3
## Speed multiplier during spin (e.g., 2.0 = double speed)
@export var speed_multiplier: float = 2.0
## Whether to disable gravity during spin (optional)
@export var disable_gravity: bool = false

var timer: float = 0.0
var original_move_speed: float  # To restore after spin

func _ready() -> void:
    state_name = "Spinning"
    can_move = true  # Allow player to steer during spin
    has_gravity = !disable_gravity  # Toggle gravity based on setting

func on_enter() -> void:
    print("🌀 Entering Spinning State")
    
    # Store original speed to restore later
    original_move_speed = character.move_speed
    character.move_speed *= speed_multiplier
    
    # Optional: Play spin animation or sound
    # character.get_node("AnimationPlayer").play("spin")
    # character.get_node("AudioPlayer").play("spin_sound")
    
    timer = 0.0

func on_exit() -> void:
    print("🌀 Exiting Spinning State")
    # Restore original movement speed
    character.move_speed = original_move_speed
    
    timer = 0.0
    # Optional: Reset animation
    # character.get_node("AnimationPlayer").play("idle")

func state_physics_process(delta: float) -> void:
    timer += delta
    
    # Apply gravity if enabled
    if has_gravity:
        character.apply_gravity(delta)
    
    # Apply horizontal movement (with boosted speed)
    var input_dir = character.get_input_direction()
    if can_move and input_dir != 0:
        character.apply_movement(input_dir, delta)
    elif can_move:
        # Apply friction if no input
        character.velocity.x = move_toward(character.velocity.x, 0, character.friction * delta)
    
    # Check transitions
    _check_transitions()

func _check_transitions() -> void:
    # End spin after duration
    if timer >= spin_duration:
        if character.is_on_floor():
            if abs(character.get_input_direction()) > 0.1:
                transition_to("Run")
            else:
                transition_to("Idle")
        else:
            transition_to("Fall")
        return
    
    # Optional: Allow canceling spin early with crouch or jump
    # if character.is_crouch_pressed():
    #     transition_to("Crouch")
    #     return
    
    # If landed during spin
    # if character.is_on_floor() and timer > 0.05:  # Small buffer to avoid immediate transition
    #     if abs(character.get_input_direction()) > 0.1:
    #         transition_to("Run")
    #     else:
    #         transition_to("Idle")
    #     return

    # If left ground during spin (e.g., ran off ledge)
    if not character.is_on_floor() and character.velocity.y > 0:
        transition_to("Fall")
        return