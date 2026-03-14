# npc.gd — NPC dengan patrol sederhana antara dua waypoint
# Pixel art 24×32 virtual px @ PS=2 = 48×64 on screen
extends Node2D

enum NpcType { FARMER, WOMAN, MERCHANT, CHILD, GUARD }

const SPEED_DEFAULT := 65.0
const SPEED_CHILD   := 95.0
const ARRIVE_DIST   := 12.0
const TS := GameState.TILE_SIZE
const PS := 2

var npc_type    : NpcType = NpcType.FARMER
var waypoint_a  : Vector2 = Vector2.ZERO
var waypoint_b  : Vector2 = Vector2.ZERO

var _target     : Vector2 = Vector2.ZERO
var _going_b    : bool    = true
var _facing_r   : bool    = true
var _step       : int     = 0
var _anim_t     : float   = 0.0
var _idle_t     : float   = 0.0
var _idle_bob   : float   = 0.0
var _speed      : float   = SPEED_DEFAULT
var _paused     : float   = 0.0   # detik jeda di waypoint

# ── Palet per tipe ────────────────────────────────────────────────────────────
# [body_h, body_m, body_d, hair, skin, pants, boots, accent]
const PALETTES : Array = [
	# FARMER — kemeja biru tua, overall coklat, topi jerami
	[Color(0.26,0.44,0.68), Color(0.18,0.32,0.52), Color(0.10,0.20,0.36),
	 Color(0.78,0.66,0.22), Color(0.95,0.78,0.60), Color(0.48,0.32,0.12), Color(0.28,0.16,0.04), Color(0.90,0.76,0.28)],
	# WOMAN — gaun merah muda, rambut coklat gelap
	[Color(0.90,0.48,0.62), Color(0.74,0.30,0.46), Color(0.54,0.18,0.32),
	 Color(0.36,0.20,0.08), Color(0.97,0.82,0.66), Color(0.86,0.44,0.58), Color(0.54,0.26,0.36), Color(1.00,0.78,0.88)],
	# MERCHANT — jubah ungu, rambut abu
	[Color(0.52,0.20,0.68), Color(0.38,0.12,0.52), Color(0.24,0.06,0.36),
	 Color(0.62,0.60,0.62), Color(0.92,0.76,0.58), Color(0.44,0.16,0.58), Color(0.24,0.10,0.36), Color(0.86,0.70,0.16)],
	# CHILD — baju hijau, rambut pirang
	[Color(0.26,0.66,0.28), Color(0.18,0.50,0.20), Color(0.10,0.34,0.12),
	 Color(0.90,0.78,0.28), Color(0.98,0.84,0.66), Color(0.26,0.38,0.72), Color(0.18,0.26,0.52), Color(0.98,0.88,0.40)],
	# GUARD — zirah abu, helm, rambut hitam
	[Color(0.60,0.60,0.64), Color(0.42,0.42,0.46), Color(0.26,0.26,0.30),
	 Color(0.16,0.12,0.10), Color(0.88,0.72,0.54), Color(0.34,0.34,0.38), Color(0.18,0.18,0.22), Color(0.80,0.14,0.12)],
]

# Shorthand palette vars (set di _ready)
var _bh : Color; var _bm : Color; var _bd : Color
var _hr : Color; var _sk : Color; var _pn : Color
var _bt : Color; var _ac : Color
# Shared colors
const _ey := Color(0.10,0.08,0.06)
const _ew := Color(0.96,0.96,0.96)
const _ck := Color(1.00,0.70,0.66,0.50)
const _OUT := Color(0.06,0.04,0.02,0.70)
const _SHD := Color(0.0,0.0,0.0,0.16)

func setup(type: NpcType, wa: Vector2, wb: Vector2) -> void:
	npc_type   = type
	waypoint_a = wa
	waypoint_b = wb
	position   = wa
	_target    = wb
	_speed     = SPEED_CHILD if type == NpcType.CHILD else SPEED_DEFAULT

func _ready() -> void:
	var p : Array = PALETTES[int(npc_type)]
	_bh = p[0]; _bm = p[1]; _bd = p[2]
	_hr = p[3]; _sk = p[4]; _pn = p[5]; _bt = p[6]; _ac = p[7]
	if _target == Vector2.ZERO:
		_target = waypoint_b

func _process(delta: float) -> void:
	_idle_t += delta
	_idle_bob = sin(_idle_t * 2.2) * 1.5

	if _paused > 0:
		_paused -= delta
		return

	var diff  := _target - position
	var dist  := diff.length()

	if dist < ARRIVE_DIST:
		# Sampai di waypoint — jeda sebentar lalu balik
		_going_b = not _going_b
		_target  = waypoint_b if _going_b else waypoint_a
		_paused  = 0.8 + randf() * 1.2
		_step    = 0
		queue_redraw()
		return

	var dir := diff.normalized()
	_facing_r = dir.x >= 0

	_anim_t += delta
	if _anim_t >= 0.18:
		_anim_t = 0.0
		_step   = 1 - _step
		queue_redraw()

	var new_pos := position + dir * _speed * delta
	# Cek walkability sebelum pindah
	if _can_move(new_pos):
		position = new_pos
	else:
		# Coba sliding horizontal
		if _can_move(Vector2(new_pos.x, position.y)):
			position.x = new_pos.x
		elif _can_move(Vector2(position.x, new_pos.y)):
			position.y = new_pos.y
		else:
			# Balik arah
			var tmp := waypoint_a
			waypoint_a = waypoint_b
			waypoint_b = tmp
			_target = waypoint_b if _going_b else waypoint_a

func _can_move(pos: Vector2) -> bool:
	for p in [pos + Vector2(-8, 4), pos + Vector2(8, 4)]:
		var t := Vector2i(int(p.x / TS), int(p.y / TS))
		if not GameState.is_walkable(t): return false
	return true

# ── Draw ──────────────────────────────────────────────────────────────────────
# Grid 24×32 vp (origin = center kaki), PS=2 → 48×64 px layar
# ox = -12*PS, oy = -32*PS

func _draw() -> void:
	var ox := -12 * PS
	var oy := -32 * PS + int(_idle_bob) if _paused > 0 else -32 * PS

	# Ground shadow
	draw_rect(Rect2(ox + 3*PS, oy + 31*PS, 18*PS, 2*PS), _SHD)

	if _facing_r:
		_draw_body(ox, oy, false)
	else:
		_draw_body(ox, oy, true)

func _px(x:int, y:int, ox:int, oy:int, c:Color) -> void:
	draw_rect(Rect2(ox + x*PS, oy + y*PS, PS, PS), c)

func _row(x0:int, x1:int, y:int, ox:int, oy:int, c:Color) -> void:
	draw_rect(Rect2(ox + x0*PS, oy + y*PS, (x1-x0+1)*PS, PS), c)

func _blk(x:int, y:int, w:int, h:int, ox:int, oy:int, c:Color) -> void:
	draw_rect(Rect2(ox + x*PS, oy + y*PS, w*PS, h*PS), c)

func _fp(x:int, y:int, ox:int, oy:int, c:Color, flip:bool) -> void:
	if flip: _px(23-x, y, ox, oy, c)
	else:    _px(x, y, ox, oy, c)

func _fr(x0:int, x1:int, y:int, ox:int, oy:int, c:Color, flip:bool) -> void:
	if flip: _row(23-x1, 23-x0, y, ox, oy, c)
	else:    _row(x0, x1, y, ox, oy, c)

func _fb(x:int, y:int, w:int, h:int, ox:int, oy:int, c:Color, flip:bool) -> void:
	if flip: _blk(23-x-w+1, y, w, h, ox, oy, c)
	else:    _blk(x, y, w, h, ox, oy, c)

func _draw_body(ox:int, oy:int, flip:bool) -> void:
	# Boots / kaki
	var ll := 5; var rl := 13
	if _step == 1: ll = 4; rl = 14
	_fb(ll, 26, 6, 6, ox, oy, _bt, flip)
	for y in range(26,32):
		_fp(ll, y, ox, oy, _bt.lightened(0.2), flip)
		_fp(ll+5, y, ox, oy, _bt.darkened(0.2), flip)
	_fr(ll, ll+5, 31, ox, oy, Color(0.05,0.03,0.01), flip)
	_fb(rl, 26, 5, 6, ox, oy, _bt, flip)
	for y in range(26,32):
		_fp(rl, y, ox, oy, _bt.darkened(0.2), flip)
		_fp(rl+4, y, ox, oy, _bt.lightened(0.2), flip)
	_fr(rl, rl+4, 31, ox, oy, Color(0.05,0.03,0.01), flip)

	# Celana
	_fb(5, 22, 6, 4, ox, oy, _pn, flip)
	_fb(13, 22, 5, 4, ox, oy, _pn, flip)
	for y in range(22,26):
		_fp(5, y, ox, oy, _pn.lightened(0.15), flip)
		_fp(10, y, ox, oy, _pn.darkened(0.15), flip)

	# Badan (kemeja)
	_blk(4, 15, 16, 7, ox, oy, _bm)
	_blk(6, 15, 10, 5, ox, oy, _bh)
	for y in range(15,22):
		_blk(4, y, 2, 1, ox, oy, _bd)
		_blk(18, y, 2, 1, ox, oy, _bd)
	# Belt tipis
	_row(4, 19, 21, ox, oy, Color(0.20,0.14,0.06))
	_px(11, 21, ox, oy, _ac)

	# Lengan
	var ay := 16 if _step == 0 else 15
	# Kiri
	_fb(2, ay, 3, 5, ox, oy, _bm, flip)
	_fp(2, ay, ox, oy, _bh, flip)
	_fb(2, ay+4, 3, 2, ox, oy, _sk, flip)
	_fp(2, ay+4, ox, oy, _sk.lightened(0.1), flip)
	# Kanan
	_fb(19, ay, 3, 5, ox, oy, _bm, flip)
	_fp(21, ay, ox, oy, _bh, flip)
	_fb(19, ay+4, 3, 2, ox, oy, _sk, flip)
	_fp(21, ay+4, ox, oy, _sk.lightened(0.1), flip)

	# Leher + kepala
	_blk(9, 12, 6, 3, ox, oy, _sk)

	# Kepala — bentuk lebih bulat
	_blk(5, 2, 14, 10, ox, oy, _sk)
	_row(7, 16, 1, ox, oy, _sk)
	_row(7, 16, 12, ox, oy, _sk)
	_row(6, 17, 2, ox, oy, _sk)
	_row(6, 17, 11, ox, oy, _sk)
	# Highlight pipi & dahi
	_blk(8, 3, 8, 4, ox, oy, _sk.lightened(0.08))
	# Shadow bawah kepala
	_row(6, 17, 11, ox, oy, _sk.darkened(0.10))
	# Shadow sisi
	for y in range(2,12):
		_px(5, y, ox, oy, _sk.darkened(0.08))
		_px(18, y, ox, oy, _sk.darkened(0.08))

	# Pipi
	_blk(6, 7, 3, 2, ox, oy, _ck)
	_blk(15, 7, 3, 2, ox, oy, _ck)

	# Mata kiri
	_blk(7, 4, 4, 3, ox, oy, _ey)
	_blk(8, 5, 2, 2, ox, oy, _ew)
	_px(8, 5, ox, oy, _ey.lightened(0.3))
	_px(9, 5, ox, oy, Color(0.24,0.52,0.88))
	_px(9, 6, ox, oy, _ey)
	_px(8, 6, ox, oy, _ew)
	# Mata kanan
	_blk(13, 4, 4, 3, ox, oy, _ey)
	_blk(14, 5, 2, 2, ox, oy, _ew)
	_px(14, 5, ox, oy, _ey.lightened(0.3))
	_px(15, 5, ox, oy, Color(0.24,0.52,0.88))
	_px(15, 6, ox, oy, _ey)
	_px(14, 6, ox, oy, _ew)
	# Hidung
	_px(11, 8, ox, oy, _sk.darkened(0.15))
	_px(12, 8, ox, oy, _sk.darkened(0.15))
	# Mulut
	_row(10, 13, 10, ox, oy, _sk.darkened(0.18))
	_row(11, 13, 10, ox, oy, Color(0.80,0.36,0.30))

	# ── Rambut / aksesoris per tipe ──────────────────────────────────────────
	match npc_type:
		NpcType.FARMER:
			# Topi jerami
			_blk(4, 0, 16, 3, ox, oy, _ac)
			_blk(3, 1, 18, 2, ox, oy, _ac.lightened(0.1))
			_row(4, 19, 0, ox, oy, _ac.darkened(0.1))
			_blk(6, 0, 12, 2, ox, oy, _hr)
			_row(7, 16, 2, ox, oy, _hr.darkened(0.1))
			# Pita topi
			_row(4, 19, 2, ox, oy, _ac.darkened(0.2))
		NpcType.WOMAN:
			# Rambut panjang di sisi
			_blk(5, 0, 14, 5, ox, oy, _hr)
			_row(6, 17, 0, ox, oy, _hr.darkened(0.1))
			_row(7, 16, 1, ox, oy, _hr.lightened(0.15))
			for y in range(5,14):
				_px(5, y, ox, oy, _hr); _px(6, y, ox, oy, _hr)
				_px(17, y, ox, oy, _hr); _px(18, y, ox, oy, _hr)
			# Pita rambut
			_row(8, 15, 3, ox, oy, _ac)
		NpcType.MERCHANT:
			# Topi runcing
			_blk(8, 0, 8, 2, ox, oy, _bd)
			_blk(9, -2, 6, 2, ox, oy, _bd)
			_px(11, -3, ox, oy, _bd)
			_blk(6, 0, 12, 3, ox, oy, _bm)
			_row(5, 18, 2, ox, oy, _bm.darkened(0.1))
			# Rambut keluar sisi
			for y in range(3,7):
				_px(5, y, ox, oy, _hr)
				_px(18, y, ox, oy, _hr)
			# Aksen emas
			_px(12, 0, ox, oy, _ac); _px(11, -2, ox, oy, _ac)
		NpcType.CHILD:
			# Rambut berantakan
			_blk(5, 0, 14, 5, ox, oy, _hr)
			_row(6, 17, 0, ox, oy, _hr.darkened(0.1))
			# Cowlick
			_px(10, 0, ox, oy, _hr.lightened(0.2))
			_px(11, -1, ox, oy, _hr.lightened(0.1))
			_px(13, 0, ox, oy, _hr.lightened(0.2))
			_row(7, 16, 1, ox, oy, _hr.lightened(0.1))
			# Sisi rambut
			for y in range(4,9):
				_px(5, y, ox, oy, _hr)
				_px(18, y, ox, oy, _hr)
		NpcType.GUARD:
			# Helm
			_blk(5, -1, 14, 6, ox, oy, _bm)
			_row(6, 17, -1, ox, oy, _bd)
			_row(5, 18, 4, ox, oy, _bd)
			# Pengganjal helm di depan
			_blk(6, 4, 12, 2, ox, oy, _bm.darkened(0.1))
			# Bulu plume merah
			for y in range(-4, 0):
				_px(12, y, ox, oy, _ac)
				_px(11, y+1, ox, oy, _ac.lightened(0.1))
			# Highlight helm
			_row(7, 11, 0, ox, oy, _bm.lightened(0.15))
