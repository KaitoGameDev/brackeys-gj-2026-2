class_name Money extends Node3D

@export var money_resource: MoneyResource

@onready var front_content: MoneyContent = $Front/ViewportMoney/FrontContent
@onready var back_content: MoneyContent = $Back/ViewportMoney/BackContent


func setup(resource: MoneyResource) -> void:
	apply_resource(resource)


func _ready() -> void:
	if money_resource:
		apply_resource(money_resource)


func apply_resource(resource: MoneyResource) -> void:
	money_resource = resource

	var front := _get_front_content()
	var back := _get_back_content()
	if front == null or back == null:
		push_error("Money: bill content nodes are not ready yet.")
		return

	front.top_left_value_label.text = str(money_resource.front_value)
	front.bottom_right_value_label.text = str(money_resource.front_value)
	front.add_serial(money_resource.front_serial)
	front.bg_color.self_modulate = money_resource.front_color
	front.stamp.texture = money_resource.front_stamp

	back.top_left_value_label.text = str(money_resource.back_value)
	back.bottom_right_value_label.text = str(money_resource.back_value)
	back.bg_color.self_modulate = money_resource.back_color
	back.add_serial(money_resource.back_serial)
	back.stamp.texture = money_resource.back_stamp


func _get_front_content() -> MoneyContent:
	if front_content == null:
		front_content = $Front/ViewportMoney/FrontContent as MoneyContent
	return front_content


func _get_back_content() -> MoneyContent:
	if back_content == null:
		back_content = $Back/ViewportMoney/BackContent as MoneyContent
	return back_content


func reset_transform() -> void:
	rotation = Vector3.ZERO
	scale = Vector3.ONE
