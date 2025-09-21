# EdgeGrapState.gd
# Player edge grab state - handles grabbing ledges and climbing up
# This should be attached to a child node of StateMachine named "EdgeGrap"

extends State
class_name EdgeGrapState



func _ready() -> void:
	state_name = "EdgeGrap"
	

func on_enter() -> void:
	character.edge_grap_enabled = true
	# var wall_direction = character.get_wall_direction()
	#character.velocity = Vector2.ZERO
	#character.velocity.x = 150 * wall_direction

	print("Entering Jump State")

	
	
	

func on_exit() -> void:
	character.edge_grap_enabled = false
	print("Exiting Jump State")

func state_physics_process(delta: float) -> void:
	
	character.apply_gravity(delta)
	# Check for state transitions
	_check_transitions()

	

func _check_transitions() -> void:
	# Check for air dodge (down input while in air)
	# if character.is_crouch_pressed() and character.velocity.y > -100:  # Don't dodge at peak of jump
	
	if character.is_down_pressed() or not character.is_on_edge:
		# Check for wall slide (if touching wall and starting to fall)
		if character.can_wall_slide():
			transition_to("WallSlide")
			return
		# Check if we've started falling or lost the edge
		
		transition_to("Fall")
		return


	
		
	
	
	
	# Check for wall jump (if touching wall while jumping)
	if character.is_jump_pressed() and character.can_wall_jump():
		transition_to("WallJump")
		return

	# Check for double jump or multi-jump
	if character.is_jump_pressed() and character.can_jump():
		# Stay in jump state but execute another jump
		character.jump()
		transition_to("Jump")
		return
