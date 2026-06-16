extends AudioStreamPlayer

var walking_sound: AudioStream = preload("res://sounds/walking_office.wav") # needs to be preload

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	var level_its_on :String = GlobalVars.next_level
	
	print("its the level ", level_its_on)
	if level_its_on == "res://Scenes/Office.tscn":
		stream = walking_sound
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
