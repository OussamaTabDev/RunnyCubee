# @tool
extends Node2D


@export var flipwith: Array[Node2D] = []
@export var sprite: SpineSprite
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	handle_fliping()
	pass


func handle_fliping():
	if self.scale.x < 0:
		for node in flipwith:
			node.scale.x = abs(scale.x) * -1
	else:
		for node in flipwith:
			node.scale.x = abs(scale.x)
