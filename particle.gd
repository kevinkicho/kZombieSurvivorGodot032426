extends Node2D

var vel: Vector2 = Vector2.ZERO
var life: float = 0.6
var init_life: float = 0.6
var size: float = 8.0
var color: Color = Color.WHITE

func _process(delta: float):
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	position += vel * delta
	vel *= 0.88
	vel.y += 55.0 * delta
	queue_redraw()

func _draw():
	var alpha = clamp(life / init_life, 0.0, 1.0)
	var half = size * 0.5
	draw_rect(Rect2(-half, -half, size, size), Color(color.r, color.g, color.b, alpha))
