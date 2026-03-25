extends Node2D

var xp_value: float = 20.0
var player: Node = null
var speed: float = 0.0
var bob_timer: float = 0.0
var color: Color = Color(0.2, 1.0, 0.45)

func _ready():
	bob_timer = randf() * TAU

func _draw():
	var pulse = sin(bob_timer) * 0.22 + 0.85
	var r = 7.0 * pulse
	draw_circle(Vector2.ZERO, r, color)
	draw_circle(Vector2.ZERO, r * 0.42, Color(1.0, 1.0, 1.0, 0.75))

func _process(delta: float):
	bob_timer += delta * 5.0
	queue_redraw()
	if not is_instance_valid(player):
		return
	var magnet_active = player.boost_magnet_timer > 0.0
	var attract_range = 650.0 if magnet_active else 190.0
	var diff = player.global_position - global_position
	var dist = diff.length()
	if dist < attract_range:
		var accel = 1800.0 if magnet_active else 900.0
		speed = min(speed + accel * delta, 480.0)
		global_position += diff.normalized() * speed * delta
		if dist < 20.0:
			player.gain_xp(xp_value)
			queue_free()
	else:
		speed = max(speed - 300.0 * delta, 0.0)
