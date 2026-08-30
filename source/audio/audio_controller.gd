extends Node

const WAVE_START_JINGLE := preload("res://assets/music/xylophone_level_start.wav")
const WAVE_END_JINGLE := preload("res://assets/music/xylophone_positive_long.wav")

@onready var bgm_player: AudioStreamPlayer = $BgAudioPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXAudioPlayer
@onready var voice_player: AudioStreamPlayer = $VoicePlayer
@onready var jingle_player: AudioStreamPlayer = $JinglePlayer

var bgm: Dictionary[String, Resource] = {
	"main": preload("res://assets/music/regrowth wip.wav"),
	"gameplay": preload("res://assets/music/shop.wav")
}

var sfx: Dictionary[String, Resource] = {
	"buttons": preload("res://assets/sfx/pop_3.wav"),
	"on_page": preload("res://assets/sfx/book_close.wav"),
	"swipe": preload("res://assets/sfx/whoosh_1.wav"),
	"failure": preload("res://assets/sfx/failure.wav"),
	"success": preload("res://assets/sfx/success_beep.wav")
}


func _ready() -> void:
	EventBus.on_event.connect(_on_event)
	play_bgm("main")


func _on_event(event: Object) -> void:
	if event is WaveStartedEvent:
		play_wave_start_jingle()
	if event is WaveCompletedEvent:
		play_wave_end_jingle()


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


func start_voice() -> void:
	voice_player.play()

func stop_voice() -> void:
	voice_player.stop()


func swipe() -> void:
	sfx_player.stream = sfx.get("swipe")
	sfx_player.play()


func failure() -> void:
	sfx_player.stream = sfx.get("failure")
	sfx_player.play()


func success() -> void:
	sfx_player.stream = sfx.get("success")
	sfx_player.play()


func _play_jingle(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	jingle_player.stream = stream

	if bgm_player.playing:
		bgm_player.stream_paused = true

	if jingle_player.finished.is_connected(_resume_bgm_after_jingle):
		jingle_player.finished.disconnect(_resume_bgm_after_jingle)
	jingle_player.finished.connect(_resume_bgm_after_jingle, CONNECT_ONE_SHOT)
	jingle_player.play()


func play_wave_start_jingle() -> void:
	_play_jingle(WAVE_START_JINGLE)


func play_wave_end_jingle() -> void:
	_play_jingle(WAVE_END_JINGLE)


func _resume_bgm_after_jingle() -> void:
	bgm_player.stream_paused = false
