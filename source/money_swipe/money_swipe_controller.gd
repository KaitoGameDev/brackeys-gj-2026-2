extends Node

@export var money_scene: PackedScene = preload("res://source/money_swipe/money.tscn")

@export_group("Positions")
@export var money_container: Node3D
@export var customer_position: Node3D
@export var table_position: Node3D
@export var player_position: Node3D

@export_group("Slide")
@export var slide_duration: float = 0.35
@export var slide_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var slide_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Swipe")
## Minimum vertical travel (pixels) to count as a swipe.
@export var swipe_min_distance: float = 48.0
## Horizontal drift may be at most this fraction of vertical travel.
@export var swipe_max_horizontal_ratio: float = 0.85

var current_money: Node3D
var _is_sliding: bool = false

# -1 = none, -2 = mouse, >= 0 = touch index
var _active_pointer: int = -1
var _swipe_start: Vector2 = Vector2.ZERO

const _POINTER_MOUSE := -2


func _ready() -> void:
	if money_container == null or customer_position == null \
			or table_position == null or player_position == null:
		push_error("MoneySwipeController: assign all position node references in the inspector.")
		return

	spawn_money()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index != 0:
			return
		if touch.pressed:
			_begin_swipe(touch.position, touch.index)
		else:
			_end_swipe(touch.position, touch.index)
		return

	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_begin_swipe(mouse.position, _POINTER_MOUSE)
		else:
			_end_swipe(mouse.position, _POINTER_MOUSE)


func spawn_money() -> void:
	if money_scene == null or money_container == null:
		push_warning("MoneySwipeController: money_scene or money_container is not set.")
		return
	if current_money != null:
		return

	var money := money_scene.instantiate() as Node3D
	if money == null:
		push_warning("MoneySwipeController: money_scene root must be a Node3D.")
		return

	money_container.add_child(money)
	money.global_position = customer_position.global_position
	money.rotation.y = deg_to_rad(randf_range(-30.0, 30.0))
	current_money = money
	_slide_to(table_position)


func _begin_swipe(screen_pos: Vector2, pointer_id: int) -> void:
	if _active_pointer != -1:
		return
	_active_pointer = pointer_id
	_swipe_start = screen_pos


func _end_swipe(screen_pos: Vector2, pointer_id: int) -> void:
	if _active_pointer != pointer_id:
		return
	_active_pointer = -1
	_resolve_swipe(screen_pos)


func _resolve_swipe(screen_end: Vector2) -> void:
	if current_money == null or _is_sliding:
		return

	var delta := screen_end - _swipe_start
	var vertical := delta.y
	var abs_vertical := absf(vertical)
	if abs_vertical < swipe_min_distance:
		return
	if absf(delta.x) > abs_vertical * swipe_max_horizontal_ratio:
		return

	if vertical < 0.0:
		# Bottom -> top: give to customer, then destroy + respawn.
		_slide_to(customer_position, _destroy_current_and_respawn)
	else:
		# Top -> bottom: take to player, then destroy + respawn.
		_slide_to(player_position, _destroy_current_and_respawn)


func _slide_to(target: Node3D, on_finished: Callable = Callable()) -> void:
	if current_money == null or target == null:
		return
	if _is_sliding:
		return

	_is_sliding = true
	var tween := create_tween()
	tween.set_trans(slide_trans)
	tween.set_ease(slide_ease)
	tween.tween_property(current_money, "global_position", target.global_position, slide_duration)
	tween.finished.connect(func () -> void:
		_is_sliding = false
		if on_finished.is_valid():
			on_finished.call()
	, CONNECT_ONE_SHOT)


func _destroy_current_and_respawn() -> void:
	if current_money != null:
		current_money.queue_free()
		current_money = null
	spawn_money()
