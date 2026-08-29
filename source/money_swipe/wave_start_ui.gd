extends Control

@export var wave_controller: WaveController
@export var money_ui_item_scene: PackedScene = preload("res://source/ui/money_ui_item.tscn")

@onready var _money_container: HBoxContainer = $MoneyContainer
@onready var _day_label: Label = $DayLabel
@onready var _button: Button = $Button


func _ready() -> void:
	_button.pressed.connect(_on_start_day_pressed)
	EventBus.on_event.connect(_on_event)
	_refresh_bill_preview()


func _on_event(event: Object) -> void:
	if event is WaveCompletedEvent:
		_refresh_bill_preview()


func _on_start_day_pressed() -> void:
	AudioController.on_click()
	EventBus.send_event(WaveStartedEvent.new())


func _refresh_bill_preview() -> void:
	if wave_controller == null or money_ui_item_scene == null:
		return

	_day_label.text = "Day {0}".format([wave_controller.get_current_wave_number()])
	_clear_money_container()

	for bill in wave_controller.get_current_wave_bill_pool():
		var item := money_ui_item_scene.instantiate() as Control
		if item == null:
			continue
		_money_container.add_child(item)
		_apply_bill_to_item(item, bill)


func _clear_money_container() -> void:
	for child in _money_container.get_children():
		child.free()


func _apply_bill_to_item(item: Control, bill: MoneyResource) -> void:
	var front: MoneyContent = item.get_node("FrontContent") as MoneyContent
	if front == null:
		return

	front.top_left_value_label.text = str(bill.front_value)
	front.bottom_right_value_label.text = str(bill.front_value)
	front.add_serial(bill.front_serial)
	front.bg_color.self_modulate = bill.front_color
	front.stamp.texture = bill.front_stamp
