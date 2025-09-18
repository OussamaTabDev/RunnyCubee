# Player State Machine Setup Guide

## Overview
This is a flexible, scalable state machine system for Godot 4.4.1 that automatically discovers states and provides easy state management. The system is designed for platformer games with Rayman Legends-style movement.

## Scene Structure

Create your scene with this hierarchy:
```
Player (CharacterBody2D) [Player.gd attached]
├── CollisionShape2D
├── Sprite2D or AnimationPlayer
└── StateMachine (Node) [StateMachine.gd attached]
    ├── Idle (Node) [IdleState.gd attached]
    ├── Run (Node) [RunState.gd attached] 
    ├── Jump (Node) [JumpState.gd attached]
    ├── Fall (Node) [FallState.gd attached]
    ├── Crouch (Node) [CrouchState.gd attached]
    ├── CrouchJump (Node) [CrouchJumpState.gd attached]
    ├── SlideJump (Node) [SlideJumpState.gd attached]
    ├── CrouchIdleJump (Node) [CrouchIdleJumpState.gd attached]
    ├── AirDodge (Node) [AirDodgeState.gd attached]
    ├── GroundPound (Node) [GroundPoundState.gd attached] (canceled)
    ├── WallJump (Node) [WallJumpState.gd attached]
    ├── Spinning (Node) [SpinningState.gd attached]
    ├── EdgeGrap (Node) [EdgeGrapState.gd attached]
    └── #### (Node) [####State.gd attached] (newsones)
    
```

## Input Map Setup

Configure these actions in your Input Map:
- `move_left` (A, Left Arrow)
- `move_right` (D, Right Arrow)  
- `jump` (Space)
- `crouch` (S, Down Arrow, Ctrl)
- `spin` (D)

## Key Features

### 🔄 Automatic State Discovery
- The StateMachine automatically finds all child nodes that inherit from State
- No need to manually register states in code
- Add new states by simply creating a new Node child and attaching a state script

### 🎯 Easy State Transitions
```gdscript
# From any state, transition by name:
transition_to("Jump")
transition_to("Idle")
```

### ⏰ Built-in Buffers
- **Coyote Time**: Jump shortly after leaving ground (0.15s default)
- **Jump Buffer**: Jump input registers before landing (0.1s default)
- **Variable Jump Height**: Hold/release jump for different heights

### 🎮 Rayman Legends Features
- Air control during jumps and falls
- Sliding when crouching at high speed
- Momentum preservation
- Multiple jump support
- Cut jump for variable height

## Adding New States

1. **Create the State File** (e.g., `WallSlideState.gd`):
```gdscript
extends State
class_name WallSlideState

func _ready():
    state_name = "WallSlide"
    can_move = false  # Can't move horizontally while wall sliding

func on_enter():
    print("Wall sliding!")

func state_physics_process(delta):
    # Your wall slide logic here
    _check_transitions()

func _check_transitions():
    if not _is_on_wall():
        transition_to("Fall")
```

2. **Add to Scene**: Create a new Node child under StateMachine, name it "WallSlide", attach the script

3. **That's it!** The state is automatically discovered and ready to use

## State System API

### State Base Class Methods
```gdscript
# Override these in your states:
func on_enter() -> void          # Called when entering state
func on_exit() -> void           # Called when exiting state  
func state_process(delta) -> void      # Called every frame
func state_physics_process(delta) -> void  # Called every physics frame

# Use these helpers:
transition_to("StateName")       # Change to another state
is_on_floor_buffered(0.1)       # Floor check with coyote time
apply_horizontal_movement(...)    # Standard movement helper
apply_gravity(...)               # Standard gravity helper
```

### StateMachine Methods  
```gdscript
change_state("StateName")        # Change state by name
get_current_state_name()         # Get current state name
has_state("StateName")           # Check if state exists
buffer_jump()                    # Buffer a jump input
is_jump_buffered()              # Check if jump is buffered
```

### Player Controller Methods
```gdscript
get_input_direction()            # Get -1/0/1 input
is_jump_pressed()               # Jump just pressed this frame
is_jump_held()                  # Jump currently held
jump(custom_velocity)           # Execute jump
can_jump()                      # Check if jump available
apply_movement(dir, delta)      # Apply horizontal movement
apply_gravity(delta, multiplier) # Apply gravity
```

## Customization

### Movement Parameters
Adjust these in the Player node:
- `move_speed`: Base movement speed
- `acceleration`: How quickly to reach target speed  
- `friction`: How quickly to stop
- `jump_velocity`: Jump strength
- `gravity_scale`: Gravity multiplier
- `max_fall_speed`: Terminal velocity

### State-Specific Settings
Each state can override:
- `can_move`: Allow horizontal movement
- `has_gravity`: Apply gravity  
- `animation_speed`: Animation speed multiplier

### Wall Detection Parameters
Adjust these in the Player node:
- `wall_check_distance`: How far to check for walls (8.0 default)
- `wall_check_offset_top`: Top raycast offset (-10.0 default) 
- `wall_check_offset_bottom`: Bottom raycast offset (10.0 default)

### Wall Slide Settings
Each wall slide state can customize:
- `max_wall_slide_speed`: Terminal velocity on wall (150 default)
- `wall_slide_gravity`: Gravity multiplier while sliding (0.3 default)
- `max_wall_slide_time`: Max time before auto-fall (3.0s default)

### Buffer Timings
Modify in StateMachine:
- `COYOTE_TIME`: How long after leaving ground you can jump
- `JUMP_BUFFER_TIME`: How long jump input is remembered

## Advanced Usage

### Runtime State Addition
```gdscript
# Load and add states dynamically
var new_state_scene = preload("res://states/CustomState.tscn")
state_machine.add_state_from_scene("Custom", new_state_scene)
```

### State Communication
```gdscript
# States can communicate through the character or state machine
func on_enter():
    var previous = state_machine.previous_state
    if previous and previous.state_name == "Jump":
        # Do something special if we came from jumping
        pass
```

### Debug Information
```gdscript
# Print debug info
player.debug_print_info()
state_machine.debug_print_state_info()
```

## Animation Integration

While animations aren't included, here's how to integrate them:

```gdscript
# In your states:
func on_enter():
    # Play animation based on state name
    character.get_node("AnimationPlayer").play(state_name.to_lower())

# Or use the animation_speed property:
func _ready():
    animation_speed = 1.5  # Play animations 50% faster
```

## Troubleshooting

### State Not Found
- Ensure the node is a direct child of StateMachine
- Check that the script extends State class
- Verify the node name matches what you're calling

### Transitions Not Working
- Make sure you're calling `transition_to()` not direct state changes
- Check state names are spelled correctly (case-sensitive)
- Verify the target state exists in the scene

### Physics Issues  
- Ensure Player is a CharacterBody2D
- Check that move_and_slide() is called in Player._physics_process()
- Verify collision shapes are set up properly

## Performance Notes

- State discovery happens once in `_ready()`
- State transitions are O(1) dictionary lookups
- Only active state processes each frame
- No unnecessary state polling or checking

This system scales well - add as many states as needed without performance impact!