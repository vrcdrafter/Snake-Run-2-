
extends Camera3D

# === Base look ===
@export var base_fov: float = 70.0

# === Max intensities when fully ramped ===
@export var max_fov_amount: float = 12.0
@export var max_rotation_amt_deg: float = 22.0

# === Timings (seconds) ===
@export var ramp_up_time: float = 4
@export var mature_hold_time: float = 20.0

@export var ramp_down_time: float = 1.25
var timer_start :bool = false
var poison_accumulator :float = 0
var poison_time :float = 0

# === Motion feel ===
@export var wobble_speed: float = 1.0 # Hz-ish feel controller
@export var z_wobble_scale: float = 0.6 # Z usually feels harsher—scale it down a bit

# === Internal state ===
var _t := 0.0
var _intensity :float  = 0.0 # 0..1 driven by tween
var _current_tween: Tween

# poison node 
@onready var  sprite_poison :AnimatedSprite2D = get_node("../../poison")
@onready var health_2 :AnimatedSprite2D = get_node("../../health2")

# Optional: link to the color overlay to feed intensity

@onready var _color_filter :ColorRect = get_node("../../../ColorRect")

var player_bitten :Node3D 
var position_bitten :Vector3 

var timer_re_connect :float = 5.0
var timer_accumulator :float = 0 

@onready var player_script :CharacterBody3D = get_node("../..")



func _ready() -> void:
	health_2.frame = 6
	poison_time = mature_hold_time
	remake_connections()
	sprite_poison.frame = 0
	var player_base :CharacterBody3D = self.get_parent().get_parent()
	var lose_bite = Callable(self, "_reset_bitten")
	player_base.connect("dead",lose_bite)
	print("test")
	


func _process(delta: float) -> void:
	_t += delta
	# Drive amounts from current intensity
	var fov_amount :float = lerp(0.0, max_fov_amount, _intensity)
	var rotation_amt_deg :float = lerp(0.0, max_rotation_amt_deg, _intensity)
	# Wobble
	var w := sin(_t * wobble_speed)
	var w2 := cos(_t * wobble_speed * 0.9)
	# FOV breathing tied to intensity
	
	fov = base_fov + w * fov_amount
	# Triple-axis wobble — Z tamed a bit
	

	
	# problem occurs here , if the player dies, the camera goes to a position that shows the ragdoll, 
	# but then the line below resets the rotation >=( , 
	if timer_start:
		poison_accumulator += delta
		var value = poison_accumulator
		var result = (value / 20.0) * 9.0 # Result: 9.0
		var integer_result = int(round(result)) # Rounded to 9
		sprite_poison.frame = integer_result
		if poison_accumulator > poison_time:
			timer_start = false
			poison_accumulator = 0
			sprite_poison.frame = 0

		
		
	var health_read = player_script.health
	if health_read > 0:
		rotation_degrees = Vector3(w2 * rotation_amt_deg * 0.35,w  * rotation_amt_deg,sin(_t * wobble_speed * 0.6) * rotation_amt_deg * z_wobble_scale)
		health_2.frame = 6
	# do a health check for the bar 
	if health_read < 100:
		var result = (health_read / 100.0) * 6.0 # Result: 9.0
		var integer_result = int(round(result)) # Rounded to 9
		health_2.frame = integer_result
	
		# Feed intensity to overlay if present
	if _color_filter and _color_filter.has_method("set_intensity"):
		_color_filter.set_intensity(_intensity)
	
	timer_accumulator += delta
	if timer_accumulator > timer_re_connect:
		remake_connections()
		timer_accumulator = 0 


# Call this when the player gets bitten.
func on_player_bitten() -> void:
	timer_start = true
	# If we’re already in a cycle, restart cleanly
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		# Create a fresh tween with nice easing
	_current_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_current_tween.tween_property(self, "_intensity", 1.0, ramp_up_time)
	_current_tween.tween_interval(mature_hold_time)
	_current_tween.tween_property(self, "_intensity", 0.0, ramp_down_time)
	
func remake_connections():
	
	var all_snakes :Array = get_tree().get_nodes_in_group("snake")
	var _snake_bitten_callable = Callable(self, "_on_snake_bitten")
	for n in all_snakes:
		
		if not n.is_connected("venom_bite", _snake_bitten_callable):
			n.connect("venom_bite", _snake_bitten_callable)
			
			
func _on_snake_bitten(player_node):
	if self.get_parent().get_parent() == player_node:
		on_player_bitten()

func _reset_bitten(player_node):
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		_current_tween = null
	_intensity = 0.0
	_t = 0.0
	fov = base_fov
	rotation = Vector3.ZERO
	if _color_filter and _color_filter.has_method("set_intensity"):
		_color_filter.set_intensity(0.0)
