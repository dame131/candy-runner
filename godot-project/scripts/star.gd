class_name Star
extends Node3D
## Sugar star collectible, built in real Blender (star.glb): glossy yellow
## 5-point star with a pink center bead, on a thin pink ring lying flat
## on the track. Types: normal (1), big bonus (5), rare rainbow (10).

const STAR_SCENE: PackedScene = preload("res://models/star.glb")

var kind: String = "normal"
var value: int = 1
var collected: bool = false
var missed: bool = false
var base_y: float = 0.9
var phase: float = 0.0
var _star_mesh: Node3D
var _spin_speed: float = 2.0


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
	var model: Node3D = STAR_SCENE.instantiate()
	add_child(model)
	_star_mesh = model.find_child("Star")
	# kind color on the star body (by imported material name)
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
	mat.roughness = 0.15
	_recolor(model, "star", mat)


func _recolor(node: Node, mat_name: String, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var m: Material = mesh.surface_get_material(i)
				if m and m.resource_name == mat_name:
					mi.set_surface_override_material(i, mat)
	for c in node.get_children():
		_recolor(c, mat_name, mat)


func update_star(delta: float, magnet_target: Vector3, magnet_on: bool) -> void:
	if collected:
		return
	phase += delta * _spin_speed
	if _star_mesh:
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
## Kept as a static builder: powerup.gd uses it for the purple 2x star.
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
