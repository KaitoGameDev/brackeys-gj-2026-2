class_name ScoreController extends Node

@export var wave_controller: WaveController
@export var score_counter: Label

@export_group("Score Pop")
@export var score_pop_scale: float = 1.35
@export var score_pop_grow_duration: float = 0.12
@export var score_pop_shrink_duration: float = 0.15

var _score: int = 0
var _game_over: bool = false
var _score_pop_tween: Tween


func _ready() -> void:
	if wave_controller == null:
		push_error("ScoreController: assign wave_controller in the inspector.")
	if score_counter == null:
		push_error("ScoreController: assign score_counter in the inspector.")

	EventBus.on_event.connect(_on_event)
	_update_label()


func _on_event(event: Object) -> void:
	if event is OnGameOver:
		_game_over = true
		return
	if _game_over:
		return
	if event is MoneySwipedEvent:
		_on_money_swiped(event as MoneySwipedEvent)


func _on_money_swiped(event: MoneySwipedEvent) -> void:
	if wave_controller == null or not _is_correct_swipe(event):
		return

	var bill := event.money_resource
	var wave_number := wave_controller.get_current_wave_number()
	var patience_fill := wave_controller.get_patience_fill_percent()
	var points := _calculate_points(bill, wave_number, patience_fill)
	_award_points(points)


func _is_correct_swipe(event: MoneySwipedEvent) -> bool:
	var is_fake := event.money_resource.is_fake()
	if event.direction == MoneySwipedEvent.Direction.DOWN and not is_fake:
		return true
	if event.direction == MoneySwipedEvent.Direction.UP and is_fake:
		return true
	return false


func _calculate_points(bill: MoneyResource, wave_number: int, patience_fill: float) -> int:
	return ceili(float(bill.base_score) * wave_number * patience_fill)


func _award_points(amount: int) -> void:
	if amount <= 0:
		return
	_score += amount
	_update_label()
	_pop_score_counter()


func _update_label() -> void:
	if score_counter != null:
		score_counter.text = str(_score)


func _pop_score_counter() -> void:
	if score_counter == null:
		return

	score_counter.pivot_offset = score_counter.size * 0.5 if score_counter.size != Vector2.ZERO \
		else score_counter.get_minimum_size() * 0.5
	score_counter.scale = Vector2.ONE

	if _score_pop_tween != null and _score_pop_tween.is_valid():
		_score_pop_tween.kill()

	var peak_scale := Vector2.ONE * score_pop_scale
	_score_pop_tween = create_tween()
	_score_pop_tween.tween_property(score_counter, "scale", peak_scale, score_pop_grow_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_score_pop_tween.tween_property(score_counter, "scale", Vector2.ONE, score_pop_shrink_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
