class_name Obstacle
extends Node3D
## One generic obstacle. The track builder spawns one per hazard and the
## game asks check_player() every physics frame.
## Upgraded with 3D studio candy shaders, ground contact shadows, and 3D detail.

var kind: String = "hole"
var lane: int = 0
var consumed: bool = false
var is_hole: bool = false
var crossed: bool = false
var counted: bool = false
var cleared_airborne: bool = false
var perfect: bool = false
var time: float = 0.0

var _tiles: Dictionary = {}
var _rim: Node3D = null
var _current_lane: int = 0
var _rim_x: float = 0.0
var _arm_pivot: Node3D = null
var _arm_angle: float = 0.0
var _block: MeshInstance3D = null
var _block_y: float = -1.3
var _gate_bar: MeshInstance3D = null
var _gate_closed: bool = true
var _bean_y: float = 0.0
var _drop_x: float = 0.0
var _drop_y: float = 0.0
var _bubble_y: float = 1.6
var _chunk: MeshInstance3D = null
var _chunk_y: float = 7.0
var _chunk_triggered: bool = false
var _chunk_landed: bool = false
var _wind_dir: int = 1
var _open_lane: int = 0
var _hole_rows: int = 1
var _ball: MeshInstance3D = null
var _shadow: MeshInstance3D = null


func setup(p_kind: String, board: Dictionary, p_lane: int, data: Dictionary = {}) -> void:
	kind = p_kind
	lane = p_lane
	_tiles = data.get("tiles", {})
	_rim = data.get("rim", null)
	_open_lane = int(data.get("open_lane", 0))
	_wind_dir = int(data.get("wind_dir", 1))
	_hole_rows = int(data.get("rows", 1))
	_current_lane = lane
	_rim_x = float(lane) * 2.2
	is_hole = kind in ["hole", "wide_pit", "cloud_gap", "sliding_hole"]
	match kind:
		"blocker":
			_build_gummy_bear(board)
		"rolling_ball":
			_build_rolling_ball(Color.html("#ff2e4d"), Color.html("#7ed957"), 0.62)
		"rolling_pit":
			_build_rolling_ball(Color.html("#5e0a1a"), Color.html("#7a1030"), 0.48)
		"pinwheel":
			_build_pinwheel(board)
		"sticky_patch":
			_build_sticky_patch(board)
		"bubble":
			_build_bubble()
		"whip":
			_build_whip(board)
		"rising_block":
			_build_rising_block(board)
		"bouncing_bean":
			_build_bouncing_bean(board)
		"wind_gust":
			_build_wind_gust()
		"falling_chunk":
			_build_falling_chunk(board)
		"bouncing_drop":
			_build_bouncing_drop(board)
		"thorn_bush":
			_build_thorn_bush(board)
		"gate":
			_build_gate(board)
		"honeycomb_wall":
			_build_honeycomb_wall(board)
		"blueberry_roller":
			_build_blueberry_roller()


func current_lane_x() -> float:
	if kind == "sliding_hole":
		return _rim_x
	return float(lane) * 2.2


func _mat(c: Color, rough: float = 0.16, glow: bool = false) -> ShaderMaterial:
	return CandyMaterials.mat("#" + c.to_html(false), rough, glow, false, 0.42)


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


func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
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


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


func _star_prism(parent: Node3D, pos: Vector3, outer_r: float, inner_r: float, thick: float, mat: Material) -> MeshInstance3D:
	var pts: Array = []
	for k in range(10):
		var a: float = PI * 0.5 + float(k) * PI / 5.0
		var r: float = outer_r if k % 2 == 0 else inner_r
		pts.append(Vector3(cos(a) * r, 0, sin(a) * r))
	var half: float = thick * 0.5
	var top_c := Vector3(0, half, 0)
	var bot_c := Vector3(0, -half, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(10):
		var p0: Vector3 = pts[k]
		var p1: Vector3 = pts[(k + 1) % 10]
		var t0 := Vector3(p0.x, half, p0.z)
		var t1 := Vector3(p1.x, half, p1.z)
		var b0 := Vector3(p0.x, -half, p0.z)
		var b1 := Vector3(p1.x, -half, p1.z)
		_tri(st, top_c, t1, t0, Vector3(0, 1, 0))
		_tri(st, bot_c, b0, b1, Vector3(0, -1, 0))
		var e: Vector3 = p1 - p0
		var n := Vector3(e.z, 0, -e.x).normalized()
		var mid: Vector3 = (p0 + p1) * 0.5
		if n.dot(mid) < 0.0:
			n = -n
		_tri(st, t0, b0, b1, n)
		_tri(st, t0, b1, t1, n)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


const GUMMY_BEAR: PackedScene = preload("res://models/gummy_bear.glb")


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


func _build_gummy_bear(_board: Dictionary) -> void:
	var colors: Array = [Color.html("#7ed957"), Color.html("#ff8a00"), Color.html("#ffd23f"), Color.html("#ff5c8a")]
	var c: Color = colors[randi() % colors.size()]
	var bear: Node3D = GUMMY_BEAR.instantiate()
	bear.rotation.y = PI
	add_child(bear)
	_apply_overrides(bear, {
		"Gummy": _mat(c, 0.08),
		"Belly": _mat(Color.html("#ffffff"), 0.16),
	})
	add_child(CandyMaterials.make_drop_shadow(0.65, 0.48))


func _build_rolling_ball(_body_c: Color, _top_c: Color, r: float) -> void:
	var truf_r: float = maxf(r, 0.74)
	var truf_mat := CandyMaterials.get_truffle_material()
	_ball = _sphere(self, Vector3(0, truf_r, 0), truf_r, truf_mat)
	# Organic swirled chocolate truffle ribs around the sphere
	for i in range(6):
		var ang: float = float(i) * PI / 3.0
		var lobe := _sphere(_ball, Vector3(cos(ang) * truf_r * 0.22, 0.0, sin(ang) * truf_r * 0.22), truf_r * 0.84, truf_mat)
		lobe.scale = Vector3(0.88, 1.04, 0.88)
		lobe.rotation = Vector3(0.25, ang, 0.20)
	_shadow = CandyMaterials.make_drop_shadow(truf_r * 1.35, 0.58)
	add_child(_shadow)


func _build_pinwheel(_board: Dictionary) -> void:
	_cyl(self, Vector3(0, 0.7, 0), 0.08, 0.10, 1.4, _mat(Color.html("#ffffff"), 0.15))
	add_child(CandyMaterials.make_drop_shadow(0.55, 0.42))
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 1.45, 0)
	add_child(pivot)
	_arm_pivot = pivot
	var cols: Array = [Color.html("#ff2e4d"), Color.html("#ffffff"), Color.html("#ff2e4d"), Color.html("#ffffff")]
	for i in range(4):
		var blade := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.16, 0.88, 0.07)
		blade.mesh = b
		blade.position = Vector3(0, 0.45, 0)
		blade.material_override = _mat(cols[i], 0.12, i % 2 == 0)
		var holder := Node3D.new()
		holder.rotation.z = float(i) * PI * 0.5
		holder.add_child(blade)
		pivot.add_child(holder)
	_sphere(pivot, Vector3(0, 0, 0.06), 0.16, _mat(Color.html("#ffd23f"), 0.10, true))


func _build_sticky_patch(_board: Dictionary) -> void:
	var disc := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 1.1
	c.bottom_radius = 1.1
	c.height = 0.09
	disc.mesh = c
	disc.position = Vector3(0, 0.045, 0)
	disc.material_override = _mat(Color.html("#6e2f00"), 0.05)
	add_child(disc)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.02
	tm.outer_radius = 1.26
	rim.mesh = tm
	rim.position = Vector3(0, 0.06, 0)
	rim.material_override = _mat(Color.html("#ffb300"), 0.08, true)
	add_child(rim)
	_sphere(self, Vector3(0.4, 0.12, 0.3), 0.22, _mat(Color.html("#ffd23f"), 0.06, true))
	_sphere(self, Vector3(-0.5, 0.12, -0.2), 0.18, _mat(Color.html("#ffd23f"), 0.06, true))


func _build_bubble() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.22, 0.72, 0.72)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic = 0.25
	m.emission_enabled = true
	m.emission = Color.html("#ff5ce1")
	m.emission_energy_multiplier = 0.25
	_sphere(self, Vector3(0, 1.6, 0), 0.72, m)
	_sphere(self, Vector3(-0.22, 1.82, 0.48), 0.18, _mat(Color.html("#ffffff"), 0.05, true))
	add_child(CandyMaterials.make_drop_shadow(0.68, 0.35))


func _build_whip(_board: Dictionary) -> void:
	_cyl(self, Vector3(-3.6, 0.6, 0), 0.16, 0.18, 1.25, _mat(Color.html("#ff2fb3"), 0.15, true))
	_arm_pivot = Node3D.new()
	_arm_pivot.position = Vector3(-3.6, 0.8, 0)
	add_child(_arm_pivot)
	var arm := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.17
	c.bottom_radius = 0.17
	c.height = 5.0
	arm.mesh = c
	arm.rotation.z = PI * 0.5
	arm.position = Vector3(2.5, 0, 0)
	arm.material_override = _mat(Color.html("#3d0a4e"), 0.14)
	_arm_pivot.add_child(arm)
	var tip := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.24
	s.height = 0.48
	tip.mesh = s
	tip.position = Vector3(5.0, 0, 0)
	tip.material_override = _mat(Color.html("#ff5ce1"), 0.08, true)
	_arm_pivot.add_child(tip)


func _build_rising_block(_board: Dictionary) -> void:
	_block = _box(self, Vector3(0, -1.3, 0), Vector3(1.9, 1.3, 1.3), _mat(Color.html("#8a5a2a"), 0.20))
	_box(_block, Vector3(0, 0.66, 0), Vector3(1.75, 0.12, 1.15), _mat(Color.html("#ffd23f"), 0.12, true))
	_box(_block, Vector3(0, 0.0, 0.66), Vector3(1.6, 0.9, 0.06), _mat(Color.html("#c68a3a"), 0.22))


func _build_bouncing_bean(_board: Dictionary) -> void:
	var cols: Array = [Color.html("#ff5c8a"), Color.html("#7ed957"), Color.html("#ffd23f"), Color.html("#b967ff"), Color.html("#ff8a00")]
	var c: Color = cols[randi() % cols.size()]
	var cap := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.44
	cm.height = 1.15
	cap.mesh = cm
	cap.material_override = _mat(c, 0.08)
	add_child(cap)
	_block = cap
	_shadow = CandyMaterials.make_drop_shadow(0.58, 0.45)
	add_child(_shadow)


func _build_wind_gust() -> void:
	for i in range(3):
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.55 + float(i) * 0.12
		tm.outer_radius = tm.inner_radius + 0.16
		ring.mesh = tm
		ring.position = Vector3(0, 0.9 + float(i) * 0.5, float(i) * 0.7 - 0.7)
		ring.material_override = _mat(Color.html("#fff0f8"), 0.08, true)
		add_child(ring)
		_block = ring


func _build_falling_chunk(_board: Dictionary) -> void:
	_chunk = _box(self, Vector3(0, 7.0, 0), Vector3(1.45, 1.15, 1.45), _mat(Color.html("#7a4a22"), 0.22))
	_box(_chunk, Vector3(0, 0.58, 0), Vector3(1.28, 0.14, 1.28), _mat(Color.html("#ffd23f"), 0.12, true))
	_shadow = CandyMaterials.make_drop_shadow(0.85, 0.50)
	add_child(_shadow)


func _build_bouncing_drop(_board: Dictionary) -> void:
	_ball = _sphere(self, Vector3(0, 0.55, 0), 0.56, _mat(Color.html("#ffe14d"), 0.10, true))
	_sphere(_ball, Vector3(0, 0.58, 0), 0.15, _mat(Color.html("#7ed957"), 0.12))
	_shadow = CandyMaterials.make_drop_shadow(0.60, 0.45)
	add_child(_shadow)


func _build_thorn_bush(_board: Dictionary) -> void:
	var bush := _mat(Color.html("#8a1a3a"), 0.24)
	_sphere(self, Vector3(0, 0.6, 0), 0.64, bush)
	_sphere(self, Vector3(-0.5, 0.4, 0.2), 0.42, bush)
	_sphere(self, Vector3(0.5, 0.4, -0.2), 0.42, bush)
	for i in range(6):
		var ang: float = TAU * float(i) / 6.0
		var thorn := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.10
		c.height = 0.42
		thorn.mesh = c
		thorn.position = Vector3(cos(ang) * 0.75, 0.9, sin(ang) * 0.75)
		thorn.rotation = Vector3(sin(ang) * 0.7, 0, -cos(ang) * 0.7)
		thorn.material_override = _mat(Color.html("#ff2e4d"), 0.12, true)
		add_child(thorn)
	_sphere(self, Vector3(0, 1.25, 0), 0.20, _mat(Color.html("#ff2e4d"), 0.10, true))
	_sphere(self, Vector3(-0.4, 1.05, 0.2), 0.15, _mat(Color.html("#ff2e4d"), 0.10, true))
	add_child(CandyMaterials.make_drop_shadow(0.85, 0.48))


func _build_gate(_board: Dictionary) -> void:
	_cyl(self, Vector3(-3.4, 0.9, 0), 0.16, 0.18, 1.85, _mat(Color.html("#ff2e4d"), 0.12))
	_cyl(self, Vector3(3.4, 0.9, 0), 0.16, 0.18, 1.85, _mat(Color.html("#ff2e4d"), 0.12))
	_gate_bar = _box(self, Vector3(0, 0.7, 0), Vector3(6.6, 0.36, 0.32), _mat(Color.html("#ffffff"), 0.14))
	for i in range(5):
		_box(_gate_bar, Vector3(-2.6 + float(i) * 1.3, 0, 0), Vector3(0.55, 0.38, 0.34), _mat(Color.html("#ff2e4d"), 0.12, true))


func _build_blueberry_roller() -> void:
	_ball = _sphere(self, Vector3(0, 0.97, 0), 0.97, _mat(Color.html("#3a1a6e"), 0.08))
	_sphere(self, Vector3(-0.33, 1.37, 0.59), 0.29, _mat(Color.html("#8c6eff"), 0.08, true))
	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color.html("#c44dff")
	crown_mat.roughness = 0.12
	crown_mat.emission_enabled = true
	crown_mat.emission = Color.html("#c44dff")
	crown_mat.emission_energy_multiplier = 0.55
	crown_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_star_prism(self, Vector3(0, 1.88, 0), 0.66, 0.29, 0.18, crown_mat)
	_sphere(self, Vector3(0, 1.93, 0), 0.13, _mat(Color.html("#1a0830"), 0.20))
	add_child(CandyMaterials.make_drop_shadow(1.05, 0.52))


func _build_honeycomb_wall(_board: Dictionary) -> void:
	var gold := _mat(Color.html("#ffb300"), 0.16)
	var dark := _mat(Color.html("#7a4400"), 0.24)
	for lane_i in [-1, 0, 1]:
		if lane_i == _open_lane:
			continue
		var x: float = float(lane_i) * 2.2
		_box(self, Vector3(x, 0.8, 0), Vector3(2.1, 1.6, 0.52), gold)
		for cy in [-0.4, 0.3]:
			for cx in [-0.6, 0.0, 0.6]:
				_cyl(self, Vector3(x + cx, 0.8 + cy, 0.29), 0.26, 0.26, 0.08, dark)
	_box(self, Vector3(0, 1.7, 0), Vector3(6.6, 0.28, 0.56), dark)


# --- Per-frame animation ---

func update_obstacle(delta: float, player_z: float) -> void:
	time += delta
	match kind:
		"sliding_hole":
			_update_sliding_hole(delta)
		"rolling_ball", "rolling_pit", "blueberry_roller":
			position.z += delta * 2.0
			if _ball != null:
				_ball.rotation.x -= delta * 3.0
		"pinwheel":
			if _arm_pivot != null:
				_arm_pivot.rotation.z += delta * 4.0
		"bubble":
			_bubble_y = 1.6 + sin(time * 2.0) * 0.25
			var b: MeshInstance3D = get_child(0) as MeshInstance3D
			if b != null:
				b.position.y = _bubble_y
		"whip":
			_arm_angle = sin(time * 1.8) * 1.05
			if _arm_pivot != null:
				_arm_pivot.rotation.y = _arm_angle
		"rising_block":
			var cyc: float = fmod(time, 2.4)
			var up: float = smoothstep(0.0, 0.5, cyc) * (1.0 - smoothstep(1.2, 1.7, cyc))
			_block_y = -1.3 + up * 1.85
			if _block != null:
				_block.position.y = _block_y
		"bouncing_bean":
			_bean_y = absf(sin(time * 3.5)) * 1.3
			if _block != null:
				_block.position.y = _bean_y + 0.55
			if _shadow != null:
				var sc: float = clampf(1.0 - _bean_y * 0.35, 0.4, 1.0)
				_shadow.scale = Vector3(sc, 1.0, sc)
		"bouncing_drop":
			_drop_x = sin(time * 2.2) * 2.2
			_drop_y = absf(sin(time * 4.0)) * 1.1
			if _ball != null:
				_ball.position = Vector3(_drop_x, _drop_y + 0.55, 0)
			if _shadow != null:
				_shadow.position.x = _drop_x
				var sc2: float = clampf(1.0 - _drop_y * 0.35, 0.4, 1.0)
				_shadow.scale = Vector3(sc2, 1.0, sc2)
		"gate":
			var gcyc: float = fmod(time, 2.4)
			_gate_closed = gcyc < 1.2
			if _gate_bar != null:
				_gate_bar.position.y = 0.7 if _gate_closed else -1.3
		"falling_chunk":
			if not _chunk_triggered and player_z - global_position.z < 14.0 and player_z > global_position.z:
				_chunk_triggered = true
			if _chunk_triggered and not _chunk_landed:
				_chunk_y -= delta * 12.0
				if _chunk_y <= 0.55:
					_chunk_y = 0.55
					_chunk_landed = true
				if _chunk != null:
					_chunk.position.y = _chunk_y
		"wind_gust":
			if _block != null:
				_block.rotation.y += delta * 2.0


func _update_sliding_hole(delta: float) -> void:
	var seq: Array = [-1, 0, 1, 0]
	var idx: int = int(time / 1.4) % seq.size()
	var target_lane: int = seq[idx]
	_current_lane = target_lane
	var target_x: float = float(target_lane) * 2.2
	_rim_x = lerpf(_rim_x, target_x, delta * 6.0)
	if _rim != null:
		_rim.position.x = _rim_x
	if absf(_rim_x - target_x) < 0.4:
		for lane_key in _tiles.keys():
			var tiles: Array = _tiles[lane_key]
			for t in tiles:
				t.visible = int(lane_key) != target_lane


func check_player(player_pos: Vector3, player_y: float) -> String:
	if consumed:
		return "none"
	var lp: Vector3 = to_local(player_pos)
	var dz: float = lp.z
	var px: float = lp.x
	match kind:
		"hole":
			if absf(dz) < 1.3 and absf(px - float(lane) * 2.2) < 1.05 and player_y < 0.3:
				return "fall"
		"wide_pit":
			if absf(dz) < 2.4 and absf(px - float(lane) * 2.2) < 1.05 and player_y < 0.3:
				return "fall"
		"cloud_gap":
			if absf(dz) < 1.3 * float(_hole_rows) and player_y < 0.3:
				return "fall"
		"sliding_hole":
			if absf(dz) < 1.3 and absf(px - _rim_x) < 1.05 and player_y < 0.3:
				return "fall"
		"blocker":
			if absf(dz) < 0.9 and absf(px - float(lane) * 2.2) < 1.0 and player_y < 1.25:
				return "hit"
		"rolling_ball":
			if absf(dz) < 0.9 and absf(px - float(lane) * 2.2) < 0.9 and player_y < 0.9:
				return "hit"
		"rolling_pit":
			if absf(dz) < 0.85 and absf(px - float(lane) * 2.2) < 0.85 and player_y < 0.7:
				return "hit"
		"blueberry_roller":
			if absf(dz) < 1.0 and absf(px - float(lane) * 2.2) < 1.0 and player_y < 1.2:
				return "hit"
		"pinwheel":
			if absf(dz) < 0.9 and absf(px - float(lane) * 2.2) < 1.0 and player_y < 1.35:
				return "hit"
		"sticky_patch":
			if absf(dz) < 1.2 and absf(px - float(lane) * 2.2) < 1.1 and player_y < 0.3:
				return "slow"
		"bubble":
			if absf(dz) < 0.8 and absf(px - float(lane) * 2.2) < 0.9 and player_y > 0.9 and player_y < 2.5:
				return "hit"
		"whip":
			if absf(dz) < 0.7 and player_y < 1.2:
				var ax: float = -3.6
				var az: float = 0.0
				var bx: float = -3.6 + cos(_arm_angle) * 5.0
				var bz: float = sin(_arm_angle) * 5.0
				if _dist_point_segment(px, dz, ax, az, bx, bz) < 0.7:
					return "hit"
		"rising_block":
			if _block_y > -0.2 and absf(dz) < 1.0 and absf(px - float(lane) * 2.2) < 1.0 and player_y < 1.15:
				return "hit"
		"bouncing_bean":
			if absf(dz) < 0.85 and absf(px - float(lane) * 2.2) < 0.9 and player_y < _bean_y + 0.55 and player_y + 1.4 > _bean_y - 0.55:
				return "hit"
		"wind_gust":
			if absf(dz) < 1.6 and player_y < 0.5:
				return "wind_left" if _wind_dir < 0 else "wind_right"
		"falling_chunk":
			if _chunk_triggered:
				if absf(dz) < 1.0 and absf(px - float(lane) * 2.2) < 1.0:
					if _chunk_landed and player_y < 1.1:
						return "hit"
					if not _chunk_landed and _chunk_y < 2.2 and player_y + 1.4 > _chunk_y - 0.55:
						return "hit"
		"bouncing_drop":
			if absf(dz) < 0.85 and absf(px - _drop_x) < 0.9 and player_y < _drop_y + 0.5 and player_y + 1.4 > _drop_y - 0.5:
				return "hit"
		"thorn_bush":
			if absf(dz) < 0.9 and absf(px - float(lane) * 2.2) < 1.0 and player_y < 1.2:
				return "hit"
		"gate":
			if _gate_closed and absf(dz) < 0.9 and player_y < 1.35:
				return "hit"
		"honeycomb_wall":
			if absf(dz) < 0.9 and int(roundf(px / 2.2)) != _open_lane and player_y < 1.5:
				return "hit"
	return "none"


func _dist_point_segment(px: float, pz: float, ax: float, az: float, bx: float, bz: float) -> float:
	var abx: float = bx - ax
	var abz: float = bz - az
	var apx: float = px - ax
	var apz: float = pz - az
	var denom: float = abx * abx + abz * abz
	var t: float = 0.0
	if denom > 0.0001:
		t = clampf((apx * abx + apz * abz) / denom, 0.0, 1.0)
	var cx: float = ax + abx * t
	var cz: float = az + abz * t
	return Vector2(px - cx, pz - cz).length()
