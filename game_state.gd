# game_state.gd — Autoload singleton
extends Node

# ── Tile constants ────────────────────────────────────────────────────────────
const TILE_GRASS   := 0
const TILE_BLOCKED := 1
const TILE_GARDEN  := 2
const TILE_DOOR    := 3
const TILE_SHOP    := 4
const TILE_PATH    := 5
const TILE_EXIT    := 6
const TILE_WATER   := 7   # kolam / sungai — tidak bisa dilewati

# ── Map constants ─────────────────────────────────────────────────────────────
const TILE_SIZE : int = 64
const MAP_COLS  : int = 40
const MAP_ROWS  : int = 22

# ── Exterior map (40×22) ──────────────────────────────────────────────────────
# Rumah pemain : cols 1–3,   rows 1–3  | pintu col 2 row 4
# NPC House A  : cols 6–8,   rows 1–3  | "pintu" (path) col 7 row 4
# NPC House B  : cols 12–14, rows 1–3  | "pintu" col 13 row 4
# NPC House C  : cols 18–20, rows 1–3  | "pintu" col 19 row 4
# Toko         : cols 26–30, rows 1–4  | konter col 25 row 4
# Kebun utama  : cols 4–16,  rows 6–8
# Kebun timur  : cols 28–36, rows 6–8
# Balai desa   : cols 2–6,   rows 15–17
# Bengkel/lumbung : cols 10–14, rows 15–17
# Kolam        : cols 17–25, rows 15–18 (TILE_WATER)
# Kebun selatan: cols 28–36, rows 15–17
const MAP_DATA : Array = [
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
	[1,1,1,1,0,0,1,1,1,0,0,0,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
	[1,1,1,1,0,0,1,1,1,0,0,0,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
	[1,1,1,1,0,0,1,1,1,0,0,0,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
	[1,1,3,1,5,5,1,5,1,5,5,5,1,5,1,5,5,5,1,5,1,5,5,5,5,4,1,1,1,1,1,5,5,5,5,5,5,5,5,1],
	[1,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,0,0,1],
	[1,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,0,0,1],
	[1,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,0,0,1],
	[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,1],
	[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,1],
	[1,0,1,1,1,1,1,0,0,0,1,1,1,1,1,0,0,7,7,7,7,7,7,7,7,7,0,0,2,2,2,2,2,2,2,2,2,0,0,1],
	[1,0,1,1,1,1,1,0,0,0,1,1,1,1,1,0,0,7,7,7,7,7,7,7,7,7,0,0,2,2,2,2,2,2,2,2,2,0,0,1],
	[1,0,1,1,5,1,1,0,0,0,1,1,5,1,1,0,0,7,7,7,7,7,7,7,7,7,0,0,2,2,2,2,2,2,2,2,2,0,0,1],
	[1,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,7,7,7,7,7,7,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
]

# ── Interior map (12×8) ───────────────────────────────────────────────────────
const INT_COLS : int = 12
const INT_ROWS : int = 8
const INT_OFFSET_X : int = 256
const INT_OFFSET_Y : int = 104

const INTERIOR_MAP : Array = [
	[1,1,1,1,1,1,1,1,1,1,1,1],
	[1,0,0,0,0,0,0,0,0,0,1,1],
	[1,0,1,0,0,0,0,0,0,0,1,1],
	[1,0,1,0,0,0,0,0,0,0,0,1],
	[1,0,0,0,0,0,0,0,0,0,0,1],
	[1,0,0,0,0,0,0,0,0,0,0,1],
	[1,0,0,0,0,0,0,0,0,0,0,1],
	[1,1,1,1,1,1,6,1,1,1,1,1],
]

# ── Inventori & state ─────────────────────────────────────────────────────────
var seeds   : int   = 5
var money   : int   = 100
var harvest : int   = 0
var day     : int   = 1
var hour    : float = 7.0

var in_interior   : bool = false
var from_interior : bool = false

const SEED_PACK_PRICE    := 10
const SEEDS_PER_PACK     := 5
const HARVEST_SELL_PRICE := 25

signal inventory_changed

# ── Map helpers ───────────────────────────────────────────────────────────────
func tile_at(t: Vector2i) -> int:
	if t.y < 0 or t.y >= MAP_ROWS or t.x < 0 or t.x >= MAP_COLS:
		return TILE_BLOCKED
	return MAP_DATA[t.y][t.x]

func int_tile_at(t: Vector2i) -> int:
	if t.y < 0 or t.y >= INT_ROWS or t.x < 0 or t.x >= INT_COLS:
		return TILE_BLOCKED
	return INTERIOR_MAP[t.y][t.x]

func is_walkable(t: Vector2i) -> bool:
	var v := tile_at(t)
	return v != TILE_BLOCKED and v != TILE_WATER

func is_walkable_interior(t: Vector2i) -> bool:
	return int_tile_at(t) != TILE_BLOCKED

func is_plantable(t: Vector2i) -> bool:
	return tile_at(t) == TILE_GARDEN

func world_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / TILE_SIZE), int(pos.y / TILE_SIZE))

func world_to_interior_tile(pos: Vector2) -> Vector2i:
	return Vector2i(
		int((pos.x - INT_OFFSET_X) / TILE_SIZE),
		int((pos.y - INT_OFFSET_Y) / TILE_SIZE)
	)

func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE_SIZE + TILE_SIZE * 0.5,
	               t.y * TILE_SIZE + TILE_SIZE * 0.5)

# ── Save / Load ───────────────────────────────────────────────────────────────
const SAVE_PATH := "user://taman_save.json"

func save(crops_data: Array) -> void:
	var data := {
		"seeds": seeds, "money": money, "harvest": harvest,
		"day": day, "hour": hour, "crops": crops_data,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if not parsed is Dictionary:
		return {}
	seeds   = int(parsed.get("seeds",   5))
	money   = int(parsed.get("money",   100))
	harvest = int(parsed.get("harvest", 0))
	day     = int(parsed.get("day",     1))
	hour    = float(parsed.get("hour",  7.0))
	inventory_changed.emit()
	return parsed

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
