class_name ScoreController extends Node

@export var wave_controller: WaveController
@export var score_counter: Label

var _score: int = 0
var _game_over: bool = false


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


func _update_label() -> void:
	if score_counter != null:
		score_counter.text = str(_score)
