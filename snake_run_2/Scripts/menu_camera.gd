@tool
extends Camera3D


@onready var point_area :Marker3D = get_node("../../../Marker3D")

func _process(delta: float) -> void:
	
	if point_area:
		look_at(point_area.global_transform.origin, Vector3.UP)
