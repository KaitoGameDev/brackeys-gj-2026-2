class_name MoneyResource extends Resource

@export var front_value: int = 0
@export var back_value: int = 0
@export var front_color: Color = Color.WHITE
@export var back_color: Color = Color.WHITE
@export var front_stamp: Texture2D
@export var back_stamp: Texture2D
@export var front_serial: String = ""
@export var back_serial: String = ""

@export var base_score: int = 1

@export var fake: bool = false

func is_fake() -> bool:
	return fake