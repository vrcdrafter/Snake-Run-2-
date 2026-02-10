extends CharacterBody3D

const ACCEL = 10
const DEACCEL = 30

const SPEED = 5
const SPEED_CONTROLLER = 7
const SPRINT_MULT = 3
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.12
@onready var animation_tree_new :AnimationTree = get_node("AnimationTree")

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

@onready var grid_container :GridContainer = get_node("../../..")
var get_number_players :int = 0

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

# health stuff 
var health :int = 100
var death_oneshot :bool = false

signal dead 
var previous_thing_ensnared :Node3D
var current_thing_ensnared :Node3D
var player_ensnared :Node3D
var position_ensnared :Vector3
var snake_that_died :Node3D
var snake_previous_state :String
signal player_added

@onready var ray :RayCast3D = get_node("BoneAttachment3D/MeshInstance3D/RayCast3D")
@onready var ray_head :RayCast3D = get_node("rotation_helper/Camera3D/grab")

var can_pickup_item :bool = false
var examined_item :Node = null

var check_stuf_timer_accum :float = 0 
var check_stuf_timer :float = .5

var health_accumulator :float = 0
var health_decrement_timer :float = .1

var remake_connections_accuulator :float = 0 
var timer_remake_connections :float = 2

# audio bools 
var play_walk_once :bool = true

@onready var sound_shape :CollisionShape3D = get_node("Sound_area/CollisionShape3D")
var box_shape :BoxShape3D

var has_weapon :bool = false

## This is the strength at which snakes have on the player when ensnared 
@export var snake_strength :float = 15

@onready var vhs_icon :AnimatedSprite2D = get_node("/root/Node/vhs_icon")
@onready var gold_icon :AnimatedSprite2D = get_node("/root/Node/gold_icon")
@onready var chair_icon :AnimatedSprite2D = get_node("/root/Node/chair_icon")


var item_accumulator :int = 3


signal can_leave

func _ready():
	camera = $rotation_helper/Camera3D
	rotation_helper = $rotation_helper
	$pickup.hide()
	setup_level()
	
	remake_connections()   
	#DOES NOT WORK AND NEEDS TO BE MOVED#
	if GlobalVars.game_started == true:
		emit_signal("remove_mouse")
	
		emit_signal("snakes_go")
		

	
	player_id = find_id()
	print("the player identified is ", player_id)
	
	box_shape = sound_shape.shape
	if box_shape is BoxShape3D:
		box_shape.size = Vector3(5, 5, 5)  # Set to desired size
		print("set")
		
		
	if has_weapon:
		$BoneAttachment3D/MeshInstance3D.set_visible(true)
	else:
		$BoneAttachment3D/MeshInstance3D.set_visible(false)
		






func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()



func _physics_process(delta: float) -> void:
	
	if GlobalVars.items_collected > 3:
		can_leave.emit()
	
	get_number_players = grid_container.get_children().size()
	
	
	var dec_size = box_shape.size.x - 5 * delta
	#print("size of box", dec_size)
	if dec_size < 5:
		pass
	else:
		box_shape.size = Vector3(dec_size,dec_size,dec_size)
	
	remake_connections_accuulator += delta
	if remake_connections_accuulator > timer_remake_connections:
		remake_connections_accuulator = 0 
		remake_connections()
	
	check_ray(delta,ray_head)
	
	
	
	if death_oneshot:

		$"source_fox/Armature (Mecha g)/Skeleton3D/PhysicalBoneSimulator3D".physical_bones_start_simulation()
		
		print("you died")
	
	
	if not death_oneshot:
		
		if player_id == "0": # then its the regular player with mouse and keybaord 
			
			if Input.is_action_just_pressed("shoot"):
				handle_shoot(delta)

			event = top_container_handle.mouse_event
			
			# run a reload if you want 
			if $AnimatedSprite2D2.frame !=0:
				if Input.is_action_just_pressed("reload") and  has_weapon:
					animation_tree_new.set("parameters/reload/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					if $AnimatedSprite2D2.frame != 0:
						$AnimatedSprite2D2.frame -= 1 # decrement that frame
				
				
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
			
		# Handle Jump.
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
			
		else:			
			if Input.is_action_just_pressed("shoot_p" + player_id):
				handle_shoot(delta)

				
			if Input.is_action_just_pressed("reload_p" + player_id):
				animation_tree_new.set("parameters/reload/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			
			var look_stick_angle :Vector2 = Input.get_vector("look_left_p"+player_id,"look_right_p"+player_id,"look_up_p"+player_id,"look_down_p"+player_id)
			
			joy_y_accum = look_stick_angle.y * Joy_sensativity * delta
			rotation_helper.rotate_x(joy_y_accum * -1)
			#joystick left right
			self.rotate_y(look_stick_angle.x * Joy_sensativity * -1 * delta)
		
		
		
		# Add the gravity. Pulls value from project settings.
		if not is_on_floor():
			velocity.y -= gravity * delta



		# This just controls acceleration. Don't touch it.
		var accel
		if dir.dot(velocity) > 0:
			accel = ACCEL
		
		else:
			accel = DEACCEL
		
			
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with a custom keymap depending on your control scheme. These strings default to the arrow keys layout.
		if player_id == "0":
			
			var input_dir :Vector2 = Input.get_vector("player_initial_left", "player_initial_right", "player_initial_forward", "player_initial_backwards")
			direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * accel * delta


			if Input.is_key_pressed(KEY_SHIFT):
			
				
				direction = direction * SPRINT_MULT
				$AudioStreamPlayer.pitch_scale = 1.5
			else:
				$AudioStreamPlayer.pitch_scale = 1

			if direction:
				if play_walk_once:
					$AudioStreamPlayer.play()
					play_walk_once = false
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				if has_weapon:
					animation_tree_new.set("parameters/no_wep/blend_amount", 0)
					animation_tree_new.set("parameters/Blend2/blend_amount", 0)
				else: 
					animation_tree_new.set("parameters/no_wep/blend_amount", 1)
					animation_tree_new.set("parameters/Blend3/blend_amount", -1)
			else:
				play_walk_once = true
				$AudioStreamPlayer.stop()
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
				if has_weapon:
					animation_tree_new.set("parameters/no_wep/blend_amount", 0)
					animation_tree_new.set("parameters/Blend2/blend_amount", 1)
				else:
					animation_tree_new.set("parameters/no_wep/blend_amount", 1)
					animation_tree_new.set("parameters/Blend3/blend_amount", 0)
				

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
				if play_walk_once:
					$AudioStreamPlayer.play()
					play_walk_once = false
				velocity.x = direction.x * SPEED_CONTROLLER
				velocity.z = direction.z * SPEED_CONTROLLER
				if has_weapon:
					animation_tree_new.set("parameters/no_wep/blend_amount", 0)
					animation_tree_new.set("parameters/Blend2/blend_amount", 0)
				else: 
					animation_tree_new.set("parameters/no_wep/blend_amount", 1)
					animation_tree_new.set("parameters/Blend3/blend_amount", -1)
			else:
				play_walk_once = true
				$AudioStreamPlayer.stop()
				velocity.x = move_toward(velocity.x, 0, SPEED_CONTROLLER)
				velocity.z = move_toward(velocity.z, 0, SPEED_CONTROLLER)
				animation_tree_new.set("parameters/Blend2/blend_amount", 1)
				if has_weapon:
					animation_tree_new.set("parameters/no_wep/blend_amount", 0)
					animation_tree_new.set("parameters/Blend2/blend_amount", 1)
				else:
					animation_tree_new.set("parameters/no_wep/blend_amount", 1)
					animation_tree_new.set("parameters/Blend3/blend_amount", 0)

			move_and_slide()
		
		if ensnared: # remember ensnared needs to be player indendent , plain signals is not good enough 
			# decrement health too 
			health_accumulator += delta
			if health_accumulator > health_decrement_timer:
				health -= 1
				$health.value -= 1
				health_accumulator = 0
			time+= delta
			

			slow_move_back(ensnared_position,delta,wave(1,3,time,delta)+snake_strength)
			var distance_to_free = (ensnared_position-self.get_global_position()).length()
			if ((ensnared_position-self.get_global_position()).length() > .58):
				snakes_around_you = 0 
				ensnared = false
				
			if health < 0:
				death_oneshot = true
				ensnared = false
				# turn off ability to be detected by snake 
				collision_layer = 0
				print("the colission should be off now ")
				emit_signal("dead")
				
	else:
		#move camera to death position . 
		$rotation_helper/Camera3D.global_transform = $rotation_helper/Camera3D.global_transform.interpolate_with($Marker3D.global_transform,1)

func _on_button_button_down():
	
	emit_signal("remove_mouse")
	GlobalVars.game_started = true

func _on_snake_ensnared(player_ensnared,position_ensnared,test):
	print("should be ensnared ",player_ensnared.name)
	if self == player_ensnared:
		ensnared = true
		ensnared_position = self.get_global_position() # may want a different position , 
		snakes_around_you += 1
		
func turn_off_ensnared(previous_thing_ensnared,current_thing_ensnared,test,test2):

	if previous_thing_ensnared == self and current_thing_ensnared != self:
		ensnared = false
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
	

	var callable_mouse_button = Callable(self,"_on_button_button_down")
	var callable_ensnare = Callable(self, "_on_snake_ensnared")
	var timer_callable = Callable(self, "_on_game_over_timer_timeout")
	var reset_level = Callable(self,"_on_button_pressed")
	var callable_dead_snake = Callable(self,"turn_off_ensnared")
	var callable_changed_target = Callable(self,"turn_off_ensnared")
	var test
	var test2
	for n in all_snakes:
		
		if not n.is_connected("ensnared",callable_ensnare.bind([player_ensnared,position_ensnared,test])):
			n.connect("ensnared",callable_ensnare.bind([player_ensnared,position_ensnared,test]))
			n.connect("dead_snake",callable_dead_snake.bind([snake_that_died,test]))
			n.connect("let_go_prey",callable_changed_target.bind([previous_thing_ensnared,current_thing_ensnared,test,test2]))
			#	timer_handle.connect("timeout",timer_callable)
#	game_over_button_handle.connect("pressed",reset_level)
	
	
	# walking audio connection 
	if GlobalVars.next_level == "res://Scenes/level_4.tscn":
		print("your in level 4")
		var audio_handle :Area3D = get_node("../sounds/corridore_sound")
		var walk_callable :Callable = Callable(self, "audio_function")
		audio_handle.body_entered.connect(_on_body_entered)

	
	
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

	
func check_ray(delta,ray :RayCast3D):
	if ray.is_colliding():
		var collider :Node = ray.get_collider()
		if collider == null:
			pass
		else:
			if collider.is_in_group("item"):
				
				$pickup.show()
				if get_number_players == 1:
					
					$pickup.global_position = Vector2i(270,311)
					print("halved")
				else :
					
					$pickup.global_position = Vector2i(270,311)
					print("halved")
				$pickup.play()
				
				if has_weapon:
				
					can_pickup_item = true
					animation_tree_new.set("parameters/select_no_wep/blend_amount",0)
					animation_tree_new.set("parameters/select/add_amount", 1)
					animation_tree_new.set("parameters/Add2/add_amount", 0)
					examined_item = collider
					check_stuf_timer_accum = 0
					if collider.is_in_group("ammo"):
						$AnimatedSprite2D2.frame = 3
				else:
					animation_tree_new.set("parameters/select_no_wep/blend_amount",1)
					can_pickup_item = true
					examined_item = collider
					check_stuf_timer_accum = 0
					
	else:
		check_stuf_timer_accum += delta
		$pickup.hide()
	
	if check_stuf_timer_accum > check_stuf_timer:
		can_pickup_item = false
		animation_tree_new.set("parameters/select_no_wep/blend_amount",0)
		animation_tree_new.set("parameters/select/add_amount", 0)
		animation_tree_new.set("parameters/Add2/add_amount", 1)
		examined_item = null
		
func add_ammo():
	
	$AnimatedSprite2D.frame = 0
	
func handle_shoot(delta :float):
					
	if can_pickup_item:
		if examined_item == null:
			pass
		else:
			$got_item.play()

			if examined_item.is_in_group("gun"):
				$AnimatedSprite2D.visible = true
				$AnimatedSprite2D2.visible = true
				has_weapon = true
				$BoneAttachment3D/MeshInstance3D.set_visible(true)
			
			
			examined_item.queue_free()
			var item_name = examined_item.name
			if item_name == "VHS_new":
				
				vhs_icon.frame = 2
				GlobalVars.items_collected += 1
			elif item_name.contains("teasure"):
				gold_icon.frame = 2
				GlobalVars.items_collected += 1
			elif item_name == "game_chair":
				chair_icon.frame = 2
				GlobalVars.items_collected += 1
			else:
				pass
			
			
	elif has_weapon:
		$AnimatedSprite2D.frame += 1
		
		if $AnimatedSprite2D.frame == 19:
			$empty_clip.play()
		else:
			# make it so its loud 
			box_shape.size = Vector3(20,20,20)
			spawn_bullet(delta)
			$BoneAttachment3D/MeshInstance3D/AnimatedSprite3D.play()
			$AudioStreamPlayer2.play()
			animation_tree_new.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	else:
		pass
			
func play_reload_sound():
	$reload.play()
	
