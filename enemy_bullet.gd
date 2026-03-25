extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 230.0
var damage: float = 12.0
var lifetime: float = 3.5
var player_ref: Node = null
var _bob: float = 0.0

func _process(delta: float):
	_bob += delta * 9.0
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) < 18.0:
		player_ref.take_damage(damage)
		queue_free()
		return
	queue_redraw()

func _draw():
	var p = sin(_bob) * 0.18 + 0.9
	draw_circle(Vector2.ZERO, 5.5 * p, Color(0.15, 1.0, 0.3, 0.92))
	draw_circle(Vector2.ZERO, 2.8 * p, Color(0.8,  1.0, 0.8, 0.92))
	draw_line(Vector2.ZERO, -direction * 13.0, Color(0.15, 0.85, 0.25, 0.4), 3.0)
