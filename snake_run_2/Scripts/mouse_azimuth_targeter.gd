@tool

extends Node3D



@onready var snake_target :Marker3D = get_node("../snake_head")

func _process(delta: float) -> void:
	
	
	self.look_at(snake_target.global_position, Vector3(0, 1, 0))
