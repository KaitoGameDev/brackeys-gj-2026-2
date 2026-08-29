extends Node

@export var wave_start_container: Control
@export var game_over_container: Control


func _ready() -> void:
	if wave_start_container == null:
		push_error("UIController: assign wave_start_container in the inspector.")
		return
	if game_over_container == null:
		push_error("UIController: assign game_over_container in the inspector.")
		return

	EventBus.on_event.connect(_on_event)
	hide_game_over()
	show_wave_start()


func _on_event(event: Object) -> void:
	if event is WaveStartedEvent:
		hide_wave_start()
	elif event is WaveCompletedEvent:
		show_wave_start()
	elif event is OnGameOver:
		hide_wave_start()
		show_game_over()


func show_wave_start() -> void:
	wave_start_container.visible = true


func hide_wave_start() -> void:
	wave_start_container.visible = false


func show_game_over() -> void:
	game_over_container.visible = true


func hide_game_over() -> void:
	game_over_container.visible = false
