class_name Client extends Node3D

@export var client_resource: ClientResource

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite3D = $Client
@onready var dialog: Dialog = $Dialog

signal finished_transition

var stage: int = 0

func setup(resource: ClientResource) -> void:
	client_resource = resource

func move_to(target_position: Vector3, is_end_position: bool = false) -> void:
	stage += 1
	animation.play("move")
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", target_position.x, 1.2)
	tween.finished.connect(
		func():
			if is_end_position:
				finished_transition.emit()
			animation.stop()
			_handle_stage()
	)

func _handle_stage() -> void:
	if stage == 1:
		dialog.set_text(client_resource.lines.pick_random())
		dialog.start_dialog()
		EventBus.send_event(OnClientEntered.new())
	if stage == 2:
		EventBus.send_event(OnClientExited.new())

func _ready() -> void:
	if client_resource:
		sprite.texture = client_resource.texture
