

extends Node3D

var angle :float = 0 

@onready var snake_target :Node3D = get_node("/root/Node/Snake/BoneAttachment3D/tounge_1")

@onready var skeleton_for_measure :Skeleton3D = get_node("../mouse_soldier2/Armature (Mecha g)_002/Skeleton3D")


var hips_integer :int = 0 
var spine_integer :int = 0 

@export var transform_1 :Transform3D 
@export var transform_2 :Transform3D 

@onready var orientation :Node3D = get_node("../mouse_soldier2")



@onready var parent :Node3D = get_node("../mouse_soldier2")

@onready var tree :AnimationTree = get_node("../AnimationTree")

@onready var detection_area :Area3D = get_node("../Detection")


	
func _ready() -> void:
	

	
	for i in skeleton_for_measure.get_bone_count():
		var immediate_name :String = skeleton_for_measure.get_bone_name(i)
		if immediate_name == "Spine":
			hips_integer = i
		if immediate_name == "Chest":
			spine_integer = i
	# 
	
	



func _process(delta: float) -> void:
	
	transform_1 = skeleton_for_measure.get_bone_global_pose_no_override(hips_integer)
	#transform_2 = skeleton_for_measure.get_bone_global_pose_no_override(spine_integer)
	transform_2 = self.global_transform
	self.look_at(snake_target.global_position, Vector3(0, 1, 0))
	
	var current_angle :float = self.rotation_degrees.y + 180
	
  

	if current_angle > 45 and current_angle <= 135 :
		parent.set_rotation_degrees(Vector3(0,90,0)) 
		tree.set("parameters/BlendSpace2D/blend_position", Vector2(-1, 0))
	elif current_angle > 135 and current_angle <= 225 :
		
		parent.set_rotation_degrees(Vector3(0,180,0)) 
		tree.set("parameters/BlendSpace2D/blend_position", Vector2(0, -1))
		
	elif current_angle > 225 and current_angle <= 315 :
		parent.set_rotation_degrees(Vector3(0,270,0)) 
		tree.set("parameters/BlendSpace2D/blend_position", Vector2(1, 0))
		
	elif current_angle > 315 or current_angle <= 45 :
		parent.set_rotation_degrees(Vector3(0,0,0)) 
		tree.set("parameters/BlendSpace2D/blend_position", Vector2(0, 1))
	else:
		pass
		


func _on_detection_body_entered(body: Node3D) -> void:
	var body_detected :String = body.name
	var body_parent :String = body.get_parent().get_parent().name
	var body_parent2 :String = body.get_parent().get_parent().get_parent().name
	var body_parent3 :String = body.get_parent().get_parent().get_parent().get_parent().get_parent().name
	print(body_detected)
