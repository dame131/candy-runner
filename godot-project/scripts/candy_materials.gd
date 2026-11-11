class_name CandyMaterials
extends RefCounted
## Pixar/Nintendo-grade 3D Candy & Waffle Shader Library for Dijah's Delights Candy Run.
## Includes:
## - Sculpted 3D Belgian Waffle shader with beveled pockets & warm toasted bake gradient
## - Helical 3D Peppermint Candy-Cane stripe shader
## - Subsurface Scattering (SSS) Gummy & Frosting studio shader
## - Swirled Cocoa-Dusted Chocolate Truffle shader
## - Bubbly Strawberry-Milkshake 3D Ocean shader

static var _cache: Dictionary = {}
static var _candy_shader: Shader = null
static var _waffle_shader: Shader = null
static var _cane_shader: Shader = null
static var _truffle_shader: Shader = null
static var _sea_shader: Shader = null
static var _afro_shader: Shader = null
static var _sleek_hair_shader: Shader = null
static var _denim_shader: Shader = null
static var _shadow_mat: StandardMaterial3D = null


static func get_afro_hair_material() -> ShaderMaterial:
	var key := "afro_curls_v1"
	if _cache.has(key):
		return _cache[key]
	if _afro_shader == null:
		_afro_shader = Shader.new()
		_afro_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 v_local_pos;
varying vec3 v_world_normal;

float hash3(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

float curl_field(vec3 p) {
	// Multi-frequency 3D coily/curly Afro puff displacement
	float c1 = sin(p.x * 52.0 + cos(p.y * 48.0) * 1.8) * cos(p.z * 52.0 + sin(p.x * 48.0) * 1.8);
	float c2 = sin(p.y * 95.0 - p.z * 85.0) * cos(p.x * 90.0 + p.y * 75.0) * 0.5;
	float c3 = sin(p.x * 160.0 + p.y * 160.0 + p.z * 160.0) * 0.25;
	return (c1 + c2 + c3) / 1.75;
}

void vertex() {
	v_local_pos = VERTEX;
	float cf = curl_field(VERTEX);
	// Softly displace the high-res puff silhouette into hundreds of natural curls!
	VERTEX += NORMAL * cf * 0.014;
	v_world_normal = normalize((MODEL_NORMAL_MATRIX * NORMAL));
}

void fragment() {
	float cf = curl_field(v_local_pos);
	float micro = hash3(floor(v_local_pos * 220.0));
	vec3 root_col = vec3(0.05, 0.03, 0.025);
	vec3 tip_col = vec3(0.16, 0.095, 0.075);
	vec3 col = mix(root_col, tip_col, smoothstep(-0.6, 0.7, cf) * 0.75 + micro * 0.25);

	// Perturb normal for coily hair strand depth
	vec3 n_off = vec3(
		cos(v_local_pos.x * 110.0 + v_local_pos.y * 80.0),
		sin(v_local_pos.y * 110.0 + v_local_pos.z * 80.0),
		cos(v_local_pos.z * 110.0 - v_local_pos.x * 80.0)
	) * 0.22;
	NORMAL = normalize(NORMAL + n_off);

	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - ndotv, 3.5) * 0.08;

	ALBEDO = col + vec3(rim * 1.2, rim * 0.8, rim * 0.6);
	ROUGHNESS = 0.78;
	METALLIC = 0.0;
	SPECULAR = 0.18;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _afro_shader
	_cache[key] = sm
	return sm


static func get_sleek_hair_material() -> ShaderMaterial:
	var key := "sleek_hair_v1"
	if _cache.has(key):
		return _cache[key]
	if _sleek_hair_shader == null:
		_sleek_hair_shader = Shader.new()
		_sleek_hair_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	// Fine brushed hair strands radiating from the center part toward the puffs
	float strand = sin(v_local_pos.y * 260.0 + abs(v_local_pos.x) * 180.0 + sin(v_local_pos.z * 90.0) * 2.0);
	vec3 dark_hair = vec3(0.06, 0.035, 0.03);
	vec3 sheen_hair = vec3(0.18, 0.11, 0.09);
	vec3 col = mix(dark_hair, sheen_hair, smoothstep(-0.3, 0.8, strand) * 0.45);
	ALBEDO = col;
	ROUGHNESS = 0.46;
	SPECULAR = 0.38;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _sleek_hair_shader
	_cache[key] = sm
	return sm


static func get_denim_material(base_col: Color) -> ShaderMaterial:
	var key := "denim_" + base_col.to_html(false)
	if _cache.has(key):
		return _cache[key]
	if _denim_shader == null:
		_denim_shader = Shader.new()
		_denim_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 denim_color : source_color = vec4(0.31, 0.44, 0.62, 1.0);

varying vec3 v_local_pos;
varying vec3 v_local_normal;

void vertex() {
	v_local_pos = VERTEX;
	v_local_normal = NORMAL;
}

void fragment() {
	vec3 base = denim_color.rgb;
	// 1. Diagonal twill denim fabric weave
	float weave = sin((v_local_pos.x + v_local_pos.y) * 280.0) * cos((v_local_pos.x - v_local_pos.y + v_local_pos.z) * 280.0);
	// 2. Soft stone-washed fade on the center glutes and front thighs
	float wash = smoothstep(0.03, 0.11, abs(v_local_pos.x)) * (1.0 - smoothstep(0.11, 0.16, abs(v_local_pos.x)));
	vec3 col = base * (0.94 + weave * 0.04 + wash * 0.14);

	// 3. Back denim details (+Z is back of shorts)
	if (v_local_normal.z > 0.15) {
		float ax = abs(v_local_pos.x);
		float py = v_local_pos.y;
		// Center vertical back seam
		float center_seam = 1.0 - smoothstep(0.0, 0.0045, ax);
		// Curved back yoke seam near top of shorts
		float yoke_y = -0.105 - ax * 0.12;
		float yoke_seam = 1.0 - smoothstep(0.0, 0.004, abs(py - yoke_y));

		// Sculpted back patch pockets (centered at x = +-0.072, y = -0.165)
		float px = ax - 0.072;
		float p_top = -0.128;
		float p_bot = -0.205 + abs(px) * 0.22;
		float in_pocket_x = 1.0 - smoothstep(0.038, 0.041, abs(px));
		float in_pocket_y = step(p_bot, py) * step(py, p_top);
		float in_pocket = in_pocket_x * in_pocket_y;

		// Pocket border & golden topstitching
		float edge_x = smoothstep(0.034, 0.038, abs(px)) * (1.0 - smoothstep(0.038, 0.042, abs(px))) * in_pocket_y;
		float edge_top = (1.0 - smoothstep(0.0, 0.004, abs(py - p_top))) * in_pocket_x;
		float edge_bot = (1.0 - smoothstep(0.0, 0.004, abs(py - p_bot))) * in_pocket_x;
		float pocket_edge = clamp(edge_x + edge_top + edge_bot, 0.0, 1.0);

		col = mix(col, col * 0.88, in_pocket * 0.65);
		col = mix(col, col * 0.68, clamp(center_seam + yoke_seam, 0.0, 1.0));

		// Golden-tan dashed stitching thread along seams and pockets
		float stitch_dash = step(0.2, sin((py + ax) * 380.0));
		vec3 gold_thread = vec3(0.86, 0.68, 0.36);
		col = mix(col, gold_thread, pocket_edge * stitch_dash * 0.75);
	}

	ALBEDO = clamp(col, vec3(0.0), vec3(0.95));
	ROUGHNESS = 0.68;
	METALLIC = 0.0;
	SPECULAR = 0.18;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _denim_shader
	sm.set_shader_parameter("denim_color", base_col)
	_cache[key] = sm
	return sm


static func get_candy_shader() -> Shader:
	if _candy_shader != null:
		return _candy_shader
	_candy_shader = Shader.new()
	_candy_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(1.0, 0.36, 0.54, 1.0);
uniform float roughness : hint_range(0.02, 1.0) = 0.22;
uniform float metallic : hint_range(0.0, 1.0) = 0.02;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.35;
uniform float sss_strength : hint_range(0.0, 1.0) = 0.30;
uniform float emission_strength : hint_range(0.0, 3.0) = 0.0;
uniform float bump_scale : hint_range(0.0, 1.0) = 0.0;
uniform bool use_vertex_color = false;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_NORMAL_MATRIX * NORMAL));
}

void fragment() {
	vec3 base = albedo_color.rgb;
	if (use_vertex_color) {
		base *= COLOR.rgb;
	}

	// Warm hemisphere + key light wrap for smooth Pixar-style 3D form
	float up_dot = clamp(v_world_normal.y, -1.0, 1.0);
	float sun_wrap = clamp(dot(v_world_normal, normalize(vec3(0.45, 0.78, 0.42))) * 0.5 + 0.5, 0.0, 1.0);
	vec3 warm_light = mix(vec3(0.70, 0.58, 0.64), vec3(0.96, 0.94, 0.92), sun_wrap);
	float ao = mix(0.76, 0.98, clamp(up_dot * 0.5 + 0.5, 0.0, 1.0));

	// Subsurface scattering warmth (translucent gummy / skin / frosting glow)
	vec3 sss_col = pow(max(base, vec3(0.001)), vec3(0.88)) * vec3(1.04, 0.94, 0.92);
	vec3 final_albedo = mix(base, sss_col, sss_strength * 0.45 * (1.0 - sun_wrap * 0.5)) * warm_light * ao;

	// Subtle grazing Fresnel rim (avoid blowing out highlights in OpenGL Compatibility)
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 4.5);
	vec3 rim_col = base * fresnel * rim_strength * 0.12;

	ALBEDO = clamp(final_albedo, vec3(0.0), vec3(0.95));
	ROUGHNESS = clamp(roughness, 0.18, 0.95);
	METALLIC = metallic;
	SPECULAR = 0.35;
	EMISSION = base * emission_strength * 0.35 + rim_col;
}
"""
	return _candy_shader


static func get_waffle_material(ridge_col: Color, pocket_col: Color) -> ShaderMaterial:
	var key := "waffle_" + ridge_col.to_html(false) + "_" + pocket_col.to_html(false)
	if _cache.has(key):
		return _cache[key]
	if _waffle_shader == null:
		_waffle_shader = Shader.new()
		_waffle_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 ridge_color : source_color = vec4(0.95, 0.72, 0.38, 1.0);
uniform vec4 pocket_color : source_color = vec4(0.68, 0.38, 0.14, 1.0);

varying vec3 v_local_pos;
varying vec3 v_world_normal;

void vertex() {
	v_local_pos = VERTEX;
	v_world_normal = normalize((MODEL_NORMAL_MATRIX * NORMAL));
}

void fragment() {
	// Rich golden-baked Belgian waffle gradient + fine biscuit grain
	float grain = sin(v_local_pos.x * 65.0) * cos(v_local_pos.z * 65.0) * 0.022;
	float height_t = clamp((v_local_pos.y + 0.034) / 0.080, 0.0, 1.0);
	float side_t = clamp(abs(v_world_normal.y), 0.0, 1.0);
	vec3 col = mix(pocket_color.rgb * 0.82, ridge_color.rgb * 0.88, clamp(height_t * 0.72 + side_t * 0.28, 0.0, 1.0));
	col += vec3(grain);

	ALBEDO = clamp(col, vec3(0.0), vec3(0.92));
	ROUGHNESS = mix(0.65, 0.48, side_t);
	METALLIC = 0.0;
	SPECULAR = 0.22;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _waffle_shader
	sm.set_shader_parameter("ridge_color", ridge_col)
	sm.set_shader_parameter("pocket_color", pocket_col)
	_cache[key] = sm
	return sm


static func get_candy_cane_material(stripe_hex: String = "#e61938") -> ShaderMaterial:
	var key := "cane_" + stripe_hex
	if _cache.has(key):
		return _cache[key]
	if _cane_shader == null:
		_cane_shader = Shader.new()
		_cane_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 stripe_color : source_color = vec4(0.90, 0.10, 0.22, 1.0);
uniform vec4 white_color : source_color = vec4(0.99, 0.98, 0.97, 1.0);

varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	float angle = atan(v_local_pos.x, v_local_pos.z);
	float wave = sin((v_local_pos.y + v_local_pos.z) * 14.0 + angle * 2.0);
	float mask = smoothstep(-0.08, 0.08, wave);
	vec3 col = mix(white_color.rgb, stripe_color.rgb, mask);
	ALBEDO = col;
	ROUGHNESS = 0.12;
	SPECULAR = 0.88;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _cane_shader
	sm.set_shader_parameter("stripe_color", Color.html(stripe_hex))
	_cache[key] = sm
	return sm


static func get_truffle_material() -> ShaderMaterial:
	var key := "truffle_choc"
	if _cache.has(key):
		return _cache[key]
	if _truffle_shader == null:
		_truffle_shader = Shader.new()
		_truffle_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 v_local_pos;
varying vec3 v_local_normal;

void vertex() {
	v_local_pos = VERTEX;
	v_local_normal = NORMAL;
}

void fragment() {
	vec3 dark_choc = vec3(0.24, 0.11, 0.05);
	vec3 milk_choc = vec3(0.38, 0.18, 0.09);
	vec3 cocoa_dust = vec3(0.52, 0.28, 0.14);

	float swirl = sin(v_local_pos.x * 9.0 + v_local_pos.y * 6.0 + sin(v_local_pos.z * 8.0) * 1.5);
	vec3 base = mix(dark_choc, milk_choc, smoothstep(-0.4, 0.6, swirl));

	// Cocoa powder dusting on the top hemisphere (just like the mockup!)
	float top_mask = smoothstep(0.15, 0.75, v_local_normal.y + swirl * 0.15);
	float grain = fract(sin(dot(v_local_pos.xz * 40.0, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 final_col = mix(base, cocoa_dust, top_mask * (0.65 + grain * 0.35));

	// Sculpted swirl normal perturbation
	NORMAL = normalize(NORMAL + vec3(cos(swirl * 3.0) * 0.12, 0.0, sin(swirl * 3.0) * 0.12));
	ALBEDO = final_col;
	ROUGHNESS = mix(0.22, 0.68, top_mask);
	SPECULAR = 0.65;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _truffle_shader
	_cache[key] = sm
	return sm


static func mat(color_hex: String, rough: float = 0.20, glow: bool = false, vcol: bool = false, sss: float = 0.28, bump: float = 0.0) -> ShaderMaterial:
	var key: String = "%s_%.2f_%s_%s_%.2f_%.2f" % [color_hex, rough, str(glow), str(vcol), sss, bump]
	if _cache.has(key):
		return _cache[key]
	var sm := ShaderMaterial.new()
	sm.shader = get_candy_shader()
	sm.set_shader_parameter("albedo_color", Color.html(color_hex))
	sm.set_shader_parameter("roughness", rough)
	sm.set_shader_parameter("metallic", 0.03 if rough < 0.25 else 0.01)
	sm.set_shader_parameter("rim_strength", 0.38 if rough < 0.3 else 0.20)
	sm.set_shader_parameter("sss_strength", sss)
	sm.set_shader_parameter("emission_strength", 0.42 if glow else 0.0)
	sm.set_shader_parameter("bump_scale", bump)
	sm.set_shader_parameter("use_vertex_color", vcol)
	_cache[key] = sm
	return sm


static func mat_color(c: Color, rough: float = 0.20, glow: bool = false, sss: float = 0.28) -> ShaderMaterial:
	return mat("#" + c.to_html(false), rough, glow, false, sss, 0.0)


static func get_sea_material(sea_col: Color, rim_col: Color) -> ShaderMaterial:
	if _sea_shader == null:
		_sea_shader = Shader.new()
		_sea_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.88, 0.42, 0.62, 1.0);
uniform vec4 crest_color : source_color = vec4(0.98, 0.66, 0.80, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.92, 0.96, 1.0);

varying float v_wave_h;
varying vec3 v_world_pos;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * 1.4;
	float w1 = sin(wp.x * 0.42 + wp.z * 0.26 + t) * 0.15;
	float w2 = cos(wp.x * 0.78 - wp.z * 0.48 + t * 1.2) * 0.08;
	float h = w1 + w2;
	VERTEX.y += h;
	v_wave_h = h;
	v_world_pos = wp;

	float dx = 0.42 * 0.15 * cos(wp.x * 0.42 + wp.z * 0.26 + t)
	         - 0.78 * 0.08 * sin(wp.x * 0.78 - wp.z * 0.48 + t * 1.2);
	float dz = 0.26 * 0.15 * cos(wp.x * 0.42 + wp.z * 0.26 + t)
	         + 0.48 * 0.08 * sin(wp.x * 0.78 - wp.z * 0.48 + t * 1.2);
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
	float t = TIME * 0.9;
	float norm_h = clamp((v_wave_h + 0.25) / 0.50, 0.0, 1.0);
	vec3 col = mix(deep_color.rgb, crest_color.rgb, smoothstep(0.15, 0.85, norm_h));

	// Creamy strawberry-milkshake foam swirls and bubble clusters
	float swirl = sin(v_world_pos.x * 0.65 + sin(v_world_pos.z * 0.32 + t) * 2.0)
	            * cos(v_world_pos.z * 0.45 - t * 0.6);
	float foam_mask = smoothstep(0.48, 0.82, swirl + norm_h * 0.35);
	col = mix(col, foam_color.rgb, foam_mask * 0.72);

	ALBEDO = clamp(col * 0.90, vec3(0.0), vec3(0.95));
	ROUGHNESS = mix(0.42, 0.62, foam_mask);
	METALLIC = 0.02;
	SPECULAR = 0.25;
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _sea_shader
	# Creamy strawberry milkshake tones matching the mockup!
	var base_pink := sea_col.lerp(Color.html("#ec76a4"), 0.65)
	sm.set_shader_parameter("deep_color", base_pink.darkened(0.18))
	sm.set_shader_parameter("crest_color", base_pink.lightened(0.08))
	sm.set_shader_parameter("foam_color", Color.html("#ffdce9"))
	return sm


static func make_drop_shadow(radius: float = 0.55, opacity: float = 0.48) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.2, radius * 2.2)
	mi.mesh = pm
	mi.position = Vector3(0, 0.025, 0)
	if _shadow_mat == null:
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_mat.albedo_texture = _build_shadow_texture()
		_shadow_mat.albedo_color = Color(0.18, 0.07, 0.02, opacity)
	mi.material_override = _shadow_mat
	return mi


static func _build_shadow_texture() -> ImageTexture:
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y in range(sz):
		for x in range(sz):
			var uv := Vector2((float(x) + 0.5) / float(sz) * 2.0 - 1.0, (float(y) + 0.5) / float(sz) * 2.0 - 1.0)
			var r := uv.length()
			var a := clampf(1.0 - smoothstep(0.15, 0.95, r), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a))
	return ImageTexture.create_from_image(img)
