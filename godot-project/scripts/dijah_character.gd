class_name DijahCharacter
extends Node3D
## Dijah — the hero, real Blender 3D model (dijah.glb) with named pivots
## (ArmL/ArmR/LegL/LegR) and meshes (Body/Head/Top/Bottom/Shoes/Hair).
##
## WHY THIS EXISTS: the Nov 11 "Pixar relief" build loaded its character
## pictures from an absolute Windows path on one PC
## (C:/Users/Dame/.gemini/antigravity/.../scratch/dijah_back_l.png etc).
## Those files were never put in the repo, so on a phone every load failed,
## the shader had no picture, and Dijah rendered as a blank white plane —
## a piece of paper. This version uses the .glb that is already in the repo
## (res://models/dijah.glb), so she is real 3D on every device.
##
## Same public API as the Nov 11 script, so game.gd / shop.gd /
## main_menu.gd work unchanged. Outfits recolor the named Blender
## materials (Hair / Top / Bottom / Shoes) instead of shader tints.
## NOTE: bottom_style (jeans/leggings) only changed the old PNG shader's
## leg drawing; the 3D model's bottoms are fixed geometry, so the style
## does not reshape the legs — the bottom color still applies.

const DIJAH_SCENE: PackedScene = preload("res://models/dijah.glb")

var _model: Node3D
var _body: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _shadow: MeshInstance3D
var _trail_root: Node3D
var _aura_root: Node3D
var _trail_particles: Array = []
var _aura_particles: Array = []
var _rush_active: bool = false
var _vfx_time: float = 0.0

var _hair_mat: StandardMaterial3D
var _top_mat: StandardMaterial3D
var _bottom_mat: StandardMaterial3D
var _shoe_mat: StandardMaterial3D
var _cape_mat: StandardMaterial3D
var _cape: MeshInstance3D

var _bob_phase: float = 0.0
var _lean_z: float = 0.0
var _squash: Vector3 = Vector3.ONE
var _body_base_y: float = 1.42
var _head_base_y: float = 1.92
var _is_jumping: bool = false
var _is_sliding: bool = false
var _is_showcase: bool = false


func _ready() -> void:
	_hair_mat = _mat(Color.html("#2b160c"))
	_top_mat = _mat(Color.html("#f49ac2"))
	_bottom_mat = _mat(Color.html("#4f6d9a"))
	_shoe_mat = _mat(Color.html("#f282b4"))
	_cape_mat = _mat(Color.html("#e60026"))

	_shadow = CandyMaterials.make_drop_shadow(0.68, 0.56)
	add_child(_shadow)

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
	_recolor("Hair", _hair_mat)
	_recolor("Top", _top_mat)
	_recolor("Bottom", _bottom_mat)
	_recolor("Shoes", _shoe_mat)

	# --- cape (hidden unless the outfit has one) ---
	_cape = MeshInstance3D.new()
	var cape_box := BoxMesh.new()
	cape_box.size = Vector3(0.42, 0.62, 0.03)
	_cape.mesh = cape_box
	_cape.position = Vector3(0, 1.50, 0.28)
	_cape.material_override = _cape_mat
	_cape.visible = false
	add_child(_cape)

	# --- 3D Sneaker Sparkle & Sugar-Dust Trail (OpenGL 3 Compatible Mesh Pool) ---
	_trail_root = Node3D.new()
	add_child(_trail_root)
	var sp_colors := ["#ff6ca8", "#ffd54f", "#5fe8d2", "#68c8ff", "#ffffff"]
	var sp_mesh := SphereMesh.new()
	sp_mesh.radius = 0.048
	sp_mesh.height = 0.096
	for i in range(16):
		var mi := MeshInstance3D.new()
		mi.mesh = sp_mesh
		mi.material_override = CandyMaterials.mat(sp_colors[i % sp_colors.size()], 0.15, true)
		_trail_root.add_child(mi)
		_trail_particles.append({"node": mi, "phase": float(i) / 16.0, "side": -1.0 if i % 2 == 0 else 1.0})

	# --- 3D Sugar Rush Rainbow Aura Swirl (Orbiting 3D Candy Stars/Gems) ---
	_aura_root = Node3D.new()
	_aura_root.visible = false
	add_child(_aura_root)
	var aura_mesh := SphereMesh.new()
	aura_mesh.radius = 0.058
	aura_mesh.height = 0.116
	for j in range(12):
		var ami := MeshInstance3D.new()
		ami.mesh = aura_mesh
		ami.material_override = CandyMaterials.mat(sp_colors[j % sp_colors.size()], 0.12, true)
		_aura_root.add_child(ami)
		_aura_particles.append({"node": ami, "idx": j})


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


## Apply an outfit or modular look dictionary {hair, top, bottom, shoes, cape}.
func set_outfit(outfit: Dictionary) -> void:
	_hair_mat.albedo_color = Color.html(outfit.get("hair", "#2b160c"))
	_top_mat.albedo_color = Color.html(outfit.get("top", "#f49ac2"))
	_bottom_mat.albedo_color = Color.html(outfit.get("bottom", "#4f6d9a"))
	_shoe_mat.albedo_color = Color.html(outfit.get("shoes", "#f282b4"))
	var cape_color: String = outfit.get("cape", "")
	if cape_color == "":
		_cape.visible = false
	else:
		_cape.visible = true
		_cape_mat.albedo_color = Color.html(cape_color)


## Update 3D ground shadow & lateral steering lean.
func update_ground_shadow(player_y: float, steer_vel: float, delta: float) -> void:
	if _shadow:
		_shadow.position = Vector3(0, -player_y + 0.03, 0)
		var s_scale: float = clampf(1.0 - player_y * 0.28, 0.35, 1.0)
		_shadow.scale = Vector3(s_scale, 1.0, s_scale)
	_lean_z = lerpf(_lean_z, clampf(-steer_vel * 0.08, -0.20, 0.20), delta * 10.0)
	if not _is_sliding:
		_squash = _squash.lerp(Vector3.ONE, delta * 12.0)
	if _model:
		_model.rotation.z = _lean_z
		_model.scale = _squash


## Trigger squash/stretch impulse on jump or landing.
func trigger_squash(scale_vec: Vector3) -> void:
	_squash = scale_vec


## Run-cycle animation: swinging arms/legs, bobbing body, trail sparkles.
## Call every frame while running.
func animate_run(delta: float, speed: float) -> void:
	if _is_sliding:
		_vfx_time += delta
		if _trail_root:
			_trail_root.visible = true
			for item in _trail_particles:
				var mi: MeshInstance3D = item["node"]
				var ph: float = fmod(float(item["phase"]) + _vfx_time * 3.5, 1.0)
				var side: float = float(item["side"])
				mi.position = Vector3(side * 0.35 + sin(ph * 12.0) * 0.08, 0.05 + sin(ph * PI) * 0.15, 0.2 + ph * 1.8)
				var sc: float = (1.0 - ph * 0.75) * 1.3
				mi.scale = Vector3(sc, sc, sc)
		return
	_is_jumping = false
	_is_showcase = false
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
	_vfx_time += delta
	if _trail_root:
		_trail_root.visible = true
		for item in _trail_particles:
			var mi: MeshInstance3D = item["node"]
			var ph: float = fmod(float(item["phase"]) + _vfx_time * 2.4, 1.0)
			var side: float = float(item["side"])
			mi.position = Vector3(side * (0.14 + ph * 0.22) + sin(ph * 9.0 + side) * 0.06, 0.08 + sin(ph * PI) * 0.34, 0.15 + ph * 1.65)
			var sc: float = (1.0 - ph * 0.85) * 1.15
			mi.scale = Vector3(sc, sc, sc)
	if _aura_root and _rush_active:
		_aura_root.visible = true
		for aitem in _aura_particles:
			var ami: MeshInstance3D = aitem["node"]
			var idx: int = int(aitem["idx"])
			var ang: float = _vfx_time * 5.2 + float(idx) * TAU / 12.0
			var h_t: float = fmod(float(idx) / 12.0 + _vfx_time * 1.1, 1.0)
			var rad: float = 0.48 + sin(h_t * PI) * 0.16
			ami.position = Vector3(cos(ang) * rad, 0.35 + h_t * 1.35, sin(ang) * 0.25 + 0.12)
			var asc: float = sin(h_t * PI) * 1.25
			ami.scale = Vector3(asc, asc, asc)


func set_rush_aura(active: bool) -> void:
	_rush_active = active
	if _aura_root:
		_aura_root.visible = active


## Confident hands-on-hips Pixar hero pose for Main Menu and Outfit Shop.
func animate_idle(delta: float) -> void:
	_is_showcase = true
	_is_jumping = false
	_bob_phase += delta * 2.2
	var s: float = sin(_bob_phase)
	var c: float = cos(_bob_phase * 2.0)
	# Note: in main_menu.gd and shop.gd, Dijah is rotated by Y = PI so her
	# front faces the camera (+Z). Swaying the inner model keeps that.
	if _model:
		_model.rotation.y = s * 0.04
		_model.rotation.z = s * 0.015
	if _body:
		_body.position.y = _body_base_y + c * 0.014
	if _head:
		_head.position.y = _head_base_y + c * 0.014
	if _trail_root:
		_trail_root.visible = false
	if _aura_root:
		_aura_root.visible = false


func set_air_tilt(t: float) -> void:
	if _model:
		_model.rotation.x = clampf(t * 0.25, -0.18, 0.18)


## Jump pose: arms up, legs tucked.
func set_jump_pose() -> void:
	_is_jumping = true
	_is_sliding = false
	if _arm_l:
		_arm_l.rotation.x = -2.2
	if _arm_r:
		_arm_r.rotation.x = -2.2
	if _leg_l:
		_leg_l.rotation.x = 0.6
	if _leg_r:
		_leg_r.rotation.x = -0.4


## Slide pose: low, tilted forward, squashed — duck under the bar.
func set_slide_pose() -> void:
	_is_sliding = true
	_is_jumping = false
	if _leg_l:
		_leg_l.rotation.x = 0.9
	if _leg_r:
		_leg_r.rotation.x = 0.9
	if _arm_l:
		_arm_l.rotation.x = 0.6
	if _arm_r:
		_arm_r.rotation.x = 0.6
	if _model:
		_model.position.y = -0.48
		_model.rotation.x = -0.55
		_model.scale = Vector3(1.15, 0.58, 1.25)


func reset_pose() -> void:
	_is_jumping = false
	_is_sliding = false
	rotation.x = 0.0
	if _model:
		_model.rotation = Vector3.ZERO
		_model.position = Vector3.ZERO
		_model.scale = Vector3.ONE
	_squash = Vector3.ONE
	if _arm_l:
		_arm_l.rotation.x = 0.0
	if _arm_r:
		_arm_r.rotation.x = 0.0
	if _leg_l:
		_leg_l.rotation.x = 0.0
	if _leg_r:
		_leg_r.rotation.x = 0.0
