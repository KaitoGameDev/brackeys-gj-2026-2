extends Node

@export var money_scene: PackedScene = preload("res://source/money/money.tscn")
@export var bill_pool: Array[MoneyResource] = [
	preload("res://resources/money/2_bill.tres"),
	preload("res://resources/money/5_bill.tres"),
	preload("res://resources/money/10_bill.tres"),
	preload("res://resources/money/20_bill.tres"),
	preload("res://resources/money/50_bill.tres"),
	preload("res://resources/money/100_bill.tres"),
]

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

@export_group("Flip")
@export var flip_duration: float = 0.4
@export var flip_jump_height: float = 0.3
@export var flip_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var flip_ease: Tween.EaseType = Tween.EASE_IN_OUT

var current_money: Node3D
var _is_sliding: bool = false
var _is_flipping: bool = false

# -1 = none, -2 = mouse, >= 0 = touch index
var _active_pointer: int = -1
var _swipe_start: Vector2 = Vector2.ZERO

const _POINTER_MOUSE := -2

enum FakeFeature {
	FRONT_SERIAL,
	BACK_SERIAL,
	FRONT_VALUE,
	BACK_VALUE,
	FRONT_COLOR,
	BACK_COLOR,
}

const _IMPLEMENTED_FAKE_FEATURES: Array[FakeFeature] = [
	FakeFeature.FRONT_SERIAL,
	FakeFeature.BACK_SERIAL,
	FakeFeature.FRONT_VALUE,
	FakeFeature.BACK_VALUE,
	FakeFeature.FRONT_COLOR,
	FakeFeature.BACK_COLOR,
]


func _ready() -> void:
	# Remove the comment below to see the Swipe Event logs
	#EventBus.on_event.connect(_on_debug_event)

	if money_container == null or customer_position == null \
			or table_position == null or player_position == null:
		push_error("MoneySwipeController: assign all position node references in the inspector.")
		return

func _on_debug_event(event: Object) -> void:
	if event is MoneySpawnedEvent:
		var spawned := event as MoneySpawnedEvent
		print("[EventBus] MoneySpawnedEvent resource=", spawned.money_resource)
	elif event is MoneyDestroyedEvent:
		var destroyed := event as MoneyDestroyedEvent
		print("[EventBus] MoneyDestroyedEvent resource=", destroyed.money_resource)
	elif event is MoneySwipedEvent:
		var swiped := event as MoneySwipedEvent
		var direction_name := "UP" if swiped.direction == MoneySwipedEvent.Direction.UP else "DOWN"
		print("[EventBus] MoneySwipedEvent direction=", direction_name, " resource=", swiped.money_resource)
	elif event is RotateMoneyEvent:
		var rotated := event as RotateMoneyEvent
		print("[EventBus] RotateMoneyEvent showing_back=", rotated.showing_back, " resource=", rotated.money_resource)


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


func spawn_money(is_fake: bool = false, alter_count: int = 0) -> void:
	if money_scene == null or money_container == null:
		push_warning("MoneySwipeController: money_scene or money_container is not set.")
		return
	if current_money != null:
		return

	if bill_pool.is_empty():
		push_warning("MoneySwipeController: bill_pool is empty.")
		return

	var money : Money = money_scene.instantiate() as Node3D
	if money == null:
		push_warning("MoneySwipeController: money_scene root must be a Node3D.")
		return

	var bill: MoneyResource = bill_pool.pick_random().duplicate()
	bill.fake = is_fake
	if is_fake and alter_count > 0:
		_apply_fake_alterations(bill, alter_count)
	money.setup(bill)

	money_container.add_child(money)
	money.global_position = customer_position.global_position
	money.rotation.y = deg_to_rad(randf_range(-30.0, 30.0))
	current_money = money
	EventBus.send_event(MoneySpawnedEvent.create(money, money.money_resource))
	_slide_to(table_position)


func _apply_fake_alterations(bill: MoneyResource, alter_count: int) -> void:
	var count := mini(alter_count, _IMPLEMENTED_FAKE_FEATURES.size())
	if count <= 0:
		return
	var features := _IMPLEMENTED_FAKE_FEATURES.duplicate()
	features.shuffle()
	for i in count:
		_alter_fake_feature(bill, features[i])


func _alter_fake_feature(bill: MoneyResource, feature: FakeFeature) -> void:
	match feature:
		FakeFeature.FRONT_SERIAL:
			_alter_front_serial(bill)
		FakeFeature.BACK_SERIAL:
			_alter_back_serial(bill)
		FakeFeature.FRONT_VALUE:
			_alter_front_value(bill)
		FakeFeature.BACK_VALUE:
			_alter_back_value(bill)
		FakeFeature.FRONT_COLOR:
			_alter_front_color(bill)
		FakeFeature.BACK_COLOR:
			_alter_back_color(bill)


func _pick_donor_bill(bill: MoneyResource, matches_exclusion: Callable) -> MoneyResource:
	var donors: Array[MoneyResource] = []
	for candidate in bill_pool:
		if matches_exclusion.call(candidate, bill):
			continue
		donors.append(candidate)
	if donors.is_empty():
		return null
	return donors.pick_random()


func _alter_front_serial(bill: MoneyResource) -> void:
	var donor := _pick_donor_bill(bill, func(candidate: MoneyResource, current: MoneyResource) -> bool:
		return candidate.front_serial == current.front_serial \
			and candidate.front_value == current.front_value
	)
	if donor == null:
		push_warning("MoneySwipeController: no donor bill for front_serial alteration.")
		return
	bill.front_serial = donor.front_serial


func _alter_back_serial(bill: MoneyResource) -> void:
	var donor := _pick_donor_bill(bill, func(candidate: MoneyResource, current: MoneyResource) -> bool:
		return candidate.back_serial == current.back_serial \
			and candidate.back_value == current.back_value
	)
	if donor == null:
		push_warning("MoneySwipeController: no donor bill for back_serial alteration.")
		return
	bill.back_serial = donor.back_serial


func _alter_front_value(bill: MoneyResource) -> void:
	var donor := _pick_donor_bill(bill, func(candidate: MoneyResource, current: MoneyResource) -> bool:
		return candidate.front_value == current.front_value
	)
	if donor == null:
		push_warning("MoneySwipeController: no donor bill for front_value alteration.")
		return
	bill.front_value = donor.front_value


func _alter_back_value(bill: MoneyResource) -> void:
	var donor := _pick_donor_bill(bill, func(candidate: MoneyResource, current: MoneyResource) -> bool:
		return candidate.back_value == current.back_value
	)
	if donor == null:
		push_warning("MoneySwipeController: no donor bill for back_value alteration.")
		return
	bill.back_value = donor.back_value


func _alter_front_color(bill: MoneyResource) -> void:
	var donor := _pick_donor_bill(bill, func(candidate: MoneyResource, current: MoneyResource) -> bool:
		return candidate.front_color.is_equal_approx(current.front_color)
	)
	if donor == null:
		push_warning("MoneySwipeController: no donor bill for front_color alteration.")
		return
	bill.front_color = donor.front_color


func _alter_back_color(bill: MoneyResource) -> void:
	var donor := _pick_donor_bill(bill, func(candidate: MoneyResource, current: MoneyResource) -> bool:
		return candidate.back_color.is_equal_approx(current.back_color)
	)
	if donor == null:
		push_warning("MoneySwipeController: no donor bill for back_color alteration.")
		return
	bill.back_color = donor.back_color


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
	if current_money == null or _is_sliding or _is_flipping:
		return

	var delta := screen_end - _swipe_start
	if delta.length() < swipe_min_distance:
		_flip_current_money()
		return

	var vertical := delta.y
	var abs_vertical := absf(vertical)
	if abs_vertical < swipe_min_distance:
		return
	if absf(delta.x) > abs_vertical * swipe_max_horizontal_ratio:
		return

	var money := current_money as Money
	if vertical < 0.0:
		# Bottom -> top: give to customer, then destroy.
		EventBus.send_event(MoneySwipedEvent.create(
			money, money.money_resource, MoneySwipedEvent.Direction.UP
		))
		_slide_to(customer_position, _destroy_current)
	else:
		# Top -> bottom: take to player, then destroy.
		EventBus.send_event(MoneySwipedEvent.create(
			money, money.money_resource, MoneySwipedEvent.Direction.DOWN
		))
		_slide_to(player_position, _destroy_current)


func _flip_current_money() -> void:
	if current_money == null or _is_sliding or _is_flipping:
		return

	_is_flipping = true
	var money := current_money as Money
	var base_y := money.global_position.y
	var target_z := money.rotation.z + PI
	var normalized_z := fposmod(target_z, TAU)
	var showing_back := normalized_z > PI * 0.5 and normalized_z < PI * 1.5
	EventBus.send_event(RotateMoneyEvent.create(money, money.money_resource, showing_back))

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(flip_trans)
	tween.set_ease(flip_ease)
	tween.tween_property(money, "rotation:z", target_z, flip_duration)
	tween.tween_method(
		func(t: float) -> void:
			if not is_instance_valid(money):
				return
			money.global_position.y = base_y + flip_jump_height * sin(t * PI),
		0.0,
		1.0,
		flip_duration
	)
	tween.finished.connect(func () -> void:
		_is_flipping = false
	, CONNECT_ONE_SHOT)


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


func _destroy_current() -> void:
	if current_money == null:
		return
	var money := current_money as Money
	current_money = null
	EventBus.send_event(MoneyDestroyedEvent.create(money, money.money_resource))
	money.queue_free()
