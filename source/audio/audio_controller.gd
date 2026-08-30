extends Node

@onready var bgm_player: AudioStreamPlayer = $BgAudioPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXAudioPlayer
@onready var voice_player: AudioStreamPlayer = $VoicePlayer

var bgm: Dictionary[String, Resource] = {
	"main": preload("res://assets/music/regrowth wip.wav"),
	"gameplay": preload("res://assets/music/shop.wav")
}

var sfx: Dictionary[String, Resource] = {
	"buttons": preload("res://assets/sfx/pop_3.wav"),
	"on_page": preload("res://assets/sfx/book_close.wav"),
	"swipe": preload("res://assets/sfx/whoosh_1.wav"),
	"failure": preload("res://assets/sfx/failure.wav")
}

func _ready() -> void:
	play_bgm("main")

func play_bgm(track_name: String, volume: float = 0.0) -> void:
	if bgm.has(track_name):
		bgm_player.volume_db = volume
		bgm_player.stream = bgm.get(track_name)
		bgm_player.play()

func on_click() -> void:
	sfx_player.stream = sfx.get("buttons")
	sfx_player.play()
	
func on_page() -> void:
	sfx_player.stream = sfx.get("on_page")
	sfx_player.play()

func voice_1() -> AudioStreamPlayer:
	voice_player.play.call_deferred()
	return voice_player

func swipe() -> void:
	sfx_player.stream = sfx.get("swipe")
	sfx_player.play()

func failure() -> void:
	sfx_player.stream = sfx.get("failure")
	sfx_player.play()
