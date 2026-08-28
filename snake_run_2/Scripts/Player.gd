extends CharacterBody3D

const ACCEL = 10
const DEACCEL = 30

const SPEED = 7
const SPEED_CONTROLLER = 9
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
var held = false
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
var nommed_oneshot :bool = true

signal dead(player_id :CharacterBody3D)
var previous_thing_ensnared :Node3D
var current_thing_ensnared :Node3D
var player_ensnared :Node3D
var position_ensnared :Vector3
var snake_stength :int
var active_strength :float = 0 # not sure why I need this . 
 
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
var health_hurt_speed_local :float = 0 

var remake_connections_accuulator :float = 0 
var timer_remake_connections :float = 2

# audio bools 
var play_walk_once :bool = true

@onready var sound_shape :CollisionShape3D = get_node("Sound_area/CollisionShape3D")
var box_shape :BoxShape3D

var has_weapon :bool = false

## This is the strength at which snakes have on the player when ensnared 


@onready var treasure_1_icon :AnimatedSprite2D = get_node("/root/Node/treasure_1_icon")
@onready var treasure_2_icon :AnimatedSprite2D = get_node("/root/Node/treasure_2_icon")
@onready var treasure_3_icon :AnimatedSprite2D = get_node("/root/Node/treasure_3_icon")




@onready var respawn_point :Marker3D = get_node("../../../../spawn_point_1")

var item_accumulator :int = 3

var respawn_timer :float = 1.0
var respawn_accumulator :float = 0 

var treasure_counter :float = 0 

signal can_leave

var snake_that_nommed :Node3D = null
var snake_that_nommed2 :Node3D = null # because the first did not work . 

@onready var yaw_pivot = $Cam_origin
@onready var pitch_pivot = $Cam_origin/Cam_pitch

var yaw := 0.0

var pitch := 0.0
@export var sens :float = .5

#nomming variables 
var struggle = 0.0
const MAX_STRUGGLE = 1.0
const PUSH_SPEED = 8
const RETURN_SPEED = 1.5

var skin_material :Material = null
 

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

	
	box_shape = sound_shape.shape
	if box_shape is BoxShape3D:
		box_shape.size = Vector3(5, 5, 5)  # Set to desired size
	
		
		
	if has_weapon:
		$BoneAttachment3D/MeshInstance3D.set_visible(true)
	else:
		$BoneAttachment3D/MeshInstance3D.set_visible(false)
		






func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_released("Debug_orphans"):
		print_orphan_nodes()
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()





func _physics_process(delta: float) -> void:
	
	if GlobalVars.items_collected >= 3:
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
		$rotation_helper/Camera3D.global_transform = $rotation_helper/Camera3D.global_transform.interpolate_with($Marker3D.global_transform,1)

		
		respawn_accumulator += delta
		if respawn_accumulator > respawn_timer:
			respawn()
			respawn_accumulator = 0 
		# start rebirth timer 
	elif held:
		
		if nommed_oneshot:
			make_inert()
			# make camera not defautl 
			$rotation_helper/Camera3D.current = false
	
			$Cam_origin/Cam_pitch/SpringArm3D/Camera3D.current = true
			player_id = find_id()
			nommed_oneshot = false
			dead.emit(self) # your not really dead but undetected. 
		# now you need to move the player to that snake anchor point . 
				# camera stuff 
		var anchor :Marker3D = snake_that_nommed2.get_node("player_internal_anchor/player_pos")
		var follow_speed := 6.0
		self.global_position = global_position.lerp(anchor.global_position,follow_speed * delta) # this makes it softer . 
		event = top_container_handle.mouse_event
		if previous_event == event:
			event = Vector2(0,0)
		else:
			previous_event = event
		
		yaw -= event.x * sens
		pitch -= event.y * sens
		pitch = clamp(pitch, -90, 45)
		yaw_pivot.rotation_degrees.y = yaw
		pitch_pivot.rotation_degrees.x = pitch
		
		# run the struggle stuff too 
		run_struggle(player_id,delta,skin_material)
		
	else:
		
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
				if is_on_floor():
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
					$AudioStreamPlayer.stop()
					play_walk_once = true
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
			
			if Input.is_action_just_pressed("jump_p"+player_id) and is_on_floor():
				velocity.y = JUMP_VELOCITY
			
			var direction :Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * accel * delta
			
			if Input.is_action_pressed("sprint_p"+player_id):
				direction = direction * SPRINT_MULT
				# speed up animations too 

			if direction:
				if is_on_floor():
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
					$AudioStreamPlayer.stop()
					play_walk_once = true
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
		
		if ensnared or held: # remember ensnared needs to be player indendent , plain signals is not good enough 
			# decrement health too 
			health_accumulator += delta
			if health_accumulator > health_decrement_timer and ensnared:
				health -= health_hurt_speed_local
				
				health_accumulator = 0
			time+= delta

			slow_move_back(ensnared_position,delta,wave(1,8,time,delta)+active_strength)
			var distance_to_free = (ensnared_position-self.get_global_position()).length()
			if ((ensnared_position-self.get_global_position()).length() > .58):
				snakes_around_you = 0 
				ensnared = false
				held = false
				
			if health < 0:
				death_oneshot = true
				ensnared = false
				held = false
				# turn off ability to be detected by snake 
				collision_layer = 0
				dead.emit(self)
				
				

		

func _on_button_button_down():
	
	emit_signal("remove_mouse")
	GlobalVars.game_started = true

func _on_snake_ensnared(player_ensnared,position_ensnared,snake_stength,health_hurt_speed,test):

	if self == player_ensnared:
		health_hurt_speed_local = health_hurt_speed
		active_strength = snake_stength
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
	var callable_nommed = Callable(self, "been_nommed")
	var test
	var test2
	var test3
	var health_hurt_speed 
	for n in all_snakes:
		
		if not n.is_connected("ensnared",callable_ensnare.bind([player_ensnared,position_ensnared,snake_stength,health_hurt_speed,test])):
			n.connect("ensnared",callable_ensnare.bind([player_ensnared,position_ensnared,snake_stength,health_hurt_speed,test]))
			n.connect("dead_snake",callable_dead_snake.bind([snake_that_died,test]))
			n.connect("nommed",callable_nommed.bind([snake_that_nommed,position_ensnared,skin_material,test]))
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
					
				else :
					
					$pickup.global_position = Vector2i(270,311)
					
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
			if item_name == "treasure_1":
				treasure_1_icon.frame = 1
				GlobalVars.items_collected += 1
			elif item_name.contains("treasure_2"):
				
				GlobalVars.items_collected += .25 # because there is 4 of them 
				treasure_counter += .25
				if treasure_counter == 1.0:
					treasure_2_icon.frame = 1
			elif item_name == "treasure_3":
				treasure_3_icon.frame = 1
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
	
	
func respawn():
	self.global_position = respawn_point.global_position
	death_oneshot = false
	$"source_fox/Armature (Mecha g)/Skeleton3D/PhysicalBoneSimulator3D".physical_bones_stop_simulation()
	$rotation_helper/Camera3D.position = Vector3(0, .821, -.338)
	$rotation_helper/Camera3D.rotation = Vector3(0,0,0)
	health = 100
	
func been_nommed(snake_that_nommed,position_ensnared,skin_material_2,test):
	print("been eaten")
	# we need to do a few special and odd things here . we need to disable key input . 
	# we need to remove the colission all of the 
	snake_that_nommed2 = snake_that_nommed
	held = true
	nommed_oneshot = true
	skin_material = skin_material_2

	
	pass
	
func make_inert():
	# so this function takes all of the 
	# get the current mask settings . 
	var current_mask :int = collision_mask
	var current_layer :int = collision_layer
	self.hide()
	# make them 0 
	collision_mask = 0 
	collision_layer = 0 
	
	# no more movement. 
	velocity = Vector3.ZERO
	# how do I turn off the gravity on kinematic body ? 
	$Sound_area.monitorable = false 
	# reset that rotaiton helper to 0 
	
	pass
	

	
func run_struggle(player_id:String, delta:float, material:Material):
	var dir = Input.get_axis("player_initial_left","player_initial_right")
	struggle += dir * PUSH_SPEED * delta
	struggle = clamp(
		struggle,
		-MAX_STRUGGLE,
		MAX_STRUGGLE
		)
	if abs(dir) < 0.01:
		struggle = move_toward(
		struggle,
		0.0,
		RETURN_SPEED * delta
		)
	material.set_shader_parameter(
		"struggle_offset",
		struggle
		)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
