class_name Star
extends Node3D
## Sugar star collectible, built in real Blender (star.glb) and upgraded with
## 3D studio candy shaders, ground contact shadow, and rainbow shimmer.

const STAR_SCENE: PackedScene = preload("res://models/star.glb")

var kind: String = "normal"
var value: int = 1
var collected: bool = false
var missed: bool = false
var base_y: float = 0.9
var phase: float = 0.0
var _star_mesh: Node3D
var _spin_speed: float = 2.4


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

	var star_hex: String = "#ffd23f"
	var bead_hex: String = "#ff5c8a"
	if kind == "rainbow":
		star_hex = "#ff2fb3"
		bead_hex = "#00e5ff"
	elif kind == "big":
		star_hex = "#ff8a00"
		bead_hex = "#ffd23f"

	var star_mat := CandyMaterials.mat(star_hex, 0.08, true, false, 0.45)
	var bead_mat := CandyMaterials.mat(bead_hex, 0.10, true, false, 0.45)
	var ring_mat := CandyMaterials.mat("#ff5c8a", 0.14, true, false, 0.35)
	_recolor(model, "star", star_mat)
	_recolor(model, "bead", bead_mat)
	_recolor(model, "ring", ring_mat)


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


func update_star(delta: float, magnet_target: Vector3, magnet_on: bool, soft_radius: float = 2.3) -> void:
	if collected:
		return
	phase += delta * _spin_speed
	if _star_mesh:
		_star_mesh.rotation.y = phase
		_star_mesh.rotation.z = sin(phase * 1.2) * 0.12
		_star_mesh.position.y = sin(phase * 1.8) * 0.14
	var d: Vector3 = magnet_target - global_position
	var dist: float = d.length()
	if magnet_on:
		if dist < 7.0:
			global_position += d.normalized() * delta * 14.0
	elif dist < soft_radius and dist > 0.01:
		# Always-on gentle pull so near-grabs feel generous.
		global_position += d.normalized() * delta * (3.5 + (soft_radius - dist) * 5.0)


func collect() -> void:
	collected = true
	visible = false
	set_process(false)


## Extruded 5-point star mesh with beveled 3D center peak, facing +Z (toward the camera).
static func make_star_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer: float = 0.52
	var inner: float = 0.23
	var half: float = 0.14
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
		# True 3D faceted star: front and back bevel faces meet at outer/inner ridge
		var nf := (b - cf).cross(a - cf).normalized()
		if nf.z < 0.0:
			nf = -nf
		_add_tri(st, cf, a, b, nf)
		var nb := (a - cb).cross(b - cb).normalized()
		if nb.z > 0.0:
			nb = -nb
		_add_tri(st, cb, b, a, nb)
	return st.commit()


static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)
