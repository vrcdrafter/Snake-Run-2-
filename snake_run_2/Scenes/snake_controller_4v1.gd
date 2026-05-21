extends Snake
var ensnare_state :String = "setup"
var snake_state :String = "patrol"

@onready var test_mesh :MeshInstance3D = get_node("../MeshInstance3D")
var stunned_material :StandardMaterial3D = preload("res://Materials/snake_stunned.tres")
var stunned_material2 :StandardMaterial3D = preload("res://Materials/cobra_blue.tres")
var stunned_material3 :StandardMaterial3D = preload("res://Materials/adder.tres")
var regular_material :StandardMaterial3D = preload("res://Materials/snake_friendly.tres")
var regular_material2 :StandardMaterial3D = preload("res://Materials/cobra_blue.tres")
var regular_material3 :StandardMaterial3D = preload("res://Materials/adder.tres")

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
var simlation_oneshot_stunn :bool = true

var death_accumulator :float = 0 
var death_timer :float = 30

var stun_accumulator :float = 0
var stun_timer :float = .2

signal snake_removed



var ensnarement_transform_snapline :Transform3D

var animation_curve :Curve3D

var ennarement_done :bool = false



var ensnared_position :Vector3 

var player_references :Array

var frame_counter :int = 0

var old_target_position :Vector3 = Vector3(0,0,0)

signal let_go_prey


var new_patrol_instance :bool = false

var toung_enabled :bool = true


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
	
	if home == null:
	
		snake_target = fetch_random_patrol_object() # just pick a first target . 
	else:
		snake_target = home
	
	all_animation_curves = _make_curve_from_animation(skel,false) # register animations if ther is any on the model

	var make_timer :Timer = make_anim_timer()
	
	connect_player_signals()
	
	widen_cull_margin()
	
	make_physical_skeleton()
	
	add_colission_shapes()
	
	game_manager_connect_sripts()
	
	
	
func _physics_process(delta: float) -> void:
	

	player_references = check_player_references()
	
	snake_wave_pysics_process(delta) # initialize the snake wavyness
	if health < 0:
		snake_state = "null"
		
		
	if health_decremented:
		snake_state = "stunned"
		health_decremented = false
		

		#snake_state = "null"
	# have snake start to chase target 
	
	snake_target_at_beginning = snake_target
	
	give_hiss(delta)
	
	match snake_state:
		
		"patrol":
			if new_patrol_instance:
				new_patrol_instance = false
				old_target_position = Vector3(0,0,0) # the reason for this is that is prevents a odd edge case where the snake is targeting a position right under its chin. 
			var name_local = snake_target.name
			
			if found_player:
				snake_state = "chase"
			
			var target_distance :float = tri_array[0].global_position.distance_to(snake_target.global_position)
						# when you go into patrol , just skip a frame , see how bad it looks 
						# just be casual agressivness 
			aggressivness = 12
			movement_speed = 3
			#find something to patrol to 
			if old_target_position.distance_to(snake_target.global_position) > .1  or  snake_target.is_in_group("Player"):
				set_movement_target(snake_target.global_position) # assigns target
			nav_startup_physics_process(delta,tri_array[0]) #starts up the navigation server 
			#start tris following eachother
			follower(delta,tri_array,bone_length)
			# if condition if its just a relay point
			
			# so here is a odd edge, sometimes your still chasing the player 
			if target_distance < 1 and snake_target.name.contains("Player") or snake_target.name.contains("Mouse"):
				snake_state = "chase" # go back to chasing 
				
			else: # go ahead and pick a new waypoint 
				
				# so if there is no Home , do the regular 
				if home == null: # then its not assigned and doesne need to go back to its desk .  
				
					if target_distance < 1 and not snake_target.is_in_group("A"): # meaning its just a way point 
						# pick new object
						snake_target = pick_new_target(snake_target)					
					# if condition if its a animated object 
					if target_distance < 1 and snake_target.is_in_group("A"):
						# its a animated spot run an animated ensnar 
						snake_state = "ensnare_anim"			
						ensnared_position = snake_target.global_position
						
				else: 
					# go back to your desk . 
					snake_target = home
					if target_distance < 1 and snake_target.is_in_group("A"):
						# its a animated spot run an animated ensnar 
						snake_state = "ensnare_anim"			
						ensnared_position = snake_target.global_position
				
			old_target_position = snake_target.global_position
		"ensnare_anim": # meaning animated ensnarement
			match ensnare_state:

				"setup":
					# need to find right curve to use 
					target_animation = find_target_animation(snake_target)
					 # for now just play the first curve found
					for i in all_animation_curves.size():
						if all_animation_curves[i].resource_name == target_animation:
							animation_curve = all_animation_curves[i]
							
					ensnare_state = "path"
					# if at some point the player gets too close resume chase 			
				"path":
					bone_simulation_phys.active = false
					ensnarement_transform_snapline = snake_target.global_transform
					make_ensnarement_curve(ensnarement_points,tri_array,snake_target,animation_curve)

					
					var total_curve_length = curve.get_baked_length()
					move_segments_to_path(total_curve_length - animation_curve.get_baked_length()) # so this 14.6 is the added curve length 
					var target_name = snake_target.name
					if (snake_target.name.contains("Player") or snake_target.name.contains("Mouse"))  and target_animation == "anim_ensnare_3":
						
						if not target_animation == "anim_strike":
							ensnared.emit(snake_target,ensnared_position)

					ensnare_state = "run"
				"run":
					ensnared_position = snake_target.global_position
					var local_target_distance :float = (snake_target.global_position - tri_array[0].global_position).length()
					twist_triangles(0)
					# turn off the colission on the stupid snake 
					change_masking_bones(0)
					if target_animation == "anim_ensnare_3":
						if local_target_distance < 4: # keep trying to ensnare 
							ennarement_done = move_segments_along_path(delta,5)
							
							if ennarement_done:
								move_segments_back_normal()
								ensnare_state = "run_animation"
								
						else:
							# means the prey esaped 
							
							ensnare_state = "abort_dynamic"
					
					else: # for any other animation 
						
						if local_target_distance < 10: # keep trying to ensnare 
							if target_animation == "anim_strike":
								ennarement_done = move_segments_along_path(delta,25)
							else:
							
								ennarement_done = move_segments_along_path(delta,13)
							
							if ennarement_done and local_target_distance < 4:
								move_segments_back_normal()
								ensnare_state = "run_animation"
								
								# if its a biting animation there is no ensnare 
								
								if not target_animation == "anim_strike":
									ensnared.emit(snake_target,ensnared_position) # run this if its the right animation or the player is in the rigth position
							if ennarement_done and local_target_distance > 4:
								ensnare_state = "abort_dynamic"
						else:
							# means the prey esaped 						
							ensnare_state = "abort_dynamic"
				"run_animation":
					bone_simulation_phys.active = true
					var dist_1 = snake_target.global_position
					var dist_2 = self.global_position
					
					var local_target_distance_self :float = (snake_target.global_position - self.global_position).length() # this is the true snake to player at this point
					var local_target_distance_tri :float = (snake_target.global_position - tri_array[0].global_position).length() 
					var discernment_distance :float = 0 
					if local_target_distance_self > local_target_distance_tri:
						discernment_distance = local_target_distance_tri
					else:
						discernment_distance = local_target_distance_self
					
					if (snake_target.name.contains("Player") or snake_target.name.contains("Mouse")) and discernment_distance > 3:
						
						timer_up = true
					if found_player and not (snake_target.name.contains("Player") or snake_target.name.contains("Mouse")): 
						timer_up = true
						
					bone_overriding = false
					skel.clear_bones_global_pose_override()
					if transform_onestart:
						transform_save = self.global_transform # note this line needs to run once too 
						snake_animations.play(target_animation)
						
						
						var rot_y = Transform3D(Basis(Vector3.UP, angle_local), Vector3.ZERO)
						self.global_transform = ensnarement_transform_snapline * rot_y # this doesnt quite work
						var offset :Vector3 = Vector3(0,1,0)
						if snake_target.name == "Mouse":
						# need another offset here . 
							offset = Vector3(0,0,0)
						self.global_transform.origin = snake_target.global_position - offset
						transform_onestart = false
						
					# check to see if player gets close 
					var name_local :String = snake_target.name
					# so a odd edge error occurs here where the snaek is targetsing the mouse , but cant move into if statement , onestart is true 
					if onestart and not (snake_target.name.contains("Player") or snake_target.name.contains("Mouse")):  #do not run this if you have a player 
						timer_move_on.start() # start the timer for how long to be there .
						onestart = false
					
					if timer_up:
						# you need to skip some of these frames too . 
						ensnare_state = "abort_static"
				"abort_static":
					abort_universal_reset()
					self.global_transform = transform_save# # this is a PROBLEM PROBLEM , be careful where abort comes form 
					if snake_target.name.contains("Player") or snake_target.name.contains("Mouse"):
						pass # make this so theres a otpion to target the player!!!!!!!!!!!!!!!
					else:
						
						# do a check to see if the snake has a home 
						if home == null:
							snake_target = pick_new_target(snake_target)
						else:
							snake_target = home
				"abort_dynamic":
					abort_universal_reset()
		"chase":
			found_player = false
			# make it so the target is the player 			snake_target = target_player
			var named_think = target_player.name
			snake_target = target_player
		
			var target_distance :float = tri_array[0].global_position.distance_to(snake_target.global_position)
			aggressivness = randf_range(5.0, 7.0)
			movement_speed = randf_range(5.0, 7.0)
			#find something to patrol to 
			set_movement_target(snake_target.global_position) # assigns target
			nav_startup_physics_process(delta,tri_array[0]) #starts up the navigation server 
			#start tris following eachother
			follower(delta,tri_array,bone_length)
			
			# chase is intereting because it stays here unless the target is far away , 
			if target_distance > 17:
				snake_state = "patrol"
				new_patrol_instance = true
			if target_distance < 2:  
				snake_state = "ensnare_anim"
		"null":
			var test2 :Array[Node] = self.find_children("*PhysicalBoneSimulator3D*","PhysicalBoneSimulator3D",true,false)
			if simlation_oneshot:
				let_go_prey.emit(snake_target_at_beginning, null, ensnare_state)
				
				var scene_path = self.scene_file_path
				var scene_name = scene_path.get_file().get_basename()				
				if scene_name == "Cobra_biting":
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = stunned_material2
				elif scene_name == "adder_biting":
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = stunned_material3
				
				else:
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = stunned_material
				$BoneAttachment3D/Node3D.show()
				$BoneAttachment3D/tounge_1/AnimationPlayer.stop()
				for each in test2:
					if each.get_child_count() > 0:
						bone_simulation_phys.active = true
						each.physical_bones_start_simulation()
						bone_overriding = false
						simlation_oneshot = false
						skel.clear_bones_global_pose_override()
						# also make is to the snake collides with nothing ( might fall through floor ) 
				for area_examined in physical_bone_ref:
					area_examined.collision_mask = 7
					area_examined.collision_layer = 7
					area_examined.gravity_scale = 1
					area_examined.mass = .1
					area_examined.friction = .1
					
			death_accumulator += delta
			if death_accumulator > death_timer:
				for area_examined in physical_bone_ref:
					area_examined.collision_mask = 8
					area_examined.collision_layer = 8
					area_examined.gravity_scale = .5
					area_examined.mass = .1
			if death_accumulator > death_timer + 3:
				var resource_name = self.get_scene_file_path().get_file().get_basename()
				snake_removed.emit(resource_name)
				
				self.queue_free()
		"limp_RESET":
			var test2 :Array[Node] = self.find_children("*PhysicalBoneSimulator3D*","PhysicalBoneSimulator3D",true,false)
			for each in test2:
				if each.get_child_count() > 0:
					bone_simulation_phys.active = false
					each.physical_bones_stop_simulation()
			abort_universal_reset()
			snake_state = "patrol"
			new_patrol_instance = true
		"stunned":
			let_go_prey.emit(snake_target_at_beginning, snake_target, ensnare_state)
			var test2 :Array[Node] = self.find_children("*PhysicalBoneSimulator3D*","PhysicalBoneSimulator3D",true,false)
			if simlation_oneshot_stunn:
				var scene_path = self.scene_file_path
				var scene_name = scene_path.get_file().get_basename()
				if scene_name == "Cobra_biting":
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = stunned_material2
				elif scene_name == "adder_biting":
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = stunned_material3
				else:
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = stunned_material
				for each in test2:
					if each.get_child_count() > 0:
						bone_simulation_phys.active = true
						each.physical_bones_start_simulation()
						bone_overriding = false
						simlation_oneshot_stunn = false
						skel.clear_bones_global_pose_override()
						# also make is to the snake collides with nothing ( might fall through floor ) 
				for area_examined in physical_bone_ref:
					area_examined.collision_mask = 9
					area_examined.collision_layer = 9
					area_examined.gravity_scale = 1
					area_examined.mass = .1			
			stun_accumulator += delta
			if stun_accumulator > stun_timer:
				
				var scene_path = self.scene_file_path
				var scene_name = scene_path.get_file().get_basename()
				
				if scene_name == "Cobra_biting":
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = regular_material2
				elif scene_name == "adder_biting":
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = stunned_material3
				else:
					$snake_python/snake_export/Skeleton3D/export_snake_mesh.material_override = regular_material
				snake_state = "limp_RESET"
				simlation_oneshot_stunn= true
				stun_accumulator = 0
				
				sway_head.position = Vector3(0,0,0) 
				move_triangles_to_bones(tri_array)
				# move head back to 0 just in case. 
				
				#snake_state = "null2"
		"null2":
			pass

	if bone_overriding:
		frame_counter += 1
		var distance_list :Array[float]
		# check distance 
		for each in player_references:
			var distance :float = each.global_position.distance_to(tri_array[0].global_position)
			distance_list.append(distance)
			
		var min_distance = distance_list.min()
		
		if min_distance < 30:
			
			frame_counter = 0
			override_skeleton(skel)  #Run all the time 
			
			# enable that tounge again 
			if !toung_enabled: # starts off true but so does the tounge . 
				set_tongue_enabled(true,$BoneAttachment3D/tounge_1,$BoneAttachment3D/tounge_1/AnimationPlayer)
				toung_enabled = true
			
		else:
			
			# turn off that tounge
			
			if toung_enabled:
				
				set_tongue_enabled(false,$BoneAttachment3D/tounge_1,$BoneAttachment3D/tounge_1/AnimationPlayer)
				toung_enabled = false
			
			if frame_counter > 50:
				
				override_skeleton(skel) 
				frame_counter = 0
			else:
				pass
				
	
		
	if snake_target_at_beginning == snake_target:
		# nothing changed , resume . 
		pass
		
	else:
		let_go_prey.emit(snake_target_at_beginning, snake_target, ensnare_state)
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
		new_patrol_instance = true
	ensnare_state = "setup"
	change_masking_bones(7)
	
	
