class_name VoiceLines
extends Node3D
## Dijah Dash — Dijah's spoken one-liners (sarcastic nursing humor; LPN).
## Plays the voice clip and shows the line as a speech bubble above her head.
## Silent when the game is muted (Save.muted). One line at a time: a new
## line replaces the one currently playing.

const BUBBLE_TIME: float = 2.5

const LINES: Dictionary = {
	"big_star": "Ooh, shiny! Charting this one as a win.",
	"rainbow_star": "JACKPOT! Somebody call the nurse. Oh wait, that's me.",
	"sour_star": "Ew! That one was SOUR! Tastes like night shift.",
	"speed_boost": "I'm running faster than a call light at 3 AM!",
	"new_best": "Vitals: excellent. Diagnosis: unstoppable.",
	"fall": "Somebody file an incident report. On me.",
	"win": "Patient discharged! I mean... I did it!",
	"near_miss": "That was closer than med pass at 6 AM.",
}

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

## General pool: random one-liners on regular star pickups. Event lines
## (above) always win: they replace a playing general line, and a general
## line never starts while an event line is still playing.
const GENERAL_COOLDOWN: float = 4.0

const GENERAL_LINES: Dictionary = {
	"call_lights": "I've seen things. Mostly call lights.",
	"per_my_last_note": "Per my last note... I ran.",
	"shift_great": "This shift is going great. Said no nurse ever.",
	"night_shift": "If I can survive night shift, I can survive this track.",
	"chart_it": "Another star? Chart it. Everything gets charted.",
	"feet_hurt": "My feet hurt, my back hurts, but look, a star!",
	"hero": "I'm not saying I'm a hero, but nobody else grabbed that star.",
	"hydrate": "Hydrate, chart, run. In that order.",
	"bed_alarm": "Bed alarm going off? That's just my motivation.",
	"warm_up": "Twelve-hour shift? Please. This is my warm-up.",
	"vitals_dropping": "Somebody's vitals are dropping. It's mine. I'm tired.",
	"med_cart": "I'm not running from my problems, I'm running toward the med cart.",
}

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

var _player: AudioStreamPlayer
var _bubble: Label3D
var _bubble_timer: float = 0.0
var _time_alive: float = 0.0
var _last_line_time: float = -100.0
var _playing_event: bool = false
var _last_general: String = ""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_bubble = Label3D.new()
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.font_size = 48
	_bubble.pixel_size = 0.008
	_bubble.width = 520.0
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.outline_size = 8
	_bubble.modulate = Color.html("#ffffff")
	_bubble.outline_modulate = Color.html("#4a1030")
	_bubble.position = Vector3(0, 2.4, 0)
	_bubble.visible = false
	add_child(_bubble)


## Event line: always plays (replaces any general line currently playing).
func play_line(event: String) -> void:
	if not LINES.has(event):
		return
	_play(event, true)


## General line: random pool line for regular star pickups. Respects the
## cooldown and never talks over an event line that is still playing.
func play_general() -> void:
	if _time_alive - _last_line_time < GENERAL_COOLDOWN:
		return
	if _playing_event and _player.playing:
		return
	var keys: Array = GENERAL_LINES.keys()
	keys.erase(_last_general)
	var key: String = String(keys[randi() % keys.size()])
	_last_general = key
	_play(key, false)


func _play(event: String, is_event: bool) -> void:
	var text: String = String(LINES.get(event, GENERAL_LINES.get(event, "")))
	_bubble.text = text
	_bubble.visible = true
	_bubble_timer = BUBBLE_TIME
	_playing_event = is_event and not Save.muted
	_last_line_time = _time_alive
	if Save.muted:
		return
	var clip: AudioStream = CLIPS.get(event, GENERAL_CLIPS.get(event, null))
	if clip == null:
		return
	_player.stop()
	_player.stream = clip
	_player.play()
	print("VOICE: ", event)


func _process(delta: float) -> void:
	_time_alive += delta
	if _playing_event and not _player.playing:
		_playing_event = false
	if _bubble.visible:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0:
			_bubble.visible = false
