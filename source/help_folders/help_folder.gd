class_name HelpFolder extends Control

@onready var close_btn: Button = $CloseBtn
@onready var next_page_button: TextureButton = $NextPageBtn
@onready var previous_page_button: TextureButton = $PreviousPageBtn

@onready var front_bill: MoneyContent = $OpenFolderLeft/FrontContent
@onready var back_bill: MoneyContent = $OpenFolderRight/BackContent

@export var money_swipe_controller: MoneySwipeController

var _current_page: int = 0

func _ready() -> void:
	close_btn.pressed.connect(_on_close_btn_pressed)
	next_page_button.pressed.connect(_on_next_page_pressed)
	previous_page_button.pressed.connect(_on_previous_page_pressed)
	
	_render_page.call_deferred()
	
func _on_close_btn_pressed() -> void:
	visible = false
	
func _on_previous_page_pressed() -> void:
	_current_page += 1
	_render_page()
	
func _on_next_page_pressed() -> void:
	_current_page -= 1
	_render_page()
	
func _render_page() -> void:
#	var bill_page: MoneyResource = money_swipe_controller.get_active_bill_pool()[_current_page]
#	front_bill.bg_color.self_modulate = bill_page.front_color
	pass