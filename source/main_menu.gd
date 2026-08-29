class_name MainMenu extends Node

@onready var play_btn: Button = $CanvasLayer/ActionButtons/PlayBtn
@onready var credits_btn: Button = $CanvasLayer/ActionButtons/CreditsBtn

func _ready() -> void:
	play_btn.pressed.connect(_on_play_btn_pressed)
	
	
func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://source/main.tscn")
	
func _on_credits_btn_pressed() -> void:
	pass
