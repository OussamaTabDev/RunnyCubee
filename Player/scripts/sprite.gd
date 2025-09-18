extends Sprite2D


@export var flipwith: Array[Node2D] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func handle_fliping():
	if self.flip_h:
		for node in flipwith:
			node.scale.x = abs(scale.x) * -1
	else:
		for node in flipwith:
			node.scale.x = abs(scale.x)