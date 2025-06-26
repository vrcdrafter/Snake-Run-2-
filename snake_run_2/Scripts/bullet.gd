extends MeshInstance3D


func _physics_process(delta: float) -> void:
	var forward = self.transform.basis.z
	translate(Vector3(0,1,0) * 1 * delta)
