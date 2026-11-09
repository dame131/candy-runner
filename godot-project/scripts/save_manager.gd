class_name SaveManager
extends Node
## Dijah Dash — local save: unlocked boards, best scores, sugar-star
## currency, owned/equipped outfits, mute setting. Stored as JSON in user://.

const SAVE_PATH := "user://dijah_dash_save.json"

# Highest board index unlocked (0-based). Board 0 is always unlocked.
var unlocked: int = 0
# Best score per board index, stored as {"0": 1234, ...} after JSON round-trip.
var best: Dictionary = {}
# Sugar stars (currency) banked across runs, spent in the outfit shop.
var stars_total: int = 0
# Outfit indices owned (0 is free and always owned).
var outfits_owned: Array = [0]
# Outfit index currently equipped.
var outfit_equipped: int = 0
# Music/SFX muted.
var muted: bool = false
var total_runs: int = 0


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
	stars_total = int(data.get("stars_total", 0))
	outfits_owned = data.get("outfits_owned", [0])
	outfit_equipped = int(data.get("outfit_equipped", 0))
	muted = bool(data.get("muted", false))
	total_runs = int(data.get("total_runs", 0))
	# Safety: outfit 0 is always owned.
	if not outfits_owned.has(0):
		outfits_owned.append(0)


func save_game() -> void:
	var data := {
		"unlocked": unlocked,
		"best": best,
		"stars_total": stars_total,
		"outfits_owned": outfits_owned,
		"outfit_equipped": outfit_equipped,
		"muted": muted,
		"total_runs": total_runs,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()


func best_score(board_index: int) -> int:
	return int(best.get(str(board_index), 0))


func record_run(board_index: int, score: int, stars_earned: int, won: bool) -> bool:
	# Returns true when the score is a new best for this board.
	total_runs += 1
	stars_total += stars_earned
	var is_new_best := false
	if score > best_score(board_index):
		best[str(board_index)] = score
		is_new_best = true
	if won and board_index + 1 < Boards.board_count() and board_index + 1 > unlocked:
		unlocked = board_index + 1
	save_game()
	return is_new_best


func is_unlocked(board_index: int) -> bool:
	return board_index <= unlocked


func owns_outfit(index: int) -> bool:
	return outfits_owned.has(index)


func buy_outfit(index: int) -> bool:
	var outfit: Dictionary = Boards.OUTFITS[index]
	var cost: int = int(outfit.get("cost", 0))
	if owns_outfit(index) or stars_total < cost:
		return false
	stars_total -= cost
	outfits_owned.append(index)
	outfit_equipped = index
	save_game()
	return true


func equip_outfit(index: int) -> bool:
	if not owns_outfit(index):
		return false
	outfit_equipped = index
	save_game()
	return true
