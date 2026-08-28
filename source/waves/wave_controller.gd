extends Node

@export var money_swipe_controller: Node
@export var wave_label: Label
@export var bill_auth_label: Label
@export var wave_progress_bar: ProgressBar
@export var waves: Array[WaveConfig] = []

@export_group("Progress")
@export var progress_tween_duration: float = 0.35
@export var progress_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var progress_ease: Tween.EaseType = Tween.EASE_OUT

var _wave_index: int = 0
var _spawned_in_wave: int = 0
var _completed_in_wave: int = 0
var _awaiting_destroy: bool = false
var _progress_tween: Tween


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
	if wave_progress_bar == null:
		push_error("WaveController: assign wave_progress_bar in the inspector.")
		return
	if waves.is_empty():
		push_error("WaveController: waves must contain at least one WaveConfig.")
		return
	if not money_swipe_controller.has_method("spawn_money"):
		push_error("WaveController: money_swipe_controller must expose spawn_money().")
		return

	EventBus.on_event.connect(_on_event)
	_update_wave_label()
	_update_wave_progress(false)
	#_try_spawn_next()


func _on_event(event: Object) -> void:
	if event is MoneyDestroyedEvent:
		_on_money_destroyed()
	if event is OnClientEntered:
		_try_spawn_next()


func _on_money_destroyed() -> void:
	_awaiting_destroy = false
	_completed_in_wave += 1
	_update_wave_progress()

	var current_wave := waves[_wave_index]
	#if _spawned_in_wave < current_wave.money_count:
		#_try_spawn_next()
		#return

	if _wave_index + 1 < waves.size():
		_wave_index += 1
		_spawned_in_wave = 0
		_completed_in_wave = 0
		_update_wave_label()
		_update_wave_progress(false)
		#_try_spawn_next()


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


func _update_wave_progress(animate: bool = true) -> void:
	var total := waves[_wave_index].money_count
	wave_progress_bar.max_value = total
	var target := float(_completed_in_wave)

	if _progress_tween != null and _progress_tween.is_valid():
		_progress_tween.kill()

	if not animate or progress_tween_duration <= 0.0:
		wave_progress_bar.value = target
		return

	_progress_tween = create_tween()
	_progress_tween.set_trans(progress_trans)
	_progress_tween.set_ease(progress_ease)
	_progress_tween.tween_property(wave_progress_bar, "value", target, progress_tween_duration)


func _update_bill_auth_label(is_fake: bool) -> void:
	bill_auth_label.text = "Fake: Yes" if is_fake else "Fake: No"
