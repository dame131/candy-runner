extends Node3D
## Dijah Dash — game controller.
## Auto-run forward, swipe to steer between 3 lanes, tap to jump.
## 3 hearts, Sugar Rush streaks, per-board objectives, power-ups, juice.

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


func _ready() -> void:
	board_index = Boards.selected_board
	board = Boards.get_board(board_index)
	base_speed = float(board.get("speed", 9.0))
	speed = base_speed
	finish_z = -float(board.get("length", 300))
	rng.seed = randi()
	randomize()

	# --- environment (per-board sky/fog) ---
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Boards.palette_color(board, "sky")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 0.95, 0.95)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Boards.palette_color(board, "fog")
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

	# --- glossy syrup sea below the track ---
	var sea_mesh := PlaneMesh.new()
	sea_mesh.size = Vector2(240, 240)
	_sea = MeshInstance3D.new()
	_sea.mesh = sea_mesh
	var sea_mat := StandardMaterial3D.new()
	sea_mat.albedo_color = Boards.palette_color(board, "sea")
	sea_mat.roughness = 0.15
	sea_mat.metallic = 0.25
	_sea.material_override = sea_mat
	_sea.position = Vector3(0, -2.5, -40)
	add_child(_sea)

	# --- player + Dijah ---
	player = Node3D.new()
	player.position = Vector3(0, 0, 0)
	add_child(player)
	character = DijahCharacter.new()
	player.add_child(character)
	character.set_outfit(Boards.OUTFITS[Save.outfit_equipped])

	# --- chase camera: behind the hero, hero small in frame ---
	camera = Camera3D.new()
	camera.fov = 60.0
	camera.near = 0.1
	camera.far = 250.0
	camera.position = Vector3(0, 4.6, 7.8)
	add_child(camera)

	# --- track ---
	builder = TrackBuilder.new(board, rng)
	while next_seg_z > -SPAWN_AHEAD:
		_spawn_segment()

	# --- HUD ---
	hud = Hud.new()
	add_child(hud)
	hud.retry_pressed.connect(_on_retry)
	hud.menu_pressed.connect(_on_menu)
	hud.next_pressed.connect(_on_next)
	hud.mute_pressed.connect(_on_mute)

	# --- Dijah's voice lines (speech bubble + spoken audio) ---
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
	_touch_time += delta
	if state == State.FALLING:
		fall_timer -= delta
		player_y -= delta * 6.0
		player.position.y = player_y
		character.rotation.y += delta * 10.0
		if fall_timer <= 0.0:
			character.rotation.y = 0.0
			character.reset_pose()
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
	magnet_timer = maxf(0.0, magnet_timer - delta)
	speed_timer = maxf(0.0, speed_timer - delta)
	score2x_timer = maxf(0.0, score2x_timer - delta)
	sour_timer = maxf(0.0, sour_timer - delta)
	invincible = maxf(0.0, invincible - delta)
	stumble_timer = maxf(0.0, stumble_timer - delta)

	# --- speed ---
	var factor: float = 1.0
	if sour_timer > 0.0:
		factor *= 0.5
	if speed_timer > 0.0:
		factor *= 1.6
	if stumble_timer > 0.0:
		factor *= 0.3
	speed = (base_speed + minf(distance * 0.003, 3.0)) * factor
	if _on_sticky:
		speed *= 0.5

	# --- forward motion + steering ---
	player.position.z -= speed * delta
	distance = -player.position.z
	var want_x: float = clampf(target_x + wind_offset, -3.3, 3.3)
	player.position.x = lerpf(player.position.x, want_x, delta * 10.0)

	# --- jumping (floaty, ~30 degree tilt in the air) ---
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
	player.position.y = player_y

	# invincibility flashing
	character.visible = invincible <= 0.0 or int(invincible * 12.0) % 2 == 0

	# --- segments ---
	if next_seg_z > player.position.z - SPAWN_AHEAD and not _finish_spawned:
		_spawn_segment()
	_cleanup_segments()

	# --- obstacles ---
	_on_sticky = false
	var wind_dir: int = 0
	for ob in active_obstacles:
		if not is_instance_valid(ob):
			continue
		ob.update_obstacle(delta, player.position.z)
		var res: String = ob.check_player(player.global_position, player_y)
		match res:
			"fall":
				_on_fall()
				if state != State.PLAYING:
					return
			"hit":
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
	if wind_dir != 0:
		wind_offset = clampf(wind_offset + float(wind_dir) * delta * 2.0, -2.0, 2.0)
	else:
		wind_offset = lerpf(wind_offset, 0.0, delta * 3.0)

	# --- stars ---
	for s in active_stars:
		if not is_instance_valid(s) or s.collected:
			continue
		s.update_star(delta, player.global_position + Vector3(0, player_y + 0.9, 0), magnet_timer > 0.0)
		var sp: Vector3 = s.global_position
		if absf(sp.z - player.position.z) < 1.1 and absf(sp.x - player.position.x) < 1.2 and absf(sp.y - (player_y + 0.9)) < 1.4:
			_collect_star(s)
		elif sp.z > player.position.z + 2.0:
			s.missed = true
			stars_missed += 1
			# Only break the streak if the missed star was in the player's lane.
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

	# --- sugar rush: speed lines + wider FOV ---
	var rush: bool = streak >= 5
	hud.set_speed_lines(rush)
	camera.fov = lerpf(camera.fov, 68.0 if rush else 60.0, delta * 3.0)

	# --- objectives ---
	var stats: Dictionary = _stats()
	if Boards.objective_met_now(board, stats):
		_win()
		return
	if board.get("objective", {}).get("type", "") == "timed_collect":
		if time_alive > float(board["objective"].get("target2", 45)) and stars_collected < int(board["objective"].get("target", 20)):
			_fail()
			return
	if player.position.z <= finish_z and not finished:
		finished = true
		if Boards.objective_met_at_finish(board, stats):
			_win()
		else:
			_fail()
		return

	# --- camera + sea follow ---
	camera.position = Vector3(player.position.x * 0.35, 4.6, player.position.z + 7.8)
	camera.look_at(Vector3(player.position.x * 0.5, 1.0, player.position.z - 8.0))
	_sea.position = Vector3(0, -2.5, player.position.z - 40.0)

	_update_hud()


func _track_hole(ob: Obstacle) -> void:
	if not ob.is_hole:
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
				if ob.perfect:
					perfect_jumps += 1
		elif dx < 3.3 and player_y < 0.3:
			# threaded past a hole in the next lane: near miss!
			near_misses += 1
			score += 50.0
			hud.show_message("NEAR MISS +50", Color.html("#5fe3c0"), 1.0)
			Music.play_sfx("streak")
			voice.play_line("near_miss")


func _score_mult() -> float:
	var m: float = 1.0
	if streak >= 5:
		m *= 1.0 + minf(float(streak), 20.0) * 0.1
	if score2x_timer > 0.0:
		m *= 2.0
	if speed_timer > 0.0:
		m *= 1.5
	return m


func _rush_mult() -> float:
	if streak >= 5:
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
	hud.update_hud(int(score), int(distance), maxi(Save.best_score(board_index), int(score)), _rush_mult(), stars_collected, streak, hearts, Boards.objective_progress(board, _stats()))


# --- input: swipe to steer, tap to jump ---

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_start = t.position
			_touch_time = 0.0
			_touch_moved = false
		else:
			if not _touch_moved and _touch_time < 0.35:
				_do_jump()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_touch_moved = true
		var dx: float = d.position.x - _touch_start.x
		if dx > 90.0:
			_do_steer(1)
			_touch_start = d.position
		elif dx < -90.0:
			_do_steer(-1)
			_touch_start = d.position
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_LEFT or k.keycode == KEY_A:
				_do_steer(-1)
			elif k.keycode == KEY_RIGHT or k.keycode == KEY_D:
				_do_steer(1)
			elif k.keycode == KEY_SPACE or k.keycode == KEY_UP or k.keycode == KEY_W:
				_do_jump()


func _do_steer(dir: int) -> void:
	if state != State.PLAYING:
		return
	var new_lane: int = clampi(lane + dir, -1, 1)
	if new_lane != lane:
		lane = new_lane
		target_x = float(lane) * LANE_X
		used_steer = true


func _do_jump() -> void:
	if state != State.PLAYING or not grounded:
		return
	grounded = false
	vel_y = JUMP_V
	used_jump = true
	Music.play_sfx("jump")


# --- falls / hits ---

func _on_fall() -> void:
	if invincible > 0.0 or state != State.PLAYING:
		return
	if shield_on:
		shield_on = false
		invincible = 1.2
		vel_y = 5.0
		grounded = false
		player_y = 0.4
		hud.show_message("SHIELD SAVED YOU!", Color.html("#00e5ff"), 1.4)
		Music.play_sfx("streak")
		return
	hearts -= 1
	falls += 1
	streak = 0
	Music.play_sfx("fall")
	voice.play_line("fall")
	state = State.FALLING
	fall_timer = 0.7
	vel_y = 0.0


func _on_hit(ob: Obstacle) -> void:
	if invincible > 0.0 or state != State.PLAYING:
		return
	if shield_on:
		shield_on = false
		ob.consumed = true
		invincible = 1.2
		hud.show_message("SHIELD!", Color.html("#00e5ff"), 1.2)
		Music.play_sfx("streak")
		return
	hearts -= 1
	falls += 1
	streak = 0
	ob.consumed = true
	invincible = 1.5
	stumble_timer = 0.8
	Music.play_sfx("fall")
	voice.play_line("fall")
	if hearts <= 0:
		_game_over()


# --- pickups ---

func _collect_star(s: Star) -> void:
	s.collect()
	stars_collected += s.value
	streak += 1
	max_streak = maxi(max_streak, streak)
	score += float(s.value) * 10.0 * _score_mult()
	_spawn_burst(s.global_position, Color.html("#ffd23f") if s.kind == "normal" else Color.html("#ff8a00"), 24)
	Music.play_sfx("bigpop" if s.kind != "normal" else "pop")
	if s.kind == "big":
		voice.play_line("big_star")
	elif s.kind == "rainbow":
		voice.play_line("rainbow_star")
	else:
		voice.play_general()
	if streak == 5:
		hud.show_message("SUGAR RUSH!", Color.html("#ff2fb3"), 1.4)
		Music.play_sfx("streak")
	s.queue_free()


func _collect_powerup(p: PowerUp) -> void:
	p.collect()
	match p.kind:
		"speed":
			speed_timer = 5.0
			hud.show_message("SPEED BOOST!", Color.html("#ffd23f"), 1.2)
			voice.play_line("speed_boost")
		"shield":
			shield_on = true
			hud.show_message("SHIELD!", Color.html("#00e5ff"), 1.2)
		"magnet":
			magnet_timer = 8.0
			hud.show_message("STAR MAGNET!", Color.html("#ff2e4d"), 1.2)
		"2x":
			score2x_timer = 10.0
			hud.show_message("2x SCORE!", Color.html("#b967ff"), 1.2)
		"sour":
			sour_timer = 5.0
			streak = 0
			hud.show_message("SOUR! SLOW DOWN!", Color.html("#7ed957"), 1.4)
			Music.play_sfx("sour")
			voice.play_line("sour_star")
			p.queue_free()
			return
	Music.play_sfx("streak")
	_spawn_burst(p.global_position, Color.html("#ffffff"), 16)
	p.queue_free()


# --- particles ---

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
	var t := get_tree().create_timer(1.2)
	t.timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)


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
	var t := get_tree().create_timer(2.2)
	t.timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free()
	)


# --- endings ---

func _win() -> void:
	if state == State.WIN:
		return
	state = State.WIN
	var is_best: bool = Save.record_run(board_index, int(score), stars_collected, true)
	Music.play_sfx("win")
	if is_best:
		_spawn_confetti(player.global_position + Vector3(0, 2, -3))
		voice.play_line("new_best")
	else:
		voice.play_line("win")
	var has_next: bool = board_index + 1 < Boards.board_count()
	hud.show_win(int(score), int(distance), stars_collected, Save.best_score(board_index), is_best, has_next)


func _game_over() -> void:
	if state == State.OVER:
		return
	state = State.OVER
	var is_best: bool = Save.record_run(board_index, int(score), stars_collected, false)
	Music.play_sfx("fall")
	if is_best:
		voice.play_line("new_best")
	hud.show_game_over(int(score), int(distance), stars_collected, Save.best_score(board_index), is_best)


func _fail() -> void:
	if state == State.FAIL:
		return
	state = State.FAIL
	Save.record_run(board_index, int(score), stars_collected, false)
	Music.play_sfx("fall")
	hud.show_fail(board.get("objective", {}).get("label", ""), int(score), int(distance), stars_collected)


# --- HUD buttons ---

func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/roadmap.tscn")


func _on_next() -> void:
	Boards.selected_board = mini(board_index + 1, Boards.board_count() - 1)
	get_tree().reload_current_scene()


func _on_mute() -> void:
	Music.set_muted(not Music.is_muted())
	hud.set_mute_icon(not Music.is_muted())
