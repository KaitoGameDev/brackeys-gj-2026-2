extends Node

signal on_event(event: Object)

func send_event(event: Object) -> void:
	on_event.emit(event)