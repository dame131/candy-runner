class_name BoardData
extends Node
## Dijah's Delights Candy Run — all 21 boards as data.
## Each board: look (palette), objective, obstacle type, speed, length, music.
## Palettes are cherry-red friendly, never blue — EXCEPT board 21
## "Blueberry Bash", deliberately blueberry-purple because the joke is
## that Dijah hates blueberries (ordered by Damon).

# Objective types:
#   collect      - collect N sugar stars (immediate win)
#   distance     - run N meters (win at finish line; no_fall=true means any fall fails)
#   jumps        - clear N holes by jumping (immediate win)
#   score        - reach N points (immediate win)
#   streak       - collect N stars in a row without missing one (immediate win)
#   survive      - stay alive N seconds (immediate win)
#   streak_hold  - reach streak N and finish the run (win at finish)
#   perfect      - land N perfect jumps (immediate win)
#   collect_all  - collect EVERY star spawned before the finish (win at finish)
#   combo        - distance N AND collect M stars (win at finish)
#   score_double - reach N points, streak points count double (immediate win)
#   no_jump      - finish the run without jumping (win at finish)
#   jump_all     - jump every hole encountered (win at finish)
#   timed_collect- collect N stars within T seconds (immediate win / fail on timeout)
#   survive_fast - survive N seconds at double speed (immediate win)
#   near_miss    - near-miss N holes (immediate win)
#   finale       - score N AND distance M in one run (win at finish)

const BOARDS: Array = [
	{
		"name": "Candyland", "look": "pink syrup",
		"palette": {"tile": "#bd8143", "tile_dark": "#9a652f", "side": "#2e1a0c", "rail_left": "#ff5c8a", "rail_right": "#5fe3c0", "rim": "#ff5c8a", "syrup": "#7a1030", "sea": "#ff2e7e", "sky": "#ffb3cf", "fog": "#ff8fb8", "accent": "#ffd23f", "scenery": "#ff9ec7"},
		"objective": {"type": "collect", "target": 10, "label": "Collect 10 sugar stars"},
		"obstacle": "hole", "speed": 9.0, "length": 300,
		"music": {"tempo": 118, "root": 60, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Chocolate World", "look": "caramel river",
		"palette": {"tile": "#5a3a22", "tile_dark": "#4a2c18", "side": "#2a1608", "rail_left": "#ffd23f", "rail_right": "#ff9ec7", "rim": "#ffb347", "syrup": "#3a1c05", "sea": "#c47a1e", "sky": "#ffe0b3", "fog": "#f7c98f", "accent": "#ffd23f", "scenery": "#8a5a2a"},
		"objective": {"type": "distance", "target": 300, "no_fall": true, "label": "Run 300m without falling"},
		"obstacle": "wide_pit", "speed": 9.5, "length": 300,
		"music": {"tempo": 104, "root": 55, "scale": [0, 3, 5, 7, 10], "wave": 1},
	},
	{
		"name": "Gummy Jungle", "look": "green jelly",
		"palette": {"tile": "#7ed957", "tile_dark": "#5cbf3a", "side": "#2a4a1a", "rail_left": "#a8e063", "rail_right": "#ffb347", "rim": "#ff8a00", "syrup": "#1e4d12", "sea": "#4ecb5d", "sky": "#e3ffd6", "fog": "#c8f7b0", "accent": "#ff8a00", "scenery": "#3fae5a"},
		"objective": {"type": "jumps", "target": 10, "label": "Jump 10 holes"},
		"obstacle": "blocker", "speed": 9.5, "length": 350,
		"music": {"tempo": 126, "root": 62, "scale": [0, 2, 3, 7, 9], "wave": 0},
	},
	{
		"name": "Neon Night", "look": "purple glow",
		"palette": {"tile": "#3a2a5e", "tile_dark": "#2c1e4a", "side": "#150a2e", "rail_left": "#ff2fb3", "rail_right": "#00e5ff", "rim": "#ff2fb3", "syrup": "#12041f", "sea": "#b5179e", "sky": "#2a1052", "fog": "#3d1a6e", "accent": "#00e5ff", "scenery": "#7b2fbe"},
		"objective": {"type": "score", "target": 1000, "label": "Score 1,000 points"},
		"obstacle": "sliding_hole", "speed": 10.0, "length": 400,
		"music": {"tempo": 132, "root": 57, "scale": [0, 3, 5, 6, 10], "wave": 1},
	},
	{
		"name": "Strawberry Fields", "look": "red",
		"palette": {"tile": "#f7d774", "tile_dark": "#e8c25e", "side": "#5e1a1a", "rail_left": "#ff2e4d", "rail_right": "#7ed957", "rim": "#ff2e4d", "syrup": "#5e0a1a", "sea": "#ff5c6e", "sky": "#ffe3e3", "fog": "#ffc9c9", "accent": "#ff2e4d", "scenery": "#e85d75"},
		"objective": {"type": "streak", "target": 5, "label": "Collect 5 stars in a row, miss none"},
		"obstacle": "rolling_ball", "speed": 10.0, "length": 350,
		"music": {"tempo": 122, "root": 64, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Mint Meadow", "look": "mint green",
		"palette": {"tile": "#b8f1cc", "tile_dark": "#9fe6b8", "side": "#1e4d33", "rail_left": "#2ee6a8", "rail_right": "#ff5c8a", "rim": "#2ee6a8", "syrup": "#0d3d26", "sea": "#3fd9a4", "sky": "#e3fff2", "fog": "#c8ffe9", "accent": "#ff5c8a", "scenery": "#5ec98f"},
		"objective": {"type": "near_miss", "target": 5, "label": "Near-miss 5 holes"},
		"obstacle": "pinwheel", "speed": 10.0, "length": 400,
		"music": {"tempo": 128, "root": 65, "scale": [0, 2, 5, 7, 9], "wave": 0},
	},
	{
		"name": "Caramel Sunset", "look": "amber/gold",
		"palette": {"tile": "#f2b544", "tile_dark": "#dd9c2e", "side": "#4a2c05", "rail_left": "#ff8a00", "rail_right": "#ff5c8a", "rim": "#ff8a00", "syrup": "#4a1e00", "sea": "#e07b00", "sky": "#ffe8c2", "fog": "#ffd9a0", "accent": "#ff8a00", "scenery": "#d98a2b"},
		"objective": {"type": "survive", "target": 60, "label": "Survive 60 seconds"},
		"obstacle": "sticky_patch", "speed": 9.0, "length": 540,
		"music": {"tempo": 96, "root": 58, "scale": [0, 2, 4, 7, 10], "wave": 1},
	},
	{
		"name": "Bubblegum Blvd", "look": "pink/purple",
		"palette": {"tile": "#f7a8d8", "tile_dark": "#e88ec2", "side": "#4a1a3d", "rail_left": "#ff5ce1", "rail_right": "#b967ff", "rim": "#ff5ce1", "syrup": "#3d0a33", "sea": "#e85cc8", "sky": "#ffe3f6", "fog": "#ffc9ee", "accent": "#b967ff", "scenery": "#d96ab8"},
		"objective": {"type": "streak_hold", "target": 5, "label": "Keep a Sweet Streak x5 the whole run"},
		"obstacle": "bubble", "speed": 10.0, "length": 400,
		"music": {"tempo": 124, "root": 63, "scale": [0, 3, 5, 7, 10], "wave": 0},
	},
	{
		"name": "Licorice Lane", "look": "dark purple",
		"palette": {"tile": "#4a3a5e", "tile_dark": "#382a4a", "side": "#120a1e", "rail_left": "#b967ff", "rail_right": "#ff5c8a", "rim": "#b967ff", "syrup": "#0d0518", "sea": "#5e2a8a", "sky": "#e8dcff", "fog": "#d5c2f7", "accent": "#ff5c8a", "scenery": "#6e4a9e"},
		"objective": {"type": "perfect", "target": 10, "label": "Land 10 perfect jumps"},
		"obstacle": "whip", "speed": 10.5, "length": 400,
		"music": {"tempo": 130, "root": 56, "scale": [0, 3, 5, 6, 10], "wave": 1},
	},
	{
		"name": "Marshmallow Clouds", "look": "white/cream",
		"palette": {"tile": "#fff3e0", "tile_dark": "#ffe3c2", "side": "#8a6a4a", "rail_left": "#ff9ec7", "rail_right": "#ffd23f", "rim": "#ff9ec7", "syrup": "#e8d5b5", "sea": "#fff0f5", "sky": "#fff8f0", "fog": "#fff0e0", "accent": "#ff5c8a", "scenery": "#f7d9a8"},
		"objective": {"type": "collect_all", "target": 0, "label": "Collect EVERY star on the track"},
		"obstacle": "cloud_gap", "speed": 9.5, "length": 400,
		"music": {"tempo": 100, "root": 67, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Cherry Blossom", "look": "pink/red blossoms",
		"palette": {"tile": "#f7c6c6", "tile_dark": "#e8a8a8", "side": "#5e1a24", "rail_left": "#ff5c8a", "rail_right": "#ffd23f", "rim": "#ff5c8a", "syrup": "#4a0a14", "sea": "#ff7a9e", "sky": "#ffeef0", "fog": "#ffd9de", "accent": "#ff2e4d", "scenery": "#e88aa0"},
		"objective": {"type": "combo", "target": 500, "target2": 20, "label": "Run 500m and grab at least 20 stars"},
		"obstacle": "rolling_pit", "speed": 10.0, "length": 500,
		"music": {"tempo": 116, "root": 61, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Toffee Town", "look": "brown/gold",
		"palette": {"tile": "#c68a3a", "tile_dark": "#a86f28", "side": "#3a2405", "rail_left": "#ffd23f", "rail_right": "#ff8a00", "rim": "#ffd23f", "syrup": "#2a1800", "sea": "#b87a1e", "sky": "#ffefd0", "fog": "#ffe0a8", "accent": "#ff8a00", "scenery": "#a87a3a"},
		"objective": {"type": "score_double", "target": 2500, "label": "Score 2,500 — streaks count double"},
		"obstacle": "rising_block", "speed": 10.0, "length": 500,
		"music": {"tempo": 112, "root": 53, "scale": [0, 2, 3, 7, 8], "wave": 1},
	},
	{
		"name": "Jellybean Junction", "look": "rainbow",
		"palette": {"tile": "#f7e06a", "tile_dark": "#e8cc4a", "side": "#4a2c5e", "rail_left": "#ff5c8a", "rail_right": "#5fe3c0", "rim": "#ff5ce1", "syrup": "#3d0a33", "sea": "#ff8ad8", "sky": "#fff3d6", "fog": "#ffe8b3", "accent": "#b967ff", "scenery": "#e88ad8"},
		"objective": {"type": "no_jump", "target": 0, "label": "Steer around every hole — no jumping"},
		"obstacle": "bouncing_bean", "speed": 10.0, "length": 450,
		"music": {"tempo": 134, "root": 60, "scale": [0, 2, 4, 5, 7, 9], "wave": 0},
	},
	{
		"name": "Cotton Candy Sky", "look": "pastel pink/white",
		"palette": {"tile": "#ffe0f0", "tile_dark": "#ffc9e8", "side": "#7a4a68", "rail_left": "#ff9ec7", "rail_right": "#ffffff", "rim": "#ff9ec7", "syrup": "#e8b8d8", "sea": "#ffd6ec", "sky": "#fff5fb", "fog": "#ffeef8", "accent": "#ff5c8a", "scenery": "#f7b8d8"},
		"objective": {"type": "jump_all", "target": 0, "label": "Jump every hole — no steering"},
		"obstacle": "wind_gust", "speed": 9.5, "length": 450,
		"music": {"tempo": 108, "root": 69, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Fudge Falls", "look": "dark brown",
		"palette": {"tile": "#4a2c1a", "tile_dark": "#38200f", "side": "#120805", "rail_left": "#ff8a00", "rail_right": "#ffd23f", "rim": "#ff8a00", "syrup": "#0d0500", "sea": "#5e2a10", "sky": "#e8d5c2", "fog": "#d9c2a8", "accent": "#ffd23f", "scenery": "#6e4423"},
		"objective": {"type": "timed_collect", "target": 20, "target2": 45, "label": "Collect 20 stars in 45 seconds"},
		"obstacle": "falling_chunk", "speed": 10.0, "length": 400,
		"music": {"tempo": 140, "root": 50, "scale": [0, 3, 5, 7, 10], "wave": 1},
	},
	{
		"name": "Lemon Drop Lagoon", "look": "yellow",
		"palette": {"tile": "#ffe95e", "tile_dark": "#f7d93a", "side": "#5e4a05", "rail_left": "#ffd23f", "rail_right": "#7ed957", "rim": "#ffd23f", "syrup": "#4a3800", "sea": "#ffe14d", "sky": "#fffbe0", "fog": "#fff3a8", "accent": "#7ed957", "scenery": "#e8c53a"},
		"objective": {"type": "survive_fast", "target": 90, "label": "Survive 90 seconds at double speed"},
		"obstacle": "bouncing_drop", "speed": 18.0, "length": 1600,
		"music": {"tempo": 150, "root": 62, "scale": [0, 2, 4, 7, 9], "wave": 1},
	},
	{
		"name": "Raspberry Ridge", "look": "red/purple",
		"palette": {"tile": "#e85d75", "tile_dark": "#d94a62", "side": "#3d0a24", "rail_left": "#ff2e4d", "rail_right": "#b967ff", "rim": "#ff2e4d", "syrup": "#2a0518", "sea": "#d94a7a", "sky": "#ffe8ec", "fog": "#ffc9d6", "accent": "#b967ff", "scenery": "#c24a6e"},
		"objective": {"type": "near_miss", "target": 10, "label": "Near-miss 10 holes"},
		"obstacle": "thorn_bush", "speed": 10.5, "length": 500,
		"music": {"tempo": 126, "root": 59, "scale": [0, 3, 5, 7, 10], "wave": 0},
	},
	{
		"name": "Peppermint Peak", "look": "red/white",
		"palette": {"tile": "#f7f0e8", "tile_dark": "#e8ddd2", "side": "#5e1a1a", "rail_left": "#ff2e4d", "rail_right": "#ffffff", "rim": "#ff2e4d", "syrup": "#4a0a0a", "sea": "#ffb8c2", "sky": "#fff0f0", "fog": "#ffe0e0", "accent": "#ff2e4d", "scenery": "#e88a8a"},
		"objective": {"type": "score", "target": 5000, "label": "Score 5,000 points"},
		"obstacle": "gate", "speed": 10.5, "length": 600,
		"music": {"tempo": 136, "root": 64, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Golden Honeycomb", "look": "gold/amber",
		"palette": {"tile": "#ffd23f", "tile_dark": "#f7c22a", "side": "#4a3405", "rail_left": "#ff8a00", "rail_right": "#ff5c8a", "rim": "#ff8a00", "syrup": "#3a2400", "sea": "#ffb300", "sky": "#fff3c2", "fog": "#ffe8a0", "accent": "#ff8a00", "scenery": "#d9a52a"},
		"objective": {"type": "distance", "target": 1000, "no_fall": true, "label": "Run 1,000m without falling"},
		"obstacle": "honeycomb_wall", "speed": 10.5, "length": 1000,
		"music": {"tempo": 120, "root": 57, "scale": [0, 2, 4, 7, 9], "wave": 1},
	},
	{
		"name": "Sugar Rush Finale", "look": "rainbow neon",
		"palette": {"tile": "#b967ff", "tile_dark": "#9e4ae8", "side": "#1e0a3d", "rail_left": "#ff2fb3", "rail_right": "#00e5ff", "rim": "#ff2fb3", "syrup": "#12041f", "sea": "#ff2fb3", "sky": "#3d1a6e", "fog": "#5e2a8a", "accent": "#ffd23f", "scenery": "#7b2fbe"},
		"objective": {"type": "finale", "target": 3000, "target2": 750, "label": "Score 3,000 AND run 750m in one run"},
		"obstacle": "mixed", "speed": 11.0, "length": 750,
		"music": {"tempo": 144, "root": 60, "scale": [0, 2, 4, 7, 9], "wave": 1},
	},
	{
		"name": "Blueberry Bash", "look": "blueberry patch",
		"palette": {"tile": "#5e3a8a", "tile_dark": "#4a2a6e", "side": "#1e0a33", "rail_left": "#7b5cd6", "rail_right": "#ff5c8a", "rim": "#7b5cd6", "syrup": "#1a0830", "sea": "#4a1a8a", "sky": "#b39ae0", "fog": "#8a68c8", "accent": "#7b5cd6", "scenery": "#6e4ab8"},
		"objective": {"type": "distance", "target": 400, "no_fall": true, "label": "Run 400m without falling"},
		"obstacle": "blueberry_roller", "speed": 10.0, "length": 400,
		"music": {"tempo": 130, "root": 57, "scale": [0, 3, 5, 7, 10], "wave": 1},
	},
]

# Outfits for the shop. Cost is in sugar stars (the currency, not the score).
const OUTFITS: Array = [
	{"name": "Teal Classic", "top": "#0e9b8a", "bottom": "#ff5c8a", "shoes": "#ffffff", "cape": "", "cost": 0},
	{"name": "Cherry Red", "top": "#e60026", "bottom": "#5b2333", "shoes": "#ffd23f", "cape": "#e60026", "cost": 150},
	{"name": "Mint Fresh", "top": "#2ee6a8", "bottom": "#ffffff", "shoes": "#ff5c8a", "cape": "", "cost": 200},
	{"name": "Golden Honey", "top": "#ffd23f", "bottom": "#8a5a2a", "shoes": "#ffffff", "cape": "#ffd23f", "cost": 300},
	{"name": "Neon Pop", "top": "#ff2fb3", "bottom": "#3a2a5e", "shoes": "#00e5ff", "cape": "#ff2fb3", "cost": 500},
]

# The board currently selected for play (set by the roadmap, read by the game).
var selected_board: int = 0


func get_board(index: int) -> Dictionary:
	if index < 0 or index >= BOARDS.size():
		return BOARDS[0]
	return BOARDS[index]


func board_count() -> int:
	return BOARDS.size()


func palette_color(board: Dictionary, key: String) -> Color:
	var p: Dictionary = board.get("palette", {})
	return Color.html(p.get(key, "#ffffff"))


## Objective text with live progress, for the HUD.
func objective_progress(board: Dictionary, stats: Dictionary) -> String:
	var o: Dictionary = board.get("objective", {})
	var t: String = o.get("type", "collect")
	var target: int = int(o.get("target", 0))
	match t:
		"collect", "score", "score_double":
			return "%s  %d / %d" % [o.get("label", ""), int(stats.get("progress", 0)), target]
		"distance":
			return "%s  %d / %d m" % [o.get("label", ""), int(stats.get("distance", 0)), target]
		"jumps", "perfect", "near_miss":
			return "%s  %d / %d" % [o.get("label", ""), int(stats.get("progress", 0)), target]
		"streak", "streak_hold":
			return "%s  streak x%d / x%d" % [o.get("label", ""), int(stats.get("streak", 0)), target]
		"survive", "survive_fast":
			return "%s  %d / %d s" % [o.get("label", ""), int(stats.get("time", 0)), target]
		"collect_all":
			return "%s  missed: %d" % [o.get("label", ""), int(stats.get("missed", 0))]
		"combo":
			return "%s  %d / %d m, %d / %d stars" % [o.get("label", ""), int(stats.get("distance", 0)), target, int(stats.get("stars", 0)), int(o.get("target2", 0))]
		"no_jump":
			return "%s" % o.get("label", "")
		"jump_all":
			return "%s  cleared %d / %d" % [o.get("label", ""), int(stats.get("cleared", 0)), int(stats.get("holes", 0))]
		"timed_collect":
			return "%s  %d / %d stars, %d s left" % [o.get("label", ""), int(stats.get("stars", 0)), target, int(stats.get("time_left", 0))]
		"finale":
			return "%s  %d / %d pts, %d / %d m" % [o.get("label", ""), int(stats.get("score", 0)), target, int(stats.get("distance", 0)), int(o.get("target2", 0))]
	return o.get("label", "")


## Immediate-win check, called every frame. Returns true when the objective
## is met right now (for objectives that can complete before the finish line).
func objective_met_now(board: Dictionary, stats: Dictionary) -> bool:
	var o: Dictionary = board.get("objective", {})
	var t: String = o.get("type", "collect")
	var target: int = int(o.get("target", 0))
	match t:
		"collect":
			return int(stats.get("stars", 0)) >= target
		"score", "score_double":
			return int(stats.get("score", 0)) >= target
		"jumps":
			return int(stats.get("cleared", 0)) >= target
		"streak":
			return int(stats.get("streak", 0)) >= target
		"perfect":
			return int(stats.get("perfect", 0)) >= target
		"near_miss":
			return int(stats.get("near_miss", 0)) >= target
		"survive", "survive_fast":
			return int(stats.get("time", 0)) >= target
		"timed_collect":
			return int(stats.get("stars", 0)) >= target
	return false


## Win check at the finish line.
func objective_met_at_finish(board: Dictionary, stats: Dictionary) -> bool:
	var o: Dictionary = board.get("objective", {})
	var t: String = o.get("type", "collect")
	var target: int = int(o.get("target", 0))
	match t:
		"distance":
			if bool(o.get("no_fall", false)) and int(stats.get("falls", 0)) > 0:
				return false
			return int(stats.get("distance", 0)) >= target
		"streak_hold":
			return int(stats.get("max_streak", 0)) >= target
		"collect_all":
			return int(stats.get("missed", 0)) == 0 and int(stats.get("spawned", 0)) > 0
		"combo":
			return int(stats.get("distance", 0)) >= target and int(stats.get("stars", 0)) >= int(o.get("target2", 0))
		"no_jump":
			return not bool(stats.get("used_jump", false))
		"jump_all":
			return int(stats.get("holes", 0)) > 0 and int(stats.get("cleared", 0)) >= int(stats.get("holes", 0))
		"finale":
			return int(stats.get("score", 0)) >= target and int(stats.get("distance", 0)) >= int(o.get("target2", 0))
		"timed_collect":
			return int(stats.get("stars", 0)) >= target
		_:
			return objective_met_now(board, stats)
