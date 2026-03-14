# interior_renderer.gd — HD v2
# Menggambar interior rumah dengan detail tinggi via _draw()
extends Node2D

const TS  := GameState.TILE_SIZE   # 64
const OX  := GameState.INT_OFFSET_X  # 256
const OY  := GameState.INT_OFFSET_Y  # 104
const C   := GameState.INT_COLS    # 12
const R   := GameState.INT_ROWS    # 8

# ── Palet interior ────────────────────────────────────────────────────────────
# Lantai papan kayu
const FL_A  := Color(0.82, 0.66, 0.42)   # papan terang
const FL_B  := Color(0.74, 0.58, 0.36)   # papan gelap
const FL_H  := Color(0.90, 0.76, 0.54)   # highlight papan
const FL_D  := Color(0.62, 0.48, 0.28)   # gap antar papan
const FL_G  := Color(0.52, 0.40, 0.24)   # serat kayu
# Dinding
const WL_A  := Color(0.92, 0.86, 0.74)   # dinding plaster
const WL_B  := Color(0.84, 0.76, 0.62)   # dinding shadow
const WL_H  := Color(1.00, 0.96, 0.88)   # dinding highlight
const WL_D  := Color(0.72, 0.62, 0.48)   # dinding gelap
const WL_SK  := Color(0.62, 0.54, 0.42)  # skirting
# Furniture
const WD_H  := Color(0.62, 0.42, 0.20)   # kayu terang
const WD_M  := Color(0.48, 0.32, 0.14)   # kayu mid
const WD_D  := Color(0.30, 0.18, 0.06)   # kayu gelap
const WD_G  := Color(0.22, 0.12, 0.04)   # kayu gelap sekali
# Karpet
const RG_A  := Color(0.68, 0.28, 0.22)   # karpet merah
const RG_B  := Color(0.52, 0.18, 0.14)
const RG_H  := Color(0.84, 0.40, 0.30)
const RG_FR := Color(0.90, 0.78, 0.38)   # fringe karpet
# Kasur / linen
const BD_M  := Color(0.86, 0.84, 0.94)
const BD_H  := Color(0.96, 0.95, 1.00)
const BD_D  := Color(0.70, 0.68, 0.80)
const BL_A  := Color(0.52, 0.42, 0.76)   # selimut ungu
const BL_B  := Color(0.64, 0.54, 0.88)
const PL    := Color(0.96, 0.94, 1.00)   # bantal putih
# Buku
const BK_R  := Color(0.78, 0.22, 0.16)
const BK_G  := Color(0.20, 0.56, 0.24)
const BK_B  := Color(0.18, 0.34, 0.72)
const BK_Y  := Color(0.82, 0.70, 0.14)
const BK_P  := Color(0.60, 0.18, 0.58)
# Lampu
const LP_Y  := Color(1.00, 0.92, 0.60)   # cahaya lampu
const LP_G  := Color(0.80, 0.72, 0.48)   # kap lampu
const LP_GD := Color(0.86, 0.72, 0.20)   # aksen emas
# Pintu
const DR_A  := Color(0.42, 0.28, 0.12)
const DR_H  := Color(0.60, 0.44, 0.22)
const DR_D  := Color(0.28, 0.16, 0.06)
# Efek
const SHAD  := Color(0.0, 0.0, 0.0, 0.22)
const AMB   := Color(1.0, 0.96, 0.80, 0.06)  # ambient warm tint

func _draw() -> void:
	_draw_walls()
	_draw_floor()
	_draw_rug()
	_draw_baseboard()
	_draw_door()
	_draw_table()
	_draw_bookshelf()
	_draw_bed()
	_draw_lamp()
	_draw_window_interior()
	_draw_ambient()

# ══════════════════════════════════════════════════════════════════════════════
#  DINDING
# ══════════════════════════════════════════════════════════════════════════════
func _draw_walls() -> void:
	var rx := float(OX)
	var ry := float(OY)
	var rw := float(C * TS)
	var rh := float(R * TS)

	# Dinding bagian luar (tile BLOCKED)
	for row in range(R):
		for col in range(C):
			if GameState.INTERIOR_MAP[row][col] == GameState.TILE_BLOCKED:
				var wx := float(OX + col * TS)
				var wy := float(OY + row * TS)
				_draw_wall_tile(wx, wy)

	# Shadow bawah dinding atas (kedalaman)
	draw_rect(Rect2(rx, ry + TS - 2, rw, 8), SHAD)
	# Shadow kanan dinding kiri
	draw_rect(Rect2(rx + TS - 2, ry, 8, rh), SHAD)

func _draw_wall_tile(wx: float, wy: float) -> void:
	# Plaster — gradient subtle
	draw_rect(Rect2(wx, wy, TS, TS), WL_A)
	# Baris horizontal tekstur dinding
	for i in range(3):
		var ly := wy + 10.0 + float(i) * 18.0
		draw_rect(Rect2(wx + 4, ly, TS - 8, 2), WL_H)
		draw_rect(Rect2(wx + 4, ly + 14, TS - 8, 2), WL_D)
	# Shadow tepi
	draw_rect(Rect2(wx, wy, TS, 3), WL_D)
	draw_rect(Rect2(wx, wy, 3, TS), WL_D)
	draw_rect(Rect2(wx + TS - 2, wy, 2, TS), WL_H)
	draw_rect(Rect2(wx, wy + TS - 2, TS, 2), WL_H)

# ══════════════════════════════════════════════════════════════════════════════
#  LANTAI
# ══════════════════════════════════════════════════════════════════════════════
func _draw_floor() -> void:
	for row in range(R):
		for col in range(C):
			if GameState.INTERIOR_MAP[row][col] != GameState.TILE_BLOCKED:
				var fx := float(OX + col * TS)
				var fy := float(OY + row * TS)
				_draw_floor_tile(fx, fy, col, row)

func _draw_floor_tile(fx: float, fy: float, col: int, row: int) -> void:
	# Papan kayu 3 per tile (lebar ~21px masing)
	var plank_c := FL_A if (col + row) % 2 == 0 else FL_B
	draw_rect(Rect2(fx, fy, TS, TS), plank_c)

	# 3 papan per tile
	for p in range(3):
		var px := fx + float(p * 21)
		var pw := 20.0 if p < 2 else float(TS - 42)
		# Papan alternating
		var pc := FL_A if (p + col) % 2 == 0 else FL_B
		draw_rect(Rect2(px, fy, pw, TS), pc)
		# Highlight atas papan
		draw_rect(Rect2(px + 2, fy + 2, pw - 4, 4), FL_H)
		# Shadow bawah papan
		draw_rect(Rect2(px + 2, fy + TS - 5, pw - 4, 3), FL_D)
		# Serat kayu (garis samar horizontal)
		for i in range(2):
			var gy := fy + 12.0 + float(i) * 22.0
			draw_rect(Rect2(px + 2, gy, pw - 4, 1), FL_G)
		# Gap antar papan
		draw_rect(Rect2(px + pw, fy, 1, TS), FL_D)

	# Gap horizontal antar baris
	draw_rect(Rect2(fx, fy, TS, 1), FL_D)

func _draw_baseboard() -> void:
	# Papan alas dinding (skirting board)
	# Bawah dinding atas
	var base_y := float(OY + TS)
	draw_rect(Rect2(float(OX + TS), base_y, float((C - 2) * TS), 8), WL_SK)
	draw_rect(Rect2(float(OX + TS), base_y, float((C - 2) * TS), 3), WL_H)
	draw_rect(Rect2(float(OX + TS), base_y + 5, float((C - 2) * TS), 3), WL_D)
	# Kanan dinding kiri
	draw_rect(Rect2(float(OX + TS), base_y, 8, float((R - 2) * TS)), WL_SK)

# ══════════════════════════════════════════════════════════════════════════════
#  KARPET
# ══════════════════════════════════════════════════════════════════════════════
func _draw_rug() -> void:
	var rx := float(OX + 3 * TS)
	var ry := float(OY + 3 * TS)
	var rw := float(4 * TS)
	var rh := float(3 * TS)

	# Shadow karpet
	draw_rect(Rect2(rx + 6, ry + rh, rw, 8), SHAD)
	# Badan karpet
	draw_rect(Rect2(rx, ry, rw, rh), RG_A)
	# Border dalam
	draw_rect(Rect2(rx + 10, ry + 10, rw - 20, rh - 20), RG_B)
	draw_rect(Rect2(rx + 16, ry + 16, rw - 32, rh - 32), RG_A)
	# Motif tengah (bunga geometrik sederhana)
	var cx := rx + rw / 2.0
	var cy := ry + rh / 2.0
	draw_circle(Vector2(cx, cy), 22.0, RG_B)
	draw_circle(Vector2(cx, cy), 16.0, RG_H)
	draw_circle(Vector2(cx, cy), 10.0, RG_B)
	draw_circle(Vector2(cx, cy), 6.0, RG_FR)
	# Kelopak silang
	for ang in [0.0, PI/2, PI, PI*1.5]:
		var bx := cx + cos(ang) * 18.0
		var by := cy + sin(ang) * 18.0
		draw_circle(Vector2(bx, by), 8.0, RG_B)
		draw_circle(Vector2(bx, by), 5.0, RG_H)
	# Highlight atas karpet
	draw_rect(Rect2(rx, ry, rw, 4), RG_H.lightened(0.2))
	# Fringe (rumbai) kiri kanan
	for i in range(0, int(rh), 8):
		draw_rect(Rect2(rx - 8, ry + float(i), 8, 5), RG_FR)
		draw_rect(Rect2(rx + rw, ry + float(i), 8, 5), RG_FR)

# ══════════════════════════════════════════════════════════════════════════════
#  MEJA (col 2, row 2–3)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_table() -> void:
	var tx := float(OX + 2 * TS + 6)
	var ty := float(OY + 2 * TS + 6)
	var tw := float(TS - 12)
	var th := float(TS * 2 - 12)

	# Shadow meja
	draw_rect(Rect2(tx + 4, ty + th, tw, 10), SHAD)
	# Permukaan atas
	draw_rect(Rect2(tx, ty, tw, th), WD_M)
	draw_rect(Rect2(tx + 3, ty + 3, tw - 6, th - 6), WD_H)
	draw_rect(Rect2(tx + 3, ty + 3, tw - 6, 6), Color(1,1,1,0.15))  # gloss
	# Serat kayu horizontal
	for i in range(5):
		draw_rect(Rect2(tx + 3, ty + 10.0 + float(i) * 18.0, tw - 6, 2), WD_G)
	# Tepi meja (bevel)
	draw_rect(Rect2(tx, ty, tw, 4), WD_H)
	draw_rect(Rect2(tx, ty + th - 4, tw, 4), WD_D)
	draw_rect(Rect2(tx, ty, 4, th), WD_H)
	draw_rect(Rect2(tx + tw - 4, ty, 4, th), WD_D)
	# Kaki meja
	draw_rect(Rect2(tx + 4, ty + th - 2, 6, 14), WD_D)
	draw_rect(Rect2(tx + tw - 10, ty + th - 2, 6, 14), WD_D)
	draw_rect(Rect2(tx + 4, ty + th + 8, 6, 6), WD_G)
	draw_rect(Rect2(tx + tw - 10, ty + th + 8, 6, 6), WD_G)
	# Item di atas meja
	_draw_table_items(tx, ty, tw)

func _draw_table_items(tx: float, ty: float, tw: float) -> void:
	# Cangkir teh
	var cx := tx + tw / 2.0 - 6.0
	var cy := ty + 16.0
	draw_rect(Rect2(cx - 8, cy, 16, 14), Color(0.92, 0.90, 0.86))
	draw_rect(Rect2(cx - 7, cy + 2, 14, 10), Color(0.80, 0.54, 0.32, 0.85))  # teh
	draw_rect(Rect2(cx - 8, cy, 16, 3), Color(0.97, 0.97, 0.97))
	draw_rect(Rect2(cx + 7, cy + 4, 5, 6), Color(0.80, 0.78, 0.74))  # pegangan
	draw_rect(Rect2(cx + 9, cy + 5, 3, 4), Color(0.92, 0.90, 0.86))
	# Piring
	draw_rect(Rect2(cx - 10, cy + 13, 20, 4), Color(0.90, 0.88, 0.84))
	# Uap
	for i in range(3):
		var steam_a := 0.25 - float(i) * 0.07
		draw_circle(Vector2(cx - 3 + float(i) * 3, cy - 4 - float(i) * 3), 2.0, Color(0.90, 0.90, 0.92, steam_a))
	# Pot tanaman kecil
	var px := tx + tw / 2.0 + 14.0
	var py := ty + 22.0
	draw_rect(Rect2(px - 8, py + 6, 16, 12), Color(0.58, 0.36, 0.14))
	draw_rect(Rect2(px - 9, py + 4, 18, 4), Color(0.48, 0.28, 0.10))
	draw_circle(Vector2(px, py), 8.0, Color(0.28, 0.62, 0.22))
	draw_circle(Vector2(px, py - 2), 5.0, Color(0.40, 0.80, 0.30))
	draw_circle(Vector2(px - 3, py + 2), 4.0, Color(0.26, 0.58, 0.20))

# ══════════════════════════════════════════════════════════════════════════════
#  LEMARI BUKU (col 1, row 1–3)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_bookshelf() -> void:
	var sx := float(OX + TS + 4)
	var sy := float(OY + TS + 4)
	var sw := float(TS - 8)
	var sh := float(TS * 3 - 8)

	# Shadow
	draw_rect(Rect2(sx + 4, sy + sh, sw, 8), SHAD)
	# Frame lemari
	draw_rect(Rect2(sx, sy, sw, sh), WD_D)
	draw_rect(Rect2(sx + 4, sy + 4, sw - 8, sh - 8), WD_G)
	# Panel belakang
	draw_rect(Rect2(sx + 6, sy + 6, sw - 12, sh - 12), Color(0.24, 0.16, 0.06))
	# Rak divider
	for i in range(3):
		var ry2 := sy + 6.0 + float(i + 1) * ((sh - 12) / 4.0)
		draw_rect(Rect2(sx + 4, ry2, sw - 8, 5), WD_M)
		draw_rect(Rect2(sx + 4, ry2, sw - 8, 2), WD_H)
	# Highlight frame
	draw_rect(Rect2(sx, sy, 4, sh), WD_H)
	draw_rect(Rect2(sx, sy, sw, 4), WD_H)
	# Buku-buku
	var book_colors : Array[Color] = [BK_R, BK_G, BK_B, BK_Y, BK_P, BK_R, BK_B, BK_G]
	for shelf in range(4):
		var shelf_y := sy + 8.0 + float(shelf) * ((sh - 12) / 4.0)
		var shelf_h := (sh - 12) / 4.0 - 5.0
		var bx_start := sx + 8.0
		var bi := shelf * 2
		for b in range(4):
			var bw := 8.0 + float((bi + b) % 3) * 2.0
			if bx_start + bw > sx + sw - 8: break
			var bc := book_colors[(bi + b) % book_colors.size()]
			draw_rect(Rect2(bx_start, shelf_y, bw, shelf_h - 2), bc)
			draw_rect(Rect2(bx_start, shelf_y, 2, shelf_h - 2), bc.lightened(0.2))
			draw_rect(Rect2(bx_start + bw - 2, shelf_y, 2, shelf_h - 2), bc.darkened(0.2))
			# Judul buku (garis mini)
			draw_rect(Rect2(bx_start + 1, shelf_y + 4, bw - 4, 1), Color(1,1,1,0.3))
			bx_start += bw + 2.0
	# Alas lemari
	draw_rect(Rect2(sx - 2, sy + sh - 4, sw + 4, 6), WD_D)

# ══════════════════════════════════════════════════════════════════════════════
#  RANJANG (col 9–10, row 1–2)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_bed() -> void:
	var bx := float(OX + 9 * TS)
	var by := float(OY + 1 * TS)
	var bw := float(2 * TS)
	var bh := float(2 * TS)

	# Shadow
	draw_rect(Rect2(bx + 4, by + bh, bw, 10), SHAD)
	# Rangka ranjang
	draw_rect(Rect2(bx, by, bw, bh), WD_D)
	draw_rect(Rect2(bx + 4, by + 4, bw - 8, bh - 8), WD_M)
	# Highlight rangka
	draw_rect(Rect2(bx, by, bw, 4), WD_H)
	draw_rect(Rect2(bx, by, 4, bh), WD_H)
	# Kasur
	draw_rect(Rect2(bx + 6, by + 6, bw - 12, bh - 12), BD_M)
	draw_rect(Rect2(bx + 8, by + 8, bw - 16, bh - 16), BD_H)
	draw_rect(Rect2(bx + 8, by + 8, bw - 16, 5), Color(1,1,1,0.3))
	# Kepala ranjang
	draw_rect(Rect2(bx, by, bw, 20), WD_D)
	draw_rect(Rect2(bx + 4, by + 4, bw - 8, 14), WD_M)
	draw_rect(Rect2(bx + 6, by + 5, bw - 12, 4), WD_H)
	# Ukiran kepala ranjang
	draw_circle(Vector2(bx + bw/2, by + 12), 6.0, WD_H)
	draw_circle(Vector2(bx + bw/2, by + 12), 4.0, WD_M)
	# Bantal (2 bantal)
	draw_rect(Rect2(bx + 8, by + 22, bw/2 - 10, 24), PL)
	draw_rect(Rect2(bx + bw/2 + 2, by + 22, bw/2 - 10, 24), PL)
	# Highlight bantal
	draw_rect(Rect2(bx + 10, by + 23, 10, 4), Color(1,1,1,0.6))
	draw_rect(Rect2(bx + bw/2 + 4, by + 23, 10, 4), Color(1,1,1,0.6))
	# Selimut (memenuhi 2/3 bawah)
	var sel_y := by + 44.0
	for i in range(5):
		var sc := BL_A if i % 2 == 0 else BL_B
		draw_rect(Rect2(bx + 6, sel_y + float(i) * 8, bw - 12, 8), sc)
	# Highlight atas selimut
	draw_rect(Rect2(bx + 6, sel_y, bw - 12, 4), BL_B.lightened(0.2))
	# Lekukan selimut
	draw_rect(Rect2(bx + 6, sel_y + 40, bw - 12, 4), BL_A.darkened(0.15))
	# Kaki ranjang
	draw_rect(Rect2(bx + 2, by + bh, 8, 10), WD_D)
	draw_rect(Rect2(bx + bw - 10, by + bh, 8, 10), WD_D)

# ══════════════════════════════════════════════════════════════════════════════
#  LAMPU (col 8, row 1)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_lamp() -> void:
	var lx := float(OX + 8 * TS + TS / 2)
	var ly := float(OY + TS + 10)

	# Cahaya ambient (glow oval)
	draw_circle(Vector2(lx, ly + 20), 40.0, Color(LP_Y.r, LP_Y.g, LP_Y.b, 0.08))
	draw_circle(Vector2(lx, ly + 20), 28.0, Color(LP_Y.r, LP_Y.g, LP_Y.b, 0.10))
	draw_circle(Vector2(lx, ly + 20), 16.0, Color(LP_Y.r, LP_Y.g, LP_Y.b, 0.14))
	# Tiang lampu
	draw_rect(Rect2(lx - 3, ly + 16, 6, 40), WD_M)
	draw_rect(Rect2(lx - 2, ly + 16, 3, 38), WD_H)
	draw_rect(Rect2(lx - 6, ly + 52, 12, 5), WD_D)
	draw_rect(Rect2(lx - 8, ly + 54, 16, 3), WD_D)
	# Kap lampu
	draw_rect(Rect2(lx - 18, ly + 4, 36, 14), LP_G)
	draw_rect(Rect2(lx - 16, ly + 4, 32, 4), LP_G.lightened(0.2))
	draw_rect(Rect2(lx - 20, ly + 14, 40, 4), LP_G.darkened(0.1))
	# Bola lampu
	draw_circle(Vector2(lx, ly + 12), 8.0, LP_Y)
	draw_circle(Vector2(lx - 3, ly + 10), 3.0, Color(1.0, 1.0, 0.9, 0.8))  # glare
	# Aksen emas
	draw_rect(Rect2(lx - 4, ly + 2, 8, 4), LP_GD)

# ══════════════════════════════════════════════════════════════════════════════
#  JENDELA INTERIOR (col 10, row 2)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_window_interior() -> void:
	var wx := float(OX + 10 * TS + 8)
	var wy := float(OY + 2 * TS + 10)
	var ww := 44.0
	var wh := 38.0
	# Kusen
	draw_rect(Rect2(wx - 5, wy - 5, ww + 10, wh + 10), WD_D)
	draw_rect(Rect2(wx, wy, ww, wh), Color(0.42, 0.32, 0.14))
	# Kaca — langit/luar
	draw_rect(Rect2(wx + 3, wy + 3, ww - 6, wh - 6), Color(0.62, 0.82, 0.96, 0.90))
	# Langit gradasi di kaca
	draw_rect(Rect2(wx + 3, wy + 3, ww - 6, (wh - 6) / 2.0), Color(0.48, 0.68, 0.92, 0.90))
	# Refleksi cahaya
	draw_rect(Rect2(wx + 5, wy + 5, 10, 6), Color(1.0, 1.0, 1.0, 0.28))
	draw_rect(Rect2(wx + 8, wy + 7, 4, 4), Color(1.0, 1.0, 1.0, 0.20))
	# Pembagi kaca
	draw_rect(Rect2(wx + 3, wy + wh/2 - 1, ww - 6, 3), Color(0.42, 0.32, 0.14))
	draw_rect(Rect2(wx + ww/2 - 1, wy + 3, 3, wh - 6), Color(0.42, 0.32, 0.14))
	# Highlight kusen
	draw_rect(Rect2(wx - 5, wy - 5, ww + 10, 3), WD_H)
	draw_rect(Rect2(wx - 5, wy - 5, 3, wh + 10), WD_H)

# ══════════════════════════════════════════════════════════════════════════════
#  PINTU KELUAR (col 5–6, row 7)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_door() -> void:
	var dx := float(OX + 5 * TS + 8)
	var dy := float(OY + 7 * TS - 52)
	var dw := float(TS * 2 - 16)
	var dh := 52.0

	# Kusen
	draw_rect(Rect2(dx - 6, dy - 4, dw + 12, dh + 4), WD_D)
	# Daun pintu
	draw_rect(Rect2(dx, dy, dw, dh), DR_A)
	draw_rect(Rect2(dx + 3, dy + 3, dw - 6, dh - 3), DR_A.lightened(0.06))
	# Panel panel pintu
	draw_rect(Rect2(dx + 6, dy + 6, dw/2 - 10, 18), DR_H)
	draw_rect(Rect2(dx + dw/2 + 4, dy + 6, dw/2 - 10, 18), DR_H)
	draw_rect(Rect2(dx + 6, dy + 28, dw - 12, 18), DR_H)
	# Shadow panel
	for px2 in [dx + 6, dx + dw/2 + 4]:
		draw_rect(Rect2(px2, dy + 22, dw/2 - 10, 3), DR_D)
	draw_rect(Rect2(dx + 6, dy + 44, dw - 12, 3), DR_D)
	# Knob
	draw_circle(Vector2(dx + dw - 14, dy + 30), 5.0, Color(0.86, 0.72, 0.18))
	draw_circle(Vector2(dx + dw - 14, dy + 30), 3.0, Color(1.0, 0.90, 0.40))
	# Label ↓ EXIT
	draw_rect(Rect2(dx + dw/2 - 24, dy - 20, 48, 16), Color(0.22, 0.64, 0.28))
	draw_rect(Rect2(dx + dw/2 - 22, dy - 18, 44, 12), Color(0.30, 0.78, 0.34))
	# Teks mini "EXIT" (blok pixel)
	var ex := dx + dw/2 - 16.0
	var ey := dy - 16.0
	for i in range(4): draw_rect(Rect2(ex + float(i)*9, ey, 7, 8), Color(1,1,1,0.9))
	draw_rect(Rect2(ex - 1, ey - 1, 39, 10), Color(0,0,0,0))  # clear hit

# ══════════════════════════════════════════════════════════════════════════════
#  AMBIENT WARM TINT
# ══════════════════════════════════════════════════════════════════════════════
func _draw_ambient() -> void:
	# Sedikit warna hangat overlay dari lampu
	var lx := float(OX + 8 * TS + TS / 2)
	var ly := float(OY + TS + 30)
	draw_circle(Vector2(lx, ly), 120.0, Color(LP_Y.r, LP_Y.g, LP_Y.b, 0.04))
