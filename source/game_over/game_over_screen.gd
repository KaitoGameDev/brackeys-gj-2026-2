class_name GameOverScreen extends Control

@onready var exit_btn: Button = $ExitBtn

func _ready() -> void:
	exit_btn.pressed.connect(_on_exit_btn_pressed)

func _on_exit_btn_pressed() -> void:
	AudioController.on_click()
	AudioController.play_bgm("main")
	get_tree().change_scene_to_file("res://source/main_menu.tscn")
