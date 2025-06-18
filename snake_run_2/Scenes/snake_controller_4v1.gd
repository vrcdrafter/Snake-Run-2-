extends Snake
var ensnare_state :String = "path"
var snake_state :String = "patrol"
@onready var player :CharacterBody3D = get_node("../../../../GridContainer/SubViewportContainer2/SubViewport/Player")
@onready var test_mesh :MeshInstance3D = get_node("../MeshInstance3D")
var snake_target :Node3D = null

@onready var skel :Skeleton3D
var all_animation_curves :Array[Curve3D]

var bone_overriding :bool = true

# animation one start , so the animation timer plays once 
var onestart :bool = true
var transform_onestart :bool = true
var transform_save :Transform3D 

# list of oneshots 
var snake_ensnare_oneshot :bool = true

# slider bar
@onready var slidex :VSlider = get_node("../X_axis")

# RENDERING INCREMENTER , OK THIS IS A WIERD ONE , 
#THIS IS THE VARIABLE THAT KEEPS TRACK OF WHAT FRAMES TO SKIP 
var skip_frame :int = 1

var willing_to_chase :bool = true


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

func _physics_process(delta: float) -> void:
	
	snake_wave_pysics_process(delta) # initialize the snake wavyness
	
	# have snake start to chase target 
	match snake_state:
		
		"patrol":
			var target_distance :float = tri_array[0].global_position.distance_to(snake_target.global_position)
						# when you go into patrol , just skip a frame , see how bad it looks 
						# just be casual agressivness 
			aggressivness = 1
			movement_speed = 1
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
					make_ensnarement_curve(ensnarement_points,tri_array,snake_target,animation_curve)
					move_segments_to_path()
					ensnare_state = "run"
					if snake_target == target_player: # meaning you have the player and not some inatimate object
						emit_signal("ensnared") # good to put this signal here because path is only written once 
				"run":
					

					twist_triangles(0)
					ennarement_done = move_segments_along_path(delta,3)
					var local_target_distance :float = (snake_target.global_position - tri_array[0].global_position).length()
					if ennarement_done and not (local_target_distance > 2.3):
						ensnare_state = "run_animation"
					else :
						pass
				"run_animation":
					bone_overriding = false
					skel.clear_bones_global_pose_override()
					var local_target_distance :float = (snake_target.global_position - tri_array[0].global_position).length()
					if transform_onestart:
						transform_save = self.global_transform # note this line needs to run once too 
						
					# move the snake to the position 
						self.global_transform = snake_target.global_transform
						snake_animations.play(target_animation)
						transform_onestart = false
					# check to see if player gets close 

					if onestart:
						timer_move_on.start() # start the timer for how long to be there .
						onestart = false
					
					if timer_up:
						# you need to skip some of these frames too . 
						ensnare_state = "abort"
				"abort":
					transform_onestart = true # reset this so it can grab the next transform when the time comes . 
					# reset the ensnare state too 
					onestart = true
					snake_animations.stop()
					bone_overriding = true
					#transform the object back too 
					# you need to skip some of these frames too . 						
					self.global_transform = transform_save# remember to restore the transform 
					snake_target = pick_new_target(snake_target) # make this so theres a otpion to target the player!!!!!!!!!!!!!!!
					timer_up = false
					snake_state = "patrol"
					ensnare_state = "path"


	if bone_overriding:
		override_skeleton(skel)
