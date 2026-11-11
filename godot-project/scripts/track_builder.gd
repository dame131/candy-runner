class_name TrackBuilder
extends RefCounted
## Builds endless 12m 3D track segments for Dijah's Delights Candy Run.
## Upgraded with deep 3D Belgian waffle pocket contrast, 3D cream-wafer
## side layers, bridge support pillars, studio candy shaders, and 3D drop shadows.

const SEG_LEN: float = 12.0
const LANE_X: float = 2.2
const ROWS: int = 5
const ROW_LEN: float = 2.4

const TILE_A: PackedScene = preload("res://models/tile_a.glb")
const TILE_B: PackedScene = preload("res://models/tile_b.glb")
const HOLE_TILE: PackedScene = preload("res://models/hole_tile.glb")
const RAIL_LEFT: PackedScene = preload("res://models/rail_left.glb")
const RAIL_RIGHT: PackedScene = preload("res://models/rail_right.glb")
const LOLLIPOP: PackedScene = preload("res://models/lollipop.glb")
const ICE_CREAM: PackedScene = preload("res://models/ice_cream_cone.glb")
const DONUT: PackedScene = preload("res://models/donut.glb")
const CANDY_ARCH: PackedScene = preload("res://models/candy_cane_arch.glb")
const GUMMY_BEAR: PackedScene = preload("res://models/gummy_bear.glb")
const CUPCAKE: PackedScene = preload("res://models/cupcake.glb")
const MOUNTAIN: PackedScene = preload("res://models/candy_mountain.glb")

var board: Dictionary
var rng: RandomNumberGenerator

const MIXED_POOL: Array = ["hole", "blocker", "sliding_hole", "rolling_ball", "pinwheel", "rising_block", "bouncing_bean", "gate", "honeycomb_wall", "thorn_bush", "whip", "bubble"]


func _init(p_board: Dictionary, p_rng: RandomNumberGenerator) -> void:
	board = p_board
	rng = p_rng


func _mat(color_hex: String, rough: float = 0.18, glow: bool = false, vcol: bool = false, sss: float = 0.35, bump: float = 0.0) -> ShaderMaterial:
	return CandyMaterials.mat(color_hex, rough, glow, vcol, sss, bump)


func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _sphere(parent: Node3D, pos: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, pos: Vector3, r_top: float, r_bot: float, h: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	mi.mesh = c
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## Swap every surface whose imported material name is a key of `overrides`
## with the matching palette material, and upgrade any remaining standard materials
## to glossy 3D CandyMaterials.
func _apply_overrides(node: Node, overrides: Dictionary = {}) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var m: Material = mesh.surface_get_material(i)
				if m:
					if overrides.has(m.resource_name):
						mi.set_surface_override_material(i, overrides[m.resource_name])
					elif m is StandardMaterial3D:
						var sm := m as StandardMaterial3D
						var hex := "#" + sm.albedo_color.to_html(false)
						mi.set_surface_override_material(i, _mat(hex, clampf(sm.roughness, 0.08, 0.45), sm.emission_enabled, false, 0.38))
	for c in node.get_children():
		_apply_overrides(c, overrides)


static var _beveled_waffle_mesh: ArrayMesh = null


static func _get_beveled_waffle_mesh() -> ArrayMesh:
	if _beveled_waffle_mesh != null:
		return _beveled_waffle_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Build a 2x2 grid of deep, sloped/beveled Belgian waffle pockets (total size 2.16 x 2.40)
	# Each cell is 1.08 wide x 1.20 long, with a flat golden rim at y=0.045,
	# 45-degree sloped inner bevel walls descending to y=-0.032, and a recessed toasted floor.
	var cell_w := 1.06
	var cell_l := 1.18
	var rim_w := 0.11
	var bev_w := 0.16
	var y_top := 0.046
	var y_bot := -0.034

	for gx in [-0.53, 0.53]:
		for gz in [-0.59, 0.59]:
			var x0: float = gx - cell_w * 0.5
			var x1: float = gx + cell_w * 0.5
			var z0: float = gz - cell_l * 0.5
			var z1: float = gz + cell_l * 0.5

			var ix0: float = x0 + rim_w
			var ix1: float = x1 - rim_w
			var iz0: float = z0 + rim_w
			var iz1: float = z1 - rim_w

			var bx0: float = ix0 + bev_w
			var bx1: float = ix1 - bev_w
			var bz0: float = iz0 + bev_w
			var bz1: float = iz1 - bev_w

			# 1. Top flat golden rim (4 quads around the pocket opening)
			_add_quad(st, Vector3(x0, y_top, z0), Vector3(x1, y_top, z0), Vector3(ix1, y_top, iz0), Vector3(ix0, y_top, iz0))
			_add_quad(st, Vector3(ix0, y_top, iz1), Vector3(ix1, y_top, iz1), Vector3(x1, y_top, z1), Vector3(x0, y_top, z1))
			_add_quad(st, Vector3(x0, y_top, z0), Vector3(ix0, y_top, iz0), Vector3(ix0, y_top, iz1), Vector3(x0, y_top, z1))
			_add_quad(st, Vector3(ix1, y_top, iz0), Vector3(x1, y_top, z0), Vector3(x1, y_top, z1), Vector3(ix1, y_top, iz1))

			# 2. Sloped 45-degree inner bevel walls (catch directional sun & shadow!)
			_add_quad(st, Vector3(ix0, y_top, iz0), Vector3(ix1, y_top, iz0), Vector3(bx1, y_bot, bz0), Vector3(bx0, y_bot, bz0))
			_add_quad(st, Vector3(bx0, y_bot, bz1), Vector3(bx1, y_bot, bz1), Vector3(ix1, y_top, iz1), Vector3(ix0, y_top, iz1))
			_add_quad(st, Vector3(ix0, y_top, iz0), Vector3(bx0, y_bot, bz0), Vector3(bx0, y_bot, bz1), Vector3(ix0, y_top, iz1))
			_add_quad(st, Vector3(bx1, y_bot, bz0), Vector3(ix1, y_top, iz0), Vector3(ix1, y_top, iz1), Vector3(bx1, y_bot, bz1))

			# 3. Recessed toasted waffle pocket floor
			_add_quad(st, Vector3(bx0, y_bot, bz0), Vector3(bx1, y_bot, bz0), Vector3(bx1, y_bot, bz1), Vector3(bx0, y_bot, bz1))

	st.generate_normals()
	_beveled_waffle_mesh = st.commit()
	return _beveled_waffle_mesh


static func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n: Vector3 = (b - a).cross(d - a).normalized()
	if n.y < 0.0:
		n = -n
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)

	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(c)
	st.set_normal(n)
	st.add_vertex(d)


## Construct a crisp, beveled 3D Belgian waffle tile with sloped pockets and zero clutter.
func _style_waffle_tile(tile_node: Node3D, waffle_mat: Material, _pocket_mat: Material, side_mat: Material) -> void:
	for c in tile_node.get_children():
		if c is Node3D:
			(c as Node3D).visible = false

	# 1. Golden-brown baked waffle base slab
	_box(tile_node, Vector3(0, -0.16, 0), Vector3(2.14, 0.28, 2.38), side_mat)
	# 2. Sculpted 2x2 beveled Belgian waffle pocket mesh
	var w_mi := MeshInstance3D.new()
	w_mi.mesh = _get_beveled_waffle_mesh()
	w_mi.material_override = waffle_mat
	tile_node.add_child(w_mi)


func _hide_named(node: Node, target: String) -> void:
	var found: Node = node.find_child(target)
	if found:
		found.visible = false


func _lane_x(lane: int) -> float:
	return float(lane) * LANE_X


func _row_z(row: int) -> float:
	return -(float(row) * ROW_LEN + ROW_LEN * 0.5)


func build_segment(seg_index: int, z_start: float, is_finish: bool, finish_z: float) -> Dictionary:
	var seg := Node3D.new()
	seg.position = Vector3(0, 0, z_start)
	var obstacles: Array = []
	var stars: Array = []
	var powerups: Array = []
	var pal: Dictionary = board.get("palette", {})

	var tile_col := Color.html(pal.get("tile", "#efa852"))
	var tile_dark_col := Color.html(pal.get("tile_dark", "#d98c36"))
	var pocket_col := tile_col.darkened(0.36)
	var pocket_dark_col := tile_dark_col.darkened(0.36)

	var tile_mat: ShaderMaterial = CandyMaterials.get_waffle_material(tile_col.lightened(0.08), pocket_col)
	var tile_dark_mat: ShaderMaterial = CandyMaterials.get_waffle_material(tile_dark_col.lightened(0.04), pocket_dark_col)
	var pocket_mat: ShaderMaterial = tile_mat
	var pocket_dark_mat: ShaderMaterial = tile_dark_mat
	var side_mat: ShaderMaterial = _mat(pal.get("side", "#8c4d1e"), 0.36, false, false, 0.22)
	var cone_mat: ShaderMaterial = CandyMaterials.get_waffle_material(Color.html("#d98b38"), Color.html("#824414"))
	var white_frost_mat: ShaderMaterial = _mat("#fffdf9", 0.18, false, false, 0.45)
	var foam_mat: ShaderMaterial = _mat("#ffd6e7", 0.28, false, false, 0.50)

	# --- 3D Golden Waffle Bridge Deck & Tapered Waffle-Cone Sea Pillars ---
	_box(seg, Vector3(0, -0.28, -SEG_LEN * 0.5), Vector3(7.15, 0.28, SEG_LEN + 0.08), side_mat)

	# Tapered Waffle-Cone Support Pillars plunging into the strawberry milkshake sea
	for pz in [-3.0, -9.0]:
		for sx in [-3.18, 3.18]:
			_cyl(seg, Vector3(sx, -0.78, pz), 0.44, 0.24, 1.35, cone_mat)
			# Bubbly strawberry-milkshake foam pad around the base of each waffle pillar
			var pad := _sphere(seg, Vector3(sx, -0.96, pz), 0.75, foam_mat)
			pad.scale = Vector3(1.3, 0.18, 1.3)

	# --- 3D Beveled Waffle Tiles: 3 lanes x 5 rows ---
	var tiles: Dictionary = {}
	for lane_i in [-1, 0, 1]:
		tiles[lane_i] = {}
		for row in range(ROWS):
			var even: bool = (lane_i + row) % 2 == 0
			var t: Node3D = (TILE_A if even else TILE_B).instantiate()
			t.position = Vector3(_lane_x(lane_i), 0, _row_z(row))
			seg.add_child(t)
			_style_waffle_tile(
				t,
				tile_mat if even else tile_dark_mat,
				pocket_mat if even else pocket_dark_mat,
				side_mat
			)
			tiles[lane_i][row] = t

	# --- 3D Rounded Whipped-Frosting Lane Dividers ---
	for div_x in [-1.09, 1.09]:
		var pipe := _cyl(seg, Vector3(div_x, 0.062, -SEG_LEN * 0.5), 0.072, 0.072, SEG_LEN, white_frost_mat)
		pipe.rotation.x = PI * 0.5

	# --- Thick Billowy Whipped-Frosting Outer Curbs + Striped Candy Canes ---
	_add_whipped_curb(seg, -3.42, white_frost_mat, pal.get("rim", "#e61938"))
	_add_whipped_curb(seg, 3.42, white_frost_mat, pal.get("rim", "#e61938"))

	var hole_rows: Dictionary = {}

	# --- Board obstacles ---
	if seg_index >= 2 and not is_finish:
		var ob_kind: String = board.get("obstacle", "hole")
		if ob_kind == "mixed":
			ob_kind = MIXED_POOL[rng.randi_range(0, MIXED_POOL.size() - 1)]
		var ob_lane: int = rng.randi_range(-1, 1)
		var ob_row: int = rng.randi_range(1, 3)
		_place_obstacle(seg, obstacles, tiles, hole_rows, ob_kind, ob_lane, ob_row)
		if seg_index > 6 and rng.randf() < 0.35:
			var ob2_kind: String = board.get("obstacle", "hole")
			if ob2_kind == "mixed":
				ob2_kind = MIXED_POOL[rng.randi_range(0, MIXED_POOL.size() - 1)]
			var ob2_row: int = (ob_row + 2) % ROWS
			_place_obstacle(seg, obstacles, tiles, hole_rows, ob2_kind, rng.randi_range(-1, 1), ob2_row)
		if ob_kind not in ["hole", "wide_pit", "cloud_gap", "sliding_hole"] and rng.randf() < 0.45:
			var h_row: int = rng.randi_range(0, ROWS - 1)
			if not hole_rows.has(h_row):
				_place_obstacle(seg, obstacles, tiles, hole_rows, "hole", rng.randi_range(-1, 1), h_row)

	# --- Star patterns ---
	var star_chance: float = 0.75 if board.get("objective", {}).get("type", "") == "collect_all" else 0.40
	if seg_index >= 2 and rng.randf() < star_chance and not is_finish:
		_place_star_pattern(seg, stars, hole_rows)
	# High-risk / high-reward: bonus stars parked right beside or over hazards.
	if seg_index >= 3 and not is_finish and not obstacles.is_empty():
		_place_risk_stars(seg, stars, obstacles)

	# --- Power-ups ---
	if seg_index >= 3 and seg_index % 5 == 4:
		var kinds: Array = ["speed", "shield", "magnet", "2x"]
		_add_powerup(seg, powerups, kinds[rng.randi_range(0, kinds.size() - 1)], rng.randi_range(-1, 1), rng.randi_range(0, ROWS - 1))
	if seg_index >= 4 and seg_index % 6 == 5:
		_add_powerup(seg, powerups, "sour", rng.randi_range(-1, 1), rng.randi_range(0, ROWS - 1))

	# --- 3D Scenery (matching the polished target mockup!) ---
	_add_scenery(seg)
	_add_scenery(seg)
	if rng.randf() < 0.6:
		_add_scenery(seg)
	if seg_index % 6 == 4:
		_build_waffle_viaduct(seg, side_mat, cone_mat, white_frost_mat, pal.get("rim", "#e61938"))
	elif seg_index % 4 == 2:
		_build_candy_arch(seg)
	if rng.randf() < 0.85:
		_add_sea_swirl(seg)
	if rng.randf() < 0.9:
		_add_sea_bubbles(seg)
	_add_cloud(seg)
	if rng.randf() < 0.6:
		_add_cloud(seg)
	if rng.randf() < 0.7:
		_add_far_cloud(seg)
	if rng.randf() < 0.65:
		_add_mountain(seg)
	if rng.randf() < 0.2:
		_add_mountain(seg)

	if is_finish:
		_add_finish(seg, finish_z - z_start)

	return {"node": seg, "obstacles": obstacles, "stars": stars, "powerups": powerups}


func _add_whipped_curb(seg: Node3D, x: float, frost_mat: Material, cane_hex: String) -> void:
	var cane_mat := CandyMaterials.get_candy_cane_material(cane_hex)
	# Continuous thick creamy whipped-frosting curb cylinder
	var curb := _cyl(seg, Vector3(x, 0.14, -SEG_LEN * 0.5), 0.30, 0.30, SEG_LEN + 0.2, frost_mat)
	curb.rotation.x = PI * 0.5
	# Soft billowy whipped-frosting puffs along the curb
	for i in range(8):
		var pz: float = -0.75 - float(i) * 1.5
		var puff := _sphere(seg, Vector3(x, 0.14, pz), 0.33, frost_mat)
		puff.scale = Vector3(1.05, 0.82, 1.35)
	# Diagonal red-and-white striped candy-cane rolls nestled on top of the frosting curb!
	for cz in [-1.8, -5.8, -9.8]:
		var roll := _cyl(seg, Vector3(x, 0.36, cz), 0.12, 0.12, 1.55, cane_mat)
		roll.rotation.x = PI * 0.5
		_sphere(seg, Vector3(x, 0.36, cz - 0.77), 0.12, cane_mat)
		_sphere(seg, Vector3(x, 0.36, cz + 0.77), 0.12, cane_mat)
	# Standing curved candy-cane pole rising from the strawberry sea beside the bridge
	var side_sign: float = -1.0 if x < 0.0 else 1.0
	var pole_x: float = x + side_sign * 0.85
	_cyl(seg, Vector3(pole_x, 0.55, -6.0), 0.14, 0.14, 3.2, cane_mat)
	var hook := MeshInstance3D.new()
	var h_tm := TorusMesh.new()
	h_tm.inner_radius = 0.28
	h_tm.outer_radius = 0.56
	hook.mesh = h_tm
	hook.position = Vector3(pole_x - side_sign * 0.42, 2.15, -6.0)
	hook.rotation.x = PI * 0.5
	hook.material_override = cane_mat
	seg.add_child(hook)


func _build_waffle_viaduct(seg: Node3D, side_mat: Material, cone_mat: Material, frost_mat: Material, cane_hex: String) -> void:
	# Elevated cross-bridge waffle viaduct spanning the horizon with waffle-cone pillars (like the mockup!)
	var vy := 2.45
	var vz := -6.0
	_box(seg, Vector3(0, vy, vz), Vector3(32.0, 0.34, 1.85), side_mat)
	var top_bar := _cyl(seg, Vector3(0, vy + 0.22, vz + 0.85), 0.18, 0.18, 32.0, frost_mat)
	top_bar.rotation.z = PI * 0.5
	var cane_mat := CandyMaterials.get_candy_cane_material(cane_hex)
	for cx in [-11.0, -6.0, 6.0, 11.0]:
		_cyl(seg, Vector3(cx, vy - 1.75, vz), 0.62, 0.32, 3.5, cone_mat)
		var c_roll := _cyl(seg, Vector3(cx, vy + 0.34, vz + 0.85), 0.09, 0.09, 1.4, cane_mat)
		c_roll.rotation.z = PI * 0.5


func _place_obstacle(seg: Node3D, obstacles: Array, tiles: Dictionary, hole_rows: Dictionary, kind: String, lane: int, row: int) -> void:
	var z: float = _row_z(row)
	match kind:
		"hole":
			_make_hole(seg, tiles, hole_rows, lane, row, 1)
			_add_obstacle(seg, obstacles, "hole", lane, z, {})
		"wide_pit":
			_make_hole(seg, tiles, hole_rows, lane, row, 2)
			_add_obstacle(seg, obstacles, "wide_pit", lane, z - 1.2, {})
		"cloud_gap":
			var rows: int = 2 if rng.randf() < 0.3 else 1
			_make_cloud_gap(seg, tiles, hole_rows, row, rows)
			_add_obstacle(seg, obstacles, "cloud_gap", 0, z - float(rows - 1) * 1.2, {"rows": rows})
		"sliding_hole":
			_make_sliding_hole(seg, obstacles, tiles, hole_rows, row)
		"honeycomb_wall":
			_add_obstacle(seg, obstacles, "honeycomb_wall", 0, z, {"open_lane": rng.randi_range(-1, 1)})
		"wind_gust":
			_add_obstacle(seg, obstacles, "wind_gust", 0, z, {"wind_dir": -1 if rng.randf() < 0.5 else 1})
		"gate":
			_add_obstacle(seg, obstacles, "gate", 0, z, {})
		"whip":
			_add_obstacle(seg, obstacles, "whip", 0, z, {})
		_:
			_add_obstacle(seg, obstacles, kind, lane, z, {})


func _add_obstacle(seg: Node3D, obstacles: Array, kind: String, lane: int, z: float, data: Dictionary) -> void:
	var ob := Obstacle.new()
	ob.setup(kind, board, lane, data)
	ob.position = Vector3(_lane_x(lane), 0, z)
	seg.add_child(ob)
	obstacles.append(ob)


func _hole_overrides() -> Dictionary:
	var pal: Dictionary = board.get("palette", {})
	return {
		"rim": _mat(pal.get("rim", "#ff5c8a"), 0.12, true, false, 0.45),
		"syrup": _mat(pal.get("syrup", "#7a1030"), 0.06, false, false, 0.30),
		"side": _mat(pal.get("side", "#3d2113"), 0.28, false, false, 0.20),
		"joint": _mat("#ffffff", 0.15, true, false, 0.35),
	}


func _make_hole(seg: Node3D, tiles: Dictionary, hole_rows: Dictionary, lane: int, row: int, depth: int) -> void:
	for d in range(depth):
		var r: int = row + d
		if r >= ROWS:
			break
		tiles[lane][r].visible = false
		hole_rows[r] = true
		var ht: Node3D = HOLE_TILE.instantiate()
		ht.position = Vector3(_lane_x(lane), 0, _row_z(r))
		seg.add_child(ht)
		_apply_overrides(ht, _hole_overrides())


func _make_cloud_gap(seg: Node3D, tiles: Dictionary, hole_rows: Dictionary, row: int, rows: int) -> void:
	var pal: Dictionary = board.get("palette", {})
	for d in range(rows):
		var r: int = row + d
		if r >= ROWS:
			break
		for lane_i in [-1, 0, 1]:
			tiles[lane_i][r].visible = false
		hole_rows[r] = true
	var z: float = _row_z(row) - float(rows - 1) * 1.2
	var l: float = 2.34 * float(rows)
	var rim_mat: ShaderMaterial = _mat(pal.get("rim", "#ff9ec7"), 0.12, true)
	_box(seg, Vector3(0, 0.06, z - l * 0.5 - 0.09), Vector3(6.9, 0.14, 0.20), rim_mat)
	_box(seg, Vector3(0, 0.06, z + l * 0.5 + 0.09), Vector3(6.9, 0.14, 0.20), rim_mat)
	_box(seg, Vector3(0, -0.85, z), Vector3(6.6, 0.05, l), _mat(pal.get("syrup", "#e8d5b5"), 0.06))


func _make_sliding_hole(seg: Node3D, obstacles: Array, tiles: Dictionary, hole_rows: Dictionary, row: int) -> void:
	_box(seg, Vector3(0, -0.85, _row_z(row)), Vector3(6.6, 0.05, 2.3), _mat(board.get("palette", {}).get("syrup", "#7a1030"), 0.06))
	var rim: Node3D = HOLE_TILE.instantiate()
	rim.position = Vector3(0, 0, _row_z(row))
	seg.add_child(rim)
	_apply_overrides(rim, _hole_overrides())
	_hide_named(rim, "Syrup")
	var row_tiles: Dictionary = {}
	for lane_i in [-1, 0, 1]:
		row_tiles[lane_i] = [tiles[lane_i][row]]
	hole_rows[row] = true
	var ob := Obstacle.new()
	ob.setup("sliding_hole", board, 0, {"tiles": row_tiles, "rim": rim})
	ob.position = Vector3(0, 0, _row_z(row))
	seg.add_child(ob)
	obstacles.append(ob)


func _place_star_pattern(seg: Node3D, stars: Array, hole_rows: Dictionary) -> void:
	var roll: float = rng.randf()
	if roll < 0.3 and not hole_rows.is_empty():
		var rows: Array = hole_rows.keys()
		var row: int = rows[rng.randi_range(0, rows.size() - 1)]
		var lane: int = rng.randi_range(-1, 1)
		for i in range(5):
			var t: float = float(i) / 4.0
			var y: float = 0.9 + sin(t * PI) * 1.0
			var z: float = _row_z(row) + (t - 0.5) * 4.0
			_add_star(seg, stars, _lane_x(lane), y, z)
	elif roll < 0.65:
		var lane2: int = rng.randi_range(-1, 1)
		for i in range(6):
			_add_star(seg, stars, _lane_x(lane2), 0.9, -1.0 - float(i) * 1.8)
	elif roll < 0.85:
		for i in range(6):
			var lane3: int = [-1, 0, 1, 0, -1, 1][i]
			_add_star(seg, stars, _lane_x(lane3), 0.9, -1.0 - float(i) * 1.8)
	else:
		for lane4 in [-1, 0, 1]:
			_add_star(seg, stars, _lane_x(lane4), 0.9, -6.0)


func _place_risk_stars(seg: Node3D, stars: Array, obstacles: Array) -> void:
	if rng.randf() > 0.6:
		return
	var ob: Obstacle = obstacles[rng.randi_range(0, obstacles.size() - 1)]
	var kind: String = ob.kind
	var x: float = ob.position.x
	var z: float = ob.position.z
	if kind in ["hole", "wide_pit", "sliding_hole"]:
		# Big star hovering over the pit edge: commit to the jump to grab it.
		_add_star(seg, stars, x, 1.9, z, "big")
		_add_star(seg, stars, x, 1.3, z + 1.2)
		_add_star(seg, stars, x, 1.0, z + 2.3)
	elif kind in ["cloud_gap", "wind_gust", "gate", "whip", "honeycomb_wall"]:
		var lane: int = [-1, 1][rng.randi_range(0, 1)]
		_add_star(seg, stars, _lane_x(lane), 1.2, z + 0.6, "big")
	else:
		# Solid hazard: bait stars in the hazard's own lane - grab them and dodge late.
		_add_star(seg, stars, x, 1.0, z + 2.7)
		_add_star(seg, stars, x, 1.0, z + 1.6)
		_add_star(seg, stars, x, 2.0, z, "big")


func _add_star(seg: Node3D, stars: Array, x: float, y: float, z: float, force_kind: String = "") -> void:
	var r: float = rng.randf()
	var kind: String = "normal"
	if r > 0.95:
		kind = "rainbow"
	elif r > 0.80:
		kind = "big"
	var s := Star.new()
	if force_kind != "":
		kind = force_kind
	s.setup(kind, Vector3(x, y, z))
	seg.add_child(s)
	stars.append(s)


func _add_powerup(seg: Node3D, powerups: Array, kind: String, lane: int, row: int) -> void:
	var p := PowerUp.new()
	p.setup(kind, Vector3(_lane_x(lane), 1.0, _row_z(row)))
	seg.add_child(p)
	powerups.append(p)


# --- 3D Scenery ---

func _add_scenery(seg: Node3D) -> void:
	var pick: int = rng.randi_range(0, 4)
	var side: float = -1.0 if rng.randf() < 0.5 else 1.0
	var x: float = side * rng.randf_range(7.8, 12.5)
	var z: float = rng.randf_range(-11.0, -2.5)
	# Creamy white whipped-sugar island mound under each distant prop
	var snow_mat := _mat("#fff9fc", 0.32, false, false, 0.55)
	var mound := _sphere(seg, Vector3(x, -0.95, z), rng.randf_range(2.6, 3.8), snow_mat)
	mound.scale = Vector3(1.35, 0.48, 1.25)
	match pick:
		0, 1:
			_build_lollipop(seg, x, z)
		2:
			_build_edge_bear(seg, x, z)
		3:
			_build_ice_cream(seg, x, z)
		_:
			_build_donut(seg, x, z)


func _decorate_bear_face(b: Node3D, col_hex: String) -> void:
	_apply_overrides(b, {
		"Gummy": _mat(col_hex, 0.08, false, false, 0.65),
		"Belly": _mat(col_hex, 0.12, false, false, 0.55),
	})


func _build_lollipop(seg: Node3D, x: float, z: float) -> void:
	var lol: Node3D = LOLLIPOP.instantiate()
	lol.position = Vector3(x, -0.4, z)
	lol.scale = Vector3.ONE * rng.randf_range(2.4, 3.2)
	lol.rotation.y = rng.randf_range(-0.35, 0.35)
	seg.add_child(lol)
	var cols: Array = ["#ff9a3c", "#ff6ea7", "#6ed3cf", "#b978ff"]
	_apply_overrides(lol, {
		"LolliPink": _mat(cols[rng.randi_range(0, cols.size() - 1)], 0.10, false, false, 0.48),
		"LolliWhite": _mat("#fff8ee", 0.14, false, false, 0.35),
	})


func _build_ice_cream(seg: Node3D, x: float, z: float) -> void:
	var ic: Node3D = ICE_CREAM.instantiate()
	ic.position = Vector3(x, -0.5, z)
	ic.scale = Vector3.ONE * rng.randf_range(2.3, 2.9)
	ic.rotation.y = rng.randf_range(0, TAU)
	seg.add_child(ic)
	_apply_overrides(ic, {
		"Cone": _mat("#c48842", 0.30, false, false, 0.30, 0.8),
		"ScoopPink": _mat("#ff85b3", 0.16, false, false, 0.50),
		"ScoopWhite": _mat("#fff8f2", 0.16, false, false, 0.45),
		"Cherry": _mat("#ff1e42", 0.06, true, false, 0.55),
	})


func _build_donut(seg: Node3D, x: float, z: float) -> void:
	var d: Node3D = DONUT.instantiate()
	d.position = Vector3(x, -0.5, z)
	d.scale = Vector3.ONE * rng.randf_range(2.0, 2.5)
	d.rotation = Vector3(1.15, rng.randf_range(0, TAU), 0.2)
	seg.add_child(d)
	_apply_overrides(d, {
		"Dough": _mat("#d6914c", 0.28, false, false, 0.38),
		"Frosting": _mat("#ff6ea7", 0.12, false, false, 0.50),
	})


func _build_candy_arch(seg: Node3D) -> void:
	var a: Node3D = CANDY_ARCH.instantiate()
	a.position = Vector3(0, 0, -6.0)
	seg.add_child(a)
	var pal: Dictionary = board.get("palette", {})
	_apply_overrides(a, {
		"CanePink": _mat(pal.get("rim", "#e61938"), 0.12, false, false, 0.42),
		"CaneWhite": _mat("#ffffff", 0.15, false, false, 0.35),
	})


func _build_edge_bear(seg: Node3D, x: float, z: float) -> void:
	var b: Node3D = GUMMY_BEAR.instantiate()
	b.position = Vector3(x, 0.1, z)
	b.scale = Vector3.ONE * rng.randf_range(2.2, 2.8)
	b.rotation.y = PI + rng.randf_range(-0.35, 0.35)
	seg.add_child(b)
	var cols: Array = ["#62d962", "#f07898", "#ffd23f", "#66d9e8"]
	_decorate_bear_face(b, cols[rng.randi_range(0, cols.size() - 1)])


func _build_cupcake(seg: Node3D, x: float, z: float) -> void:
	var c: Node3D = CUPCAKE.instantiate()
	c.position = Vector3(x, -1.2, z)
	c.scale = Vector3.ONE * rng.randf_range(2.3, 2.9)
	c.rotation.y = rng.randf_range(0, TAU)
	seg.add_child(c)
	_apply_overrides(c, {
		"Cup": _mat("#ff9ec7", 0.28, false, false, 0.35, 0.7),
		"Frosting": _mat("#ff5c9e", 0.12, false, false, 0.50),
		"Cherry": _mat("#ff1e42", 0.06, true, false, 0.55),
	})


func _add_sea_swirl(seg: Node3D) -> void:
	# Soft bubbly strawberry-milkshake foam rafts floating on the sea (like the mockup!)
	var foam_mat := _mat("#ffd6e8", 0.32, false, false, 0.50)
	var bubble_mat := _mat("#fff0f7", 0.18, false, false, 0.45)
	for i in range(rng.randi_range(3, 5)):
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var fx: float = side * rng.randf_range(4.2, 7.2)
		var fz: float = rng.randf_range(-11.0, -1.0)
		var pad := _sphere(seg, Vector3(fx, -0.94, fz), rng.randf_range(0.85, 1.45), foam_mat)
		pad.scale = Vector3(1.25, 0.12, 1.15)
		for b_i in range(4):
			var bx: float = fx + rng.randf_range(-0.6, 0.6)
			var bz: float = fz + rng.randf_range(-0.6, 0.6)
			_sphere(seg, Vector3(bx, -0.88, bz), rng.randf_range(0.08, 0.16), bubble_mat)


func _add_sea_bubbles(seg: Node3D) -> void:
	var pink_pearl := _mat("#ffe6f2", 0.05, true, false, 0.50)
	for i in range(rng.randi_range(8, 12)):
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var r: float = rng.randf_range(0.14, 0.32)
		_sphere(seg, Vector3(side * rng.randf_range(3.7, 5.6), -0.80, rng.randf_range(-11.0, -1.0)), r, pink_pearl)


func _add_cloud(seg: Node3D) -> void:
	var x: float = rng.randf_range(-16.0, 16.0)
	var y: float = rng.randf_range(8.0, 13.5)
	var z: float = rng.randf_range(-14.0, -4.0)
	var white := _mat("#fff8fc", 0.35, false, false, 0.55)
	var shade := _mat("#e5c8dc", 0.40, false, false, 0.45)
	var parts: Array = [
		[Vector3(x, y, z), 1.8, Vector3(1.6, 0.85, 1.0)],
		[Vector3(x + 1.8, y + 0.3, z), 1.4, Vector3(1.4, 0.85, 1.0)],
		[Vector3(x - 1.8, y + 0.2, z), 1.2, Vector3(1.3, 0.85, 1.0)],
		[Vector3(x + 0.7, y + 1.2, z), 1.1, Vector3(1.3, 0.9, 1.0)],
		[Vector3(x - 0.8, y + 1.0, z), 1.0, Vector3(1.2, 0.9, 1.0)],
		[Vector3(x + 2.6, y - 0.1, z), 0.8, Vector3(1.2, 0.85, 1.0)],
		[Vector3(x - 2.4, y - 0.2, z), 0.75, Vector3(1.2, 0.85, 1.0)],
		[Vector3(x + 0.2, y + 1.9, z), 0.8, Vector3(1.2, 0.9, 1.0)],
	]
	for p in parts:
		var c := _sphere(seg, p[0], p[1], white)
		c.scale = p[2]
	for p in [
		[Vector3(x - 1.0, y - 0.9, z), 1.0, Vector3(1.3, 0.75, 1.0)],
		[Vector3(x + 1.2, y - 1.0, z), 0.85, Vector3(1.2, 0.75, 1.0)],
	]:
		var c := _sphere(seg, p[0], p[1], shade)
		c.scale = p[2]


func _add_far_cloud(seg: Node3D) -> void:
	var x: float = rng.randf_range(-20.0, 20.0)
	var y: float = rng.randf_range(12.0, 16.0)
	var z: float = rng.randf_range(-30.0, -18.0)
	var white := _mat("#fff8fc", 0.35, false, false, 0.55)
	var shade := _mat("#e5c8dc", 0.40, false, false, 0.45)
	var parts: Array = [
		[Vector3(x, y, z), 3.5, Vector3(1.8, 0.8, 1.0)],
		[Vector3(x + 3.0, y + 0.6, z), 2.6, Vector3(1.5, 0.8, 1.0)],
		[Vector3(x - 3.0, y + 0.5, z), 2.2, Vector3(1.4, 0.8, 1.0)],
		[Vector3(x + 1.0, y + 1.3, z), 1.8, Vector3(1.3, 0.85, 1.0)],
		[Vector3(x - 1.2, y + 1.1, z), 1.6, Vector3(1.3, 0.85, 1.0)],
	]
	for p in parts:
		var c := _sphere(seg, p[0], p[1], white)
		c.scale = p[2]
	var c := _sphere(seg, Vector3(x, y - 1.1, z), 1.8, shade)
	c.scale = Vector3(1.6, 0.7, 1.0)


func _add_mountain(seg: Node3D) -> void:
	var side: float = -1.0 if rng.randf() < 0.5 else 1.0
	var x: float = side * rng.randf_range(20.0, 30.0)
	var z: float = rng.randf_range(-11.0, -1.0)
	var m: Node3D = MOUNTAIN.instantiate()
	m.position = Vector3(x, -0.9, z)
	m.scale = Vector3.ONE * rng.randf_range(1.8, 2.4)
	seg.add_child(m)
	var cols: Array = ["#a55cd6", "#ff5c9e", "#6fbf3a", "#e86a00", "#ffb38a", "#7fe0b0"]
	_apply_overrides(m, {
		"Mountain": _mat(cols[rng.randi_range(0, cols.size() - 1)], 0.25, false, false, 0.42),
		"Snow": _mat("#fff8fc", 0.14, true, false, 0.45),
	})


func _add_finish(seg: Node3D, local_z: float) -> void:
	for lane_i in [-1, 0, 1]:
		for i in range(3):
			var white: bool = (lane_i + i) % 2 == 0
			_box(seg, Vector3(_lane_x(lane_i) + (float(i) - 1.0) * 0.72, 0.04, local_z), Vector3(0.72, 0.06, 0.5), _mat("#ffffff" if white else "#24101c", 0.15, white))
	var gold_mat := _mat("#ffd23f", 0.12, true, false, 0.40)
	_cyl(seg, Vector3(-3.4, 1.4, local_z), 0.18, 0.22, 2.8, gold_mat)
	_cyl(seg, Vector3(3.4, 1.4, local_z), 0.18, 0.22, 2.8, gold_mat)
	_box(seg, Vector3(0, 2.8, local_z), Vector3(7.2, 0.55, 0.38), gold_mat)
