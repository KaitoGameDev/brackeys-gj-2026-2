class_name Dialog extends Control

@onready var message: Label = $Text

var _text: String = ""

func _ready() -> void:
	EventBus.on_event.connect(_on_event)

func _on_event(event: Object) -> void:
	if event is OnClientEntered:
		message.text = ""
		_text = event.client_resource.lines.pick_random()
		start_dialog()
	if event is OnClientExited:
		message.text = ""
		AudioController.stop_voice()
	
func start_dialog() -> void:
	visible = true
	AudioController.start_voice()
		
	for c in _text:
		message.text += c

		if c != " ":
			await get_tree().create_timer(0.04).timeout
	
	AudioController.stop_voice()
	
func disable() -> void:
	visible = false
	_text = ""
	message.text = ""
