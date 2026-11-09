class_name DijahCharacter
extends Node3D
## Dijah — the hero, built from Godot primitives in a soft clay style.
## Braids, warm skin tone, teal top (or outfit colors), candy sneakers.
## Runs away from the camera; bobs and swings arms/legs while running.

var _body: MeshInstance3D
var _head: MeshInstance3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _cape: MeshInstance3D
var _top_mat: StandardMaterial3D
var _bottom_mat: StandardMaterial3D
var _shoe_mat: StandardMaterial3D
var _cape_mat: StandardMaterial3D
var _bob_phase: float = 0.0


func _ready() -> void:
	_top_mat = _mat(Color.html("#0e9b8a"))
	_bottom_mat = _mat(Color.html("#ff5c8a"))
	_shoe_mat = _mat(Color.html("#ffffff"))
	_cape_mat = _mat(Color.html("#e60026"))
	var skin := _mat(Color.html("#9a6a45"))
	var hair := _mat(Color.html("#1e1420"))
	var white := _mat(Color.html("#ffffff"))
	var dark := _mat(Color.html("#1a1a1a"))
	var blush := _mat(Color.html("#ff9ec7"))

	# --- legs ---
	_leg_l = _limb(Vector3(-0.14, 0.42, 0), skin, 0.09, 0.42)
	_leg_r = _limb(Vector3(0.14, 0.42, 0), skin, 0.09, 0.42)
	add_child(_leg_l)
	add_child(_leg_r)
	# candy sneakers
	_add_box(_leg_l, Vector3(0, -0.22, 0.05), Vector3(0.2, 0.12, 0.34), _shoe_mat)
	_add_box(_leg_r, Vector3(0, -0.22, 0.05), Vector3(0.2, 0.12, 0.34), _shoe_mat)

	# --- body (teal top) ---
	_body = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.30
	cap.height = 0.85
	_body.mesh = cap
	_body.position = Vector3(0, 0.85, 0)
	_body.material_override = _top_mat
	add_child(_body)
	# skirt / bottom
	var skirt := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.30
	cyl.bottom_radius = 0.38
	cyl.height = 0.28
	skirt.mesh = cyl
	skirt.position = Vector3(0, 0.52, 0)
	skirt.material_override = _bottom_mat
	add_child(skirt)
	# butterfly tattoo (tiny purple mark on the chest)
	var tat := MeshInstance3D.new()
	var tat_box := BoxMesh.new()
	tat_box.size = Vector3(0.16, 0.02, 0.10)
	tat.mesh = tat_box
	tat.position = Vector3(0, 0.98, -0.29)
	tat.material_override = _mat(Color.html("#b967ff"))
	add_child(tat)

	# --- cape (hidden unless the outfit has one) ---
	_cape = MeshInstance3D.new()
	var cape_box := BoxMesh.new()
	cape_box.size = Vector3(0.5, 0.7, 0.03)
	_cape.mesh = cape_box
	_cape.position = Vector3(0, 0.85, 0.32)
	_cape.material_override = _cape_mat
	_cape.visible = false
	add_child(_cape)

	# --- arms ---
	_arm_l = _limb(Vector3(-0.36, 1.18, 0), skin, 0.08, 0.5)
	_arm_r = _limb(Vector3(0.36, 1.18, 0), skin, 0.08, 0.5)
	add_child(_arm_l)
	add_child(_arm_r)

	# --- head ---
	_head = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.30
	sph.height = 0.60
	_head.mesh = sph
	_head.position = Vector3(0, 1.55, 0)
	_head.material_override = skin
	add_child(_head)
	# blush cheeks
	_add_sphere(_head, Vector3(-0.18, -0.05, -0.24), 0.06, blush)
	_add_sphere(_head, Vector3(0.18, -0.05, -0.24), 0.06, blush)
	# eyes (she faces away from the camera, but the face is visible on the map/shop)
	_add_sphere(_head, Vector3(-0.11, 0.03, -0.27), 0.035, dark)
	_add_sphere(_head, Vector3(0.11, 0.03, -0.27), 0.035, dark)
	# smile
	_add_box(_head, Vector3(0, -0.10, -0.28), Vector3(0.12, 0.02, 0.02), dark)

	# --- braids: 6 hanging braids + 2 buns ---
	for i in range(6):
		var ang: float = TAU * float(i) / 6.0
		var bx: float = cos(ang) * 0.24
		var bz: float = sin(ang) * 0.24
		var braid := MeshInstance3D.new()
		var bc := CapsuleMesh.new()
		bc.radius = 0.05
		bc.height = 0.42
		braid.mesh = bc
		braid.position = Vector3(bx, 1.32, bz)
		braid.material_override = hair
		add_child(braid)
		# bead at the tip
		var bead := MeshInstance3D.new()
		var bs := SphereMesh.new()
		bs.radius = 0.06
		bs.height = 0.12
		bead.mesh = bs
		bead.position = Vector3(bx, 1.10, bz)
		bead.material_override = _mat(Color.html("#ffd23f") if i % 2 == 0 else Color.html("#ff5c8a"))
		add_child(bead)
	_add_sphere(self, Vector3(-0.22, 1.82, 0), 0.11, hair)
	_add_sphere(self, Vector3(0.22, 1.82, 0), 0.11, hair)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.45
	return m


func _limb(pos: Vector3, mat: Material, radius: float, length: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = length
	mesh.mesh = cap
	mesh.position = Vector3(0, -length * 0.5, 0)
	mesh.material_override = mat
	pivot.add_child(mesh)
	return pivot


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _add_sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	mi.mesh = s
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## Apply an outfit from Boards.OUTFITS.
func set_outfit(outfit: Dictionary) -> void:
	_top_mat.albedo_color = Color.html(outfit.get("top", "#0e9b8a"))
	_bottom_mat.albedo_color = Color.html(outfit.get("bottom", "#ff5c8a"))
	_shoe_mat.albedo_color = Color.html(outfit.get("shoes", "#ffffff"))
	var cape_color: String = outfit.get("cape", "")
	if cape_color == "":
		_cape.visible = false
	else:
		_cape.visible = true
		_cape_mat.albedo_color = Color.html(cape_color)


## Run-cycle animation. Call every frame while running.
func animate_run(delta: float, speed: float) -> void:
	_bob_phase += delta * speed * 1.4
	var s: float = sin(_bob_phase)
	_arm_l.rotation.x = s * 0.9
	_arm_r.rotation.x = -s * 0.9
	_leg_l.rotation.x = -s * 0.8
	_leg_r.rotation.x = s * 0.8
	_body.position.y = 0.85 + absf(cos(_bob_phase)) * 0.06
	_head.position.y = 1.55 + absf(cos(_bob_phase)) * 0.06


## Tilt forward ~30 degrees while airborne (floaty jump).
func set_air_tilt(t: float) -> void:
	rotation.x = t


## Jump pose: arms up, legs tucked.
func set_jump_pose() -> void:
	_arm_l.rotation.x = -2.2
	_arm_r.rotation.x = -2.2
	_leg_l.rotation.x = 0.6
	_leg_r.rotation.x = -0.4


func reset_pose() -> void:
	rotation.x = 0.0
	_arm_l.rotation.x = 0.0
	_arm_r.rotation.x = 0.0
	_leg_l.rotation.x = 0.0
	_leg_r.rotation.x = 0.0
