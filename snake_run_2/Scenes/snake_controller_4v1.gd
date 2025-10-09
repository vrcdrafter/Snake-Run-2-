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

# list of oneshots 
var snake_ensnare_oneshot :bool = true



# RENDERING INCREMENTER , OK THIS IS A WIERD ONE , 
#THIS IS THE VARIABLE THAT KEEPS TRACK OF WHAT FRAMES TO SKIP 
var skip_frame :int = 1

var willing_to_chase :bool = true

var simlation_oneshot :bool = true

var death_accumulator :float = 0 
var death_timer :float = 9

signal snake_removed

func _ready() -> void:

	#initialize spine 
	initilaize_spine_bones()
	# make triangles for each bone in snake , move position to each bone 
	#make_tris() ( head tris is green ) 
	make_tris()
	# initialize the ensnarment points , basically the points where the snake wraps around . 
	initialize_ensnarment_curve()
	
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
	
func _physics_process(delta: float) -> void:
	

	
	
	snake_wave_pysics_process(delta) # initialize the snake wavyness
	if health < 0:
		snake_state = "null"

		#snake_state = "null"
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
			#start tris following eachother
			follower(delta,tri_array,bone_length)
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
			# if at some point the player gets too close resume chase 
			var ennarement_done :bool = false
			
			match ensnare_state:
			
				"path":
					bone_simulation_phys.active = false
					make_ensnarement_curve(ensnarement_points,tri_array,snake_target,animation_curve)

					var total_curve_length = curve.get_baked_length()
					move_segments_to_path(total_curve_length - animation_curve.get_baked_length()) # so this 14.6 is the added curve length 
				
					if snake_target.name.contains("Player"):
						ensnared.emit(snake_target)
					ensnare_state = "run"
				"run":
					
					var local_target_distance :float = (snake_target.global_position - tri_array[0].global_position).length()
					twist_triangles(0)
					if local_target_distance < 4: # keep trying to ensnare 
						ennarement_done = move_segments_along_path(delta,3)
						
						if ennarement_done:
							move_segments_back_normal()
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
						self.global_transform = snake_target.global_transform * LOWER_OFFSET_TRANSFORM
						transform_onestart = false
					# check to see if player gets close 

					if onestart and not snake_target.name.contains("Player"):  #do not run this if you have a player 
						timer_move_on.start() # start the timer for how long to be there .
						onestart = false
					
					if timer_up:
						# you need to skip some of these frames too . 
						ensnare_state = "abort_static"
						
				"abort_static":
					abort_universal_reset()
					self.global_transform = transform_save# # this is a PROBLEM PROBLEM , be careful where abort comes form 
					if snake_target.name.contains("Player"):
						pass # make this so theres a otpion to target the player!!!!!!!!!!!!!!!
					else:
						snake_target = pick_new_target(snake_target)
				"abort_dynamic":
					abort_universal_reset()
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
			follower(delta,tri_array,bone_length)
			
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
			
				


	if bone_overriding:
		override_skeleton(skel)
		
		
func abort_universal_reset():
	
	transform_onestart = true # reset this so it can grab the next transform when the time comes . 
	onestart = true
	bone_overriding = true
	timer_up = false
	snake_animations.stop() 
	var name_loca = snake_target.name
	
	if snake_target == target_player:
		snake_state = "chase"
	else :
		snake_state = "patrol"
	ensnare_state = "path"
	
	
	
