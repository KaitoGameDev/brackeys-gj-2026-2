class_name GameOverScreen extends Control

@export var score_controller: ScoreController

@onready var exit_btn: Button = $ExitBtn
@onready var final_score_count: Label = $FinalScoreCount


func _ready() -> void:
	exit_btn.pressed.connect(_on_exit_btn_pressed)
	EventBus.on_event.connect(_on_event)


func _on_event(event: Object) -> void:
	if event is OnGameOver:
		_update_final_score()


func _update_final_score() -> void:
	if score_controller == null:
		push_error("GameOverScreen: assign score_controller in the inspector.")
		return
	final_score_count.text = str(score_controller.get_score())


func _on_exit_btn_pressed() -> void:
	AudioController.on_click()
	AudioController.play_bgm("main")
	get_tree().change_scene_to_file("res://source/main_menu.tscn")
