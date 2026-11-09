class_name TrackBuilder
extends RefCounted
## Builds endless 12m track segments for Dijah's Delights Candy Run.
## All visuals are real Blender models (.glb): waffle tiles with sprinkles,
## pink/mint rails, rimmed holes, swirl lollipops, donuts, candy-cane
## arches, gummy bears, ice-cream cones, cupcakes, candy mountains.
## Per-board palettes are applied by imported material name
## ("tile", "tile_dark", "side", "rim", "syrup", "rail", "joint").

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
var _mats: Dictionary = {}

const MIXED_POOL: Array = ["hole", "blocker", "sliding_hole", "rolling_ball", "pinwheel", "rising_block", "bouncing_bean", "gate", "honeycomb_wall", "thorn_bush", "whip", "bubble"]


func _init(p_board: Dictionary, p_rng: RandomNumberGenerator) -> void:
	board = p_board
	rng = p_rng


func _mat(color_hex: String, rough: float = 0.2, glow: bool = false) -> StandardMaterial3D:
	var key: String = color_hex + str(rough) + str(glow)
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html(color_hex)
	m.roughness = rough
	if glow:
		m.emission_enabled = true
		m.emission = Color.html(color_hex)
		m.emission_energy_multiplier = 0.9
	_mats[key] = m
	return m


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
## with the matching palette material. Works on any .glb instance.
func _apply_overrides(node: Node, overrides: Dictionary) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var m: Material = mesh.surface_get_material(i)
				if m and overrides.has(m.resource_name):
					mi.set_surface_override_material(i, overrides[m.resource_name])
	for c in node.get_children():
		_apply_overrides(c, overrides)


## Hide one named mesh inside a .glb instance (e.g. the syrup plane of a
## sliding hole tile, where the segment provides its own syrup).
func _hide_named(node: Node, target: String) -> void:
	var found: Node = node.find_child(target)
	if found:
		found.visible = false


func _lane_x(lane: int) -> float:
	return float(lane) * LANE_X


func _row_z(row: int) -> float:
	return -(float(row) * ROW_LEN + ROW_LEN * 0.5)


## Build one segment. z_start is the segment's near edge (largest z).
## Returns {"node": seg, "obstacles": [...], "stars": [...], "powerups": [...]}.
func build_segment(seg_index: int, z_start: float, is_finish: bool, finish_z: float) -> Dictionary:
	var seg := Node3D.new()
	seg.position = Vector3(0, 0, z_start)
	var obstacles: Array = []
	var stars: Array = []
	var powerups: Array = []
	var pal: Dictionary = board.get("palette", {})
	var tile_mat: StandardMaterial3D = _mat(pal.get("tile", "#e0aa6e"), 0.22)
	var tile_dark_mat: StandardMaterial3D = _mat(pal.get("tile_dark", "#cf9557"), 0.22)
	var side_mat: StandardMaterial3D = _mat(pal.get("side", "#3d2113"), 0.35)

	# --- base slab (dark chocolate, shows through the tile gaps) ---
	_box(seg, Vector3(0, -0.38, -SEG_LEN * 0.5), Vector3(7.0, 0.35, SEG_LEN + 0.1), side_mat)

	# --- waffle tiles: 3 lanes x 5 rows, Blender models, checkerboard ---
	var tiles: Dictionary = {}
	for lane_i in [-1, 0, 1]:
		tiles[lane_i] = {}
		for row in range(ROWS):
			var even: bool = (lane_i + row) % 2 == 0
			var t: Node3D = (TILE_A if even else TILE_B).instantiate()
			t.position = Vector3(_lane_x(lane_i), 0, _row_z(row))
			seg.add_child(t)
			_apply_overrides(t, {"tile": tile_mat if even else tile_dark_mat, "side": side_mat})
			tiles[lane_i][row] = t

	# --- rails: pink left, mint right (per board palette) ---
	_add_rail(seg, -3.55, RAIL_LEFT, pal.get("rail_left", "#ff5c8a"), "#ffffff")
	_add_rail(seg, 3.55, RAIL_RIGHT, pal.get("rail_right", "#5fe3c0"), pal.get("rail_left", "#ff5c8a"))

	var hole_rows: Dictionary = {}  # lane -> Array of rows with holes

	# --- board obstacle (none on the first two segments: safe start) ---
	if seg_index >= 2 and not is_finish:
		var ob_kind: String = board.get("obstacle", "hole")
		if ob_kind == "mixed":
			ob_kind = MIXED_POOL[rng.randi_range(0, MIXED_POOL.size() - 1)]
		var ob_lane: int = rng.randi_range(-1, 1)
		var ob_row: int = rng.randi_range(1, 3)
		_place_obstacle(seg, obstacles, tiles, hole_rows, ob_kind, ob_lane, ob_row)
		# Second hazard on some later segments (different row, keeps a lane open).
		if seg_index > 6 and rng.randf() < 0.35:
			var ob2_kind: String = board.get("obstacle", "hole")
			if ob2_kind == "mixed":
				ob2_kind = MIXED_POOL[rng.randi_range(0, MIXED_POOL.size() - 1)]
			var ob2_row: int = (ob_row + 2) % ROWS
			_place_obstacle(seg, obstacles, tiles, hole_rows, ob2_kind, rng.randi_range(-1, 1), ob2_row)
		# Sprinkle plain holes on boards whose obstacle is not a hole, so
		# jump/near-miss objectives stay possible (never blocking all lanes).
		if ob_kind not in ["hole", "wide_pit", "cloud_gap", "sliding_hole"] and rng.randf() < 0.45:
			var h_row: int = rng.randi_range(0, ROWS - 1)
			if not hole_rows.has(h_row):
				_place_obstacle(seg, obstacles, tiles, hole_rows, "hole", rng.randi_range(-1, 1), h_row)

	# --- star patterns (organized, a little challenging) ---
	# Balance: no stars on the first two segments (safe start, same as
	# obstacles) and a lower spawn chance, so a "collect 10 stars" board
	# takes a real run instead of ending in the first seconds.
	var star_chance: float = 0.75 if board.get("objective", {}).get("type", "") == "collect_all" else 0.40
	if seg_index >= 2 and rng.randf() < star_chance and not is_finish:
		_place_star_pattern(seg, stars, hole_rows)

	# --- power-up every 5th segment, Sour Star every 6th ---
	if seg_index >= 3 and seg_index % 5 == 4:
		var kinds: Array = ["speed", "shield", "magnet", "2x"]
		_add_powerup(seg, powerups, kinds[rng.randi_range(0, kinds.size() - 1)], rng.randi_range(-1, 1), rng.randi_range(0, ROWS - 1))
	if seg_index >= 4 and seg_index % 6 == 5:
		_add_powerup(seg, powerups, "sour", rng.randi_range(-1, 1), rng.randi_range(0, ROWS - 1))

	# --- scenery: line BOTH track edges like the mockups — at least one
	# prop per side per segment, edge gummy bears, arch every 3rd segment.
	_add_scenery(seg)
	_add_scenery(seg)
	if rng.randf() < 0.6:
		_add_scenery(seg)
	_add_edge_bears(seg)
	if seg_index % 3 == 2:
		_build_candy_arch(seg)
	if rng.randf() < 0.85:
		_add_sea_swirl(seg)
	if rng.randf() < 0.35:
		_add_cloud(seg)
	if rng.randf() < 0.3:
		_add_mountain(seg)

	# --- finish arch ---
	if is_finish:
		_add_finish(seg, finish_z - z_start)

	return {"node": seg, "obstacles": obstacles, "stars": stars, "powerups": powerups}


func _add_rail(seg: Node3D, x: float, scene: PackedScene, rail_hex: String, joint_hex: String) -> void:
	var rail: Node3D = scene.instantiate()
	rail.position = Vector3(x, 0, -SEG_LEN * 0.5)
	seg.add_child(rail)
	_apply_overrides(rail, {"rail": _mat(rail_hex, 0.15), "joint": _mat(joint_hex, 0.25)})


func _place_obstacle(seg: Node3D, obstacles: Array, tiles: Dictionary, hole_rows: Dictionary, kind: String, lane: int, row: int) -> void:
	var pal: Dictionary = board.get("palette", {})
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
		"rim": _mat(pal.get("rim", "#ff5c8a"), 0.15, true),
		"syrup": _mat(pal.get("syrup", "#7a1030"), 0.08),
		"side": _mat(pal.get("side", "#3d2113"), 0.35),
		"joint": _mat("#ffffff", 0.25),
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
	var rim_mat: StandardMaterial3D = _mat(pal.get("rim", "#ff9ec7"), 0.15, true)
	_box(seg, Vector3(0, 0.06, z - l * 0.5 - 0.09), Vector3(6.9, 0.12, 0.18), rim_mat)
	_box(seg, Vector3(0, 0.06, z + l * 0.5 + 0.09), Vector3(6.9, 0.12, 0.18), rim_mat)
	_box(seg, Vector3(0, -0.85, z), Vector3(6.6, 0.05, l), _mat(pal.get("syrup", "#e8d5b5"), 0.08))


func _make_sliding_hole(seg: Node3D, obstacles: Array, tiles: Dictionary, hole_rows: Dictionary, row: int) -> void:
	# syrup under the whole row (the hole can slide to any lane)
	_box(seg, Vector3(0, -0.85, _row_z(row)), Vector3(6.6, 0.05, 2.3), _mat(board.get("palette", {}).get("syrup", "#7a1030"), 0.08))
	# rim that slides with the hole: Blender hole tile, syrup hidden
	# (the segment's full-row syrup box provides it instead).
	var rim: Node3D = HOLE_TILE.instantiate()
	rim.position = Vector3(0, 0, _row_z(row))
	seg.add_child(rim)
	_apply_overrides(rim, _hole_overrides())
	_hide_named(rim, "Syrup")
	# tile refs per lane for this row
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
		# arc of stars over a hole row
		var rows: Array = hole_rows.keys()
		var row: int = rows[rng.randi_range(0, rows.size() - 1)]
		var lane: int = rng.randi_range(-1, 1)
		for i in range(5):
			var t: float = float(i) / 4.0
			var y: float = 0.9 + sin(t * PI) * 1.0
			var z: float = _row_z(row) + (t - 0.5) * 4.0
			_add_star(seg, stars, _lane_x(lane), y, z)
	elif roll < 0.65:
		# trail threading down one lane
		var lane2: int = rng.randi_range(-1, 1)
		for i in range(6):
			_add_star(seg, stars, _lane_x(lane2), 0.9, -1.0 - float(i) * 1.8)
	elif roll < 0.85:
		# zigzag across lanes
		for i in range(6):
			var lane3: int = [-1, 0, 1, 0, -1, 1][i]
			_add_star(seg, stars, _lane_x(lane3), 0.9, -1.0 - float(i) * 1.8)
	else:
		# wall: one star per lane at the same z
		for lane4 in [-1, 0, 1]:
			_add_star(seg, stars, _lane_x(lane4), 0.9, -6.0)


func _add_star(seg: Node3D, stars: Array, x: float, y: float, z: float) -> void:
	var r: float = rng.randf()
	var kind: String = "normal"
	if r > 0.95:
		kind = "rainbow"
	elif r > 0.80:
		kind = "big"
	var s := Star.new()
	s.setup(kind, Vector3(x, y, z))
	seg.add_child(s)
	stars.append(s)


func _add_powerup(seg: Node3D, powerups: Array, kind: String, lane: int, row: int) -> void:
	var p := PowerUp.new()
	p.setup(kind, Vector3(_lane_x(lane), 1.0, _row_z(row)))
	seg.add_child(p)
	powerups.append(p)


# --- scenery (Blender models, big like the target image) ---

func _add_scenery(seg: Node3D) -> void:
	var pick: int = rng.randi_range(0, 5)
	var side: float = -1.0 if rng.randf() < 0.5 else 1.0
	# Closer to the track and bigger than before, like the mockups.
	var x: float = side * rng.randf_range(4.0, 6.0)
	var z: float = rng.randf_range(-11.0, -1.0)
	match pick:
		0:
			_build_lollipop(seg, x, z)
		1:
			_build_ice_cream(seg, x, z)
		2:
			_build_donut(seg, x, z)
		3:
			_build_candy_arch(seg)
		4:
			_build_edge_bear(seg, x, z)
		_:
			_build_cupcake(seg, x, z)


func _add_edge_bears(seg: Node3D) -> void:
	# Gummy bears standing ON the track edges, like the mockups — one per
	# side most segments, so the edges are never bare.
	for side in [-1.0, 1.0]:
		if rng.randf() < 0.7:
			_build_edge_bear(seg, side * 2.9, rng.randf_range(-11.0, -1.0))


func _build_lollipop(seg: Node3D, x: float, z: float) -> void:
	var lol: Node3D = LOLLIPOP.instantiate()
	# Base on the sea (y=-2.5) so it rises from the syrup like the mockups
	# instead of looming over the camera at track level.
	lol.position = Vector3(x, -2.5, z)
	lol.scale = Vector3.ONE * rng.randf_range(2.2, 2.8)
	lol.rotation.y = rng.randf_range(-0.4, 0.4)
	seg.add_child(lol)
	var cols: Array = ["#ff5c8a", "#5fe3c0", "#ff8a00"]
	_apply_overrides(lol, {"LolliPink": _mat(cols[rng.randi_range(0, cols.size() - 1)], 0.15)})


func _build_ice_cream(seg: Node3D, x: float, z: float) -> void:
	var ic: Node3D = ICE_CREAM.instantiate()
	ic.position = Vector3(x, -2.5, z)
	ic.scale = Vector3.ONE * rng.randf_range(2.2, 2.8)
	ic.rotation.y = rng.randf_range(0, TAU)
	seg.add_child(ic)


func _build_donut(seg: Node3D, x: float, z: float) -> void:
	var d: Node3D = DONUT.instantiate()
	# further out and stood up facing the camera, like the target image
	var far_x: float = (7.5 if x > 0 else -7.5) + (1.0 if x > 0 else -1.0) * rng.randf_range(0.0, 1.5)
	d.position = Vector3(far_x, -0.9, z)
	d.scale = Vector3.ONE * rng.randf_range(2.0, 2.6)
	d.rotation = Vector3(1.15, rng.randf_range(0, TAU), 0.2)
	seg.add_child(d)


func _build_candy_arch(seg: Node3D) -> void:
	var a: Node3D = CANDY_ARCH.instantiate()
	a.position = Vector3(0, 0, -6.0)
	seg.add_child(a)


func _build_edge_bear(seg: Node3D, x: float, z: float) -> void:
	var b: Node3D = GUMMY_BEAR.instantiate()
	# on the track edge, just inside the rail, like the target image
	var edge_x: float = (2.9 if x > 0 else -2.9)
	b.position = Vector3(edge_x, 0, z)
	b.scale = Vector3.ONE * rng.randf_range(0.8, 1.0)
	b.rotation.y = rng.randf_range(0, TAU)
	seg.add_child(b)
	var cols: Array = ["#7ed957", "#ff8a00", "#ffd23f", "#ff5c8a"]
	_apply_overrides(b, {"Gummy": _mat(cols[rng.randi_range(0, cols.size() - 1)], 0.12)})


func _build_cupcake(seg: Node3D, x: float, z: float) -> void:
	var c: Node3D = CUPCAKE.instantiate()
	c.position = Vector3(x, -2.5, z)
	c.scale = Vector3.ONE * rng.randf_range(2.2, 2.8)
	c.rotation.y = rng.randf_range(0, TAU)
	seg.add_child(c)


func _add_sea_swirl(seg: Node3D) -> void:
	# white foam streaks on the syrup sea beside the track
	var white := _mat("#ffffff", 0.1)
	for i in range(rng.randi_range(3, 5)):
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = rng.randf_range(1.0, 1.8)
		tm.outer_radius = tm.inner_radius + 0.3
		tm.rings = 24
		tm.ring_segments = 8
		ring.mesh = tm
		ring.rotation.x = PI * 0.5
		ring.scale = Vector3(1.6, 1.0, 1.0)
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		ring.position = Vector3(side * rng.randf_range(6.0, 14.0), -2.3, rng.randf_range(-11.0, -1.0))
		ring.material_override = white
		seg.add_child(ring)


func _add_cloud(seg: Node3D) -> void:
	var x: float = rng.randf_range(-12.0, 12.0)
	var y: float = rng.randf_range(6.0, 10.0)
	var z: float = rng.randf_range(-11.0, -1.0)
	var white := _mat("#ffffff", 0.6)
	var c := _sphere(seg, Vector3(x, y, z), 1.4, white)
	c.scale = Vector3(1.6, 0.55, 1.0)
	var c2 := _sphere(seg, Vector3(x + 1.6, y + 0.3, z), 1.0, white)
	c2.scale = Vector3(1.4, 0.55, 1.0)


func _add_mountain(seg: Node3D) -> void:
	var side: float = -1.0 if rng.randf() < 0.5 else 1.0
	# Far background only — close mountains filled the whole frame.
	var x: float = side * rng.randf_range(18.0, 30.0)
	var z: float = rng.randf_range(-11.0, -1.0)
	var m: Node3D = MOUNTAIN.instantiate()
	m.position = Vector3(x, -0.9, z)
	m.scale = Vector3.ONE * rng.randf_range(2.2, 3.0)
	seg.add_child(m)
	var cols: Array = ["#c9a0dc", "#ff9ec7", "#a8e063", "#ffb347"]
	_apply_overrides(m, {"Mountain": _mat(cols[rng.randi_range(0, cols.size() - 1)], 0.5)})


func _add_finish(seg: Node3D, local_z: float) -> void:
	# checkered finish line on the track
	for lane_i in [-1, 0, 1]:
		for i in range(3):
			var white: bool = (lane_i + i) % 2 == 0
			_box(seg, Vector3(_lane_x(lane_i) + (float(i) - 1.0) * 0.72, 0.02, local_z), Vector3(0.72, 0.04, 0.5), _mat("#ffffff" if white else "#1a1a1a", 0.4))
	# finish arch
	_cyl(seg, Vector3(-3.4, 1.3, local_z), 0.14, 0.14, 2.6, _mat("#ffd23f", 0.3))
	_cyl(seg, Vector3(3.4, 1.3, local_z), 0.14, 0.14, 2.6, _mat("#ffd23f", 0.3))
	_box(seg, Vector3(0, 2.7, local_z), Vector3(7.0, 0.5, 0.3), _mat("#ffd23f", 0.3))
