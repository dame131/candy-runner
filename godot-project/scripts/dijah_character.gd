class_name DijahCharacter
extends Node3D
## Dijah — Pixar 3D Character Rig powered directly by the high-resolution Pixar
## character renders (`dijah_back_l.png`, `dijah_back_mid.png`, `dijah_back_r.png`,
## `dijah_front.png`, `dijah_jump.png`) on a curved 3D relief mesh with real-time
## 3D directional lighting, sun shadow casting, dynamic running stride animation,
## and outfit color shifting.

var _model: Node3D
var _mesh_inst: MeshInstance3D
var _shadow: MeshInstance3D
var _mat: ShaderMaterial
var _trail_root: Node3D
var _aura_root: Node3D
var _trail_particles: Array = []
var _aura_particles: Array = []
var _rush_active: bool = false
var _vfx_time: float = 0.0

var _tex_back_l: Texture2D
var _tex_back_mid: Texture2D
var _tex_back_r: Texture2D
var _tex_front: Texture2D
var _tex_jump: Texture2D

var _bob_phase: float = 0.0
var _lean_z: float = 0.0
var _squash: Vector3 = Vector3.ONE
var _is_jumping: bool = false
var _is_sliding: bool = false
var _is_showcase: bool = false


var _tex_dir: String = "res://textures/char/"

func _ready() -> void:
	_tex_back_l = _load_tex(_tex_dir + "dijah_back_l.png")
	_tex_back_mid = _load_tex(_tex_dir + "dijah_back_mid.png")
	_tex_back_r = _load_tex(_tex_dir + "dijah_back_r.png")
	_tex_front = _load_tex(_tex_dir + "dijah_front.png")
	_tex_jump = _load_tex(_tex_dir + "dijah_jump.png")

	_shadow = CandyMaterials.make_drop_shadow(0.68, 0.56)
	add_child(_shadow)

	_model = Node3D.new()
	add_child(_model)

	_build_pixar_3d_rig()


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			return ImageTexture.create_from_image(img)
	return null


func _build_pixar_3d_rig() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.mesh = _build_curved_relief_mesh(1.42, 1.92, 24, 32)
	_mesh_inst.position = Vector3(0.0, 0.96, 0.0)
	_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED

	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D char_tex : source_color, filter_linear_mipmap;
uniform vec4 hair_target_col : source_color = vec4(0.169, 0.086, 0.047, 1.0);
uniform vec4 top_target_col : source_color = vec4(0.957, 0.604, 0.761, 1.0);
uniform vec4 bot_target_col : source_color = vec4(0.310, 0.427, 0.604, 1.0);
uniform vec4 shoe_target_col : source_color = vec4(0.949, 0.510, 0.706, 1.0);
uniform float hair_tint_strength = 0.0;
uniform float top_tint_strength = 0.0;
uniform float bot_tint_strength = 0.0;
uniform float shoe_tint_strength = 0.0;
uniform int bottom_style_mode = 0; // 0 = shorts, 1 = full-length jeans, 2 = full-length leggings
uniform float run_stride_skew = 0.0;

void vertex() {
	// Subtle 3D running torso & stride depth motion
	float y_norm = clamp(1.0 - UV.y, 0.0, 1.0);
	VERTEX.x += sin(y_norm * 3.14159) * run_stride_skew * 0.025;
	VERTEX.z += (UV.x - 0.5) * run_stride_skew * 0.06;
}

void fragment() {
	float u_coord = (FRONT_FACING) ? UV.x : (1.0 - UV.x);
	vec2 uv = vec2(u_coord, UV.y);
	vec4 tex = texture(char_tex, uv);
	if (tex.a < 0.35) {
		discard;
	}
	vec3 col = tex.rgb;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));

	// 1. Hair Recoloring (UV.y < 0.28, dark coily hair puffs while preserving colorful rainbow beads/clips)
	if (hair_tint_strength > 0.01 && uv.y < 0.28) {
		float max_c = max(col.r, max(col.g, col.b));
		float min_c = min(col.r, min(col.g, col.b));
		float sat = max_c - min_c;
		// Hair curls are dark/low-luminance (lum < 0.36) and not high-saturation rainbow beads
		if (lum < 0.38 && sat < 0.26) {
			vec3 tinted_hair = hair_target_col.rgb * (0.35 + 1.55 * lum);
			col = mix(col, tinted_hair, hair_tint_strength * 0.88);
		}
	}

	// 2. Top Recoloring (Cropped Hoodie / Jacket / Top in UV.y 0.25..0.53)
	float pinkness = clamp((col.r - col.g - 0.04) * 6.0, 0.0, 1.0);
	if (top_tint_strength > 0.01 && uv.y > 0.25 && uv.y < 0.53 && pinkness > 0.12) {
		vec3 tinted_top = top_target_col.rgb * (0.42 + 0.78 * lum);
		col = mix(col, tinted_top, pinkness * top_tint_strength * 0.90);
	}

	// 3. Bottom Recoloring & Style (0 = Shorts, 1 = Full-Length Jeans, 2 = Full-Length Leggings)
	float blueness = clamp((col.b - col.r - 0.02) * 5.5, 0.0, 1.0);
	if (uv.y > 0.44 && uv.y < 0.70 && blueness > 0.12) {
		if (bot_tint_strength > 0.01 || bottom_style_mode > 0) {
			vec3 tinted_bot = bot_target_col.rgb * (0.42 + 0.82 * lum);
			col = mix(col, tinted_bot, max(bot_tint_strength, float(bottom_style_mode)) * 0.90);
		}
	}
	// If Jeans (mode 1) or Leggings (mode 2) are equipped, extend the pants down Dijah's legs (UV.y 0.56..0.855) above her white crew socks!
	if (bottom_style_mode > 0 && uv.y >= 0.56 && uv.y < 0.855) {
		// Detect warm brown leg skin (R > G > B, not white socks or pink shoes)
		float skin_mask = clamp((col.r - col.g - 0.06) * 7.0, 0.0, 1.0) * clamp((col.g - col.b - 0.03) * 7.0, 0.0, 1.0) * step(col.r, 0.84);
		if (skin_mask > 0.15) {
			vec3 pant_col = bot_target_col.rgb * (0.38 + 0.95 * lum);
			if (bottom_style_mode == 1) {
				// Subtle vertical denim weave + side seam highlight for Jeans
				float weave = sin(uv.x * 420.0 + uv.y * 420.0) * 0.025;
				pant_col += vec3(weave);
			} else {
				// Sleek athletic sheen for Leggings
				pant_col = mix(pant_col, pant_col * 1.12, smoothstep(0.45, 0.68, lum));
			}
			col = mix(col, pant_col, skin_mask * 0.95);
		}
	}

	// 4. Flat Athletic Shoes Recoloring (UV.y > 0.72)
	if (shoe_tint_strength > 0.01 && uv.y > 0.72 && pinkness > 0.12) {
		vec3 tinted_shoe = shoe_target_col.rgb * (0.42 + 0.78 * lum);
		col = mix(col, tinted_shoe, pinkness * shoe_tint_strength * 0.90);
	}

	// Preserve 88% of the rich Pixar subsurface lighting baked in the render + 12% live 3D scene sun shading
	ALBEDO = col * 0.24;
	EMISSION = col * 0.78;
	ROUGHNESS = 0.42;
	SPECULAR = 0.18;
}
"""
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	var initial_tex: Texture2D = _tex_back_mid if _tex_back_mid != null else _tex_back_l
	if initial_tex == null:
		initial_tex = _tex_front
	_mat.set_shader_parameter("char_tex", initial_tex)
	_mesh_inst.material_override = _mat
	_model.add_child(_mesh_inst)

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


func _build_curved_relief_mesh(w: float, h: float, segs_x: int, segs_y: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for iy in range(segs_y + 1):
		var v: float = float(iy) / float(segs_y)
		var py: float = (0.5 - v) * h
		for ix in range(segs_x + 1):
			var u: float = float(ix) / float(segs_x)
			var px: float = (u - 0.5) * w
			# Gentle cylindrical 3D relief curve so Dijah catches 3D directional lighting & casts a full 3D shadow
			var nx_val: float = (u - 0.5) * 2.0
			var pz: float = (1.0 - nx_val * nx_val) * 0.085
			var nrm := Vector3(nx_val * 0.28, 0.06, 1.0).normalized()
			st.set_normal(nrm)
			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3(px, py, pz))

	var stride: int = segs_x + 1
	for iy in range(segs_y):
		for ix in range(segs_x):
			var i00: int = iy * stride + ix
			var i10: int = i00 + 1
			var i01: int = (iy + 1) * stride + ix
			var i11: int = i01 + 1
			st.add_index(i00)
			st.add_index(i10)
			st.add_index(i01)
			st.add_index(i10)
			st.add_index(i11)
			st.add_index(i01)

	return st.commit()


## Apply an outfit or modular look dictionary {hair, top, bottom, bottom_style, shoes}.
func set_outfit(outfit: Dictionary) -> void:
	if _mat == null:
		return
	var hair_hex: String = outfit.get("hair", "#2b160c")
	var top_hex: String = outfit.get("top", "#f49ac2")
	var bot_hex: String = outfit.get("bottom", "#4f6d9a")
	var shoe_hex: String = outfit.get("shoes", "#f282b4")
	var b_style: String = outfit.get("bottom_style", "shorts")

	_mat.set_shader_parameter("hair_target_col", Color.html(hair_hex))
	_mat.set_shader_parameter("top_target_col", Color.html(top_hex))
	_mat.set_shader_parameter("bot_target_col", Color.html(bot_hex))
	_mat.set_shader_parameter("shoe_target_col", Color.html(shoe_hex))

	var h_tint: float = float(outfit.get("hair_tint", 0.0 if hair_hex == "#2b160c" else 0.85))
	var t_tint: float = float(outfit.get("top_tint", 0.0 if top_hex == "#f49ac2" else 1.0))
	var b_tint: float = float(outfit.get("bottom_tint", 0.0 if bot_hex == "#4f6d9a" else 1.0))
	var s_tint: float = float(outfit.get("shoe_tint", 0.0 if shoe_hex == "#f282b4" else 1.0))

	_mat.set_shader_parameter("hair_tint_strength", h_tint)
	_mat.set_shader_parameter("top_tint_strength", t_tint)
	_mat.set_shader_parameter("bot_tint_strength", b_tint)
	_mat.set_shader_parameter("shoe_tint_strength", s_tint)

	var mode_int: int = 0
	if b_style == "jeans":
		mode_int = 1
	elif b_style == "leggings":
		mode_int = 2
	_mat.set_shader_parameter("bottom_style_mode", mode_int)


## Update 3D ground shadow & lateral steering lean.
func update_ground_shadow(player_y: float, steer_vel: float, delta: float) -> void:
	if _shadow:
		_shadow.position = Vector3(0, -player_y + 0.03, 0)
		var s_scale: float = clampf(1.0 - player_y * 0.28, 0.35, 1.0)
		_shadow.scale = Vector3(s_scale, 1.0, s_scale)
	_lean_z = lerpf(_lean_z, clampf(-steer_vel * 0.08, -0.20, 0.20), delta * 10.0)
	_squash = _squash.lerp(Vector3.ONE, delta * 12.0)
	if _model:
		_model.rotation.z = _lean_z
		_model.scale = _squash


## Trigger squash/stretch impulse on jump or landing.
func trigger_squash(scale_vec: Vector3) -> void:
	_squash = scale_vec


## Athletic 3-frame Pixar run-cycle with vertical bounce, hip sway & 3D stride relief!
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
	_bob_phase += delta * speed * 1.15
	var s: float = sin(_bob_phase)
	var c: float = cos(_bob_phase * 2.0)

	if _mat:
		if s > 0.28:
			_mat.set_shader_parameter("char_tex", _tex_back_l)
		elif s < -0.28:
			_mat.set_shader_parameter("char_tex", _tex_back_r)
		else:
			_mat.set_shader_parameter("char_tex", _tex_back_mid)
		_mat.set_shader_parameter("run_stride_skew", s)

	if _mesh_inst:
		_mesh_inst.position.y = 0.96 + absf(sin(_bob_phase)) * 0.055
		_mesh_inst.rotation.z = -s * 0.028
		_mesh_inst.rotation.y = s * 0.045
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

	if _mat and _tex_front != null:
		# Note: in main_menu.gd and shop.gd, Dijah is rotated by Y = PI so her front faces the camera (+Z).
		# Rotating the mesh by Y = PI inside _mesh_inst ensures UV.x is un-mirrored facing the camera!
		_mat.set_shader_parameter("char_tex", _tex_front)
		_mat.set_shader_parameter("run_stride_skew", 0.0)

	if _mesh_inst:
		_mesh_inst.rotation.y = s * 0.04
		_mesh_inst.position.y = 0.96 + c * 0.014
		_mesh_inst.rotation.z = s * 0.015
	if _trail_root:
		_trail_root.visible = false
	if _aura_root:
		_aura_root.visible = false


func set_air_tilt(t: float) -> void:
	if _model:
		_model.rotation.x = clampf(t * 0.25, -0.18, 0.18)


func set_jump_pose() -> void:
	_is_jumping = true
	_is_sliding = false
	# Preserve seamless back running view during leap — no front-facing turnaround image switch!
	if _mat and _tex_back_mid != null:
		_mat.set_shader_parameter("char_tex", _tex_back_mid)
		_mat.set_shader_parameter("run_stride_skew", 0.0)
	if _mesh_inst:
		# Athletic 3D jump tuck & elevation
		_mesh_inst.position.y = 1.04
		_mesh_inst.scale = Vector3(0.94, 1.12, 0.94)


func set_slide_pose() -> void:
	_is_sliding = true
	_is_jumping = false
	if _mat and _tex_back_mid != null:
		_mat.set_shader_parameter("char_tex", _tex_back_mid)
		_mat.set_shader_parameter("run_stride_skew", 0.0)
	if _mesh_inst:
		_mesh_inst.position.y = 0.48
		_mesh_inst.rotation.x = -0.55
		_mesh_inst.scale = Vector3(1.15, 0.58, 1.25)


func reset_pose() -> void:
	_is_jumping = false
	_is_sliding = false
	rotation.x = 0.0
	if _model:
		_model.rotation = Vector3.ZERO
	if _mesh_inst:
		_mesh_inst.rotation = Vector3.ZERO
		_mesh_inst.position = Vector3(0.0, 0.96, 0.0)
		_mesh_inst.scale = Vector3.ONE
	if _mat:
		var r_tex: Texture2D = _tex_back_mid if _tex_back_mid != null else _tex_back_l
		if r_tex != null:
			_mat.set_shader_parameter("char_tex", r_tex)
		_mat.set_shader_parameter("run_stride_skew", 0.0)
