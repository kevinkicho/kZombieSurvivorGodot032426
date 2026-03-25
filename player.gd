extends CharacterBody2D

signal leveled_up(new_level: int)
signal died
signal took_damage

var max_hp: float = 100.0
var hp: float = 100.0
var speed: float = 200.0
var damage: float = 25.0
var fire_rate: float = 0.5
var bullet_speed: float = 500.0
var xp: float = 0.0
var xp_needed: float = 100.0
var level: int = 1
var dead: bool = false
var multi_shot: int = 1
var piercing: bool = false
var heal_per_kill: float = 0.0

# New combat stats
var crit_chance: float = 0.08
var crit_mult: float   = 2.2
var has_explosive: bool = false
var has_homing: bool    = false
var xp_mult: float      = 1.0
var force_shield: float = 0.0

# Temporary boost timers
var boost_speed_timer:  float = 0.0
var boost_damage_timer: float = 0.0
var boost_shield_timer: float = 0.0
var boost_magnet_timer: float = 0.0

var enemies_node: Node2D = null
var bullets_node: Node2D = null
var effects_node: Node2D = null

var fire_timer: float    = 0.0
var iframes: float       = 0.0
var damage_flash: float  = 0.0
var gun_angle: float     = -PI * 0.5

# Level-up ring
var lvlup_ring: float = 0.0

# Dash
var dash_speed: float    = 660.0
var dash_duration: float = 0.18
var dash_cooldown: float = 2.0
var _dash_timer: float   = 0.0
var _dash_cd: float      = 0.0
var _dashing: bool       = false
var _dash_dir: Vector2   = Vector2.ZERO

const BulletScript = preload("res://bullet.gd")

func _ready():
	collision_layer = 1
	collision_mask = 2
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)

func _draw():
	var flash = clamp(damage_flash / 0.22, 0.0, 1.0)
	var bc = Color(0.15, 0.70, 0.20).lerp(Color(1.0, 0.15, 0.15), flash)

	# Level-up expanding rainbow ring
	if lvlup_ring > 0.0:
		var pct = 1.0 - (lvlup_ring / 0.65)
		var ring_r = pct * 130.0
		var ring_a = (1.0 - pct) * 0.9
		for i in range(12):
			var hue = float(i) / 12.0
			draw_arc(Vector2.ZERO, ring_r,
				(TAU / 12.0) * i, (TAU / 12.0) * (i + 0.82), 8,
				Color.from_hsv(hue, 0.9, 1.0, ring_a), 4.0)

	# Dash glow
	if _dashing:
		draw_circle(Vector2.ZERO, 24.0, Color(0.3, 0.6, 1.0, 0.28))

	# Force shield ring
	if force_shield > 0.0:
		var sa = clamp(force_shield / 100.0, 0.3, 0.9)
		draw_arc(Vector2.ZERO, 22.5, 0.0, TAU, 48, Color(0.28, 0.82, 1.0, sa), 3.5)
		draw_circle(Vector2.ZERO, 22.5, Color(0.28, 0.82, 1.0, sa * 0.11))

	# One-hit boost shield glow
	if boost_shield_timer > 0.0:
		draw_circle(Vector2.ZERO, 20.5, Color(0.9, 1.0, 0.25, 0.22))

	draw_circle(Vector2.ZERO, 16.0, bc)
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 32, Color(0.5, 1.0, 0.5, 0.85), 2.5)

	# Active boost indicator dots (centered above player)
	var dots: Array = []
	if boost_speed_timer  > 0.0: dots.append(Color(0.15, 0.9, 1.0))
	if boost_damage_timer > 0.0: dots.append(Color(1.0,  0.4, 0.1))
	if boost_magnet_timer > 0.0: dots.append(Color(0.88, 0.2, 0.95))
	if boost_shield_timer > 0.0: dots.append(Color(0.9,  1.0, 0.25))
	var dot_start_x = -6.0 * (dots.size() - 1) * 0.5
	for di in range(dots.size()):
		draw_circle(Vector2(dot_start_x + di * 12.0, -31.0), 4.5, dots[di])

	# Gun barrel
	var gd = Vector2(cos(gun_angle), sin(gun_angle))
	draw_line(gd * 7.0, gd * 27.0, Color(0.9, 0.85, 0.3), 5.0)
	draw_circle(gd * 27.0, 4.5, Color(1.0, 0.92, 0.22))

	# Dash cooldown arc
	if _dash_cd > 0.0:
		var pct = 1.0 - (_dash_cd / dash_cooldown)
		draw_arc(Vector2.ZERO, 23.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 36, Color(0.3, 0.65, 1.0, 0.85), 3.0)
	else:
		draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 36, Color(0.3, 0.65, 1.0, 0.4), 2.0)

func _physics_process(delta: float):
	if iframes > 0.0:    iframes -= delta
	if damage_flash > 0.0:
		damage_flash -= delta
		queue_redraw()
	if _dash_cd > 0.0:
		_dash_cd -= delta
		queue_redraw()
	if lvlup_ring > 0.0:
		lvlup_ring -= delta
		queue_redraw()

	# Tick boost timers
	var any = boost_speed_timer > 0.0 or boost_damage_timer > 0.0 or \
		boost_shield_timer > 0.0 or boost_magnet_timer > 0.0
	boost_speed_timer  = max(0.0, boost_speed_timer  - delta)
	boost_damage_timer = max(0.0, boost_damage_timer - delta)
	boost_shield_timer = max(0.0, boost_shield_timer - delta)
	boost_magnet_timer = max(0.0, boost_magnet_timer - delta)
	if any: queue_redraw()

	_handle_dash(delta)
	if not _dashing:
		_move()
	_auto_shoot(delta)
	_update_gun_angle()

func _handle_dash(delta: float):
	if _dashing:
		velocity = _dash_dir * dash_speed
		move_and_slide()
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_dashing = false
	elif Input.is_action_just_pressed("ui_accept") and _dash_cd <= 0.0:
		var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if dir == Vector2.ZERO:
			dir = Vector2(cos(gun_angle), sin(gun_angle))
		_dash_dir = dir.normalized()
		_dashing = true
		_dash_timer = dash_duration
		_dash_cd = dash_cooldown
		iframes = dash_duration + 0.12

func _move():
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var spd = speed * (1.42 if boost_speed_timer > 0.0 else 1.0)
	velocity = dir * spd
	move_and_slide()

func _update_gun_angle():
	if not enemies_node: return
	var t = _nearest_enemy()
	if t:
		gun_angle = (t.global_position - global_position).angle()
		queue_redraw()

func _auto_shoot(delta: float):
	fire_timer -= delta
	if fire_timer > 0.0 or not enemies_node or not bullets_node: return
	var target = _nearest_enemy()
	if not target: return
	_fire(target.global_position - global_position, target)
	fire_timer = fire_rate

func _nearest_enemy() -> Node:
	var nearest: Node = null
	var best: float = INF
	for e in enemies_node.get_children():
		if not is_instance_valid(e): continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < best:
			best = d
			nearest = e
	return nearest

func _fire(dir: Vector2, target: Node = null):
	var base_a = dir.angle()
	var spread = deg_to_rad(18.0) if multi_shot > 1 else 0.0
	var is_crit = randf() < crit_chance
	var dmg = damage * (1.42 if boost_damage_timer > 0.0 else 1.0)
	if is_crit: dmg *= crit_mult
	for i in range(multi_shot):
		var offset = 0.0
		if multi_shot > 1:
			offset = lerp(-spread, spread, float(i) / float(multi_shot - 1))
		var b = BulletScript.new()
		b.direction     = Vector2.from_angle(base_a + offset)
		b.speed         = bullet_speed
		b.damage        = dmg
		b.piercing      = piercing
		b.is_crit       = is_crit
		b.is_explosive  = has_explosive
		b.enemies_node  = enemies_node
		b.effects_node  = effects_node
		if has_homing and is_instance_valid(target):
			b.homing_target = target
		b.global_position = global_position
		bullets_node.add_child(b)

func take_damage(amount: float):
	if iframes > 0.0 or dead: return
	# Priority: temp one-hit shield > force shield > HP
	if boost_shield_timer > 0.0:
		boost_shield_timer = 0.0
		iframes = 0.4
		damage_flash = 0.15
		took_damage.emit()
		queue_redraw()
		return
	if force_shield > 0.0:
		force_shield = max(0.0, force_shield - amount)
		iframes = 0.25
		damage_flash = 0.1
		took_damage.emit()
		queue_redraw()
		return
	hp = max(0.0, hp - amount)
	iframes = 0.5
	damage_flash = 0.22
	took_damage.emit()
	if hp <= 0.0:
		dead = true
		died.emit()

func gain_xp(amount: float):
	xp += amount * xp_mult
	if xp >= xp_needed:
		xp -= xp_needed
		xp_needed = ceil(xp_needed * 1.5)
		level += 1
		leveled_up.emit(level)
