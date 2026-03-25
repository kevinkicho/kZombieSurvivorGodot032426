# kZombieSurvivorGodot032426

A wave-based zombie survival shooter built in Godot 4.6. Fight off increasingly difficult hordes of zombies, level up with upgrade choices, collect power-ups, and survive as long as possible.

## Controls

- **WASD** - Move
- **SPACE** - Dash (invincibility frames during dash)

Combat is automatic - the player auto-aims and fires at the nearest enemy.

## Enemy Types

| Type | Description |
|------|-------------|
| **Normal** | Standard zombie, balanced stats |
| **Runner** | Fast but fragile, erratic movement |
| **Tank** | Slow but massive HP |
| **Brute** | Tougher than normal, deals more damage |
| **Exploder** | Rushes and explodes on contact or death |
| **Spitter** | Ranged enemy that keeps distance and fires projectiles |
| **Boss** | Massive HP, appears every 5 waves |

## Upgrade System

On level up, choose from 3 random upgrades:
- Max HP, Move Speed, Damage, Fire Rate, Bullet Speed
- Multi-Shot, Piercing Rounds, Explosive Rounds, Homing Rounds
- Dash Cooldown Reduction, Vampire (heal on kill), Critical Chance
- Force Shield (absorb damage), Scholar (XP multiplier)

## Power-ups

- **Speed** (cyan) - Move 42% faster for 10s
- **Damage** (orange) - Deal 42% more damage for 10s
- **Shield** (yellow) - Absorb next hit
- **Magnet** (magenta) - Pull XP orbs from far away for 10s

---

## File Reference

### Core Files

#### `project.godot`
Godot project configuration file. Sets window size to 1280x720, main scene to `main.tscn`, and enables Forward Plus renderer.

#### `main.tscn`
Scene file containing the root Main node that loads `main.gd`.

#### `main.gd`
Main game controller and manager. Handles wave spawning, UI, upgrades, game state, and coordinates all game systems.

**Constants:**
- `PlayerScript`, `ZombieScript`, `ParticleScript`, `XpOrbScript`, `FloatyScript`, `PowerupScript`, `EnemyBulletScript` - Preloaded scripts for spawning entities
- `MILESTONES` - Array of kill counts for milestone announcements [10, 25, 50, 100, 200, 350, 500]

**Game State Variables:**
- `wave` - Current wave number
- `kills` - Total zombies killed
- `time_alive` - Survival time in seconds
- `spawn_remaining` - Zombies left to spawn in current wave
- `spawn_timer`, `spawn_interval` - Spawn timing control
- `wave_active` - Whether a wave is currently in progress
- `between_wave_timer` - Countdown between waves
- `boss_alive`, `boss_ref` - Boss tracking
- `streak`, `streak_timer` - Kill streak tracking
- `game_over` - Game over state flag
- `wave_total`, `wave_start_kills` - Wave progress tracking
- `_next_milestone` - Index of next kill milestone

**Node References:**
- `player` - Player character instance
- `camera` - Camera2D attached to player
- `enemies_node`, `bullets_node`, `enemy_bullets_node`, `orbs_node`, `effects_node`, `powerups_node` - Container nodes for spawned entities
- `ui_layer` - CanvasLayer for UI elements

**UI References:**
- `hp_bar`, `xp_bar` - Player status bars
- `wave_lbl`, `kills_lbl`, `lvl_lbl`, `time_lbl` - Stats labels
- `streak_lbl`, `boost_lbl` - Active effect displays
- `msg_lbl` - Center screen message display
- `upgrade_panel` - Level-up upgrade selection UI
- `boss_bar_panel`, `boss_bar` - Boss health display
- `wave_prog_bar` - Wave progress bar
- `low_hp_overlay` - Red flash effect when HP is low

**Camera:**
- `shake_amt` - Current screen shake intensity

**Functions:**
- `_ready()` - Initializes input mapping, world, player, and UI
- `_add_wasd()` - Adds WASD key mappings to ui_left/right/up/down actions
- `_setup_world()` - Creates background, random terrain details, and entity containers
- `_spawn_player()` - Creates player instance and attaches camera
- `_setup_ui()` - Builds all UI elements including bars, labels, and panels
- `_lbl()`, `_bar()` - Helper functions to create Label and ProgressBar nodes
- `_process(delta)` - Main game loop handling UI updates, waves, messages, shake, streaks
- `_update_ui()` - Updates all UI elements based on game state
- `_update_streak(delta)` - Decays kill streak timer
- `_update_shake(delta)` - Applies camera shake with decay
- `_update_boss_bar()` - Updates boss health bar
- `_handle_waves(delta)` - Manages wave spawning and transitions
- `_start_wave()` - Begins a new wave with appropriate enemy count
- `_pick_type()` - Selects zombie type based on wave number and random chance
- `_spawn_zombie()` - Creates and configures a zombie enemy
- `_spawn_boss()` - Spawns a boss zombie every 5 waves
- `_make_boss_bar(boss)` - Creates boss health bar UI
- `_on_zombie_died(pos, xp_val)` - Handles zombie death: XP, streaks, milestones, power-up drops
- `_on_boss_died(pos, xp_val)` - Handles boss death with enhanced effects and rewards
- `_on_zombie_damaged(amount, pos, is_crit)` - Shows floating damage text
- `_on_player_hit()` - Triggers screen shake on player damage
- `_on_exploder_detonated(pos, radius, dmg)` - Handles exploder explosion with AoE damage
- `_on_spitter_fired(from_pos, direction, dmg)` - Creates enemy projectile
- `_spawn_powerup(pos)` - Spawns random power-up at position
- `_on_powerup_collected(type, pos)` - Shows floating text for collected power-ups
- `_burst(pos, col, count)` - Spawns particle burst effect
- `_spawn_orb(pos, xp_val)` - Creates XP orb at position
- `_floaty(pos, text, col, size, life)` - Creates floating text effect
- `_on_level_up(_lv)` - Triggers level-up effects and upgrade menu
- `_show_upgrade_menu()` - Displays upgrade selection UI and pauses game
- `_upgrade_pool()` - Returns available upgrades filtered by already-acquired ones
- `_apply_upgrade(u)` - Applies selected upgrade to player and resumes game
- `_calc_score()` - Calculates final score based on kills, wave, level, and time
- `_calc_grade(score)` - Returns letter grade (S+ to F) based on score
- `_on_player_died()` - Shows game over screen with stats and restart button
- `_restart()` - Reloads current scene to restart game
- `_show_msg(text, dur)` - Displays center screen message
- `_handle_msg(delta)` - Decays message timer

---

#### `player.gd`
Player character controller. Handles movement, dashing, auto-aim shooting, damage, leveling, and visual effects.

**Signals:**
- `leveled_up(new_level)` - Emitted when player gains a level
- `died` - Emitted when player HP reaches zero
- `took_damage` - Emitted when player takes damage

**Stats:**
- `max_hp`, `hp` - Health (default 100)
- `speed` - Movement speed (default 200)
- `damage` - Bullet damage (default 25)
- `fire_rate` - Seconds between shots (default 0.5)
- `bullet_speed` - Projectile speed (default 500)
- `xp`, `xp_needed` - Current and required XP for next level
- `level` - Current player level
- `multi_shot` - Number of bullets per shot (default 1)
- `piercing` - Whether bullets pass through enemies
- `heal_per_kill` - HP restored per zombie kill
- `crit_chance`, `crit_mult` - Critical hit chance (default 8%) and multiplier (2.2x)
- `has_explosive` - Whether bullets explode on impact
- `has_homing` - Whether bullets track enemies
- `xp_mult` - XP gain multiplier (default 1.0)
- `force_shield` - Absorbable damage shield HP

**Boost Timers:**
- `boost_speed_timer` - Speed boost duration
- `boost_damage_timer` - Damage boost duration
- `boost_shield_timer` - One-hit shield duration
- `boost_magnet_timer` - XP magnet duration

**Node References:**
- `enemies_node`, `bullets_node`, `effects_node` - Containers for spawning entities

**Combat State:**
- `fire_timer` - Cooldown between shots
- `iframes` - Invincibility frames after taking damage
- `damage_flash` - Visual flash duration on damage
- `gun_angle` - Current aim angle
- `lvlup_ring` - Level-up visual ring timer

**Dash State:**
- `dash_speed`, `dash_duration`, `dash_cooldown` - Dash parameters
- `_dash_timer`, `_dash_cd` - Current dash and cooldown timers
- `_dashing` - Whether currently dashing
- `_dash_dir` - Dash direction vector

**Functions:**
- `_ready()` - Sets up collision layer/mask and creates hitbox
- `_draw()` - Renders player: body, gun barrel, dash cooldown arc, active boosts, level-up ring, force shield, damage flash
- `_physics_process(delta)` - Main update: timers, dash handling, movement, shooting, aim updates
- `_handle_dash(delta)` - Processes dash movement and activation
- `_move()` - Handles normal movement with WASD input
- `_update_gun_angle()` - Aims at nearest enemy
- `_auto_shoot(delta)` - Fires at nearest enemy when off cooldown
- `_nearest_enemy()` - Finds closest valid enemy
- `_fire(dir, target)` - Creates bullet(s) with all player modifiers applied
- `take_damage(amount)` - Processes damage with shield/buff priority, emits signals
- `gain_xp(amount)` - Adds XP with multiplier, handles level-ups

---

#### `zombie.gd`
Enemy zombie controller with multiple types and behaviors.

**Signals:**
- `died_at(pos, xp_val)` - Emitted when zombie dies
- `damaged(amount, pos, is_crit)` - Emitted when taking damage
- `exploded(pos, radius, dmg)` - Emitted by exploders on detonation
- `fired_projectile(from_pos, direction, dmg)` - Emitted by spitters when shooting

**Base Properties:**
- `player` - Reference to player node
- `zombie_type` - Type string: "normal", "runner", "tank", "brute", "exploder", "spitter", "boss"
- `radius` - Collision/Visual size
- `body_color`, `eye_color` - Visual colors
- `hp`, `max_hp` - Health values
- `speed` - Movement speed
- `damage` - Contact damage
- `xp_value` - XP awarded on death
- `contact_timer` - Cooldown between contact damage ticks
- `wobble_offset` - Random movement variation
- `_flash` - Damage flash timer

**Type-Specific:**
- `spit_timer`, `spit_interval`, `preferred_dist` - Spitter behavior
- `explode_radius` - Exploder blast radius
- `_pulse` - Exploder visual pulse timer

**Functions:**
- `configure(type, wave)` - Sets up zombie based on type and scales stats by wave number
- `_ready()` - Sets collision and creates hitbox
- `_draw()` - Renders zombie body, eyes, HP bar, type-specific visuals (spikes, pulses, charge rings)
- `_physics_process(delta)` - Movement AI based on type, contact damage, spitter firing
- `_trigger_explode()` - Detonates exploder zombie with AoE damage
- `take_damage(amount, crit)` - Applies damage with flash effect, handles death

---

### Projectiles

#### `bullet.gd`
Player bullet projectile with various upgrade modifiers.

**Properties:**
- `direction` - Movement vector
- `speed` - Projectile speed
- `damage` - Damage dealt on hit
- `lifetime` - Seconds before auto-destruct
- `piercing` - Whether bullet continues through enemies
- `is_crit` - Whether this was a critical hit
- `is_explosive` - Whether bullet explodes on impact
- `aoe_radius` - Explosion radius (82.0)
- `homing_target` - Target node for homing bullets
- `enemies_node`, `effects_node` - Containers for explosion effects
- `_hit_ids` - Array tracking already-hit enemies (for piercing)

**Functions:**
- `_ready()` - Sets up collision and connects hit signal
- `_draw()` - Renders bullet with trail, crit size/color, explosive indicator
- `_process(delta)` - Updates homing, moves bullet, decays lifetime
- `_on_hit(body)` - Applies damage, handles piercing/explosive behavior
- `_do_explosion()` - Creates AoE damage and particle burst

---

#### `enemy_bullet.gd`
Spitter projectile that damages the player.

**Properties:**
- `direction` - Movement vector
- `speed` - Projectile speed (230)
- `damage` - Damage dealt (12)
- `lifetime` - Seconds before auto-destruct (3.5)
- `player_ref` - Reference to player for collision
- `_bob` - Visual bobbing timer

**Functions:**
- `_process(delta)` - Moves bullet, checks player collision, decays lifetime
- `_draw()` - Renders pulsing green projectile with trail

---

### Collectibles

#### `xp_orb.gd`
Experience orb dropped by defeated enemies.

**Properties:**
- `xp_value` - XP amount granted on collection
- `player` - Reference to player
- `speed` - Current movement velocity
- `bob_timer` - Visual pulse timer
- `color` - Orb color (green)

**Functions:**
- `_ready()` - Randomizes bob timer start
- `_draw()` - Renders pulsing orb with white center
- `_process(delta)` - Updates animation, applies magnet attraction, handles collection

---

#### `powerup.gd`
Temporary buff pickup dropped randomly from enemies (7% chance).

**Signals:**
- `collected(type, pos)` - Emitted when picked up

**Properties:**
- `type` - Power-up type: "speed", "damage", "shield", "magnet"
- `player` - Reference to player
- `lifetime` - Seconds before despawning (12)
- `bob_timer` - Visual animation timer
- `_done` - Whether already collected

**Functions:**
- `_ready()` - Randomizes bob timer
- `_process(delta)` - Updates animation, checks player proximity, handles collection/despawn
- `_collect()` - Applies buff to player based on type and emits signal
- `_draw()` - Renders colored orb with spin indicators and fade when expiring

---

### Effects

#### `floaty_text.gd`
Floating text effect for damage numbers and notifications.

**Properties:**
- `text` - String to display
- `color` - Text color
- `font_size` - Text size
- `lifetime` - Seconds to live (1.1)
- `_age` - Current age
- `_vel` - Velocity vector (random horizontal, upward)

**Functions:**
- `_ready()` - Initializes random horizontal velocity
- `_draw()` - Renders text with pop-in and fade-out
- `_process(delta)` - Updates position with gravity, decays lifetime

---

#### `particle.gd`
Simple physics particle for explosion/burst effects.

**Properties:**
- `vel` - Velocity vector
- `life`, `init_life` - Remaining and initial lifetime
- `size` - Particle size
- `color` - Particle color

**Functions:**
- `_process(delta)` - Updates position with drag and gravity, decays lifetime
- `_draw()` - Renders fading square particle

---

## License

This project is open source. Feel free to use, modify, and distribute.
