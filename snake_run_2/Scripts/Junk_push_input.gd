extends SubViewport



func _input(event: InputEvent) -> void:
	
	print("viewport event ",event)
	self.push_input(event)
