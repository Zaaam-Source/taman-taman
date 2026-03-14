# floating_text.gd — Teks melayang saat panen
extends Node2D

const FLOAT_SPEED    := -70.0
const FLOAT_DURATION := 1.4

var _elapsed : float = 0.0
var _label   : Label

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size                 = Vector2(160, 48)
	_label.position             = Vector2(-80, -24)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.20))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)

func setup(msg: String) -> void:
	if _label:
		_label.text = msg

func _process(delta: float) -> void:
	_elapsed   += delta
	position.y += FLOAT_SPEED * delta
	modulate.a  = 1.0 - (_elapsed / FLOAT_DURATION)
	if _elapsed >= FLOAT_DURATION:
		queue_free()
