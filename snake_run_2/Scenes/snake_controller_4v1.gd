extends Snake
var ensnare_state :String = "path"
var snake_state :String = "patrol"

@onready var test_mesh :MeshInstance3D = get_node("../MeshInstance3D")


@onready var skel :Skeleton3D
var all_animation_curves :Array[Curve3D]

var bone_overriding :bool = true

# animation one start , so the animation timer plays once 
var onestart :bool = true
var transform_onestart :bool = true
var transform_save :Transform3D 
var transform_save_target :Transform3D

# list of oneshots 
var snake_ensnare_oneshot :bool = true
var rough_start_oneshot :bool = true


# RENDERING INCREMENTER , OK THIS IS A WIERD ONE , 
#THIS IS THE VARIABLE THAT KEEPS TRACK OF WHAT FRAMES TO SKIP 
var skip_frame :int = 1

var willing_to_chase :bool = true

var simlation_oneshot :bool = true

var death_accumulator :float = 0 
var death_timer :float = 3

signal snake_removed

# timing stuff just for benchmark , you can delete these 
# Put these at the top of your script
var time_sum_usec: int = 0
var time_count: int = 0
var recent_times :Array =  []
var max_samples := 60


func _ready() -> void:

	#initialize spine 
	initilaize_spine_bones()
	# make triangles for each bone in snake , move position to each bone 
	#make_tris() ( head tris is green ) 
	make_tris()
	# initialize the ensnarment points , basically the points where the snake wraps around . 

	
	initialize_timing_sway() # initializes the snakes wavyness with time 
	
	nav_startup_ready() # starts up the navigation
	
	skel = find_skeleton()
	
	initialize_patrol_objects()
	
	snake_target = fetch_random_patrol_object() # just pick a first target . 
	
	all_animation_curves = _make_curve_from_animation(skel,false) # register animations if ther is any on the model

	var make_timer :Timer = make_anim_timer()
	
	connect_player_signals()
	
	widen_cull_margin()
	
	make_physical_skeleton()
	
	add_colission_shapes()
	
	game_manager_connect_sripts()
	
	initialize_slither_path()
	
	inialize_slither_curve(slither_curve,skel,path_slither)
	
	move_tris_to_slither2(tri_array)
	
	
	
func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("slither_inc_fine"):
		
		drop_interval = .05
		force_tris_catch_up(tri_array)
		
	if Input.is_action_just_pressed("slither_increment_medium"):
		drop_interval = .5
		force_tris_catch_up(tri_array)
	if Input.is_action_just_pressed("slither_increment_course"):
		drop_interval = 1
		force_tris_catch_up(tri_array)
	
	
	snake_wave_pysics_process(delta) # initialize the snake wavyness
	if health < 0:
		snake_state = "null"
	
	
		#snake_state = "null"
	if Input.is_action_just_pressed("ui_accept"):
		pass
		#snake_state = "null2"
	# have snake start to chase target 
	match snake_state:
		"patrol":
			if found_player:
				snake_state = "chase"
			
			var target_distance :float = tri_array[0].global_position.distance_to(snake_target.global_position)
						# when you go into patrol , just skip a frame , see how bad it looks 
						# just be casual agressivness 
			aggressivness = 12
			movement_speed = 3
			#find something to patrol to 
			set_movement_target(snake_target.global_position) # assigns target
			nav_startup_physics_process(delta,tri_array[0]) #starts up the navigation server 
			
			
			var start_time = Time.get_ticks_usec()
			#follower(delta,tri_array,bone_length)
			#follower_curve(sway_head,path_slither)
			follower_curve_2(sway_head,path_slither)
			#print("the state is ",tri_array[1].get_parent().progress_ratio)
			#move_tris_forward()
			var elapsed :float = Time.get_ticks_usec() - start_time
			# Maintain a rolling list of the last 60 samples
			recent_times.append(elapsed)
			if recent_times.size() > max_samples:
				recent_times.remove_at(0)
			# Print every 60 frames
			if (Engine.get_process_frames() % 60) == 0 and recent_times.size() > 0:
				var avg_recent = recent_times.reduce(sum,0) / recent_times.size()
				print("Avg (last %d samples): %.1f μs" % [recent_times.size(), avg_recent])
			
			
			
			# if condition if its just a relay point
			if target_distance < 1 and not snake_target.is_in_group("A"): # meaning its just a way point 
				# pick new object
				snake_target = pick_new_target(snake_target)
			# if condition if its a animated object 
			if target_distance < 1 and snake_target.is_in_group("A"):
				# its a animated spot run an animated ensnar 
				snake_state = "ensnare_anim"
			
		"ensnare_anim": # meaning animated ensnarement


			
			# need to find right curve to use 
			var target_animation :String = find_target_animation(snake_target)
			var animation_curve :Curve3D # for now just play the first curve found
			for i in all_animation_curves.size():
				if all_animation_curves[i].resource_name == target_animation:
					animation_curve = all_animation_curves[i]
			# extract all thos points from that found curve 
			var animation_points = animation_curve.get_baked_points()
			# if at some point the player gets too close resume chase 
			var ennarement_done :bool = false
			
			match ensnare_state:
			
				"path":
					bone_simulation_phys.active = false
					make_ensnarement_curve(animation_points,path_slither,snake_target,slither_curve)
					
					# so the moment you make that cuve save that target transform 
					transform_save_target = snake_target.global_transform
					
					if snake_target.name.contains("Player"):
						ensnared.emit(snake_target)
					# set up the triangles too along the path 
					tri_array[0].reparent(slither_follow_array[0],true)
					tri_array[0].transform = Transform3D.IDENTITY
					slither_follow_array[0].progress = slither_follow_array[1].progress + bone_length
					ensnare_state = "run"
					
				"run":
					
					var local_target_distance :float = (snake_target.global_position - tri_array[0].global_position).length()
					twist_triangles(0)
					if local_target_distance < 100: # keep trying to ensnare 
						# move tri array 0 so it moves too 
						
						ennarement_done = move_segments_along_path(delta,3,slither_follow_array)
						
						if ennarement_done:
							#inialize_slither_curve(slither_curve,skel,path_slither)
							
							
							ensnare_state = "run_animation"
					else:
						# means the prey esaped 
						
						ensnare_state = "abort_dynamic"
				"run_animation":
					bone_simulation_phys.active = true
					var local_target_distance_self :float = (snake_target.global_position - self.global_position).length() # this is the true snake to player at this point
					var local_target_distance_tri :float = (snake_target.global_position - tri_array[0].global_position).length() 
					var discernment_distance :float = 0 
					if local_target_distance_self > local_target_distance_tri:
						discernment_distance = local_target_distance_tri
					else:
						discernment_distance = local_target_distance_self
					
					if snake_target.name.contains("Player") and discernment_distance > 3:
						
						timer_up = true
					if found_player and not snake_target.name.contains("Player"): 
						timer_up = true
						
					bone_overriding = false
					skel.clear_bones_global_pose_override()
					if transform_onestart:
						transform_save = self.global_transform # note this line needs to run once too 
						snake_animations.play(target_animation)
						self.global_transform = transform_save_target # if this isnt handled properly , the snake launches the player !
						var target_name_local = snake_target.name
						
						transform_onestart = false
					# check to see if player gets close 

					if onestart and not snake_target.name.contains("Player"):  #do not run this if you have a player 
						timer_move_on.start() # start the timer for how long to be there .
						onestart = false
					
					if timer_up:
						# you need to skip some of these frames too . 
						ensnare_state = "abort_static"
						
				"abort_static":
					
					abort_universal_reset() # may need to switch this with line below
					# # this is a PROBLEM PROBLEM , be careful where abort comes form 
					if snake_target.name.contains("Player"):
						pass # make this so theres a otpion to target the player!!!!!!!!!!!!!!!
					else:
						snake_target = pick_new_target(snake_target)
				"abort_dynamic":
					abort_universal_reset()
					
				"null2":
					pass
		"chase":
			found_player = false
			# make it so the target is the player 			snake_target = target_player
			snake_target = target_player
		
			var target_distance :float = tri_array[0].global_position.distance_to(snake_target.global_position)
			aggressivness = 5
			movement_speed = 5
			#find something to patrol to 
			set_movement_target(snake_target.global_position) # assigns target
			nav_startup_physics_process(delta,tri_array[0]) #starts up the navigation server 
			#start tris following eachother
			#follower(delta,tri_array,bone_length)
			follower_curve_2(sway_head,path_slither)
			# chase is intereting because it stays here unless the target is far away , 
			if target_distance > 8:
				snake_state = "patrol"
			if target_distance < 1: 
				snake_state = "ensnare_anim"
			
			
		"null":
			
			
			var test2 :Array[Node] = self.find_children("*PhysicalBoneSimulator3D*","PhysicalBoneSimulator3D",true,false)
			if simlation_oneshot:
				dead_snake.emit($BoneAttachment3D/tounge_1)
				for each in test2:
					if each.get_child_count() > 0:
						bone_simulation_phys.active = true
						each.physical_bones_start_simulation()
						bone_overriding = false
						simlation_oneshot = false
						skel.clear_bones_global_pose_override()
						# also make is to the snake collides with nothing ( might fall through floor ) 
				for area_examined in physical_bone_ref:
					area_examined.collision_mask = 9
					area_examined.collision_layer = 9
					area_examined.gravity_scale = 1
					area_examined.mass = .1
					
			death_accumulator += delta
			if death_accumulator > death_timer:
				for area_examined in physical_bone_ref:
					area_examined.collision_mask = 8
					area_examined.collision_layer = 8
					area_examined.gravity_scale = .5
					area_examined.mass = .1
			if death_accumulator > death_timer + 3:
				emit_signal("snake_removed")
				self.queue_free()
			
		"null2":
			pass


	if bone_overriding:
		override_skeleton(skel)
		
		
		
func abort_universal_reset():
	
	# furst unparent the head so it doenst go crazy 
	#tri_array[0].reparent(tri_array[0].get_parent().get_parent().get_parent(),true)
	#before you initialize the curve 
	#move triangles to skeleton 
	
	var triangle_orientation :Array[Transform3D] = capture_triangle_transforms(tri_array)
	
	slither_curve.clear_points()
	# move triangles out of paths 
	move_triangles_out_of_path(tri_array)
	#apply_triangle_transforms(tri_array,transform_save_target)
	# move whole snake 
	self.global_transform = transform_save
	initialize_slither_curve_3(tri_array)
	# make is dense 
	#remake_curve_density(drop_interval)
	
	# so t1his curve has low density , make the density according to the travel setting 
	move_triangles_in_path(tri_array)
	
	spread_tirangles_out(tri_array)
	#move_tris_to_slither_process(tri_array,true)
	
	transform_onestart = true # reset this so it can grab the next transform when the time comes . 
	
	onestart = true
	bone_overriding = true
	timer_up = false
	snake_animations.stop() 
	var name_loca = snake_target.name
	#spread_tirangles_out(tri_array)
	if snake_target == target_player:
		snake_state = "chase"
		#snake_state = "null2"
		force_tris_catch_up(tri_array)
		print("should be caught up ")
	else :
		snake_state = "patrol"
		#snake_state = "null2"
		force_tris_catch_up(tri_array)
		print("should be caught up ")
		
		
	ensnare_state = "path"
	#ensnare_state = "null2"
	
	
	
	
