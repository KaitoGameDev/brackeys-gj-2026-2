class_name WaveController
extends Node

@export var money_swipe_controller: Node
@export var wave_label: Label
@export var bill_auth_label: Label
@export var wave_progress_bar: ProgressBar
@export var waves: Array[WaveConfig] = []

@export_group("Patience")
@export var patience_trans: Tween.TransitionType = Tween.TRANS_LINEAR
@export var patience_ease: Tween.EaseType = Tween.EASE_IN_OUT

@export_group("Wave Label Pop")
@export var wave_label_pop_scale: float = 1.35
@export var wave_label_pop_grow_duration: float = 0.12
@export var wave_label_pop_shrink_duration: float = 0.15

var _wave_index: int = 0
var _spawned_in_wave: int = 0
var _completed_in_wave: int = 0
var _awaiting_destroy: bool = false
var _wave_active: bool = false
var _pending_wave_complete: bool = false
var _patience_tween: Tween
var _patience_running: bool = false
var _patience_paused: bool = false
var _patience_total_duration: float = 0.0
var _wave_label_pop_tween: Tween
var _game_over: bool = false


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
	if not money_swipe_controller.has_method("destroy_current_money"):
		push_error("WaveController: money_swipe_controller must expose destroy_current_money().")
		return

	EventBus.on_event.connect(_on_event)
	_update_wave_label(false)
	wave_progress_bar.max_value = 1.0
	wave_progress_bar.value = 1.0
	wave_progress_bar.value_changed.connect(
		func(value):
			if value <= 0.3:
				wave_progress_bar.get_theme_stylebox("fill").bg_color = Color.RED
			elif value <= 0.6:
				wave_progress_bar.get_theme_stylebox("fill").bg_color = Color.ORANGE
			else:
				wave_progress_bar.get_theme_stylebox("fill").bg_color = Color.GREEN
	)


func _on_event(event: Object) -> void:
	if _game_over:
		return
	if event is OnGameOver:
		_on_game_over()
		return
	if event is WaveStartedEvent:
		if can_start_wave():
			_wave_active = true
			_update_wave_label(true, true)
	if event is MoneySwipedEvent:
		_stop_patience_meter()
	if event is MoneyDestroyedEvent:
		_stop_patience_meter()
		_on_money_destroyed()
	if event is OnClientEntered:
		_try_spawn_next()
	if event is OnClientExited:
		_on_client_exited()
	if event is HelpFolderOpenedEvent:
		_pause_patience_meter()
	if event is HelpFolderClosedEvent:
		_resume_patience_meter()


func _on_money_destroyed() -> void:
	_awaiting_destroy = false
	_completed_in_wave += 1

	var current_wave := waves[_wave_index]
	
	_update_wave_label()
	
	if _completed_in_wave < current_wave.money_count:
		return

	_wave_active = false
	_pending_wave_complete = true

	if _wave_index + 1 < waves.size():
		_wave_index += 1
		_spawned_in_wave = 0
		_completed_in_wave = 0
		_update_wave_label(true, true)


func _on_client_exited() -> void:
	if not _pending_wave_complete:
		return

	_pending_wave_complete = false
	EventBus.send_event(WaveCompletedEvent.new())


func _on_game_over() -> void:
	_game_over = true
	_wave_active = false
	_stop_patience_meter()

func _try_spawn_next() -> void:
	if not _wave_active:
		return
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
	money_swipe_controller.spawn_money(is_fake, alter_count, current_wave.bill_pool)
	_spawned_in_wave += 1
	_awaiting_destroy = true
	_start_patience_meter()


func _start_patience_meter() -> void:
	_stop_patience_meter()
	var duration := waves[_wave_index].patience_duration
	if duration <= 0.0:
		return
	_patience_total_duration = duration
	wave_progress_bar.max_value = 1.0
	wave_progress_bar.step = 0.0
	wave_progress_bar.value = 1.0
	_patience_running = true
	_patience_paused = false
	_patience_tween = create_tween()
	_patience_tween.set_trans(patience_trans)
	_patience_tween.set_ease(patience_ease)
	_patience_tween.tween_property(wave_progress_bar, "value", 0.0, duration)
	_patience_tween.finished.connect(_on_patience_expired, CONNECT_ONE_SHOT)


func _pause_patience_meter() -> void:
	if not _patience_running or _patience_paused:
		return
	_patience_paused = true
	if _patience_tween != null and _patience_tween.is_valid():
		_patience_tween.kill()
	_patience_tween = null


func _resume_patience_meter() -> void:
	if not _patience_paused:
		return
	_patience_paused = false
	if not _patience_running or not _awaiting_destroy or _game_over:
		return

	var remaining_ratio := wave_progress_bar.value
	if remaining_ratio <= 0.0:
		return

	var remaining_duration := _patience_total_duration * remaining_ratio
	if remaining_duration <= 0.0:
		return

	_patience_tween = create_tween()
	_patience_tween.set_trans(patience_trans)
	_patience_tween.set_ease(patience_ease)
	_patience_tween.tween_property(wave_progress_bar, "value", 0.0, remaining_duration)
	_patience_tween.finished.connect(_on_patience_expired, CONNECT_ONE_SHOT)


func _stop_patience_meter() -> void:
	_patience_running = false
	_patience_paused = false
	if _patience_tween != null and _patience_tween.is_valid():
		_patience_tween.kill()
	_patience_tween = null


func _on_patience_expired() -> void:
	if not _patience_running or not _awaiting_destroy:
		return
	_patience_running = false
	EventBus.send_event(PatienceExpiredEvent.new())
	money_swipe_controller.destroy_current_money()


func _update_wave_label(animate: bool = true, force_pop: bool = false) -> void:
	var new_text := "{0}".format([waves[_wave_index].money_count + 1 - _completed_in_wave])
	var text_changed := wave_label.text != new_text
	wave_label.text = new_text
	if animate and (text_changed or force_pop):
		_pop_wave_label()


func _pop_wave_label() -> void:
	wave_label.pivot_offset = wave_label.size * 0.5 if wave_label.size != Vector2.ZERO \
		else wave_label.get_minimum_size() * 0.5
	wave_label.scale = Vector2.ONE

	if _wave_label_pop_tween != null and _wave_label_pop_tween.is_valid():
		_wave_label_pop_tween.kill()

	var peak_scale := Vector2.ONE * wave_label_pop_scale
	_wave_label_pop_tween = create_tween()
	_wave_label_pop_tween.tween_property(wave_label, "scale", peak_scale, wave_label_pop_grow_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_wave_label_pop_tween.tween_property(wave_label, "scale", Vector2.ONE, wave_label_pop_shrink_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _update_bill_auth_label(is_fake: bool) -> void:
	bill_auth_label.text = "Fake: Yes" if is_fake else "Fake: No"


func can_start_wave() -> bool:
	if _wave_index >= waves.size():
		return false
	return _completed_in_wave < waves[_wave_index].money_count


func is_pending_wave_complete() -> bool:
	return _pending_wave_complete


func get_current_wave_bill_pool() -> Array[MoneyResource]:
	if _wave_index >= waves.size():
		return []
	var pool := waves[_wave_index].bill_pool
	if pool.is_empty() and money_swipe_controller != null and "bill_pool" in money_swipe_controller:
		return money_swipe_controller.bill_pool
	return pool


func get_current_wave_number() -> int:
	return _wave_index + 1
