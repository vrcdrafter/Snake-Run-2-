extends CharacterBody3D

const ACCEL = 10
const DEACCEL = 30

const SPEED = 5.0
const SPEED_CONTROLLER = 7.0
const SPRINT_MULT = 2
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.06
@onready var animation_tree_new :AnimationTree = get_node("AnimationTree")
@onready var Game_over :Control = get_node("../../../../SubViewportContainer/SubViewport/Node3D/Control")
@onready var Game_over_timer :Timer = get_node("../../../../SubViewportContainer/SubViewport/Node3D/Game_over_timer")
# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var camera
var rotation_helper
var dir = Vector3.ZERO
var flashlight
signal remove_mouse
signal snakes_go
# esnanremente data   hi
var ensnared = false
var ensnared_position:Vector3 
var snakes_around_you :int = 0 
# for seeding the sine wave for heavier ensarement snap back
var time = 1.1
var timer_oneshot :bool = true
var direction :Vector3
var can_play_walk :bool = false
var audio_toggle :bool = false

# fetching mouse events from top sub viewport container 
@onready var top_container_handle :SubViewportContainer = get_node("../..")
var event : Vector2 
var previous_event :Vector2 = Vector2(0,0)
@export var player_id = null

# controller stuff
var Joy_sensativity :float = 2.0
var joy_y_accum:float = 0

# bullet stuff
var bullet_scene :PackedScene = preload("res://Scenes/bullet.tscn")

func _ready():
	camera = $rotation_helper/Camera3D
	rotation_helper = $rotation_helper
	
	setup_level()
	
	remake_connections()   
	#DOES NOT WORK AND NEEDS TO BE MOVED#
	if GlobalVars.game_started == true:
		emit_signal("remove_mouse")
		print("should be removing the enable mouse button AAAAAAAAsDDD")
		emit_signal("snakes_go")
		
	$AudioStreamPlayer3D.play()
	$AudioStreamPlayer3D.stream_paused = true
	$AudioStreamPlayer3D.pitch_scale = .8
	
	player_id = find_id()
	print("the player identified is ", player_id)




func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()



func _physics_process(delta: float) -> void:
	

	
	
	if player_id == "0": # then its the regular player with mouse and keybaord 
		
		if Input.is_action_just_pressed("shoot"):
			print("fired")
			animation_tree_new.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			spawn_bullet(delta)
		event = top_container_handle.mouse_event
		
		if previous_event == event:
			event = Vector2(0,0)
		else:
			previous_event = event
		
		rotation_helper.rotate_x(deg_to_rad(event.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg_to_rad(event.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation
		camera_rot.x = clampf(camera_rot.x, -1.4, 1.4)
		rotation_helper.rotation = camera_rot
		
		event = Vector2(0,0)
	else:
		
		if Input.is_action_just_pressed("shoot_p" + player_id):
			
			animation_tree_new.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			spawn_bullet(delta)
			
		
		var look_stick_angle :Vector2 = Input.get_vector("look_left_p"+player_id,"look_right_p"+player_id,"look_up_p"+player_id,"look_down_p"+player_id)
		
		joy_y_accum = look_stick_angle.y * Joy_sensativity * delta
		rotation_helper.rotate_x(joy_y_accum * -1)
		#joystick left right
		self.rotate_y(look_stick_angle.x * Joy_sensativity * -1 * delta)
	
	
	var moving = false
	# Add the gravity. Pulls value from project settings.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and (snakes_around_you < 2):
		velocity.y = JUMP_VELOCITY

	# This just controls acceleration. Don't touch it.
	var accel
	if dir.dot(velocity) > 0:
		accel = ACCEL
		moving = true
	else:
		accel = DEACCEL
		moving = false



	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with a custom keymap depending on your control scheme. These strings default to the arrow keys layout.
	if player_id == "0":
		
		var input_dir :Vector2 = Input.get_vector("player_initial_left", "player_initial_right", "player_initial_forward", "player_initial_backwards")
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * accel * delta


		if Input.is_key_pressed(KEY_SHIFT):
			direction = direction * SPRINT_MULT

		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			animation_tree_new.set("parameters/Blend2/blend_amount", 0)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			animation_tree_new.set("parameters/Blend2/blend_amount", 1)

		move_and_slide()
	else:
		var input_dir = Input.get_vector("pan_left_p"+player_id, "pan_right_p"+player_id, "move_forward_p"+player_id, "move_backward_p"+player_id)
		
		if Input.is_action_just_pressed("jump_p"+player_id) and is_on_floor() and (snakes_around_you < 2):
			velocity.y = JUMP_VELOCITY
		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * accel * delta
		if Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("sprint_p"+player_id):
			direction = direction * SPRINT_MULT
			# speed up animations too 

		if direction:
			velocity.x = direction.x * SPEED_CONTROLLER
			velocity.z = direction.z * SPEED_CONTROLLER
			animation_tree_new.set("parameters/Blend2/blend_amount", 0)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED_CONTROLLER)
			velocity.z = move_toward(velocity.z, 0, SPEED_CONTROLLER)
			animation_tree_new.set("parameters/Blend2/blend_amount", 1)

		move_and_slide()
	
	if ensnared:
		time+= delta
		slow_move_back(ensnared_position,delta,wave(1,3,time,delta)+8.0)
		
		if ((ensnared_position-self.get_global_position()).length() > .58):
			snakes_around_you = 0 
			ensnared = false
			

func _on_button_button_down():
	
	emit_signal("remove_mouse")
	GlobalVars.game_started = true

func _on_snake_ensnared():
	print("should be ensnared")
	ensnared = true
	ensnared_position = self.get_global_position() # may want a different position , 
	snakes_around_you += 1

func slow_move_back(pos:Vector3, delta:float, move_strength:float):
	var current_position = self.get_global_position() # get the position 
	self.position = self.position.lerp(pos, delta * move_strength)
	
	
func wave(amplitude:float, freq:int, time:float, delta):
		
		freq = 1
		amplitude = .1
		var variation 
		variation = sin(time * freq) * amplitude
		return variation

# this is a test if you can commit 


func _on_game_over_timer_timeout():
	print("ten seconds up ")
	# were not doing this anymore 
	#Game_over.visible = true
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # were 


func _on_button_pressed():
	get_tree().reload_current_scene()
	
	
func remake_connections():
	
	var all_snakes :Array = get_tree().get_nodes_in_group("snake")
	print("all _snakes", all_snakes)
	

	

	var timer_handle :Timer = get_tree().root.get_node("Node/SubViewportContainer/SubViewport/Node3D/Game_over_timer")

	var game_over_button_handle :Button = get_node("../../../../SubViewportContainer/SubViewport/Node3D/Control/Button")
	var callable_mouse_button = Callable(self,"_on_button_button_down")
	var callable_ensnare = Callable(self, "_on_snake_ensnared")
	var timer_callable = Callable(self, "_on_game_over_timer_timeout")
	var reset_level = Callable(self,"_on_button_pressed")
	for n in range(all_snakes.size()):
		all_snakes[n].connect("ensnared",callable_ensnare)
#	timer_handle.connect("timeout",timer_callable)
#	game_over_button_handle.connect("pressed",reset_level)
	
	
	# walking audio connection 
	if GlobalVars.next_level == "res://Scenes/level_4.tscn":
		print("your in level 4")
		var audio_handle :Area3D = get_node("../sounds/corridore_sound")
		var walk_callable :Callable = Callable(self, "audio_function")
		audio_handle.body_entered.connect(_on_body_entered)



func _on_camper_area_reconnect_snakes() -> void:
	print("pleace reconenct everything")
	remake_connections()


func _on_node_3d_reconnect_snakes() -> void:
	print("pleace reconenct everything")
	remake_connections()
	
	
func setup_level():
	print("please remove mouse")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if audio_toggle:
			print("turn off the audio for feet")
			can_play_walk = false
			audio_toggle = false
		else:
			can_play_walk = true
			audio_toggle = true
			
			
func find_id() ->String:
	var id = "0"
	if self.get_parent().get_parent().name.contains("1"):
		id = str(1)
	return id
	
	
func spawn_bullet(delta :float):
	
	
	var bullet_instance :Node3D = bullet_scene.instantiate()


	var pt1 :Marker3D = get_node("rotation_helper/Marker3D_shoot")

	var transform_end_of_gun :Transform3D = pt1.global_transform

	bullet_instance.global_transform = transform_end_of_gun
	
	get_tree().root.add_child(bullet_instance)

	
	
