class_name PowerUp
extends Node3D
## Floating 3D power-up pickups with studio candy shaders, halo rings, and drop shadows.

var kind: String = "speed"
var collected: bool = false
var phase: float = 0.0
var _visual: Node3D
var _halo: MeshInstance3D


func setup(p_kind: String, pos: Vector3) -> void:
	kind = p_kind
	position = pos
	phase = randf() * TAU
	_visual = Node3D.new()
	add_child(_visual)

	var shadow := CandyMaterials.make_drop_shadow(0.55, 0.42)
	shadow.position = Vector3(0, -pos.y + 0.03, 0)
	add_child(shadow)

	match kind:
		"speed":
			_build_lightning()
		"shield":
			_build_shield()
		"magnet":
			_build_magnet()
		"2x":
			_build_2x()
		"sour":
			_build_sour()


func update_powerup(delta: float) -> void:
	if collected:
		return
	phase += delta * 2.4
	_visual.rotation.y = phase
	_visual.position.y = sin(phase * 1.6) * 0.16
	if _halo:
		_halo.rotation.z = -phase * 1.5


func collect() -> void:
	collected = true
	visible = false
	set_process(false)


func _mat(c: Color, glow: bool = false, rough: float = 0.14) -> ShaderMaterial:
	return CandyMaterials.mat("#" + c.to_html(false), rough, glow, false, 0.45)


func _add_halo(c: Color) -> void:
	_halo = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.56
	tm.outer_radius = 0.64
	_halo.mesh = tm
	_halo.rotation.x = PI * 0.35
	_halo.material_override = _mat(c, true, 0.10)
	_visual.add_child(_halo)


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


func _cone(parent: Node3D, pos: Vector3, r: float, h: float, mat: Material, flip: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = r
	c.height = h
	mi.mesh = c
	mi.position = pos
	if flip:
		mi.rotation.x = PI
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _build_lightning() -> void:
	var gold := _mat(Color.html("#ffd23f"), true, 0.08)
	var white := _mat(Color.html("#ffffff"), true, 0.08)
	_cone(_visual, Vector3(0.06, 0.30, 0), 0.24, 0.58, gold)
	_cone(_visual, Vector3(-0.06, -0.30, 0), 0.24, 0.58, gold, true)
	_sphere(_visual, Vector3(0, 0, 0), 0.20, white)
	_add_halo(Color.html("#ffd23f"))


func _build_shield() -> void:
	var core := _mat(Color.html("#00e5ff"), true, 0.08)
	_sphere(_visual, Vector3(0, 0, 0), 0.26, core)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.25, 0.92, 1.0, 0.52)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic = 0.25
	m.emission_enabled = true
	m.emission = Color.html("#00e5ff")
	m.emission_energy_multiplier = 0.35
	_sphere(_visual, Vector3(0, 0, 0), 0.50, m)
	_sphere(_visual, Vector3(-0.16, 0.18, 0.32), 0.11, _mat(Color.html("#ffffff"), true))
	_add_halo(Color.html("#00e5ff"))


func _build_magnet() -> void:
	_sphere(_visual, Vector3(0, 0, 0), 0.42, _mat(Color.html("#ff2e4d"), true, 0.10))
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.40
	tm.outer_radius = 0.52
	ring.mesh = tm
	ring.material_override = _mat(Color.html("#ffffff"), true, 0.12)
	_visual.add_child(ring)
	_add_halo(Color.html("#ff2e4d"))


func _build_2x() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Star.make_star_mesh()
	mi.material_override = _mat(Color.html("#b967ff"), true, 0.08)
	mi.scale = Vector3.ONE * 1.35
	_visual.add_child(mi)
	_add_halo(Color.html("#b967ff"))


func _build_sour() -> void:
	var green := _mat(Color.html("#7ed957"), true, 0.12)
	var lime := _mat(Color.html("#c8ff4d"), true, 0.10)
	_sphere(_visual, Vector3(0, 0, 0), 0.46, green)
	# 3D spiky sour crystals around the sphere
	for i in range(6):
		var a: float = float(i) * TAU / 6.0
		var sp := _cone(_visual, Vector3(cos(a) * 0.48, sin(a) * 0.48, 0), 0.11, 0.26, lime)
		sp.rotation.z = a - PI * 0.5
	var dark := _mat(Color.html("#1a1a1a"), false, 0.10)
	var eye_l := MeshInstance3D.new()
	var eb := BoxMesh.new()
	eb.size = Vector3(0.15, 0.045, 0.04)
	eye_l.mesh = eb
	eye_l.position = Vector3(-0.16, 0.12, 0.44)
	eye_l.rotation.z = 0.5
	eye_l.material_override = dark
	_visual.add_child(eye_l)
	var eye_r := MeshInstance3D.new()
	eye_r.mesh = eb
	eye_r.position = Vector3(0.16, 0.12, 0.44)
	eye_r.rotation.z = -0.5
	eye_r.material_override = dark
	_visual.add_child(eye_r)
	_add_frown_piece(Vector3(-0.12, -0.10, 0.44), 0.6)
	_add_frown_piece(Vector3(0.0, -0.05, 0.45), 0.0)
	_add_frown_piece(Vector3(0.12, -0.10, 0.44), -0.6)


func _add_frown_piece(pos: Vector3, rot_z: float) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.12, 0.045, 0.04)
	mi.mesh = b
	mi.position = pos
	mi.rotation.z = rot_z
	mi.material_override = _mat(Color.html("#1a1a1a"), false, 0.10)
	_visual.add_child(mi)
