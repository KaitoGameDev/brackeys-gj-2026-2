class_name HelpFolderButton extends TextureButton

@export var help_folder: HelpFolder

func _ready() -> void:
	help_folder.visible = false
	
	pressed.connect(_on_pressed)
	
	
func _on_pressed() -> void:
	AudioController.on_click()
	help_folder.visible = !help_folder.visible
	if help_folder.visible:
		EventBus.send_event(HelpFolderOpenedEvent.new())
	else:
		EventBus.send_event(HelpFolderClosedEvent.new())
