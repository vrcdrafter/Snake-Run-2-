extends MeshInstance3D


func _physics_process(delta: float) -> void:

	translate(Vector3(1,0,0) * 150 * delta)


func _on_timer_timeout() -> void:
	get_parent().queue_free()
