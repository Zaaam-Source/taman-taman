# character_body_2d.gd — HD v2
# Grid virtual 32×32 @ PS=2 → output 64×64 px di layar
# 4 arah, animasi jalan, shading 3-tone per material
extends CharacterBody2D

const SPEED    := 200.0
const DEADZONE := 22.0

var _touch_id  : int     = -1
var _drag_orig : Vector2 = Vector2.ZERO
var _drag_cur  : Vector2 = Vector2.ZERO

enum Dir { DOWN = 0, UP = 1, LEFT = 2, RIGHT = 3 }
var _dir    : int   = Dir.DOWN
var _step   : int   = 0
var _anim_t : float = 0.0
const STEP_INTERVAL := 0.16

# 1 virtual pixel = 2×2 layar → sprite 32vp * 2 = 64px
const PS := 2

# ── Palet warna ───────────────────────────────────────────────────────────────
# Skin
const SK_H := Color(1.00, 0.90, 0.74)   # highlight
const SK_M := Color(0.93, 0.75, 0.56)   # mid
const SK_D := Color(0.76, 0.56, 0.38)   # shadow
# Hair
const HR_H := Color(0.50, 0.32, 0.13)
const HR_M := Color(0.28, 0.16, 0.05)
const HR_D := Color(0.14, 0.07, 0.01)
# Eyes
const EW   := Color(0.97, 0.97, 0.97)   # putih
const EI   := Color(0.20, 0.52, 0.94)   # iris biru
const EP   := Color(0.06, 0.04, 0.08)   # pupil / lash
const ESH  := Color(0.80, 0.66, 0.50)   # eyelid shadow
const BR   := Color(0.20, 0.11, 0.03)   # alis
const CK   := Color(1.00, 0.68, 0.64, 0.60)  # pipi
# Shirt
const SH_H := Color(0.46, 0.74, 1.00)
const SH_M := Color(0.22, 0.52, 0.92)
const SH_D := Color(0.10, 0.32, 0.72)
const SH_X := Color(0.06, 0.20, 0.52)   # fold gelap
const CL   := Color(0.60, 0.84, 1.00)   # collar
# Pants
const PN_H := Color(0.40, 0.42, 0.84)
const PN_M := Color(0.22, 0.24, 0.62)
const PN_D := Color(0.12, 0.14, 0.42)
# Belt
const BL   := Color(0.20, 0.14, 0.06)
const BK   := Color(0.88, 0.74, 0.18)   # buckle emas
# Boots
const BT_H := Color(0.54, 0.36, 0.16)
const BT_M := Color(0.30, 0.18, 0.06)
const BT_D := Color(0.16, 0.09, 0.02)
const SL   := Color(0.10, 0.07, 0.02)   # sole
# Outline & shadow
const OUT  := Color(0.08, 0.06, 0.04, 0.85)
const SHAD := Color(0.00, 0.00, 0.00, 0.18)
const MRED := Color(0.82, 0.38, 0.32)   # mulut

# ── Physics & input (sama seperti versi lama) ─────────────────────────────────
func _physics_process(delta: float) -> void:
	var dir_vec := Vector2.ZERO
	if _touch_id >= 0:
		var d := _drag_cur - _drag_orig
		if d.length() > DEADZONE:
			dir_vec = d.normalized()
	if dir_vec != Vector2.ZERO:
		_anim_t += delta
		if _anim_t >= STEP_INTERVAL:
			_anim_t = 0.0
			_step = 1 - _step
			queue_redraw()
		_update_dir(dir_vec)
		_try_move(dir_vec * SPEED * delta)
	elif _step != 0:
		_step = 0
		queue_redraw()

func _update_dir(d: Vector2) -> void:
	var prev := _dir
	if absf(d.x) > absf(d.y):
		_dir = Dir.RIGHT if d.x > 0 else Dir.LEFT
	else:
		_dir = Dir.DOWN if d.y > 0 else Dir.UP
	if _dir != prev:
		queue_redraw()

func _try_move(dp: Vector2) -> void:
	var np := position + dp
	if _walkable(np):          position = np;         return
	if _walkable(Vector2(np.x, position.y)): position.x = np.x; return
	if _walkable(Vector2(position.x, np.y)): position.y = np.y

func _walkable(pos: Vector2) -> bool:
	var off := 10.0
	for p: Vector2 in [pos + Vector2(-off, 4), pos + Vector2(off, 4)]:
		if GameState.in_interior:
			var lp := p - Vector2(GameState.INT_OFFSET_X, GameState.INT_OFFSET_Y)
			var t := Vector2i(int(lp.x / GameState.TILE_SIZE), int(lp.y / GameState.TILE_SIZE))
			if not GameState.is_walkable_interior(t): return false
		else:
			var t := Vector2i(int(p.x / GameState.TILE_SIZE), int(p.y / GameState.TILE_SIZE))
			if not GameState.is_walkable(t): return false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id < 0:
			_touch_id  = event.index
			_drag_orig = event.position
			_drag_cur  = event.position
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_step = 0
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_drag_cur = event.position

# ── Draw helpers ─────────────────────────────────────────────────────────────
# Semua koordinat dalam virtual pixel (VP), origin = pusat kaki
# ox = -16*PS, oy = -32*PS

func _px(x: int, y: int, ox: int, oy: int, c: Color) -> void:
	draw_rect(Rect2(ox + x * PS, oy + y * PS, PS, PS), c)

func _row(x0: int, x1: int, y: int, ox: int, oy: int, c: Color) -> void:
	if x1 < x0: return
	draw_rect(Rect2(ox + x0 * PS, oy + y * PS, (x1 - x0 + 1) * PS, PS), c)

func _blk(x: int, y: int, w: int, h: int, ox: int, oy: int, c: Color) -> void:
	draw_rect(Rect2(ox + x * PS, oy + y * PS, w * PS, h * PS), c)

# Mirror x untuk tampak kiri (flip = true)
func _frow(x0: int, x1: int, y: int, ox: int, oy: int, c: Color, flip: bool) -> void:
	if flip: _row(31 - x1, 31 - x0, y, ox, oy, c)
	else:    _row(x0, x1, y, ox, oy, c)

func _fblk(x: int, y: int, w: int, h: int, ox: int, oy: int, c: Color, flip: bool) -> void:
	if flip: _blk(31 - x - w + 1, y, w, h, ox, oy, c)
	else:    _blk(x, y, w, h, ox, oy, c)

func _fpx(x: int, y: int, ox: int, oy: int, c: Color, flip: bool) -> void:
	if flip: _px(31 - x, y, ox, oy, c)
	else:    _px(x, y, ox, oy, c)

# ── Main draw ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	var ox := -16 * PS
	var oy := -32 * PS
	# Bayangan ground
	draw_rect(Rect2(ox + 5 * PS, oy + 31 * PS, 22 * PS, 2 * PS), SHAD)
	draw_rect(Rect2(ox + 3 * PS, oy + 31 * PS, 26 * PS, PS),     SHAD)
	match _dir:
		Dir.DOWN:  _draw_front(ox, oy)
		Dir.UP:    _draw_back(ox, oy)
		Dir.LEFT:  _draw_side(ox, oy, true)
		Dir.RIGHT: _draw_side(ox, oy, false)

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  TAMPAK DEPAN                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════╝
func _draw_front(ox: int, oy: int) -> void:
	_front_boots(ox, oy)
	_front_pants(ox, oy)
	_front_belt(ox, oy)
	_front_shirt(ox, oy)
	_front_arms(ox, oy)
	_front_neck(ox, oy)
	_front_face(ox, oy)
	_front_hair(ox, oy)

func _front_hair(ox: int, oy: int) -> void:
	# Outline atas
	_row(8, 23, 0, ox, oy, HR_D)
	# Badan rambut
	_row(6, 25, 1, ox, oy, HR_M)
	_row(5, 26, 2, ox, oy, HR_M)
	_row(5, 26, 3, ox, oy, HR_M)
	_row(5, 26, 4, ox, oy, HR_M)
	# Sisi menggantung
	for y in [5, 6, 7, 8]:
		_px(5, y, ox, oy, HR_M); _px(6, y, ox, oy, HR_M)
		_px(25, y, ox, oy, HR_M); _px(26, y, ox, oy, HR_M)
	# Highlight atas
	_row(9, 18, 1, ox, oy, HR_H)
	_row(10, 16, 2, ox, oy, HR_H)
	# Outline sisi
	_px(5, 1, ox, oy, HR_D); _px(26, 1, ox, oy, HR_D)
	_px(5, 5, ox, oy, HR_D); _px(26, 5, ox, oy, HR_D)
	# Poni depan (beberapa helai)
	_px(7, 4, ox, oy, HR_D); _px(8, 4, ox, oy, HR_D)
	_px(23, 4, ox, oy, HR_D); _px(24, 4, ox, oy, HR_D)

func _front_face(ox: int, oy: int) -> void:
	# Base wajah
	_blk(7, 4, 18, 10, ox, oy, SK_M)
	# Highlight dahi dan pipi tengah
	_blk(11, 4, 10, 5, ox, oy, SK_H)
	# Shadow sisi wajah
	for y in range(4, 14):
		_px(7, y, ox, oy, SK_D); _px(24, y, ox, oy, SK_D)
	# Shadow bawah rambut
	_row(8, 23, 4, ox, oy, SK_D)
	# Shadow dagu
	_row(9, 22, 13, ox, oy, SK_D)
	# Alis
	_row(9, 13, 5, ox, oy, BR)
	_row(18, 22, 5, ox, oy, BR)
	# Mata kiri  — outline → iris → pupil → shine
	_blk(9, 6, 5, 3, ox, oy, EP)     # outline
	_blk(10, 7, 3, 2, ox, oy, EI)    # iris
	_px(11, 7, ox, oy, EP)            # pupil
	_px(10, 6, ox, oy, EW)            # white corner
	_px(13, 6, ox, oy, EW)
	_blk(10, 6, 3, 1, ox, oy, ESH)   # eyelid
	_px(10, 8, ox, oy, EW)            # sclera bawah
	_px(12, 8, ox, oy, EW)
	_px(10, 7, ox, oy, Color(1,1,1,0.7)) # shine
	# Mata kanan
	_blk(18, 6, 5, 3, ox, oy, EP)
	_blk(19, 7, 3, 2, ox, oy, EI)
	_px(20, 7, ox, oy, EP)
	_px(18, 6, ox, oy, EW); _px(22, 6, ox, oy, EW)
	_blk(19, 6, 3, 1, ox, oy, ESH)
	_px(19, 8, ox, oy, EW); _px(21, 8, ox, oy, EW)
	_px(20, 7, ox, oy, Color(1,1,1,0.7))
	# Hidung
	_px(14, 10, ox, oy, SK_D); _px(17, 10, ox, oy, SK_D)
	_row(15, 16, 11, ox, oy, SK_D)
	# Pipi
	_blk(8, 10, 3, 2, ox, oy, CK)
	_blk(21, 10, 3, 2, ox, oy, CK)
	# Mulut
	_row(13, 19, 12, ox, oy, SK_D)
	_row(14, 18, 12, ox, oy, MRED)
	_px(13, 12, ox, oy, SK_D); _px(19, 12, ox, oy, SK_D)
	# Outline bawah wajah
	_row(9, 22, 13, ox, oy, OUT)

func _front_neck(ox: int, oy: int) -> void:
	_blk(13, 14, 6, 2, ox, oy, SK_M)
	_px(13, 14, ox, oy, SK_D); _px(18, 14, ox, oy, SK_D)
	# Collar
	_blk(9, 15, 14, 2, ox, oy, CL)
	_px(9, 15, ox, oy, SH_D); _px(22, 15, ox, oy, SH_D)
	_row(10, 21, 16, ox, oy, SH_M)

func _front_shirt(ox: int, oy: int) -> void:
	# Badan kemeja
	_blk(7, 17, 18, 7, ox, oy, SH_M)
	# Highlight chest kiri-tengah
	_blk(12, 17, 6, 5, ox, oy, SH_H)
	_blk(13, 17, 4, 3, ox, oy, SH_H)
	# Shadow sisi
	for y in range(17, 24):
		_px(7, y, ox, oy, SH_D); _px(8, y, ox, oy, SH_D)
		_px(23, y, ox, oy, SH_D); _px(24, y, ox, oy, SH_D)
	# Fold baju bawah
	_row(7, 24, 23, ox, oy, SH_X)
	# Garis kancing
	_px(16, 18, ox, oy, SH_D)
	_px(16, 20, ox, oy, SH_D)
	_px(16, 22, ox, oy, SH_D)

func _front_arms(ox: int, oy: int) -> void:
	var ay := 18 if _step == 0 else 17   # animasi ayun
	# Lengan kiri
	_blk(4, ay, 4, 5, ox, oy, SH_M)
	_px(4, ay, ox, oy, SH_D); _px(4, ay+1, ox, oy, SH_D)
	_px(7, ay, ox, oy, SH_H)
	# Tangan kiri
	_blk(4, ay+5, 4, 3, ox, oy, SK_M)
	_px(4, ay+5, ox, oy, SK_D)
	_px(7, ay+5, ox, oy, SK_H)
	# Lengan kanan
	_blk(24, ay, 4, 5, ox, oy, SH_M)
	_px(27, ay, ox, oy, SH_D); _px(27, ay+1, ox, oy, SH_D)
	_px(24, ay, ox, oy, SH_H)
	# Tangan kanan
	_blk(24, ay+5, 4, 3, ox, oy, SK_M)
	_px(27, ay+5, ox, oy, SK_D)
	_px(24, ay+5, ox, oy, SK_H)

func _front_belt(ox: int, oy: int) -> void:
	_blk(7, 24, 18, 2, ox, oy, BL)
	# Buckle tengah
	_blk(14, 24, 4, 2, ox, oy, BK)
	_px(14, 24, ox, oy, BL); _px(17, 24, ox, oy, BL)

func _front_pants(ox: int, oy: int) -> void:
	var ll := 7; var rl := 18
	if _step == 1: ll = 6; rl = 19
	# Kaki kiri
	_blk(ll, 26, 8, 3, ox, oy, PN_M)
	for y in range(26, 29):
		_px(ll, y, ox, oy, PN_H)       # outer hl
		_px(ll+7, y, ox, oy, PN_D)     # inner shadow
	# Kaki kanan
	_blk(rl, 26, 7, 3, ox, oy, PN_M)
	for y in range(26, 29):
		_px(rl, y, ox, oy, PN_D)       # inner shadow
		_px(rl+6, y, ox, oy, PN_H)
	# Garis tengah celana
	_row(15, 16, 26, ox, oy, PN_D)
	_row(15, 16, 27, ox, oy, PN_D)

func _front_boots(ox: int, oy: int) -> void:
	var ll := 7; var rl := 18
	if _step == 1: ll = 6; rl = 19
	# Boot kiri
	_blk(ll, 29, 8, 3, ox, oy, BT_M)
	for y in range(29, 32):
		_px(ll, y, ox, oy, BT_H)
		_px(ll+7, y, ox, oy, BT_D)
	# Boot kanan
	_blk(rl, 29, 7, 3, ox, oy, BT_M)
	for y in range(29, 32):
		_px(rl, y, ox, oy, BT_D)
		_px(rl+6, y, ox, oy, BT_H)
	# Sole
	_row(ll, ll+7, 31, ox, oy, SL)
	_row(rl, rl+6, 31, ox, oy, SL)
	# Highlight toe
	_px(ll+1, 30, ox, oy, BT_H)
	_px(rl+5, 30, ox, oy, BT_H)

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  TAMPAK BELAKANG                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════╝
func _draw_back(ox: int, oy: int) -> void:
	# Tubuh sama seperti depan tapi tanpa wajah
	_front_boots(ox, oy)
	_front_pants(ox, oy)
	_front_belt(ox, oy)
	_front_shirt(ox, oy)
	_front_arms(ox, oy)
	# Leher belakang (kulit)
	_blk(13, 14, 6, 2, ox, oy, SK_M)
	# Kepala — rambut belakang menutupi wajah
	_blk(6, 4, 20, 10, ox, oy, HR_M)
	# Highlight mahkota
	_blk(8, 1, 16, 3, ox, oy, HR_H)
	_blk(10, 1, 12, 2, ox, oy, HR_H)
	# Outline top
	_row(8, 23, 0, ox, oy, HR_D)
	_row(6, 25, 1, ox, oy, HR_M)
	_row(5, 26, 2, ox, oy, HR_M)
	_row(5, 26, 3, ox, oy, HR_M)
	_row(5, 26, 4, ox, oy, HR_M)
	# Sisi rambut
	for y in range(5, 14):
		_px(5, y, ox, oy, HR_D); _px(6, y, ox, oy, HR_M)
		_px(25, y, ox, oy, HR_M); _px(26, y, ox, oy, HR_D)
	# Nape detail
	_row(13, 18, 13, ox, oy, SK_D)

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  TAMPAK SAMPING (flip = kiri)                                           ║
# ╚══════════════════════════════════════════════════════════════════════════╝
func _draw_side(ox: int, oy: int, flip: bool) -> void:
	_side_boots(ox, oy, flip)
	_side_pants(ox, oy, flip)
	_side_belt(ox, oy, flip)
	_side_shirt(ox, oy, flip)
	_side_neck(ox, oy, flip)
	_side_face(ox, oy, flip)
	_side_hair(ox, oy, flip)

func _side_hair(ox: int, oy: int, flip: bool) -> void:
	# Mahkota
	_frow(8, 22, 0, ox, oy, HR_D, flip)
	_frow(7, 24, 1, ox, oy, HR_M, flip)
	_frow(6, 24, 2, ox, oy, HR_M, flip)
	_frow(6, 22, 3, ox, oy, HR_M, flip)
	# Highlight
	_frow(9, 18, 1, ox, oy, HR_H, flip)
	_frow(9, 16, 2, ox, oy, HR_H, flip)
	# Rambut belakang
	for y in range(3, 13):
		_fpx(6, y, ox, oy, HR_D, flip)
		_fpx(7, y, ox, oy, HR_M, flip)
	# Poni depan
	_fpx(20, 3, ox, oy, HR_M, flip)
	_fpx(21, 4, ox, oy, HR_M, flip)
	_fpx(21, 5, ox, oy, HR_D, flip)

func _side_face(ox: int, oy: int, flip: bool) -> void:
	# Wajah dasar
	_fblk(8, 4, 14, 10, ox, oy, SK_M, flip)
	# Highlight
	_fblk(9, 5, 8, 5, ox, oy, SK_H, flip)
	# Shadow sisi belakang
	for y in range(4, 14):
		_fpx(8, y, ox, oy, SK_D, flip)
	# Hidung menonjol
	_fpx(21, 9, ox, oy, SK_D, flip)
	_fpx(22, 9, ox, oy, SK_D, flip)
	_fpx(22, 10, ox, oy, SK_M, flip)
	# Telinga
	_fblk(8, 7, 2, 3, ox, oy, SK_D, flip)
	_fpx(8, 8, ox, oy, SK_M, flip)
	# Alis
	_frow(13, 18, 5, ox, oy, BR, flip)
	# Mata sisi
	_fblk(14, 6, 5, 3, ox, oy, EP, flip)
	_fblk(15, 7, 3, 2, ox, oy, EI, flip)
	_fpx(16, 7, ox, oy, EP, flip)
	_fpx(15, 6, ox, oy, ESH, flip)
	_fpx(16, 6, ox, oy, ESH, flip)
	_fpx(15, 8, ox, oy, EW, flip)
	_fpx(17, 8, ox, oy, EW, flip)
	_fpx(15, 7, ox, oy, Color(1,1,1,0.7), flip)   # shine
	# Pipi
	_fblk(11, 10, 4, 2, ox, oy, CK, flip)
	# Mulut
	_frow(13, 17, 12, ox, oy, SK_D, flip)
	_frow(14, 17, 12, ox, oy, MRED, flip)
	# Outline dagu
	_frow(9, 21, 13, ox, oy, OUT, flip)

func _side_neck(ox: int, oy: int, flip: bool) -> void:
	_fblk(12, 14, 6, 2, ox, oy, SK_M, flip)
	_fblk(10, 15, 12, 2, ox, oy, CL, flip)
	_fpx(10, 15, ox, oy, SH_D, flip)
	_fpx(21, 15, ox, oy, SH_D, flip)

func _side_shirt(ox: int, oy: int, flip: bool) -> void:
	var ay := 18 if _step == 0 else 17
	# Badan samping
	_fblk(8, 17, 16, 7, ox, oy, SH_M, flip)
	_fblk(11, 17, 8, 5, ox, oy, SH_H, flip)
	# Shadow sisi
	for y in range(17, 24):
		_fpx(8, y, ox, oy, SH_D, flip)
		_fpx(23, y, ox, oy, SH_D, flip)
	_frow(8, 23, 23, ox, oy, SH_X, flip)
	# Lengan depan (terlihat menonjol ke depan)
	_fblk(22, ay, 4, 6, ox, oy, SH_M, flip)
	_fpx(22, ay, ox, oy, SH_H, flip)
	_fpx(25, ay, ox, oy, SH_D, flip)
	_fblk(22, ay+5, 4, 3, ox, oy, SK_M, flip)
	_fpx(22, ay+5, ox, oy, SK_H, flip)
	# Lengan belakang samar
	_fblk(4, ay+1, 3, 5, ox, oy, SH_D, flip)

func _side_belt(ox: int, oy: int, flip: bool) -> void:
	_fblk(8, 24, 16, 2, ox, oy, BL, flip)
	_fblk(14, 24, 4, 2, ox, oy, BK, flip)

func _side_pants(ox: int, oy: int, flip: bool) -> void:
	var front_x := 11 if _step == 0 else 9
	var back_x  := 9  if _step == 0 else 11
	# Kaki belakang (lebih gelap)
	_fblk(back_x, 26, 7, 3, ox, oy, PN_D, flip)
	# Kaki depan
	_fblk(front_x, 26, 8, 3, ox, oy, PN_M, flip)
	for y in range(26, 29):
		_fpx(front_x, y, ox, oy, PN_H, flip)
		_fpx(front_x+7, y, ox, oy, PN_D, flip)

func _side_boots(ox: int, oy: int, flip: bool) -> void:
	var front_x := 11 if _step == 0 else 9
	var back_x  := 9  if _step == 0 else 11
	# Boot belakang
	_fblk(back_x, 29, 7, 3, ox, oy, BT_D, flip)
	_frow(back_x, back_x+6, 31, ox, oy, SL, flip)
	# Boot depan
	_fblk(front_x, 29, 8, 3, ox, oy, BT_M, flip)
	for y in range(29, 32):
		_fpx(front_x, y, ox, oy, BT_H, flip)
		_fpx(front_x+7, y, ox, oy, BT_D, flip)
	_frow(front_x, front_x+7, 31, ox, oy, SL, flip)
	_fpx(front_x+1, 30, ox, oy, BT_H, flip)
