# Level System Guide - Streets of Rage Style Beat 'Em Up

## Overview

This level system provides a complete framework for a 2D beat 'em up game in Godot 4.x with Y-sorted depth, camera control, enemy spawning, destructibles, and pickups.

## Architecture

### Core Components

1. **CameraController** (`scripts/systems/camera_controller.gd`)
   - Follows the player with smooth lerp-based movement
   - Constrains Y movement to a walkable band (e.g., 280-450px)
   - Locks camera to combat zones during battles
   - Provides screen shake effects
   - Shows "GO!" prompt when zones are cleared

2. **CombatZone** (`scripts/level/combat_zone.gd`)
   - Area2D trigger that detects player entry
   - Spawns enemies with configurable delays
   - Tracks alive enemies
   - Locks camera when zone activates
   - Emits signals when zone is cleared
   - One-time trigger by default (configurable)

3. **Destructible** (`scripts/level/destructible.gd`)
   - StaticBody2D for breakable objects (barrels, crates)
   - Health system with visual feedback (3 sprite frames)
   - Drops items with probability
   - Hit effects and sound feedback
   - Accepts damage from player attacks

4. **Pickup** (`scripts/level/pickup.gd`)
   - Area2D for collectible items
   - Types: HEALTH, STAR, MONEY
   - Bobbing float animation
   - Glow/flash effects
   - Auto-applies effects to player
   - Plays collection sound and animation

5. **HitEffect** (`scripts/level/hit_effect.gd`)
   - Sprite-based visual feedback for hits
   - Expanding + fading animation
   - Procedural circle generation if no texture
   - Self-cleaning after animation

6. **EffectSpawner** (`scripts/systems/effect_spawner.gd`)
   - Autoload singleton for spawning effects
   - Methods:
     - `spawn_hit_effect(position)`
     - `spawn_damage_number(position, amount)`
     - `spawn_pickup(position, type)`
     - `spawn_particles(position, effect_type)`
     - `play_sfx(sound_path, position, volume_db)`
     - `screen_flash(duration, color)`

7. **Level01** (`scripts/level/level_01.gd`)
   - Main level scene script
   - Sets up 5 combat zones across 4000px
   - Manages player spawn
   - Creates destructible objects between zones
   - Zone configurations:
     - Zone 1: 3 Goons (tutorial)
     - Zone 2: 4 Goons + 1 Slasher
     - Zone 3: 2 Goons + 2 Throwers + 1 Heavy
     - Zone 4: 3 Goons + 2 Slashers + 1 Thrower
     - Zone 5: 1 Heavy + 2 Goons, then 2 Heavies (boss fight)

## Setup Instructions

### 1. Project Structure

Ensure your project has this structure:
```
starter_project/
├── scripts/
│   ├── systems/
│   │   ├── camera_controller.gd
│   │   └── effect_spawner.gd
│   └── level/
│       ├── level_01.gd
│       ├── combat_zone.gd
│       ├── destructible.gd
│       ├── pickup.gd
│       └── hit_effect.gd
├── scenes/
│   ├── enemies/
│   │   ├── goon.tscn
│   │   ├── slasher.tscn
│   │   ├── thrower.tscn
│   │   └── heavy.tscn
│   ├── pickups/
│   │   ├── health_pickup.tscn
│   │   ├── star_pickup.tscn
│   │   └── money_pickup.tscn
│   ├── effects/
│   │   ├── hit_effect.tscn
│   │   └── damage_number.tscn
│   └── player/
│       └── player.tscn
└── assets/
    └── sprites/
        └── barrel.png (optional)
```

### 2. Autoload Setup

In Project Settings > Autoload, add:
- **EffectSpawner**: `res://scripts/systems/effect_spawner.gd`

This makes the effect spawner globally accessible via `EffectSpawner.spawn_hit_effect()` etc.

### 3. Scene Setup

Create a main scene with:
1. A Node2D as root
2. Add `Level01` script to root node
3. Player scene as child (or will be created if missing)
4. CameraController will be created automatically if not found

```gdscript
# In your main scene
extends Node2D

func _ready():
    var level = Level01.new()
    add_child(level)
```

### 4. Player Requirements

Your player script should:
- Be in group "player": `add_to_group("player")`
- Implement attack box in group "player_attack"
- Have methods/properties:
  - `heal(amount)` or `current_health`/`max_health` properties
  - `global_position` for camera following

### 5. Enemy Requirements

Your enemy scripts should:
- Emit signal `died()` when killed
- Be positioned at `global_position`
- Have collision detection for attacks

## Usage Examples

### Spawning Effects

```gdscript
# Spawn hit effect at position
EffectSpawner.spawn_hit_effect(position)

# Spawn floating damage number
EffectSpawner.spawn_damage_number(position, 25)

# Spawn pickup item
EffectSpawner.spawn_pickup(position, Pickup.PickupType.HEALTH)

# Play sound effect
EffectSpawner.play_sfx("res://sounds/sfx/hit.ogg", position, 0.0)

# Screen flash
EffectSpawner.screen_flash(0.2, Color.WHITE)
```

### Creating Custom Zones

```gdscript
var zone = _create_combat_zone(
    x_position,
    y_position,
    "My Zone",
    [enemy_scene_1, enemy_scene_2, enemy_scene_3]
)
zone.zone_cleared.connect(_on_custom_zone_cleared)
```

### Camera Control

```gdscript
# Lock camera to zone
_camera_controller.lock_to_zone(left_bound, right_bound)

# Unlock camera
_camera_controller.unlock_zone()

# Screen shake
_camera_controller.screen_shake(strength)
```

### Managing Destructibles

```gdscript
var destructible = Destructible.new()
destructible.max_health = 3
destructible.global_position = position
destructible.destroyed.connect(_on_destructible_destroyed)
add_child(destructible)

# Damage it
destructible.take_damage(1)
```

### Managing Pickups

```gdscript
var pickup = Pickup.new()
pickup.pickup_type = Pickup.PickupType.HEALTH
pickup.value = 30
pickup.global_position = position
pickup.collected.connect(_on_pickup_collected)
add_child(pickup)
```

## Configuration

### Level01 Exports

- `player_spawn_position`: Where player starts (default: 200, 360)
- `total_width`: Total level width in pixels (default: 4000)
- `walkable_y_min`: Top of walkable area (default: 280)
- `walkable_y_max`: Bottom of walkable area (default: 450)
- `num_zones`: Number of combat zones (default: 5)

### CameraController Exports

- `follow_target`: The node to follow
- `smoothing`: Lerp smoothing 0-1 (default: 0.15)
- `walkable_y_min/max`: Y constraints
- `shake_amplitude`: Screen shake strength
- `shake_decay`: How quickly shake fades

### CombatZone Exports

- `enemy_scenes`: Array of enemy PackedScenes to spawn
- `spawn_delay`: Delay between spawns in seconds
- `zone_width`: Width of locked camera zone
- `one_time_trigger`: Trigger only once per level

## Signals & Events

### CombatZone Signals
- `zone_activated()` - Zone starts
- `zone_cleared()` - All enemies defeated
- `enemy_spawned(enemy)` - New enemy spawned

### Destructible Signals
- `destroyed()` - Object destroyed
- `health_changed(new_health)` - Health updated

### Pickup Signals
- `collected(type, value)` - Pickup collected

### Level01 Signals
- `level_complete()` - All zones cleared
- `zone_cleared(zone_index)` - Individual zone cleared

## Performance Tips

1. **Use Object Pooling**: Pre-spawn and reuse effects instead of creating new ones
2. **Limit Particles**: Use GPUParticles2D for large numbers of particles
3. **Audio Caching**: EffectSpawner caches pickup scenes
4. **Enemy Limits**: Limit simultaneous active enemies per zone
5. **Y-Sort**: Always use y_sort_enabled on the root Node2D for proper depth

## Common Issues

### Camera not following player
- Ensure player is in "player" group
- Check that player has `global_position` property
- Verify CameraController has `follow_target` set

### Enemies not spawning
- Check scene paths in Level01 match your project
- Verify PackedScenes are assigned to enemy_scenes array
- Look at console for warnings about missing scenes

### Pickups not being collected
- Ensure player is in "player" group
- Check Pickup's Area2D collision layer/mask
- Verify player body_entered is connecting properly

### Screen shake not working
- Verify GameManager exists in scene tree (optional)
- Test manual call: `_camera_controller.screen_shake(1.0)`
- Check shake_amplitude > 0

## Extending the System

### Add New Enemy Type
1. Create enemy scene/script
2. Add to enemy_scenes in Level01 or CombatZone
3. Implement `died` signal

### Add New Pickup Type
1. Add type to `Pickup.PickupType` enum
2. Create pickup scene
3. Add case in `Pickup._apply_effect()`
4. Add case in `EffectSpawner.spawn_pickup()`

### Add Level Progression
```gdscript
func _on_level_complete():
    # Load next level
    get_tree().change_scene_to_file("res://scenes/levels/level_02.tscn")
```

### Custom Zone Logic
Override `_on_zone_activated` or `_on_zone_cleared` in Level01.

## Chinese Comments Guide

The code includes bilingual comments. Key terms:
- 敌人 = enemy
- 摄像机 = camera
- 伤害 = damage/hurt
- 掉落 = drop
- 拾取 = pickup
- 破坏 = destroy/break
- 生命值 = health
- 精灵 = sprite
- 动画 = animation
- 信号 = signal

