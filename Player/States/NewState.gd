# NewState.gd
extends State
class_name NewState

func _init():
    can_move = true
    has_gravity = true
    movement_speed_multiplier = 1.0
    can_be_interrupted = true

func state_process(delta: float):
    super.state_process(delta)
    # Your state logic here
    _check_transitions()

func on_enter():
    super.on_enter()
    # State entry logic

func on_exit():
    super.on_exit()
    # State exit logic

func _check_transitions():
    # Define when to transition to other states
    if some_condition:
        change_state("OtherState")