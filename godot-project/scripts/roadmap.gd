extends Control
## Dijah's Delights Candy Run — 3D-styled Roadmap map with beveled candy board nodes.

var _stars_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# --- Live 3D Candy World Map Background ---
	var svc := SubViewportContainer.new()
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)

	var sv := SubViewport.new()
	sv.size = Vector2i(720, 1280)
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)
	_build_3d_map_bg(sv)

	var header_panel := PanelContainer.new()
	header_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header_panel.offset_left = -280
	header_panel.offset_right = 280
	header_panel.offset_top = 14
	header_panel.offset_bottom = 118
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color.html("#3aa5f7")
	hsb.border_color = Color.html("#ffffff")
	hsb.set_border_width_all(4)
	hsb.border_width_bottom = 8
	hsb.set_corner_radius_all(26)
	hsb.shadow_color = Color(0.08, 0.22, 0.42, 0.40)
	hsb.shadow_size = 10
	hsb.shadow_offset = Vector2(0, 5)
	header_panel.add_theme_stylebox_override("panel", hsb)
	add_child(header_panel)

	var hbox := VBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(hbox)

	var header := Label.new()
	header.text = "CHOOSE A CANDY BOARD"
	header.add_theme_font_size_override("font_size", 34)
	header.add_theme_color_override("font_color", Color.html("#ffffff"))
	header.add_theme_color_override("font_outline_color", Color.html("#4a1030"))
	header.add_theme_constant_override("outline_size", 8)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(header)

	_stars_label = Label.new()
	_stars_label.text = "★ %d SUGAR STARS   •   %d/%d RATING ★" % [Save.stars_total, Save.total_rating_stars(), Boards.board_count() * 3]
	_stars_label.add_theme_font_size_override("font_size", 22)
	_stars_label.add_theme_color_override("font_color", Color.html("#ffd54f"))
	_stars_label.add_theme_color_override("font_outline_color", Color.html("#4a1030"))
	_stars_label.add_theme_constant_override("outline_size", 6)
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(_stars_label)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 130
	scroll.offset_bottom = -96
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var map := Control.new()
	map.custom_minimum_size = Vector2(720, 160.0 + float(Boards.board_count()) * 92.0)
	scroll.add_child(map)

	# Winding 3D shadow path + golden candy path
	var shadow_line := Line2D.new()
	shadow_line.width = 24.0
	shadow_line.default_color = Color(0.28, 0.06, 0.16, 0.45)
	shadow_line.joint_mode = Line2D.LINE_JOINT_ROUND
	shadow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for i in range(Boards.board_count()):
		shadow_line.add_point(_node_pos(i) + Vector2(0, 6))
	map.add_child(shadow_line)

	var line := Line2D.new()
	line.width = 18.0
	line.default_color = Color.html("#ffd23f")
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for i in range(Boards.board_count()):
		line.add_point(_node_pos(i))
	map.add_child(line)

	for i in range(Boards.board_count()):
		var board: Dictionary = Boards.get_board(i)
		var unlocked: bool = Save.is_unlocked(i)
		var b := Button.new()
		var best: int = Save.best_score(i)
		if unlocked:
			b.text = "%d  •  %s" % [i + 1, board.get("name", "")]
			if best > 0:
				b.text += "   %s" % Save.rating_text(i)
		else:
			b.text = "🔒  %d  •  LOCKED" % (i + 1)
		b.custom_minimum_size = Vector2(440, 68)
		b.add_theme_font_size_override("font_size", 24)
		var pal: Dictionary = board.get("palette", {})
		var accent: Color = Color.html(pal.get("rim", pal.get("accent", "#ff5c8a")))
		var sb := StyleBoxFlat.new()
		sb.bg_color = accent if unlocked else Color.html("#8e7b88")
		sb.border_color = Color.html("#ffffff") if unlocked else Color.html("#cbbdc7")
		sb.border_width_left = 3
		sb.border_width_right = 3
		sb.border_width_top = 3
		sb.border_width_bottom = 9
		sb.set_corner_radius_all(32)
		sb.shadow_color = Color(0.15, 0.03, 0.09, 0.38)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 4)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		var sb2 := sb.duplicate() as StyleBoxFlat
		sb2.bg_color = accent.darkened(0.18) if unlocked else Color(0.5, 0.5, 0.5)
		sb2.border_width_bottom = 4
		b.add_theme_stylebox_override("pressed", sb2)
		b.add_theme_stylebox_override("disabled", sb)
		b.add_theme_color_override("font_color", Color.html("#ffffff") if unlocked else Color(0.9, 0.9, 0.9))
		b.add_theme_color_override("font_outline_color", Color.html("#2a0818"))
		b.add_theme_constant_override("outline_size", 6)
		b.add_theme_color_override("font_disabled_color", Color(0.88, 0.88, 0.88))
		b.disabled = not unlocked
		var pos: Vector2 = _node_pos(i)
		b.position = Vector2(pos.x - 220, pos.y - 34)
		var idx: int = i
		b.pressed.connect(func() -> void:
			Boards.selected_board = idx
			get_tree().change_scene_to_file("res://scenes/game.tscn")
		)
		map.add_child(b)

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -320
	bar.offset_right = 320
	bar.offset_top = -88
	bar.offset_bottom = -16
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 20)
	add_child(bar)
	var back := _bar_button("← MENU", Color.html("#4a1030"), Color.html("#240616"))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	bar.add_child(back)
	var shop := _bar_button("👗 3D OUTFITS", Color.html("#ff5c8a"), Color.html("#a81d4e"))
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	bar.add_child(shop)


func _build_3d_map_bg(sv: SubViewport) -> void:
	var root := Node3D.new()
	sv.add_child(root)

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color.html("#5eb8ff")
	sky_mat.sky_horizon_color = Color.html("#e4f4ff")
	sky_mat.ground_horizon_color = Color.html("#ffd6e8")
	sky_mat.ground_bottom_color = Color.html("#f48fb1")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.html("#ffeef6")
	env.ambient_light_energy = 0.36
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -32, 0)
	sun.light_color = Color.html("#fff5e6")
	sun.light_energy = 0.80
	root.add_child(sun)

	var sea := MeshInstance3D.new()
	var sm := PlaneMesh.new()
	sm.size = Vector2(160, 160)
	sm.subdivide_width = 40
	sm.subdivide_depth = 40
	sea.mesh = sm
	sea.material_override = CandyMaterials.get_sea_material(Color.html("#f48fb1"), Color.html("#ffffff"))
	sea.position = Vector3(0, -1.5, -25)
	root.add_child(sea)

	var cream_mat := CandyMaterials.mat("#fff8f4", 0.45, false, false, 0.20)
	for pos in [Vector3(-6.0, -1.2, -10.0), Vector3(6.2, -1.2, -12.0), Vector3(-5.5, -1.2, -20.0), Vector3(5.8, -1.2, -22.0)]:
		var hill := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 3.6
		hs.height = 3.2
		hill.mesh = hs
		hill.position = pos
		hill.material_override = cream_mat
		root.add_child(hill)

	var cam := Camera3D.new()
	cam.fov = 50.0
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 3.2, 6.0), Vector3(0, 0.2, -12.0), Vector3.UP)


func _node_pos(i: int) -> Vector2:
	var y: float = 90.0 + float(i) * 92.0
	var x: float = 360.0 + sin(float(i) * 0.55) * 130.0
	return Vector2(x, y)


func _bar_button(text: String, bg: Color, rim: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 68)
	b.add_theme_font_size_override("font_size", 28)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = rim
	sb.set_border_width_all(3)
	sb.border_width_bottom = 8
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0.12, 0.02, 0.08, 0.45)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", Color.html("#ffffff"))
	return b
