extends NPC
var AI_STATE :String = "patrol"


func _ready() -> void:
	
	startup_navigation_ready()
	initialize_targeting()




func _process(delta: float) -> void:
	
	run_targeting()
	_process_navigation(delta)
	
	
	match AI_STATE:
		"patrol":
			pass
		"attack":
			pass
		"follow_player":
			pass
		"hold_position":
			# Hold position is where the NPC stays in that area and does not move , attacking when a enemy approaches 
			# if health gets low enough it can switch to retrat 
			
			pass
		"attack_retreat":
			pass
			
		"attack_travel":
			pass
