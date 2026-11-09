class_name DijahCharacter
extends Node3D
## Dijah — the hero, built in real Blender (dijah.glb): smooth-shaded,
## glossy, braids + buns, teal top, pink skirt, candy sneakers.
## Runs away from the camera; bobs and swings arms/legs while running.
## The .glb has named pivot empties (ArmL/ArmR/LegL/LegR) and meshes
## (Body/Head/Top/Bottom/Shoes) so the run animation and outfits keep
## working exactly as before.

const DIJAH_SCENE: PackedScene = preload("res://models/dijah.glb")

var _model: Node3D
var _body: Node3D
var _head: Node3D
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
var _body_base_y: float = 0.85
var _head_base_y: float = 1.55


func _ready() -> void:
	_top_mat = _mat(Color.html("#0e9b8a"))
	_bottom_mat = _mat(Color.html("#ff5c8a"))
	_shoe_mat = _mat(Color.html("#ffffff"))
	_cape_mat = _mat(Color.html("#e60026"))

	_model = DIJAH_SCENE.instantiate()
	add_child(_model)
	_arm_l = _model.find_child("ArmL")
	_arm_r = _model.find_child("ArmR")
	_leg_l = _model.find_child("LegL")
	_leg_r = _model.find_child("LegR")
	_body = _model.find_child("Body")
	_head = _model.find_child("Head")
	if _body:
		_body_base_y = _body.position.y
	if _head:
		_head_base_y = _head.position.y
	# outfit colors onto the Blender meshes (by material name)
	_recolor("Top", _top_mat)
	_recolor("Bottom", _bottom_mat)
	_recolor("Shoes", _shoe_mat)

	# --- cape (hidden unless the outfit has one) ---
	_cape = MeshInstance3D.new()
	var cape_box := BoxMesh.new()
	cape_box.size = Vector3(0.5, 0.7, 0.03)
	_cape.mesh = cape_box
	_cape.position = Vector3(0, 0.85, 0.32)
	_cape.material_override = _cape_mat
	_cape.visible = false
	add_child(_cape)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.25
	return m


## Swap every surface whose imported material has the given name.
func _recolor(mat_name: String, mat: Material) -> void:
	_recolor_node(_model, mat_name, mat)


func _recolor_node(node: Node, mat_name: String, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var m: Material = mesh.surface_get_material(i)
				if m and m.resource_name == mat_name:
					mi.set_surface_override_material(i, mat)
	for c in node.get_children():
		_recolor_node(c, mat_name, mat)


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
	if _arm_l:
		_arm_l.rotation.x = s * 0.9
	if _arm_r:
		_arm_r.rotation.x = -s * 0.9
	if _leg_l:
		_leg_l.rotation.x = -s * 0.8
	if _leg_r:
		_leg_r.rotation.x = s * 0.8
	if _body:
		_body.position.y = _body_base_y + absf(cos(_bob_phase)) * 0.06
	if _head:
		_head.position.y = _head_base_y + absf(cos(_bob_phase)) * 0.06


## Tilt forward ~30 degrees while airborne (floaty jump).
func set_air_tilt(t: float) -> void:
	rotation.x = t


## Jump pose: arms up, legs tucked.
func set_jump_pose() -> void:
	if _arm_l:
		_arm_l.rotation.x = -2.2
	if _arm_r:
		_arm_r.rotation.x = -2.2
	if _leg_l:
		_leg_l.rotation.x = 0.6
	if _leg_r:
		_leg_r.rotation.x = -0.4


func reset_pose() -> void:
	rotation.x = 0.0
	if _arm_l:
		_arm_l.rotation.x = 0.0
	if _arm_r:
		_arm_r.rotation.x = 0.0
	if _leg_l:
		_leg_l.rotation.x = 0.0
	if _leg_r:
		_leg_r.rotation.x = 0.0
