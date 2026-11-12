extends Node3D
## Dijah's Delights Candy Run — 3D game controller.
## Upgraded with 3D ProceduralSky reflections, 3-point studio + rim lighting,
## vertex-displaced 3D rolling syrup sea waves, dynamic camera banking,
## 3D shield aura, and ground shadow / squash-stretch juice.

enum State { PLAYING, FALLING, OVER, WIN, FAIL }

const LANE_X: float = 2.2
const GRAVITY: float = 22.0
const JUMP_V: float = 9.5
const SEG_LEN: float = 12.0
const SPAWN_AHEAD: float = 84.0
const DESPAWN_BEHIND: float = 24.0

var board: Dictionary
var board_index: int = 0
var state: int = State.PLAYING

var player: Node3D
var character: DijahCharacter
var camera: Camera3D
var hud: Hud
var voice: VoiceLines
var builder: TrackBuilder
var rng := RandomNumberGenerator.new()

var lane: int = 0
var target_x: float = 0.0
var vel_y: float = 0.0
var player_y: float = 0.0
var grounded: bool = true
var is_sliding: bool = false
var slide_timer: float = 0.0
const SLIDE_DURATION: float = 0.65
var base_speed: float = 9.0
var speed: float = 9.0
var wind_offset: float = 0.0

var hearts: int = 3
var invincible: float = 0.0
var shield_on: bool = false
var magnet_timer: float = 0.0
var speed_timer: float = 0.0
var score2x_timer: float = 0.0
var sour_timer: float = 0.0
var stumble_timer: float = 0.0
var fall_timer: float = 0.0

var score: float = 0.0
var distance: float = 0.0
var stars_collected: int = 0
var stars_spawned: int = 0
var stars_missed: int = 0
var streak: int = 0
var max_streak: int = 0
var falls: int = 0
var time_alive: float = 0.0
var perfect_jumps: int = 0
var holes_cleared: int = 0
var holes_encountered: int = 0
var near_misses: int = 0
var used_jump: bool = false
var used_steer: bool = false

var segments: Dictionary = {}
var next_seg_index: int = 0
var next_seg_z: float = 12.0
var active_obstacles: Array = []
var active_stars: Array = []
var active_powerups: Array = []
var finish_z: float = -300.0
var finished: bool = false
var _finish_spawned: bool = false

var _touch_start: Vector2 = Vector2.ZERO
var _touch_time: float = 0.0
var _touch_moved: bool = false
var _sea: MeshInstance3D
var _on_sticky: bool = false
var _shield_dome: MeshInstance3D
var _cam_bank: float = 0.0
var _shake_timer: float = 0.0
var _shake_amp: float = 0.0
var _second_wind_used: bool = false
var _combo_timer: float = 0.0
const COMBO_MAX_TIME: float = 3.2
var _hitstop_end_usec: int = 0
var _speed_pct: int = 100

# --- Controls forgiveness ---
const COYOTE_TIME: float = 0.12      # 120 ms to still jump after the ledge/hole edge
const JUMP_BUFFER: float = 0.12      # a tap just before landing fires on touchdown
var _coyote_left: float = -1.0
var _jump_buffer: float = 0.0
var _fall_grace: float = 0.0

# --- Flow: objective latch, rating, rush meter / invincible Sugar Rush Fever ---
const FEVER_DURATION: float = 6.0
const MAX_SPEED: float = 26.0
var objective_done: bool = false
var star_pickups: int = 0
var rush_meter: float = 0.0
var _fever_timer: float = 0.0
var _fever_len: float = FEVER_DURATION
var _act: int = 1
var par_time: float = 60.0
var _run_clock: float = 0.0
var _over_msec: int = 0
var _last_retry_msec: int = -10000


func _ready() -> void:
	board_index = Boards.selected_board
	board = Boards.get_board(board_index)
	base_speed = float(board.get("speed", 9.0))
	speed = base_speed
	finish_z = -float(board.get("length", 300))
	par_time = float(board.get("par_time", 60.0))
	rng.seed = randi()
	randomize()

	var sky_col: Color = Boards.palette_color(board, "sky")
	var fog_col: Color = Boards.palette_color(board, "fog")
	var sea_col: Color = Boards.palette_color(board, "sea")
	var rim_col: Color = Boards.palette_color(board, "rim")

	# --- 3D Sky Dome + Reflections + Balanced Studio Lighting ---
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color.html("#5eb8ff").lerp(sky_col, 0.35)
	sky_mat.sky_horizon_color = Color.html("#d8f0ff").lerp(fog_col, 0.30)
	sky_mat.ground_horizon_color = sea_col.lightened(0.08)
	sky_mat.ground_bottom_color = sea_col.darkened(0.15)
	sky_mat.sky_curve = 0.14
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.html("#ffeef6")
	env.ambient_light_energy = 0.36
	env.fog_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# 1. Key Sun: warm golden 3D directional light casting diagonal shadows across waffle pockets
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -52, 0)
	sun.light_color = Color.html("#fff4e2")
	sun.light_energy = 0.82
	sun.shadow_enabled = true
	sun.shadow_bias = 0.015
	sun.shadow_normal_bias = 1.0
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)

	# 2. Gentle Cool Fill Light from opposite angle
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-34, 135, 0)
	fill.light_color = Color.html("#d8ecff")
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	add_child(fill)

	# --- 3D Vertex-Displaced Rolling Syrup Sea ---
	var sea_mesh := PlaneMesh.new()
	sea_mesh.size = Vector2(220, 700)
	sea_mesh.subdivide_width = 88
	sea_mesh.subdivide_depth = 160
	_sea = MeshInstance3D.new()
	_sea.mesh = sea_mesh
	_sea.material_override = CandyMaterials.get_sea_material(sea_col, rim_col)
	_sea.position = Vector3(0, -1.0, -300)
	add_child(_sea)

	# --- Player + Dijah + Shield Dome ---
	player = Node3D.new()
	player.position = Vector3(0, 0, 0)
	add_child(player)
	character = DijahCharacter.new()
	player.add_child(character)
	character.set_outfit(Save.get_current_look())

	# Apply Equipped Abilities from the Store!
	if Save.has_ability("extra_heart"):
		hearts = 4
	if Save.has_ability("start_shield"):
		shield_on = true
	if Save.has_ability("star_magnet"):
		magnet_timer = 9999.0

	_shield_dome = MeshInstance3D.new()
	var s_mesh := SphereMesh.new()
	s_mesh.radius = 1.05
	s_mesh.height = 2.1
	_shield_dome.mesh = s_mesh
	_shield_dome.position = Vector3(0, 1.0, 0)
	var s_mat := StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.2, 0.92, 1.0, 0.30)
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.roughness = 0.05
	s_mat.emission_enabled = true
	s_mat.emission = Color.html("#00e5ff")
	s_mat.emission_energy_multiplier = 0.45
	_shield_dome.material_override = s_mat
	_shield_dome.visible = false
	player.add_child(_shield_dome)

	# --- 3D Chase Camera (wide 74 deg FOV, pulled back so Dijah reads small
	# on screen and the track ahead stays visible — the Nov 11 46 deg
	# close-up filled the frame with her and hid the track) ---
	camera = Camera3D.new()
	camera.fov = 74.0
	camera.near = 0.1
	camera.far = 250.0
	camera.position = Vector3(0, 3.1, 5.2)
	add_child(camera)
	camera.look_at_from_position(Vector3(0, 3.1, 5.2), Vector3(0, 0.9, -8.0), Vector3.UP)

	# --- Track ---
	builder = TrackBuilder.new(board, rng)
	while next_seg_z > -SPAWN_AHEAD:
		_spawn_segment()

	# --- HUD ---
	hud = Hud.new()
	add_child(hud)
	hud.set_board("BOARD %d • %s" % [board_index + 1, str(board.get("name", "")).to_upper()])
	hud.retry_pressed.connect(_on_retry)
	hud.menu_pressed.connect(_on_menu)
	hud.next_pressed.connect(_on_next)
	hud.mute_pressed.connect(_on_mute)

	# --- Dijah's voice lines ---
	voice = VoiceLines.new()
	player.add_child(voice)

	Music.play_board(board_index)
	hud.show_message("GO!", Color.html("#ffd23f"), 1.0)
	_update_hud()


func _spawn_segment() -> void:
	var is_finish: bool = (next_seg_z - SEG_LEN) <= finish_z
	var res: Dictionary = builder.build_segment(next_seg_index, next_seg_z, is_finish, finish_z)
	var node: Node3D = res["node"]
	add_child(node)
	segments[next_seg_index] = node
	active_obstacles.append_array(res["obstacles"])
	active_stars.append_array(res["stars"])
	active_powerups.append_array(res["powerups"])
	stars_spawned += (res["stars"] as Array).size()
	next_seg_index += 1
	next_seg_z -= SEG_LEN
	if is_finish:
		_finish_spawned = true


func _cleanup_segments() -> void:
	var to_remove: Array = []
	for idx in segments.keys():
		var seg: Node3D = segments[idx]
		if seg.position.z > player.position.z + DESPAWN_BEHIND:
			to_remove.append(idx)
	for idx in to_remove:
		var seg2: Node3D = segments[idx]
		segments.erase(idx)
		seg2.queue_free()
	active_obstacles = active_obstacles.filter(func(o: Variant) -> bool: return is_instance_valid(o))
	active_stars = active_stars.filter(func(s: Variant) -> bool: return is_instance_valid(s))
	active_powerups = active_powerups.filter(func(p: Variant) -> bool: return is_instance_valid(p))


func _physics_process(delta: float) -> void:
	if _hitstop_end_usec > 0 and Time.get_ticks_usec() >= _hitstop_end_usec:
		Engine.time_scale = 1.0
		_hitstop_end_usec = 0

	_touch_time += delta
	if state == State.FALLING:
		fall_timer -= delta
		_run_clock += delta
		player_y -= delta * 6.0
		player.position.y = player_y
		character.rotation.y += delta * 10.0
		if fall_timer <= 0.0:
			character.rotation.y = 0.0
			character.reset_pose()
			if hearts <= 0 and Save.has_ability("second_wind") and not _second_wind_used:
				_second_wind_used = true
				hearts = 2
				hud.show_message("CODE BLUE REVIVE! +2 ♥", Color.html("#ff8a00"), 1.6)
				hud.flash_screen(Color.html("#ff8a00"), 0.32)
				Music.play_sfx("win")
			if hearts <= 0:
				_game_over()
			else:
				player_y = 0.0
				player.position.y = 0.0
				grounded = true
				invincible = 1.5
				state = State.PLAYING
		return
	if state != State.PLAYING:
		return

	time_alive += delta
	_run_clock += delta
	magnet_timer = maxf(0.0, magnet_timer - delta)
	speed_timer = maxf(0.0, speed_timer - delta)
	score2x_timer = maxf(0.0, score2x_timer - delta)
	sour_timer = maxf(0.0, sour_timer - delta)
	invincible = maxf(0.0, invincible - delta)
	stumble_timer = maxf(0.0, stumble_timer - delta)
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			is_sliding = false
			character.reset_pose()
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	_fall_grace = maxf(0.0, _fall_grace - delta)
	_shield_dome.visible = shield_on

	# --- Sugar Rush Fever (invincible, high-speed) countdown ---
	if _fever_timer > 0.0:
		_fever_timer = maxf(0.0, _fever_timer - delta)
		rush_meter = _fever_timer / _fever_len
		if _fever_timer <= 0.0:
			rush_meter = 0.0
			hud.set_fever(0.0)
			hud.flash_screen(Color.html("#ffffff"), 0.18)
			hud.show_message("RUSH OVER - build it again!", Color.html("#ff9ec7"), 1.2)
		else:
			hud.set_fever(_fever_timer)

	# --- Combo Streak Decay Timer ---
	if streak > 0:
		_combo_timer = maxf(0.0, _combo_timer - delta)
		if _combo_timer <= 0.0:
			streak = maxi(0, streak - 2)
			_combo_timer = 1.1 if streak > 0 else 0.0
	if _fever_timer <= 0.0 and _combo_timer <= 0.0:
		rush_meter = maxf(0.0, rush_meter - delta * 0.04)
	var rush_req: int = 3 if Save.has_ability("fast_rush") else 5
	hud.set_combo_bar(rush_meter, _fever_timer > 0.0)

	# --- 3-act speed ramp + combo flow + fever (hard-capped) ---
	var factor: float = 1.0
	if sour_timer > 0.0:
		factor *= 0.55
	if speed_timer > 0.0:
		factor *= 1.45
	if _fever_timer > 0.0:
		factor *= 1.35
	if stumble_timer > 0.0:
		factor *= 0.38
	var track_ratio: float = clampf(distance / maxf(absf(finish_z), 100.0), 0.0, 1.0)
	var act_now: int = Boards.act_index(track_ratio)
	if act_now != _act:
		_act = act_now
		if _act == 2:
			hud.show_message("ACT II - PICK UP THE PACE!", Color.html("#ffd23f"), 1.4)
		else:
			hud.show_message("ACT III - FULL SPRINT!", Color.html("#ff2fb3"), 1.6)
		hud.flash_screen(Color.html("#ffffff"), 0.16)
		_spawn_ring_wave(player.global_position + Vector3(0, 0.5, 0), Color.html("#ffd23f"))
		Music.play_sfx("streak")
	var combo_flow_boost: float = 1.0 + minf(float(streak) * 0.01, 0.15)
	speed = base_speed * Boards.act_multiplier(track_ratio) * combo_flow_boost * factor
	if _on_sticky:
		speed *= 0.55
	speed = minf(speed, MAX_SPEED)
	_speed_pct = int(round((speed / maxf(base_speed, 1.0)) * 100.0))

	# --- forward motion + steering ---
	player.position.z -= speed * delta
	distance = -player.position.z
	var want_x: float = clampf(target_x + wind_offset, -3.3, 3.3)
	var prev_x: float = player.position.x
	player.position.x = lerpf(player.position.x, want_x, delta * 10.0)
	var steer_vel: float = (player.position.x - prev_x) / maxf(delta, 0.001)

	# --- jumping ---
	if grounded:
		character.animate_run(delta, speed)
		character.set_air_tilt(0.0)
	else:
		vel_y -= GRAVITY * delta
		player_y += vel_y * delta
		character.set_air_tilt(-0.5)
		character.set_jump_pose()
		if player_y <= 0.0:
			player_y = 0.0
			vel_y = 0.0
			grounded = true
			character.reset_pose()
			character.trigger_squash(Vector3(1.16, 0.84, 1.16))
			_spawn_ring_wave(player.global_position + Vector3(0, 0.08, 0), Color.html("#ff80b5"))
			_spawn_burst(player.global_position + Vector3(0, 0.15, 0), Color.html("#ffeaf4"), 14)
			if _jump_buffer > 0.0:
				_jump_buffer = 0.0
				_do_jump()
	player.position.y = player_y
	character.update_ground_shadow(player_y, steer_vel, delta)

	character.visible = invincible <= 0.0 or _fever_timer > 0.0 or int(invincible * 12.0) % 2 == 0

	# --- segments ---
	if next_seg_z > player.position.z - SPAWN_AHEAD and not _finish_spawned:
		_spawn_segment()
	_cleanup_segments()

	# --- obstacles ---
	_on_sticky = false
	var wind_dir: int = 0
	var fall_seen: bool = false
	for ob in active_obstacles:
		if not is_instance_valid(ob):
			continue
		ob.update_obstacle(delta, player.position.z)
		var res: String = ob.check_player(player.global_position, player_y, is_sliding)
		match res:
			"fall":
				fall_seen = true
				if _fever_timer > 0.0:
					_fever_hop()
				elif _fall_grace <= 0.0 and _coyote_left < 0.0:
					_coyote_left = COYOTE_TIME
			"hit":
				if _fever_timer > 0.0:
					_fever_smash(ob)
				else:
					_on_hit(ob)
					if state != State.PLAYING:
						return
			"slow":
				_on_sticky = true
			"wind_left":
				wind_dir = -1
			"wind_right":
				wind_dir = 1
		_track_hole(ob)
	# Coyote time: the fall verdict is delayed 120 ms so a late jump still saves you.
	if fall_seen and _fever_timer <= 0.0 and _fall_grace <= 0.0:
		_coyote_left -= delta
		if _coyote_left <= 0.0:
			_coyote_left = -1.0
			_on_fall()
			if state != State.PLAYING:
				return
	elif not fall_seen:
		_coyote_left = -1.0
	if wind_dir != 0:
		wind_offset = clampf(wind_offset + float(wind_dir) * delta * 2.0, -2.0, 2.0)
	else:
		wind_offset = lerpf(wind_offset, 0.0, delta * 3.0)

	# --- stars ---
	for s in active_stars:
		if not is_instance_valid(s) or s.collected:
			continue
		s.update_star(delta, player.global_position + Vector3(0, player_y + 0.9, 0), magnet_timer > 0.0 or _fever_timer > 0.0)
		var sp: Vector3 = s.global_position
		if absf(sp.z - player.position.z) < 1.1 and absf(sp.x - player.position.x) < 1.2 and absf(sp.y - (player_y + 0.9)) < 1.4:
			_collect_star(s)
		elif sp.z > player.position.z + 2.0:
			s.missed = true
			stars_missed += 1
			if absf(sp.x - player.position.x) < 1.2:
				streak = 0
			s.queue_free()

	# --- power-ups ---
	for p in active_powerups:
		if not is_instance_valid(p) or p.collected:
			continue
		p.update_powerup(delta)
		var pp: Vector3 = p.global_position
		if absf(pp.z - player.position.z) < 1.1 and absf(pp.x - player.position.x) < 1.2 and absf(pp.y - (player_y + 0.9)) < 1.4:
			_collect_powerup(p)

	# --- score ---
	score += speed * delta * _score_mult()

	# --- sugar rush & dynamic flow: speed lines + wider FOV + 3D character rainbow aura ---
	var rush: bool = streak >= rush_req or speed_timer > 0.0 or _fever_timer > 0.0 or _speed_pct >= 115
	var flow_intensity: float = clampf(float(_speed_pct - 100) / 55.0 + (0.20 if rush else 0.0) + (0.15 if _fever_timer > 0.0 else 0.0), 0.18, 0.65)
	hud.set_speed_lines(rush, flow_intensity)
	character.set_rush_aura(streak >= rush_req or speed_timer > 0.0 or _fever_timer > 0.0)
	var target_fov: float = clampf(74.0 + float(_speed_pct - 100) * 0.22 + (3.0 if speed_timer > 0.0 else 0.0), 74.0, 86.5)
	camera.fov = lerpf(camera.fov, target_fov, delta * 4.5)

	# --- objectives (latch: keep running to the finish line for the 3-star rating) ---
	var stats: Dictionary = _stats()
	if not objective_done and Boards.objective_met_now(board, stats):
		objective_done = true
		hud.show_message("OBJECTIVE COMPLETE! Reach the finish for ★★★", Color.html("#5fe3c0"), 1.8)
		hud.flash_screen(Color.html("#5fe3c0"), 0.2)
		Music.play_sfx("win")
	if board.get("objective", {}).get("type", "") == "timed_collect" and not objective_done:
		if time_alive > float(board["objective"].get("target2", 45)) and stars_collected < int(board["objective"].get("target", 20)):
			_fail()
			return
	if player.position.z <= finish_z and not finished:
		finished = true
		if objective_done or Boards.objective_met_at_finish(board, stats):
			_win()
		else:
			_fail()
		return

	# --- 3D camera + sea follow + lateral bank + impact shake ---
	var shake_ofs := Vector3.ZERO
	if _shake_timer > 0.0:
		_shake_timer = maxf(0.0, _shake_timer - delta)
		var cur_s: float = _shake_amp * (_shake_timer / 0.35)
		shake_ofs = Vector3(rng.randf_range(-cur_s, cur_s), rng.randf_range(-cur_s, cur_s), 0.0)
	camera.position = Vector3(player.position.x * 0.35, 3.1 + player_y * 0.22, player.position.z + 5.2) + shake_ofs
	camera.look_at(Vector3(player.position.x * 0.5, 0.9 + player_y * 0.15, player.position.z - 8.0))
	_cam_bank = lerpf(_cam_bank, clampf(-steer_vel * 0.015, -0.06, 0.06), delta * 8.0)
	camera.rotation.z += _cam_bank

	var sea_target_z: float = floor((player.position.z - 40.0) / 120.0) * 120.0
	_sea.position = Vector3(0, -1.0, sea_target_z)

	_update_hud()


func _track_hole(ob: Obstacle) -> void:
	if not ob.is_hole:
		# Track close-call near-misses on solid 3D obstacles too!
		if not ob.counted and not ob.consumed and player.position.z <= ob.global_position.z - 0.9:
			ob.counted = true
			var ob_x: float = ob.current_lane_x()
			var dx_ob: float = absf(player.position.x - ob_x)
			if dx_ob < 2.35:
				near_misses += 1
				streak += 2
				max_streak = maxi(max_streak, streak)
				_combo_timer = COMBO_MAX_TIME
				score += 75.0 * _score_mult()
				hud.trigger_combo_pop()
				hud.trigger_score_pop()
				hud.show_message("CLOSE CALL! +75", Color.html("#00e5ff"), 0.9)
				_spawn_ring_wave(player.global_position + Vector3(0, 0.5, 0), Color.html("#00e5ff"))
				# (no 3D label here — the HUD banner above already says it;
				# a second copy at the player drew the same words mid-screen)
				_near_miss_juice()
				Music.play_sfx("streak")
		return
	if not ob.crossed and player.position.z <= ob.global_position.z:
		ob.crossed = true
		if player_y > 0.3:
			ob.cleared_airborne = true
		if player_y > 0.8:
			ob.perfect = true
	if ob.counted:
		return
	if player.position.z <= ob.global_position.z - 1.5:
		ob.counted = true
		var hole_x: float = ob.current_lane_x() if ob.kind != "cloud_gap" else player.position.x
		var dx: float = absf(player.position.x - hole_x)
		if dx < 1.1:
			holes_encountered += 1
			if ob.cleared_airborne:
				holes_cleared += 1
				streak += 1
				max_streak = maxi(max_streak, streak)
				_combo_timer = COMBO_MAX_TIME
				hud.trigger_combo_pop()
				if ob.perfect:
					perfect_jumps += 1
					score += 75.0 * _score_mult()
					hud.trigger_score_pop()
					hud.show_message("PERFECT JUMP +75!", Color.html("#ffd23f"), 1.0)
					_spawn_ring_wave(player.global_position + Vector3(0, 0.4, 0), Color.html("#ffd23f"))
					# (no 3D label — HUD banner already says it)
					_add_rush(0.10)
					Music.play_sfx("streak")
		elif dx < 3.3 and player_y < 0.3:
			near_misses += 1
			streak += 2
			max_streak = maxi(max_streak, streak)
			_combo_timer = COMBO_MAX_TIME
			score += 50.0 * _score_mult()
			hud.trigger_combo_pop()
			hud.trigger_score_pop()
			hud.show_message("NEAR MISS +50", Color.html("#5fe3c0"), 1.0)
			# (no 3D label — HUD banner already says it)
			_near_miss_juice()
			Music.play_sfx("streak")
			voice.play_line("near_miss")


func _score_mult() -> float:
	var m: float = 1.0
	var rush_req: int = 3 if Save.has_ability("fast_rush") else 5
	if streak >= rush_req:
		m *= 1.0 + minf(float(streak), 20.0) * 0.1
		if Save.has_ability("fast_rush"):
			m *= 1.25
	if score2x_timer > 0.0:
		m *= 2.0
	if speed_timer > 0.0:
		m *= 1.5
	if _fever_timer > 0.0:
		m *= 2.0
	return m


func _rush_mult() -> float:
	var rush_req: int = 3 if Save.has_ability("fast_rush") else 5
	if streak >= rush_req:
		return 1.0 + minf(float(streak), 20.0) * 0.1
	return 1.0


func _stats() -> Dictionary:
	var o: Dictionary = board.get("objective", {})
	var progress: int = 0
	match o.get("type", ""):
		"collect":
			progress = stars_collected
		"score", "score_double":
			progress = int(score)
		"jumps":
			progress = holes_cleared
		"streak", "streak_hold":
			progress = streak
		"perfect":
			progress = perfect_jumps
		"near_miss":
			progress = near_misses
	return {
		"score": int(score),
		"distance": int(distance),
		"stars": stars_collected,
		"streak": streak,
		"max_streak": max_streak,
		"falls": falls,
		"time": int(time_alive),
		"time_left": maxi(0, int(float(o.get("target2", 0)) - time_alive)),
		"missed": stars_missed,
		"spawned": stars_spawned,
		"cleared": holes_cleared,
		"holes": holes_encountered,
		"perfect": perfect_jumps,
		"near_miss": near_misses,
		"used_jump": used_jump,
		"used_steer": used_steer,
		"progress": progress,
	}


func _update_hud() -> void:
	var obj_text: String = Boards.objective_progress(board, _stats())
	if objective_done:
		obj_text = "✅ Objective complete - reach the finish line!"
	hud.update_hud(int(score), int(distance), maxi(Save.best_score(board_index), int(score)), _rush_mult(), stars_collected, streak, hearts, obj_text, _speed_pct)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_start = t.position
			_touch_time = 0.0
			_touch_moved = false
		else:
			if not _touch_moved and _touch_time < 0.35:
				if (state == State.OVER or state == State.FAIL) and Time.get_ticks_msec() - _over_msec > 450:
					_instant_retry()
				else:
					_do_jump()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_touch_moved = true
		var dx: float = d.position.x - _touch_start.x
		var dy: float = d.position.y - _touch_start.y
		if dy > 80.0 and absf(dy) > absf(dx):
			_do_slide()
			_touch_start = d.position
		elif dy < -80.0 and absf(dy) > absf(dx):
			_do_jump()
			_touch_start = d.position
		elif dx > 80.0:
			_do_steer(1)
			_touch_start = d.position
		elif dx < -80.0:
			_do_steer(-1)
			_touch_start = d.position
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_R:
				_instant_retry()
				return
			if state == State.OVER or state == State.FAIL:
				if k.keycode == KEY_SPACE or k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
					_instant_retry()
					return
			elif state == State.WIN:
				if k.keycode == KEY_SPACE or k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
					_on_next()
					return
			if k.keycode == KEY_LEFT or k.keycode == KEY_A:
				_do_steer(-1)
			elif k.keycode == KEY_RIGHT or k.keycode == KEY_D:
				_do_steer(1)
			elif k.keycode == KEY_SPACE or k.keycode == KEY_UP or k.keycode == KEY_W:
				_do_jump()
			elif k.keycode == KEY_DOWN or k.keycode == KEY_S:
				_do_slide()


func _do_steer(dir: int) -> void:
	if state != State.PLAYING:
		return
	var new_lane: int = clampi(lane + dir, -1, 1)
	if new_lane != lane:
		lane = new_lane
		target_x = float(lane) * LANE_X
		used_steer = true
		_spawn_burst(player.global_position + Vector3(0, 0.25, 0.2), Color.html("#ff9ec7"), 10)


func _do_jump() -> void:
	if state != State.PLAYING:
		return
	if not grounded:
		# Jump buffering: remember a tap made just before landing.
		_jump_buffer = JUMP_BUFFER
		return
	if _coyote_left >= 0.0:
		# Coyote jump: tapped within 120 ms of the ledge/hole edge - forgive the fall.
		_fall_grace = 0.25
		_coyote_left = -1.0
	grounded = false
	vel_y = JUMP_V
	used_jump = true
	character.trigger_squash(Vector3(0.86, 1.20, 0.86))
	_spawn_ring_wave(player.global_position + Vector3(0, 0.08, 0), Color.html("#ffd23f"))
	_spawn_burst(player.global_position + Vector3(0, 0.15, 0), Color.html("#fff59d"), 16)
	Music.play_sfx("jump")


func _do_slide() -> void:
	if state != State.PLAYING or not grounded:
		return
	is_sliding = true
	slide_timer = SLIDE_DURATION
	character.set_slide_pose()
	_spawn_burst(player.global_position + Vector3(0, 0.12, 0.3), Color.html("#ffd23f"), 12)
	_spawn_ring_wave(player.global_position + Vector3(0, 0.05, 0), Color.html("#ff5c8a"))
	Music.play_sfx("pop", 0.75)


func _on_fall() -> void:
	if invincible > 0.0 or _fever_timer > 0.0 or state != State.PLAYING:
		return
	if shield_on:
		shield_on = false
		invincible = 1.2
		vel_y = 5.0
		grounded = false
		player_y = 0.4
		_trigger_shake(0.18, 0.25)
		_trigger_hitstop(0.045, 0.25)
		hud.flash_screen(Color.html("#00e5ff"), 0.28)
		_spawn_ring_wave(player.global_position + Vector3(0, 0.5, 0), Color.html("#00e5ff"))
		hud.show_message("SHIELD SAVED YOU!", Color.html("#00e5ff"), 1.4)
		Music.play_sfx("streak")
		return
	hearts -= 1
	falls += 1
	streak = 0
	_combo_timer = 0.0
	_trigger_shake(0.32, 0.38)
	_trigger_hitstop(0.06, 0.22)
	hud.flash_screen(Color.html("#ff2e55"), 0.34)
	Music.play_sfx("fall")
	voice.play_line("fall")
	state = State.FALLING
	fall_timer = 0.7
	vel_y = 0.0


func _on_hit(ob: Obstacle) -> void:
	if invincible > 0.0 or _fever_timer > 0.0 or state != State.PLAYING:
		return
	if shield_on:
		shield_on = false
		ob.consumed = true
		invincible = 1.2
		_trigger_shake(0.18, 0.25)
		_trigger_hitstop(0.045, 0.25)
		hud.flash_screen(Color.html("#00e5ff"), 0.28)
		_spawn_ring_wave(player.global_position + Vector3(0, 0.8, 0), Color.html("#00e5ff"))
		hud.show_message("SHIELD!", Color.html("#00e5ff"), 1.2)
		Music.play_sfx("streak")
		return
	hearts -= 1
	falls += 1
	streak = 0
	_combo_timer = 0.0
	ob.consumed = true
	invincible = 1.5
	stumble_timer = 0.8
	_trigger_shake(0.32, 0.38)
	_trigger_hitstop(0.06, 0.22)
	hud.flash_screen(Color.html("#ff2e55"), 0.34)
	_spawn_burst(player.global_position + Vector3(0, 0.8, -0.3), Color.html("#ff2e55"), 28)
	Music.play_sfx("fall")
	voice.play_line("fall")
	if hearts <= 0 and Save.has_ability("second_wind") and not _second_wind_used:
		_second_wind_used = true
		hearts = 2
		hud.show_message("CODE BLUE REVIVE! +2 ♥", Color.html("#ff8a00"), 1.6)
		hud.flash_screen(Color.html("#ff8a00"), 0.32)
		Music.play_sfx("win")
		return
	if hearts <= 0:
		_game_over()


func _collect_star(s: Star) -> void:
	var star_pos: Vector3 = s.global_position
	s.collect()
	var star_mult: int = 2 if Save.has_ability("double_stars") else 1
	stars_collected += s.value * star_mult
	streak += 1
	max_streak = maxi(max_streak, streak)
	_combo_timer = COMBO_MAX_TIME
	star_pickups += 1
	_add_rush(0.07 if s.kind == "normal" else (0.14 if s.kind == "big" else 0.25))
	var pts: int = int(round(float(s.value) * 10.0 * _score_mult()))
	score += float(pts)
	hud.trigger_score_pop()
	hud.trigger_combo_pop()
	_spawn_burst(star_pos, Color.html("#ffd23f") if s.kind == "normal" else Color.html("#ff8a00"), 28)
	_spawn_ring_wave(star_pos, Color.html("#ffd23f") if s.kind == "normal" else Color.html("#ff2fb3"))
	_spawn_floating_3d_text(star_pos + Vector3(0, 0.35, 0), "+%d ★  (x%d)" % [pts, streak], Color.html("#ffd54f"))
	Music.play_pickup(streak, s.kind != "normal")
	if s.kind == "big":
		_trigger_hitstop(0.035, 0.35)
		hud.flash_screen(Color.html("#ffd23f"), 0.18)
		voice.play_line("big_star")
	elif s.kind == "rainbow":
		_trigger_hitstop(0.045, 0.30)
		hud.flash_screen(Color.html("#ff2fb3"), 0.24)
		voice.play_line("rainbow_star")
	elif board_index == 20:
		voice.play_blueberry()
	else:
		voice.play_general()
	var rush_req: int = 3 if Save.has_ability("fast_rush") else 5
	if streak == rush_req:
		hud.show_message("SWEET STREAK! 1.5x", Color.html("#ff2fb3"), 1.3)
		hud.flash_screen(Color.html("#ff2fb3"), 0.20)
		Music.play_sfx("streak")
	elif streak == 10:
		hud.show_message("10x SUPER STREAK! 2.0x", Color.html("#ffd23f"), 1.3)
		hud.flash_screen(Color.html("#ffd23f"), 0.22)
		_spawn_ring_wave(player.global_position + Vector3(0, 0.6, 0), Color.html("#ffd23f"))
		Music.play_sfx("streak")
	elif streak == 20:
		hud.show_message("20x HYPER FLOW! 3.0x", Color.html("#00e5ff"), 1.4)
		hud.flash_screen(Color.html("#00e5ff"), 0.25)
		_spawn_ring_wave(player.global_position + Vector3(0, 0.6, 0), Color.html("#00e5ff"))
		Music.play_sfx("streak")
	elif streak >= 30 and streak % 10 == 0:
		hud.show_message("%dx UNSTOPPABLE FEVER!" % streak, Color.html("#ff8a00"), 1.4)
		hud.flash_screen(Color.html("#ff8a00"), 0.26)
		_spawn_ring_wave(player.global_position + Vector3(0, 0.6, 0), Color.html("#ff8a00"))
		Music.play_sfx("streak")
	s.queue_free()


func _collect_powerup(p: PowerUp) -> void:
	p.collect()
	var dur_mult: float = 1.5 if Save.has_ability("long_power") else 1.0
	var sour_mult: float = 0.5 if Save.has_ability("long_power") else 1.0
	_combo_timer = COMBO_MAX_TIME
	hud.trigger_combo_pop()
	match p.kind:
		"speed":
			speed_timer = 5.0 * dur_mult
			hud.flash_screen(Color.html("#ffd23f"), 0.24)
			hud.show_message("TURBO SPEED BOOST!", Color.html("#ffd23f"), 1.2)
			voice.play_line("speed_boost")
		"shield":
			shield_on = true
			hud.flash_screen(Color.html("#00e5ff"), 0.22)
			hud.show_message("SHIELD ACTIVE!", Color.html("#00e5ff"), 1.2)
		"magnet":
			magnet_timer = maxf(magnet_timer, 8.0 * dur_mult)
			hud.flash_screen(Color.html("#ff2e4d"), 0.20)
			hud.show_message("🧲 STAR MAGNET!", Color.html("#ff2e4d"), 1.2)
		"2x":
			score2x_timer = 10.0 * dur_mult
			hud.flash_screen(Color.html("#b967ff"), 0.22)
			hud.show_message("✨ 2x SCORE FEVER!", Color.html("#b967ff"), 1.2)
		"sour":
			sour_timer = 5.0 * sour_mult
			streak = 0
			_combo_timer = 0.0
			hud.flash_screen(Color.html("#7ed957"), 0.25)
			hud.show_message("SOUR! SLOW DOWN!", Color.html("#7ed957"), 1.4)
			Music.play_sfx("sour")
			voice.play_line("sour_star")
			p.queue_free()
			return
	Music.play_sfx("streak")
	_spawn_burst(p.global_position, Color.html("#ffffff"), 16)
	p.queue_free()


func _add_rush(amount: float) -> void:
	if _fever_timer > 0.0 or state != State.PLAYING:
		return
	rush_meter = minf(1.0, rush_meter + amount)
	if rush_meter >= 1.0:
		_start_fever()


func _start_fever() -> void:
	_fever_len = FEVER_DURATION * (1.5 if Save.has_ability("long_power") else 1.0)
	_fever_timer = _fever_len
	rush_meter = 1.0
	hud.set_fever(_fever_timer)
	hud.flash_screen(Color.html("#ff2fb3"), 0.34)
	hud.show_message("🌈 SUGAR RUSH FEVER! INVINCIBLE!", Color.html("#ff2fb3"), 1.6)
	_trigger_shake(0.12, 0.3)
	_spawn_ring_wave(player.global_position + Vector3(0, 0.5, 0), Color.html("#ff2fb3"))
	_spawn_ring_wave(player.global_position + Vector3(0, 0.9, 0), Color.html("#00e5ff"))
	_spawn_burst(player.global_position + Vector3(0, 0.8, 0), Color.html("#ffd23f"), 40)
	Music.play_sfx("win")


## Fever auto-hop: sail over pits/gaps without taking damage.
func _fever_hop() -> void:
	if grounded:
		grounded = false
		vel_y = JUMP_V * 0.85
		player_y = maxf(player_y, 0.35)
		_spawn_ring_wave(player.global_position + Vector3(0, 0.08, 0), Color.html("#00e5ff"))


## Fever smash: plough straight through solid hazards.
func _fever_smash(ob: Obstacle) -> void:
	if ob.consumed:
		return
	ob.consumed = true
	score += 25.0
	_spawn_burst(ob.global_position + Vector3(0, 0.7, 0), Color.html("#ffd23f"), 24)
	_spawn_floating_3d_text(player.global_position + Vector3(0, 1.4, 0), "SMASH +25", Color.html("#ff2fb3"))
	_trigger_shake(0.1, 0.18)
	Music.play_sfx("bigpop")


## Near-miss feel: 50 ms micro-slowdown + subtle shake + a little rush-meter fuel.
func _near_miss_juice() -> void:
	_trigger_hitstop(0.05, 0.3)
	_trigger_shake(0.05, 0.15)
	_add_rush(0.10)


func _trigger_hitstop(dur_sec: float, scale_val: float = 0.25) -> void:
	Engine.time_scale = scale_val
	_hitstop_end_usec = Time.get_ticks_usec() + int(dur_sec * 1000000.0)


func _trigger_shake(amp: float, dur: float) -> void:
	_shake_amp = amp
	_shake_timer = dur


func _instant_retry() -> void:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_retry_msec < 250:
		return
	_last_retry_msec = now_ms
	_coyote_left = -1.0
	_jump_buffer = 0.0
	_fall_grace = 0.0
	objective_done = false
	star_pickups = 0
	rush_meter = 0.0
	_fever_timer = 0.0
	_act = 1
	_run_clock = 0.0
	hud.set_fever(0.0)
	hud.set_combo_bar(0.0, false)
	Engine.time_scale = 1.0
	_hitstop_end_usec = 0
	for idx in segments.keys():
		var seg: Node3D = segments[idx]
		if is_instance_valid(seg):
			seg.queue_free()
	segments.clear()
	active_obstacles.clear()
	active_stars.clear()
	active_powerups.clear()

	state = State.PLAYING
	lane = 0
	target_x = 0.0
	vel_y = 0.0
	player_y = 0.0
	grounded = true
	wind_offset = 0.0
	player.position = Vector3.ZERO
	character.rotation.y = 0.0
	character.reset_pose()
	character.set_rush_aura(false)

	hearts = 4 if Save.has_ability("extra_heart") else 3
	shield_on = Save.has_ability("start_shield")
	magnet_timer = 9999.0 if Save.has_ability("star_magnet") else 0.0
	invincible = 0.0
	speed_timer = 0.0
	score2x_timer = 0.0
	sour_timer = 0.0
	stumble_timer = 0.0
	fall_timer = 0.0
	_second_wind_used = false

	score = 0.0
	distance = 0.0
	stars_collected = 0
	stars_spawned = 0
	stars_missed = 0
	streak = 0
	max_streak = 0
	_combo_timer = 0.0
	falls = 0
	time_alive = 0.0
	perfect_jumps = 0
	holes_cleared = 0
	holes_encountered = 0
	near_misses = 0
	used_jump = false
	used_steer = false
	finished = false
	_finish_spawned = false

	next_seg_index = 0
	next_seg_z = 12.0
	rng.seed = randi()
	builder = TrackBuilder.new(board, rng)
	while next_seg_z > -SPAWN_AHEAD:
		_spawn_segment()

	hud.hide_panels()
	hud.flash_screen(Color.html("#ffd23f"), 0.22)
	hud.show_message("INSTANT RETRY — GO!", Color.html("#ffd23f"), 1.0)
	_update_hud()


func _spawn_ring_wave(pos: Vector3, col: Color) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.28
	tm.outer_radius = 0.42
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(col.r, col.g, col.b, 0.85)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.emission_enabled = true
	rm.emission = col
	rm.emission_energy_multiplier = 0.8
	ring.material_override = rm
	ring.position = pos
	add_child(ring)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(3.2, 1.0, 3.2), 0.36)
	tw.tween_property(rm, "albedo_color:a", 0.0, 0.36)
	tw.chain().tween_callback(ring.queue_free)


func _spawn_burst(pos: Vector3, color: Color, amount: int) -> void:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 0.9
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 8.0
	pm.gravity = Vector3(0, -12, 0)
	pm.damping_min = 1.0
	pm.damping_max = 2.0
	pm.scale_min = 0.06
	pm.scale_max = 0.12
	p.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.16
	var mm := StandardMaterial3D.new()
	mm.albedo_color = color
	mm.emission_enabled = true
	mm.emission = color
	mesh.material = mm
	p.draw_pass_1 = mesh
	p.position = pos
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _spawn_floating_3d_text(pos: Vector3, txt: String, col: Color) -> void:
	var lbl := Label3D.new()
	lbl.text = txt
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 42
	lbl.pixel_size = 0.0045
	lbl.modulate = col
	lbl.outline_modulate = Color.html("#4a1030")
	lbl.outline_size = 10
	lbl.position = pos
	add_child(lbl)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y + 1.25, 0.55)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.55)
	tw.tween_property(lbl, "outline_modulate:a", 0.0, 0.55)
	tw.chain().tween_callback(lbl.queue_free)


func _spawn_confetti(pos: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 200
	p.lifetime = 1.6
	p.one_shot = true
	p.explosiveness = 1.0
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 5.0
	pm.initial_velocity_max = 11.0
	pm.gravity = Vector3(0, -7, 0)
	pm.scale_min = 0.08
	pm.scale_max = 0.16
	var grad := Gradient.new()
	grad.set_color(0, Color.html("#ff5c8a"))
	grad.add_point(0.25, Color.html("#ffd23f"))
	grad.add_point(0.5, Color.html("#5fe3c0"))
	grad.add_point(0.75, Color.html("#b967ff"))
	grad.set_color(1, Color.html("#ff8a00"))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	pm.color_ramp = grad_tex
	p.process_material = pm
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 0.14, 0.02)
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color.html("#ffffff")
	mesh.material = mm
	p.draw_pass_1 = mesh
	p.position = pos
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _win() -> void:
	if state == State.WIN:
		return
	state = State.WIN
	# 3-star rating: clear the board, grab >=90% of the stars, beat the par time.
	var star_pct: float = float(star_pickups) / float(maxi(stars_spawned, 1))
	var got_pct: bool = star_pct >= 0.9
	var got_par: bool = _run_clock <= par_time
	var rating: int = 1 + (1 if got_pct else 0) + (1 if got_par else 0)
	var is_best: bool = Save.record_run(board_index, int(score), stars_collected, true, rating, _run_clock)
	_over_msec = Time.get_ticks_msec()
	Music.play_sfx("win")
	_spawn_confetti(player.global_position + Vector3(0, 2, -3))
	_spawn_ring_wave(player.global_position + Vector3(0, 0.5, -1), Color.html("#ffd23f"))
	if is_best:
		voice.play_line("new_best")
	else:
		voice.play_line("win")
	var has_next: bool = board_index + 1 < Boards.board_count()
	hud.show_win(int(score), int(distance), stars_collected, Save.best_score(board_index), is_best, has_next, rating, star_pct, _run_clock, par_time)


func _game_over() -> void:
	if state == State.OVER:
		return
	state = State.OVER
	_over_msec = Time.get_ticks_msec()
	var is_best: bool = false
	if bool(board.get("is_endless", false)):
		is_best = Save.record_endless_run(int(score), int(distance), stars_collected)
		Music.play_sfx("fall")
		if is_best:
			voice.play_line("new_best")
		hud.show_game_over(int(score), int(distance), stars_collected, Save.endless_high_score, is_best)
	else:
		is_best = Save.record_run(board_index, int(score), stars_collected, false)
		Music.play_sfx("fall")
		if is_best:
			voice.play_line("new_best")
		hud.show_game_over(int(score), int(distance), stars_collected, Save.best_score(board_index), is_best)


func _fail() -> void:
	if state == State.FAIL:
		return
	state = State.FAIL
	_over_msec = Time.get_ticks_msec()
	Save.record_run(board_index, int(score), stars_collected, false)
	Music.play_sfx("fall")
	hud.show_fail(board.get("objective", {}).get("label", ""), int(score), int(distance), stars_collected)


func _on_retry() -> void:
	_instant_retry()


func _on_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/roadmap.tscn")


func _on_next() -> void:
	Engine.time_scale = 1.0
	Boards.selected_board = mini(board_index + 1, Boards.board_count() - 1)
	get_tree().reload_current_scene()


func _on_mute() -> void:
	Music.set_muted(not Music.is_muted())
	hud.set_mute_icon(not Music.is_muted())
