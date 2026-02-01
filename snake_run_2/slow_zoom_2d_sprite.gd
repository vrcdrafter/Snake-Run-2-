extends Sprite2D


@export var base_scale: Vector2 = Vector2.ONE        # The average (center) scale
@export var amplitude: float = 0.15                   # How much it grows/shrinks around the base
@export var frequency_hz: float = 0.25                # Oscillations per second (lower = slower)

var _t: float = 0.0

var image_1 :Resource = preload("res://textures/tip_get_gun.png")
var image_2 :Resource = preload("res://textures/tip_help_player.png")

@onready var images :Array = [image_1, image_2]

@onready var label_text :Label = get_node("../Label2")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	var random_image  = images.pick_random()
	self.texture = random_image
	
	var index_image :int = images.find(random_image)
	
	match  index_image:
		0:
			label_text.text = "Having a hard time , Get a weapon "
		1:
			label_text.text = "If you can , try and save your buddy"
			
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_t += delta
	var offset := sin(TAU * frequency_hz * _t) * amplitude
	scale = base_scale * (1.0 + offset)
	
