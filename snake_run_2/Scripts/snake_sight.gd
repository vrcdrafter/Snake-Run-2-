extends Area3D


signal found_player(player_id :Node3D)

func _on_body_entered(body: Node3D) -> void:
	
	if body.name.contains("Player"):
		
		found_player.emit(body)
