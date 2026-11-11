extends Control
## Dijah's Delights Candy Run — Full 3D Boutique & Ability Store.
## Features 6 modular categories:
##   1. HAIR (8 colors/styles)
##   2. TOPS (10 hoodies, varsity tops, sweaters, scrub jackets)
##   3. BOTTOMS (12 bottoms: Shorts, Full-Length Jeans, Full-Length Leggings)
##   4. SHOES (9 athletic sneakers/runners/kicks — zero high heels)
##   5. ⚡ ABILITIES (7 separate gameplay perks — equip up to 3 at once, independent of clothes)
##   6. SETS (5 signature full-outfit presets)

var _balance_label: Label
var _active_perks_label: Label
var _rows: VBoxContainer
var _preview_dijah: DijahCharacter
var _pedestal: Node3D
var _spin_angle: float = 0.0
var _current_tab: String = "bottoms"
var _tab_buttons: Dictionary = {}

const TABS: Array = [
	{"id": "hair", "label": "HAIR"},
	{"id": "tops", "label": "TOPS"},
	{"id": "bottoms", "label": "BOTTOMS"},
	{"id": "shoes", "label": "SHOES"},
	{"id": "abilities", "label": "⚡ PERKS"},
	{"id": "sets", "label": "SETS"},
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.html("#ffbfd9")
	add_child(bg)

	var title := Label.new()
	title.text = "DIJAH'S BOUTIQUE & PERKS"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color.html("#4a1030"))
	title.add_theme_color_override("font_outline_color", Color.html("#ffffff"))
	title.add_theme_constant_override("outline_size", 8)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -340
	title.offset_right = 340
	title.offset_top = 12
	title.offset_bottom = 56
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	_balance_label = Label.new()
	_balance_label.add_theme_font_size_override("font_size", 22)
	_balance_label.add_theme_color_override("font_color", Color.html("#4a1030"))
	_balance_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_balance_label.offset_left = -330
	_balance_label.offset_right = 330
	_balance_label.offset_top = 54
	_balance_label.offset_bottom = 84
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_balance_label)

	# --- Live 3D Outfit Turntable Showcase ---
	var stage_panel := PanelContainer.new()
	stage_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	stage_panel.offset_left = -330
	stage_panel.offset_right = 330
	stage_panel.offset_top = 86
	stage_panel.offset_bottom = 376
	var stage_sb := StyleBoxFlat.new()
	stage_sb.bg_color = Color.html("#3a1028")
	stage_sb.border_color = Color.html("#ff5c8a")
	stage_sb.set_border_width_all(4)
	stage_sb.border_width_bottom = 8
	stage_sb.set_corner_radius_all(22)
	stage_sb.shadow_color = Color(0.12, 0.02, 0.08, 0.35)
	stage_sb.shadow_size = 10
	stage_sb.shadow_offset = Vector2(0, 4)
	stage_panel.add_theme_stylebox_override("panel", stage_sb)
	add_child(stage_panel)

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_panel.add_child(svc)

	var sv := SubViewport.new()
	sv.size = Vector2i(640, 275)
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)
	_build_3d_stage(sv)

	# Active Equipped Perks Banner (Option A: Abilities Separate from Clothes)
	var perks_bar := PanelContainer.new()
	perks_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	perks_bar.offset_left = -330
	perks_bar.offset_right = 330
	perks_bar.offset_top = 382
	perks_bar.offset_bottom = 424
	var pbsb := StyleBoxFlat.new()
	pbsb.bg_color = Color.html("#4a1030")
	pbsb.border_color = Color.html("#ffd54f")
	pbsb.set_border_width_all(2)
	pbsb.set_corner_radius_all(14)
	pbsb.content_margin_left = 12
	pbsb.content_margin_right = 12
	perks_bar.add_theme_stylebox_override("panel", pbsb)
	add_child(perks_bar)

	_active_perks_label = Label.new()
	_active_perks_label.add_theme_font_size_override("font_size", 17)
	_active_perks_label.add_theme_color_override("font_color", Color.html("#ffd54f"))
	_active_perks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_active_perks_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	perks_bar.add_child(_active_perks_label)

	# --- 6-Category Tab Bar (HAIR | TOPS | BOTTOMS | SHOES | ⚡ PERKS | SETS) ---
	var tab_row := HBoxContainer.new()
	tab_row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tab_row.offset_left = -340
	tab_row.offset_right = 340
	tab_row.offset_top = 432
	tab_row.offset_bottom = 484
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 6)
	add_child(tab_row)

	for t in TABS:
		var tid: String = str(t["id"])
		var btn := Button.new()
		btn.text = str(t["label"])
		btn.custom_minimum_size = Vector2(106, 48)
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(func() -> void:
			_current_tab = tid
			_refresh()
		)
		tab_row.add_child(btn)
		_tab_buttons[tid] = btn

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 18
	scroll.offset_right = -18
	scroll.offset_top = 492
	scroll.offset_bottom = -92
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	scroll.add_child(_rows)

	var back := Button.new()
	back.text = "← BACK TO MAP"
	back.custom_minimum_size = Vector2(320, 64)
	back.add_theme_font_size_override("font_size", 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.html("#4a1030")
	sb.border_color = Color.html("#ff5c8a")
	sb.set_border_width_all(3)
	sb.border_width_bottom = 7
	sb.set_corner_radius_all(18)
	back.add_theme_stylebox_override("normal", sb)
	back.add_theme_color_override("font_color", Color.html("#ffffff"))
	back.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	back.offset_left = -160
	back.offset_right = 160
	back.offset_top = -80
	back.offset_bottom = -16
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/roadmap.tscn"))
	add_child(back)

	_refresh()


func _build_3d_stage(sv: SubViewport) -> void:
	var root := Node3D.new()
	sv.add_child(root)

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color.html("#7ec8ff")
	sky_mat.sky_horizon_color = Color.html("#ffd6ec")
	sky_mat.ground_horizon_color = Color.html("#ffb3d9")
	sky_mat.ground_bottom_color = Color.html("#d46a9e")
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

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -30, 0)
	key.light_color = Color.html("#fff5e6")
	key.light_energy = 0.78
	key.shadow_enabled = true
	root.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 145, 0)
	fill.light_color = Color.html("#d4f0ff")
	fill.light_energy = 0.22
	root.add_child(fill)

	var stage_floor := MeshInstance3D.new()
	var floor_cyl := CylinderMesh.new()
	floor_cyl.top_radius = 6.5
	floor_cyl.bottom_radius = 6.5
	floor_cyl.height = 0.1
	stage_floor.mesh = floor_cyl
	stage_floor.position = Vector3(0, -0.26, -1.0)
	stage_floor.material_override = CandyMaterials.mat("#c74878", 0.68, false, false, 0.08)
	root.add_child(stage_floor)

	_pedestal = Node3D.new()
	root.add_child(_pedestal)

	var donut_dough := MeshInstance3D.new()
	var d_tm := TorusMesh.new()
	d_tm.inner_radius = 0.30
	d_tm.outer_radius = 1.12
	donut_dough.mesh = d_tm
	donut_dough.position = Vector3(0, -0.08, 0)
	donut_dough.scale = Vector3(1.0, 0.72, 1.0)
	donut_dough.material_override = CandyMaterials.mat("#e3963e", 0.38)
	_pedestal.add_child(donut_dough)

	var donut_icing := MeshInstance3D.new()
	var i_tm := TorusMesh.new()
	i_tm.inner_radius = 0.28
	i_tm.outer_radius = 1.14
	donut_icing.mesh = i_tm
	donut_icing.position = Vector3(0, 0.0, 0)
	donut_icing.scale = Vector3(1.0, 0.52, 1.0)
	donut_icing.material_override = CandyMaterials.mat("#ff74a4", 0.16, true, false, 0.25)
	_pedestal.add_child(donut_icing)

	var center_pad := MeshInstance3D.new()
	var cp_cyl := CylinderMesh.new()
	cp_cyl.top_radius = 0.52
	cp_cyl.bottom_radius = 0.58
	cp_cyl.height = 0.14
	center_pad.mesh = cp_cyl
	center_pad.position = Vector3(0, 0.02, 0)
	center_pad.material_override = CandyMaterials.mat("#fff8e8", 0.22, true)
	_pedestal.add_child(center_pad)

	var sp_cols := ["#ffd54f", "#4fc3f7", "#81c784", "#ffffff", "#ba68c8", "#ff8a65"]
	for s_i in range(18):
		var ang: float = float(s_i) * TAU / 18.0
		var r_d: float = 0.64 + float(s_i % 3) * 0.10
		var sp := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.030
		cap.height = 0.13
		sp.mesh = cap
		sp.position = Vector3(cos(ang) * r_d, 0.23, sin(ang) * r_d)
		sp.rotation_degrees = Vector3(90, rad_to_deg(ang) + 35.0, 0)
		sp.material_override = CandyMaterials.mat(sp_cols[s_i % sp_cols.size()], 0.18)
		_pedestal.add_child(sp)

	_preview_dijah = DijahCharacter.new()
	_preview_dijah.position = Vector3(0, 0.20, 0)
	_preview_dijah.rotation.y = PI
	_pedestal.add_child(_preview_dijah)
	_preview_dijah.set_outfit(Save.get_current_look())
	_preview_dijah.animate_idle(0.016)

	var cam := Camera3D.new()
	cam.fov = 42.0
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.25, 3.65), Vector3(0, 0.98, 0), Vector3.UP)


func _process(delta: float) -> void:
	_spin_angle += delta * 1.35
	if _pedestal:
		_pedestal.rotation.y = sin(_spin_angle) * 0.65
	if _preview_dijah:
		_preview_dijah.animate_idle(delta)


func _refresh() -> void:
	_balance_label.text = "★ %d Sugar Stars   |   Mix & Match Clothes + Equip up to 3 Perks" % Save.stars_total
	if _preview_dijah:
		_preview_dijah.set_outfit(Save.get_current_look())

	# Update active perks summary
	var perk_names: Array = []
	for ab in Boards.ABILITY_ITEMS:
		var aid: String = str(ab.get("id", ""))
		if Save.has_ability(aid):
			perk_names.append("%s %s" % [str(ab.get("icon", "⚡")), str(ab.get("name", ""))])
	if perk_names.is_empty():
		_active_perks_label.text = "⚡ Active Perks (0/%d): None equipped — visit ⚡ PERKS tab!" % Save.MAX_EQUIPPED_ABILITIES
	else:
		_active_perks_label.text = "⚡ Active Perks (%d/%d):  %s" % [
			perk_names.size(),
			Save.MAX_EQUIPPED_ABILITIES,
			"   •   ".join(perk_names),
		]

	# Style tab buttons
	for tid in _tab_buttons.keys():
		var b: Button = _tab_buttons[tid]
		var active: bool = (tid == _current_tab)
		var tsb := StyleBoxFlat.new()
		tsb.bg_color = Color.html("#ff4081") if active else Color.html("#6a1b4d")
		tsb.border_color = Color.html("#ffd54f") if active else Color.html("#ff80ab")
		tsb.set_border_width_all(2)
		tsb.border_width_bottom = 5 if active else 3
		tsb.set_corner_radius_all(14)
		b.add_theme_stylebox_override("normal", tsb)
		b.add_theme_stylebox_override("hover", tsb)
		b.add_theme_stylebox_override("pressed", tsb)
		b.add_theme_color_override("font_color", Color.html("#ffffff"))

	for child in _rows.get_children():
		child.queue_free()

	match _current_tab:
		"hair":
			_populate_wardrobe_category("hair", Boards.HAIR_ITEMS)
		"tops":
			_populate_wardrobe_category("top", Boards.TOP_ITEMS)
		"bottoms":
			_populate_wardrobe_category("bottom", Boards.BOTTOM_ITEMS)
		"shoes":
			_populate_wardrobe_category("shoes", Boards.SHOE_ITEMS)
		"abilities":
			_populate_abilities()
		"sets":
			_populate_preset_sets()


func _populate_wardrobe_category(category: String, items: Array) -> void:
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var is_eq: bool = Save.is_item_equipped(category, i)
		var is_own: bool = Save.owns_item(category, i)
		var cost: int = int(item.get("cost", 0))

		var row := _make_card_container(is_eq)
		_rows.add_child(row)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)

		# Color Swatch
		var sw := Panel.new()
		var sw_sb := StyleBoxFlat.new()
		sw_sb.bg_color = Color.html(str(item.get("color", "#ffffff")))
		sw_sb.border_color = Color.html("#4a1030")
		sw_sb.set_border_width_all(2)
		sw_sb.border_width_bottom = 4
		sw_sb.set_corner_radius_all(12)
		sw.add_theme_stylebox_override("panel", sw_sb)
		sw.custom_minimum_size = Vector2(54, 54)
		h.add_child(sw)

		# Item Title & Type Subtitle
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(vbox)

		var name_l := Label.new()
		name_l.text = str(item.get("name", "?"))
		name_l.add_theme_font_size_override("font_size", 22)
		name_l.add_theme_color_override("font_color", Color.html("#4a1030"))
		vbox.add_child(name_l)

		var sub_text: String = str(item.get("style", category.capitalize()))
		if category == "bottom":
			var btype: String = str(item.get("style", "shorts")).to_upper()
			sub_text = "%s  •  %s" % [btype, str(item.get("label", ""))]
		var sub_l := Label.new()
		sub_l.text = sub_text
		sub_l.add_theme_font_size_override("font_size", 15)
		sub_l.add_theme_color_override("font_color", Color.html("#8c2d5c"))
		vbox.add_child(sub_l)

		var idx: int = i
		var cat: String = category
		var action := _make_action_button(is_eq, is_own, cost, "EQUIPPED ✓", "WEAR")
		action.pressed.connect(func() -> void:
			if Save.buy_or_equip_item(cat, idx):
				Music.play_sfx("win")
				_refresh()
		)
		h.add_child(action)


func _populate_abilities() -> void:
	for i in range(Boards.ABILITY_ITEMS.size()):
		var ab: Dictionary = Boards.ABILITY_ITEMS[i]
		var aid: String = str(ab.get("id", ""))
		var is_eq: bool = Save.has_ability(aid)
		var is_own: bool = Save.owns_ability(aid)
		var cost: int = int(ab.get("cost", 0))

		var row := _make_card_container(is_eq)
		_rows.add_child(row)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)

		# Ability Icon Badge
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(56, 56)
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color.html("#4a1030") if not is_eq else Color.html("#ff4081")
		bsb.border_color = Color.html("#ffd54f")
		bsb.set_border_width_all(2)
		bsb.set_corner_radius_all(14)
		badge.add_theme_stylebox_override("panel", bsb)
		h.add_child(badge)

		var icon_l := Label.new()
		icon_l.text = str(ab.get("icon", "⚡"))
		icon_l.add_theme_font_size_override("font_size", 28)
		icon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(icon_l)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(vbox)

		var name_l := Label.new()
		name_l.text = str(ab.get("name", "?"))
		name_l.add_theme_font_size_override("font_size", 21)
		name_l.add_theme_color_override("font_color", Color.html("#4a1030"))
		vbox.add_child(name_l)

		var desc_l := Label.new()
		desc_l.text = str(ab.get("desc", ""))
		desc_l.add_theme_font_size_override("font_size", 15)
		desc_l.add_theme_color_override("font_color", Color.html("#7a2048"))
		desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_l)

		var action := _make_action_button(is_eq, is_own, cost, "ACTIVE ✓", "EQUIP")
		# Allow toggling off an active ability
		if is_eq:
			action.disabled = false
			action.text = "ACTIVE ✓"
		var ab_idx: int = i
		action.pressed.connect(func() -> void:
			if Save.buy_or_toggle_ability(ab_idx):
				Music.play_sfx("win")
				_refresh()
		)
		h.add_child(action)


func _populate_preset_sets() -> void:
	for i in range(Boards.OUTFITS.size()):
		var outfit: Dictionary = Boards.OUTFITS[i]
		var is_eq: bool = (Save.outfit_equipped == i)
		var is_own: bool = Save.owns_outfit(i)
		var cost: int = int(outfit.get("cost", 0))

		var row := _make_card_container(is_eq)
		_rows.add_child(row)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)

		for key in ["hair", "top", "bottom", "shoes"]:
			var sw := Panel.new()
			var sw_sb := StyleBoxFlat.new()
			sw_sb.bg_color = Color.html(str(outfit.get(key, "#ffffff")))
			sw_sb.border_color = Color.html("#4a1030")
			sw_sb.set_border_width_all(2)
			sw_sb.border_width_bottom = 4
			sw_sb.set_corner_radius_all(10)
			sw.add_theme_stylebox_override("panel", sw_sb)
			sw.custom_minimum_size = Vector2(38, 38)
			h.add_child(sw)

		var name_l := Label.new()
		name_l.text = str(outfit.get("name", "?"))
		name_l.add_theme_font_size_override("font_size", 22)
		name_l.add_theme_color_override("font_color", Color.html("#4a1030"))
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(name_l)

		var idx: int = i
		var action := _make_action_button(is_eq, is_own, cost, "EQUIPPED ✓", "WEAR SET")
		action.pressed.connect(func() -> void:
			if is_own:
				Save.equip_outfit(idx)
				_refresh()
			elif Save.buy_outfit(idx):
				Music.play_sfx("win")
				_refresh()
		)
		h.add_child(action)


func _make_card_container(highlighted: bool) -> PanelContainer:
	var row := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color.html("#fff8fc")
	psb.border_color = Color.html("#ff4081") if highlighted else Color.html("#e0a8c4")
	psb.set_border_width_all(3)
	psb.border_width_bottom = 6
	psb.set_corner_radius_all(18)
	psb.content_margin_left = 14
	psb.content_margin_right = 14
	psb.content_margin_top = 10
	psb.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", psb)
	return row


func _make_action_button(is_eq: bool, is_own: bool, cost: int, eq_label: String, own_label: String) -> Button:
	var action := Button.new()
	action.custom_minimum_size = Vector2(176, 52)
	action.add_theme_font_size_override("font_size", 20)
	if is_eq:
		action.text = eq_label
		action.disabled = true
	elif is_own:
		action.text = own_label
	else:
		action.text = "BUY ★ %d" % cost
		action.disabled = Save.stars_total < cost
	var asb := StyleBoxFlat.new()
	if is_eq:
		asb.bg_color = Color.html("#2e7d32")
		asb.border_color = Color.html("#a5d6a7")
	elif not action.disabled:
		asb.bg_color = Color.html("#ff5c8a")
		asb.border_color = Color.html("#a81d4e")
	else:
		asb.bg_color = Color(0.65, 0.60, 0.63)
		asb.border_color = Color(0.45, 0.42, 0.44)
	asb.set_border_width_all(2)
	asb.border_width_bottom = 5
	asb.set_corner_radius_all(14)
	action.add_theme_stylebox_override("normal", asb)
	action.add_theme_stylebox_override("hover", asb)
	action.add_theme_stylebox_override("pressed", asb)
	action.add_theme_stylebox_override("disabled", asb)
	action.add_theme_color_override("font_color", Color.html("#ffffff"))
	action.add_theme_color_override("font_disabled_color", Color.html("#ffffff"))
	return action
