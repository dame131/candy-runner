class_name VoiceLines
extends Node3D
## Dijah's Delights Candy Run — Dijah's spoken one-liners (sarcastic nursing humor; LPN).
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

## Blueberry pool: 5 jokes that play ONLY on board 21 "Blueberry Bash"
## (Dijah hates blueberries). Same cooldown/priority rules as the general
## pool. Never plays on any other board.
const BLUEBERRY_LINES: Dictionary = {
	"blueberry_hate": "Blueberries? In MY candy run? Absolutely not.",
	"blueberry_chart": "I hate blueberries. Chart it.",
	"blueberry_tried": "That blueberry tried me. It lost.",
	"blueberry_grapes": "Blueberries are just sad little grapes.",
	"blueberry_writeup": "Touch me with a blueberry and I'm writing you up.",
}

const BLUEBERRY_CLIPS: Dictionary = {
	"blueberry_hate": preload("res://audio/voices/blueberry_hate.wav"),
	"blueberry_chart": preload("res://audio/voices/blueberry_chart.wav"),
	"blueberry_tried": preload("res://audio/voices/blueberry_tried.wav"),
	"blueberry_grapes": preload("res://audio/voices/blueberry_grapes.wav"),
	"blueberry_writeup": preload("res://audio/voices/blueberry_writeup.wav"),
}

var _player: AudioStreamPlayer
var _bubble: Label3D
var _bubble_panel: Sprite3D
var _bubble_timer: float = 0.0
var _time_alive: float = 0.0
var _last_line_time: float = -100.0
var _playing_event: bool = false
var _last_general: String = ""
var _last_blueberry: String = ""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	# Dark rounded panel behind the bubble text (like the HUD panels:
	# dark plum, thin pink border) so white text always reads over the
	# busy track. Generated once as a texture; sized per line below.
	_bubble_panel = Sprite3D.new()
	_bubble_panel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble_panel.no_depth_test = true
	_bubble_panel.shaded = false
	_bubble_panel.texture = _panel_texture()
	_bubble_panel.pixel_size = 0.0074  # 256 px texture -> ~1.9 m wide
	# Round 6: raised to 3.45 (was 2.65) — with the closer camera the
	# bubble sat right on top of her head and hid the braids. At 3.45
	# it floats above her head, clear of the hair and below the HUD.
	_bubble_panel.position = Vector3(0, 3.45, -0.06)
	_bubble_panel.visible = false
	add_child(_bubble_panel)
	_bubble = Label3D.new()
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.font_size = 48
	_bubble.pixel_size = 0.0045
	_bubble.width = 320.0
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.outline_size = 8
	_bubble.modulate = Color.html("#ffffff")
	_bubble.outline_modulate = Color.html("#4a1030")
	# Raised so the panel clears her head (top of hair ~2.2) — and
	# with the round-6 closer camera, raised further to 3.45 so it
	# never covers the braids.
	_bubble.position = Vector3(0, 3.45, 0)
	_bubble.visible = false
	add_child(_bubble)


func _panel_texture() -> ImageTexture:
	# Rounded rectangle, dark plum fill, pink border, transparent outside.
	var w := 256
	var h := 176
	var rad := 30.0
	var border_px := 7.0
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var fill := Color(0.16, 0.04, 0.12, 0.94)
	var border := Color(1.0, 0.36, 0.54, 1.0)
	for y in range(h):
		for x in range(w):
			var px: float = float(x) + 0.5
			var py: float = float(y) + 0.5
			var cx: float = clampf(px, rad, float(w) - rad)
			var cy: float = clampf(py, rad, float(h) - rad)
			var d: float = Vector2(px - cx, py - cy).length()
			if d > rad:
				continue
			var bx: float = clampf(px, rad + border_px, float(w) - rad - border_px)
			var by: float = clampf(py, rad + border_px, float(h) - rad - border_px)
			var bd: float = Vector2(px - bx, py - by).length()
			img.set_pixel(x, y, border if bd > rad - border_px else fill)
	return ImageTexture.create_from_image(img)


func _bubble_lines(text: String) -> int:
	# Greedy word wrap at ~11 chars/line (matches Label3D width 320
	# at font 48) so the panel height fits the wrapped text.
	var lines := 1
	var cur := 0
	for word in text.split(" "):
		var wl: int = word.length()
		if cur == 0:
			cur = wl
		elif cur + 1 + wl <= 11:
			cur += 1 + wl
		else:
			lines += 1
			cur = wl
	return lines


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


## Blueberry line: random pool line for regular star pickups on board 21
## ONLY. Same cooldown and event-priority rules as play_general().
func play_blueberry() -> void:
	if _time_alive - _last_line_time < GENERAL_COOLDOWN:
		return
	if _playing_event and _player.playing:
		return
	var keys: Array = BLUEBERRY_LINES.keys()
	keys.erase(_last_blueberry)
	var key: String = String(keys[randi() % keys.size()])
	_last_blueberry = key
	_play(key, false)


func _play(event: String, is_event: bool) -> void:
	var text: String = String(LINES.get(event, GENERAL_LINES.get(event, BLUEBERRY_LINES.get(event, ""))))
	_bubble.text = text
	_bubble.visible = true
	# Size the panel to the wrapped text (line ~0.28 m at this font size,
	# texture is 1.9 x 1.31 m at pixel_size 0.0074).
	var ph: float = float(_bubble_lines(text)) * 0.28 + 0.30
	_bubble_panel.scale = Vector3(1.0, ph / 1.31, 1.0)
	_bubble_panel.visible = true
	_bubble_timer = BUBBLE_TIME
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
	print("VOICE: ", event)


func _process(delta: float) -> void:
	_time_alive += delta
	if _playing_event and not _player.playing:
		_playing_event = false
	if _bubble.visible:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0:
			_bubble.visible = false
			_bubble_panel.visible = false
