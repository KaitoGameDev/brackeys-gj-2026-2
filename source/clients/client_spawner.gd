class_name ClientSpawner extends Node3D

var client_scene: PackedScene = preload("res://source/clients/client.tscn")

@export var client_resources: Array[ClientResource]

@onready var origin: Marker3D = $Origin
@onready var end: Marker3D = $End

var current_client: Client = null

func _ready() -> void:
	spawn_client.call_deferred()
	EventBus.on_event.connect(_on_event)
	
func _on_event(event: Object) -> void:
	if event is MoneyDestroyedEvent:
		spawn_client.call_deferred()
	
func spawn_client() -> void:
	var previous_client: Client = current_client
	current_client = client_scene.instantiate()
	var resource : ClientResource = client_resources.pick_random()
	current_client.setup(resource)
	current_client.visible = false
	current_client.position = origin.position
	
	add_child(current_client)
	
	if previous_client:
		previous_client.finished_transition.connect(
			func():
				previous_client.queue_free.call_deferred()
		)
		previous_client.move_to(end.position, true)
		
	current_client.visible = true
	current_client.move_to.call_deferred(Vector3.ZERO)
