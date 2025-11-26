
extends Skeleton3D

var head :int

@onready var target_1 :Marker3D = get_node("../../../Marker3D")
var target

var rotation_basis = Basis(Vector3(1, 0, 0), deg_to_rad(90))


var look_at_player :bool = false
var look_at_target :Area3D
var self_transform :Node3D
func _ready() -> void:
	
	head  = self.find_bone("Bone.013")
	self_transform = get_node("../../..")
	


# Create a rotation basis (90° around X axis)



func _process(delta: float) -> void:
	
	if look_at_player:
		
		var new_transform_point :Vector3 = self_transform.to_local(look_at_target.global_position)
		var new_transform2: Transform3D = Transform3D.IDENTITY
		new_transform2.origin = new_transform_point
		
		var new_transform = new_transform2 * self_transform.global_transform
		
		


		var headRotation : Transform3D = get_bone_global_pose_no_override(head) 
		# Calculate look at as you want...
		headRotation = headRotation.looking_at(new_transform_point) # possibly with some tweaks based on your model
		
		# Set global pose override to your head bone
		var correction = Basis(Vector3.UP, deg_to_rad(90))
		headRotation.basis = headRotation.basis * correction
		set_bone_global_pose_override(head, headRotation, 1.0, true)
	else: 
		clear_bones_global_pose_override()




func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player_ai_area"):
		print("found you ", area.name)
		look_at_player = true
		look_at_target = area


func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player_ai_area"):
		look_at_player = false
