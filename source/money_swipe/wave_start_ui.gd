extends Control

@onready var _button: Button = $Button


func _ready() -> void:
	_button.pressed.connect(_on_start_day_pressed)


func _on_start_day_pressed() -> void:
	EventBus.send_event(WaveStartedEvent.new())
