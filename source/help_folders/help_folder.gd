class_name HelpFolder extends Control

@onready var close_btn: Button = $CloseBtn
@onready var next_page_button: TextureButton = $NextPageBtn
@onready var previous_page_button: TextureButton = $PreviousPageBtn

@onready var front_bill: MoneyContent = $OpenFolderLeft/FrontContent
@onready var back_bill: MoneyContent = $OpenFolderRight/BackContent

@export var wave_controller: WaveController

var _current_page: int = 0
var _bill_pool: Array[MoneyResource] = []


func _ready() -> void:
	close_btn.pressed.connect(_on_close_btn_pressed)
	next_page_button.pressed.connect(_on_next_page_pressed)
	previous_page_button.pressed.connect(_on_previous_page_pressed)

	EventBus.on_event.connect(_on_event)
	_refresh_bill_pool()


func _on_event(event: Object) -> void:
	if event is WaveCompletedEvent:
		_refresh_bill_pool()


func _refresh_bill_pool() -> void:
	if wave_controller == null:
		return

	_bill_pool = wave_controller.get_current_wave_bill_pool()
	_current_page = 0
	_render_page()


func _on_close_btn_pressed() -> void:
	if not visible:
		return
	AudioController.on_click()
	visible = false
	EventBus.send_event(HelpFolderClosedEvent.new())


func _on_previous_page_pressed() -> void:
	AudioController.on_page()
	_current_page -= 1
	_render_page()


func _on_next_page_pressed() -> void:
	AudioController.on_page()
	_current_page += 1
	_render_page()


func _render_page() -> void:
	if _bill_pool.is_empty():
		previous_page_button.visible = false
		next_page_button.visible = false
		return

	_current_page = clampi(_current_page, 0, _bill_pool.size() - 1)

	if _current_page == 0:
		previous_page_button.visible = false
	else:
		previous_page_button.visible = true
	if _current_page == _bill_pool.size() - 1:
		next_page_button.visible = false
	else:
		next_page_button.visible = true

	var bill_page: MoneyResource = _bill_pool[_current_page]
	front_bill.bg_color.self_modulate = bill_page.front_color
	front_bill.stamp.texture = bill_page.front_stamp
	front_bill.top_left_value_label.text = str(bill_page.front_value)
	front_bill.bottom_right_value_label.text = str(bill_page.front_value)
	front_bill.add_serial(bill_page.front_serial)

	back_bill.bg_color.self_modulate = bill_page.back_color
	back_bill.stamp.texture = bill_page.back_stamp
	back_bill.top_left_value_label.text = str(bill_page.back_value)
	back_bill.bottom_right_value_label.text = str(bill_page.back_value)
	back_bill.add_serial(bill_page.back_serial)
