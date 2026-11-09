class_name PowerUp
extends Node3D
## Floating power-up pickups.
## speed  - golden lightning candy: faster 5s, more points
## shield - bubble shield: survive one hole
## magnet - pulls stars for 8s
## 2x     - double points for 10s
## sour   - GREEN with a sour face: half speed 5s, streak breaks (dodge it!)

var kind: String = "speed"
var collected: bool = false
var phase: float = 0.0
var _visual: Node3D


func setup(p_kind: String, pos: Vector3) -> void:
	kind = p_kind
	position = pos
	phase = randf() * TAU
	_visual = Node3D.new()
	add_child(_visual)
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
	phase += delta * 2.2
	_visual.rotation.y = phase
	_visual.position.y = sin(phase * 1.5) * 0.15


func collect() -> void:
	collected = true
	visible = false
	set_process(false)


func _mat(c: Color, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.3
	if glow:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.6
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


# Golden lightning bolt: two cones tip to tip.
func _build_lightning() -> void:
	var gold := _mat(Color.html("#ffd23f"), true)
	_cone(_visual, Vector3(0, 0.28, 0), 0.22, 0.55, gold)
	_cone(_visual, Vector3(0, -0.28, 0), 0.22, 0.55, gold, true)
	_sphere(_visual, Vector3(0, 0, 0), 0.16, gold)


# Bubble shield: transparent cyan sphere.
func _build_shield() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.9, 1.0, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	_sphere(_visual, Vector3(0, 0, 0), 0.45, m)
	_sphere(_visual, Vector3(-0.15, 0.15, 0.3), 0.1, _mat(Color.html("#ffffff")))


# Magnet: red sphere with a white band.
func _build_magnet() -> void:
	_sphere(_visual, Vector3(0, 0, 0), 0.4, _mat(Color.html("#ff2e4d"), true))
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.38
	tm.outer_radius = 0.48
	ring.mesh = tm
	ring.material_override = _mat(Color.html("#ffffff"))
	_visual.add_child(ring)


# 2x score: purple star.
func _build_2x() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Star.make_star_mesh()
	mi.material_override = _mat(Color.html("#b967ff"), true)
	mi.scale = Vector3.ONE * 1.3
	_visual.add_child(mi)


# Sour Star: green sphere with a sour face (angry eyes + frown).
# Visibly different from a sugar star on purpose — dodge it!
func _build_sour() -> void:
	var green := _mat(Color.html("#7ed957"), true)
	_sphere(_visual, Vector3(0, 0, 0), 0.45, green)
	var dark := _mat(Color.html("#1a1a1a"))
	# angry eyes (slanted boxes) — on the +Z side, facing the player
	var eye_l := MeshInstance3D.new()
	var eb := BoxMesh.new()
	eb.size = Vector3(0.14, 0.04, 0.03)
	eye_l.mesh = eb
	eye_l.position = Vector3(-0.16, 0.12, 0.42)
	eye_l.rotation.z = 0.5
	eye_l.material_override = dark
	_visual.add_child(eye_l)
	var eye_r := MeshInstance3D.new()
	eye_r.mesh = eb
	eye_r.position = Vector3(0.16, 0.12, 0.42)
	eye_r.rotation.z = -0.5
	eye_r.material_override = dark
	_visual.add_child(eye_r)
	# frown: three small boxes in an arc (middle high, ends low)
	_add_frown_piece(Vector3(-0.12, -0.10, 0.42), 0.6)
	_add_frown_piece(Vector3(0.0, -0.05, 0.43), 0.0)
	_add_frown_piece(Vector3(0.12, -0.10, 0.42), -0.6)


func _add_frown_piece(pos: Vector3, rot_z: float) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.12, 0.04, 0.03)
	mi.mesh = b
	mi.position = pos
	mi.rotation.z = rot_z
	mi.material_override = _mat(Color.html("#1a1a1a"))
	_visual.add_child(mi)
