# day_night.gd — Overlay siklus hari. Di-attach ke ColorRect fullscreen di CanvasLayer.
# Mengubah warna layar sesuai jam: pagi (oranye), siang (transparan), malam (biru gelap).
extends ColorRect

signal day_changed(day: int)
signal hour_changed(hour: float)

# Jam per detik dunia nyata
const REAL_SECONDS_PER_GAME_HOUR := 30.0   # 1 jam game = 30 detik nyata

# Warna langit per jam (key = jam 0–23)
const SKY_COLORS : Dictionary = {
	0:  Color(0.02, 0.02, 0.12, 0.75),  # tengah malam
	5:  Color(0.05, 0.04, 0.20, 0.65),  # sebelum subuh
	6:  Color(0.60, 0.28, 0.06, 0.45),  # fajar
	7:  Color(0.80, 0.45, 0.08, 0.20),  # pagi
	9:  Color(0.00, 0.00, 0.00, 0.00),  # siang (tidak ada overlay)
	17: Color(0.00, 0.00, 0.00, 0.00),  # sore cerah
	18: Color(0.70, 0.30, 0.05, 0.30),  # senja
	20: Color(0.10, 0.06, 0.25, 0.55),  # petang
	22: Color(0.02, 0.02, 0.15, 0.70),  # malam
}

var _sorted_keys : Array = []

func _ready() -> void:
	# Fullscreen overlay — pastikan size = viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0, 0, 0, 0)
	_sorted_keys = SKY_COLORS.keys()
	_sorted_keys.sort()
	_apply_hour(GameState.hour)

func _process(delta: float) -> void:
	GameState.hour += delta / REAL_SECONDS_PER_GAME_HOUR
	if GameState.hour >= 24.0:
		GameState.hour -= 24.0
		GameState.day  += 1
		day_changed.emit(GameState.day)
	_apply_hour(GameState.hour)
	hour_changed.emit(GameState.hour)

func _apply_hour(h: float) -> void:
	# Cari dua keyframe di sekitar jam h lalu lerp
	var prev_k : int = int(_sorted_keys[0])
	var next_k : int = int(_sorted_keys[_sorted_keys.size() - 1])
	for k in _sorted_keys:
		var ki : int = int(k)
		if ki <= h:
			prev_k = ki
		else:
			next_k = ki
			break
	if prev_k == next_k:
		color = SKY_COLORS[prev_k]
		return
	var t : float = (h - float(prev_k)) / float(next_k - prev_k)
	color = (SKY_COLORS[prev_k] as Color).lerp(SKY_COLORS[next_k] as Color, t)
