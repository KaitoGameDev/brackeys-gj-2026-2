class_name ClientSpawner extends Node3D

var client_scene: PackedScene = preload("res://source/clients/client.tscn")

@export var client_resources: Array[ClientResource]
@export var wave_controller: WaveController

@onready var origin: Marker3D = $Origin
@onready var end: Marker3D = $End

var current_client: Client = null
var _spawning_enabled: bool = false
var _game_over: bool = false


func _ready() -> void:
	EventBus.on_event.connect(_on_event)


func _on_event(event: Object) -> void:
	if _game_over:
		return
	if event is OnGameOver:
		_game_over = true
		_spawning_enabled = false
		return
	if event is WaveStartedEvent:
		if wave_controller != null and wave_controller.can_start_wave():
			_spawning_enabled = true
			spawn_client()
	elif event is WaveCompletedEvent:
		_spawning_enabled = false
	elif event is MoneyDestroyedEvent:
		if not _spawning_enabled:
			return
		if wave_controller != null and wave_controller.is_pending_wave_complete():
			_spawning_enabled = false
			dismiss_current_client()
			return
		spawn_client.call_deferred()


func dismiss_current_client() -> void:
	if current_client == null:
		return

	var departing: Client = current_client
	current_client = null
	departing.finished_transition.connect(
		func():
			departing.queue_free.call_deferred()
	)
	departing.move_to(end.position, true)


func spawn_client() -> void:
	var resource : ClientResource = client_resources.pick_random()
	if current_client and current_client.client_resource == resource:
		spawn_client()
		return
	var previous_client: Client = current_client
	current_client = client_scene.instantiate()
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
