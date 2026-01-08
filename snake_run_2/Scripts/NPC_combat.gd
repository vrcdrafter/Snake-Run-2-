extends NPC
var AI_STATE :String = "patrol"

var timer_follow_player :float = 3
var timer_accumulator :float = 0 

var timer_check_ative_snakes :float = 3
var check_snakes_accum :float = 0 

func _ready() -> void:
	
	startup_navigation_ready()
	initialize_targeting()
	AI_STATE = "follow_player"
	remake_connections()



func _process(delta: float) -> void:
	
	run_targeting(delta)
	_process_navigation(delta)
	
	check_snakes_accum += delta
	if check_snakes_accum > timer_check_ative_snakes:
		remake_connections()
	
	
	
	match AI_STATE:
		"patrol":
			pass
		"attack":
			

				print("bullet spawned")
		"follow_player":
			
			timer_accumulator += delta
			if timer_accumulator > timer_follow_player:
				var random_float1 :float = randf_range(2, 8)
				var random_float2 :float = randf_range(2, 8)
				set_movement_target(player.global_position + Vector3(random_float1,0,random_float2))
				timer_accumulator = 0 
		"hold_position":
			# Hold position is where the NPC stays in that area and does not move , attacking when a enemy approaches 
			# if health gets low enough it can switch to retrat 
			
			pass
		"attack_retreat":
			pass
			
		"attack_travel":
			pass
