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
		"name": "Candyland", "look": "strawberry milkshake & golden waffle",
		"palette": {"tile": "#efa852", "tile_dark": "#d98c36", "side": "#6e3b16", "rail_left": "#ffffff", "rail_right": "#ffffff", "rim": "#e61938", "syrup": "#d84b7a", "sea": "#f48fb1", "sky": "#89cff0", "fog": "#dff2ff", "accent": "#ffd23f", "scenery": "#ff9ec7"},
		"objective": {"type": "collect", "target": 15, "label": "Collect 15 sugar stars (45s Rush)"},
		"obstacle": "rolling_ball", "speed": 11.5, "length": 520,
		"music": {"tempo": 124, "root": 60, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Chocolate World", "look": "caramel river",
		"palette": {"tile": "#5a3a22", "tile_dark": "#4a2c18", "side": "#2a1608", "rail_left": "#ffd23f", "rail_right": "#ff9ec7", "rim": "#ffb347", "syrup": "#3a1c05", "sea": "#c47a1e", "sky": "#ffe0b3", "fog": "#f7c98f", "accent": "#ffd23f", "scenery": "#8a5a2a"},
		"objective": {"type": "distance", "target": 540, "no_fall": true, "label": "Run 540m without falling (45s Rush)"},
		"obstacle": "wide_pit", "speed": 12.0, "length": 540,
		"music": {"tempo": 126, "root": 55, "scale": [0, 3, 5, 7, 10], "wave": 1},
	},
	{
		"name": "Gummy Jungle", "look": "green jelly",
		"palette": {"tile": "#7ed957", "tile_dark": "#5cbf3a", "side": "#2a4a1a", "rail_left": "#a8e063", "rail_right": "#ffb347", "rim": "#ff8a00", "syrup": "#1e4d12", "sea": "#4ecb5d", "sky": "#e3ffd6", "fog": "#c8f7b0", "accent": "#ff8a00", "scenery": "#3fae5a"},
		"objective": {"type": "jumps", "target": 10, "label": "Jump 10 holes (45s Rush)"},
		"obstacle": "blocker", "speed": 12.0, "length": 540,
		"music": {"tempo": 128, "root": 62, "scale": [0, 2, 3, 7, 9], "wave": 0},
	},
	{
		"name": "Neon Night", "look": "purple glow",
		"palette": {"tile": "#3a2a5e", "tile_dark": "#2c1e4a", "side": "#150a2e", "rail_left": "#ff2fb3", "rail_right": "#00e5ff", "rim": "#ff2fb3", "syrup": "#12041f", "sea": "#b5179e", "sky": "#2a1052", "fog": "#3d1a6e", "accent": "#00e5ff", "scenery": "#7b2fbe"},
		"objective": {"type": "score", "target": 1200, "label": "Score 1,200 points (45s Rush)"},
		"obstacle": "sliding_hole", "speed": 12.0, "length": 540,
		"music": {"tempo": 132, "root": 57, "scale": [0, 3, 5, 6, 10], "wave": 1},
	},
	{
		"name": "Strawberry Fields", "look": "red",
		"palette": {"tile": "#f7d774", "tile_dark": "#e8c25e", "side": "#5e1a1a", "rail_left": "#ff2e4d", "rail_right": "#7ed957", "rim": "#ff2e4d", "syrup": "#5e0a1a", "sea": "#ff5c6e", "sky": "#ffe3e3", "fog": "#ffc9c9", "accent": "#ff2e4d", "scenery": "#e85d75"},
		"objective": {"type": "streak", "target": 5, "label": "Collect 5 stars in a row (45s Rush)"},
		"obstacle": "rolling_ball", "speed": 12.0, "length": 540,
		"music": {"tempo": 128, "root": 64, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Mint Meadow", "look": "mint green",
		"palette": {"tile": "#b8f1cc", "tile_dark": "#9fe6b8", "side": "#1e4d33", "rail_left": "#2ee6a8", "rail_right": "#ff5c8a", "rim": "#2ee6a8", "syrup": "#0d3d26", "sea": "#3fd9a4", "sky": "#e3fff2", "fog": "#c8ffe9", "accent": "#ff5c8a", "scenery": "#5ec98f"},
		"objective": {"type": "near_miss", "target": 5, "label": "Near-miss 5 holes (45s Rush)"},
		"obstacle": "pinwheel", "speed": 12.0, "length": 540,
		"music": {"tempo": 130, "root": 65, "scale": [0, 2, 5, 7, 9], "wave": 0},
	},
	{
		"name": "Caramel Sunset", "look": "amber/gold",
		"palette": {"tile": "#f2b544", "tile_dark": "#dd9c2e", "side": "#4a2c05", "rail_left": "#ff8a00", "rail_right": "#ff5c8a", "rim": "#ff8a00", "syrup": "#4a1e00", "sea": "#e07b00", "sky": "#ffe8c2", "fog": "#ffd9a0", "accent": "#ff8a00", "scenery": "#d98a2b"},
		"objective": {"type": "survive", "target": 45, "label": "Survive the 45-second Sugar Rush"},
		"obstacle": "sticky_patch", "speed": 12.0, "length": 540,
		"music": {"tempo": 128, "root": 58, "scale": [0, 2, 4, 7, 10], "wave": 1},
	},
	{
		"name": "Bubblegum Blvd", "look": "pink/purple",
		"palette": {"tile": "#f7a8d8", "tile_dark": "#e88ec2", "side": "#4a1a3d", "rail_left": "#ff5ce1", "rail_right": "#b967ff", "rim": "#ff5ce1", "syrup": "#3d0a33", "sea": "#e85cc8", "sky": "#ffe3f6", "fog": "#ffc9ee", "accent": "#b967ff", "scenery": "#d96ab8"},
		"objective": {"type": "streak_hold", "target": 5, "label": "Keep a Sweet Streak x5 (45s Rush)"},
		"obstacle": "bubble", "speed": 12.0, "length": 540,
		"music": {"tempo": 130, "root": 63, "scale": [0, 3, 5, 7, 10], "wave": 0},
	},
	{
		"name": "Licorice Lane", "look": "dark purple",
		"palette": {"tile": "#4a3a5e", "tile_dark": "#382a4a", "side": "#120a1e", "rail_left": "#b967ff", "rail_right": "#ff5c8a", "rim": "#b967ff", "syrup": "#0d0518", "sea": "#5e2a8a", "sky": "#e8dcff", "fog": "#d5c2f7", "accent": "#ff5c8a", "scenery": "#6e4a9e"},
		"objective": {"type": "perfect", "target": 10, "label": "Land 10 perfect jumps (45s Rush)"},
		"obstacle": "whip", "speed": 12.2, "length": 550,
		"music": {"tempo": 132, "root": 56, "scale": [0, 3, 5, 6, 10], "wave": 1},
	},
	{
		"name": "Marshmallow Clouds", "look": "white/cream",
		"palette": {"tile": "#fff3e0", "tile_dark": "#ffe3c2", "side": "#8a6a4a", "rail_left": "#ff9ec7", "rail_right": "#ffd23f", "rim": "#ff9ec7", "syrup": "#e8d5b5", "sea": "#fff0f5", "sky": "#fff8f0", "fog": "#fff0e0", "accent": "#ff5c8a", "scenery": "#f7d9a8"},
		"objective": {"type": "collect_all", "target": 0, "label": "Collect EVERY star on the track (45s Rush)"},
		"obstacle": "cloud_gap", "speed": 12.0, "length": 540,
		"music": {"tempo": 128, "root": 67, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Cherry Blossom", "look": "pink/red blossoms",
		"palette": {"tile": "#f7c6c6", "tile_dark": "#e8a8a8", "side": "#5e1a24", "rail_left": "#ff5c8a", "rail_right": "#ffd23f", "rim": "#ff5c8a", "syrup": "#4a0a14", "sea": "#ff7a9e", "sky": "#ffeef0", "fog": "#ffd9de", "accent": "#ff2e4d", "scenery": "#e88aa0"},
		"objective": {"type": "combo", "target": 540, "target2": 20, "label": "Run 540m and grab 20 stars (45s Rush)"},
		"obstacle": "rolling_pit", "speed": 12.0, "length": 540,
		"music": {"tempo": 130, "root": 61, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Toffee Town", "look": "brown/gold",
		"palette": {"tile": "#c68a3a", "tile_dark": "#a86f28", "side": "#3a2405", "rail_left": "#ffd23f", "rail_right": "#ff8a00", "rim": "#ffd23f", "syrup": "#2a1800", "sea": "#b87a1e", "sky": "#ffefd0", "fog": "#ffe0a8", "accent": "#ff8a00", "scenery": "#a87a3a"},
		"objective": {"type": "score_double", "target": 2500, "label": "Score 2,500 — streaks count 2x (45s Rush)"},
		"obstacle": "rising_block", "speed": 12.2, "length": 550,
		"music": {"tempo": 132, "root": 53, "scale": [0, 2, 3, 7, 8], "wave": 1},
	},
	{
		"name": "Jellybean Junction", "look": "rainbow",
		"palette": {"tile": "#f7e06a", "tile_dark": "#e8cc4a", "side": "#4a2c5e", "rail_left": "#ff5c8a", "rail_right": "#5fe3c0", "rim": "#ff5ce1", "syrup": "#3d0a33", "sea": "#ff8ad8", "sky": "#fff3d6", "fog": "#ffe8b3", "accent": "#b967ff", "scenery": "#e88ad8"},
		"objective": {"type": "no_jump", "target": 0, "label": "Steer around every hole — no jumping (45s)"},
		"obstacle": "bouncing_bean", "speed": 12.0, "length": 540,
		"music": {"tempo": 134, "root": 60, "scale": [0, 2, 4, 5, 7, 9], "wave": 0},
	},
	{
		"name": "Cotton Candy Sky", "look": "pastel pink/white",
		"palette": {"tile": "#ffe0f0", "tile_dark": "#ffc9e8", "side": "#7a4a68", "rail_left": "#ff9ec7", "rail_right": "#ffffff", "rim": "#ff9ec7", "syrup": "#e8b8d8", "sea": "#ffd6ec", "sky": "#fff5fb", "fog": "#ffeef8", "accent": "#ff5c8a", "scenery": "#f7b8d8"},
		"objective": {"type": "jump_all", "target": 0, "label": "Jump every hole — no steering (45s Rush)"},
		"obstacle": "wind_gust", "speed": 12.0, "length": 540,
		"music": {"tempo": 130, "root": 69, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Fudge Falls", "look": "dark brown",
		"palette": {"tile": "#4a2c1a", "tile_dark": "#38200f", "side": "#120805", "rail_left": "#ff8a00", "rail_right": "#ffd23f", "rim": "#ff8a00", "syrup": "#0d0500", "sea": "#5e2a10", "sky": "#e8d5c2", "fog": "#d9c2a8", "accent": "#ffd23f", "scenery": "#6e4423"},
		"objective": {"type": "timed_collect", "target": 20, "target2": 45, "label": "Collect 20 stars in 45 seconds"},
		"obstacle": "falling_chunk", "speed": 12.0, "length": 540,
		"music": {"tempo": 140, "root": 50, "scale": [0, 3, 5, 7, 10], "wave": 1},
	},
	{
		"name": "Lemon Drop Lagoon", "look": "yellow",
		"palette": {"tile": "#ffe95e", "tile_dark": "#f7d93a", "side": "#5e4a05", "rail_left": "#ffd23f", "rail_right": "#7ed957", "rim": "#ffd23f", "syrup": "#4a3800", "sea": "#ffe14d", "sky": "#fffbe0", "fog": "#fff3a8", "accent": "#7ed957", "scenery": "#e8c53a"},
		"objective": {"type": "survive_fast", "target": 45, "label": "Survive 45s at Turbo Rush Speed!"},
		"obstacle": "bouncing_drop", "speed": 16.0, "length": 720,
		"music": {"tempo": 150, "root": 62, "scale": [0, 2, 4, 7, 9], "wave": 1},
	},
	{
		"name": "Raspberry Ridge", "look": "red/purple",
		"palette": {"tile": "#e85d75", "tile_dark": "#d94a62", "side": "#3d0a24", "rail_left": "#ff2e4d", "rail_right": "#b967ff", "rim": "#ff2e4d", "syrup": "#2a0518", "sea": "#d94a7a", "sky": "#ffe8ec", "fog": "#ffc9d6", "accent": "#b967ff", "scenery": "#c24a6e"},
		"objective": {"type": "near_miss", "target": 10, "label": "Near-miss 10 holes (45s Rush)"},
		"obstacle": "thorn_bush", "speed": 12.5, "length": 560,
		"music": {"tempo": 134, "root": 59, "scale": [0, 3, 5, 7, 10], "wave": 0},
	},
	{
		"name": "Peppermint Peak", "look": "red/white",
		"palette": {"tile": "#f7f0e8", "tile_dark": "#e8ddd2", "side": "#5e1a1a", "rail_left": "#ff2e4d", "rail_right": "#ffffff", "rim": "#ff2e4d", "syrup": "#4a0a0a", "sea": "#ffb8c2", "sky": "#fff0f0", "fog": "#ffe0e0", "accent": "#ff2e4d", "scenery": "#e88a8a"},
		"objective": {"type": "score", "target": 3500, "label": "Score 3,500 points (45s Rush)"},
		"obstacle": "gate", "speed": 12.5, "length": 560,
		"music": {"tempo": 136, "root": 64, "scale": [0, 2, 4, 7, 9], "wave": 0},
	},
	{
		"name": "Golden Honeycomb", "look": "gold/amber",
		"palette": {"tile": "#ffd23f", "tile_dark": "#f7c22a", "side": "#4a3405", "rail_left": "#ff8a00", "rail_right": "#ff5c8a", "rim": "#ff8a00", "syrup": "#3a2400", "sea": "#ffb300", "sky": "#fff3c2", "fog": "#ffe8a0", "accent": "#ff8a00", "scenery": "#d9a52a"},
		"objective": {"type": "distance", "target": 560, "no_fall": true, "label": "Run 560m without falling (45s Rush)"},
		"obstacle": "honeycomb_wall", "speed": 12.5, "length": 560,
		"music": {"tempo": 138, "root": 57, "scale": [0, 2, 4, 7, 9], "wave": 1},
	},
	{
		"name": "Sugar Rush Finale", "look": "rainbow neon",
		"palette": {"tile": "#b967ff", "tile_dark": "#9e4ae8", "side": "#1e0a3d", "rail_left": "#ff2fb3", "rail_right": "#00e5ff", "rim": "#ff2fb3", "syrup": "#12041f", "sea": "#ff2fb3", "sky": "#3d1a6e", "fog": "#5e2a8a", "accent": "#ffd23f", "scenery": "#7b2fbe"},
		"objective": {"type": "finale", "target": 3000, "target2": 580, "label": "Score 3,000 AND run 580m (45s Finale)"},
		"obstacle": "mixed", "speed": 13.0, "length": 580,
		"music": {"tempo": 144, "root": 60, "scale": [0, 2, 4, 7, 9], "wave": 1},
	},
	{
		"name": "Blueberry Bash", "look": "blueberry patch",
		"palette": {"tile": "#5e3a8a", "tile_dark": "#4a2a6e", "side": "#1e0a33", "rail_left": "#7b5cd6", "rail_right": "#ff5c8a", "rim": "#7b5cd6", "syrup": "#1a0830", "sea": "#4a1a8a", "sky": "#b39ae0", "fog": "#8a68c8", "accent": "#7b5cd6", "scenery": "#6e4ab8"},
		"objective": {"type": "distance", "target": 540, "no_fall": true, "label": "Run 540m without falling (45s Rush)"},
		"obstacle": "blueberry_roller", "speed": 12.0, "length": 540,
		"music": {"tempo": 134, "root": 57, "scale": [0, 3, 5, 7, 10], "wave": 1},
	},
]

# Outfits for the shop. Cost is in sugar stars (the currency, not the score).
const OUTFITS: Array = [
	{"name": "Default Outfit", "hair": "#2b160c", "top": "#0e9b8a", "bottom": "#ff5c8a", "bottom_style": "shorts", "shoes": "#ffffff", "cape": "", "cost": 0},
	{"name": "Rainbow Sparkle", "hair": "#2b160c", "top": "#7be3f6", "bottom": "#a584f7", "bottom_style": "shorts", "shoes": "#ffd23f", "cape": "", "cost": 150},
	{"name": "Berry Sweet", "hair": "#8a1c4a", "top": "#e62e6b", "bottom": "#2e4678", "bottom_style": "jeans", "shoes": "#ff5c8a", "cape": "", "cost": 200},
	{"name": "Golden Honey", "hair": "#b8732a", "top": "#ffd23f", "bottom": "#8a5a2a", "bottom_style": "shorts", "shoes": "#ffffff", "cape": "#ffd23f", "cost": 300},
	{"name": "Neon Pop", "hair": "#a036f2", "top": "#ff2fb3", "bottom": "#261844", "bottom_style": "leggings", "shoes": "#00e5ff", "cape": "#ff2fb3", "cost": 500},
]

# Full Modular Wardrobe Categories (Hair, Tops, Bottoms [Shorts/Jeans/Leggings], Flat Athletic Shoes)
const HAIR_ITEMS: Array = [
	{"name": "Natural Espresso Puffs", "style": "Rainbow Bead Ties", "color": "#2b160c", "tint": 0.0, "cost": 0},
	{"name": "Honey Caramel Curls", "style": "Warm Golden Highlights", "color": "#c87d32", "tint": 0.85, "cost": 60},
	{"name": "Berry Velvet Puffs", "style": "Rich Raspberry Tint", "color": "#a81d58", "tint": 0.85, "cost": 80},
	{"name": "Cotton Candy Pink Curls", "style": "Pastel Sugar Frosted", "color": "#ff6ca8", "tint": 0.90, "cost": 100},
	{"name": "Midnight Sapphire Puffs", "style": "Cool Blue-Black Sheen", "color": "#26408a", "tint": 0.80, "cost": 110},
	{"name": "Lavender Twist Puffs", "style": "Royal Purple Curls", "color": "#9c4ef7", "tint": 0.85, "cost": 120},
	{"name": "Golden Sunburst Curls", "style": "Bright Honey Blonde", "color": "#f2b830", "tint": 0.88, "cost": 140},
	{"name": "Mint Choc Chip Puffs", "style": "Cool Mint Frosted Tips", "color": "#38d9a9", "tint": 0.82, "cost": 150},
]

const TOP_ITEMS: Array = [
	{"name": "Classic Teal 'DJH' Hoodie", "style": "Cropped Fleece Hoodie", "color": "#0e9b8a", "tint": 0.0, "cost": 0},
	{"name": "Sky Blue 'DJH' Hoodie", "style": "Cloud Blue Pullover", "color": "#64d2ff", "tint": 1.0, "cost": 50},
	{"name": "Berry Red Varsity Top", "style": "Strawberry Sport Top", "color": "#e62e6b", "tint": 1.0, "cost": 65},
	{"name": "Sunny Lemon Zip-Up", "style": "Bright Citrus Track Top", "color": "#ffd23f", "tint": 1.0, "cost": 75},
	{"name": "Mint Fresh Crewneck", "style": "Cool Peppermint Fleece", "color": "#48e5b5", "tint": 1.0, "cost": 85},
	{"name": "Lavender Dream Sweater", "style": "Soft Lilac Cozy Top", "color": "#b37cf7", "tint": 1.0, "cost": 95},
	{"name": "Tangerine Pop Jacket", "style": "Vibrant Orange Runner Top", "color": "#ff7a29", "tint": 1.0, "cost": 110},
	{"name": "Electric Magenta Top", "style": "Neon Night Hoodie", "color": "#ff2fb3", "tint": 1.0, "cost": 125},
	{"name": "Marshmallow White Hoodie", "style": "Crisp Frosting Pullover", "color": "#f5f7fa", "tint": 1.0, "cost": 130},
	{"name": "Royal Plum Scrub Jacket", "style": "LPN Shift Warm-Up Top", "color": "#6c2a8c", "tint": 1.0, "cost": 150},
]

# Bottoms: Shorts, Full-Length Jeans, and Full-Length Athletic Leggings!
const BOTTOM_ITEMS: Array = [
	{"name": "Classic Pink Runner Shorts", "style": "shorts", "label": "Athletic Sport Shorts", "color": "#ff5c8a", "tint": 0.0, "cost": 0},
	{"name": "Light Wash Summer Shorts", "style": "shorts", "label": "Cuffed Denim Shorts", "color": "#7eb6e6", "tint": 1.0, "cost": 50},
	{"name": "Lavender Sugar Shorts", "style": "shorts", "label": "Pastel Denim Shorts", "color": "#a584f7", "tint": 1.0, "cost": 65},
	{"name": "Berry Pink Runner Shorts", "style": "shorts", "label": "Athletic Sport Shorts", "color": "#ec407a", "tint": 1.0, "cost": 75},
	{"name": "Classic Indigo Jeans", "style": "jeans", "label": "Full-Length Stitched Jeans", "color": "#34548a", "tint": 1.0, "cost": 90},
	{"name": "Sky Acid-Wash Jeans", "style": "jeans", "label": "Full-Length Street Jeans", "color": "#5c9ce6", "tint": 1.0, "cost": 105},
	{"name": "Midnight Black Jeans", "style": "jeans", "label": "Full-Length Slim Jeans", "color": "#242834", "tint": 1.0, "cost": 115},
	{"name": "Vintage Berry Denim Jeans", "style": "jeans", "label": "Full-Length Designer Jeans", "color": "#8a2858", "tint": 1.0, "cost": 125},
	{"name": "Sleek Onyx Leggings", "style": "leggings", "label": "Full-Length Sport Leggings", "color": "#1e2029", "tint": 1.0, "cost": 85},
	{"name": "Hot-Pink Track Leggings", "style": "leggings", "label": "Full-Length Compression Leggings", "color": "#e82c78", "tint": 1.0, "cost": 100},
	{"name": "Galaxy Purple Leggings", "style": "leggings", "label": "Full-Length High-Waist Leggings", "color": "#5e2ca5", "tint": 1.0, "cost": 115},
	{"name": "Teal Shift Jogger Leggings", "style": "leggings", "label": "Full-Length Nursing Joggers", "color": "#1c8c82", "tint": 1.0, "cost": 130},
]

# Shoes: 100% Flat / Athletic Sneakers, Runners, Skate & Slip-Ons (NO high heels!)
const SHOE_ITEMS: Array = [
	{"name": "Bubblegum High-Tops", "style": "Classic Court High-Top Sneakers", "color": "#f282b4", "tint": 0.0, "cost": 0},
	{"name": "Lemon Drop Retro Runners", "style": "Cushioned Flat Track Sneakers", "color": "#ffd23f", "tint": 1.0, "cost": 50},
	{"name": "Neon Cyan Skate Kicks", "style": "Flat Vulcanized Skate Shoes", "color": "#00e5ff", "tint": 1.0, "cost": 65},
	{"name": "Strawberry Dash Sneakers", "style": "Flat Mesh Running Shoes", "color": "#ff2e55", "tint": 1.0, "cost": 75},
	{"name": "Mint Sprint Trainers", "style": "Lightweight Flat Cross-Trainers", "color": "#38e5b5", "tint": 1.0, "cost": 85},
	{"name": "Cloud White Nursing Kicks", "style": "12-Hour Shift Comfort Runners", "color": "#f5f7fa", "tint": 1.0, "cost": 95},
	{"name": "Ultra-Violet Street Highs", "style": "Flat Basketball High-Tops", "color": "#9c4ef7", "tint": 1.0, "cost": 110},
	{"name": "Tangerine Turbo Runners", "style": "Flat Marathon Foam Sneakers", "color": "#ff7a18", "tint": 1.0, "cost": 120},
	{"name": "Gold & White Low-Tops", "style": "Championship Flat Canvas Shoes", "color": "#f5b025", "tint": 1.0, "cost": 140},
]

# Separate Abilities Section: Buy & Equip up to 3 active abilities with ANY outfit!
const ABILITY_ITEMS: Array = [
	{"id": "extra_heart", "name": "Extra Vitals (+1 Heart)", "desc": "Start every board with 4 Hearts (♥♥♥♥) instead of 3!", "color": "#ff2e55", "cost": 100},
	{"id": "start_shield", "name": "Shift Armor (Auto-Shield)", "desc": "Start every board inside a glowing 3D Shield Dome!", "color": "#00e5ff", "cost": 120},
	{"id": "star_magnet", "name": "Sugar Magnet Aura", "desc": "Permanent magnetic pull draws nearby Sugar Stars to Dijah!", "color": "#ff5c8a", "cost": 150},
	{"id": "double_stars", "name": "Double Star Payday (2x ★)", "desc": "Every Sugar Star collected gives 2x Stars for the Shop!", "color": "#ffd23f", "cost": 175},
	{"id": "fast_rush", "name": "Instant Sugar Rush", "desc": "Trigger Sugar Rush at just 3 Stars & boost score +25%!", "color": "#b967ff", "cost": 150},
	{"id": "long_power", "name": "Extended Med-Pass", "desc": "All Power-Ups last 50% longer & Sour slow-downs end 50% faster!", "color": "#48e5b5", "cost": 140},
	{"id": "second_wind", "name": "Code Blue Revive", "desc": "Once per run, automatically revive with 2 Hearts on a fatal hit!", "color": "#ff8a00", "cost": 225},
]

# The board currently selected for play (set by the roadmap, read by the game).
var selected_board: int = 0


## ---- 100-board campaign (art LOCKED: boards 22-50 re-use stage palettes,
## boards 51-100 are hand-crafted expansion boards from BoardsExpansion) ----
const TOTAL_BOARDS: int = 100
## 3-act speed ramp multipliers (Act I warm-up, Act II pick-up, Act III sprint).
const ACT_MULTS: Array = [0.90, 1.05, 1.22]
## Average of (1 / act multiplier) across the three equal-ish acts -> nominal run time.
const ACT_AVG_INV: float = 0.961
var _all: Array = []


const BoardsExpansionScript = preload("res://scripts/boards_expansion.gd")


func _ensure_built() -> void:
	if not _all.is_empty():
		return
	var legacy_n: int = BOARDS.size()
	for i in range(TOTAL_BOARDS):
		var src: Dictionary
		if i < legacy_n:
			src = BOARDS[i]
		elif i < 50:
			# Re-use stage looks 1-20 (skip the one-off Blueberry joke board).
			src = BOARDS[(i - legacy_n) % (legacy_n - 1)]
		else:
			# Boards 51-100: Hand-crafted 50 expansion boards
			src = BoardsExpansionScript.EXPANSION_BOARDS[i - 50]
		var b: Dictionary = src.duplicate(true)
		if i >= legacy_n and i < 50:
			var lap: String = "II" if i < legacy_n + 20 else "III"
			b["name"] = "%s %s" % [str(src.get("name", "Board")), lap]
		# 60s on board 1 ramping to 90s on board 100.
		var run_t: int = int(round(60.0 + 30.0 * float(i) / float(TOTAL_BOARDS - 1)))
		var spd: float = float(src.get("speed", 12.0))
		if i >= legacy_n and i < 50:
			spd += 0.08 * float(i - legacy_n + 1)
		elif i >= 50:
			spd += 0.04 * float(i - 50)
		b["speed"] = spd
		b["length"] = int(round(float(run_t) * spd / ACT_AVG_INV))
		b["run_time"] = run_t
		b["par_time"] = float(run_t)
		var diff: float = 1.0 + 0.012 * float(maxi(0, i - 20))
		_retune_objective(b, run_t, diff)
		_all.append(b)


func _round100(v: float) -> int:
	return maxi(100, int(round(v / 100.0)) * 100)


func _retune_objective(b: Dictionary, run_t: int, diff: float) -> void:
	var o: Dictionary = b["objective"]
	var k: float = float(run_t) / 45.0
	var length: int = int(b["length"])
	match str(o.get("type", "")):
		"collect":
			o["target"] = int(round(float(o["target"]) * k * diff))
		"distance":
			o["target"] = length
		"jumps", "perfect", "near_miss":
			o["target"] = maxi(int(o["target"]), int(round(float(o["target"]) * k * diff)))
		"score", "score_double":
			o["target"] = _round100(float(o["target"]) * k * diff)
		"survive", "survive_fast":
			o["target"] = int(float(run_t) * 0.85)
		"combo":
			o["target"] = length
			o["target2"] = int(round(float(o["target2"]) * k * diff))
		"timed_collect":
			o["target"] = int(round(float(o["target"]) * k * diff))
			o["target2"] = int(float(run_t) * 0.92)
		"finale":
			o["target"] = _round100(float(o["target"]) * k * diff)
			o["target2"] = length
	o["label"] = _make_label(o, run_t)


func _make_label(o: Dictionary, run_t: int) -> String:
	var t: int = int(o.get("target", 0))
	var t2: int = int(o.get("target2", 0))
	var txt: String = ""
	match str(o.get("type", "")):
		"collect": txt = "Collect %d sugar stars" % t
		"distance": txt = "Run %dm without falling" % t
		"jumps": txt = "Jump %d holes" % t
		"score": txt = "Score %d points" % t
		"streak": txt = "Collect %d stars in a row" % t
		"near_miss": txt = "Near-miss %d hazards" % t
		"survive": txt = "Survive %d seconds" % t
		"streak_hold": txt = "Keep a Sweet Streak x%d" % t
		"perfect": txt = "Land %d perfect jumps" % t
		"collect_all": txt = "Collect EVERY star on the track"
		"combo": txt = "Run %dm and grab %d stars" % [t, t2]
		"score_double": txt = "Score %d (streaks count 2x)" % t
		"no_jump": txt = "Steer around every hole - no jumping"
		"jump_all": txt = "Jump every hole - no steering"
		"timed_collect": txt = "Collect %d stars in %d seconds" % [t, t2]
		"survive_fast": txt = "Survive %d seconds at Turbo speed" % t
		"finale": txt = "Score %d AND run %dm" % [t, t2]
		_: txt = str(o.get("label", ""))
	return "%s  (%ds run)" % [txt, run_t]


const ENDLESS_BOARD_INDEX: int = 999
const ENDLESS_BOARD: Dictionary = {
	"name": "Endless Sugar Rush", "look": "rainbow neon",
	"palette": {"tile": "#b967ff", "tile_dark": "#9e4ae8", "side": "#1e0a3d", "rail_left": "#ff2fb3", "rail_right": "#00e5ff", "rim": "#ffd23f", "syrup": "#12041f", "sea": "#ff2fb3", "sky": "#3d1a6e", "fog": "#5e2a8a", "accent": "#ffd23f", "scenery": "#7b2fbe"},
	"objective": {"type": "distance", "target": 999999, "label": "Endless Mode - Run for the High Score!"},
	"obstacle": "mixed", "speed": 12.0, "length": 9999999,
	"music": {"tempo": 140, "root": 60, "scale": [0, 2, 4, 7, 9], "wave": 1},
	"is_endless": true,
}


func get_board(index: int) -> Dictionary:
	if index == ENDLESS_BOARD_INDEX:
		return ENDLESS_BOARD
	_ensure_built()
	if index < 0 or index >= _all.size():
		return _all[0]
	return _all[index]


## Speed multiplier for the 3-act ramp. ratio = distance / track length (0..1).
func act_multiplier(ratio: float) -> float:
	var m1: float = ACT_MULTS[0]
	var m2: float = ACT_MULTS[1]
	var m3: float = ACT_MULTS[2]
	if ratio < 0.30:
		return m1
	if ratio < 0.38:
		return lerpf(m1, m2, smoothstep(0.30, 0.38, ratio))
	if ratio < 0.64:
		return m2
	if ratio < 0.72:
		return lerpf(m2, m3, smoothstep(0.64, 0.72, ratio))
	return m3


func act_index(ratio: float) -> int:
	if ratio < 0.33:
		return 1
	if ratio < 0.68:
		return 2
	return 3


func _get_board_legacy(index: int) -> Dictionary:
	if index < 0 or index >= BOARDS.size():
		return BOARDS[0]
	return BOARDS[index]


func board_count() -> int:
	return TOTAL_BOARDS


func _board_count_legacy() -> int:
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
