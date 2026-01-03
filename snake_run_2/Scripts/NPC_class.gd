@icon("res://textures/NPC.svg")
extends Node3D
class_name NPC






@export var movement_speed: float = 4.0
@onready var navigation_agent: NavigationAgent3D = get_node("NavigationAgent3D")
var movement_delta: float

	
	
# targeting variables 
var angle :float = 0 
@onready var snake_target :Node3D = null
@onready var skeleton_for_measure :Skeleton3D = get_node("mouse_soldier2/Armature (Mecha g)_002/Skeleton3D")
@onready var skeleton_il :SkeletonIK3D = get_node("mouse_soldier2/Armature (Mecha g)_002/Skeleton3D/SkeletonIK3D")
var hips_integer :int = 0 
var spine_integer :int = 0 
@export var transform_1 :Transform3D 
@export var transform_2 :Transform3D 
@onready var parent :Node3D = get_node("mouse_soldier2")
@onready var tree :AnimationTree = get_node("AnimationTree")
@onready var thing_to_aim :Node3D = get_node("Node3D")




	

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)




func _on_velocity_computed(safe_velocity: Vector3) -> void:
	global_position = global_position.move_toward(global_position + safe_velocity, movement_delta)
	
	
func _process_navigation(delta):
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		return

	movement_delta = movement_speed * delta
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = global_position.direction_to(next_path_position) * movement_delta
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
		
func startup_navigation_ready():
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	
	set_movement_target(Vector3(0,0,0))
	
	
func initialize_targeting():
	for i in skeleton_for_measure.get_bone_count():
		var immediate_name :String = skeleton_for_measure.get_bone_name(i)
		if immediate_name == "Spine":
			hips_integer = i
		if immediate_name == "Chest":
			spine_integer = i
	# 
	skeleton_il.start()
	
	
func run_targeting():
	
	if snake_target == null:
		pass
	else:
	
		transform_1 = skeleton_for_measure.get_bone_global_pose_no_override(hips_integer)
		#transform_2 = skeleton_for_measure.get_bone_global_pose_no_override(spine_integer)
		transform_2 = thing_to_aim.global_transform
		thing_to_aim.look_at(snake_target.global_position, Vector3(0, 1, 0))
		
		var current_angle :float = thing_to_aim.rotation_degrees.y + 180
		
	  

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
	if body is PhysicalBone3D:

		var immediate_bone :PhysicalBone3D = body
		
		var bone_name :String = immediate_bone.bone_name # uhhg I want the name of the bone now , like the bone Name 
		if bone_name.contains("head"):
			snake_target = immediate_bone
