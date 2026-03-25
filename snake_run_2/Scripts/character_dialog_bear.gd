extends Node3D


@onready var Bubble :DialogueBubble = get_node("discussion")

@onready var audio_player :AudioStreamPlayer = get_node("AudioStreamPlayer")

var dialoge_accum :float = 0 
var dialoge_time :float = 5.0
var start_timer :bool = false

@onready var treasure_1_icon :AnimatedSprite2D = get_node("/root/Node/treasure_1_icon")
@onready var treasure_2_icon :AnimatedSprite2D = get_node("/root/Node/treasure_2_icon")
@onready var treasure_3_icon :AnimatedSprite2D = get_node("/root/Node/treasure_3_icon")

var lock_dialogue :bool = true

var dialogue_thread = "4"

func  _ready() -> void:
	
	Bubble.custom_effects[0].char_displayed.connect(_on_char_displayed)
	

	$AnimatedSprite2D.hide()
	$AnimatedSprite2D.play()
	
	


func _process(delta: float) -> void:
	
	if start_timer:
		dialoge_accum += delta
		
		if dialoge_accum > dialoge_time:
			start_timer = false
			
			dialoge_accum = 0 
			treasure_1_icon.visible = true
			var tween1 = create_tween()
			tween1.tween_property(treasure_1_icon, "scale", Vector2(.5,.5), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween1.tween_property(treasure_1_icon, "scale", Vector2(1,1), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			
			var tween = create_tween()
			
			treasure_2_icon.visible = true
			tween.tween_property(treasure_2_icon, "scale", Vector2(.5,.5), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.tween_property(treasure_2_icon, "scale", Vector2(1,1), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			treasure_3_icon.visible = true
			var tween2 = create_tween()
			tween2.tween_property(treasure_3_icon, "scale", Vector2(.5,.5), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween2.tween_property(treasure_3_icon, "scale", Vector2(1,1), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	if Input.is_action_just_pressed("ui_accept") and $AnimatedSprite2D.is_visible_in_tree() and lock_dialogue:
		$AnimatedSprite2D.hide()
		Bubble.start(dialogue_thread)
		
	
	
	#Bubble.follow_node = self
	Bubble.smooth_follow
	
	if GlobalVars.items_collected == 3:

		dialogue_thread = "6"




	
func _on_char_displayed(_idx):
	audio_player.play()





func _on_area_3d_body_entered(body: Node3D) -> void:
	var name_local = body.name
	if name_local == "Physical Bone elbow_r":
		$AnimatedSprite2D.visible = true
		start_timer = false
		dialoge_accum = 0 
		


func _on_area_3d_body_exited(body: Node3D) -> void:
	var name_local = body.name
	if name_local == "Physical Bone elbow_r":
		start_timer = true
		$AnimatedSprite2D.hide()
		Bubble.stop()
		



func _on_discussion_dialogue_processed(speaker: Variant, dialogue: String, options: Array[String]) -> void:
	
	if dialogue.contains("HEY"):
		lock_dialogue = true
		dialogue_thread = "5"
	
