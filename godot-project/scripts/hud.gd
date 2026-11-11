class_name Hud
extends CanvasLayer
## Dijah's Delights Candy Run HUD — Upgraded with Arcade Game Juice:
## - Score & Star/Combo Pill scale-pop animations on every pickup
## - Live Combo Decay Timer Bar & Fever Tier Badge (1.5x -> 2x -> 3x -> 4x FEVER!)
## - Dynamic Flow Speed indicator (mph / % speed boost)
## - Full-screen arcade flash overlay (gold pickup flash, cyan shield flash, red impact flash)
## - Instant Retry button (`↻ RETRY [R]`) on HUD + one-tap/key instant retry on overlays.

signal retry_pressed
signal menu_pressed
signal next_pressed
signal mute_pressed

var _score_panel: PanelContainer
var _stars_panel: PanelContainer
var _score_label: Label
var _dist_label: Label
var _rush_label: Label
var _stars_label: Label
var _streak_label: Label
var _combo_bar: ProgressBar
var _hearts_label: Label
var _board_label: Label
var _objective_label: Label
var _message_label: Label
var _hint_bar: PanelContainer
var _mute_button: Button
var _quick_retry_button: Button
var _speed_lines: ColorRect
var _glow: ColorRect
var _flash_rect: ColorRect
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
var _score_pop_t: float = 0.0
var _combo_pop_t: float = 0.0
var _msg_pop_t: float = 0.0
var _flash_alpha: float = 0.0
var _fever_left: float = 0.0


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- dynamic speed lines overlay (shader) ---
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
	float lines = fract(a * 12.0 / 6.2831 + r * 9.0 - TIME * 2.2);
	float streak = smoothstep(0.0, 0.05, lines) * smoothstep(0.14, 0.05, lines);
	float edge = smoothstep(0.28, 0.68, r);
	COLOR = vec4(vec3(1.0, 0.96, 0.88), streak * edge * intensity);
}
"""
	var smat := ShaderMaterial.new()
	smat.shader = shader
	smat.set_shader_parameter("intensity", 0.0)
	_speed_lines.material = smat
	_speed_lines.visible = false
	root.add_child(_speed_lines)

	# --- sugar rush edge glow ---
	_glow = ColorRect.new()
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.color = Color(1.0, 0.36, 0.54, 0.0)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.visible = false
	root.add_child(_glow)

	# --- full-screen arcade impact/pickup flash ---
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash_rect)

	# --- top-left candy-wrapper pill: SCORE + SPEED FLOW ---
	_score_panel = _make_panel(Color.html("#ec5b93"), Color.html("#fff5fa"))
	_score_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_score_panel.offset_left = 14
	_score_panel.offset_top = 14
	_score_panel.offset_right = 244
	_score_panel.offset_bottom = 98
	_score_panel.pivot_offset = Vector2(115, 42)
	root.add_child(_score_panel)
	var score_box := VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 0)
	_score_panel.add_child(score_box)
	_score_label = _make_label("SCORE  0", 24, Color.html("#ffffff"), true)
	score_box.add_child(_score_label)
	_dist_label = _make_label("0 m  •  BEST 0", 14, Color.html("#ffeaf4"), true)
	score_box.add_child(_dist_label)
	_rush_label = _make_label("⚡ FLOW 100%  •  1.0x", 14, Color.html("#ffd23f"), true)
	score_box.add_child(_rush_label)

	# --- top-center golden star pill + COMBO STREAK & DECAY BAR ---
	_stars_panel = _make_panel(Color.html("#f7a828"), Color.html("#fff8e1"))
	_stars_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_stars_panel.offset_left = -105
	_stars_panel.offset_top = 14
	_stars_panel.offset_right = 105
	_stars_panel.offset_bottom = 98
	_stars_panel.pivot_offset = Vector2(105, 42)
	root.add_child(_stars_panel)
	var stars_box := VBoxContainer.new()
	stars_box.add_theme_constant_override("separation", 2)
	_stars_panel.add_child(stars_box)
	_stars_label = _make_label("★  0", 24, Color.html("#ffffff"), true)
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_box.add_child(_stars_label)
	_streak_label = _make_label("STREAK x0", 15, Color.html("#fff4cc"), true)
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_box.add_child(_streak_label)

	_combo_bar = ProgressBar.new()
	_combo_bar.custom_minimum_size = Vector2(170, 10)
	_combo_bar.max_value = 1.0
	_combo_bar.value = 0.0
	_combo_bar.show_percentage = false
	var cb_bg := StyleBoxFlat.new()
	cb_bg.bg_color = Color(0.22, 0.08, 0.02, 0.55)
	cb_bg.set_corner_radius_all(5)
	var cb_fg := StyleBoxFlat.new()
	cb_fg.bg_color = Color.html("#ff2fb3")
	cb_fg.set_corner_radius_all(5)
	_combo_bar.add_theme_stylebox_override("background", cb_bg)
	_combo_bar.add_theme_stylebox_override("fill", cb_fg)
	stars_box.add_child(_combo_bar)

	# --- hearts right under the center star pill ---
	_hearts_label = _make_label("♥♥♥", 30, Color.html("#ff2e55"), true)
	_hearts_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hearts_label.offset_left = -90
	_hearts_label.offset_right = 90
	_hearts_label.offset_top = 100
	_hearts_label.offset_bottom = 134
	_hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hearts_label)

	# --- top-right candy-wrapper pill: BOARD BANNER ---
	var board_panel := _make_panel(Color.html("#ec5b93"), Color.html("#fff5fa"))
	board_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	board_panel.offset_left = -238
	board_panel.offset_right = -14
	board_panel.offset_top = 14
	board_panel.offset_bottom = 86
	root.add_child(board_panel)
	_board_label = _make_label("BOARD 1\nCANDYLAND", 19, Color.html("#ffffff"), true)
	_board_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_panel.add_child(_board_label)

	# --- compact objective pill ---
	_objective_label = _make_label("", 17, Color.html("#ffffff"), true)
	_objective_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_objective_label.offset_left = -280
	_objective_label.offset_top = 132
	_objective_label.offset_right = 280
	_objective_label.offset_bottom = 158
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_objective_label)

	# --- center arcade callout message (with scale-pop animation) ---
	_message_label = _make_label("", 44, Color.html("#ffd23f"), true)
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.offset_left = -340
	_message_label.offset_right = 340
	_message_label.offset_top = -370
	_message_label.offset_bottom = -290
	_message_label.pivot_offset = Vector2(340, 40)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.visible = false
	root.add_child(_message_label)

	# --- bottom hint bar ---
	_hint_bar = _make_panel(Color(0, 0, 0, 0.75), Color.html("#ff5c8a"))
	_hint_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_bar.offset_left = -310
	_hint_bar.offset_right = 310
	_hint_bar.offset_top = -92
	_hint_bar.offset_bottom = -34
	root.add_child(_hint_bar)
	var hint_label := _make_label("◀ ▶ SWIPE: STEER  •  TAP: JUMP  •  [R] INSTANT RETRY", 18, Color.html("#ffffff"))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_bar.add_child(hint_label)

	# --- quick instant retry button (bottom left) ---
	_quick_retry_button = Button.new()
	_quick_retry_button.text = "↻ RETRY [R]"
	_quick_retry_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_quick_retry_button.offset_left = 16
	_quick_retry_button.offset_top = -156
	_quick_retry_button.offset_right = 164
	_quick_retry_button.offset_bottom = -104
	_quick_retry_button.add_theme_stylebox_override("normal", _btn_style(Color.html("#ff4081")))
	_quick_retry_button.add_theme_stylebox_override("pressed", _btn_style(Color.html("#c2185b")))
	_quick_retry_button.add_theme_color_override("font_color", Color.html("#ffffff"))
	_quick_retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	root.add_child(_quick_retry_button)

	# --- mute button (bottom right) ---
	_mute_button = Button.new()
	_mute_button.text = "SOUND ON"
	_mute_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_mute_button.offset_left = -150
	_mute_button.offset_top = -156
	_mute_button.offset_right = -16
	_mute_button.offset_bottom = -104
	_mute_button.add_theme_stylebox_override("normal", _btn_style(Color.html("#4a1030")))
	_mute_button.add_theme_stylebox_override("pressed", _btn_style(Color.html("#7a1030")))
	_mute_button.add_theme_color_override("font_color", Color.html("#ffffff"))
	_mute_button.pressed.connect(func() -> void: mute_pressed.emit())
	root.add_child(_mute_button)

	# --- overlay panels ---
	_game_over_panel = _make_overlay(root)
	_go_title = _overlay_title(_game_over_panel, "SPLASHED IN STRAWBERRY SYRUP!", Color.html("#ff5c8a"))
	_go_stats = _overlay_text(_game_over_panel)
	_overlay_buttons(_game_over_panel, "⚡ INSTANT RETRY [R]", "MAP", func() -> void: retry_pressed.emit(), func() -> void: menu_pressed.emit())
	_win_panel = _make_overlay(root)
	_win_title = _overlay_title(_win_panel, "BOARD CLEAR!", Color.html("#ffd23f"))
	_win_stats = _overlay_text(_win_panel)
	_overlay_buttons(_win_panel, "NEXT BOARD ➔", "MAP", func() -> void: next_pressed.emit(), func() -> void: menu_pressed.emit())
	_fail_panel = _make_overlay(root)
	_overlay_title(_fail_panel, "SO CLOSE!", Color.html("#ffffff"))
	_fail_stats = _overlay_text(_fail_panel)
	_overlay_buttons(_fail_panel, "⚡ INSTANT RETRY [R]", "MAP", func() -> void: retry_pressed.emit(), func() -> void: menu_pressed.emit())
	set_mute_icon(not Music.is_muted())


func _process(delta: float) -> void:
	if _msg_timer > 0.0:
		_msg_timer -= delta
		if _msg_timer <= 0.0:
			_message_label.visible = false
	if _msg_pop_t > 0.0:
		_msg_pop_t = maxf(0.0, _msg_pop_t - delta * 5.0)
		var s_m: float = 1.0 + sin(_msg_pop_t * PI) * 0.28
		_message_label.scale = Vector2(s_m, s_m)
	else:
		_message_label.scale = Vector2.ONE

	if _score_pop_t > 0.0:
		_score_pop_t = maxf(0.0, _score_pop_t - delta * 6.0)
		var s_sc: float = 1.0 + sin(_score_pop_t * PI) * 0.16
		_score_panel.scale = Vector2(s_sc, s_sc)
	else:
		_score_panel.scale = Vector2.ONE

	if _combo_pop_t > 0.0:
		_combo_pop_t = maxf(0.0, _combo_pop_t - delta * 6.0)
		var s_cb: float = 1.0 + sin(_combo_pop_t * PI) * 0.22
		_stars_panel.scale = Vector2(s_cb, s_cb)
	else:
		_stars_panel.scale = Vector2.ONE

	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * 3.2)
		_flash_rect.color.a = _flash_alpha

	if _glow.visible:
		_glow_phase += delta * 5.0
		var a: float = 0.06 + 0.05 * sin(_glow_phase)
		_glow.color = Color(1.0, 0.36, 0.54, a)


func trigger_score_pop() -> void:
	_score_pop_t = 1.0


func trigger_combo_pop() -> void:
	_combo_pop_t = 1.0


func flash_screen(col: Color, max_alpha: float = 0.28) -> void:
	_flash_rect.color = Color(col.r, col.g, col.b, max_alpha)
	_flash_alpha = max_alpha


func set_combo_bar(ratio: float, fever_active: bool) -> void:
	if _combo_bar:
		_combo_bar.value = clampf(ratio, 0.0, 1.0)
		var fg: StyleBoxFlat = _combo_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fg:
			fg.bg_color = Color.html("#00e5ff") if fever_active else Color.html("#ff2fb3")


func _make_panel(bg: Color, border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 8
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	return p


func _btn_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.darkened(0.38)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 6
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.38)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
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
	b1.custom_minimum_size = Vector2(260, 68)
	b1.add_theme_font_size_override("font_size", 24)
	b1.add_theme_stylebox_override("normal", _btn_style(Color.html("#ff5c8a")))
	b1.add_theme_stylebox_override("pressed", _btn_style(Color.html("#c22e5e")))
	b1.add_theme_color_override("font_color", Color.html("#ffffff"))
	b1.pressed.connect(primary_cb)
	row.add_child(b1)
	var b2 := Button.new()
	b2.text = secondary_text
	b2.custom_minimum_size = Vector2(150, 68)
	b2.add_theme_font_size_override("font_size", 24)
	b2.add_theme_stylebox_override("normal", _btn_style(Color.html("#3a2405")))
	b2.add_theme_stylebox_override("pressed", _btn_style(Color.html("#5e3a05")))
	b2.add_theme_color_override("font_color", Color.html("#ffffff"))
	b2.pressed.connect(secondary_cb)
	row.add_child(b2)


# --- public API used by game.gd ---

func update_hud(score: int, distance: int, best: int, rush_mult: float, stars: int, streak: int, hearts: int, objective_text: String, speed_pct: int = 100) -> void:
	_score_label.text = "SCORE  %d" % score
	_dist_label.text = "%d m  •  BEST %d" % [distance, best]
	_rush_label.text = "⚡ SPEED %d%%  •  %.1fx" % [speed_pct, rush_mult]
	_rush_label.visible = true
	_stars_label.text = "★  %d" % stars
	if _fever_left > 0.0:
		_streak_label.text = "🌈 INVINCIBLE %.1fs" % _fever_left
		_streak_label.add_theme_color_override("font_color", Color.html("#00e5ff"))
	elif streak >= 20:
		_streak_label.text = "🔥 FEVER x%d!" % streak
		_streak_label.add_theme_color_override("font_color", Color.html("#00e5ff"))
	elif streak >= 5:
		_streak_label.text = "⚡ STREAK x%d" % streak
		_streak_label.add_theme_color_override("font_color", Color.html("#ffd23f"))
	else:
		_streak_label.text = "STREAK x%d" % streak
		_streak_label.add_theme_color_override("font_color", Color.html("#fff4cc"))
	var max_h: int = maxi(3, hearts)
	var h := ""
	for i in range(max_h):
		h += "♥" if i < hearts else "♡"
	_hearts_label.text = h
	_objective_label.text = objective_text


func set_board(text: String) -> void:
	_board_label.text = text.replace(" • ", "\n")


func show_message(text: String, color: Color = Color.html("#ffd23f"), duration: float = 1.6) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)
	_message_label.visible = true
	_msg_timer = duration
	_msg_pop_t = 1.0


func set_speed_lines(active: bool, custom_intensity: float = 0.38) -> void:
	_speed_lines.visible = active
	_glow.visible = active
	if active:
		var smat: ShaderMaterial = _speed_lines.material
		smat.set_shader_parameter("intensity", clampf(custom_intensity, 0.15, 0.65))
	else:
		var smat2: ShaderMaterial = _speed_lines.material
		smat2.set_shader_parameter("intensity", 0.0)


func set_mute_icon(sound_on: bool) -> void:
	_mute_button.text = "SOUND ON" if sound_on else "MUTED"


func show_game_over(score: int, distance: int, stars: int, best: int, is_new_best: bool) -> void:
	_go_title.text = "SPLASHED IN STRAWBERRY SYRUP!"
	var extra: String = "\n★ NEW BEST! ★" if is_new_best else ""
	_go_stats.text = "Final Score: %d\nDistance Run: %d m\nSugar Stars: %d | Best Score: %d%s\n\n[Press R or SPACE for Instant Retry!]" % [score, distance, stars, best, extra]
	_game_over_panel.visible = true


func set_fever(seconds_left: float) -> void:
	_fever_left = seconds_left


func show_win(score: int, distance: int, stars: int, best: int, is_new_best: bool, has_next: bool, rating: int = 0, star_pct: float = 0.0, clear_time: float = 0.0, par: float = 0.0) -> void:
	_win_title.text = "BOARD CLEAR!"
	var extra: String = "\n★ NEW BEST! ★" if is_new_best else ""
	var next_note: String = "\nNext board unlocked!" if has_next else "\nYou finished the finale!"
	var rate: String = ""
	if rating > 0:
		var r_stars: String = "★".repeat(rating) + "☆".repeat(3 - rating)
		var got_pct: bool = star_pct >= 0.9
		var got_par: bool = par > 0.0 and clear_time <= par
		rate = "\n%s\n%s Clear   %s 90%% stars (%d%%)   %s Par %ds (you: %.1fs)" % [
			r_stars, "✔", "✔" if got_pct else "✘", int(star_pct * 100.0), "✔" if got_par else "✘", int(par), clear_time]
	_win_stats.text = "Final Score: %d\nDistance Run: %d m\nSugar Stars: +%d | Best Score: %d%s%s%s" % [score, distance, stars, best, rate, extra, next_note]
	_win_panel.visible = true


func _unused_show_win_legacy(score: int, distance: int, stars: int, best: int, is_new_best: bool, has_next: bool) -> void:
	_win_title.text = "BOARD CLEAR!"
	var extra: String = "\n★ NEW BEST! ★" if is_new_best else ""
	var next_note: String = "\nNext board unlocked!" if has_next else "\nYou finished the finale!"
	_win_stats.text = "Final Score: %d\nDistance Run: %d m\nSugar Stars: +%d | Best Score: %d%s%s" % [score, distance, stars, best, extra, next_note]
	_win_panel.visible = true


func show_fail(objective_label: String, score: int, distance: int, stars: int) -> void:
	_fail_stats.text = "Objective: %s\n\nScore: %d   Distance: %d m   Stars: %d\n\n[Press R or SPACE for Instant Retry!]" % [objective_label, score, distance, stars]
	_fail_panel.visible = true


func hide_panels() -> void:
	_game_over_panel.visible = false
	_win_panel.visible = false
	_fail_panel.visible = false
