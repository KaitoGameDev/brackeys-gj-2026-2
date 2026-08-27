extends Node

@export var money_swipe_controller: Node
@export var wave_label: Label
@export var money_per_wave: Array[int] = [3, 5, 7]

var _wave_index: int = 0
var _spawned_in_wave: int = 0
var _awaiting_destroy: bool = false


func _ready() -> void:
	if money_swipe_controller == null:
		push_error("WaveController: assign money_swipe_controller in the inspector.")
		return
	if wave_label == null:
		push_error("WaveController: assign wave_label in the inspector.")
		return
	if money_per_wave.is_empty():
		push_error("WaveController: money_per_wave must contain at least one wave.")
		return
	if not money_swipe_controller.has_method("spawn_money"):
		push_error("WaveController: money_swipe_controller must expose spawn_money().")
		return

	EventBus.on_event.connect(_on_event)
	_update_wave_label()
	_try_spawn_next()


func _on_event(event: Object) -> void:
	if event is MoneyDestroyedEvent:
		_on_money_destroyed()


func _on_money_destroyed() -> void:
	_awaiting_destroy = false

	if _spawned_in_wave < money_per_wave[_wave_index]:
		_try_spawn_next()
		return

	if _wave_index + 1 < money_per_wave.size():
		_wave_index += 1
		_spawned_in_wave = 0
		_update_wave_label()
		_try_spawn_next()


func _try_spawn_next() -> void:
	if _awaiting_destroy:
		return
	if _wave_index >= money_per_wave.size():
		return
	if _spawned_in_wave >= money_per_wave[_wave_index]:
		return

	money_swipe_controller.spawn_money()
	_spawned_in_wave += 1
	_awaiting_destroy = true


func _update_wave_label() -> void:
	wave_label.text = "Wave %d/%d" % [_wave_index + 1, money_per_wave.size()]
