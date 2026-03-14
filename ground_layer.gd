# ground_layer.gd
# Menggambar grid tanah dengan pola checkerboard hijau tua/muda.
# Di-attach ke Node2D bernama "GroundLayer" di scene root.
# Tidak butuh TileSet — semuanya procedural via _draw().
extends Node2D

# ── Ukuran grid ───────────────────────────────────────────────────────────────
const TILE_SIZE : int = 32
const MAP_COLS  : int = 26    # kolom tile   → total lebar  832 px
const MAP_ROWS  : int = 26    # baris tile   → total tinggi 832 px

# ── Palet warna tanah ─────────────────────────────────────────────────────────
const COLOR_A    := Color(0.20, 0.46, 0.15)    # hijau tua
const COLOR_B    := Color(0.28, 0.57, 0.21)    # hijau muda
const COLOR_GRID := Color(0.00, 0.00, 0.00, 0.10)  # garis grid tipis

# ──────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	# Tile background — pola checkerboard
	for col in range(MAP_COLS):
		for row in range(MAP_ROWS):
			var warna := COLOR_A if (col + row) % 2 == 0 else COLOR_B
			draw_rect(
				Rect2(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE),
				warna
			)

	# Garis grid samar-samar untuk memberi tekstur
	for col in range(MAP_COLS + 1):
		draw_line(
			Vector2(col * TILE_SIZE, 0),
			Vector2(col * TILE_SIZE, MAP_ROWS * TILE_SIZE),
			COLOR_GRID
		)
	for row in range(MAP_ROWS + 1):
		draw_line(
			Vector2(0,               row * TILE_SIZE),
			Vector2(MAP_COLS * TILE_SIZE, row * TILE_SIZE),
			COLOR_GRID
		)
