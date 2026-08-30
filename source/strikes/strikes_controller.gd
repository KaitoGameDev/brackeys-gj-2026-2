class_name StrikesController extends Control

var enabled_strike_texture: Texture2D = preload("res://assets/icons/enabled_x.png")
var disabled_strike_texture: Texture2D = preload("res://assets/icons/disabled_x.png")

@export_group("Strike Pop")
@export var strike_pop_scale: float = 1.35
@export var strike_pop_grow_duration: float = 0.12
@export var strike_pop_shrink_duration: float = 0.15

var current_strikes: int = 0
var strikes: Array[TextureRect] = []

@onready var container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	for child in container.get_children():
		strikes.append(child)

	EventBus.on_event.connect(_on_event)


func _on_event(event: Object) -> void:
	if event is MoneySwipedEvent:
		_on_swiped_money(event)
	elif event is PatienceExpiredEvent:
		_register_strike()


func _on_swiped_money(event: MoneySwipedEvent) -> void:
	if current_strikes == 3:
		return

	if event.direction == MoneySwipedEvent.Direction.DOWN and event.money.money_resource.is_fake():
		_register_strike()
	elif event.direction == MoneySwipedEvent.Direction.UP and not event.money.money_resource.is_fake():
		_register_strike()


func _register_strike() -> void:
	if current_strikes >= strikes.size():
		return
	AudioController.failure()
	var strike := strikes[current_strikes]
	strike.texture = enabled_strike_texture
	_pop_strike(strike)
	current_strikes += 1

	if current_strikes == 3:
		AudioController.play_bgm("gameplay", -15.0)
		EventBus.send_event(OnGameOver.new())


func _pop_strike(strike: TextureRect) -> void:
	strike.pivot_offset = strike.size * 0.5 if strike.size != Vector2.ZERO else strike.custom_minimum_size * 0.5
	strike.scale = Vector2.ONE

	var peak_scale := Vector2.ONE * strike_pop_scale
	var tween := create_tween()
	tween.tween_property(strike, "scale", peak_scale, strike_pop_grow_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(strike, "scale", Vector2.ONE, strike_pop_shrink_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
