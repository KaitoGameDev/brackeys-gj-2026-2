class_name MoneyContent extends Control

@export var serial_number_orientation: Orientation = Orientation.HORIZONTAL

@onready var bg_color: ColorRect = $BgColor
@onready var top_left_value_label: Label = $TopLeftValue
@onready var bottom_right_value_label: Label = $BottomRightValue
@onready var serial_number: Label = $Serial
@onready var stamp: TextureRect = $Stamp

func add_serial(serial: String) -> void:
	serial_number.text = ""
	
	if serial_number_orientation == Orientation.HORIZONTAL:
		serial_number.text = serial
	else:
		for digit in serial:
			serial_number.text += "{0}\n".format([digit])
