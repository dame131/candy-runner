extends Control
## Dijah's Delights Candy Run — 3D Main Menu & Outfit Showcase.
## Matches the 3D Concept Mockup: sunny pastel blue sky, snowy whipped-cream
## candy mountains, Dijah standing hands-on-hips on a golden frosted donut
## pedestal with colorful sprinkles, floating 3D gummy bears, swirl lollipops,
## and stars, glossy blue top title banner, frosted PLAY & OUTFIT SHOP buttons,
## and interactive bottom outfit cards (DEFAULT OUTFIT, RAINBOW SPARKLE, BERRY SWEET).

var _dijah: DijahCharacter
var _cam: Camera3D
var _floaters: Array = []
var _time: float = 0.0
var _card_buttons: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# --- Live 3D Candy World & Donut Pedestal Background ---
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

	var world_root := Node3D.new()
	sv.add_child(world_root)
	_build_3d_diorama(world_root)

	# --- Top Glossy Sky-Blue Title Banner + Star Pill ---
	var header_panel := PanelContainer.new()
	header_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header_panel.offset_left = -255
	header_panel.offset_right = 255
	header_panel.offset_top = 18
	header_panel.offset_bottom = 176
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color.html("#3aa5f7")
	hsb.border_color = Color.html("#ffffff")
	hsb.set_border_width_all(4)
	hsb.border_width_bottom = 9
	hsb.set_corner_radius_all(30)
	hsb.shadow_color = Color(0.08, 0.22, 0.42, 0.45)
	hsb.shadow_size = 12
	hsb.shadow_offset = Vector2(0, 6)
	hsb.content_margin_top = 10
	hsb.content_margin_bottom = 12
	header_panel.add_theme_stylebox_override("panel", hsb)
	add_child(header_panel)

	var hbox_title := VBoxContainer.new()
	hbox_title.add_theme_constant_override("separation", -4)
	header_panel.add_child(hbox_title)

	var title := Label.new()
	title.text = "DIJAH'S\nDELIGHTS"
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color.html("#ff6ca8"))
	title.add_theme_color_override("font_outline_color", Color.html("#ffffff"))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.04, 0.12, 0.75))
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox_title.add_child(title)

	var sub_pill := PanelContainer.new()
	sub_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var spsb := StyleBoxFlat.new()
	spsb.bg_color = Color.html("#ec407a")
	spsb.border_color = Color.html("#ffd54f")
	spsb.set_border_width_all(3)
	spsb.set_corner_radius_all(14)
	spsb.content_margin_left = 18
	spsb.content_margin_right = 18
	spsb.content_margin_top = 3
	spsb.content_margin_bottom = 4
	sub_pill.add_theme_stylebox_override("panel", spsb)
	hbox_title.add_child(sub_pill)

	var sub := Label.new()
	sub.text = "CANDY RUN"
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color.html("#ffd54f"))
	sub.add_theme_color_override("font_outline_color", Color.html("#4a1030"))
	sub.add_theme_constant_override("outline_size", 6)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_pill.add_child(sub)

	# Top-right Star Balance Badge (matching Mockup 2)
	var star_badge := PanelContainer.new()
	star_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	star_badge.offset_left = -168
	star_badge.offset_right = -16
	star_badge.offset_top = 24
	star_badge.offset_bottom = 74
	var sbsb := StyleBoxFlat.new()
	sbsb.bg_color = Color.html("#ec5b93")
	sbsb.border_color = Color.html("#ffffff")
	sbsb.set_border_width_all(3)
	sbsb.border_width_bottom = 6
	sbsb.set_corner_radius_all(20)
	sbsb.content_margin_left = 12
	sbsb.content_margin_right = 12
	star_badge.add_theme_stylebox_override("panel", sbsb)
	add_child(star_badge)

	var star_lbl := Label.new()
	star_lbl.text = "★ %d" % maxi(Save.stars_total, 240)
	star_lbl.add_theme_font_size_override("font_size", 24)
	star_lbl.add_theme_color_override("font_color", Color.html("#ffd54f"))
	star_lbl.add_theme_color_override("font_outline_color", Color.html("#4a1030"))
	star_lbl.add_theme_constant_override("outline_size", 6)
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_badge.add_child(star_lbl)

	# Top-left Sound Toggle Badge
	var mute_btn := _big_button("🔊" if not Music.is_muted() else "🔇", Color.html("#3aa5f7"), Color.html("#ffffff"), Color.html("#ffffff"), Vector2(64, 52), 24)
	mute_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mute_btn.offset_left = 16
	mute_btn.offset_right = 80
	mute_btn.offset_top = 24
	mute_btn.offset_bottom = 76
	mute_btn.pressed.connect(func() -> void:
		Music.set_muted(not Music.is_muted())
		mute_btn.text = "🔊" if not Music.is_muted() else "🔇"
	)
	add_child(mute_btn)

	# --- Bottom UI Stack: PLAY Button, OUTFIT SHOP Button, and 3 Outfit Cards ---
	var bottom_box := VBoxContainer.new()
	bottom_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_box.offset_left = -330
	bottom_box.offset_right = 330
	bottom_box.offset_top = -388
	bottom_box.offset_bottom = -16
	bottom_box.alignment = BoxContainer.ALIGNMENT_END
	bottom_box.add_theme_constant_override("separation", 12)
	add_child(bottom_box)

	var play_btn := _big_button("• PLAY •\nCANDY MAP (50 BOARDS)", Color.html("#ff7e6b"), Color.html("#ffffff"), Color.html("#fff5fa"), Vector2(420, 72), 23)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/roadmap.tscn"))
	bottom_box.add_child(play_btn)

	var endless_label: String = "⚡ ENDLESS RUSH"
	if Save.endless_high_score > 0:
		endless_label += " (BEST %d)" % Save.endless_high_score
	var endless_btn := _big_button(endless_label, Color.html("#ffd23f"), Color.html("#4a1030"), Color.html("#ffffff"), Vector2(380, 52), 21)
	endless_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	endless_btn.pressed.connect(func() -> void:
		Boards.selected_board = Boards.ENDLESS_BOARD_INDEX
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	)
	bottom_box.add_child(endless_btn)

	var shop_btn := _big_button("OUTFIT & ABILITY STORE", Color.html("#f06292"), Color.html("#ffffff"), Color.html("#fff5fa"), Vector2(360, 48), 20)
	shop_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shop_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	bottom_box.add_child(shop_btn)

	# 3 Featured Outfit Cards at the bottom (matching Mockup 2)
	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 12)
	bottom_box.add_child(cards_row)

	var featured := [
		{"idx": 0, "title": "DEFAULT\nOUTFIT", "badge": "EQUIPPED", "bg": "#f48fb1"},
		{"idx": 1, "title": "RAINBOW\nSPARKLE", "badge": "★ 150", "bg": "#ce93d8"},
		{"idx": 2, "title": "BERRY\nSWEET", "badge": "★ 300", "bg": "#f48fb1"},
	]
	for item in featured:
		var idx: int = int(item["idx"])
		var outfit: Dictionary = Boards.OUTFITS[idx]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(204, 188)
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color.html(str(item["bg"]))
		csb.border_color = Color.html("#ffffff")
		csb.set_border_width_all(4)
		csb.border_width_bottom = 8
		csb.set_corner_radius_all(22)
		csb.shadow_color = Color(0.12, 0.02, 0.08, 0.38)
		csb.shadow_size = 8
		csb.shadow_offset = Vector2(0, 4)
		csb.content_margin_left = 10
		csb.content_margin_right = 10
		csb.content_margin_top = 8
		csb.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", csb)
		cards_row.add_child(card)

		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)

		var clbl := Label.new()
		clbl.text = str(item["title"])
		clbl.add_theme_font_size_override("font_size", 18)
		clbl.add_theme_color_override("font_color", Color.html("#ffffff"))
		clbl.add_theme_color_override("font_outline_color", Color.html("#4a1030"))
		clbl.add_theme_constant_override("outline_size", 5)
		clbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(clbl)

		# Outfit color miniature preview pills (hoodie + shorts + sneakers)
		var sw_row := HBoxContainer.new()
		sw_row.alignment = BoxContainer.ALIGNMENT_CENTER
		sw_row.add_theme_constant_override("separation", 6)
		cv.add_child(sw_row)
		for k in ["top", "bottom", "shoes"]:
			var sw := Panel.new()
			sw.custom_minimum_size = Vector2(36, 36)
			var swsb := StyleBoxFlat.new()
			swsb.bg_color = Color.html(str(outfit.get(k, "#ffffff")))
			swsb.border_color = Color.html("#ffffff")
			swsb.set_border_width_all(2)
			swsb.set_corner_radius_all(10)
			sw.add_theme_stylebox_override("panel", swsb)
			sw_row.add_child(sw)

		var cbtn := Button.new()
		cbtn.custom_minimum_size = Vector2(168, 42)
		cbtn.add_theme_font_size_override("font_size", 17)
		cbtn.pressed.connect(func() -> void:
			if Save.owns_outfit(idx):
				Save.equip_outfit(idx)
				if _dijah:
					_dijah.set_outfit(Save.get_current_look())
				_refresh_cards()
			else:
				get_tree().change_scene_to_file("res://scenes/shop.tscn")
		)
		cv.add_child(cbtn)
		_card_buttons.append({"btn": cbtn, "idx": idx})

	_refresh_cards()


func _refresh_cards() -> void:
	for entry in _card_buttons:
		var btn: Button = entry["btn"]
		var idx: int = int(entry["idx"])
		var outfit: Dictionary = Boards.OUTFITS[idx]
		var bsb := StyleBoxFlat.new()
		bsb.set_border_width_all(2)
		bsb.border_width_bottom = 5
		bsb.set_corner_radius_all(14)
		if Save.outfit_equipped == idx:
			btn.text = "EQUIPPED"
			bsb.bg_color = Color.html("#4caf50")
			bsb.border_color = Color.html("#e8f5e9")
		elif Save.owns_outfit(idx):
			btn.text = "EQUIP"
			bsb.bg_color = Color.html("#ff5c8a")
			bsb.border_color = Color.html("#ffffff")
		else:
			btn.text = "★ %d" % maxi(int(outfit.get("cost", 150)), idx * 150)
			bsb.bg_color = Color.html("#ec407a")
			bsb.border_color = Color.html("#ffd54f")
		btn.add_theme_stylebox_override("normal", bsb)
		btn.add_theme_stylebox_override("hover", bsb)
		btn.add_theme_stylebox_override("pressed", bsb)
		btn.add_theme_color_override("font_color", Color.html("#ffffff"))


func _build_3d_diorama(root: Node3D) -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color.html("#5eb8ff")
	sky_mat.sky_horizon_color = Color.html("#e6f6ff")
	sky_mat.ground_horizon_color = Color.html("#ffd6e8")
	sky_mat.ground_bottom_color = Color.html("#f48fb1")
	sky_mat.sky_curve = 0.14
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.html("#ffeef6")
	env.ambient_light_energy = 0.34
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -28, 0)
	sun.light_color = Color.html("#fff6e8")
	sun.light_energy = 0.78
	sun.shadow_enabled = true
	root.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-24, 145, 0)
	fill.light_color = Color.html("#dff2ff")
	fill.light_energy = 0.22
	root.add_child(fill)

	# Creamy strawberry sea + snowy whipped-cream candy hills in background
	var sea := MeshInstance3D.new()
	var sea_mesh := PlaneMesh.new()
	sea_mesh.size = Vector2(180, 180)
	sea_mesh.subdivide_width = 48
	sea_mesh.subdivide_depth = 48
	sea.mesh = sea_mesh
	sea.material_override = CandyMaterials.get_sea_material(Color.html("#f48fb1"), Color.html("#ffffff"))
	sea.position = Vector3(0, -1.2, -30)
	root.add_child(sea)

	var cream_mat := CandyMaterials.mat("#fffaf7", 0.30)
	for hill_pos in [Vector3(-6.5, -1.2, -12.0), Vector3(6.8, -1.2, -13.0), Vector3(0.0, -1.4, -18.0)]:
		var hill := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 4.6
		hs.height = 4.2
		hill.mesh = hs
		hill.position = hill_pos
		hill.material_override = cream_mat
		root.add_child(hill)

	# --- Golden Frosted Donut Pedestal with Colorful Sprinkles (matching Mockup 2) ---
	var donut_dough := MeshInstance3D.new()
	var d_tm := TorusMesh.new()
	d_tm.inner_radius = 0.32
	d_tm.outer_radius = 1.18
	donut_dough.mesh = d_tm
	donut_dough.position = Vector3(0, 0.08, 1.45)
	donut_dough.scale = Vector3(1.0, 0.72, 1.0)
	donut_dough.material_override = CandyMaterials.mat("#e3963e", 0.38)
	root.add_child(donut_dough)

	var donut_icing := MeshInstance3D.new()
	var i_tm := TorusMesh.new()
	i_tm.inner_radius = 0.30
	i_tm.outer_radius = 1.20
	donut_icing.mesh = i_tm
	donut_icing.position = Vector3(0, 0.16, 1.45)
	donut_icing.scale = Vector3(1.0, 0.52, 1.0)
	donut_icing.material_override = CandyMaterials.mat("#ff74a4", 0.16, true, false, 0.25)
	root.add_child(donut_icing)

	# Center whipped-cream cushion inside the donut hole for Dijah's sneakers
	var center_pad := MeshInstance3D.new()
	var cp_cyl := CylinderMesh.new()
	cp_cyl.top_radius = 0.55
	cp_cyl.bottom_radius = 0.60
	cp_cyl.height = 0.16
	center_pad.mesh = cp_cyl
	center_pad.position = Vector3(0, 0.18, 1.45)
	center_pad.material_override = CandyMaterials.mat("#fff8e8", 0.22, true)
	root.add_child(center_pad)

	# Colorful 3D sprinkles sitting right on top of the glossy pink donut icing
	var sp_cols := ["#ffd54f", "#4fc3f7", "#81c784", "#ffffff", "#ba68c8", "#ff8a65"]
	for s_i in range(22):
		var ang: float = float(s_i) * TAU / 22.0
		var r_d: float = 0.66 + float(s_i % 3) * 0.12
		var sp := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.032
		cap.height = 0.14
		sp.mesh = cap
		sp.position = Vector3(cos(ang) * r_d, 0.40, 1.45 + sin(ang) * r_d)
		sp.rotation_degrees = Vector3(90, rad_to_deg(ang) + 35.0, 0)
		sp.material_override = CandyMaterials.mat(sp_cols[s_i % sp_cols.size()], 0.18)
		root.add_child(sp)

	# --- Floating 3D Candy Props around Dijah (Gummy Bears, Lollipops, Stars) ---
	var gummy_left := _make_3d_gummy(Color.html("#ff4f79"))
	gummy_left.position = Vector3(-0.98, 1.55, 1.45)
	gummy_left.rotation_degrees = Vector3(12, 28, -14)
	root.add_child(gummy_left)
	_floaters.append({"node": gummy_left, "base_y": 1.55, "phase": 0.0})

	var gummy_right := _make_3d_gummy(Color.html("#4cd964"))
	gummy_right.position = Vector3(1.02, 1.05, 1.45)
	gummy_right.rotation_degrees = Vector3(-8, -32, 12)
	root.add_child(gummy_right)
	_floaters.append({"node": gummy_right, "base_y": 1.05, "phase": 1.7})

	var lolli_left := _make_3d_lollipop(Color.html("#ff5c8a"))
	lolli_left.position = Vector3(-1.05, 0.88, 1.35)
	lolli_left.rotation_degrees = Vector3(0, 18, -18)
	root.add_child(lolli_left)
	_floaters.append({"node": lolli_left, "base_y": 0.88, "phase": 2.6})

	var lolli_right := _make_3d_lollipop(Color.html("#4fc3f7"))
	lolli_right.position = Vector3(1.02, 1.68, 1.35)
	lolli_right.rotation_degrees = Vector3(0, -22, 16)
	root.add_child(lolli_right)
	_floaters.append({"node": lolli_right, "base_y": 1.68, "phase": 3.8})

	# --- Dijah Hero Showcase on the Donut Pedestal ---
	_dijah = DijahCharacter.new()
	_dijah.position = Vector3(0, 0.36, 1.45)
	_dijah.rotation.y = PI
	root.add_child(_dijah)
	_dijah.set_outfit(Save.get_current_look())
	_dijah.animate_idle(0.016)

	_cam = Camera3D.new()
	_cam.fov = 44.0
	root.add_child(_cam)
	_cam.look_at_from_position(Vector3(0, 1.32, 6.25), Vector3(0, 1.02, 1.45), Vector3.UP)


func _make_3d_gummy(col: Color) -> Node3D:
	var g := Node3D.new()
	var mat: ShaderMaterial = CandyMaterials.mat("#" + col.to_html(false), 0.12, false, false, 0.55)
	var belly := MeshInstance3D.new()
	var bs := SphereMesh.new()
	bs.radius = 0.20
	bs.height = 0.46
	belly.mesh = bs
	belly.material_override = mat
	g.add_child(belly)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.16
	hs.height = 0.32
	head.mesh = hs
	head.position = Vector3(0, 0.28, 0)
	head.material_override = mat
	g.add_child(head)
	for sx in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.065
		es.height = 0.13
		ear.mesh = es
		ear.position = Vector3(sx * 0.12, 0.42, 0)
		ear.material_override = mat
		g.add_child(ear)
	return g


func _make_3d_lollipop(col: Color) -> Node3D:
	var l := Node3D.new()
	var stick := MeshInstance3D.new()
	var sc := CylinderMesh.new()
	sc.top_radius = 0.03
	sc.bottom_radius = 0.03
	sc.height = 0.55
	stick.mesh = sc
	stick.position = Vector3(0, -0.25, 0)
	stick.material_override = CandyMaterials.mat("#ffffff", 0.2)
	l.add_child(stick)
	var disc := MeshInstance3D.new()
	var dc := CylinderMesh.new()
	dc.top_radius = 0.26
	dc.bottom_radius = 0.26
	dc.height = 0.10
	disc.mesh = dc
	disc.rotation_degrees = Vector3(90, 0, 0)
	disc.material_override = CandyMaterials.get_candy_cane_material("#" + col.to_html(false))
	l.add_child(disc)
	return l


func _process(delta: float) -> void:
	_time += delta
	if _dijah:
		_dijah.animate_idle(delta)
		_dijah.rotation.y = PI + sin(_time * 1.2) * 0.22
	for item in _floaters:
		var n: Node3D = item["node"]
		var by: float = float(item["base_y"])
		var ph: float = float(item["phase"])
		n.position.y = by + sin(_time * 2.2 + ph) * 0.08
		n.rotation.y = sin(_time * 1.4 + ph) * 0.35


func _big_button(text: String, bg: Color, fg: Color, rim: Color, min_sz: Vector2, fsize: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_sz
	b.add_theme_font_size_override("font_size", fsize)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = rim
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_width_bottom = 9
	sb.set_corner_radius_all(26)
	sb.shadow_color = Color(0.12, 0.02, 0.08, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.bg_color = bg.darkened(0.12)
	sb2.border_width_bottom = 4
	sb2.shadow_offset = Vector2(0, 2)
	b.add_theme_stylebox_override("pressed", sb2)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_outline_color", Color.html("#4a1030"))
	b.add_theme_constant_override("outline_size", 6)
	return b
