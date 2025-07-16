extends SubViewportContainer
@export var mouse_event :Vector2

func _input(event: InputEvent) -> void:
	if self.name == "SubViewportContainer2":
		if event is InputEventMouseMotion:
			mouse_event = event.relative
			print("still taking mouse event ", mouse_event)
	else:
		pass


func _propagate_input_event(event: InputEvent) -> bool:
	
	return true
