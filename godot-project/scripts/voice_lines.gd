class_name VoiceLines
extends Node3D
## Dijah's Delights Candy Run — Dijah's spoken one-liners (sarcastic nursing humor; LPN).
## Plays the spoken voice audio clips only — no speech bubble is rendered on screen.
## Silent when the game is muted (Save.muted). One line at a time: a new
## line replaces the one currently playing.

const CLIPS: Dictionary = {
	"big_star": preload("res://audio/voices/big_star.wav"),
	"rainbow_star": preload("res://audio/voices/rainbow_star.wav"),
	"sour_star": preload("res://audio/voices/sour_star.wav"),
	"speed_boost": preload("res://audio/voices/speed_boost.wav"),
	"new_best": preload("res://audio/voices/new_best.wav"),
	"fall": preload("res://audio/voices/fall.wav"),
	"win": preload("res://audio/voices/win.wav"),
	"near_miss": preload("res://audio/voices/near_miss.wav"),
}

const GENERAL_COOLDOWN: float = 4.0

const GENERAL_CLIPS: Dictionary = {
	"call_lights": preload("res://audio/voices/call_lights.wav"),
	"per_my_last_note": preload("res://audio/voices/per_my_last_note.wav"),
	"shift_great": preload("res://audio/voices/shift_great.wav"),
	"night_shift": preload("res://audio/voices/night_shift.wav"),
	"chart_it": preload("res://audio/voices/chart_it.wav"),
	"feet_hurt": preload("res://audio/voices/feet_hurt.wav"),
	"hero": preload("res://audio/voices/hero.wav"),
	"hydrate": preload("res://audio/voices/hydrate.wav"),
	"bed_alarm": preload("res://audio/voices/bed_alarm.wav"),
	"warm_up": preload("res://audio/voices/warm_up.wav"),
	"vitals_dropping": preload("res://audio/voices/vitals_dropping.wav"),
	"med_cart": preload("res://audio/voices/med_cart.wav"),
}

const BLUEBERRY_CLIPS: Dictionary = {
	"blueberry_hate": preload("res://audio/voices/blueberry_hate.wav"),
	"blueberry_chart": preload("res://audio/voices/blueberry_chart.wav"),
	"blueberry_tried": preload("res://audio/voices/blueberry_tried.wav"),
	"blueberry_grapes": preload("res://audio/voices/blueberry_grapes.wav"),
	"blueberry_writeup": preload("res://audio/voices/blueberry_writeup.wav"),
}

var _player: AudioStreamPlayer
var _time_alive: float = 0.0
var _last_line_time: float = -100.0
var _playing_event: bool = false
var _last_general: String = ""
var _last_blueberry: String = ""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)


## Event line: always plays (replaces any general line currently playing).
func play_line(event: String) -> void:
	if not CLIPS.has(event):
		return
	_play(event, true)


## General line: random pool line for regular star pickups.
func play_general() -> void:
	if _time_alive - _last_line_time < GENERAL_COOLDOWN:
		return
	if _playing_event and _player.playing:
		return
	var keys: Array = GENERAL_CLIPS.keys()
	keys.erase(_last_general)
	var key: String = String(keys[randi() % keys.size()])
	_last_general = key
	_play(key, false)


## Blueberry line: random pool line for regular star pickups on board 21 ONLY.
func play_blueberry() -> void:
	if _time_alive - _last_line_time < GENERAL_COOLDOWN:
		return
	if _playing_event and _player.playing:
		return
	var keys: Array = BLUEBERRY_CLIPS.keys()
	keys.erase(_last_blueberry)
	var key: String = String(keys[randi() % keys.size()])
	_last_blueberry = key
	_play(key, false)


func _play(event: String, is_event: bool) -> void:
	_playing_event = is_event and not Save.muted
	_last_line_time = _time_alive
	if Save.muted:
		return
	var clip: AudioStream = CLIPS.get(event, GENERAL_CLIPS.get(event, BLUEBERRY_CLIPS.get(event, null)))
	if clip == null:
		return
	_player.stop()
	_player.stream = clip
	_player.play()


func _process(delta: float) -> void:
	_time_alive += delta
	if _playing_event and not _player.playing:
		_playing_event = false
