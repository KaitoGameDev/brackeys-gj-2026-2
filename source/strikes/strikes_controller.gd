class_name StrikesController extends Control

var enabled_strike_texture: Texture2D = preload("res://assets/icons/enabled_x.png")
var disabled_strike_texture: Texture2D = preload("res://assets/icons/disabled_x.png")

var current_strikes: int = 0
var strikes: Array[TextureRect] = []

@onready var container: HBoxContainer = $HBoxContainer

func _ready() -> void:
	for child in container.get_children():
		strikes.append(child)
		
	EventBus.on_event.connect(_on_event)
	

func _on_event(event: Object) -> void:
	if event is MoneySwipedEvent:
		if event.direction == MoneySwipedEvent.Direction.DOWN and event.money.money_resource.is_fake():
			strikes[current_strikes].texture = enabled_strike_texture
			current_strikes += 1
		elif event.direction == MoneySwipedEvent.Direction.UP and !event.money.money_resource.is_fake():
			strikes[current_strikes].texture = enabled_strike_texture
			current_strikes += 1