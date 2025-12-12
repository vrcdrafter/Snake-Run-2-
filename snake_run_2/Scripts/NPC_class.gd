@icon("res://textures/NPC.svg")
extends Node3D
class_name NPC






@export var movement_speed: float = 4.0
@onready var navigation_agent: NavigationAgent3D = get_node("NavigationAgent3D")
var movement_delta: float

	

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)




func _on_velocity_computed(safe_velocity: Vector3) -> void:
	global_position = global_position.move_toward(global_position + safe_velocity, movement_delta)
	
	
func _process_navigation(delta):
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		return

	movement_delta = movement_speed * delta
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = global_position.direction_to(next_path_position) * movement_delta
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
		
func startup_navigation_ready():
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	
	set_movement_target(Vector3(0,0,0))
	
