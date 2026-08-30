class_name MainMenu extends Node

const GAME_SCENE_PATH := "res://source/main.tscn"

@onready var play_btn: Button = $CanvasLayer/ActionButtons/PlayBtn
@onready var credits_btn: Button = $CanvasLayer/ActionButtons/CreditsBtn
@onready var close_btn: Button = $CanvasLayer/CreditsModal/ColorRect/CloseBtn

@onready var credits_modal: Control = $CanvasLayer/CreditsModal

var _main: Node
var _loading := true
var _play_label := ""


func _ready() -> void:
	play_btn.pressed.connect(_on_play_btn_pressed)
	close_btn.pressed.connect(_on_close_credits_pressed)
	credits_btn.pressed.connect(_on_credits_btn_pressed)
	_play_label = play_btn.text
	_set_loading(true)
	ResourceLoader.load_threaded_request(GAME_SCENE_PATH)


func _process(_delta: float) -> void:
	var status := ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	set_process(false)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("MainMenu: failed to load {0}.".format([GAME_SCENE_PATH]))
		_set_loading(false)
		return
	var packed := ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("MainMenu: {0} is not a PackedScene.".format([GAME_SCENE_PATH]))
		_set_loading(false)
		return
	_main = packed.instantiate()
	_set_loading(false)


func _set_loading(is_loading: bool) -> void:
	_loading = is_loading
	play_btn.disabled = is_loading
	play_btn.text = "Loading..." if is_loading else _play_label


func _on_close_credits_pressed() -> void:
	AudioController.on_click()
	credits_modal.visible = false


func _on_play_btn_pressed() -> void:
	if _loading or _main == null:
		return
	AudioController.on_click()
	get_tree().change_scene_to_node(_main)
	AudioController.play_bgm.call_deferred("gameplay")


func _on_credits_btn_pressed() -> void:
	AudioController.on_click()
	credits_modal.visible = true
