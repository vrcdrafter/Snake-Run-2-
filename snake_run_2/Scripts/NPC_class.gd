@icon("res://textures/NPC.svg")
extends Node3D
class_name NPC

var AI_STATE :String = "patrol"




@export var movement_speed: float = 9
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
var bullet_scene :PackedScene = preload("res://Scenes/bullet.tscn")
var turn_speed := 6.0  # higher = snappier turnin
@onready var test_target = get_node("MeshInstance3D")
var enemy_array :Array[Node3D] = []
@onready var text_diag :Label3D = get_node("Label3D")

var shooting_timer :float = 1.3
var shooting_accumulator :float = 0 

@onready var player = get_node("/root/Node/GridContainer/SubViewportContainer2/SubViewport/Player")

# Velocity stuff
var velocity = Vector3.ZERO
var last_position = Vector3.ZERO

# signal variables 

var player_ensnared :Node3D
var position_ensnared :Vector3
var snake_that_died :Node3D
var target_snake_was_after :Node3D
var the_ensnare_state :String
var der_tounge :Node3D


var is_ensnared :bool = false

var previous_thing_ensnared :Node3D
var current_thing_ensnared :Node3D

var snake_strength :float = 0 
var health_hurt_speed :float = 0 

@onready var detection_area :Area3D = get_node("Detection")

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
	
	# Compute desired travel direction (ignore vertical)
	var to_target: Vector3 = next_path_position - global_position
	to_target.y = 0.0
	# If we have a direction, rotate yaw toward it
	if to_target.length() > 0.001:
		# Godot's "forward" is -Z, so yaw is atan2(x, z)
		var target_yaw := atan2(to_target.x, to_target.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
	
	
	var new_velocity: Vector3 = global_position.direction_to(next_path_position) * movement_delta
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
		
		
func startup_navigation_ready():
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	
	set_movement_target(player.global_position)
	
	
func initialize_targeting():
	for i in skeleton_for_measure.get_bone_count():
		var immediate_name :String = skeleton_for_measure.get_bone_name(i)
		if immediate_name == "Spine":
			hips_integer = i
		if immediate_name == "Chest":
			spine_integer = i
	# 
	skeleton_il.start()
	
	
func run_targeting(delta :float) -> bool:
	
	# check_velocity . 
	
	velocity = (global_position - last_position) / delta
	last_position = global_position
	
	
	
	
	if enemy_array.size() == 0: 
		skeleton_il.stop()
		parent.set_rotation_degrees(Vector3(0,0,0)) 

		
		if velocity.length() == 0:
			tree.set("parameters/Add2/add_amount", 0.0)
			return false
		else:
			tree.set("parameters/Add2/add_amount", 1.0)
			tree.set("parameters/BlendSpace2D/blend_position", Vector2(-1, 0))
			return false
		
		
		
		
	else:
		
		
		shooting_accumulator += delta
		if shooting_accumulator > shooting_timer:
			spawn_bullet(delta)
			tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			shooting_accumulator = 0
		
		
		
		skeleton_il.start()
		transform_1 = skeleton_for_measure.get_bone_global_pose_no_override(hips_integer)
		#transform_2 = skeleton_for_measure.get_bone_global_pose_no_override(spine_integer)
		transform_2 = thing_to_aim.global_transform
		thing_to_aim.look_at(enemy_array[0].global_position, Vector3(0, 1, 0))
		
		var current_angle :float = thing_to_aim.rotation_degrees.y + 180
		if velocity.length() == 0:
			tree.set("parameters/Add2/add_amount", 0.0)
			return true
		else:
			tree.set("parameters/Add2/add_amount", 1.0)
			if current_angle > 45 and current_angle <= 135 :
				parent.set_rotation_degrees(Vector3(0,90,0)) 
				tree.set("parameters/BlendSpace2D/blend_position", Vector2(-1, 0))
				return true
			elif current_angle > 135 and current_angle <= 225 :
				
				parent.set_rotation_degrees(Vector3(0,180,0)) 
				tree.set("parameters/BlendSpace2D/blend_position", Vector2(0, -1))
				return true
				
			elif current_angle > 225 and current_angle <= 315 :
				parent.set_rotation_degrees(Vector3(0,270,0)) 
				tree.set("parameters/BlendSpace2D/blend_position", Vector2(1, 0))
				return true
				
			elif current_angle > 315 or current_angle <= 45 :
				parent.set_rotation_degrees(Vector3(0,0,0)) 
				tree.set("parameters/BlendSpace2D/blend_position", Vector2(0, 1))
				return true
			else:
				tree.set("parameters/BlendSpace2D/blend_position", Vector2(1, 0))
				return false
			
			
func spawn_bullet(delta :float):
	
	
	var bullet_instance :Node3D = bullet_scene.instantiate()


	var pt1 :Marker3D = get_node("mouse_soldier2/Armature (Mecha g)_002/Skeleton3D/BoneAttachment3D/MeshInstance3D/Marker3D")

	var transform_end_of_gun :Transform3D = pt1.global_transform

	bullet_instance.global_transform = transform_end_of_gun
	
	get_tree().root.add_child(bullet_instance)
	

			


			
			
func _on_detection_area_entered(area: Area3D) -> void:
	var area_name :String = area.name
	if area_name.contains("hitbox1"):
	
		enemy_array.append(area)
		
func _on_detection_area_exited(area: Area3D) -> void:
	var area_name :String = area.name
	if area_name.contains("hitbox1"):
		enemy_array.erase(area)
		
		
func remake_connections():
	
	var all_snakes :Array = get_tree().get_nodes_in_group("snake")
	


	var callable_ensnare = Callable(self, "_on_snake_ensnared")
	var callable_stunned_snake :Callable = Callable(self, "_snake_stunned")
	var callable_changed_target = Callable(self,"turn_off_ensnared")
	var callable_dead_snake = Callable(self,"turn_off_ensnared")
	var test
	var test2
	
	for n in all_snakes:
	
		if not n.is_connected("ensnared",callable_ensnare.bind([player_ensnared,position_ensnared,snake_strength,health_hurt_speed,test])):
			n.connect("ensnared",callable_ensnare.bind([player_ensnared,position_ensnared,snake_strength,health_hurt_speed,test]))
			n.connect("dead_snake",callable_dead_snake.bind([snake_that_died,test]))
			n.connect("let_go_prey",callable_changed_target.bind([previous_thing_ensnared,current_thing_ensnared,test,test2]))
			print("connected")
	
func _on_snake_ensnared(player_ensnared,position_ensnared,snake_strength,health_hurt_speed,test):
	var sname_local = player_ensnared.name
	print("should be ensnared ",player_ensnared.name)
	if sname_local == "Mouse":
		is_ensnared = true
		detection_area.remove_from_group("NPC")
	
	
func _snake_stunned(player_ensnared,the_state,test):
	print(player_ensnared)
	if the_state == "run" and player_ensnared == self:
		AI_STATE = "follow_player"
		detection_area.add_to_group("NPC")
		is_ensnared = false
		

func turn_off_ensnared(previous_thing_ensnared,current_thing_ensnared,test,test2):
	if previous_thing_ensnared == self and current_thing_ensnared != self:
		detection_area.add_to_group("NPC")
		AI_STATE = "follow_player"
		is_ensnared = false
# need a function incase the snake is dead 
