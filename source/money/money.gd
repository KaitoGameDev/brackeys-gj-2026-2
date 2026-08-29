class_name Money extends Node3D

@export var money_resource: MoneyResource

@onready var front_content: MoneyContent = $Front/ViewportMoney/FrontContent
@onready var back_content: MoneyContent = $Back/ViewportMoney/BackContent

func setup(resource: MoneyResource) -> void:
	self.money_resource = resource
	

func _ready() -> void:
	if money_resource:
		front_content.top_left_value_label.text = str(money_resource.front_value)
		front_content.bottom_right_value_label.text = str(money_resource.front_value)
		front_content.add_serial(money_resource.front_serial)
		front_content.bg_color.self_modulate = money_resource.front_color
		front_content.stamp.texture = money_resource.front_stamp
		#front_content.stamp.self_modulate = money_resource.front_color
		
		back_content.top_left_value_label.text = str(money_resource.back_value)
		back_content.bottom_right_value_label.text = str(money_resource.back_value)
		back_content.bg_color.self_modulate = money_resource.back_color
		back_content.add_serial(money_resource.back_serial)
		back_content.stamp.texture = money_resource.back_stamp
		#back_content.stamp.self_modulate = money_resource.back_color
