class_name MoneySwipeController extends Node

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
@export var slide_enter_overshoot: float = 0.2
@export var slide_exit_windup: float = 0.2
@export var slide_enter_overshoot_ratio: float = 0.6
@export var slide_exit_windup_ratio: float = 0.35
@export var slide_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var slide_ease: Tween.EaseType = Tween.EASE_OUT

enum SlideStyle {
	LINEAR,
	ENTER,
	EXIT,
}

@export_group("Swipe")
## Minimum vertical travel (pixels) to count as a swipe.
@export var swipe_min_distance: float = 48.0
## Horizontal drift may be at most this fraction of vertical travel.
@export var swipe_max_horizontal_ratio: float = 0.85

@export_group("Flip")
@export var flip_duration: float = 0.4
@export var flip_jump_height: float = 0.3
@export var flip_bounce_scale: float = 0.12
@export var flip_land_stretch: float = 0.03
@export var flip_land_duration: float = 0.18
@export var flip_trans: Tween.TransitionType = Tween.TRANS_QUAD
@export var flip_ease: Tween.EaseType = Tween.EASE_IN_OUT

var current_money: Node3D
var _active_bill_pool: Array[MoneyResource] = [
	bill_pool[0],
	bill_pool[1],
	bill_pool[2],
]
var _is_sliding: bool = false
var _is_flipping: bool = false
var _motion_tween: Tween
var _game_over: bool = false

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
	FRONT_STAMP,
	BACK_STAMP,
}

const _IMPLEMENTED_FAKE_FEATURES: Array[FakeFeature] = [
	FakeFeature.FRONT_SERIAL,
	FakeFeature.BACK_SERIAL,
	FakeFeature.FRONT_VALUE,
	FakeFeature.BACK_VALUE,
	FakeFeature.FRONT_COLOR,
	FakeFeature.BACK_COLOR,
	FakeFeature.FRONT_STAMP,
	FakeFeature.BACK_STAMP,
]

func get_active_bill_pool() -> Array[MoneyResource]:
	return _active_bill_pool

func _ready() -> void:
	# Remove the comment below to see the Swipe Event logs
	#EventBus.on_event.connect(_on_debug_event)

	if money_container == null or customer_position == null \
			or table_position == null or player_position == null:
		push_error("MoneySwipeController: assign all position node references in the inspector.")
		return

	EventBus.on_event.connect(_on_event)


func _on_event(event: Object) -> void:
	if event is OnGameOver:
		_on_game_over()


func _on_game_over() -> void:
	_game_over = true
	_cancel_motion_tweens()
	_is_sliding = false
	_is_flipping = false
	_active_pointer = -1

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
	if _game_over:
		return
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


func spawn_money(is_fake: bool = false, alter_count: int = 0, bill_pool_override: Array[MoneyResource] = []) -> void:
	if _game_over:
		return
	if money_scene == null or money_container == null:
		push_warning("MoneySwipeController: money_scene or money_container is not set.")
		return
	if current_money != null:
		return

	var pool := bill_pool_override if not bill_pool_override.is_empty() else bill_pool
	if pool.is_empty():
		push_warning("MoneySwipeController: bill pool is empty.")
		return

	_active_bill_pool = pool

	var money : Money = money_scene.instantiate() as Node3D
	if money == null:
		push_warning("MoneySwipeController: money_scene root must be a Node3D.")
		return

	var bill: MoneyResource = pool.pick_random().duplicate()
	bill.fake = is_fake
	if is_fake and alter_count > 0:
		_apply_fake_alterations(bill, alter_count)
	money.setup(bill)

	money_container.add_child(money)
	money.global_position = customer_position.global_position
	money.rotation.y = deg_to_rad(randf_range(-30.0, 30.0))
	current_money = money
	EventBus.send_event(MoneySpawnedEvent.create(money, money.money_resource))
	_slide_to(table_position, Callable(), SlideStyle.ENTER)


func destroy_current_money() -> void:
	if current_money == null:
		return
	_cancel_motion_tweens()
	_is_flipping = false
	_is_sliding = false
	_destroy_current()


func _cancel_motion_tweens() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = null


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
		FakeFeature.FRONT_STAMP:
			_alter_front_stamp(bill)
		FakeFeature.BACK_STAMP:
			_alter_back_stamp(bill)


func _pick_donor_bill(bill: MoneyResource, matches_exclusion: Callable) -> MoneyResource:
	var donors: Array[MoneyResource] = []
	for candidate in _active_bill_pool:
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


func _alter_front_stamp(bill: MoneyResource) -> void:
	var donor := _pick_donor_bill(bill, func(candidate: MoneyResource, current: MoneyResource) -> bool:
		return candidate.front_stamp == current.front_stamp
	)
	if donor == null:
		push_warning("MoneySwipeController: no donor bill for front_stamp alteration.")
		return
	bill.front_stamp = donor.front_stamp


func _alter_back_stamp(bill: MoneyResource) -> void:
	var donor := _pick_donor_bill(bill, func(candidate: MoneyResource, current: MoneyResource) -> bool:
		return candidate.back_stamp == current.back_stamp
	)
	if donor == null:
		push_warning("MoneySwipeController: no donor bill for back_stamp alteration.")
		return
	bill.back_stamp = donor.back_stamp


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
	if _game_over:
		return
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
		_slide_to(customer_position, _destroy_current, SlideStyle.EXIT)
	else:
		# Top -> bottom: take to player, then destroy.
		EventBus.send_event(MoneySwipedEvent.create(
			money, money.money_resource, MoneySwipedEvent.Direction.DOWN
		))
		_slide_to(player_position, _destroy_current, SlideStyle.EXIT)


func _flip_current_money() -> void:
	if _game_over:
		return
	if current_money == null or _is_sliding or _is_flipping:
		return

	_is_flipping = true
	var money := current_money as Money
	var base_y := money.global_position.y
	var base_scale := money.scale
	var target_z := money.rotation.z + PI
	var normalized_z := fposmod(target_z, TAU)
	var showing_back := normalized_z > PI * 0.5 and normalized_z < PI * 1.5
	EventBus.send_event(RotateMoneyEvent.create(money, money.money_resource, showing_back))

	var tween := create_tween()
	_motion_tween = tween
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

	var total_scale_duration := flip_duration + flip_land_duration
	tween.tween_method(
		func(t: float) -> void:
			if not is_instance_valid(money):
				return
			var elapsed := t * total_scale_duration
			var face_scale := Vector2.ONE
			if elapsed <= flip_duration:
				var flip_t := elapsed / flip_duration
				var air_scale := 1.0 + flip_bounce_scale * sin(flip_t * PI)
				face_scale = Vector2(air_scale, air_scale)
			else:
				var land_t := (elapsed - flip_duration) / flip_land_duration
				var land_scale := 1.0 + flip_land_stretch * sin(land_t * PI)
				face_scale = Vector2(land_scale, land_scale)
			_apply_bill_face_scale(money, base_scale, face_scale),
		0.0,
		1.0,
		total_scale_duration
	)

	tween.finished.connect(func () -> void:
		if is_instance_valid(money):
			_apply_bill_face_scale(money, base_scale, Vector2.ONE)
		_is_flipping = false
	, CONNECT_ONE_SHOT)


func _apply_bill_face_scale(money: Money, base_scale: Vector3, face_scale: Vector2) -> void:
	# PlaneMesh default (FACE_Y): bill lies on X/Z; size.x -> X, size.y -> Z.
	money.scale = Vector3(
		base_scale.x * face_scale.x,
		base_scale.y,
		base_scale.z * face_scale.y
	)


func _slide_to(
	target: Node3D,
	on_finished: Callable = Callable(),
	style: SlideStyle = SlideStyle.LINEAR
) -> void:
	if _game_over:
		return
	if current_money == null or target == null:
		return
	if _is_sliding:
		return

	_is_sliding = true
	var money := current_money
	var start_pos := money.global_position
	var end_pos := target.global_position

	var tween := create_tween()
	_motion_tween = tween

	match style:
		SlideStyle.ENTER:
			var slide_dir := end_pos - start_pos
			if slide_dir.length_squared() < 0.0001:
				slide_dir = Vector3(0.0, 0.0, 1.0)
			else:
				slide_dir = slide_dir.normalized()
			var overshoot_pos := end_pos + slide_dir * slide_enter_overshoot
			var overshoot_time := slide_duration * slide_enter_overshoot_ratio
			var settle_time := maxf(slide_duration - overshoot_time, 0.01)
			tween.tween_property(money, "global_position", overshoot_pos, overshoot_time)\
				.set_trans(slide_trans).set_ease(slide_ease)
			tween.tween_property(money, "global_position", end_pos, settle_time)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		SlideStyle.EXIT:
			var exit_dir := end_pos - start_pos
			if exit_dir.length_squared() < 0.0001:
				exit_dir = Vector3(0.0, 0.0, 1.0)
			else:
				exit_dir = exit_dir.normalized()
			# Wind up opposite travel: down-swipe pulls toward top, up-swipe dips toward bottom.
			var windup_pos := start_pos - exit_dir * slide_exit_windup
			var windup_time := slide_duration * slide_exit_windup_ratio
			var travel_time := maxf(slide_duration - windup_time, 0.01)
			tween.tween_property(money, "global_position", windup_pos, windup_time)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(money, "global_position", end_pos, travel_time)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_:
			tween.set_trans(slide_trans)
			tween.set_ease(slide_ease)
			tween.tween_property(money, "global_position", end_pos, slide_duration)

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
