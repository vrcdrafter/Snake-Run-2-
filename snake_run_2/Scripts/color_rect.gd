extends ColorRect

@export var tint_color: Color = Color(0.9, 0.1, 0.1, 1.0) # red bias

@export var max_alpha: float = 0.35 # cap for visibility; tune to taste

var _intensity: float = 0.0

func _ready() -> void:
	self.color = tint_color
	self.modulate.a = 0.0
	game_manager_connect_sripts()
	# Call this from your camera script each frame (or export a NodePath and fetch intensity).
	var name_section :String = self.get_parent().get_parent().get_parent().get_parent().get_parent().name
	if name_section =="controller1":
		print("it was this one ")
		size = Vector2(617,size.y)
		position = Vector2(552,position.y)
		
func set_intensity(i: float) -> void:
	_intensity = clamp(i, 0.0, 1.0)
	self.modulate.a = _intensity * max_alpha


func game_manager_connect_sripts():
	var game_manager = get_tree().root.find_child("Node", true,false)
	var test :String = game_manager.name
	game_manager.connect("player_added",Callable(self,"check_players"))
	
func check_players():
	print("player added . ")
	var name_section :String = self.get_parent().get_parent().get_parent().get_parent().get_parent().name

	
	match name_section:
		"SubViewportContainer2":
			print("it was a controller.")
			size = Vector2(617,size.y)

	
