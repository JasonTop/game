# Level System Architecture

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                       Level01 (Root)                        │
│  - Sets up all zones, destructibles, background            │
│  - Listens to zone_cleared signals                         │
│  - Emits level_complete when all zones done                │
└─────────────────────────────────────────────────────────────┘
         │                      │                      │
         ├──────────────┬───────┴────────┬────────────┤
         ▼              ▼                ▼            ▼
    ┌────────┐    ┌──────────┐    ┌──────────────┐   ┌────────┐
    │ Player │    │  Camera  │    │ CombatZones  │   │Effects │
    │        │    │Controller│    │              │   │(global)│
    └────────┘    └──────────┘    └──────────────┘   └────────┘
         │              │               │                │
    Position      Follows Player   Spawns Enemies   Spawned on
    Movement      Tracks Y bounds   Locks Camera    hit/collect
         │              │               │                │
         └──────────────┴───────────────┴────────────────┘
                    Visual Output to Screen
```

## Component Interaction

### 1. Player → Hit Enemy

```
Player Attack Input
    ↓
Player Hitbox Area2D collides with Enemy Hurtbox
    ↓
Enemy.take_damage(amount)
    ↓
├─ EffectSpawner.spawn_hit_effect(enemy.position)
├─ EffectSpawner.spawn_damage_number(enemy.position, amount)
├─ EffectSpawner.play_sfx("res://sounds/hit.ogg")
├─ Camera.screen_shake(0.5)
    ↓
Enemy emits died() signal when health reaches 0
    ↓
CombatZone._on_enemy_died() increments enemies_alive counter
    ↓
If all enemies spawned and all dead → zone_cleared signal
    ↓
Level01._on_zone_cleared() increments completion counter
    ↓
If all zones cleared → level_complete signal
```

### 2. Player Enters Combat Zone

```
Player moves into CombatZone Area2D
    ↓
CombatZone._on_body_entered(player)
    ↓
CombatZone.activate()
    ↓
├─ CameraController.lock_to_zone(left_bound, right_bound)
├─ zone_activated signal emitted
│
└─ Start spawn timer for enemies
    ↓
Each spawn_delay seconds:
    Instantiate enemy from enemy_scenes array
    Position at random offset within zone
    Add to scene tree
    Connect to enemy.died signal
    enemies_alive counter incremented
```

### 3. Player Collects Item

```
Player CharacterBody2D collides with Pickup Area2D
    ↓
Pickup._on_body_entered(player)
    ↓
Pickup.collect(player)
    ↓
├─ Apply effect based on pickup_type
│  ├─ HEALTH: player.heal(value)
│  ├─ STAR: GameManager.add_stars(value)
│  └─ MONEY: GameManager.add_money(value)
│
├─ Play collection sound
├─ Play collection animation
├─ collected signal emitted
│
└─ queue_free() after animation
```

### 4. Player Hits Destructible

```
Player Hitbox Area2D collides with Destructible Hurtbox
    ↓
Destructible._on_hurtbox_hit(attack_area)
    ↓
Destructible.take_damage(1)
    ↓
├─ current_health -= 1
├─ Update sprite frame (0=intact, 1=cracked, 2=broken)
├─ EffectSpawner.spawn_hit_effect(position)
├─ Play hit sound
├─ health_changed signal emitted
│
└─ If health <= 0: destroy()
    ├─ Play break animation
    ├─ Spawn drop item (if drop_chance passes)
    ├─ destroyed signal emitted
    └─ queue_free()
```

### 5. Camera System

```
Player moves via input
    ↓
CameraController._process()
    ↓
├─ Get player.global_position
├─ If zone_locked: clamp X to zone bounds
├─ Clamp Y to walkable_y_min/max (keeps player in "floor" band)
├─ Lerp current position toward target (smoothing)
├─ Apply screen_shake offset if active
│
└─ Update Camera2D.global_position
    ↓
Viewport follows camera
    ↓
All nodes with z_index rendered in order
```

## Signal Flow Chart

```
Level01
├─ zone_activated(zone_index)
│  └─ Fired when player enters CombatZone
│
├─ zone_cleared(zone_index)
│  └─ Fired when all enemies in zone defeated
│
└─ level_complete()
   └─ Fired when all zones cleared

CombatZone
├─ zone_activated()
│  ├─ Camera locks to zone
│  └─ Enemy spawn begins
│
├─ zone_cleared()
│  ├─ Camera unlocks
│  ├─ Level listens and increments counter
│  └─ Show GO arrow
│
└─ enemy_spawned(enemy)
   └─ Emitted when each enemy instantiated

Enemy (implicit in system)
├─ died()
│  └─ CombatZone listens and decrements enemies_alive
│
└─ health_changed(value)
   └─ Optionally displayed in UI

Destructible
├─ health_changed(new_health)
│  └─ UI updates health display
│
└─ destroyed()
   └─ Level tracks for completion stats

Pickup
└─ collected(type, value)
   └─ UI/HUD listens for stat display

CameraController
├─ zone_entered()
│  └─ When zone locked
│
└─ zone_exited()
   └─ When zone unlocked
```

## Class Hierarchy

```
Node2D (root)
├─ Level01
│  ├─ CameraController (Camera2D)
│  │  └─ Signals: zone_entered, zone_exited
│  │
│  ├─ CombatZone[5] (Area2D)
│  │  ├─ CollisionShape2D (RectangleShape2D)
│  │  └─ Signals: zone_activated, zone_cleared, enemy_spawned
│  │
│  ├─ Destructible[n] (StaticBody2D)
│  │  ├─ Sprite2D
│  │  ├─ StaticBody2D (collision body)
│  │  │  └─ CollisionShape2D
│  │  └─ Hurtbox (Area2D)
│  │     └─ CollisionShape2D
│  │
│  └─ Background
│     ├─ ColorRect (sky)
│     ├─ ColorRect (far buildings)
│     └─ ColorRect (mid buildings)
│
├─ Player (CharacterBody2D) [managed externally]
│
└─ EffectSpawner [Autoload]
   ├─ Spawns HitEffect (Sprite2D)
   ├─ Spawns Label (damage numbers)
   ├─ Spawns Pickup (Area2D)
   ├─ Spawns GPUParticles2D
   └─ Spawns AudioStreamPlayer

Pickup (Area2D)
├─ CollisionShape2D (CircleShape2D)
├─ Sprite2D
└─ Signals: collected

HitEffect (Sprite2D)
└─ Self-deletes after animation

Destructible Hurtbox (Area2D)
└─ Detects "player_attack" group Area2Ds
```

## Godot Groups Used

| Group | Type | Usage |
|-------|------|-------|
| `player` | Node2D | Identifies the player character |
| `player_attack` | Area2D | Player's hitbox (attacks) |
| `enemy` | Node2D | All enemies |
| `camera` | CameraController | Single camera controller |
| `level` | Level01 | Current level node |

## Message Passing Patterns

### Pattern 1: Area2D Collision Signals
```gdscript
# CombatZone
body_entered.connect(_on_body_entered)  # Detects player

# Destructible's Hurtbox
area_entered.connect(_on_hurtbox_hit)   # Detects attacks

# Pickup
body_entered.connect(_on_body_entered)  # Detects player
```

### Pattern 2: Custom Signals
```gdscript
# Enemy emits:
died.emit()

# CombatZone listens:
enemy.died.connect(_on_enemy_died)

# Level listens:
zone.zone_cleared.connect(_on_zone_cleared)
```

### Pattern 3: Autoload Global
```gdscript
# Anyone can call:
EffectSpawner.spawn_hit_effect(position)

# Because EffectSpawner is in Autoload
extends Node  # Singleton
```

### Pattern 4: Direct Property Access
```gdscript
# Camera access via group:
var camera = get_tree().get_first_node_in_group("camera")
camera.screen_shake(1.0)

# Direct method calls:
destructible.take_damage(1)
camera.lock_to_zone(left, right)
```

## Memory Management

- **HitEffect**: Self-deletes after ~200ms animation
- **Damage Numbers**: Self-delete after 0.8s animation
- **Pickups**: queue_free() after collection animation
- **Enemies**: Should queue_free() when died() emitted
- **Destructibles**: queue_free() after break animation
- **EffectSpawner**: Keeps EffectContainer, reuses for spawning
- **Level**: Persists until scene change

## Performance Considerations

### Optimization Points
1. **Zone Lock**: Camera only updates zone_locked clamp (O(1))
2. **Enemy Spawning**: Delayed by spawn_delay (prevents spike)
3. **Physics**: Destructibles use StaticBody2D (no velocity calc)
4. **Audio**: Temp AudioStreamPlayers deleted after playback
5. **Particles**: Use GPUParticles2D, not CPU emitters

### Scalability
- Can handle 5+ zones without issue
- Enemy count per zone: 8+ with good performance
- Simultaneous effects: 50+ acceptable
- Y-sort on 4000px level: no overhead (built-in)

## Extension Points

### To Add Custom Zone Logic
```gdscript
# In Level01
func _on_zone_activated(zone_index: int):
    # Play zone intro sound
    # Change music
    # Show zone name UI
```

### To Add Custom Enemy Types
```gdscript
# Create new scene, instantiate in Level01
zone_configs[0]["enemies"].append(new_enemy_scene)

# Ensure new enemy has:
# - died() signal
# - take_damage() method
```

### To Add Custom Pickups
```gdscript
# Add type to Pickup enum
enum PickupType { HEALTH, STAR, MONEY, AMMO }

# Add case to Pickup._apply_effect()
AMMO: player.add_ammo(value)

# Add case to EffectSpawner.spawn_pickup()
Pickup.PickupType.AMMO: scene_path = "res://..."
```

### To Add Level Progression
```gdscript
# In Level01._on_level_complete()
level_complete.emit()
await get_tree().create_timer(2.0).timeout
get_tree().change_scene_to_file("res://scenes/levels/level_02.tscn")
```
