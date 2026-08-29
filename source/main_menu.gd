class_name MainMenu extends Node

@onready var play_btn: Button = $CanvasLayer/ActionButtons/PlayBtn
@onready var credits_btn: Button = $CanvasLayer/ActionButtons/CreditsBtn
@onready var close_btn: Button = $CanvasLayer/CreditsModal/ColorRect/CloseBtn

@onready var credits_modal: Control = $CanvasLayer/CreditsModal

func _ready() -> void:
	play_btn.pressed.connect(_on_play_btn_pressed)
	close_btn.pressed.connect(_on_close_credits_pressed)
	credits_btn.pressed.connect(_on_credits_btn_pressed)
	

func _on_close_credits_pressed() -> void:
	AudioController.on_click()
	credits_modal.visible = false

func _on_play_btn_pressed() -> void:
	AudioController.on_click()
	AudioController.play_bgm("gameplay")
	get_tree().change_scene_to_file("res://source/main.tscn")
	
func _on_credits_btn_pressed() -> void:
	AudioController.on_click()
	credits_modal.visible = true
