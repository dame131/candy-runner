extends Control
## Dijah Dash — main menu: title, Play, Shop, mute, best score.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.html("#ff5c8a")
	add_child(bg)
	# decorative candy dots
	for i in range(12):
		var dot := ColorRect.new()
		var size: float = randf_range(30.0, 70.0)
		dot.size = Vector2(size, size)
		dot.position = Vector2(randf_range(0.0, 640.0), randf_range(80.0, 1180.0))
		dot.color = Color(1, 1, 1, 0.12)
		add_child(dot)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -300
	box.offset_right = 300
	box.offset_top = -420
	box.offset_bottom = 420
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	add_child(box)

	var title := Label.new()
	title.text = "DIJAH\nDASH"
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color.html("#ffffff"))
	title.add_theme_color_override("font_outline_color", Color.html("#5b2333"))
	title.add_theme_constant_override("outline_size", 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub := Label.new()
	sub.text = "A candy runner for Dijah"
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", Color.html("#ffd23f"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var play := _big_button("▶  PLAY", Color.html("#ffd23f"), Color.html("#5b2333"))
	play.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/roadmap.tscn"))
	box.add_child(play)

	var shop := _big_button("OUTFITS", Color.html("#ffffff"), Color.html("#5b2333"))
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	box.add_child(shop)

	var mute := _big_button("SOUND: ON" if not Music.is_muted() else "SOUND: MUTED", Color.html("#4a1030"), Color.html("#ffffff"))
	mute.pressed.connect(func() -> void:
		Music.set_muted(not Music.is_muted())
		mute.text = "SOUND: ON" if not Music.is_muted() else "SOUND: MUTED"
	)
	box.add_child(mute)

	var stars := Label.new()
	stars.text = "★ Sugar Stars: %d" % Save.stars_total
	stars.add_theme_font_size_override("font_size", 26)
	stars.add_theme_color_override("font_color", Color.html("#ffffff"))
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stars)

	var ver := Label.new()
	ver.text = "v1.0.0  •  Made for Dijah"
	ver.add_theme_font_size_override("font_size", 18)
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ver)


func _big_button(text: String, bg: Color, fg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(480, 84)
	b.add_theme_font_size_override("font_size", 34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(20)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", sb)
	var sb2 := StyleBoxFlat.new()
	sb2.bg_color = bg.darkened(0.2)
	sb2.set_corner_radius_all(20)
	b.add_theme_stylebox_override("pressed", sb2)
	b.add_theme_color_override("font_color", fg)
	return b
