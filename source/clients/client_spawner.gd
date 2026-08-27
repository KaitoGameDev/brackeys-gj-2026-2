class_name ClientSpawner extends Node3D

var client_scene: PackedScene = preload("res://source/clients/client.tscn")

@export var client_resources: Array[ClientResource]

@onready var origin: Marker3D = $Origin
@onready var end: Marker3D = $End

var current_client: Client
var count: int = 0

func _ready() -> void:
	spawn_client.call_deferred()
#	get_tree().create_timer(2.0).timeout.connect(spawn_client)
#	get_tree().create_timer(8.0).timeout.connect(spawn_client)
#	get_tree().create_timer(16.0).timeout.connect(spawn_client)
	
func spawn_client() -> void:
	var next_client: Client = client_scene.instantiate()
	var resource : ClientResource = client_resources[count]
	count += 1
	next_client.setup(resource)
	add_sibling(next_client)
	next_client.global_position = origin.global_position
	
	if current_client:
		current_client.move_to(end.global_position, true)
	else:
		current_client = next_client
	
	current_client.finished_transition.connect(
		func():
			current_client.queue_free.call_deferred()
			current_client = next_client
	)
		
	if next_client:
		next_client.move_to(global_position)
