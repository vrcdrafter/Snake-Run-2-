extends Node


var ping_controllers :bool = true 


func _ready() -> void:
	
	var callable = Callable(self, "act_on_connection")
	#start initial scene with one
	
	Input.joy_connection_changed.connect(callable)

func _process(delta: float) -> void:
	
	Input.joy_connection_changed
	
	
	if ping_controllers:
		assess_controllers()
		ping_controllers = false




func assess_controllers():
	
	print("so these are the controllers connected at astartup", Input.get_connected_joypads())


func act_on_connection(_device, _connected):
	print("hey you connected something, it was ",_device, " its plugged in ",_connected)
	# if more controllerd added after scene started shift number +1 
