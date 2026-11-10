class_name Hud
extends CanvasLayer
## Dijah's Delights Candy Run HUD: score/stars panels (matching the video's plum + brown
## panels), hearts, objective line, center warnings, hint bar, mute button,
## speed-lines overlay, and game-over / win / fail panels.

signal retry_pressed
signal menu_pressed
signal next_pressed
signal mute_pressed

var _score_label: Label
var _dist_label: Label
var _rush_label: Label
var _stars_label: Label
var _streak_label: Label
var _hearts_label: Label
var _board_label: Label
var _objective_label: Label
var _message_label: Label
var _hint_bar: PanelContainer
var _mute_button: Button
var _speed_lines: ColorRect
var _glow: ColorRect
var _game_over_panel: Control
var _win_panel: Control
var _fail_panel: Control
var _go_title: Label
var _go_stats: Label
var _win_title: Label
var _win_stats: Label
var _fail_stats: Label
var _msg_timer: float = 0.0
var _glow_phase: float = 0.0


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- speed lines overlay (shader) ---
	_speed_lines = ColorRect.new()
	_speed_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speed_lines.color = Color(1, 1, 1, 1)
	_speed_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	// Round 7: subtler — fewer, thinner streaks (8 angular divisions,
	// narrow window) confined to the frame edges, so they suggest
	// speed without the big white concentric arcs crossing the
	// whole screen and cluttering the bubble and scenery.
	float lines = fract(a * 8.0 / 6.2831 + r * 8.0 - TIME * 1.5);
	float streak = smoothstep(0.0, 0.05, lines) * smoothstep(0.12, 0.05, lines);
	float edge = smoothstep(0.3, 0.7, r);
	COLOR = vec4(vec3(1.0), streak * edge * intensity);
}
"""
	var smat := ShaderMaterial.new()
	smat.shader = shader
	smat.set_shader_parameter("intensity", 0.0)
	_speed_lines.material = smat
	_speed_lines.visible = false
	root.add_child(_speed_lines)

	# --- sugar rush glow ---
	_glow = ColorRect.new()
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.color = Color(1.0, 0.36, 0.54, 0.0)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.visible = false
	root.add_child(_glow)

	# --- top-left panel: score ---
	var score_panel := _make_panel(Color.html("#4a1030"), Color.html("#ff5c8a"))
	score_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	score_panel.offset_left = 16
	score_panel.offset_top = 16
	score_panel.offset_right = 316
	score_panel.offset_bottom = 138
	root.add_child(score_panel)
	var score_box := VBoxContainer.new()
	score_panel.add_child(score_box)
	_score_label = _make_label("SCORE 0", 30, Color.html("#ffffff"), true)
	score_box.add_child(_score_label)
	_dist_label = _make_label("DISTANCE 0 m | BEST 0", 20, Color.html("#ffffff"))
	score_box.add_child(_dist_label)
	_rush_label = _make_label("SUGAR RUSH 1.0x", 20, Color.html("#5fe3c0"))
	score_box.add_child(_rush_label)

	# --- top-right panel: stars ---
	var stars_panel := _make_panel(Color.html("#3a2405"), Color.html("#ffd23f"))
	stars_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stars_panel.offset_left = -316
	stars_panel.offset_top = 16
	stars_panel.offset_right = -16
	stars_panel.offset_bottom = 118
	root.add_child(stars_panel)
	var stars_box := VBoxContainer.new()
	stars_panel.add_child(stars_box)
	_stars_label = _make_label("★ SUGAR STARS 0", 26, Color.html("#ffd23f"), true)
	stars_box.add_child(_stars_label)
	_streak_label = _make_label("SWEET STREAK x0", 20, Color.html("#ffb3d9"))
	stars_box.add_child(_streak_label)

	# --- board banner (top center, like the mockups) ---
	var board_panel := _make_panel(Color.html("#4a1030"), Color.html("#ff5c8a"))
	board_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	board_panel.offset_left = -230
	board_panel.offset_right = 230
	board_panel.offset_top = 146
	board_panel.offset_bottom = 186
	root.add_child(board_panel)
	_board_label = _make_label("BOARD 1 • CANDYLAND", 24, Color.html("#ffffff"), true)
	_board_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_panel.add_child(_board_label)

	# --- hearts (top center) ---
	_hearts_label = _make_label("♥♥♥", 36, Color.html("#ff2e4d"), true)
	_hearts_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hearts_label.offset_left = -90
	_hearts_label.offset_right = 90
	_hearts_label.offset_top = 192
	_hearts_label.offset_bottom = 232
	_hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hearts_label)

	# --- objective line ---
	_objective_label = _make_label("", 20, Color.html("#ffffff"), true)
	_objective_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_objective_label.offset_left = 16
	_objective_label.offset_top = 238
	_objective_label.offset_right = 700
	_objective_label.offset_bottom = 268
	root.add_child(_objective_label)

	# --- center message (big yellow warnings) ---
	# Round 6: moved up to y ~270 (was ~380) — the raised speech
	# bubble now occupies the old spot and the two texts collided
	# ("NEAR MISS +50" printed across the bubble). Sits just below
	# the objective line and just above the bubble.
	_message_label = _make_label("", 44, Color.html("#ffd23f"), true)
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.offset_left = -340
	_message_label.offset_right = 340
	_message_label.offset_top = -370
	_message_label.offset_bottom = -290
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.visible = false
	root.add_child(_message_label)

	# --- bottom hint bar ---
	_hint_bar = _make_panel(Color(0, 0, 0, 0.75), Color.html("#ff5c8a"))
	_hint_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_bar.offset_left = -290
	_hint_bar.offset_right = 290
	_hint_bar.offset_top = -96
	_hint_bar.offset_bottom = -36
	root.add_child(_hint_bar)
	var hint_label := _make_label("◀ ▶  SWIPE: STEER    •    TAP: JUMP", 20, Color.html("#ffffff"))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_bar.add_child(hint_label)

	# --- mute button (bottom right) ---
	_mute_button = Button.new()
	_mute_button.text = "SOUND ON"
	_mute_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_mute_button.offset_left = -150
	_mute_button.offset_top = -160
	_mute_button.offset_right = -16
	_mute_button.offset_bottom = -108
	_mute_button.add_theme_stylebox_override("normal", _btn_style(Color.html("#4a1030")))
	_mute_button.add_theme_stylebox_override("pressed", _btn_style(Color.html("#7a1030")))
	_mute_button.add_theme_color_override("font_color", Color.html("#ffffff"))
	_mute_button.pressed.connect(func() -> void: mute_pressed.emit())
	root.add_child(_mute_button)

	# --- overlay panels ---
	_game_over_panel = _make_overlay(root)
	_go_title = _overlay_title(_game_over_panel, "SPLASHED IN STRAWBERRY SYRUP!", Color.html("#ff5c8a"))
	_go_stats = _overlay_text(_game_over_panel)
	_overlay_buttons(_game_over_panel, "DASH AGAIN", "MAP", func() -> void: retry_pressed.emit(), func() -> void: menu_pressed.emit())
	_win_panel = _make_overlay(root)
	_win_title = _overlay_title(_win_panel, "BOARD CLEAR!", Color.html("#ffd23f"))
	_win_stats = _overlay_text(_win_panel)
	_overlay_buttons(_win_panel, "NEXT BOARD", "MAP", func() -> void: next_pressed.emit(), func() -> void: menu_pressed.emit())
	_fail_panel = _make_overlay(root)
	_overlay_title(_fail_panel, "SO CLOSE!", Color.html("#ffffff"))
	_fail_stats = _overlay_text(_fail_panel)
	_overlay_buttons(_fail_panel, "TRY AGAIN", "MAP", func() -> void: retry_pressed.emit(), func() -> void: menu_pressed.emit())
	set_mute_icon(not Music.is_muted())


func _process(delta: float) -> void:
	if _msg_timer > 0.0:
		_msg_timer -= delta
		if _msg_timer <= 0.0:
			_message_label.visible = false
	if _glow.visible:
		_glow_phase += delta * 4.0
		var a: float = 0.05 + 0.05 * sin(_glow_phase)
		_glow.color = Color(1.0, 0.36, 0.54, a)


func _make_panel(bg: Color, border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	return p


func _btn_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _make_label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		l.add_theme_constant_override("outline_size", 6)
	return l


func _make_overlay(root: Control) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := _make_panel(Color.html("#4a1030"), Color.html("#ff5c8a"))
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	overlay.set_meta("box", box)
	root.add_child(overlay)
	return overlay


func _overlay_title(overlay: Control, text: String, color: Color) -> Label:
	var box: VBoxContainer = overlay.get_meta("box")
	var l := _make_label(text, 40, color, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	return l


func _overlay_text(overlay: Control) -> Label:
	var box: VBoxContainer = overlay.get_meta("box")
	var l := _make_label("", 26, Color.html("#ffffff"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	return l


func _overlay_buttons(overlay: Control, primary_text: String, secondary_text: String, primary_cb: Callable, secondary_cb: Callable) -> void:
	var box: VBoxContainer = overlay.get_meta("box")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var b1 := Button.new()
	b1.text = primary_text
	b1.custom_minimum_size = Vector2(230, 68)
	b1.add_theme_font_size_override("font_size", 26)
	b1.add_theme_stylebox_override("normal", _btn_style(Color.html("#ff5c8a")))
	b1.add_theme_stylebox_override("pressed", _btn_style(Color.html("#c22e5e")))
	b1.add_theme_color_override("font_color", Color.html("#ffffff"))
	b1.pressed.connect(primary_cb)
	row.add_child(b1)
	var b2 := Button.new()
	b2.text = secondary_text
	b2.custom_minimum_size = Vector2(160, 68)
	b2.add_theme_font_size_override("font_size", 26)
	b2.add_theme_stylebox_override("normal", _btn_style(Color.html("#3a2405")))
	b2.add_theme_stylebox_override("pressed", _btn_style(Color.html("#5e3a05")))
	b2.add_theme_color_override("font_color", Color.html("#ffffff"))
	b2.pressed.connect(secondary_cb)
	row.add_child(b2)


# --- public API used by game.gd ---

func update_hud(score: int, distance: int, best: int, rush_mult: float, stars: int, streak: int, hearts: int, objective_text: String) -> void:
	_score_label.text = "SCORE %d" % score
	_dist_label.text = "DISTANCE %d m | BEST %d" % [distance, best]
	_rush_label.text = "SUGAR RUSH %.1fx" % rush_mult
	_stars_label.text = "★ SUGAR STARS %d" % stars
	_streak_label.text = "SWEET STREAK x%d" % streak
	var h := ""
	for i in range(3):
		h += "♥" if i < hearts else "♡"
	_hearts_label.text = h
	_objective_label.text = objective_text


func show_message(text: String, color: Color = Color.html("#ffd23f"), duration: float = 1.6) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)
	_message_label.visible = true
	_msg_timer = duration


func set_speed_lines(active: bool) -> void:
	_speed_lines.visible = active
	_glow.visible = active
	if active:
		var smat: ShaderMaterial = _speed_lines.material
		# Round 7: 0.35, not 0.8 — the rush lines were overpowering.
		smat.set_shader_parameter("intensity", 0.35)
	else:
		var smat2: ShaderMaterial = _speed_lines.material
		smat2.set_shader_parameter("intensity", 0.0)


func set_mute_icon(sound_on: bool) -> void:
	_mute_button.text = "SOUND ON" if sound_on else "MUTED"


func set_board(text: String) -> void:
	_board_label.text = text


func show_game_over(score: int, distance: int, stars: int, best: int, is_new_best: bool) -> void:
	_go_title.text = "SPLASHED IN STRAWBERRY SYRUP!"
	var extra: String = "\n★ NEW BEST! ★" if is_new_best else ""
	_go_stats.text = "Final Score: %d\nDistance Run: %d m\nSugar Stars: %d | Best Score: %d%s" % [score, distance, stars, best, extra]
	_game_over_panel.visible = true


func show_win(score: int, distance: int, stars: int, best: int, is_new_best: bool, has_next: bool) -> void:
	_win_title.text = "BOARD CLEAR!"
	var extra: String = "\n★ NEW BEST! ★" if is_new_best else ""
	var next_note: String = "\nNext board unlocked!" if has_next else "\nYou finished the finale!"
	_win_stats.text = "Final Score: %d\nDistance Run: %d m\nSugar Stars: +%d | Best Score: %d%s%s" % [score, distance, stars, best, extra, next_note]
	_win_panel.visible = true


func show_fail(objective_label: String, score: int, distance: int, stars: int) -> void:
	_fail_stats.text = "Objective: %s\n\nScore: %d   Distance: %d m   Stars: %d\n\nTry again — you were close!" % [objective_label, score, distance, stars]
	_fail_panel.visible = true


func hide_panels() -> void:
	_game_over_panel.visible = false
	_win_panel.visible = false
	_fail_panel.visible = false
