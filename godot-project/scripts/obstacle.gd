class_name Obstacle
extends Node3D
## One generic obstacle. The track builder spawns one per hazard and the
## game asks check_player() every physics frame.
## check_player returns: "none", "fall", "hit", "slow", "wind_left", "wind_right".

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
			_build_rolling_ball(Color.html("#5e0a1a"), Color.html("#7a1030"), 0.45)
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


func current_lane_x() -> float:
	if kind == "sliding_hole":
		return _rim_x
	return float(lane) * 2.2


func _mat(c: Color, rough: float = 0.4, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if glow:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.5
	return m


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


# --- Visual builders ---

func _build_gummy_bear(board: Dictionary) -> void:
	var colors: Array = [Color.html("#7ed957"), Color.html("#ff8a00"), Color.html("#ffd23f"), Color.html("#ff5c8a")]
	var c: Color = colors[randi() % colors.size()]
	var mat := _mat(c, 0.25)
	_sphere(self, Vector3(0, 0.55, 0), 0.5, mat)
	_sphere(self, Vector3(0, 1.15, 0), 0.34, mat)
	_sphere(self, Vector3(-0.24, 1.42, 0), 0.13, mat)
	_sphere(self, Vector3(0.24, 1.42, 0), 0.13, mat)
	_sphere(self, Vector3(0, 1.10, 0.30), 0.14, _mat(Color.html("#ffffff")))
	# candy belly shine (front, facing the player)
	_sphere(self, Vector3(0, 0.55, 0.42), 0.28, _mat(Color(1, 1, 1, 0.35)))


func _build_rolling_ball(body_c: Color, top_c: Color, r: float) -> void:
	_ball = _sphere(self, Vector3(0, r, 0), r, _mat(body_c, 0.3))
	# leafy top
	_cyl(self, Vector3(0, r * 2.0 + 0.05, 0), 0.02, 0.16, 0.18, _mat(top_c))
	_sphere(self, Vector3(0.14, r * 2.0, 0), 0.12, _mat(top_c))
	_sphere(self, Vector3(-0.14, r * 2.0, 0), 0.12, _mat(top_c))


func _build_pinwheel(board: Dictionary) -> void:
	_cyl(self, Vector3(0, 0.7, 0), 0.06, 0.06, 1.4, _mat(Color.html("#ffffff")))
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 1.45, 0)
	add_child(pivot)
	_arm_pivot = pivot
	var cols: Array = [Color.html("#ff2e4d"), Color.html("#ffffff"), Color.html("#ff2e4d"), Color.html("#ffffff")]
	for i in range(4):
		var blade := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.12, 0.85, 0.04)
		blade.mesh = b
		blade.position = Vector3(0, 0.45, 0)
		blade.material_override = _mat(cols[i])
		var holder := Node3D.new()
		holder.rotation.z = float(i) * PI * 0.5
		holder.add_child(blade)
		pivot.add_child(holder)


func _build_sticky_patch(board: Dictionary) -> void:
	var disc := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 1.1
	c.bottom_radius = 1.1
	c.height = 0.06
	disc.mesh = c
	disc.position = Vector3(0, 0.03, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html("#e07b00")
	m.roughness = 0.05
	m.metallic = 0.2
	disc.material_override = m
	add_child(disc)
	# glossy bubbles on the caramel
	_sphere(self, Vector3(0.4, 0.08, 0.3), 0.16, _mat(Color.html("#ffb347"), 0.1))
	_sphere(self, Vector3(-0.5, 0.08, -0.2), 0.12, _mat(Color.html("#ffb347"), 0.1))


func _build_bubble() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.6, 0.9, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	_sphere(self, Vector3(0, 1.6, 0), 0.7, m)
	_sphere(self, Vector3(-0.2, 1.8, -0.5), 0.16, _mat(Color.html("#ffffff")))


func _build_whip(board: Dictionary) -> void:
	# pivot post at the left track edge
	_cyl(self, Vector3(-3.6, 0.6, 0), 0.12, 0.12, 1.2, _mat(Color.html("#3d0a33")))
	_arm_pivot = Node3D.new()
	_arm_pivot.position = Vector3(-3.6, 0.8, 0)
	add_child(_arm_pivot)
	var arm := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.16
	c.bottom_radius = 0.16
	c.height = 5.0
	arm.mesh = c
	arm.rotation.z = PI * 0.5
	arm.position = Vector3(2.5, 0, 0)
	arm.material_override = _mat(Color.html("#2a0a2e"), 0.3)
	_arm_pivot.add_child(arm)
	# pink tip
	var tip := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.2
	s.height = 0.4
	tip.mesh = s
	tip.position = Vector3(5.0, 0, 0)
	tip.material_override = _mat(Color.html("#ff5ce1"), 0.3)
	_arm_pivot.add_child(tip)


func _build_rising_block(board: Dictionary) -> void:
	_block = _box(self, Vector3(0, -1.3, 0), Vector3(1.9, 1.3, 1.3), _mat(Color.html("#8a5a2a"), 0.35))
	# golden top
	_box(_block, Vector3(0, 0.66, 0), Vector3(1.7, 0.08, 1.1), _mat(Color.html("#ffd23f"), 0.3))


func _build_bouncing_bean(board: Dictionary) -> void:
	var cols: Array = [Color.html("#ff5c8a"), Color.html("#7ed957"), Color.html("#ffd23f"), Color.html("#b967ff"), Color.html("#ff8a00")]
	var c: Color = cols[randi() % cols.size()]
	var cap := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.42
	cm.height = 1.1
	cap.mesh = cm
	cap.material_override = _mat(c, 0.2)
	add_child(cap)
	_block = cap


func _build_wind_gust() -> void:
	for i in range(3):
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.55
		tm.outer_radius = 0.7
		ring.mesh = tm
		ring.position = Vector3(0, 0.9 + float(i) * 0.5, float(i) * 0.7 - 0.7)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 1, 1, 0.5)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = m
		add_child(ring)
		_block = ring


func _build_falling_chunk(board: Dictionary) -> void:
	_chunk = _box(self, Vector3(0, 7.0, 0), Vector3(1.4, 1.1, 1.4), _mat(Color.html("#3a1c05"), 0.5))
	_box(_chunk, Vector3(0, 0.56, 0), Vector3(1.2, 0.1, 1.2), _mat(Color.html("#5e2a10"), 0.4))


func _build_bouncing_drop(board: Dictionary) -> void:
	_ball = _sphere(self, Vector3(0, 0.55, 0), 0.55, _mat(Color.html("#ffe14d"), 0.25))
	_sphere(self, Vector3(0, 1.15, 0), 0.14, _mat(Color.html("#7ed957")))


func _build_thorn_bush(board: Dictionary) -> void:
	var bush := _mat(Color.html("#8a1a3a"), 0.5)
	_sphere(self, Vector3(0, 0.6, 0), 0.62, bush)
	_sphere(self, Vector3(-0.5, 0.4, 0.2), 0.4, bush)
	_sphere(self, Vector3(0.5, 0.4, -0.2), 0.4, bush)
	# thorns: small cones pointing out
	for i in range(6):
		var ang: float = TAU * float(i) / 6.0
		var thorn := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.09
		c.height = 0.4
		thorn.mesh = c
		thorn.position = Vector3(cos(ang) * 0.75, 0.9, sin(ang) * 0.75)
		thorn.rotation = Vector3(sin(ang) * 0.7, 0, -cos(ang) * 0.7)
		thorn.material_override = _mat(Color.html("#ff2e4d"), 0.4)
		add_child(thorn)
	# raspberries on top
	_sphere(self, Vector3(0, 1.25, 0), 0.18, _mat(Color.html("#ff2e4d"), 0.3))
	_sphere(self, Vector3(-0.4, 1.05, 0.2), 0.14, _mat(Color.html("#ff2e4d"), 0.3))


func _build_gate(board: Dictionary) -> void:
	# two candy-cane poles
	_cyl(self, Vector3(-3.4, 0.9, 0), 0.14, 0.14, 1.8, _mat(Color.html("#ff2e4d")))
	_cyl(self, Vector3(3.4, 0.9, 0), 0.14, 0.14, 1.8, _mat(Color.html("#ff2e4d")))
	# striped bar that slides down when open
	_gate_bar = _box(self, Vector3(0, 0.7, 0), Vector3(6.6, 0.35, 0.3), _mat(Color.html("#ffffff")))
	for i in range(5):
		_box(_gate_bar, Vector3(-2.6 + float(i) * 1.3, 0, 0), Vector3(0.55, 0.36, 0.31), _mat(Color.html("#ff2e4d")))


func _build_honeycomb_wall(board: Dictionary) -> void:
	var gold := _mat(Color.html("#ffb300"), 0.35)
	var dark := _mat(Color.html("#8a5a00"), 0.4)
	# wall covers the two lanes that are NOT the open lane
	for lane_i in [-1, 0, 1]:
		if lane_i == _open_lane:
			continue
		var x: float = float(lane_i) * 2.2
		_box(self, Vector3(x, 0.8, 0), Vector3(2.1, 1.6, 0.5), gold)
		# honeycomb cells: small cylinders on the face
		for cy in [-0.4, 0.3]:
			for cx in [-0.6, 0.0, 0.6]:
				_cyl(self, Vector3(x + cx, 0.8 + cy, -0.28), 0.22, 0.22, 0.06, dark)
	# golden frame on top
	_box(self, Vector3(0, 1.7, 0), Vector3(6.6, 0.25, 0.5), dark)


# --- Per-frame animation ---

func update_obstacle(delta: float, player_z: float) -> void:
	time += delta
	match kind:
		"sliding_hole":
			_update_sliding_hole(delta)
		"rolling_ball", "rolling_pit":
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
		"bouncing_drop":
			_drop_x = sin(time * 2.2) * 2.2
			_drop_y = absf(sin(time * 4.0)) * 1.1
			if _ball != null:
				_ball.position = Vector3(_drop_x, _drop_y + 0.55, 0)
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
	# The hole slides between lanes every 1.4s; tiles toggle with it.
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


# --- Collision query (player position in GLOBAL space) ---

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
