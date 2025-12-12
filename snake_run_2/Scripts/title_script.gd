extends Control

const path :String = "user://.save"

var data = "1"

var file :FileAccess

@onready var path_handle :PathFollow3D = get_node("../Path3D/PathFollow3D")

var camera_position :String 


var level_array : Array[String] = ["Jungle", "Winter forest", "Office"]
var current_index : int = 0


var current_selected_level :String = "Jungle"


var target_progress: float = 0.0
var lerp_speed: float = 2.0  # Adjust for smoothness

@onready var sound_menu :AudioStreamPlayer = get_node("../AudioStreamPlayer")

@onready var terminal :Label = $Label
func _ready() -> void:
	
	$TextureButton4.disabled = false
	
	#build a file so its ready 
	print("Starting at:", level_array[current_index])
	if FileAccess.file_exists(path):
		#do a read 
		file = FileAccess.open(path,FileAccess.READ)
		print("data esists")
		terminal.text = "file already exists \n"
		terminal.text = "is is here \n " + file.get_path_absolute() + "\n"
		# load it 
		
		
		terminal.text = load_game() +"\n"
		$Label2.text = "Jungle"
		
		# close the file 
		print(file.get_path_absolute())
		
	else:
		# make a new one and make a default value 
		
		file = FileAccess.open(path,FileAccess.WRITE)
		save(data)
		print("file does not exist we made one here ",file.get_path_absolute())
		terminal.text = "file does not exist we made one here \n " + file.get_path_absolute()
		file.close()
	print(load_game())
	
	# asses what levels the player gets 
	
	target_progress = 21.37
	
func _process(delta: float) -> void:
	match current_selected_level:
		"Jungle":
			target_progress = 21.37
			$Label2.text = "Jungle"
		"Winter forest":
			target_progress = 19.34
			$Label2.text = "Winter forest"
		"Office":
			target_progress = 12.28
			$Label2.text = "Office"
	path_handle.progress = lerp(path_handle.progress, target_progress, delta * lerp_speed)
	
func save(content):
	
	file.store_string(content)
	
func load_game():
	var file = FileAccess.open(path,FileAccess.READ)
	var content = file.get_as_text()
	return content
	
	

func level_access(current_level: int) -> void:
	var save_raw: String = load_game().strip_edges()
	var highest_unlocked: int = 0

	highest_unlocked = int(save_raw)
		
	$TextureButton4.disabled = current_level >= highest_unlocked
			



func setup_level():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GlobalVars.game_started = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)





func _on_texture_button_2_pressed() -> void:
	current_index -= 1
	
	if current_index < 0:
		current_index = level_array.size() - 1  # Loop to the last item
	print("Selected level:", level_array[current_index])
	current_selected_level = level_array[current_index]
	level_access(current_index)
	sound_menu.play()


func _on_texture_button_pressed() -> void:
	current_index += 1
	if current_index >= level_array.size():
		current_index = 0  # Loop back to start
	print("Selected level:", level_array[current_index])
	current_selected_level = level_array[current_index]
	level_access(current_index)
	sound_menu.play()





func _on_texture_button_4_pressed() -> void:
	GlobalVars.next_level = "res://Scenes/"+current_selected_level+".tscn"
	get_tree().change_scene_to_file("res://Scenes/loading.tscn")
	
	setup_level()
