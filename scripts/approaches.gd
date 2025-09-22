extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label_left: Label = $LabelLeft
@onready var label_right: Label = $LabelRight

func _ready() -> void:
	animation_player.play("approaches")
	
	animation_player.animation_finished.connect(_on_intro_finished)
	
func _on_intro_finished(_anim_name) -> void:
	queue_free()
