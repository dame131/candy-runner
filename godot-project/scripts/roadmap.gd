extends Control
## Dijah Dash — roadmap map: full-screen winding path with all 20 boards
## in their own colors. Boards stay locked until the previous one is beaten.

var _stars_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.html("#ffd6e8")
	add_child(bg)

	# header
	var header := Label.new()
	header.text = "CHOOSE A BOARD"
	header.add_theme_font_size_override("font_size", 40)
	header.add_theme_color_override("font_color", Color.html("#5b2333"))
	header.add_theme_color_override("font_outline_color", Color.html("#ffffff"))
	header.add_theme_constant_override("outline_size", 6)
	header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header.offset_left = -300
	header.offset_right = 300
	header.offset_top = 24
	header.offset_bottom = 84
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)

	_stars_label = Label.new()
	_stars_label.text = "★ %d sugar stars" % Save.stars_total
	_stars_label.add_theme_font_size_override("font_size", 26)
	_stars_label.add_theme_color_override("font_color", Color.html("#5b2333"))
	_stars_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_stars_label.offset_left = -300
	_stars_label.offset_right = 300
	_stars_label.offset_top = 88
	_stars_label.offset_bottom = 122
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_stars_label)

	# scrollable map
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 130
	scroll.offset_bottom = -96
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var map := Control.new()
	map.custom_minimum_size = Vector2(720, 2000)
	scroll.add_child(map)

	# winding golden path
	var line := Line2D.new()
	line.width = 16.0
	line.default_color = Color.html("#ffd23f")
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for i in range(Boards.board_count()):
		line.add_point(_node_pos(i))
	map.add_child(line)

	# board nodes
	for i in range(Boards.board_count()):
		var board: Dictionary = Boards.get_board(i)
		var unlocked: bool = Save.is_unlocked(i)
		var b := Button.new()
		var best: int = Save.best_score(i)
		if unlocked:
			b.text = "%d  %s" % [i + 1, board.get("name", "")]
			if best > 0:
				b.text += "  •  BEST %d" % best
		else:
			b.text = "%d  LOCKED" % (i + 1)
		b.custom_minimum_size = Vector2(430, 64)
		b.add_theme_font_size_override("font_size", 24)
		var pal: Dictionary = board.get("palette", {})
		var accent: Color = Color.html(pal.get("accent", "#ffd23f"))
		var sb := StyleBoxFlat.new()
		sb.bg_color = accent if unlocked else Color(0.6, 0.6, 0.6)
		sb.set_corner_radius_all(32)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		b.add_theme_stylebox_override("normal", sb)
		var sb2 := StyleBoxFlat.new()
		sb2.bg_color = accent.darkened(0.2) if unlocked else Color(0.5, 0.5, 0.5)
		sb2.set_corner_radius_all(32)
		b.add_theme_stylebox_override("pressed", sb2)
		b.add_theme_stylebox_override("disabled", sb)
		b.add_theme_color_override("font_color", Color.html("#ffffff") if unlocked else Color(0.9, 0.9, 0.9))
		b.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
		b.disabled = not unlocked
		var pos: Vector2 = _node_pos(i)
		b.position = Vector2(pos.x - 215, pos.y - 32)
		var idx: int = i
		b.pressed.connect(func() -> void:
			Boards.selected_board = idx
			get_tree().change_scene_to_file("res://scenes/game.tscn")
		)
		map.add_child(b)

	# bottom bar: back + shop
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -320
	bar.offset_right = 320
	bar.offset_top = -88
	bar.offset_bottom = -16
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 20)
	add_child(bar)
	var back := _bar_button("← MENU", Color.html("#4a1030"))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	bar.add_child(back)
	var shop := _bar_button("OUTFITS", Color.html("#ff5c8a"))
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	bar.add_child(shop)


func _node_pos(i: int) -> Vector2:
	var y: float = 90.0 + float(i) * 92.0
	var x: float = 360.0 + sin(float(i) * 0.55) * 130.0
	return Vector2(x, y)


func _bar_button(text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 64)
	b.add_theme_font_size_override("font_size", 28)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(16)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", Color.html("#ffffff"))
	return b
