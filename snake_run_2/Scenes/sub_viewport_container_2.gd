extends SubViewportContainer
var mouse_event :Vector2


func _input(event: InputEvent) -> void:

	if self.name == "SubViewportContainer2":
		if event is InputEventMouseMotion:
			mouse_event = event.relative.clampf(-89,89)
			
	else:
		pass


func _propagate_input_event(event: InputEvent) -> bool:
	
	return true
