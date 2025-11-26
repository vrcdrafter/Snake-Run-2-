extends Label





func _process(delta):
	var fps = Engine.get_frames_per_second()
	text = "FPS: %d" % fps
	if fps < 30:
		add_theme_color_override("font_color", Color.RED)
	else:
		add_theme_color_override("font_color", Color.GREEN)
