# shop_dialog.gd — Panel toko: beli benih, jual hasil panen.
# Di-attach ke Panel node di CanvasLayer. Dipanggil oleh world_manager.gd.
extends Panel

signal closed

var _lbl_money  : Label
var _lbl_seeds  : Label
var _lbl_harvest: Label
var _lbl_status : Label
var _status_timer : float = 0.0

func _ready() -> void:
	visible = false
	_build_ui()
	GameState.inventory_changed.connect(_refresh)

func _build_ui() -> void:
	var vp   := get_viewport().get_visible_rect().size
	var pw   : float = min(520.0, vp.x - 48)
	var ph   : float = 340.0
	size      = Vector2(pw, ph)
	position  = Vector2((vp.x - pw) / 2.0, (vp.y - ph) / 2.0)

	# Latar panel
	var style := StyleBoxFlat.new()
	style.bg_color       = Color(0.10, 0.14, 0.10)
	style.border_color   = Color(0.38, 0.62, 0.28)
	style.border_width_bottom = 3; style.border_width_top    = 3
	style.border_width_left   = 3; style.border_width_right  = 3
	style.corner_radius_top_left     = 12; style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12; style.corner_radius_bottom_right = 12
	add_theme_stylebox_override("panel", style)

	var bw : float = (pw - 60.0) / 2.0  # lebar tombol

	# Judul
	_add_label("TOKO BENIH", 0, 14, pw, 36, 26, Color(0.95, 0.85, 0.25), true)

	# Info inventori
	_lbl_money   = _add_label("", 0, 58, pw, 28, 20, Color(0.85, 0.85, 0.30))
	_lbl_seeds   = _add_label("", 0, 86, pw, 28, 20, Color(0.55, 0.90, 0.42))
	_lbl_harvest = _add_label("", 0, 114, pw, 28, 20, Color(0.90, 0.78, 0.30))

	# Tombol Beli Benih
	var btn_beli := _buat_tombol(
		"Beli 5 Benih  (-$%d)" % GameState.SEED_PACK_PRICE,
		Vector2(20, 158), Vector2(bw, 64), Color(0.18, 0.50, 0.22))
	btn_beli.pressed.connect(_on_beli_pressed)
	add_child(btn_beli)

	# Tombol Jual Panen
	var btn_jual := _buat_tombol(
		"Jual 1 Gandum  (+$%d)" % GameState.HARVEST_SELL_PRICE,
		Vector2(40 + bw, 158), Vector2(bw, 64), Color(0.50, 0.38, 0.10))
	btn_jual.pressed.connect(_on_jual_pressed)
	add_child(btn_jual)

	# Status feedback
	_lbl_status = _add_label("", 0, 234, pw, 28, 17, Color(0.90, 0.90, 0.90))

	# Tombol tutup
	var btn_close := _buat_tombol("Tutup", Vector2((pw - 140) / 2.0, 272), Vector2(140, 52),
		Color(0.55, 0.18, 0.12))
	btn_close.pressed.connect(_on_close_pressed)
	add_child(btn_close)

	_refresh()

func _add_label(txt: String, x: float, y: float, w: float, h: float,
		fs: int, c: Color, bold: bool = false) -> Label:
	var lbl                 := Label.new()
	lbl.text                 = txt
	lbl.position             = Vector2(x, y)
	lbl.size                 = Vector2(w, h)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fs)
	lbl.add_theme_color_override("font_color", c)
	add_child(lbl)
	return lbl

func _buat_tombol(txt: String, pos: Vector2, sz: Vector2, bg: Color) -> Button:
	var btn                  := Button.new()
	btn.text                  = txt
	btn.position              = pos
	btn.size                  = sz
	btn.add_theme_font_size_override("font_size", 18)
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.corner_radius_top_left = 8; s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", s)
	return btn

func _process(delta: float) -> void:
	if not visible:
		return
	if _status_timer > 0:
		_status_timer -= delta
		if _status_timer <= 0 and _lbl_status:
			_lbl_status.text = ""

func _on_beli_pressed() -> void:
	if GameState.money >= GameState.SEED_PACK_PRICE:
		GameState.money  -= GameState.SEED_PACK_PRICE
		GameState.seeds  += GameState.SEEDS_PER_PACK
		GameState.inventory_changed.emit()
		_set_status("+%d benih dibeli!" % GameState.SEEDS_PER_PACK, Color(0.5, 1.0, 0.5))
	else:
		_set_status("Uang tidak cukup!", Color(1.0, 0.4, 0.4))

func _on_jual_pressed() -> void:
	if GameState.harvest > 0:
		GameState.harvest -= 1
		GameState.money   += GameState.HARVEST_SELL_PRICE
		GameState.inventory_changed.emit()
		_set_status("+$%d dari penjualan!" % GameState.HARVEST_SELL_PRICE, Color(1.0, 0.9, 0.3))
	else:
		_set_status("Tidak ada gandum untuk dijual!", Color(1.0, 0.4, 0.4))

func _on_close_pressed() -> void:
	visible = false
	closed.emit()

func _refresh() -> void:
	if _lbl_money:   _lbl_money.text   = "Uang: $%d" % GameState.money
	if _lbl_seeds:   _lbl_seeds.text   = "Benih: %d" % GameState.seeds
	if _lbl_harvest: _lbl_harvest.text = "Gandum: %d" % GameState.harvest

func _set_status(msg: String, c: Color) -> void:
	if _lbl_status:
		_lbl_status.text = msg
		_lbl_status.add_theme_color_override("font_color", c)
		_status_timer    = 2.5

func open() -> void:
	_refresh()
	visible = true
