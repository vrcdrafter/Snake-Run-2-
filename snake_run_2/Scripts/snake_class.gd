@icon("res://snake_icon.svg")
extends Node3D
class_name Snake

@export var aggressivness :float = 1.0


@export var hide_triangles :bool = false
var ensarement_path :Path3D

var curve :Curve3D
var ensnarement_points :PackedVector3Array
var animation_transiton_points :PackedVector3Array
var all_transition_curves :Array[Curve3D]
var rotate_heper :Array[Node3D]
var tri_array :Array[MeshInstance3D]
var sway_head :MeshInstance3D
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
var wave_strength_narrow :float

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

signal ensnared(player_id :Node3D)
signal dead_snake(snake_id :Node3D)

# for finding players 
var found_player :bool = false
var player_to_chase :Node3D
var target_player :Node3D

var bone_simulation_phys : PhysicalBoneSimulator3D = PhysicalBoneSimulator3D.new()

var health :int = 8

var physical_bone_ref :Array[PhysicalBone3D] 

var nav_mesh_calc_time :float = .2
var time_accumulator :float = 0 
var next_path_position :Vector3

const LOWER_OFFSET_TRANSFORM := Transform3D(Basis(), Vector3(0, -1, 0)) # 1 meter down

var health_decremented :bool = false
 # really just using this for the triangles to snap to during damage hit 
var colission_array :Array[CollisionShape3D]

@onready var attacker :Node3D = get_node("BoneAttachment3D/tounge_1")

var angle_local


var bone_collission_reference :Array[PhysicalBone3D]

var number_changed :bool = true

var num_players :int

var player_in_scene :Array = []

func _init() -> void:


	

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
		pass
	

func follower(delta :float, body_segment_pimitived :Array[MeshInstance3D], bone_length :float):
	for i in range(body_segment_pimitived.size()):
		
		if i == 0: # meaning its the first piece, THE HEAD , note the head is already the green triangle and needs to follow nothing 
			pass
		else:
			
			if i == 1:
				body_segment_pimitived[i].look_at(sway_head.global_position)
				if (sway_head.global_position.distance_to(body_segment_pimitived[i].global_position) > bone_length):
					body_segment_pimitived[i].global_position = body_segment_pimitived[i].global_position.lerp(sway_head.global_position,delta * movement_speed)
			else:
				
				body_segment_pimitived[i].look_at(body_segment_pimitived[i-1].global_position)
				if (body_segment_pimitived[i-1].global_position.distance_to(body_segment_pimitived[i].global_position) > bone_length):
					body_segment_pimitived[i].global_position = body_segment_pimitived[i].global_position.lerp(body_segment_pimitived[i-1].global_position,delta * movement_speed)

func calc_length(skeleton :Skeleton3D):
	var bone_length
	bone_length = (skeleton.get_bone_global_rest(0).origin - skeleton.get_bone_global_rest(1).origin).length()
	return bone_length
	
func make_ensnarement_curve(ensnarement_data :PackedVector3Array, body_segment_pimitived :Array[MeshInstance3D],target :Node3D ,anim_curve :Curve3D = null):
	curve.clear_points()
	var anim_ensnare_points :PackedVector3Array 
	var anim_ensnare_points2 :PackedVector3Array 
	var anim_ensnare_point_2_translated :PackedVector3Array
	# make the curve where the snake is currently at . 
	for each in body_segment_pimitived:
		var local_transform :Vector3 = ensarement_path.to_local(each.global_position)
		anim_ensnare_points.append(local_transform)
	anim_ensnare_points.reverse()
	# make the curve to slither into 
	
# Create a rotation transform (180° around Y) 	
	for each in anim_curve.get_baked_points():
		anim_ensnare_points2.append(each)
		
		
	var snake_head_global_position :Vector3 = attacker.global_position
	var global_vector :Vector3 = target.global_position - snake_head_global_position
	var local_vector_appoach :Vector3 = target.to_local(global_vector)
	# how do I get the local angle between the target and the approach 
	angle_local = atan2(local_vector_appoach.x, local_vector_appoach.z)
	
	
	var rot_y = Transform3D(Basis(Vector3.UP, angle_local), Vector3.ZERO)
	var offset :Vector3 = Vector3(0,-1,0)
	for each in anim_ensnare_points2:
		var transform_test :Vector3 = (target.global_transform * rot_y) * each
		var local_transform :Vector3 = ensarement_path.to_local(transform_test)
		anim_ensnare_point_2_translated.append(local_transform + offset)
		
		
	anim_ensnare_points.append_array(anim_ensnare_point_2_translated)
	
	for each in anim_ensnare_points:
		curve.add_point(each)
	
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
		if i == 0:
			skeleton_L.set_bone_global_pose_override(snake_vertibrea[i], self.transform.inverse() * sway_head.global_transform * trans_prime, 1, true)
		else:
			skeleton_L.set_bone_global_pose_override(snake_vertibrea[i], self.transform.inverse() * tri_array[i].global_transform * trans_prime, 1, true)
		#so the self.transform.inverse()  is what makes the snake note mobile and cane be moved anywhere around the scene 

	

		
func move_triangles_to_bones(tris :Array[MeshInstance3D]):
	for i in snake_vertibrea.size(): #EXCLUDE THE TWO EYES AND JAW

		tris[i].global_transform = colission_array[i].global_transform
		

	
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
			var list_points :Array[Vector3]
			var curve_new :Curve3D = Curve3D.new()
			for g in snake_skeleton.get_bone_count(): # needs to excllude eyes and jaw bone 
				# try backwards
				var bone_name = snake_skeleton.get_bone_name(g) # why is jaw in there !
				if "neck" in bone_name:
					
					var bone_position :Vector3 = snake_skeleton.get_bone_global_pose(g).origin
					list_points.append(bone_position)
			list_points.reverse()
			for l in list_points:
				
				curve_new.add_point(l)		
			
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
		var triangle_mesh_small :PrismMesh = PrismMesh.new()
		triangle_mesh_small.size = Vector3(.2, .2, .2)

		triangle_mesh.size = Vector3(.5,.5,.5)
		tri_array[i].mesh = triangle_mesh
		
		tri_array[i].name = "body"+str(i)
		var new_mat :StandardMaterial3D = StandardMaterial3D.new()
		new_mat.albedo_color = Color(0,1,0,0)
		
		var new_mat2 :StandardMaterial3D = StandardMaterial3D.new()
		new_mat2.albedo_color = Color(1,0,0,0)
		
		sway_head = MeshInstance3D.new()
		
		sway_head.mesh = triangle_mesh_small
		sway_head.set_surface_override_material(0,new_mat2)
		tri_array[0].set_surface_override_material(0,new_mat)
		tri_array[0].add_child(sway_head)
		sway_head.position = Vector3(0,0,0)
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
		colission_array.append(colission_snake_shape)
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


	var distance = tri_array[0].get_child(0).global_position.distance_to(snake_target.global_position)

	if distance < 3: # start clamping
		wave_strength_narrow = clamp(wave_thing,distance * -1 ,distance)
	else: 
		wave_strength_narrow = 1


	sway_head.position = Vector3(wave_thing* 20 * wave_strength_narrow,0,0)
	
	tri_array[0].global_position = tri_array[0].global_position.move_toward(tri_array[0].global_position + safe_velocity, movement_delta)

	
	tri_array[0].look_at(tri_array[0].global_position + safe_velocity,Vector3.UP)
	
func nav_startup_ready():
	
	navigation_agent = NavigationAgent3D.new()
	tri_array[0].add_child(navigation_agent)
	navigation_agent.simplify_path
	navigation_agent.simplify_epsilon = 3
	#navigation_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	
	var _on_velocity_computed :Callable = Callable(self,"velocity_computed")
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	

	
func nav_startup_physics_process(delta,head_object :MeshInstance3D):
			# Do not query when the map has never synchronized and is empty.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	
	movement_delta = movement_speed * delta
	time_accumulator += delta
	if time_accumulator > nav_mesh_calc_time:
		next_path_position = navigation_agent.get_next_path_position()
		time_accumulator = 0
	
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
	if follow_path_array[0].progress_ratio > .99:
		return true
	else:	
		for i in snake_vertibrea.size():
			follow_path_array[i].progress += speed_new *delta
		var temp_progress = follow_path_array[0].progress_ratio
		
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
	var all_ensnare_animations :Array[StringName]
	
	for i in anim_name_local_array.size():
		var test :StringName = anim_name_local_array[i]
		if test.contains("anim"):
			all_ensnare_animations.append(anim_name_local_array[i])
			
	return all_ensnare_animations.pick_random()
	

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
		if skeleton.get_bone_name(i).contains("neck"): # so this is case sensative , 
			all_spine_bones.append(i)
		else:
			pass
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

	var player_death_callable :Callable = Callable(self,"prey_dead")
	var remake_connections_callable :Callable = Callable(self,"re_do_connections")
	
	for each in player_in_scene:
		each.connect("dead",player_death_callable)
	
		
	
func found_prey(player_to_chase,test):
	found_player = true

	target_player = player_to_chase
	
func prey_dead():
	found_player = false
	snake_target = pick_new_target(snake_target)

func widen_cull_margin():
	var all_stuff :Array = self.find_children("*")
	for child :Node  in all_stuff:

		
		if child.is_class("MeshInstance3D"):
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
		if not name.contains("neck"):
			capsule_mesh.height = .05
			capsule_mesh.radius = .05
		else:
			capsule_mesh.height = .5
			capsule_mesh.radius = .2
		var colission_shape :CollisionShape3D = CollisionShape3D.new()
		colission_shape.disabled = false
		colission_shape.shape = capsule_mesh
		one_physical_bone.add_child(colission_shape)
		one_physical_bone.collision_layer = 7
		one_physical_bone.collision_mask = 7
		
		one_physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF
		physical_bone_ref.append(one_physical_bone)



func _on_snake_hitbox_body_entered(test):
	health -= 1
	 # you would need to do a damage operation 
	health_decremented = true
	
	
func make_transition_key(anim_player :AnimationPlayer, Skel :Skeleton3D):
	
	
	var transition_animation :Animation = Animation.new()
	var animation_libary :AnimationLibrary = anim_player.get_animation_library("")
	
	var number_of_bones :int= Skel.get_bone_count()

	for i in number_of_bones:
		if Skel.get_bone_name(i) == "Neck.004":

			transition_animation.add_track(Animation.TYPE_ROTATION_3D,0)
			transition_animation.add_track(Animation.TYPE_POSITION_3D,1)
			transition_animation.track_set_path(0,"Armature_001/Skeleton3D:" + Skel.get_bone_name(i)) # note these paths are wrong IDIOT !
			transition_animation.track_set_path(1,"Armature_001/Skeleton3D:" + Skel.get_bone_name(i)) # note these paths are wrong IDIOT !
			var head_rotation :Quaternion = Skel.get_bone_global_pose(0).basis.get_rotation_quaternion()
			var head_posi :Vector3 = Skel.get_bone_global_pose(0).origin

			transition_animation.rotation_track_insert_key(0,0.0,head_rotation)
			transition_animation.position_track_insert_key(1,0.0,head_posi)
			Skel.get_bone_global_pose(i)
		else:
			transition_animation.add_track(Animation.TYPE_ROTATION_3D,i+1)
			
			transition_animation.track_set_path(i+1,"Armature_001/Skeleton3D:" + Skel.get_bone_name(i)) # note these paths are wrong IDIOT !
			
			var bone_rotation :Quaternion = Skel.get_bone_pose_rotation(i+1)
			transition_animation.rotation_track_insert_key(i+1,0.0,bone_rotation)


	
	animation_libary.add_animation("transition_animation",transition_animation)

	animation_libary.resource_name = "test_new"

	var save_result = ResourceSaver.save(animation_libary,"res://" + animation_libary.resource_name + ".tres") # save the animation so I can dink with it . 


	
	
func game_manager_connect_sripts():
	
		var game_manager = get_tree().root.get_child(1)
		game_manager.connect("player_added",Callable(self,"check_players"))
		
func check_players():
	var player_in_scene :Array  = get_tree().root.find_children("Player","CharacterBody3D",true,false)### attach all player connections so the snake is listening for player is dead 

	var player_death_callable :Callable = Callable(self,"prey_dead")
	for each in player_in_scene:
		each.connect("dead",player_death_callable)
		
		
func change_masking_bones(mask_int):
	for each in physical_bone_ref:
		each.collision_mask = mask_int
		each.collision_layer = mask_int
		
func check_player_references() -> Array:
	var where_players_spawn :GridContainer = get_node("/root/Node/GridContainer")
	
	var player_save_state :int = num_players
	num_players = where_players_spawn.get_child_count()
	
	if num_players != player_save_state:
		number_changed = true
		player_in_scene.clear()
		
	else:
		number_changed = false
	
	if number_changed:
	
		if num_players == 2 : 
			# this means we got another player 
			# go find it 
			player_in_scene = get_tree().root.find_children("Player","CharacterBody3D",true,false)### attach all player connections so the snake is listening for player is dead
			return player_in_scene
		else:
			player_in_scene.append(get_node("/root/Node/GridContainer/SubViewportContainer2/SubViewport/Player"))
			return player_in_scene
			
	else:
		return player_in_scene
		
	
	
	
	
	
	
