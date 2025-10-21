extends Node3D

var array2 = ["Spine.001","Spine.002","Spine.003","Spine.004"]

var timer :float = .1
var tail_accumulator :float = 0
var oneshot_bool :bool = true
func _ready() -> void:
	pass
	
	#$"Armature (Mecha g)/Skeleton3D/PhysicalBoneSimulator3D".physical_bones_start_simulation(array2)
func _process(delta: float) -> void:
	
	tail_accumulator += delta
	if oneshot_bool: 
		if tail_accumulator > timer:
			#$"Armature (Mecha g)/Skeleton3D/PhysicalBoneSimulator3D".physical_bones_start_simulation(array2)
			$AnimationPlayer.play("wag")
			tail_accumulator = 0 
		oneshot_bool = false
	
