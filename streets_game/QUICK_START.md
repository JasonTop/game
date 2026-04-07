# Quick Start - Level System

## 5-Minute Setup

### Step 1: Add EffectSpawner to Autoload
1. Open Project Settings > Autoload
2. Click "Add" and select `res://scripts/systems/effect_spawner.gd`
3. Name it `EffectSpawner`

### Step 2: Create Your First Level Scene
```gdscript
# scene: res://scenes/levels/level_01.tscn
extends Node2D

func _ready():
    # CameraController and Level01 will be created automatically
    var level = Level01.new()
    level.player_spawn_position = Vector2(200, 360)
    add_child(level)
```

### Step 3: Ensure Player is Set Up
Your player script must:
```gdscript
extends CharacterBody2D

func _ready():
    add_to_group("player")

    # Create attack box
    var attack_box = Area2D.new()
    attack_box.add_to_group("player_attack")
    add_child(attack_box)
```

## Essential File Locations

| File | Purpose |
|------|---------|
| `scripts/systems/camera_controller.gd` | Camera following & screen shake |
| `scripts/systems/effect_spawner.gd` | Global effect spawning |
| `scripts/level/level_01.gd` | Main level setup |
| `scripts/level/combat_zone.gd` | Enemy spawn zones |
| `scripts/level/destructible.gd` | Breakable objects |
| `scripts/level/pickup.gd` | Collectible items |
| `scripts/level/hit_effect.gd` | Visual hit feedback |

## Core Classes

### CameraController
```gdscript
# Usage in your player or enemy hit code
var camera = get_tree().get_first_node_in_group("camera") as CameraController
camera.screen_shake(1.0)  # Strength 0-2
```

### CombatZone
```gdscript
# Automatically triggered when player enters Area2D
# Configure in Level01._create_combat_zone()
zone.enemy_scenes = [goon_scene, goon_scene, slasher_scene]
zone.spawn_delay = 0.5  # Seconds between spawns
```

### EffectSpawner (Autoload)
```gdscript
# Use anywhere in your code
EffectSpawner.spawn_hit_effect(position)
EffectSpawner.spawn_damage_number(position, 25)
EffectSpawner.play_sfx("res://sounds/hit.ogg", position)
```

### Destructible
```gdscript
# Takes damage from Area2Ds in "player_attack" group
destructible.take_damage(1)  # Emits health_changed signal
# Drops items with drop_chance probability
```

### Pickup
```gdscript
# Types: HEALTH, STAR, MONEY
var pickup = Pickup.new()
pickup.pickup_type = Pickup.PickupType.HEALTH
pickup.value = 30
pickup.global_position = position
add_child(pickup)
```

## Level01 Zone Setup

5 zones automatically generated with enemies:

| Zone | Enemy Composition |
|------|-------------------|
| 1 | 3 Goons (tutorial) |
| 2 | 4 Goons + 1 Slasher |
| 3 | 2 Goons + 2 Throwers + 1 Heavy |
| 4 | 3 Goons + 2 Slashers + 1 Thrower |
| 5 | 1 Heavy + 2 Goons → 2 Heavies (boss) |

## Common Integration Points

### When Player Hits Enemy
```gdscript
# In your player attack code
var enemies_hit = attack_area.get_overlapping_bodies()
for enemy in enemies_hit:
    if enemy.is_in_group("enemy"):
        EffectSpawner.spawn_hit_effect(enemy.global_position)
        EffectSpawner.spawn_damage_number(enemy.global_position, damage)
        enemy.take_damage(damage)
```

### When Enemy Dies
```gdscript
# In your enemy script
func die():
    EffectSpawner.spawn_particles(global_position, "blood")
    if randf() < 0.5:  # 50% drop chance
        EffectSpawner.spawn_pickup(global_position, Pickup.PickupType.HEALTH)
    died.emit()
    queue_free()
```

### When Zone Completes
```gdscript
# Automatically happens in Level01
# But you can listen to it:
level.zone_cleared.connect(func(zone_idx):
    print("Zone %d complete!" % zone_idx)
)
```

## Debug Features

### Check Zone Status
```gdscript
var level = get_tree().get_first_node_in_group("level") as Level01
var stats = level.get_level_stats()
print("Completed zones: %d/%d" % [stats.completed_zones, stats.zones])
```

### Pause Level
```gdscript
level.set_paused(true)   # Pauses game
level.set_paused(false)  # Resumes game
```

### Reset Level
```gdscript
level.reset_level()
```

## Quick Configuration

### Adjust Walking Area (Y constraints)
```gdscript
# In Level01 or directly on CameraController
camera_controller.walkable_y_min = 280.0  # Top
camera_controller.walkable_y_max = 450.0  # Bottom
```

### Adjust Level Width
```gdscript
# In Level01._ready()
total_width = 5000.0  # Default 4000
```

### Add More Zones
```gdscript
# In Level01._ready()
num_zones = 7  # Default 5
# Then update zone_configs array
```

## Expected Project Structure

```
project/
├── scripts/
│   ├── level/
│   │   ├── level_01.gd          ← Main level
│   │   ├── combat_zone.gd       ← Enemy zones
│   │   ├── destructible.gd      ← Breakables
│   │   ├── pickup.gd            ← Items
│   │   └── hit_effect.gd        ← Visual effects
│   └── systems/
│       ├── camera_controller.gd ← Camera
│       └── effect_spawner.gd    ← Effects (autoload)
├── scenes/
│   ├── enemies/
│   │   ├── goon.tscn
│   │   ├── slasher.tscn
│   │   ├── thrower.tscn
│   │   └── heavy.tscn
│   ├── player/
│   │   └── player.tscn
│   ├── levels/
│   │   └── level_01.tscn
│   └── pickups/
│       ├── health_pickup.tscn
│       └── star_pickup.tscn
└── sounds/
    └── sfx/
        ├── hit_object.ogg
        ├── pickup.ogg
        └── ...
```

## Troubleshooting

**Camera not following player?**
- Player must be in "player" group
- CameraController.follow_target must be set
- Player needs global_position

**Enemies not spawning?**
- Check enemy scene paths in Level01
- Verify PackedScenes aren't null
- Look at console warnings

**Pickups not working?**
- Player must be in "player" group
- Check Area2D collision layers
- Verify player has body_entered connected

**Effects not showing?**
- EffectSpawner must be in Autoload
- Check if sound files exist
- Verify z_index settings

For full documentation, see `LEVEL_SYSTEM_GUIDE.md`
