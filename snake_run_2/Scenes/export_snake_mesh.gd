extends MeshInstance3D
var bulge_pos := 1.0
var animate_bulge := false

@onready var mesh_instance :MeshInstance3D = self
@onready var skin_material : Material = mesh_instance.get_surface_override_material(0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	skin_material.set_shader_parameter("bulge_size", 0.2)
	skin_material.set_shader_parameter("bulge_amount", 5.0)
	skin_material.set_shader_parameter("bulge_pos", 1.0)
	

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		bulge_pos = 1.0
		animate_bulge = true
	if animate_bulge:
		move_shape(delta)





func move_shape(delta: float) -> void:

	bulge_pos = lerp(bulge_pos, 0.27, 1.0 * delta)

	skin_material.set_shader_parameter("bulge_size", 0.08)
	skin_material.set_shader_parameter("bulge_amount", 3.0)
	skin_material.set_shader_parameter("bulge_pos", bulge_pos)
