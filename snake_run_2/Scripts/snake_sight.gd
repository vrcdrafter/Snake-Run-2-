extends Area3D


signal found_player(player_id :Node3D)



func _on_area_entered(area: Area3D) -> void:
# need to add logic here so that the snake detect the player 
	if area.is_in_group("Player"):
		print(" here is the large area")
		var name_specific = area.name
		# so you cant chase a eaten player . just to be sure make sure you didnt eat it . 
		var _player_detected_local :Node = area.get_parent()
		if !_player_detected_local.held:
			found_player.emit(_player_detected_local)

		
	if area.is_in_group("NPC"):
		found_player.emit(area.get_parent())
