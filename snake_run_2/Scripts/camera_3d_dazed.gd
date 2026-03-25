
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

# === Motion feel ===
@export var wobble_speed: float = 1.0 # Hz-ish feel controller
@export var z_wobble_scale: float = 0.6 # Z usually feels harsher—scale it down a bit

# === Internal state ===
var _t := 0.0
var _intensity :float  = 0.0 # 0..1 driven by tween
var _current_tween: Tween

# Optional: link to the color overlay to feed intensity
@export var color_filter_path: NodePath
var _color_filter :ColorRect = null




func _ready() -> void:
	if color_filter_path != NodePath():
		_color_filter = get_node_or_null(color_filter_path)
		


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
	rotation_degrees = Vector3(w2 * rotation_amt_deg * 0.35,w  * rotation_amt_deg,sin(_t * wobble_speed * 0.6) * rotation_amt_deg * z_wobble_scale)
	
	
		# Feed intensity to overlay if present
	if _color_filter and _color_filter.has_method("set_intensity"):
		_color_filter.set_intensity(_intensity)
	
	if Input.is_action_just_pressed("ui_accept"):
		on_player_bitten()

# Call this when the player gets bitten.
func on_player_bitten() -> void:
	# If we’re already in a cycle, restart cleanly
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		# Create a fresh tween with nice easing
	_current_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_current_tween.tween_property(self, "_intensity", 1.0, ramp_up_time)
	_current_tween.tween_interval(mature_hold_time)
	_current_tween.tween_property(self, "_intensity", 0.0, ramp_down_time)
	
	

	
