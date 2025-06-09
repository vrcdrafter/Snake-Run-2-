extends Node


var ping_controllers :bool = true 


func _ready() -> void:
	
	var callable = Callable(self, "act_on_connection")
	#start initial scene with one
	
	Input.joy_connection_changed.connect(callable)
	
	# make the grid columns 1 at statup 
	$GridContainer.columns = 1

func _process(delta: float) -> void:
	
	Input.joy_connection_changed
	
	
	if ping_controllers:
		assess_controllers()
		ping_controllers = false




func assess_controllers():
	
	print("so these are the controllers connected at astartup", Input.get_connected_joypads())


func act_on_connection(_device, _connected):
	print("hey you connected something, it was ",_device, " its plugged in ",_connected)
	# if more controllerd added after scene started shift number +1 
	if _device == 1:
		print("you have one controller")
		
		spawn_player($spawn_point_1.global_position,1)


func spawn_player(spawn_position :Vector3,num :int):
	var new_player :SubViewportContainer = load("res://Scenes/player_spawn.tscn").instantiate()
	new_player.name = "controller" + str(num)
	$GridContainer.columns = 2
	$GridContainer.add_child(new_player)
	var path_player_1 = "GridContainer/" + new_player.name + "/SubViewport/Player"
	var player_1_handle :CharacterBody3D = get_node(path_player_1)
	var sub_viewport_sizing :SubViewport = get_node(new_player.name + "/SubViewport")
	player_1_handle.global_position = spawn_position
	
	
