@tool
extends Skeleton3D

var head :int

@onready var target_1 :Marker3D = get_node("../../../Marker3D")
var target

var rotation_basis = Basis(Vector3(1, 0, 0), deg_to_rad(90))
func _ready() -> void:
	
	head  = self.find_bone("Bone.013")
	
	


# Create a rotation basis (90° around X axis)



func _process(delta: float) -> void:
	target = target_1.global_position
	var headRotation : Transform3D = get_bone_global_pose_no_override(head) 
	# Calculate look at as you want...
	headRotation = headRotation.looking_at(target)  # possibly with some tweaks based on your model
	
	# Set global pose override to your head bone
	var correction = Basis(Vector3.UP, deg_to_rad(90))
	headRotation.basis = headRotation.basis * correction
	set_bone_global_pose_override(head, headRotation, 1.0, true)
	
