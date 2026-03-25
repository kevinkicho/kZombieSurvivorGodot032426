extends Node2D

signal collected(type: String, pos: Vector2)

var type: String = "speed"
var player: Node = null
var lifetime: float = 12.0
var bob_timer: float = 0.0
var _done: bool = false

func _ready():
	bob_timer = randf() * TAU

func _process(delta: float):
	if _done: return
	lifetime -= delta
	bob_timer += delta * 3.0
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()
		return
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 28.0:
		_collect()

func _collect():
	_done = true
	match type:
		"speed":  player.boost_speed_timer  = 10.0
		"damage": player.boost_damage_timer = 10.0
		"shield": player.boost_shield_timer = 1.0   # absorbs next hit
		"magnet": player.boost_magnet_timer = 10.0
	collected.emit(type, global_position)
	queue_free()

func _draw():
	if _done: return
	var pulse = sin(bob_timer) * 0.22 + 0.88
	var fade  = clamp(lifetime / 4.0, 0.25, 1.0)
	var r     = 13.0 * pulse
	var col: Color
	match type:
		"speed":  col = Color(0.15, 0.88, 1.0,  fade)
		"damage": col = Color(1.0,  0.35, 0.10, fade)
		"shield": col = Color(0.85, 1.0,  0.25, fade)
		"magnet": col = Color(0.88, 0.18, 0.95, fade)
		_:        col = Color(1.0,  1.0,  1.0,  fade)
	draw_circle(Vector2.ZERO, r, col)
	draw_circle(Vector2.ZERO, r * 0.42, Color(1.0, 1.0, 1.0, fade * 0.65))
	draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, fade * 0.45), 2.0)
	# Spin indicator lines
	for i in range(4):
		var a = bob_timer * 1.2 + (TAU / 4.0) * i
		var tip = Vector2(cos(a), sin(a)) * (r + 8.0)
		draw_line(Vector2(cos(a), sin(a)) * (r + 2.0), tip, Color(col.r, col.g, col.b, fade * 0.7), 2.0)
