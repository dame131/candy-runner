class_name Star
extends Node3D
## Sugar star collectible: yellow 5-point star (extruded mesh) floating
## above a thin pink ring lying flat on the track.
## Types: normal (1), big bonus (5), rare rainbow (10).

var kind: String = "normal"
var value: int = 1
var collected: bool = false
var missed: bool = false
var base_y: float = 0.9
var phase: float = 0.0
var _star_mesh: MeshInstance3D
var _spin_speed: float = 2.0

static var _shared_mesh: ArrayMesh = null


func setup(p_kind: String, pos: Vector3) -> void:
	kind = p_kind
	match kind:
		"big":
			value = 5
			scale = Vector3.ONE * 1.5
		"rainbow":
			value = 10
			scale = Vector3.ONE * 1.8
		_:
			value = 1
	position = pos
	base_y = pos.y
	phase = randf() * TAU
	if _shared_mesh == null:
		_shared_mesh = make_star_mesh()
	_star_mesh = MeshInstance3D.new()
	_star_mesh.mesh = _shared_mesh
	var mat := StandardMaterial3D.new()
	if kind == "rainbow":
		mat.albedo_color = Color.html("#ff2fb3")
		mat.emission_enabled = true
		mat.emission = Color.html("#ff2fb3")
		mat.emission_energy_multiplier = 0.8
	elif kind == "big":
		mat.albedo_color = Color.html("#ff8a00")
		mat.emission_enabled = true
		mat.emission = Color.html("#ff8a00")
		mat.emission_energy_multiplier = 0.4
	else:
		mat.albedo_color = Color.html("#ffd23f")
		mat.emission_enabled = true
		mat.emission = Color.html("#ffd23f")
		mat.emission_energy_multiplier = 0.35
	mat.roughness = 0.3
	_star_mesh.material_override = mat
	add_child(_star_mesh)
	# pink/red bead in the center
	var bead := MeshInstance3D.new()
	var bs := SphereMesh.new()
	bs.radius = 0.12
	bs.height = 0.24
	bead.mesh = bs
	bead.position = Vector3(0, 0, 0.10)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color.html("#ff5c8a")
	bead.material_override = bmat
	_star_mesh.add_child(bead)
	# thin pink ring lying flat on the track
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.55
	tm.rings = 24
	tm.ring_segments = 12
	ring.mesh = tm
	ring.rotation.x = PI * 0.5
	ring.position = Vector3(0, -base_y + 0.08, 0)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color.html("#ff5c8a")
	rmat.roughness = 0.35
	ring.material_override = rmat
	add_child(ring)


func update_star(delta: float, magnet_target: Vector3, magnet_on: bool) -> void:
	if collected:
		return
	phase += delta * _spin_speed
	_star_mesh.rotation.y = phase
	_star_mesh.position.y = sin(phase * 1.6) * 0.12
	if magnet_on:
		var d: Vector3 = magnet_target - global_position
		if d.length() < 7.0:
			global_position += d.normalized() * delta * 14.0


func collect() -> void:
	collected = true
	visible = false
	set_process(false)


## Extruded 5-point star mesh, facing +Z (toward the camera).
static func make_star_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer: float = 0.5
	var inner: float = 0.21
	var half: float = 0.07
	var pts: Array = []
	for i in range(10):
		var ang: float = -PI * 0.5 + float(i) * PI / 5.0
		var r: float = outer if i % 2 == 0 else inner
		pts.append(Vector3(cos(ang) * r, sin(ang) * r, 0.0))
	var cf := Vector3(0, 0, half)
	var cb := Vector3(0, 0, -half)
	for i in range(10):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % 10]
		var af := Vector3(a.x, a.y, half)
		var bf := Vector3(b.x, b.y, half)
		var ab := Vector3(a.x, a.y, -half)
		var bb := Vector3(b.x, b.y, -half)
		# Front fan (+Z normal).
		_add_tri(st, cf, af, bf, Vector3(0, 0, 1))
		# Back fan (-Z normal).
		_add_tri(st, cb, bb, ab, Vector3(0, 0, -1))
		# Side quad (outward normal in the XY plane).
		var mid: Vector3 = (a + b) * 0.5
		var n := Vector3(mid.x, mid.y, 0).normalized()
		_add_tri(st, af, ab, bb, n)
		_add_tri(st, af, bb, bf, n)
	return st.commit()


static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)
