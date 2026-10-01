extends MeshInstance3D
var one_shot :bool = true
var distance_to_floor 
@onready var child_ray :RayCast3D = get_child(0)
func _process(delta: float) -> void:
	if child_ray.is_colliding() and one_shot:
		var hit_pos = child_ray.get_collision_point()
		distance_to_floor = self.global_position.y - hit_pos.y
		one_shot = false
