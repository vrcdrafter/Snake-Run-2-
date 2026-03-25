extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var path := get_tree().current_scene.scene_file_path  # e.g. "res://scenes/MainMenu.tscn"
	var scene_name := path.get_file().get_basename()      # -> "MainMenu"
	print(scene_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
