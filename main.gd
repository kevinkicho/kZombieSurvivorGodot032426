extends Node2D

const PlayerScript    = preload("res://player.gd")
const ZombieScript    = preload("res://zombie.gd")
const ParticleScript  = preload("res://particle.gd")
const XpOrbScript     = preload("res://xp_orb.gd")
const FloatyScript    = preload("res://floaty_text.gd")
const PowerupScript   = preload("res://powerup.gd")
const EnemyBulletScript = preload("res://enemy_bullet.gd")

# ── Game state ─────────────────────────────────────────────────────────────
var wave: int = 0
var kills: int = 0
var time_alive: float = 0.0
var spawn_remaining: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 0.35
var wave_active: bool = false
var between_wave_timer: float = 3.0
var boss_alive: bool = false
var boss_ref: Node = null
var streak: int = 0
var streak_timer: float = 0.0
var game_over: bool = false

# Wave progress tracking
var wave_total: int = 0
var wave_start_kills: int = 0

# Kill milestones
const MILESTONES = [10, 25, 50, 100, 200, 350, 500]
var _next_milestone: int = 0

# ── Nodes ──────────────────────────────────────────────────────────────────
var player: CharacterBody2D
var camera: Camera2D
var enemies_node: Node2D
var bullets_node: Node2D
var enemy_bullets_node: Node2D
var orbs_node: Node2D
var effects_node: Node2D
var powerups_node: Node2D
var ui_layer: CanvasLayer

# ── Camera shake ───────────────────────────────────────────────────────────
var shake_amt: float = 0.0

# ── UI refs ────────────────────────────────────────────────────────────────
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var wave_lbl: Label
var kills_lbl: Label
var lvl_lbl: Label
var time_lbl: Label
var streak_lbl: Label
var boost_lbl: Label
var msg_lbl: Label
var msg_timer: float = 0.0
var upgrade_panel: Control = null
var boss_bar_panel: Panel = null
var boss_bar: ProgressBar = null
var wave_prog_bar: ProgressBar = null
var low_hp_overlay: ColorRect = null

# ── Ready ──────────────────────────────────────────────────────────────────
func _ready():
	_add_wasd()
	_setup_world()
	_spawn_player()
	_setup_ui()
	_show_msg("SURVIVE THE HORDE!", 2.5)

func _add_wasd():
	var map = { "ui_left": KEY_A, "ui_right": KEY_D, "ui_up": KEY_W, "ui_down": KEY_S }
	for action in map:
		var ev = InputEventKey.new()
		ev.keycode = map[action]
		InputMap.action_add_event(action, ev)

# ── World ──────────────────────────────────────────────────────────────────
func _setup_world():
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.09, 0.06)
	bg.size = Vector2(20000, 20000)
	bg.position = Vector2(-10000, -10000)
	bg.z_index = -10
	add_child(bg)

	for i in range(450):
		var dot = ColorRect.new()
		var g = randf_range(0.09, 0.17)
		dot.color = Color(g * 0.7, g, g * 0.7)
		dot.size = Vector2(randf_range(12, 110), randf_range(12, 110))
		dot.position = Vector2(randf_range(-5000, 5000), randf_range(-5000, 5000))
		dot.rotation = randf() * PI
		dot.z_index = -9
		add_child(dot)

	enemies_node      = Node2D.new(); add_child(enemies_node)
	bullets_node      = Node2D.new(); add_child(bullets_node)
	enemy_bullets_node = Node2D.new(); add_child(enemy_bullets_node)
	orbs_node         = Node2D.new(); add_child(orbs_node)
	effects_node      = Node2D.new(); add_child(effects_node)
	powerups_node     = Node2D.new(); add_child(powerups_node)

func _spawn_player():
	player = PlayerScript.new()
	player.enemies_node = enemies_node
	player.bullets_node = bullets_node
	player.effects_node = effects_node
	player.leveled_up.connect(_on_level_up)
	player.died.connect(_on_player_died)
	player.took_damage.connect(_on_player_hit)
	add_child(player)

	camera = Camera2D.new()
	player.add_child(camera)

# ── UI ─────────────────────────────────────────────────────────────────────
func _setup_ui():
	ui_layer = CanvasLayer.new()
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	# Low HP overlay (behind everything else in UI)
	low_hp_overlay = ColorRect.new()
	low_hp_overlay.color = Color(0.9, 0.0, 0.0, 0.0)
	low_hp_overlay.size = Vector2(1600, 900)
	low_hp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(low_hp_overlay)

	var panel = Panel.new()
	panel.position = Vector2(8, 8)
	panel.size = Vector2(256, 202)
	ui_layer.add_child(panel)

	_lbl(ui_layer, "HP", Vector2(16, 12))
	hp_bar = _bar(ui_layer, Vector2(16, 30), Vector2(228, 20), Color(0.85, 0.15, 0.15))

	_lbl(ui_layer, "XP", Vector2(16, 57))
	xp_bar = _bar(ui_layer, Vector2(16, 75), Vector2(228, 12), Color(0.2, 0.7, 1.0))

	wave_lbl  = _lbl(ui_layer, "Wave 1",  Vector2(16, 93))
	kills_lbl = _lbl(ui_layer, "Kills 0", Vector2(148, 93))
	lvl_lbl   = _lbl(ui_layer, "Lv. 1",  Vector2(16, 113))
	time_lbl  = _lbl(ui_layer, "0:00",   Vector2(148, 113))
	streak_lbl = _lbl(ui_layer, "",       Vector2(16, 135))
	streak_lbl.modulate = Color(1.0, 0.85, 0.15)
	boost_lbl = _lbl(ui_layer, "", Vector2(16, 158))
	boost_lbl.modulate = Color(0.85, 1.0, 0.85)
	boost_lbl.add_theme_font_size_override("font_size", 13)

	# Wave progress bar (top center)
	var wave_prog_panel = Panel.new()
	wave_prog_panel.position = Vector2(290, 8)
	wave_prog_panel.size = Vector2(700, 38)
	ui_layer.add_child(wave_prog_panel)
	_lbl(ui_layer, "WAVE PROGRESS", Vector2(298, 10)).add_theme_font_size_override("font_size", 12)
	wave_prog_bar = _bar(ui_layer, Vector2(298, 24), Vector2(686, 14), Color(0.9, 0.55, 0.1))
	wave_prog_bar.max_value = 1
	wave_prog_bar.value = 0

	var hint = _lbl(ui_layer, "[WASD] Move   [SPACE] Dash   Auto-aims & shoots", Vector2(16, 695))
	hint.modulate = Color(1, 1, 1, 0.45)

	msg_lbl = Label.new()
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.position = Vector2(240, 52)
	msg_lbl.size = Vector2(800, 62)
	msg_lbl.add_theme_font_size_override("font_size", 38)
	msg_lbl.modulate = Color(1.0, 0.95, 0.25)
	ui_layer.add_child(msg_lbl)

func _lbl(parent: Node, text: String, pos: Vector2) -> Label:
	var l = Label.new()
	l.text = text
	l.position = pos
	parent.add_child(l)
	return l

func _bar(parent: Node, pos: Vector2, sz: Vector2, fill_col: Color) -> ProgressBar:
	var b = ProgressBar.new()
	b.position = pos
	b.size = sz
	b.max_value = 100
	b.value = 100
	var s = StyleBoxFlat.new()
	s.bg_color = fill_col
	b.add_theme_stylebox_override("fill", s)
	parent.add_child(b)
	return b

# ── Main loop ──────────────────────────────────────────────────────────────
func _process(delta: float):
	if game_over: return
	time_alive += delta
	_update_ui()
	_handle_waves(delta)
	_handle_msg(delta)
	_update_shake(delta)
	_update_streak(delta)
	_update_boss_bar()

func _update_ui():
	if not is_instance_valid(player): return
	hp_bar.max_value = player.max_hp
	hp_bar.value     = player.hp
	xp_bar.max_value = player.xp_needed
	xp_bar.value     = player.xp
	kills_lbl.text = "Kills %d" % kills
	lvl_lbl.text   = "Lv. %d"  % player.level
	time_lbl.text  = "%d:%02d" % [int(time_alive / 60), int(time_alive) % 60]

	# Wave label shows countdown between waves
	if not wave_active and between_wave_timer > 0.0:
		wave_lbl.text = "Next: %ds" % ceili(between_wave_timer)
	else:
		wave_lbl.text = "Wave %d" % wave

	# Wave progress bar
	if wave_prog_bar:
		if wave_active and wave_total > 0:
			wave_prog_bar.max_value = wave_total
			wave_prog_bar.value = kills - wave_start_kills
			wave_prog_bar.visible = true
		else:
			wave_prog_bar.visible = false

	# Low HP overlay
	if low_hp_overlay:
		var hp_pct = player.hp / player.max_hp
		if hp_pct < 0.30:
			low_hp_overlay.color.a = (sin(time_alive * 6.5) * 0.5 + 0.5) * 0.18
		else:
			low_hp_overlay.color.a = max(0.0, low_hp_overlay.color.a - 0.05)

	# Active boost display
	if boost_lbl:
		var parts: Array = []
		if player.boost_speed_timer  > 0.0: parts.append("SPD %.0fs"    % player.boost_speed_timer)
		if player.boost_damage_timer > 0.0: parts.append("DMG %.0fs"    % player.boost_damage_timer)
		if player.boost_magnet_timer > 0.0: parts.append("MAGNET %.0fs" % player.boost_magnet_timer)
		if player.boost_shield_timer > 0.0: parts.append("SHIELD")
		if player.force_shield       > 0.0: parts.append("FSH %.0f"     % player.force_shield)
		boost_lbl.text = "  ".join(parts)

func _update_streak(delta: float):
	if streak >= 3:
		streak_timer -= delta
		if streak_timer <= 0.0:
			streak = 0
	streak_lbl.text = "STREAK x%d!" % streak if streak >= 3 else ""

func _update_shake(delta: float):
	if shake_amt > 0.0:
		camera.offset = Vector2(randf_range(-shake_amt, shake_amt), randf_range(-shake_amt, shake_amt))
		shake_amt = move_toward(shake_amt, 0.0, 200.0 * delta)
	else:
		camera.offset = Vector2.ZERO

func _update_boss_bar():
	if not boss_bar or not is_instance_valid(boss_ref): return
	boss_bar.value = boss_ref.hp

# ── Waves ──────────────────────────────────────────────────────────────────
func _handle_waves(delta: float):
	if upgrade_panel: return
	if not wave_active:
		between_wave_timer -= delta
		if between_wave_timer <= 0.0:
			_start_wave()
	else:
		if spawn_remaining > 0:
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				_spawn_zombie()
				spawn_remaining -= 1
				spawn_timer = spawn_interval
		if spawn_remaining == 0 and enemies_node.get_child_count() == 0 and not boss_alive:
			wave_active = false
			between_wave_timer = 7.0
			_show_msg("Wave %d  CLEARED!" % wave, 2.5)
			# Wave clear bonus XP
			if is_instance_valid(player):
				var bonus = wave * 55.0
				player.gain_xp(bonus)
				_floaty(player.global_position + Vector2(0, -80),
					"+%d WAVE BONUS XP!" % int(bonus), Color(0.25, 1.0, 0.8), 22, 2.2)

func _start_wave():
	wave += 1
	boss_alive = false
	wave_active = true
	spawn_timer = 0.0
	spawn_interval = max(0.13, 0.35 - wave * 0.012)
	wave_start_kills = kills

	var is_boss = (wave % 5 == 0)
	if is_boss:
		spawn_remaining = wave * 3
		wave_total = spawn_remaining + 1
		boss_alive = true
		_show_msg("!! BOSS WAVE %d !!" % wave, 3.0)
		get_tree().create_timer(2.0).timeout.connect(_spawn_boss)
	else:
		spawn_remaining = 8 + wave * 5
		wave_total = spawn_remaining
		_show_msg("Wave %d  [ %d Zombies ]" % [wave, spawn_remaining], 2.5)

func _pick_type() -> String:
	var r = randf()
	var thresholds: Array = []
	if wave >= 7: thresholds.append(["brute",   0.12])
	if wave >= 6: thresholds.append(["exploder", 0.11])
	if wave >= 4: thresholds.append(["spitter",  0.10])
	if wave >= 5: thresholds.append(["tank",     0.14])
	if wave >= 3: thresholds.append(["runner",   0.16])
	var cum = 0.0
	for t in thresholds:
		cum += t[1]
		if r < cum: return t[0]
	return "normal"

func _spawn_zombie():
	var z: CharacterBody2D = ZombieScript.new()
	z.player = player
	z.configure(_pick_type(), wave)
	var angle = randf() * TAU
	z.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(520.0, 720.0)
	z.died_at.connect(_on_zombie_died)
	z.damaged.connect(_on_zombie_damaged)
	z.exploded.connect(_on_exploder_detonated)
	z.fired_projectile.connect(_on_spitter_fired)
	enemies_node.add_child(z)

func _spawn_boss():
	if game_over:
		boss_alive = false
		return
	var z: CharacterBody2D = ZombieScript.new()
	z.player = player
	z.configure("boss", wave)
	var angle = randf() * TAU
	z.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * 620.0
	z.died_at.connect(_on_boss_died)
	z.damaged.connect(_on_zombie_damaged)
	z.exploded.connect(_on_exploder_detonated)
	z.fired_projectile.connect(_on_spitter_fired)
	enemies_node.add_child(z)
	boss_ref = z
	_make_boss_bar(z)

func _make_boss_bar(boss: Node):
	if boss_bar_panel: boss_bar_panel.queue_free()
	boss_bar_panel = Panel.new()
	boss_bar_panel.position = Vector2(290, 668)
	boss_bar_panel.size = Vector2(700, 42)
	ui_layer.add_child(boss_bar_panel)
	var lbl = Label.new()
	lbl.text = "BOSS"
	lbl.position = Vector2(4, 6)
	lbl.modulate = Color(1, 0.2, 0.85)
	lbl.add_theme_font_size_override("font_size", 18)
	boss_bar_panel.add_child(lbl)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(58, 8)
	boss_bar.size = Vector2(632, 26)
	boss_bar.max_value = boss.max_hp
	boss_bar.value = boss.max_hp
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.8, 0.1, 0.9)
	boss_bar.add_theme_stylebox_override("fill", s)
	boss_bar_panel.add_child(boss_bar)

# ── Enemy events ────────────────────────────────────────────────────────────
func _on_zombie_died(pos: Vector2, xp_val: float):
	kills += 1
	streak += 1
	streak_timer = 3.2
	shake_amt = max(shake_amt, 3.5)
	_burst(pos, Color(0.72, 0.1, 0.1), 10)
	_burst(pos, Color(0.9, 0.45, 0.1), 5)
	_spawn_orb(pos, xp_val)
	if is_instance_valid(player) and player.heal_per_kill > 0.0:
		player.hp = min(player.max_hp, player.hp + player.heal_per_kill)
	if streak >= 5 and streak % 5 == 0:
		_floaty(pos + Vector2(0, -30), "x%d STREAK!" % streak, Color(1.0, 0.8, 0.1), 26, 1.5)
	# Kill milestones
	if _next_milestone < MILESTONES.size() and kills >= MILESTONES[_next_milestone]:
		_floaty(player.global_position + Vector2(0, -65),
			"%d KILLS!" % kills, Color(1.0, 0.92, 0.15), 30, 2.2)
		_show_msg("%d KILL MILESTONE!" % kills, 2.0)
		_next_milestone += 1
	# Random power-up drop
	if randf() < 0.07:
		_spawn_powerup(pos)

func _on_boss_died(pos: Vector2, xp_val: float):
	kills += 1
	boss_alive = false
	boss_ref = null
	if boss_bar_panel:
		boss_bar_panel.queue_free()
		boss_bar_panel = null
	boss_bar = null
	shake_amt = max(shake_amt, 28.0)
	for i in range(6):
		_burst(pos + Vector2(randf_range(-70, 70), randf_range(-70, 70)), Color(0.9, 0.2, 0.9), 16)
	_burst(pos, Color(1.0, 0.88, 0.2), 22)
	for i in range(10):
		_spawn_orb(pos + Vector2(randf_range(-60, 60), randf_range(-60, 60)), xp_val / 10.0)
	_floaty(pos, "BOSS SLAIN!", Color(1.0, 0.3, 1.0), 34, 2.2)
	_show_msg("BOSS DEFEATED!  +BIG XP!", 3.0)

func _on_zombie_damaged(amount: float, pos: Vector2, is_crit: bool):
	if is_crit:
		_floaty(pos + Vector2(randf_range(-14, 14), -22),
			"CRIT! -%d" % int(amount), Color(1.0, 0.92, 0.1), 26, 1.4)
		_burst(pos, Color(1.0, 0.85, 0.1), 5)
	else:
		_floaty(pos + Vector2(randf_range(-12, 12), -18),
			"-%d" % int(amount), Color(1.0, 0.45, 0.15), 18)

func _on_player_hit():
	shake_amt = max(shake_amt, 9.0)

func _on_exploder_detonated(pos: Vector2, radius: float, dmg: float):
	shake_amt = max(shake_amt, 14.0)
	for i in range(3):
		_burst(pos + Vector2(randf_range(-28, 28), randf_range(-28, 28)),
			Color(1.0, randf_range(0.3, 0.7), 0.0), 12)
	_burst(pos, Color(1.0, 0.92, 0.2), 18)
	_floaty(pos + Vector2(0, -20), "BOOM!", Color(1.0, 0.6, 0.1), 32, 1.6)
	# AoE player damage
	if is_instance_valid(player) and player.global_position.distance_to(pos) < radius:
		player.take_damage(dmg)
	# Chain damage to nearby non-exploder enemies (skip exploders to prevent infinite recursion)
	for e in enemies_node.get_children():
		if is_instance_valid(e) and e.zombie_type != "exploder" and \
				e.global_position.distance_to(pos) < radius * 0.65:
			e.take_damage(dmg * 0.45)

func _on_spitter_fired(from_pos: Vector2, direction: Vector2, dmg: float):
	var eb = EnemyBulletScript.new()
	eb.direction = direction.rotated(randf_range(-0.18, 0.18)).normalized()
	eb.damage = dmg
	eb.player_ref = player
	eb.global_position = from_pos + direction * 22.0
	enemy_bullets_node.add_child(eb)

# ── Power-ups ───────────────────────────────────────────────────────────────
func _spawn_powerup(pos: Vector2):
	var pu = PowerupScript.new()
	var roll = randf()
	if roll < 0.30:   pu.type = "speed"
	elif roll < 0.60: pu.type = "damage"
	elif roll < 0.80: pu.type = "shield"
	else:             pu.type = "magnet"
	pu.player = player
	pu.global_position = pos + Vector2(randf_range(-22, 22), randf_range(-22, 22))
	pu.collected.connect(_on_powerup_collected)
	powerups_node.add_child(pu)

func _on_powerup_collected(type: String, pos: Vector2):
	var info = {
		"speed":  ["SPEED BOOST!", Color(0.15, 0.9, 1.0)],
		"damage": ["DAMAGE UP!",   Color(1.0, 0.4, 0.1)],
		"shield": ["ONE-HIT SHIELD!", Color(0.9, 1.0, 0.25)],
		"magnet": ["ORB MAGNET!",  Color(0.88, 0.2, 0.95)],
	}
	if type in info:
		_floaty(pos + Vector2(0, -45), info[type][0], info[type][1], 24, 2.0)
		_burst(pos, info[type][1], 8)

# ── Helpers ─────────────────────────────────────────────────────────────────
func _burst(pos: Vector2, col: Color, count: int):
	for i in range(count):
		var p = ParticleScript.new()
		p.vel = Vector2.from_angle(randf() * TAU) * randf_range(55, 250)
		p.life = randf_range(0.3, 0.72)
		p.init_life = p.life
		p.size = randf_range(5, 14)
		p.color = col
		p.global_position = pos
		effects_node.add_child(p)

func _spawn_orb(pos: Vector2, xp_val: float):
	var orb = XpOrbScript.new()
	orb.xp_value = xp_val
	orb.player = player
	orb.global_position = pos
	orbs_node.add_child(orb)

func _floaty(pos: Vector2, text: String, col: Color, size: int = 20, life: float = 1.1):
	var ft = FloatyScript.new()
	ft.text = text
	ft.color = col
	ft.font_size = size
	ft.lifetime = life
	ft.global_position = pos
	effects_node.add_child(ft)

# ── Level up ────────────────────────────────────────────────────────────────
func _on_level_up(_lv: int):
	shake_amt = max(shake_amt, 5.0)
	player.lvlup_ring = 0.65
	_floaty(player.global_position + Vector2(0, -55),
		"LEVEL %d!" % _lv, Color(1.0, 0.92, 0.2), 28, 1.8)
	_show_upgrade_menu()

func _show_upgrade_menu():
	if upgrade_panel: return
	get_tree().paused = true

	upgrade_panel = Panel.new()
	upgrade_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var psz = Vector2(700, 470)
	var screen = get_viewport().get_visible_rect().size
	upgrade_panel.position = (screen - psz) / 2.0
	upgrade_panel.size = psz
	ui_layer.add_child(upgrade_panel)

	var title = Label.new()
	title.text = "  LEVEL %d!  Choose an upgrade:" % player.level
	title.position = Vector2(10, 14)
	title.add_theme_font_size_override("font_size", 26)
	title.modulate = Color(1.0, 0.9, 0.2)
	upgrade_panel.add_child(title)

	var pool = _upgrade_pool()
	pool.shuffle()
	for i in range(mini(3, pool.size())):
		var u = pool[i]
		var btn = Button.new()
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.text = u["label"]
		btn.position = Vector2(10, 62 + i * 122)
		btn.size = Vector2(680, 108)
		btn.add_theme_font_size_override("font_size", 19)
		btn.pressed.connect(_apply_upgrade.bind(u))
		upgrade_panel.add_child(btn)

func _upgrade_pool() -> Array:
	var pool: Array = [
		{"label": "Max HP +40      Iron Constitution  [+40 max HP]",                "stat": "max_hp",       "val": 40.0},
		{"label": "Move Speed +20%   Quick Feet  [Move 20%% faster]",               "stat": "speed",        "val": 0.20},
		{"label": "Damage +35%   Heavy Hitter  [Bullets hit harder]",               "stat": "damage",       "val": 0.35},
		{"label": "Fire Rate +25%   Rapid Fire  [Shoot more often]",                "stat": "fire_rate",    "val": 0.25},
		{"label": "Restore 50 HP   Field Medic  [Instant heal]",                    "stat": "heal",         "val": 50.0},
		{"label": "Bullet Speed +30%   Swift Shots  [Bullets travel faster]",       "stat": "bullet_speed", "val": 0.30},
		{"label": "Multi-Shot   Fire 3 bullets per shot  [Wide spread]",            "stat": "multi_shot",   "val": 1.0},
		{"label": "Piercing Rounds   Bullets pass through zombies",                 "stat": "piercing",     "val": 1.0},
		{"label": "Dash Cooldown -35%   Agile Warrior  [Dash more often]",          "stat": "dash_cd",      "val": 0.35},
		{"label": "Vampire   Heal 3 HP per kill  [Lifesteal]",                      "stat": "vampire",      "val": 3.0},
		{"label": "Explosive Rounds   Bullets AoE on impact  [Area damage]",        "stat": "explosive",    "val": 1.0},
		{"label": "Critical Eye   +18%% crit chance  [Lucky shots hit 2.2x harder]","stat": "crit_eye",     "val": 0.18},
		{"label": "Force Shield   Absorb 80 damage  [Permanent shield HP]",         "stat": "force_shield", "val": 80.0},
		{"label": "Homing Rounds   Bullets track nearest enemy  [Seeking shots]",   "stat": "homing",       "val": 1.0},
		{"label": "Scholar   +40%% XP gain  [Level up faster]",                     "stat": "xp_mult",      "val": 0.40},
	]
	# Filter one-time upgrades already acquired
	if player.multi_shot  > 1:      pool = pool.filter(func(u): return u["stat"] != "multi_shot")
	if player.piercing:             pool = pool.filter(func(u): return u["stat"] != "piercing")
	if player.has_explosive:        pool = pool.filter(func(u): return u["stat"] != "explosive")
	if player.has_homing:           pool = pool.filter(func(u): return u["stat"] != "homing")
	return pool

func _apply_upgrade(u: Dictionary):
	match u["stat"]:
		"max_hp":       player.max_hp += u["val"]; player.hp = min(player.hp + u["val"], player.max_hp)
		"speed":        player.speed *= 1.0 + u["val"]
		"damage":       player.damage *= 1.0 + u["val"]
		"fire_rate":    player.fire_rate = max(0.07, player.fire_rate * (1.0 - u["val"]))
		"heal":         player.hp = min(player.max_hp, player.hp + u["val"])
		"bullet_speed": player.bullet_speed *= 1.0 + u["val"]
		"multi_shot":   player.multi_shot = 3
		"piercing":     player.piercing = true
		"dash_cd":      player.dash_cooldown = max(0.5, player.dash_cooldown * (1.0 - u["val"]))
		"vampire":      player.heal_per_kill += u["val"]
		"explosive":    player.has_explosive = true
		"crit_eye":     player.crit_chance += u["val"]
		"force_shield": player.force_shield += u["val"]
		"homing":       player.has_homing = true
		"xp_mult":      player.xp_mult += u["val"]
	upgrade_panel.queue_free()
	upgrade_panel = null
	get_tree().paused = false

# ── Game over ───────────────────────────────────────────────────────────────
func _calc_score() -> int:
	return kills * 100 + wave * 500 + player.level * 300 + int(time_alive) * 2

func _calc_grade(score: int) -> String:
	if score >= 15000: return "S+"
	if score >= 10000: return "S"
	if score >= 7000:  return "A"
	if score >= 4500:  return "B"
	if score >= 2500:  return "C"
	if score >= 1000:  return "D"
	return "F"

func _on_player_died():
	game_over = true
	get_tree().paused = false
	shake_amt = max(shake_amt, 22.0)
	_burst(player.global_position, Color(0.2, 0.85, 0.3), 24)

	await get_tree().create_timer(0.9).timeout

	var score = _calc_score()
	var grade = _calc_grade(score)
	var grade_col = Color(1.0, 0.35, 0.35)
	if grade in ["S+", "S"]:    grade_col = Color(1.0, 0.88, 0.1)
	elif grade == "A":           grade_col = Color(0.35, 1.0, 0.35)
	elif grade == "B":           grade_col = Color(0.25, 0.85, 1.0)

	var go = Panel.new()
	var gsz = Vector2(760, 520)
	go.position = (get_viewport().get_visible_rect().size - gsz) / 2.0
	go.size = gsz
	ui_layer.add_child(go)

	var lbl = Label.new()
	lbl.text = ("YOU DIED\n\n"
		+ "Wave Reached:    %d\n"
		+ "Zombies Killed:  %d\n"
		+ "Level Reached:   %d\n"
		+ "Time Survived:   %d:%02d\n\n"
		+ "Score:  %d") % [
		wave, kills, player.level,
		int(time_alive / 60), int(time_alive) % 60,
		score]
	lbl.position = Vector2(30, 28)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.modulate = Color(1.0, 0.4, 0.4)
	go.add_child(lbl)

	# Grade badge
	var grade_lbl = Label.new()
	grade_lbl.text = grade
	grade_lbl.position = Vector2(580, 28)
	grade_lbl.add_theme_font_size_override("font_size", 88)
	grade_lbl.modulate = grade_col
	go.add_child(grade_lbl)

	var btn = Button.new()
	btn.text = "Rise Again"
	btn.position = Vector2(230, 424)
	btn.size = Vector2(300, 72)
	btn.add_theme_font_size_override("font_size", 26)
	btn.pressed.connect(_restart)
	go.add_child(btn)

func _restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

# ── Message ─────────────────────────────────────────────────────────────────
func _show_msg(text: String, dur: float):
	msg_lbl.text = text
	msg_timer = dur

func _handle_msg(delta: float):
	if msg_timer > 0.0:
		msg_timer -= delta
		if msg_timer <= 0.0:
			msg_lbl.text = ""
