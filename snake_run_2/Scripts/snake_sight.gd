extends Area3D


signal found_player(player_id :Node3D)



func _on_area_entered(area: Area3D) -> void:
# need to add logic here so that the snake detect the player 
	if area.is_in_group("Player"):
		print(" here is the large area")
		var name_specific = area.name
		found_player.emit(area.get_parent())

		
	if area.is_in_group("NPC"):
		found_player.emit(area.get_parent())
