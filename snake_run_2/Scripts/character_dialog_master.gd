extends Node3D


@onready var Bubble :DialogueBubble = get_node("discussion")

@onready var audio_player :AudioStreamPlayer = get_node("AudioStreamPlayer")

var dialoge_accum :float = 0 
var dialoge_time :float = 5.0
var start_timer :bool = false

@onready var VHS_ICON :AnimatedSprite2D = get_node("/root/Node/vhs_icon")
@onready var gold_ICON :AnimatedSprite2D = get_node("/root/Node/gold_icon")
@onready var chair_ICON :AnimatedSprite2D = get_node("/root/Node/chair_icon")

func  _ready() -> void:
	
	Bubble.custom_effects[0].char_displayed.connect(_on_char_displayed)
	

	
	
	


func _process(delta: float) -> void:
	
	if start_timer:
		dialoge_accum += delta
		
		if dialoge_accum > dialoge_time:
			start_timer = false
			Bubble.stop()
			dialoge_accum = 0 
			VHS_ICON.visible = true
			var tween1 = create_tween()
			tween1.tween_property(VHS_ICON, "scale", Vector2(.5,.5), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
			tween1.tween_property(VHS_ICON, "scale", Vector2(1,1), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			
			var tween = create_tween()
			
			gold_ICON.visible = true
			tween.tween_property(gold_ICON, "scale", Vector2(.5,.5), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.tween_property(gold_ICON, "scale", Vector2(1,1), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			chair_ICON.visible = true
			var tween2 = create_tween()
			tween2.tween_property(chair_ICON, "scale", Vector2(.5,.5), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
			tween2.tween_property(chair_ICON, "scale", Vector2(1,1), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	#Bubble.follow_node = self
	Bubble.smooth_follow


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player_ai_area"):
		Bubble.start("1")
		start_timer = false
		dialoge_accum = 0 
	
func _on_char_displayed(_idx):
	audio_player.play()


func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player_ai_area"):
		start_timer = true
