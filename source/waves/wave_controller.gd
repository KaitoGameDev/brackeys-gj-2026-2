extends Node

@export var money_swipe_controller: Node
@export var wave_label: Label
@export var bill_auth_label: Label
@export var waves: Array[WaveConfig] = []

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
	if bill_auth_label == null:
		push_error("WaveController: assign bill_auth_label in the inspector.")
		return
	if waves.is_empty():
		push_error("WaveController: waves must contain at least one WaveConfig.")
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

	var current_wave := waves[_wave_index]
	if _spawned_in_wave < current_wave.money_count:
		_try_spawn_next()
		return

	if _wave_index + 1 < waves.size():
		_wave_index += 1
		_spawned_in_wave = 0
		_update_wave_label()
		_try_spawn_next()


func _try_spawn_next() -> void:
	if _awaiting_destroy:
		return
	if _wave_index >= waves.size():
		return

	var current_wave := waves[_wave_index]
	if _spawned_in_wave >= current_wave.money_count:
		return

	var is_fake := randf() < current_wave.fake_chance
	var alter_count := current_wave.fake_alter_count if is_fake else 0
	_update_bill_auth_label(is_fake)
	money_swipe_controller.spawn_money(is_fake, alter_count)
	_spawned_in_wave += 1
	_awaiting_destroy = true


func _update_wave_label() -> void:
	wave_label.text = "Wave %d/%d" % [_wave_index + 1, waves.size()]


func _update_bill_auth_label(is_fake: bool) -> void:
	bill_auth_label.text = "Fake: Yes" if is_fake else "Fake: No"
