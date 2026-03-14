extends Node2D

var crops = {}
var inventory = 0
var inventory_label: Label
var CropScene: PackedScene

@onready var player = $CharacterBody2D
@onready var crop_manager = $CropManager

const TILE_SIZE = 16

func _ready():
	CropScene = load("res://crop.tscn")
	call_deferred("setup_ui")

func setup_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var screen_size = get_viewport().get_visible_rect().size

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.position = Vector2(0, screen_size.y - 120)
	bg.size = Vector2(screen_size.x, 120)
	canvas.add_child(bg)

	inventory_label = Label.new()
	inventory_label.text = "Hasil Panen: 0"
	inventory_label.position = Vector2(0, screen_size.y - 115)
	inventory_label.size = Vector2(screen_size.x, 30)
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_label.add_theme_color_override("font_color", Color.WHITE)
	inventory_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(inventory_label)

	var btn_tanam = Button.new()
	btn_tanam.text = "Tanam"
	btn_tanam.position = Vector2(10, screen_size.y - 80)
	btn_tanam.size = Vector2(screen_size.x / 2 - 15, 70)
	btn_tanam.add_theme_font_size_override("font_size", 22)
	btn_tanam.pressed.connect(_on_tanam_pressed)
	canvas.add_child(btn_tanam)

	var btn_panen = Button.new()
	btn_panen.text = "Panen"
	btn_panen.position = Vector2(screen_size.x / 2 + 5, screen_size.y - 80)
	btn_panen.size = Vector2(screen_size.x / 2 - 15, 70)
	btn_panen.add_theme_font_size_override("font_size", 22)
	btn_panen.pressed.connect(_on_panen_pressed)
	canvas.add_child(btn_panen)

func _on_tanam_pressed():
	var tile_pos = get_player_tile()
	if not crops.has(tile_pos):
		var crop = CropScene.instantiate()
		crop.position = Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)
		crop.tile_pos = tile_pos
		crop_manager.add_child(crop)
		crops[tile_pos] = crop

func _on_panen_pressed():
	var tile_pos = get_player_tile()
	if crops.has(tile_pos):
		var crop = crops[tile_pos]
		if crop.is_ready_to_harvest():
			crop.harvest()
			crops.erase(tile_pos)
			inventory += 1
			update_ui()

func get_player_tile() -> Vector2i:
	var p = player.position
	return Vector2i(int(p.x / TILE_SIZE), int(p.y / TILE_SIZE))

func update_ui():
	if inventory_label:
		inventory_label.text = "Hasil Panen: " + str(inventory)
