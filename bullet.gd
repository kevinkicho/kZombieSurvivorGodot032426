extends Area2D

const ParticleScript = preload("res://particle.gd")

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 25.0
var lifetime: float = 2.0
var piercing: bool = false
var is_crit: bool = false
var is_explosive: bool = false
var aoe_radius: float = 82.0
var homing_target: Node = null
var enemies_node: Node2D = null
var effects_node: Node2D = null
var _hit_ids: Array = []

func _ready():
	collision_layer = 4
	collision_mask = 2
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_hit)

func _draw():
	var col = Color(1.0, 0.28, 0.18) if is_crit else Color(1.0, 0.95, 0.25)
	var sz  = 8.5 if is_crit else 6.0
	draw_circle(Vector2.ZERO, sz, col)
	draw_arc(Vector2.ZERO, sz, 0.0, TAU, 12, Color(1.0, 0.6, 0.1), 1.5)
	draw_line(Vector2.ZERO, -direction * 15.0, Color(col.r, col.g, col.b, 0.38), 4.0)
	if is_explosive:
		draw_arc(Vector2.ZERO, sz + 4.0, 0.0, TAU, 12, Color(1.0, 0.55, 0.0, 0.5), 2.0)

func _process(delta: float):
	# Gentle homing
	if is_instance_valid(homing_target):
		var toward = (homing_target.global_position - global_position).normalized()
		direction = direction.lerp(toward, 5.0 * delta).normalized()

	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_hit(body: Node) -> void:
	var id = body.get_instance_id()
	if id in _hit_ids:
		return
	_hit_ids.append(id)
	if body.has_method("take_damage"):
		body.take_damage(damage, is_crit)
	if is_explosive:
		_do_explosion()
		return
	if not piercing:
		queue_free()

func _do_explosion():
	if is_instance_valid(enemies_node):
		for e in enemies_node.get_children():
			var eid = e.get_instance_id()
			if is_instance_valid(e) and eid not in _hit_ids and \
					e.zombie_type != "exploder" and \
					e.global_position.distance_to(global_position) < aoe_radius:
				e.take_damage(damage * 0.55)
	if is_instance_valid(effects_node):
		for i in range(12):
			var p = ParticleScript.new()
			p.vel = Vector2.from_angle(randf() * TAU) * randf_range(80, 220)
			p.life = randf_range(0.28, 0.58)
			p.init_life = p.life
			p.size = randf_range(6, 16)
			p.color = Color(1.0, randf_range(0.4, 0.85), 0.05)
			p.global_position = global_position
			effects_node.add_child(p)
	queue_free()
