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

var health :int = 2

var physical_bone_ref :Array[PhysicalBone3D] 

var nav_mesh_calc_time :float = .1 #so this can get set high when the snakes are far away too  .
var time_accumulator :float = 0 
var next_path_position :Vector3

# follower curve variables 
var last_position: Vector3
var distance_accumulator: float = 0.0
var curve_length_accumulator: float = 0.0
var drop_interval: float = 2 # meters
var remove_interval: float = 8.0  # meters
var path_slither :Path3D
var slither_follow_array :Array[PathFollow3D]
var slither_curve :Curve3D

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
	
func make_ensnarement_curve(ensnarement_data :PackedVector3Array, slither_path_node :Path3D,target :Node3D ,anim_curve :Curve3D = null):
	# get points so there local 

	# first make curve for all points where snake is at that moment 
	for each in ensnarement_data:
		var world_position = target.global_transform * each
		var local_position = slither_path_node.to_local(world_position)
		anim_curve.add_point(local_position)
	

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
		var tri_parrent_name = tri_array[i].get_parent().name
		var tri_path = tri_array[i].get_path()
		tri_array[i].reparent(follow_path_array[i],false)
		
		
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
		
		tris[i].global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(i)
		
	
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
		
		wave_strength_narrow = clamp(wave_thing,0,distance)
		#print("narrowing ",wave_strength_narrow)
		
	else: 
		wave_strength_narrow = 1


	sway_head.position = Vector3(wave_thing* 20 * wave_strength_narrow,0,0)
	
	tri_array[0].global_position = tri_array[0].global_position.move_toward(tri_array[0].global_position + safe_velocity, movement_delta)

	
	tri_array[0].look_at(tri_array[0].global_position + safe_velocity,Vector3.UP)
	
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
	
func move_segments_along_path(delta,speed_new :float, path_rail_set :Array[PathFollow3D]) -> bool:
	for i in snake_vertibrea.size():
		path_rail_set[i].progress += speed_new *delta
	if path_rail_set[0].progress_ratio > .99:		
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

	health -= 1
	
	
	
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
		
		
func follower_curve(head :Node3D, snake_path :Path3D):
	var current_position = head.global_position
	var frame_distance = current_position.distance_to(last_position)
	distance_accumulator += frame_distance
	if distance_accumulator >= drop_interval:
		
		var local_position = snake_path.to_local(head.global_position)
		snake_path.curve.add_point(local_position)
		distance_accumulator = 0.0
		curve_length_accumulator += drop_interval  # assume each drop adds ~drop_interval
	if curve_length_accumulator >= remove_interval and snake_path.curve.get_point_count() > 0:
		var first_point = snake_path.curve.get_point_position(0)
		var second_point = snake_path.curve.get_point_position(1) if snake_path.curve.get_point_count() > 1 else first_point
		var removed_distance = first_point.distance_to(second_point)
		snake_path.curve.remove_point(0)
		curve_length_accumulator -= removed_distance
	last_position = current_position
	
func initialize_slither_path():
	path_slither = Path3D.new()
	path_slither.name = "slither_path"
	slither_curve = Curve3D.new()
	path_slither.curve = slither_curve
	# you need to initliaze the curve whereverr the snake is 

	
	add_child(path_slither)
	for each in snake_vertibrea.size():
		# add a follow path 
		var local_follow :PathFollow3D = PathFollow3D.new()
		
		path_slither.add_child(local_follow)
		slither_follow_array.append(local_follow)
		
	remove_interval = bone_length * snake_vertibrea.size()
	print("snake is this long", remove_interval)
	
func move_tris_to_slither(triangles :Array[MeshInstance3D]):
	var count = triangles.size()
	
	 # because we dont want to use the lead triangle as the follower
	for each in slither_follow_array:
		# skip the 0th triangle through 
		if count == 1:
			pass
		else:
			triangles[count-1].transform = Transform3D.IDENTITY
			each.add_child(triangles[count-1])
			
			# need to modify the progress too 
			var name_local = slither_follow_array[count -1 ].name
			slither_follow_array[count-1].progress = count - 1 * bone_length
			var lenght_local = path_slither.curve.get_baked_length()
			print("progress set on ", name_local, " also its ", slither_follow_array[count-1].progress)
			count -=1
			

		
func inialize_slither_curve(slither_curve :Curve3D,snake_skeleton :Skeleton3D, slither_path :Path3D):
	var bones_poses :Array[Vector3]
	slither_curve.clear_points()
	slither_curve.up_vector_enabled = false
	for i in snake_skeleton.get_bone_count():
		var one_transform :Transform3D = self.transform * snake_skeleton.get_bone_global_pose(i)
		var point :Vector3 = one_transform.origin
		bones_poses.append(point)
		var local_point = slither_path.to_local(point) 
		slither_curve.add_point(local_point)
	var cure_lenght_local = slither_curve.get_baked_length()
	print("hi")
	
	
func inialize_slither_curve2(slither_curve :Curve3D,snake_skeleton :Skeleton3D, slither_path :Path3D):
	var bones_poses :Array[Vector3]
	slither_curve.clear_points()
	slither_curve.up_vector_enabled = false
	for i in snake_skeleton.get_bone_count():
		var one_transform :Transform3D = snake_target.transform * snake_skeleton.get_bone_global_pose(i)
		var target_pos_l = snake_target.global_position
		var point :Vector3 = one_transform.origin
		bones_poses.append(point)
		var local_point = slither_path.to_local(point) 
		slither_curve.add_point(local_point)
	var cure_lenght_local = slither_curve.get_baked_length()

	
func follower_curve_2(head :Node3D, snake_path :Path3D):
	var current_position = head.global_position
	var frame_distance = current_position.distance_to(last_position)
	distance_accumulator += frame_distance
	#print(distance_accumulator)
	if distance_accumulator >= drop_interval:
		var local_position = snake_path.to_local(head.global_position)
		snake_path.curve.add_point(local_position)
		
		distance_accumulator = 0
	last_position = current_position
	
	if snake_path.curve.get_baked_length() > spine_bones().size() * bone_length:
		snake_path.curve.remove_point(0)
		
		
func move_tris_to_slither2(triangles: Array[MeshInstance3D]):
	var count = triangles.size()
	var whole_snake_lenght = count * bone_length
	if count <= 1:
		return # Nothing to do if there's only one triangle
	for i in range(count - 1, 0, -1): # Skip the lead triangle at index 0
		var triangle = triangles[i]
		triangle.transform = Transform3D.IDENTITY
		var follower = slither_follow_array[i]
		follower.add_child(triangle)
		# Set progress based on bone length
		var count_up = abs(i - count) +1
		var progress = (float(count_up * bone_length) / whole_snake_lenght)
		follower.progress_ratio = progress


		
		

func force_tris_catch_up(triangles: Array[MeshInstance3D]):
	var count = triangles.size()
	var whole_snake_lenght = count * bone_length
	if count <= 1:
		return # Nothing to do if there's only one triangle
	for i in range(count - 1, 0, -1): # Skip the lead triangle at index 0
		var triangle = triangles[i]
		triangle.transform = Transform3D.IDENTITY
		var follower = slither_follow_array[i]
		# Set progress based on bone length
		var count_up = abs(i - count) +1
		var progress = (float(count_up * bone_length) / whole_snake_lenght)
		follower.progress_ratio = progress

func sum(accum, number):
	return accum + number


func move_tris_to_slither_process(triangles: Array[MeshInstance3D],reverse :bool = false):
	var count = triangles.size()
	var whole_snake_lenght = count * bone_length
	if count <= 1:
		return # Nothing to do if there's only one triangle
	for i in range(count - 1, 0, -1): # Skip the lead triangle at index 0

		#triangles[i].transform = Transform3D.IDENTITY
		var count_up :int
		count_up = abs(i - count) +1
		var progress = (float(count_up * bone_length) / whole_snake_lenght)
		slither_follow_array[i].progress_ratio = progress

func move_tris_back_to_snake(tris :Array[MeshInstance3D]):
	for i in tris.size():
		tris[i].global_transform =  snake_target.global_transform * tris[i].global_transform
		
		
func spread_tirangles_out(triangles: Array[MeshInstance3D]):
	var count = triangles.size()
	var whole_snake_lenght = count * bone_length
	if count <= 1:
		return # Nothing to do if there's only one triangle
	for i in range(count - 1, 0, -1): # Skip the lead triangle at index 0
		# Set progress based on bone length
		var count_up = abs(i - count) +1
		var count_down = i
		var progress = (float(count_up * bone_length) / whole_snake_lenght)
		slither_follow_array[i].progress_ratio = progress
		
func initialize_slither_curve_3(tris :Array[MeshInstance3D]):
	for i in tris.size():
		var point :Vector3 = tris[tris.size() - 1 -i].global_position
		var local_point = path_slither.to_local(point) 
		slither_curve.add_point(local_point)
		
func capture_triangle_transforms(tris: Array[MeshInstance3D]) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	for tri in tris:
		transforms.append(tri.global_transform)
	return transforms
	
func apply_triangle_transforms(tris: Array[MeshInstance3D],offset_transform: Transform3D = Transform3D.IDENTITY):
	for each in tris:
		var current_position = self.global_transform
		var offset_inv = offset_transform.affine_inverse()
		each.global_transform = offset_inv * current_position * each.transform
		
func move_triangles_out_of_path(tris :Array[MeshInstance3D]):
	for each in tris:
		each.reparent(each.get_parent().get_parent().get_parent(),true)
		
func move_triangles_in_path(tris :Array[MeshInstance3D]):
	for i in tris.size():
		if i == 0:
			pass # skip the head 
		else:
			tris[i].transform = Transform3D.IDENTITY
			tris[i].reparent(slither_follow_array[i],false)
			
func remake_curve_density(interval :float):
	# the interval is the distance between points that we want . 
	
	var curve_length :float = slither_curve.get_baked_length()
	var num_of_points_desired :int = int(curve_length / interval)
	var dist_between_current_points :float = curve_length / slither_curve.point_count
	var num_of_points_desired_between_segments = int(dist_between_current_points / interval)
	var dense_points :PackedVector3Array = slither_curve.tessellate_even_length(num_of_points_desired_between_segments/2,.05)
	
	print(" i tessalated", dense_points.size())
	
	slither_curve.clear_points()
	for each in dense_points:
		slither_curve.add_point(each)

	
