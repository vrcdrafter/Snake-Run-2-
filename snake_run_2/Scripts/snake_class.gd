@icon("res://snake_icon.svg")
extends Node3D
class_name Snake

@export var aggressivness :float = 1.0

@export var anglex :float = 0
@export var angley :float = 0
@export var anglez :float = 0

@onready var sliderx :VSlider = get_node("../X_axis")
@onready var slidery :VSlider = get_node("../y_axis")
@onready var sliderz :VSlider = get_node("../z_axis")

@onready var disp_x :TextEdit = get_node("../x_display")
@onready var disp_y :TextEdit = get_node("../y_display")
@onready var disp_z :TextEdit = get_node("../z_display")

@export var hide_triangles :bool = false
var ensarement_path :Path3D

var curve :Curve3D
var ensnarement_points :PackedVector3Array
var animation_transiton_points :PackedVector3Array
var all_transition_curves :Array[Curve3D]
var rotate_heper :Array[Node3D]
var tri_array :Array[MeshInstance3D]
var area_array :Array[Area3D]
var Segment_colission_array :Array[CollisionShape3D]
var follow_path_array :Array[PathFollow3D] 
var running_on_track :bool = false
var just_tarting_out :bool = true
var bone_length :float
var bone_numbers :int
var parent_basis :Transform3D
var parent_rotation_deg :float
var skeleton :Skeleton3D
var SPEED :float = 10
var target :Node3D
var snake_target :Node3D = null
var patrol_objects :Array[MeshInstance3D]

var debug = false

# navigation agent stuff , stuff to move the green triangle
var navigation_agent :NavigationAgent3D 
@export var movement_speed: float = 4.0
var movement_delta: float

# snake wave stuff
var time :float = 0
var snake_wavyness :float = .01
var wave_thing :float = 0


# for snapping snake to triangles 

var trans_new :Transform3D = Transform3D.IDENTITY
var trans_prime :Transform3D

# grip on animation player 
var snake_animations :AnimationPlayer


# timer for utility use 
var timer_move_on :Timer
var timer_up :bool = false

# timer2 for utility use 
var timer_move_on2 :Timer
var timer_up2 :bool = false

# global variable for snake's vertebra, were using this now for moving all the bones 
var snake_vertibrea :PackedInt32Array

signal ensnared

# for finding players 
var found_player :bool = false
var player_to_chase :Node3D
var target_player :Node3D

var bone_simulation_phys : PhysicalBoneSimulator3D = PhysicalBoneSimulator3D.new()

var health :int = 2

var physical_bone_ref :Array[PhysicalBone3D] 

func _init() -> void:


	
	print("ran this too")
	if debug:
		var snake_node :Node3D = find_child("sn*")
		var name = snake_node.name
		
		skeleton = snake_node.find_child("Skeleton3D",true,true)
		bone_numbers = skeleton.get_bone_count() #EXCLUDE THE TWO EYES AND JAW
		bone_length = (skeleton.get_bone_global_rest(0).origin - skeleton.get_bone_global_rest(1).origin).length()
		
		var parent_node :Node3D = get_parent()
		parent_basis = parent_node.global_transform
		parent_rotation_deg = parent_node.rotation_degrees.y
	else:
		print("ran this in else")
		print_tree_pretty()
	

func follower(delta :float, body_segment_pimitived :Array[MeshInstance3D], bone_length :float):
	for i in range(body_segment_pimitived.size()):
		
		if i == 0: # meaning its the first piece, THE HEAD , note the head is already the green triangle and needs to follow nothing 
			pass
		else:
			body_segment_pimitived[i].look_at(body_segment_pimitived[i-1].global_position)
			if (body_segment_pimitived[i-1].global_position.distance_to(body_segment_pimitived[i].global_position) > bone_length):
				body_segment_pimitived[i].global_position = body_segment_pimitived[i].global_position.lerp(body_segment_pimitived[i-1].global_position,delta * movement_speed)

func calc_length(skeleton :Skeleton3D):
	var bone_length
	bone_length = (skeleton.get_bone_global_rest(0).origin - skeleton.get_bone_global_rest(1).origin).length()
	return bone_length
	
func make_ensnarement_curve(ensnarement_data :PackedVector3Array, body_segment_pimitived :Array[MeshInstance3D],target :Node3D ,anim_curve :Curve3D = null):
	# first check if the last argument is empty 

	# first make curve for all points where snake is at that moment 
	
	var node :Node3D = self
	var transform_global :Transform3D = self.global_transform
	var rotation_global_y :float = self.rotation_degrees.y
	var position_global :Vector3 = self.global_position
	var rotation_global :Vector3 = self.rotation
	var points :Array[Vector3] 
	# fetches the triangle positions of wherever the snake is at the time 
	for i in range(body_segment_pimitived.size()):
		points.append((body_segment_pimitived[i].global_position - position_global).rotated(Vector3(0,1,0),deg_to_rad(rotation_global_y * -1)))
	curve.clear_points()
	points.pop_front() # have no idea why I have to do this 
	# 

	for i in points.size():
		curve.add_point(points[(points.size()-1)-i]) # add the points in revers
	# add points to current curve , no rotation yet
	# check if there is unique animation argument added , if so add those points to the curve 
	if not anim_curve == null:
		
		# clear curve as is
		
		var points_anim :PackedVector3Array  = anim_curve.get_baked_points()
		for i in points_anim.size():
			# really wierd transform order ., I have no idea why 
			curve.add_point(target.global_transform * points_anim[i] * self.global_transform) 
			curve.set_point_tilt(i,deg_to_rad(45)) # why am I setting this manually 
		# need to keep working here . 
		
	# of no unique animation add points to regular ensarment
	else:
		for i in ensnarement_data.size():
			var parent_thing :Node3D= get_node("..")
			var magic_numver :Vector3 = target.global_position - position_global
			curve.add_point((ensnarement_data[i]) + (magic_numver).rotated(Vector3(0,1,0),deg_to_rad(rotation_global_y * -1)) + Vector3(0,-.7,0)) 
	ensarement_path.curve = curve

func move_segments_to_path(offset_head):
	# measure head and how far up it is on the path 
	
	
	# need to make follow paths and put the meshes in each one 
	
	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAW
		follow_path_array.append(PathFollow3D.new())
		follow_path_array[i].name = "path" + str(i)
		follow_path_array[i].tilt_enabled = false
		ensarement_path.add_child(follow_path_array[i])
		
	# move each segment into array 
	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAW

		remove_child(tri_array[i])
		follow_path_array[i].add_child(tri_array[i])
		tri_array[i].transform.origin = Vector3(0,0,0)
		tri_array[i].rotation_degrees = Vector3(0,0,0)
		
		# need to set the head at the offset
		follow_path_array[i].set_progress(offset_head - (bone_length * i))
		follow_path_array[i].global_rotation.z = deg_to_rad(0)
func move_segments_back_normal():
	var tri_pos :Array[Transform3D] 
	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAW
		tri_pos.append(tri_array[i].global_transform)
		follow_path_array[i].remove_child(tri_array[i])
		ensarement_path.remove_child(follow_path_array[i])

	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAW
		add_child(tri_array[i])
		tri_array[i].global_transform = tri_pos[i]
		
		

# this functon needs a edit S
func override_skeleton(skeleton_L :Skeleton3D): # need to changet this for two cases , one for ensnarement , one for chasing , right now only looks right for chasing !!!!!!!!!!!
	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAW
		skeleton_L.set_bone_global_pose_override(snake_vertibrea[i], self.transform.inverse() * tri_array[i].global_transform * trans_prime, 1, true)
		#so the self.transform.inverse()  is what makes the snake note mobile and cane be moved anywhere around the scene 

	
func move_triangles_to_bones(tris :Array[Node3D]):
	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAW
		
		tris[i].global_transform = skeleton.get_bone_global_pose((snake_vertibrea.size()-1)-i) # go reverse
		tris[i].global_position = tris[i].global_position  # may need to comment this out 
	
func shift_rotate_points(points :PackedVector3Array, angle_deg :float, offset :Vector3):
	var new_points :PackedVector3Array
	for i in points.size():
		new_points.append(points[i].rotated(Vector3(0,1,0),deg_to_rad(angle_deg)) - offset)
	return new_points
	

# this functon needs a edit 
func _make_curve_from_animation(snake_skeleton :Skeleton3D, debug :bool) -> Array[Curve3D]:
	
	var whole_lib :AnimationPlayer = self.find_child("Anim*")
	
	var anim_library :AnimationLibrary = whole_lib.get_animation_library("")
	var anim_list :Array[StringName] = anim_library.get_animation_list()
	var transition_curves :Array[Curve3D]
	
	if not debug:
		for i in anim_list.size():
			whole_lib.play(anim_list[i])
			
			whole_lib.advance(0)
			#whole_lib.seek(0.0,true,false)
			var curve_new :Curve3D = Curve3D.new()
			for g in snake_skeleton.get_bone_count(): # needs to excllude eyes and jaw bone 
				# try backwards
				var bone_position :Vector3 = snake_skeleton.get_bone_global_pose((snake_skeleton.get_bone_count()-1)-g).origin
				curve_new.add_point(bone_position)
			curve_new.resource_name = anim_list[i]
			transition_curves.append(curve_new)
			
	return transition_curves

# this function need a edit 
func make_tris():
	
	var snake_node :Node3D = find_child("sn*")
	var name = snake_node.name
	
	skeleton = snake_node.find_child("Skeleton3D",true,true)
	
	bone_length = (skeleton.get_bone_global_rest(4).origin - skeleton.get_bone_global_rest(5).origin).length()
	

	
	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAW
		# add triangles
		tri_array.append(MeshInstance3D.new())
		var triangle_mesh :PrismMesh = PrismMesh.new()
		triangle_mesh.size = Vector3(.5,.5,.5)
		tri_array[i].mesh = triangle_mesh
		
		tri_array[i].name = "body"+str(i)
		var new_mat :StandardMaterial3D = StandardMaterial3D.new()
		new_mat.albedo_color = Color(0,1,0,0)
		tri_array[0].set_surface_override_material(0,new_mat)
		
		
		tri_array[i].transform = skeleton.get_bone_global_pose(snake_vertibrea[i]) #EXCLUDE THE TWO EYES AND JAW
		add_child.call_deferred(tri_array[i]) #EXCLUDE THE TWO EYES AND JAW
		
		
		if hide_triangles:
			tri_array[i].hide()
			
	# does not belong here but initialize a re-orient transform used by override_skeleton
	trans_prime = trans_new.rotated(Vector3(1,0,0),deg_to_rad(90))
	trans_prime = trans_new.rotated(Vector3(0,1,0),deg_to_rad(0)) * trans_prime
	trans_prime = trans_new.rotated(Vector3(0,0,1),deg_to_rad(180)) * trans_prime
	
	# does not belong here but find that animion player 
	snake_animations = find_child("Anim*") # note this may be a problem if there is two animation players
	

func add_colission_shapes():
	

	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAw
		var bone_attachment_hit :BoneAttachment3D = BoneAttachment3D.new()
		skeleton.add_child(bone_attachment_hit)
		var name = skeleton.get_bone_name(i)
		bone_attachment_hit.bone_name = name
		var colission_shape :CapsuleShape3D = CapsuleShape3D.new()
		colission_shape.height = .2
		colission_shape.radius = .2
		
		var colis_area :Area3D = Area3D.new()
		var colission_snake_shape :CollisionShape3D = CollisionShape3D.new()
		
		bone_attachment_hit.add_child(colis_area)
		colis_area.position = skeleton.get_bone_pose_position(i)
		colis_area.name = "hitbox" + str(i)
		colis_area.add_child(colission_snake_shape)
		colission_snake_shape.shape = colission_shape
		
		var snake_took_hit :Callable = Callable(self,"_on_snake_hitbox_body_entered")
		colis_area.area_entered.connect(Callable(snake_took_hit))
		# migth need to connect now all them areas . 
		colis_area.collision_layer = 1
		colis_area.collision_mask = 2


# navigation stuff 
func velocity_computed(safe_velocity: Vector3) -> void:
	
	
	
	var new_velocity = tri_array[0].global_position.move_toward(tri_array[0].global_position + safe_velocity, movement_delta)
	# need to include the wavyness of snake
	
	if new_velocity.length() != 0:
		var perpendicular :Vector3 = Vector3(-safe_velocity.x/safe_velocity.length(),0.0,safe_velocity.z/safe_velocity.length())
		var waving_perpendicular :Vector3 = perpendicular.normalized() * wave_thing
		
		tri_array[0].global_position = new_velocity + waving_perpendicular
	
	else:
		tri_array[0].global_position = tri_array[0].global_position.move_toward(tri_array[0].global_position + safe_velocity, movement_delta)

	
	tri_array[0].look_at(tri_array[0].global_position + safe_velocity)
	
func nav_startup_ready():
	
	navigation_agent = NavigationAgent3D.new()
	tri_array[0].add_child(navigation_agent)
	#navigation_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	
	var _on_velocity_computed :Callable = Callable(self,"velocity_computed")
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	
func nav_startup_physics_process(delta,head_object :MeshInstance3D):
			# Do not query when the map has never synchronized and is empty.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		return

	movement_delta = movement_speed * delta
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = head_object.global_position.direction_to(next_path_position) * movement_delta
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		velocity_computed(new_velocity)
	
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
	
	
func initialize_ensnarment_curve():
	curve = Curve3D.new() # this is the one that will get remade again and again with each ensnarement
	var curve_resource :Curve3D = load("res://Resources/perfect_ensnarement_2.tres")
	var curve :Curve3D = Curve3D.new() #may not use this

	ensnarement_points = curve_resource.get_baked_points()
	
	# make a path too 
	ensarement_path = Path3D.new()
	
	add_child(ensarement_path)
	
func move_segments_along_path(delta,speed_new :float) -> bool:
	
	
	
	for i in snake_vertibrea.size():
		follow_path_array[i].progress += speed_new *delta

	if follow_path_array[0].progress_ratio > .99:
		
		return true
		
	else:
		return false


func initialize_timing_sway(): # function to randomize the snakes wavyness 
	time = randf() * 10
	
func snake_wave_pysics_process(delta):
		#wavy stuff
	
	time += delta
	wave_thing = (sin(time * 2)*snake_wavyness * aggressivness)
	
	
func find_skeleton() -> Skeleton3D:
	var snake_skeletong :Skeleton3D = find_child("Skel*",true)
	
	return snake_skeletong
	
func fetch_random_patrol_object() ->MeshInstance3D:
	var next_target :MeshInstance3D = patrol_objects.pick_random()
	return next_target
	
func initialize_patrol_objects():
	for child in get_parent().get_children():
		if child.is_in_group("patrol_object"):
			patrol_objects.append(child)
			
			
func find_target_animation(target_local :Node3D ) ->String:
	var anim_name_local_array :Array[StringName] = target_local.get_groups()

	var animation_to_return :String
	for i in anim_name_local_array.size():
		var test :StringName = anim_name_local_array[i]
		if test.contains("anim"):
			
			animation_to_return = anim_name_local_array[i]
	return animation_to_return
	

func make_anim_timer() -> Timer: # at startup makes a timer in the tree
	timer_move_on = Timer.new()
	timer_move_on.name = "move_on"
	timer_move_on.wait_time = 1
	add_child(timer_move_on)
	timer_move_on.one_shot = true
	# make connection to timer right away 
	timer_move_on.connect("timeout",Callable(self, "_on_timer_timeout"))
	
	
	return timer_move_on

func _on_timer_timeout():    # Code to execute when the timer times out
	
	timer_up = true
	
	
func pick_new_target(snake_target :Node3D) -> Node3D:
	snake_target.remove_from_group("occupied") # first remove from the occupies group of whereveer the snake was .
	var next_target :MeshInstance3D = fetch_random_patrol_object()
	while next_target == snake_target or (snake_target.is_in_group("occupied")):
		next_target = patrol_objects.pick_random() # keep picking till its a new unoccupied group
	next_target .add_to_group("occupied")
	return next_target


func spine_bones() -> PackedInt32Array:
	var all_spine_bones :PackedInt32Array
	var snake_node :Node3D = find_child("sn*")
	skeleton = snake_node.find_child("Skeleton3D",true,true)
	for i in skeleton.get_bone_count():
		if skeleton.get_bone_name(i).contains("Neck"):
			all_spine_bones.append(i)
		else:
			print("skipped one ")
	return all_spine_bones


func initilaize_spine_bones():
	snake_vertibrea = spine_bones()
	# this is the global . 
	
func make_reaction_timer() -> Timer: # this is a timer so the snake does not change its decision too fast when it start to ensnarre 
	timer_move_on2 = Timer.new()
	timer_move_on2.name = "reaction_timer"
	timer_move_on2.wait_time = 1.0
	add_child(timer_move_on2)
	timer_move_on2.one_shot = true
	# make connection to timer right away 
	timer_move_on2.connect("timeout",Callable(self, "_on_timer_timeout2"))
	
	
	return timer_move_on2
	
	
func _on_timer_timeout2():    # Code to execute when the timer times out
	
	timer_up2 = true
	timer_move_on2.queue_free() # remove timer 


func twist_triangles(value :float):
	for tri in tri_array:
		tri.global_rotation.z = deg_to_rad(value)
		



func connect_player_signals(): #what this does is connect the players signals if there on the scene 
	
	var test
	var all_player :Array[Node] = self.find_children("Detection","Area3D",true,false) # what the FUCK are you doing , dont connect all the signals to this !!!!
	var chase_callable :Callable = Callable(self, "found_prey")
	
	for each in all_player:
		
		each.connect("found_player",chase_callable.bind([player_to_chase,test]))
		
	var player_in_scene :Array  = get_tree().root.find_children("Player","CharacterBody3D",true,false)### attach all player connections so the snake is listening for player is dead 
	print("found these")
	var player_death_callable :Callable = Callable(self,"prey_dead")
	
	for each in player_in_scene:
		each.connect("dead",player_death_callable)
	
func found_prey(player_to_chase,test):
	found_player = true
	print("found something to chase ",player_to_chase.name)
	target_player = player_to_chase
	
func prey_dead():
	found_player = false
	snake_target = pick_new_target(snake_target)

func widen_cull_margin():
	var all_stuff :Array = self.find_children("*")
	for child :Node  in all_stuff:

		
		if child.is_class("MeshInstance3D"):
			print("found a mesh ")
			child.extra_cull_margin = 80
			
			
func make_physical_skeleton():
		
	
	
	skeleton.add_child(bone_simulation_phys)
	
	for i in skeleton.get_bone_count():
		var one_physical_bone :PhysicalBone3D = PhysicalBone3D.new()
		
		bone_simulation_phys.add_child(one_physical_bone)
		

		var name = skeleton.get_bone_name(i)
		one_physical_bone.bone_name = name
		var rest_bone :Transform3D = skeleton.get_bone_global_rest(i)
		one_physical_bone.transform = rest_bone
		
		var capsule_mesh :CapsuleShape3D = CapsuleShape3D.new()
		if not name.contains("Neck"):
			capsule_mesh.height = .05
			capsule_mesh.radius = .05
		else:
			capsule_mesh.height = .2
			capsule_mesh.radius = .2
		var colission_shape :CollisionShape3D = CollisionShape3D.new()
		colission_shape.shape = capsule_mesh
		one_physical_bone.add_child(colission_shape)
		one_physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF
		physical_bone_ref.append(one_physical_bone)



func _on_snake_hitbox_body_entered(test):
	print(test)
	print("something hit me ")
	health -= 1
	
	
	
func make_transition_key(anim_player :AnimationPlayer, Skel :Skeleton3D):
	
	
	var transition_animation :Animation = Animation.new()
	var animation_libary :AnimationLibrary = anim_player.get_animation_library("")
	
	var number_of_bones :int= Skel.get_bone_count()
	print("found this many bones",number_of_bones)
	for i in number_of_bones:
		if Skel.get_bone_name(i) == "Neck.004":
			print(" its a head bone now")
			transition_animation.add_track(Animation.TYPE_ROTATION_3D,0)
			transition_animation.add_track(Animation.TYPE_POSITION_3D,1)
			transition_animation.track_set_path(0,"Armature_001/Skeleton3D:" + Skel.get_bone_name(i)) # note these paths are wrong IDIOT !
			transition_animation.track_set_path(1,"Armature_001/Skeleton3D:" + Skel.get_bone_name(i)) # note these paths are wrong IDIOT !
			var head_rotation :Quaternion = Skel.get_bone_global_pose(0).basis.get_rotation_quaternion()
			var head_posi :Vector3 = Skel.get_bone_global_pose(0).origin
			print("quat", head_rotation)
			transition_animation.rotation_track_insert_key(0,0.0,head_rotation)
			transition_animation.position_track_insert_key(1,0.0,head_posi)
			Skel.get_bone_global_pose(i)
		else:
			transition_animation.add_track(Animation.TYPE_ROTATION_3D,i+1)
			
			transition_animation.track_set_path(i+1,"Armature_001/Skeleton3D:" + Skel.get_bone_name(i)) # note these paths are wrong IDIOT !
			
			var bone_rotation :Quaternion = Skel.get_bone_pose_rotation(i+1)
			transition_animation.rotation_track_insert_key(i+1,0.0,bone_rotation)
			print("Armature_001/Skeleton3D:" + Skel.get_bone_name(i+1) + " had rotatoion " + str(bone_rotation))

	
	animation_libary.add_animation("transition_animation",transition_animation)
	print(animation_libary.get_animation_list())
	print(transition_animation.get_track_count())
	animation_libary.resource_name = "test_new"
	print("the name is ",animation_libary.resource_name)
	var save_result = ResourceSaver.save(animation_libary,"res://" + animation_libary.resource_name + ".tres") # save the animation so I can dink with it . 
	print(save_result)

	
