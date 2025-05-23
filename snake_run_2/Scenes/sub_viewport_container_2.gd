extends SubViewportContainer
@export var mouse_event :Vector2

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_event = event.relative
		print("top_mouse_event",mouse_event)
		


func _propagate_input_event(event: InputEvent) -> bool:
	
	return true
