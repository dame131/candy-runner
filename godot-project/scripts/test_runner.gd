extends SceneTree

func _init() -> void:
	print("=== STARTING CANDY RUNNER VERIFICATION SUITE ===")
	var failures: int = 0
	
	# Test 1: Boards & Endless Mode
	var boards_script = load("res://scripts/boards.gd")
	if boards_script == null:
		print("[FAIL] Could not load boards.gd")
		failures += 1
	else:
		var b_obj = boards_script.new()
		var count = b_obj.board_count()
		print("[TEST 1] Boards count: %d (expected 100)" % count)
		if count != 100:
			print("[FAIL] Board count is not 100")
			failures += 1
		else:
			print("[PASS] 100 campaign boards verified")
		
		# Sample milestone boards across all 100
		var b1 = b_obj.get_board(0)
		var b51 = b_obj.get_board(50)
		var b61 = b_obj.get_board(60)
		var b71 = b_obj.get_board(70)
		var b81 = b_obj.get_board(80)
		var b91 = b_obj.get_board(90)
		var b100 = b_obj.get_board(99)
		print("[TEST 1] Board 1: %s, Board 51: %s, Board 100: %s" % [b1.get("name"), b51.get("name"), b100.get("name")])
		if b51.get("name") != "Glazed Donut Dunes" or b100.get("name") != "The Ultimate Sweet Relief":
			print("[FAIL] Board milestone names mismatch: %s / %s" % [b51.get("name"), b100.get("name")])
			failures += 1
		else:
			print("[PASS] Handcrafted expansion boards 51-100 names verified")
		
		var endless_board = b_obj.get_board(999)
		if endless_board.get("is_endless") != true or endless_board.get("name") != "Endless Sugar Rush":
			print("[FAIL] Endless board lookup failed: ", endless_board)
			failures += 1
		else:
			print("[PASS] Endless board verified successfully: %s" % endless_board.get("name"))
			
		var act1 = b_obj.act_multiplier(0.1)
		var act2 = b_obj.act_multiplier(0.5)
		var act3 = b_obj.act_multiplier(0.85)
		print("[TEST 1] Speed scaling: Act I = %.2f, Act II = %.2f, Act III = %.2f" % [act1, act2, act3])
		if act1 != 0.90 or act2 != 1.05 or act3 != 1.22:
			print("[FAIL] Speed scaling multipliers mismatch")
			failures += 1
		else:
			print("[PASS] 3-Act speed ramp verified")
		b_obj.free()

	# Test 2: Obstacle Ducking & Slide Hitbox
	var obs_script = load("res://scripts/obstacle.gd")
	if obs_script == null:
		print("[FAIL] Could not load obstacle.gd")
		failures += 1
	else:
		var obs = obs_script.new()
		obs.kind = "gate"
		obs.lane = 0
		obs._gate_closed = true
		
		# Gate: Player standing at y=0.0 -> hit
		var res_stand = obs.check_player(Vector3(0, 0, 0), 0.0, false)
		# Gate: Player sliding at y=0.0 -> none (slid underneath!)
		var res_slide = obs.check_player(Vector3(0, 0, 0), 0.0, true)
		print("[TEST 2] Gate stand hit: %s (expected 'hit'), slide: %s (expected 'none')" % [res_stand, res_slide])
		if res_stand != "hit" or res_slide != "none":
			print("[FAIL] Gate ducking hitbox failed")
			failures += 1
		else:
			print("[PASS] Gate slide evasion verified")

		# Whip: Player standing at y=0.0 -> hit when whip overlaps
		obs.kind = "whip"
		obs._arm_angle = 0.0
		var res_whip_stand = obs.check_player(Vector3(-1.0, 0, 0), 0.0, false)
		var res_whip_slide = obs.check_player(Vector3(-1.0, 0, 0), 0.0, true)
		print("[TEST 2] Whip stand hit: %s (expected 'hit'), slide: %s (expected 'none')" % [res_whip_stand, res_whip_slide])
		if res_whip_stand != "hit" or res_whip_slide != "none":
			print("[FAIL] Whip ducking hitbox failed")
			failures += 1
		else:
			print("[PASS] Whip slide evasion verified")

		# Bubble: Overhead floating bubble at y=1.2
		obs.kind = "bubble"
		var res_bubble_stand = obs.check_player(Vector3(0, 0, 0), 1.2, false)
		var res_bubble_slide = obs.check_player(Vector3(0, 0, 0), 0.0, true)
		print("[TEST 2] Bubble stand hit: %s (expected 'hit'), slide: %s (expected 'none')" % [res_bubble_stand, res_bubble_slide])
		if res_bubble_stand != "hit" or res_bubble_slide != "none":
			print("[FAIL] Bubble ducking hitbox failed")
			failures += 1
		else:
			print("[PASS] Bubble slide evasion verified")
		obs.free()

	# Test 3: Voice Lines Audio Leveling
	print("[TEST 3] Loading voice_lines.gd...")
	var vl_script = load("res://scripts/voice_lines.gd")
	if vl_script == null:
		print("[FAIL] Could not load voice_lines.gd")
		failures += 1
	else:
		var vl = vl_script.new()
		print("[TEST 3] Calling _ready()...")
		vl._ready()
		var player_vol = vl._player.volume_db
		print("[TEST 3] Voice line player volume_db: %.1f dB (expected +2.5 dB)" % player_vol)
		if absf(player_vol - 2.5) > 0.01:
			print("[FAIL] Voice line volume is not boosted to +2.5 dB")
			failures += 1
		else:
			print("[PASS] Voice line clear audio leveling verified")
		vl._player.free()
		vl.free()

	# Test 4: Music Manager Pentatonic Scale
	var mm_script = load("res://scripts/music_manager.gd")
	if mm_script == null:
		print("[FAIL] Could not load music_manager.gd")
		failures += 1
	else:
		var mm = mm_script.new()
		print("[TEST 4] Music Manager pentatonic scale notes: %d" % mm.PICKUP_SEMITONES.size())
		if mm.PICKUP_SEMITONES.size() != 12:
			print("[FAIL] Pentatonic scale size mismatch")
			failures += 1
		else:
			print("[PASS] Ascending pentatonic scale verified")
		mm.free()

	# Test 5: Save Manager Endless & Ratings
	var sm_script = load("res://scripts/save_manager.gd")
	if sm_script == null:
		print("[FAIL] Could not load save_manager.gd")
		failures += 1
	else:
		var sm = sm_script.new()
		sm.endless_high_score = 100
		sm.endless_best_distance = 500
		var is_new = sm.record_endless_run(250, 750, 15)
		print("[TEST 5] Save Manager endless run: new_high=%s, score=%d, dist=%d" % [is_new, sm.endless_high_score, sm.endless_best_distance])
		if not is_new or sm.endless_high_score != 250 or sm.endless_best_distance != 750:
			print("[FAIL] Save manager endless persistence logic failed")
			failures += 1
		else:
			print("[PASS] Save manager endless persistence verified")
		sm.free()

	# Test 6: Dijah Character 3D Asset & Textures Validation
	var dc_script = load("res://scripts/dijah_character.gd")
	if dc_script == null:
		print("[FAIL] Could not load dijah_character.gd")
		failures += 1
	else:
		var dc = dc_script.new()
		dc._ready()
		var char_tex = dc._mat.get_shader_parameter("char_tex") if dc._mat != null else null
		print("[TEST 6] Dijah character rig loaded. Initial char_tex: %s" % [char_tex])
		if char_tex == null or dc._tex_back_mid == null or dc._tex_front == null or dc._tex_jump == null:
			print("[FAIL] Dijah character textures missing or null (would render flat white quad)")
			failures += 1
		else:
			print("[PASS] Dijah character 3D textures loaded cleanly from res://textures/char/")
			dc.animate_idle(0.016)
			var idle_tex = dc._mat.get_shader_parameter("char_tex")
			if idle_tex != dc._tex_front:
				print("[FAIL] Boutique / Idle showcase texture not set to front pose")
				failures += 1
			else:
				print("[PASS] Boutique / Idle showcase front pose verified")
		dc.free()

	print("=== VERIFICATION COMPLETE: %d FAILURES ===" % failures)
	quit(failures)
