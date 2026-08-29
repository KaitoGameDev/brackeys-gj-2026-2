class_name Dialog extends Control

@onready var message: Label = $Text

var _text: String = ""

func set_text(txt: String) -> void:
	_text = txt
	
func start_dialog() -> void:
	visible = true
	
	for c in _text:
		message.text += c
		await get_tree().create_timer(0.05).timeout
		AudioController.voice_1()

func disable() -> void:
	visible = false
	_text = ""
	message.text = ""
