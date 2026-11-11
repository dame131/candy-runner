class_name SaveManager
extends Node
## Dijah's Delights Candy Run — local save: unlocked boards, best scores, sugar-star
## currency, owned/equipped modular wardrobe (Hair, Tops, Bottoms [Shorts/Jeans/Leggings],
## Flat Athletic Shoes), owned/equipped Abilities (up to 3 active slots), and mute setting.

const SAVE_PATH := "user://dijah_dash_save.json"
const MAX_EQUIPPED_ABILITIES: int = 3

var unlocked: int = 0
var best: Dictionary = {}
## Per-board best 3-star rating (str(board_index) -> 0..3) and best clear time (seconds).
var board_stars: Dictionary = {}
var best_time: Dictionary = {}
var stars_total: int = 500
var outfits_owned: Array = [0]
var outfit_equipped: int = 0

var hair_owned: Array = [0]
var hair_equipped: int = 0
var top_owned: Array = [0]
var top_equipped: int = 0
var bottom_owned: Array = [0]
var bottom_equipped: int = 0
var shoe_owned: Array = [0]
var shoe_equipped: int = 0

var abilities_owned: Array = []
var abilities_equipped: Array = []

var muted: bool = false
var total_runs: int = 0
var endless_high_score: int = 0
var endless_best_distance: int = 0


func _ready() -> void:
	load_game()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (data is Dictionary):
		return
	unlocked = int(data.get("unlocked", 0))
	best = data.get("best", {})
	board_stars = data.get("board_stars", {})
	best_time = data.get("best_time", {})
	stars_total = int(data.get("stars_total", 500))
	outfits_owned = data.get("outfits_owned", [0])
	outfit_equipped = int(data.get("outfit_equipped", 0))
	hair_owned = data.get("hair_owned", [0])
	hair_equipped = int(data.get("hair_equipped", 0))
	top_owned = data.get("top_owned", [0])
	top_equipped = int(data.get("top_equipped", 0))
	bottom_owned = data.get("bottom_owned", [0])
	bottom_equipped = int(data.get("bottom_equipped", 0))
	shoe_owned = data.get("shoe_owned", [0])
	shoe_equipped = int(data.get("shoe_equipped", 0))
	abilities_owned = data.get("abilities_owned", [])
	abilities_equipped = data.get("abilities_equipped", [])
	muted = bool(data.get("muted", false))
	total_runs = int(data.get("total_runs", 0))
	endless_high_score = int(data.get("endless_high_score", 0))
	endless_best_distance = int(data.get("endless_best_distance", 0))
	for arr in [outfits_owned, hair_owned, top_owned, bottom_owned, shoe_owned]:
		if not arr.has(0):
			arr.append(0)


func save_game() -> void:
	var data := {
		"unlocked": unlocked,
		"best": best,
		"board_stars": board_stars,
		"best_time": best_time,
		"stars_total": stars_total,
		"outfits_owned": outfits_owned,
		"outfit_equipped": outfit_equipped,
		"hair_owned": hair_owned,
		"hair_equipped": hair_equipped,
		"top_owned": top_owned,
		"top_equipped": top_equipped,
		"bottom_owned": bottom_owned,
		"bottom_equipped": bottom_equipped,
		"shoe_owned": shoe_owned,
		"shoe_equipped": shoe_equipped,
		"abilities_owned": abilities_owned,
		"abilities_equipped": abilities_equipped,
		"muted": muted,
		"total_runs": total_runs,
		"endless_high_score": endless_high_score,
		"endless_best_distance": endless_best_distance,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()


func best_score(board_index: int) -> int:
	return int(best.get(str(board_index), 0))


func board_rating(board_index: int) -> int:
	return int(board_stars.get(str(board_index), 0))


func total_rating_stars() -> int:
	var n: int = 0
	for k in board_stars.keys():
		n += int(board_stars[k])
	return n


func rating_text(board_index: int) -> String:
	var r: int = board_rating(board_index)
	return "★".repeat(r) + "☆".repeat(3 - r)


func record_run(board_index: int, score: int, stars_earned: int, won: bool, rating: int = 0, clear_time: float = 0.0) -> bool:
	total_runs += 1
	stars_total += stars_earned
	if won and rating > board_rating(board_index):
		board_stars[str(board_index)] = rating
	if won and clear_time > 0.0:
		var prev_t: float = float(best_time.get(str(board_index), 0.0))
		if prev_t <= 0.0 or clear_time < prev_t:
			best_time[str(board_index)] = clear_time
	var is_new_best := false
	if score > best_score(board_index):
		best[str(board_index)] = score
		is_new_best = true
	if won and board_index + 1 < BoardData.TOTAL_BOARDS and board_index + 1 > unlocked:
		unlocked = board_index + 1
	save_game()
	return is_new_best


func record_endless_run(score: int, dist: int, stars_earned: int) -> bool:
	total_runs += 1
	stars_total += stars_earned
	var is_new_best := false
	if score > endless_high_score:
		endless_high_score = score
		is_new_best = true
	if dist > endless_best_distance:
		endless_best_distance = dist
	save_game()
	return is_new_best


func is_unlocked(board_index: int) -> bool:
	return board_index <= unlocked


func owns_outfit(index: int) -> bool:
	return outfits_owned.has(index)


func buy_outfit(index: int) -> bool:
	var outfit: Dictionary = BoardData.OUTFITS[index]
	var cost: int = int(outfit.get("cost", 0))
	if owns_outfit(index) or stars_total < cost:
		return false
	stars_total -= cost
	outfits_owned.append(index)
	equip_outfit(index)
	return true


func equip_outfit(index: int) -> bool:
	if not owns_outfit(index):
		return false
	outfit_equipped = index
	# Sync modular pieces to match the preset look
	match index:
		0:
			hair_equipped = 0; top_equipped = 0; bottom_equipped = 0; shoe_equipped = 0
		1:
			hair_equipped = 0; top_equipped = 1; bottom_equipped = 2; shoe_equipped = 1
		2:
			hair_equipped = 2; top_equipped = 2; bottom_equipped = 4; shoe_equipped = 3
		3:
			hair_equipped = 6; top_equipped = 3; bottom_equipped = 0; shoe_equipped = 5
		4:
			hair_equipped = 5; top_equipped = 7; bottom_equipped = 10; shoe_equipped = 2
	save_game()
	return true


func get_current_look() -> Dictionary:
	var h: Dictionary = BoardData.HAIR_ITEMS[clampi(hair_equipped, 0, BoardData.HAIR_ITEMS.size() - 1)]
	var t: Dictionary = BoardData.TOP_ITEMS[clampi(top_equipped, 0, BoardData.TOP_ITEMS.size() - 1)]
	var b: Dictionary = BoardData.BOTTOM_ITEMS[clampi(bottom_equipped, 0, BoardData.BOTTOM_ITEMS.size() - 1)]
	var s: Dictionary = BoardData.SHOE_ITEMS[clampi(shoe_equipped, 0, BoardData.SHOE_ITEMS.size() - 1)]
	return {
		"hair": h.get("color", "#2b160c"),
		"hair_tint": float(h.get("tint", 0.0)),
		"top": t.get("color", "#f49ac2"),
		"top_tint": float(t.get("tint", 0.0)),
		"bottom": b.get("color", "#4f6d9a"),
		"bottom_style": b.get("style", "shorts"),
		"bottom_tint": float(b.get("tint", 0.0)),
		"shoes": s.get("color", "#f282b4"),
		"shoe_tint": float(s.get("tint", 0.0)),
	}


func owns_item(category: String, index: int) -> bool:
	match category:
		"hair": return hair_owned.has(index)
		"top": return top_owned.has(index)
		"bottom": return bottom_owned.has(index)
		"shoe", "shoes": return shoe_owned.has(index)
	return false


func is_item_equipped(category: String, index: int) -> bool:
	match category:
		"hair": return hair_equipped == index
		"top": return top_equipped == index
		"bottom": return bottom_equipped == index
		"shoe", "shoes": return shoe_equipped == index
	return false


func buy_or_equip_item(category: String, index: int, cost: int = -1) -> bool:
	if cost < 0:
		match category:
			"hair": cost = int(BoardData.HAIR_ITEMS[index].get("cost", 0))
			"top": cost = int(BoardData.TOP_ITEMS[index].get("cost", 0))
			"bottom": cost = int(BoardData.BOTTOM_ITEMS[index].get("cost", 0))
			"shoe", "shoes": cost = int(BoardData.SHOE_ITEMS[index].get("cost", 0))
	if owns_item(category, index):
		match category:
			"hair": hair_equipped = index
			"top": top_equipped = index
			"bottom": bottom_equipped = index
			"shoe", "shoes": shoe_equipped = index
		save_game()
		return true
	if stars_total < cost:
		return false
	stars_total -= cost
	match category:
		"hair":
			hair_owned.append(index)
			hair_equipped = index
		"top":
			top_owned.append(index)
			top_equipped = index
		"bottom":
			bottom_owned.append(index)
			bottom_equipped = index
		"shoe", "shoes":
			shoe_owned.append(index)
			shoe_equipped = index
	save_game()
	return true


func owns_ability(id: String) -> bool:
	return abilities_owned.has(id)


func has_ability(id: String) -> bool:
	return abilities_equipped.has(id)


func buy_or_toggle_ability(id_or_idx: Variant, cost: int = -1) -> bool:
	var id: String = ""
	if id_or_idx is int:
		var ab: Dictionary = BoardData.ABILITY_ITEMS[int(id_or_idx)]
		id = str(ab.get("id", ""))
		if cost < 0:
			cost = int(ab.get("cost", 0))
	else:
		id = str(id_or_idx)
		if cost < 0:
			for ab in BoardData.ABILITY_ITEMS:
				if str(ab.get("id", "")) == id:
					cost = int(ab.get("cost", 0))
					break
	if owns_ability(id):
		if abilities_equipped.has(id):
			abilities_equipped.erase(id)
		else:
			if abilities_equipped.size() >= MAX_EQUIPPED_ABILITIES:
				abilities_equipped.pop_front()
			abilities_equipped.append(id)
		save_game()
		return true
	if stars_total < cost:
		return false
	stars_total -= cost
	abilities_owned.append(id)
	if abilities_equipped.size() >= MAX_EQUIPPED_ABILITIES:
		abilities_equipped.pop_front()
	abilities_equipped.append(id)
	save_game()
	return true
