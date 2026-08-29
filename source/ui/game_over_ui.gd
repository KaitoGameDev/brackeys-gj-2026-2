extends Control

@onready var _restart_button: Button = $Panel/Button


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_pressed)


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://source/main_menu.tscn")
