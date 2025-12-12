extends MeshInstance3D

var material1 :StandardMaterial3D = null
var time: float = 0.0

func _ready() -> void:
	
	material1 = self.get_surface_override_material(0)

func _process(delta: float) -> void:
	
	time += delta
	var oscillation = sin(time * 2.0) * 0.02  # 2.0 controls speed, 0.1 is amplitude
	material1.uv1_offset = Vector3(0,oscillation,0)
