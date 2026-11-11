class_name MusicManager
extends Node
## Dijah's Delights Candy Run — procedural music: a fresh chiptune loop is generated per
## board (tempo, root note, scale, waveform) as a looping AudioStreamWAV.
## SFX are tiny generated blips. Mute state lives in Save.

const MIX_RATE := 22050

var _music_player: AudioStreamPlayer
var _sfx_players: Array = []
var _sfx_cache: Dictionary = {}
var _current_board: int = -1


func _get_save() -> Node:
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var root = (loop as SceneTree).root
		if root and root.has_node("Save"):
			return root.get_node("Save")
	return null


func _get_boards() -> Node:
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		var root = (loop as SceneTree).root
		if root and root.has_node("Boards"):
			return root.get_node("Boards")
	return null


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	var s := _get_save()
	if s:
		AudioServer.set_bus_mute(0, bool(s.get("muted")))


func set_muted(m: bool) -> void:
	var s := _get_save()
	if s:
		s.set("muted", m)
		if s.has_method("save_game"):
			s.save_game()
	AudioServer.set_bus_mute(0, m)


func is_muted() -> bool:
	var s := _get_save()
	return bool(s.get("muted")) if s else false


func play_board(board_index: int) -> void:
	if board_index == _current_board and _music_player.playing:
		return
	_current_board = board_index
	var b_node := _get_boards()
	var board: Dictionary = b_node.get_board(board_index) if b_node else {}
	var m: Dictionary = board.get("music", {})
	var wav := _make_loop(int(m.get("tempo", 120)), int(m.get("root", 60)), m.get("scale", [0, 2, 4, 7, 9]), int(m.get("wave", 0)), board_index)
	_music_player.stream = wav
	_music_player.volume_db = -13.5 # Balanced so voice lines remain crystal-clear
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()
	_current_board = -1


## Generate a 4-bar loop (16th-note grid) as a looping 16-bit WAV.
func _make_loop(tempo: int, root: int, scale: Array, wave: int, seed: int) -> AudioStreamWAV:
	var step_dur: float = 60.0 / float(tempo) / 4.0
	var steps: int = 64
	var total_seconds: float = step_dur * float(steps)
	var count: int = int(total_seconds * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + seed * 77
	# Melody pattern: one scale degree per 8th note, some rests.
	var melody: Array = []
	for i in range(steps):
		if i % 2 == 1:
			melody.append(-1)
		elif rng.randf() < 0.22:
			melody.append(-1)
		else:
			melody.append(int(scale[rng.randi_range(0, scale.size() - 1)]) + 12 * rng.randi_range(0, 1))
	var sample: float = 0.0
	for n in range(count):
		var t: float = float(n) / MIX_RATE
		var step: int = int(t / step_dur)
		var step_t: float = fmod(t, step_dur)
		sample = 0.0
		# Melody voice (sine, or square-ish when wave == 1).
		var deg: int = melody[step]
		if deg >= 0:
			var freq: float = _midi_to_freq(root + deg)
			var env: float = exp(-3.0 * step_t / step_dur)
			var ph: float = TAU * freq * step_t
			var osc: float = sin(ph)
			if wave == 1:
				osc = sign(sin(ph)) * 0.6 + sin(ph) * 0.4
			sample += osc * 0.30 * env
		# Bass on every beat (steps 0,4,8,12...): root or fifth.
		if step % 4 == 0:
			var bass_deg: int = 0 if (step / 4) % 2 == 0 else 7
			var bf: float = _midi_to_freq(root - 24 + bass_deg)
			sample += sin(TAU * bf * step_t) * 0.28 * exp(-2.0 * step_t / step_dur)
		# Kick drum on beats: quick sine drop.
		if step % 4 == 0 and step_t < 0.12:
			var kf: float = 120.0 - 600.0 * step_t
			sample += sin(TAU * kf * step_t) * 0.35 * (1.0 - step_t / 0.12)
		# Hat tick on off-beats: tiny noise burst.
		if step % 2 == 1 and step_t < 0.03:
			sample += (rng.randf() * 2.0 - 1.0) * 0.08
		sample = clampf(sample, -0.9, 0.9)
		var v: int = int(sample * 32767.0)
		data[n * 2] = v & 0xFF
		data[n * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = count
	return wav


func _midi_to_freq(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - 69) / 12.0)


## ---- SFX (short generated blips, cached) ----

func play_sfx(kind: String, pitch: float = 1.0) -> void:
	if is_muted():
		return
	var stream: AudioStreamWAV = _sfx_cache.get(kind, null)
	if stream == null:
		stream = _make_sfx(kind)
		_sfx_cache[kind] = stream
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.volume_db = -6.0
			p.play()
			return
	_sfx_players[0].stream = stream
	_sfx_players[0].pitch_scale = pitch
	_sfx_players[0].play()


## Pickup blip that climbs a pentatonic scale as the streak grows (resets at streak 0).
const PICKUP_SEMITONES: Array = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26]


func play_pickup(streak: int, big: bool = false) -> void:
	var idx: int = clampi(streak - 1, 0, PICKUP_SEMITONES.size() - 1)
	var pitch: float = pow(2.0, float(PICKUP_SEMITONES[idx]) / 12.0)
	play_sfx("bigpop" if big else "pop", pitch)


func _make_sfx(kind: String) -> AudioStreamWAV:
	var dur := 0.18
	var freqs: Array = []
	match kind:
		"pop":
			dur = 0.12
			freqs = [880.0, 1320.0]
		"bigpop":
			dur = 0.2
			freqs = [660.0, 990.0, 1320.0]
		"jump":
			dur = 0.15
			freqs = [440.0, 660.0]
		"fall":
			dur = 0.35
			freqs = [300.0, 150.0]
		"sour":
			dur = 0.3
			freqs = [220.0, 180.0, 140.0]
		"win":
			dur = 0.6
			freqs = [523.0, 659.0, 784.0, 1046.0]
		"click":
			dur = 0.06
			freqs = [1000.0]
		"streak":
			dur = 0.15
			freqs = [990.0, 1480.0]
		_:
			freqs = [440.0]
	var count: int = int(dur * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var per: float = dur / float(freqs.size())
	for n in range(count):
		var t: float = float(n) / MIX_RATE
		var idx: int = mini(int(t / per), freqs.size() - 1)
		var f: float = float(freqs[idx])
		var env: float = 1.0 - float(n) / float(count)
		var s: float = sin(TAU * f * t) * 0.5 * env
		var v: int = int(clampf(s, -0.9, 0.9) * 32767.0)
		data[n * 2] = v & 0xFF
		data[n * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
