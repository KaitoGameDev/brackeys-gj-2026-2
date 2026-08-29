extends Node

@onready var bgm_player: AudioStreamPlayer = $BgAudioPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXAudioPlayer
@onready var interactions_player: AudioStreamPlayer = $InteractionsAudioPlayer

var bgm: Dictionary[String, Resource] = {
	"main": preload("res://assets/music/regrowth wip.wav")
}

func _ready() -> void:
	play_bgm("main")

func play_bgm(track_name: String) -> void:
	if bgm.has(track_name):
		bgm_player.stream = bgm.get(track_name)
		bgm_player.play()
