extends Area3D


signal found_player(player_id :Node3D)



func _on_area_entered(area: Area3D) -> void:

	if area.is_in_group("Player"):
		print(" here is the large area")
		found_player.emit(area.get_parent())
