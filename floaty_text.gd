extends Node2D

var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 20
var lifetime: float = 1.1
var _age: float = 0.0
var _vel: Vector2

func _ready():
	_vel = Vector2(randf_range(-28.0, 28.0), -88.0)

func _draw():
	if not ThemeDB.fallback_font:
		return
	var alpha = clamp(1.0 - (_age / lifetime) * 1.25, 0.0, 1.0)
	var pop = 1.0 + max(0.0, 1.0 - _age * 9.0) * 0.45
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * pop)
	draw_string(ThemeDB.fallback_font, Vector2(-22, 0), text,
		HORIZONTAL_ALIGNMENT_CENTER, 44, font_size,
		Color(color.r, color.g, color.b, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _process(delta: float):
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	position += _vel * delta
	_vel.y += 55.0 * delta
	queue_redraw()
