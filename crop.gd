# crop.gd — HD v2
# Tanaman 3 stage dengan visual detail per stage.
# Semua digambar via _draw() tanpa tekstur eksternal.
extends Node2D

enum Stage { PLANTED, GROWING, READY }

const GROW_TIME_1 := 8.0    # detik → GROWING
const GROW_TIME_2 := 18.0   # detik → READY

var stage    : Stage    = Stage.PLANTED
var timer    : float    = 0.0
var tile_pos : Vector2i = Vector2i.ZERO

const TS     := GameState.TILE_SIZE  # 64

# ── Palet ─────────────────────────────────────────────────────────────────────
# Tanah
const SL_A  := Color(0.38, 0.22, 0.08)   # tanah mid
const SL_B  := Color(0.28, 0.15, 0.04)   # tanah gelap / alur
const SL_H  := Color(0.52, 0.34, 0.14)   # tanah highlight
# Benih
const SD_A  := Color(0.70, 0.86, 0.32)   # benih hijau muda
const SD_H  := Color(0.86, 0.96, 0.52)   # benih highlight
const SD_D  := Color(0.48, 0.62, 0.20)   # benih shadow
# Batang
const ST_A  := Color(0.16, 0.58, 0.12)   # batang hijau
const ST_H  := Color(0.28, 0.74, 0.22)   # batang highlight
const ST_D  := Color(0.08, 0.38, 0.06)   # batang shadow
# Daun
const LF_A  := Color(0.22, 0.72, 0.16)   # daun mid
const LF_H  := Color(0.38, 0.88, 0.28)   # daun highlight
const LF_D  := Color(0.12, 0.50, 0.10)   # daun shadow
const LF_V  := Color(0.10, 0.44, 0.08)   # urat daun
# Gandum matang
const WH_A  := Color(0.96, 0.82, 0.16)   # gandum emas
const WH_H  := Color(1.00, 0.96, 0.60)   # gandum highlight
const WH_D  := Color(0.72, 0.56, 0.08)   # gandum shadow
const WH_B  := Color(0.88, 0.65, 0.08)   # gandum mid-dark
const AW_A  := Color(0.50, 0.40, 0.12)   # duri gandum
# Efek
const GL_A  := Color(1.0, 0.98, 0.70, 0.80)  # glint
const GL_B  := Color(0.98, 0.96, 0.50, 0.50)
# Outline umum
const OUT   := Color(0.06, 0.04, 0.02, 0.70)

var _glint_t : float = 0.0
var _sway_t  : float = 0.0

func _process(delta: float) -> void:
	if stage == Stage.READY:
		_sway_t += delta * 1.8
		_glint_t += delta
		if _glint_t > 2.5: _glint_t = 0.0
		queue_redraw()
		return
	timer += delta
	if stage == Stage.PLANTED and timer >= GROW_TIME_1:
		stage = Stage.GROWING
		queue_redraw()
	elif stage == Stage.GROWING and timer >= GROW_TIME_2:
		stage = Stage.READY
		queue_redraw()
		_pulse()

func _pulse() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.10)
	tw.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)

func _draw() -> void:
	var h := TS / 2.0   # = 32 (half tile)
	_draw_soil(h)
	match stage:
		Stage.PLANTED: _draw_planted(h)
		Stage.GROWING: _draw_growing(h)
		Stage.READY:   _draw_ready(h)

# ── Tanah dasar (sama di semua stage) ────────────────────────────────────────
func _draw_soil(h: float) -> void:
	# Base tile tanah
	draw_rect(Rect2(-h, -h, TS, TS), SL_A)
	# Alur bajak (3 garis gelap + highlight)
	for i in range(4):
		var ax := -h + 6.0 + float(i) * 14.0
		draw_rect(Rect2(ax, -h + 4, 3, TS - 8), SL_B)
		draw_rect(Rect2(ax + 3, -h + 4, 2, TS - 8), SL_H)
	# Highlight atas tanah
	draw_rect(Rect2(-h, -h, TS, 5), SL_H)
	# Shadow bawah tanah
	draw_rect(Rect2(-h, h - 5, TS, 5), SL_B)
	# Kerikil kecil
	draw_rect(Rect2(-18, -h + 16, 5, 3), SL_B.darkened(0.2))
	draw_rect(Rect2(12, -h + 40, 6, 3), SL_B.darkened(0.15))
	draw_rect(Rect2(-8, h - 18, 4, 3), SL_H)

# ── Stage 1: PLANTED ──────────────────────────────────────────────────────────
func _draw_planted(h: float) -> void:
	# Tanah terusik di tengah (lubang tanam)
	draw_circle(Vector2(0, h - 12), 10.0, SL_B)
	draw_circle(Vector2(0, h - 12), 8.0, SL_B.darkened(0.2))
	# Tanah tumpukan
	draw_rect(Rect2(-10, h - 18, 20, 8), SL_A)
	# Benih baru muncul — dua tunas kecil
	draw_circle(Vector2(-4, h - 22), 5.0, SD_A)
	draw_circle(Vector2(-4, h - 22), 3.0, SD_H)
	draw_circle(Vector2(4, h - 20), 4.0, SD_A)
	draw_circle(Vector2(4, h - 20), 2.0, SD_H)
	# Batang sangat kecil
	draw_line(Vector2(0, h - 14), Vector2(-4, h - 24), ST_A, 2.5)
	draw_line(Vector2(0, h - 14), Vector2(4, h - 22), ST_A, 2.0)
	# Outline shadow
	draw_circle(Vector2(-4, h - 22), 5.0, OUT.darkened(-0.5))
	# Percikan tanah
	for i in range(5):
		var ang := float(i) * 1.26
		var dx  := cos(ang) * 13.0
		var dy  := sin(ang) * 9.0
		draw_circle(Vector2(dx, h - 12 + dy), 2.0, SL_H)

# ── Stage 2: GROWING ──────────────────────────────────────────────────────────
func _draw_growing(_h: float) -> void:
	# Batang utama — 3 segmen dengan gradasi
	draw_rect(Rect2(-4, -22, 8, 32), ST_D)
	draw_rect(Rect2(-3, -22, 6, 30), ST_A)
	draw_rect(Rect2(-2, -22, 3, 28), ST_H)   # highlight kiri batang

	# Daun kiri bawah — bentuk oval miring
	_draw_leaf(-6, -2, -26, -14, false)
	# Daun kanan bawah
	_draw_leaf(6, -6, 26, -18, true)
	# Daun kiri atas
	_draw_leaf(-5, -14, -22, -26, false)
	# Daun kanan atas
	_draw_leaf(5, -16, 20, -28, true)
	# Tunas pucuk (ujung atas batang)
	draw_circle(Vector2(0, -24), 5.0, LF_A)
	draw_circle(Vector2(0, -24), 3.0, LF_H)
	draw_circle(Vector2(-1, -26), 2.0, LF_H)

func _draw_leaf(x0: float, y0: float, x1: float, y1: float, right: bool) -> void:
	# Isi daun (polygon sederhana dari rect + lingkaran)
	var mx := (x0 + x1) / 2.0
	var my := (y0 + y1) / 2.0
	# Outline gelap
	draw_line(Vector2(x0, y0), Vector2(x1, y1), LF_D, 7.0)
	# Isi mid
	draw_line(Vector2(x0, y0), Vector2(x1, y1), LF_A, 5.0)
	# Highlight tepi atas
	draw_line(Vector2(x0, y0 - 2), Vector2(mx, my - 3), LF_H, 2.5)
	# Urat daun utama
	draw_line(Vector2(x0, y0), Vector2(x1, y1), LF_V, 1.0)
	# Urat cabang
	var side := 1.0 if right else -1.0
	draw_line(Vector2(mx, my), Vector2(mx + side * 6, my - 6), LF_V, 1.0)
	draw_line(Vector2(mx + side * 4, my - 2), Vector2(mx + side * 10, my - 8), LF_V, 1.0)

# ── Stage 3: READY ────────────────────────────────────────────────────────────
func _draw_ready(h: float) -> void:
	# Sway ringan
	var sway := sin(_sway_t) * 2.0

	# Batang dewasa
	draw_rect(Rect2(-4 + sway * 0.3, -16, 8, 28), ST_D)
	draw_rect(Rect2(-3 + sway * 0.3, -16, 6, 26), ST_A)
	draw_rect(Rect2(-2 + sway * 0.3, -16, 3, 24), ST_H)

	# 2 daun besar
	_draw_leaf(-5, -4, -20, -16, false)
	_draw_leaf(5, -6, 20, -18, true)

	# Tangkai kepala gandum (sedikit bengkok karena sway)
	var head_x := sway
	draw_line(Vector2(0, -16), Vector2(head_x, -40), ST_D, 5.0)
	draw_line(Vector2(0, -16), Vector2(head_x, -40), ST_A, 3.0)
	draw_line(Vector2(1, -16), Vector2(head_x + 1, -38), ST_H, 1.5)

	# Kepala gandum — berlapis untuk kedalaman
	var hx := head_x
	var hy := -44.0
	# Shadow bawah bulat
	draw_circle(Vector2(hx, hy + 4), 14.0, WH_D)
	# Badan utama
	draw_circle(Vector2(hx, hy), 14.0, WH_B)
	draw_circle(Vector2(hx, hy), 12.0, WH_A)
	# Gradient highlight kiri-atas
	draw_circle(Vector2(hx - 4, hy - 4), 8.0, WH_H)
	draw_circle(Vector2(hx - 5, hy - 5), 5.0, Color(1.0, 0.99, 0.80))

	# Biji-biji gandum (6 biji, melingkar)
	for i in range(6):
		var ang   := float(i) * PI / 3.0
		var bx    := hx + cos(ang) * 9.0
		var by    := hy + sin(ang) * 9.0
		draw_circle(Vector2(bx, by), 3.5, WH_D)
		draw_circle(Vector2(bx, by), 2.5, WH_A)
		draw_circle(Vector2(bx - 0.5, by - 0.5), 1.0, WH_H)

	# Biji tengah
	draw_circle(Vector2(hx, hy), 4.0, WH_D)
	draw_circle(Vector2(hx, hy), 3.0, WH_A)
	draw_circle(Vector2(hx - 1, hy - 1), 1.2, WH_H)

	# Duri (awn) — 6 helai
	for i in range(6):
		var ang   := float(i) * PI / 3.0 - 0.2
		var ax    := hx + cos(ang) * 11.0
		var ay    := hy + sin(ang) * 11.0
		var ex    := ax + cos(ang) * 12.0
		var ey    := ay + sin(ang) * 10.0
		draw_line(Vector2(ax, ay), Vector2(ex, ey), AW_A, 1.5)
		# Ujung duri sedikit melengkung
		draw_line(Vector2(ex, ey), Vector2(ex + cos(ang + 0.4) * 4, ey + sin(ang + 0.4) * 3), AW_A, 1.0)

	# Glint berkedip
	if _glint_t < 0.3:
		var alpha := 1.0 - _glint_t / 0.3
		draw_circle(Vector2(hx - 6, hy - 8), 4.0, Color(1.0, 1.0, 0.9, alpha * 0.9))
		draw_line(Vector2(hx - 6, hy - 14), Vector2(hx - 6, hy - 4),  Color(1.0, 1.0, 0.8, alpha * 0.5), 1.5)
		draw_line(Vector2(hx - 12, hy - 8), Vector2(hx - 2, hy - 8),  Color(1.0, 1.0, 0.8, alpha * 0.5), 1.5)

	# Outline kepala gandum
	draw_arc(Vector2(hx, hy), 15.0, 0, TAU, 20, OUT.lightened(0.4), 1.5)

func is_ready_to_harvest() -> bool:
	return stage == Stage.READY

func harvest() -> bool:
	if stage != Stage.READY: return false
	queue_free()
	return true

func get_save_data() -> Dictionary:
	return { "tx": tile_pos.x, "ty": tile_pos.y, "stage": int(stage), "timer": timer }
