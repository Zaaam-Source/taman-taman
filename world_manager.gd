# world_manager.gd — Root scene. Semua sistem: HUD, tanam/panen, transisi, toko, NPC.
extends Node2D

@onready var _player         : CharacterBody2D = $CharacterBody2D
@onready var _crop_manager   : Node2D          = $CropManager
@onready var _world_renderer : Node2D          = $WorldRenderer
@onready var _interior_root  : Node2D          = $InteriorRoot
@onready var _dn_overlay     : ColorRect       = $UILayer/DayNight
@onready var _shop_dialog    : Panel           = $UILayer/ShopDialog
@onready var _camera         : Camera2D        = $CharacterBody2D/Camera2D

var _lbl_day    : Label
var _lbl_time   : Label
var _lbl_inv    : Label
var _lbl_status : Label
var _status_t   : float = 0.0

var _crop_scene  : PackedScene
var _float_scene : PackedScene
var _npc_scene   : GDScript

var _crops : Dictionary = {}

var _interact_cooldown : float = 0.0
const COOLDOWN_SEC := 1.2

# NPC manager node
var _npc_root : Node2D

func _ready() -> void:
	_crop_scene  = load("res://crop.tscn")
	_float_scene = load("res://floating_text.tscn")
	_npc_scene   = load("res://npc.gd")

	_camera.limit_left   = 0
	_camera.limit_top    = 0
	_camera.limit_right  = GameState.MAP_COLS * GameState.TILE_SIZE
	_camera.limit_bottom = GameState.MAP_ROWS * GameState.TILE_SIZE

	_setup_hud()

	_dn_overlay.day_changed.connect(_on_day_changed)
	_dn_overlay.hour_changed.connect(_on_hour_changed)

	var save_data := GameState.load_save()
	if save_data.has("crops"):
		_restore_crops(save_data["crops"])

	# Spawn NPC — harus sebelum _set_exterior_mode() karena fungsi itu akses _npc_root
	_npc_root = Node2D.new()
	_npc_root.name = "NpcRoot"
	add_child(_npc_root)
	_spawn_npcs()

	_set_exterior_mode()
	_player.position = Vector2(
		2 * GameState.TILE_SIZE + GameState.TILE_SIZE / 2.0,
		5 * GameState.TILE_SIZE + GameState.TILE_SIZE / 2.0
	)

	GameState.inventory_changed.connect(_refresh_inv)
	_refresh_inv()

func _process(delta: float) -> void:
	_interact_cooldown -= delta
	if _status_t > 0:
		_status_t -= delta
		if _status_t <= 0 and _lbl_status:
			_lbl_status.text = ""

	if _shop_dialog.visible or _interact_cooldown > 0:
		return

	var tile := _tile_pemain()

	if not GameState.in_interior:
		match GameState.tile_at(tile):
			GameState.TILE_DOOR:  _enter_house()
			GameState.TILE_SHOP:  _open_shop()
	else:
		if GameState.int_tile_at(tile) == GameState.TILE_EXIT:
			_exit_house()

# ── Tombol aksi ───────────────────────────────────────────────────────────────
func _on_tanam_pressed() -> void:
	if GameState.in_interior: return
	if GameState.seeds <= 0:
		_status("Tidak ada benih! Beli di toko.", Color(1.0, 0.5, 0.3))
		return
	var tile := _tile_pemain()
	if not GameState.is_plantable(tile):
		_status("Tanam hanya di area kebun!", Color(1.0, 0.7, 0.3))
		return
	if _crops.has(tile):
		_status("Sudah ada tanaman di sini.", Color(1.0, 0.6, 0.3))
		return

	var crop       := _crop_scene.instantiate() as Node2D
	crop.position   = GameState.tile_center(tile)
	crop.tile_pos   = tile
	_crop_manager.add_child(crop)
	_crops[tile]    = crop
	GameState.seeds -= 1
	GameState.inventory_changed.emit()
	_status("Benih ditanam! (%d tersisa)" % GameState.seeds, Color(0.5, 1.0, 0.4))

func _on_panen_pressed() -> void:
	if GameState.in_interior: return
	var tile := _tile_pemain()
	if not _crops.has(tile):
		_status("Tidak ada tanaman di sini.", Color(1.0, 0.7, 0.3))
		return
	var crop : Node2D = _crops[tile]
	if not crop.is_ready_to_harvest():
		_status("Tanaman belum matang.", Color(1.0, 0.85, 0.2))
		return
	var wpos := crop.global_position
	crop.harvest()
	_crops.erase(tile)
	GameState.harvest += 1
	GameState.inventory_changed.emit()
	_spawn_float("+1 Gandum!", wpos)
	_status("Panen berhasil! Total: %d" % GameState.harvest, Color(0.4, 1.0, 0.6))
	_auto_save()

func _on_save_pressed() -> void:
	_auto_save()
	_status("Game tersimpan!", Color(0.5, 0.9, 1.0))

# ── Transisi exterior ↔ interior ─────────────────────────────────────────────
func _enter_house() -> void:
	_interact_cooldown = COOLDOWN_SEC
	GameState.in_interior = true
	_set_interior_mode()

func _exit_house() -> void:
	_interact_cooldown = COOLDOWN_SEC
	GameState.in_interior = false
	_set_exterior_mode()
	_player.position = Vector2(
		2 * GameState.TILE_SIZE + GameState.TILE_SIZE / 2.0,
		5 * GameState.TILE_SIZE + GameState.TILE_SIZE / 2.0
	)

func _set_exterior_mode() -> void:
	_world_renderer.visible = true
	_crop_manager.visible   = true
	_interior_root.visible  = false
	_npc_root.visible       = true
	_camera.limit_left      = 0
	_camera.limit_top       = 0
	_camera.limit_right     = GameState.MAP_COLS * GameState.TILE_SIZE
	_camera.limit_bottom    = GameState.MAP_ROWS * GameState.TILE_SIZE

func _set_interior_mode() -> void:
	_world_renderer.visible = false
	_crop_manager.visible   = false
	_interior_root.visible  = true
	_npc_root.visible       = false
	_player.position = Vector2(
		GameState.INT_OFFSET_X + 5 * GameState.TILE_SIZE + GameState.TILE_SIZE / 2.0,
		GameState.INT_OFFSET_Y + 6 * GameState.TILE_SIZE + GameState.TILE_SIZE / 2.0
	)
	# Lock kamera di tengah interior
	var cx := GameState.INT_OFFSET_X + GameState.INT_COLS * GameState.TILE_SIZE / 2
	var cy := GameState.INT_OFFSET_Y + GameState.INT_ROWS * GameState.TILE_SIZE / 2
	_camera.limit_left   = cx - 1; _camera.limit_right  = cx + 1
	_camera.limit_top    = cy - 1; _camera.limit_bottom = cy + 1

# ── Toko ──────────────────────────────────────────────────────────────────────
func _open_shop() -> void:
	_interact_cooldown = COOLDOWN_SEC
	_shop_dialog.open()

# ── NPC ───────────────────────────────────────────────────────────────────────
func _spawn_npcs() -> void:
	const T := GameState.TILE_SIZE
	# [type, wa_col, wa_row, wb_col, wb_row]
	var configs : Array = [
		# Petani — patroli di tengah kebun utama
		[0,  5,  7,  15,  7],
		# Wanita desa — jalan di taman kota (row 11-12)
		[1,  2, 11,  28, 11],
		# Pedagang — dekat toko
		[2, 25,  5,  37,  5],
		# Anak — area taman tengah (row 12)
		[3, 18, 12,  24, 12],
		# Penjaga — patroli di jalan utama (row 10)
		[4,  5, 10,  35, 10],
		# NPC tambahan di area bawah (row 19)
		[1, 10, 19,  25, 19],
	]
	for cfg in configs:
		var npc    := Node2D.new()
		npc.set_script(_npc_scene)
		var wa := Vector2(cfg[1] * T + T/2.0, cfg[2] * T + T/2.0)
		var wb := Vector2(cfg[3] * T + T/2.0, cfg[4] * T + T/2.0)
		npc.call("setup", cfg[0], wa, wb)
		_npc_root.add_child(npc)

# ── Save / restore ────────────────────────────────────────────────────────────
func _auto_save() -> void:
	var crop_data : Array = []
	for tile in _crops:
		crop_data.append(_crops[tile].get_save_data())
	GameState.save(crop_data)

func _restore_crops(data: Array) -> void:
	for d in data:
		var tile := Vector2i(int(d["tx"]), int(d["ty"]))
		var crop       := _crop_scene.instantiate() as Node2D
		crop.position   = GameState.tile_center(tile)
		crop.tile_pos   = tile
		crop.stage      = int(d.get("stage", 0))
		crop.timer      = float(d.get("timer", 0.0))
		_crop_manager.add_child(crop)
		_crops[tile]    = crop
		crop.queue_redraw()

# ── Helpers ───────────────────────────────────────────────────────────────────
func _tile_pemain() -> Vector2i:
	if GameState.in_interior:
		return GameState.world_to_interior_tile(_player.global_position)
	return GameState.world_to_tile(_player.global_position)

func _spawn_float(msg: String, wpos: Vector2) -> void:
	var ft := _float_scene.instantiate() as Node2D
	ft.global_position = wpos + Vector2(0, -28)
	add_child(ft)
	ft.setup(msg)

func _status(msg: String, c: Color = Color.WHITE) -> void:
	if _lbl_status:
		_lbl_status.text = msg
		_lbl_status.add_theme_color_override("font_color", c)
		_status_t = 2.5

func _on_day_changed(d: int) -> void:
	if _lbl_day:  _lbl_day.text  = "Hari %d" % d

func _on_hour_changed(h: float) -> void:
	if _lbl_time:
		var hi := int(h); var mi := int((h - hi) * 60)
		_lbl_time.text = "%02d:%02d" % [hi, mi]

func _refresh_inv() -> void:
	if _lbl_inv:
		_lbl_inv.text = "$%d  |  Benih:%d  |  Gandum:%d" % [
			GameState.money, GameState.seeds, GameState.harvest]

# ── HUD ───────────────────────────────────────────────────────────────────────
func _setup_hud() -> void:
	var ui  := $UILayer as CanvasLayer
	var vp  := get_viewport().get_visible_rect().size
	var bw  := (vp.x - 40.0) / 3.0
	var by  := vp.y - 90.0

	var bg      := ColorRect.new()
	bg.color     = Color(0.04, 0.06, 0.04, 0.85)
	bg.position  = Vector2(0, vp.y - 140)
	bg.size      = Vector2(vp.x, 140)
	ui.add_child(bg)

	var top_bg      := ColorRect.new()
	top_bg.color     = Color(0.04, 0.06, 0.04, 0.75)
	top_bg.position  = Vector2(0, 0)
	top_bg.size      = Vector2(240, 60)
	ui.add_child(top_bg)

	_lbl_day  = _lbl("Hari 1",  10,  8, 220, 24, 20, Color(0.95, 0.85, 0.30))
	_lbl_time = _lbl("07:00",   10, 32, 220, 24, 20, Color(0.78, 0.90, 1.00))
	ui.add_child(_lbl_day)
	ui.add_child(_lbl_time)

	_lbl_inv = _lbl("", 250, 12, vp.x - 260, 36, 20, Color(0.90, 0.88, 0.50))
	_lbl_inv.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui.add_child(_lbl_inv)

	_lbl_status = _lbl("", 0, vp.y - 142, vp.x, 28, 18, Color.WHITE)
	ui.add_child(_lbl_status)

	var btn_tanam := _btn("Tanam",  Vector2(10,         by), Vector2(bw, 80), Color(0.18, 0.50, 0.20))
	var btn_panen := _btn("Panen",  Vector2(20 + bw,    by), Vector2(bw, 80), Color(0.55, 0.38, 0.08))
	var btn_save  := _btn("Simpan", Vector2(30 + bw*2,  by), Vector2(bw, 80), Color(0.18, 0.34, 0.58))
	btn_tanam.pressed.connect(_on_tanam_pressed)
	btn_panen.pressed.connect(_on_panen_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	ui.add_child(btn_tanam)
	ui.add_child(btn_panen)
	ui.add_child(btn_save)

func _lbl(txt:String, x:float, y:float, w:float, h:float, fs:int, c:Color) -> Label:
	var l := Label.new()
	l.text = txt; l.position = Vector2(x,y); l.size = Vector2(w,h)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", c)
	return l

func _btn(txt:String, pos:Vector2, sz:Vector2, bg:Color) -> Button:
	var b := Button.new()
	b.text = txt; b.position = pos; b.size = sz
	b.add_theme_font_size_override("font_size", 24)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left     = 10; s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10; s.corner_radius_bottom_right = 10
	b.add_theme_stylebox_override("normal",  s)
	b.add_theme_stylebox_override("pressed", s)
	b.add_theme_stylebox_override("hover",   s)
	return b
