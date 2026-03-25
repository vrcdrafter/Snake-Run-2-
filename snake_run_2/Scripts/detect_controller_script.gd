extends Node


var ping_controllers :bool = true 
signal player_added

var accumulator :float = 0 
var time_to_check :float = 2

@export var one_player_has_all_items  = false
var resource_name :String = ""
var test :String = ""

func _ready() -> void:
	
	var callable = Callable(self, "act_on_connection")
	#start initial scene with one
	
	Input.joy_connection_changed.connect(callable)
	
	# make the grid columns 1 at statup 
	$GridContainer.columns = 1
	# initilize so the items is zero again 
	GlobalVars.items_collected = 0
	
	

func _process(delta: float) -> void:
	
	
	
	Input.joy_connection_changed
	
	
	if ping_controllers:
		assess_controllers()
		ping_controllers = false
		
	# check connections 
	accumulator += delta
	if accumulator > time_to_check:
		poll_all_snakes_connections()
		poll_all_player_connection()
		accumulator = 0




func assess_controllers():
	
	print("so these are the controllers connected at astartup", Input.get_connected_joypads())


func act_on_connection(_device, _connected):
	print("hey you connected something, it was ",_device, " its plugged in ",_connected)
	# if more controllerd added after scene started shift number +1 
	if _device == 0 and _connected == true:
		print("you have one controller")
		print("This is the joy name ", Input.get_joy_info(0))
		spawn_player($spawn_point_1.global_position,1)
		
	if _device == 0 and _connected == false:
		print("remove a player ")
		despawn_player()


func spawn_player(spawn_position :Vector3,num :int):
	var new_player :SubViewportContainer = load("res://Scenes/player_spawn.tscn").instantiate()
	new_player.mouse_filter = Control.MOUSE_FILTER_STOP
	new_player.name = "controller" + str(num)
	$GridContainer.columns = 2
	$GridContainer.add_child(new_player)
	var path_player_1 = "GridContainer/" + new_player.name + "/SubViewport/Player"
	var player_1_handle :CharacterBody3D = get_node(path_player_1)
	var sub_viewport_sizing :SubViewport = get_node(new_player.name + "/SubViewport")
	player_1_handle.global_position = spawn_position

	emit_signal("player_added")
	
func despawn_player():
	var grid_contrainer_childredn = $GridContainer.get_children()
	
	for each in grid_contrainer_childredn:
		if each.name != "SubViewportContainer2":
			each.queue_free()
			$GridContainer.columns = 1
	
	
	
func poll_all_snakes_connections():
	
	var all_snakes :Array = get_tree().get_nodes_in_group("snake")
	
	for each in all_snakes:
		if not each.is_connected("snake_removed",Callable(self,"add_new_snake")):
			
			
			each.connect("snake_removed",Callable(self,"add_new_snake").bind([resource_name,test]))
			
			
			
			
func poll_all_player_connection():
	
	var all_player :Array = get_node("GridContainer").get_children()
	
	for each :SubViewportContainer in all_player:
		if not each.get_child(0).get_child(0).is_connected("can_leave",Callable(self,"_player_has_items")):
			each.get_child(0).get_child(0).connect("can_leave",Callable(self,"_player_has_items"))
			pass
	
	
func add_new_snake(resource_name,test):
	
	var spawn_points :Array[Node] = $snake_spawn_points.get_children()
	var random_spawn_point = spawn_points[randi() % spawn_points.size()]	
	
	var new_snake = load("res://Scenes/" + resource_name + ".tscn").instantiate()
	new_snake.global_position = random_spawn_point.global_position
	add_child(new_snake)
	
	
func back_to_title() -> void:
	GlobalVars.next_level = "res://Scenes/"+"title"+".tscn"
	get_tree().change_scene_to_file("res://Scenes/loading.tscn")



func _on_area_3d_area_entered(area: Area3D) -> void:
	var name_object = area.get_parent().name
	var area_child :CollisionShape3D= area.get_child(0)
	if name_object == "Player" and one_player_has_all_items and area_child.shape.size.x < 6:
		back_to_title()
		
func _player_has_items():
	one_player_has_all_items = true
	save_level_access()
	
func setup_level():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GlobalVars.game_started = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	
func save_level_access():
	const path :String = "user://.save"
	var path1 := get_tree().current_scene.scene_file_path  # e.g. "res://scenes/MainMenu.tscn"
	var current_scene := path1.get_file().get_basename()     
	var file = FileAccess.open(path,FileAccess.WRITE)
	if current_scene == "Jungle":
		file.store_string("2")
	elif  current_scene == "Winter forest":
		file.store_string("3")
	else:
		file.store_string("Bad_save")
	file.close()
