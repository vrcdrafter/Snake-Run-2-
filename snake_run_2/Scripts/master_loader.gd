extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_packs()
	get_tree().change_scene("res://Scenes/title.tscn")

func load_packs():
	var packs :Array = [
	"pack_1.pck",
	"pack_2.pck",
	"pack_3.pck"
	]
	for p in packs:
		var success = ProjectSettings.load_resource_pack(p)
		$Label.text = "Loading " + p + ": " + success
