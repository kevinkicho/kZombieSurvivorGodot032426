extends CharacterBody2D

signal died_at(pos: Vector2, xp_val: float)
signal damaged(amount: float, pos: Vector2, is_crit: bool)
signal exploded(pos: Vector2, radius: float, dmg: float)
signal fired_projectile(from_pos: Vector2, direction: Vector2, dmg: float)

var player: Node = null
var zombie_type: String = "normal"
var radius: float = 18.0
var body_color: Color = Color(0.65, 0.08, 0.08)
var eye_color: Color = Color(0.9, 0.85, 0.1)
var hp: float = 40.0
var max_hp: float = 40.0
var speed: float = 70.0
var damage: float = 10.0
var xp_value: float = 20.0
var contact_timer: float = 0.0
var wobble_offset: float = 0.0
var _flash: float = 0.0

# Spitter specific
var spit_timer: float = 0.0
var spit_interval: float = 2.4
var preferred_dist: float = 310.0

# Exploder specific
var explode_radius: float = 100.0
var _pulse: float = 0.0

func configure(type: String, wave: int):
	zombie_type = type
	wobble_offset = randf() * TAU
	spit_timer = randf_range(0.8, spit_interval)
	match type:
		"runner":
			radius = 13.0
			body_color = Color(0.90, 0.38, 0.05)
			eye_color  = Color(1.0, 0.95, 0.0)
			max_hp = 22.0 + wave * 5.0
			speed  = 125.0 + wave * 6.0
			damage = 7.0
			xp_value = 12.0 + wave * 2.0
		"normal":
			radius = 18.0
			body_color = Color(0.65, 0.08, 0.08)
			eye_color  = Color(0.9, 0.85, 0.1)
			max_hp = 35.0 + wave * 12.0
			speed  = 60.0 + wave * 4.0
			damage = 10.0
			xp_value = 20.0 + wave * 3.0
		"tank":
			radius = 27.0
			body_color = Color(0.28, 0.04, 0.38)
			eye_color  = Color(0.85, 0.15, 1.0)
			max_hp = 160.0 + wave * 35.0
			speed  = 36.0 + wave * 1.5
			damage = 18.0
			xp_value = 55.0 + wave * 8.0
		"brute":
			radius = 23.0
			body_color = Color(0.48, 0.03, 0.03)
			eye_color  = Color(1.0, 0.05, 0.05)
			max_hp = 75.0 + wave * 20.0
			speed  = 75.0 + wave * 5.0
			damage = 22.0
			xp_value = 38.0 + wave * 5.0
		"exploder":
			radius = 14.0
			body_color = Color(0.95, 0.52, 0.02)
			eye_color  = Color(1.0, 1.0, 0.2)
			max_hp = 20.0 + wave * 4.5
			speed  = 108.0 + wave * 7.0
			damage = 0.0
			xp_value = 18.0 + wave * 2.5
			explode_radius = 100.0 + wave * 2.0
		"spitter":
			radius = 16.0
			body_color = Color(0.08, 0.50, 0.08)
			eye_color  = Color(0.35, 1.0, 0.28)
			max_hp = 30.0 + wave * 8.0
			speed  = 50.0 + wave * 2.0
			damage = 10.0 + wave * 0.5
			xp_value = 28.0 + wave * 3.5
			spit_interval = max(1.2, 2.4 - wave * 0.06)
		"boss":
			radius = 44.0
			body_color = Color(0.15, 0.0, 0.22)
			eye_color  = Color(1.0, 0.0, 0.55)
			max_hp = 600.0 + wave * 100.0
			speed  = 50.0 + wave * 3.0
			damage = 35.0
			xp_value = 280.0 + wave * 25.0
	hp = max_hp

func _ready():
	collision_layer = 2
	collision_mask = 1
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	add_child(col)

func _draw():
	var bc = body_color.lerp(Color.WHITE, _flash * 0.65)

	# Exploder: pulsing danger glow
	if zombie_type == "exploder":
		_pulse = fmod(_pulse + 0.1, TAU)
		var glow_a = (sin(_pulse * 4.0) * 0.5 + 0.5) * 0.5
		if is_instance_valid(player):
			var proximity = clamp(1.0 - global_position.distance_to(player.global_position) / 300.0, 0.0, 1.0)
			glow_a = max(glow_a, proximity * 0.7)
		draw_circle(Vector2.ZERO, radius + 8.0, Color(1.0, 0.45, 0.0, glow_a))

	# Spitter: charge ring shows time until next spit
	if zombie_type == "spitter":
		var charge_pct = 1.0 - clamp(spit_timer / spit_interval, 0.0, 1.0)
		if charge_pct > 0.0:
			draw_arc(Vector2.ZERO, radius + 6.0, -PI * 0.5,
				-PI * 0.5 + TAU * charge_pct, 32, Color(0.2, 1.0, 0.3, 0.7), 2.5)

	# Spikes for brute / boss
	if zombie_type == "brute" or zombie_type == "boss":
		var sc = 6 if zombie_type == "brute" else 8
		for i in range(sc):
			var a = (TAU / float(sc)) * i
			var tip = Vector2(cos(a), sin(a)) * (radius + 10.0)
			var bl  = Vector2(cos(a + 0.28), sin(a + 0.28)) * radius
			var br  = Vector2(cos(a - 0.28), sin(a - 0.28)) * radius
			draw_colored_polygon(PackedVector2Array([bl, tip, br]), bc.lightened(0.28))

	draw_circle(Vector2.ZERO, radius, bc)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, bc.lightened(0.30), 2.0)

	# Eyes
	var er = radius * 0.21
	var ey = -radius * 0.22
	draw_circle(Vector2(-radius * 0.33, ey),           er,        eye_color)
	draw_circle(Vector2( radius * 0.33, ey),           er,        eye_color)
	draw_circle(Vector2(-radius * 0.33, ey + er * 0.15), er * 0.45, Color(0, 0, 0))
	draw_circle(Vector2( radius * 0.33, ey + er * 0.15), er * 0.45, Color(0, 0, 0))

	# HP bar
	var bw = radius * 2.3
	var by = -(radius + 12.0)
	draw_rect(Rect2(-bw * 0.5, by, bw, 5.0), Color(0.1, 0.1, 0.1))
	var bar_col = Color(0.8, 0.1, 0.9) if zombie_type == "boss" else Color(0.1, 0.85, 0.1)
	draw_rect(Rect2(-bw * 0.5, by, bw * (hp / max_hp), 5.0), bar_col)

func _physics_process(delta: float):
	if not is_instance_valid(player): return
	if _flash > 0.0:
		_flash = max(0.0, _flash - delta * 5.5)
		queue_redraw()

	var dir = (player.global_position - global_position).normalized()
	var dist = global_position.distance_to(player.global_position)

	match zombie_type:
		"runner":
			var t = Time.get_ticks_msec() * 0.002
			dir = dir.rotated(sin(t + wobble_offset) * 0.5)
			velocity = dir * speed
		"spitter":
			# Maintain preferred distance; fire projectiles
			spit_timer -= delta
			if spit_timer <= 0.0 and dist < 650.0:
				spit_timer = spit_interval
				fired_projectile.emit(global_position, dir, damage)
				queue_redraw()
			if dist < preferred_dist - 40.0:
				velocity = -dir * speed          # retreat
			elif dist > preferred_dist + 40.0:
				velocity = dir * speed           # advance
			else:
				# Strafe sideways
				velocity = dir.rotated(PI * 0.5) * speed * 0.55
		"exploder":
			# Accelerates as it closes in
			var charge = 1.0 + clamp((200.0 - dist) / 200.0, 0.0, 1.0) * 1.8
			velocity = dir * speed * charge
		_:
			velocity = dir * speed

	move_and_slide()
	if zombie_type == "exploder": queue_redraw()

	contact_timer -= delta
	if contact_timer <= 0.0 and dist < radius + 18.0:
		if zombie_type == "exploder":
			# Triggers explosion on contact
			_trigger_explode()
		else:
			player.take_damage(damage)
			contact_timer = 0.6

func _trigger_explode():
	exploded.emit(global_position, explode_radius, 42.0 + damage)
	died_at.emit(global_position, xp_value)
	queue_free()

func take_damage(amount: float, crit: bool = false):
	hp -= amount
	_flash = 1.0
	queue_redraw()
	damaged.emit(amount, global_position, crit)
	if hp <= 0.0:
		if zombie_type == "exploder":
			exploded.emit(global_position, explode_radius, 36.0)
		died_at.emit(global_position, xp_value)
		queue_free()
