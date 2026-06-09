extends ColorRect

@export var tint_color: Color = Color(0.9, 0.1, 0.1, 1.0) # red bias

@export var max_alpha: float = 0.35 # cap for visibility; tune to taste

var _intensity: float = 0.0

func _ready() -> void:
	self.color = tint_color
	self.modulate.a = 0.0

	# Call this from your camera script each frame (or export a NodePath and fetch intensity).

		
func set_intensity(i: float) -> void:

	_intensity = clamp(i, 0.0, 1.0)
	self.modulate.a = _intensity * max_alpha


	

	
