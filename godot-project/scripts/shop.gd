extends Control
## Dijah Dash — outfit shop: spend sugar stars on Dijah's looks.

var _balance_label: Label
var _rows: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.html("#ffd6e8")
	add_child(bg)

	var title := Label.new()
	title.text = "DIJAH'S OUTFITS"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.html("#5b2333"))
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -300
	title.offset_right = 300
	title.offset_top = 24
	title.offset_bottom = 84
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	_balance_label = Label.new()
	_balance_label.add_theme_font_size_override("font_size", 26)
	_balance_label.add_theme_color_override("font_color", Color.html("#5b2333"))
	_balance_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_balance_label.offset_left = -300
	_balance_label.offset_right = 300
	_balance_label.offset_top = 88
	_balance_label.offset_bottom = 122
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_balance_label)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 130
	scroll.offset_bottom = -96
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.custom_minimum_size = Vector2(680, 0)
	_rows.add_theme_constant_override("separation", 14)
	scroll.add_child(_rows)

	var back := Button.new()
	back.text = "← BACK TO MAP"
	back.custom_minimum_size = Vector2(300, 64)
	back.add_theme_font_size_override("font_size", 28)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.html("#4a1030")
	sb.set_corner_radius_all(16)
	back.add_theme_stylebox_override("normal", sb)
	back.add_theme_color_override("font_color", Color.html("#ffffff"))
	back.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	back.offset_left = -150
	back.offset_right = 150
	back.offset_top = -88
	back.offset_bottom = -16
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/roadmap.tscn"))
	add_child(back)

	_refresh()


func _refresh() -> void:
	_balance_label.text = "★ %d sugar stars" % Save.stars_total
	for child in _rows.get_children():
		child.queue_free()
	for i in range(Boards.OUTFITS.size()):
		var outfit: Dictionary = Boards.OUTFITS[i]
		var row := PanelContainer.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color.html("#ffffff")
		psb.set_corner_radius_all(16)
		psb.content_margin_left = 14
		psb.content_margin_right = 14
		psb.content_margin_top = 10
		psb.content_margin_bottom = 10
		row.add_theme_stylebox_override("panel", psb)
		_rows.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		h.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_child(h)
		# color swatches: top / bottom / shoes
		for key in ["top", "bottom", "shoes"]:
			var sw := ColorRect.new()
			sw.color = Color.html(outfit.get(key, "#ffffff"))
			sw.custom_minimum_size = Vector2(44, 44)
			h.add_child(sw)
		var name_l := Label.new()
		name_l.text = outfit.get("name", "?")
		name_l.add_theme_font_size_override("font_size", 26)
		name_l.add_theme_color_override("font_color", Color.html("#5b2333"))
		name_l.custom_minimum_size = Vector2(230, 44)
		name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(name_l)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(10, 44)
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(spacer)
		var action := Button.new()
		action.custom_minimum_size = Vector2(190, 56)
		action.add_theme_font_size_override("font_size", 24)
		var idx: int = i
		if Save.outfit_equipped == i:
			action.text = "EQUIPPED ✓"
			action.disabled = true
		elif Save.owns_outfit(i):
			action.text = "EQUIP"
			action.pressed.connect(func() -> void:
				Save.equip_outfit(idx)
				_refresh()
			)
		else:
			action.text = "BUY  ★ %d" % int(outfit.get("cost", 0))
			action.disabled = Save.stars_total < int(outfit.get("cost", 0))
			action.pressed.connect(func() -> void:
				if Save.buy_outfit(idx):
					Music.play_sfx("win")
					_refresh()
			)
		var asb := StyleBoxFlat.new()
		asb.bg_color = Color.html("#ff5c8a") if not action.disabled else Color(0.7, 0.7, 0.7)
		asb.set_corner_radius_all(12)
		action.add_theme_stylebox_override("normal", asb)
		action.add_theme_color_override("font_color", Color.html("#ffffff"))
		h.add_child(action)
