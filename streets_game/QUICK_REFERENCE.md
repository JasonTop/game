# Quick Reference Guide
# 快速参考指南

## File Locations

### Character Classes
- **BaseCharacter**: `/scripts/characters/base_character.gd`
- **Player**: `/scripts/characters/player_controller.gd`
- **EnemyBase**: `/scripts/characters/enemy_base.gd`
- **EnemyGoon**: `/scripts/characters/enemy_goon.gd`
- **EnemyHeavy**: `/scripts/characters/enemy_heavy.gd`
- **EnemySlasher**: `/scripts/characters/enemy_slasher.gd`
- **EnemyThrower**: `/scripts/characters/enemy_thrower.gd`

### State Classes
- **State (Base)**: `/scripts/state_machine/state.gd`
- **StateMachine**: `/scripts/state_machine/state_machine.gd`

### Player States
- `player_idle_state.gd`
- `player_walk_state.gd`
- `player_attack_state.gd`
- `player_jump_state.gd`
- `player_dash_state.gd`
- `player_grab_state.gd`
- `player_special_state.gd`
- `player_star_move_state.gd`
- `player_hit_state.gd`
- `player_knockdown_state.gd`

### Enemy States
- `enemy_idle_state.gd`
- `enemy_approach_state.gd`
- `enemy_attack_state.gd`
- `enemy_dash_attack_state.gd`
- `enemy_retreat_state.gd`
- `enemy_hit_state.gd`
- `enemy_knockdown_state.gd`
- `enemy_death_state.gd`

All state files are in `/scripts/state_machine/states/`

## Common Code Snippets

### Get Player Reference
```gdscript
var player = get_tree().get_first_child_in_group("player") as Player
```

### Get SpawnManager
```gdscript
var spawn_manager = get_node("SpawnManager")
```

### Spawn Enemy
```gdscript
var enemy = spawn_manager.spawn_enemy("goon", Vector2(400, 300))
```

### Damage Player
```gdscript
player.take_damage(10, Vector2(-200, 0))  # damage, knockback
```

### Damage Enemy
```gdscript
enemy.take_damage(20, Vector2(150, -50))
```

### Transition State
```gdscript
state_machine.transition_to("PlayerIdleState")
```

### Check Player Health
```gdscript
if player.health < 30:
    player.use_special()
```

### Add Star to Player
```gdscript
player.gain_star()
print("Stars: %d" % player.star_count)
```

### Get Distance to Player
```gdscript
var distance = enemy.get_distance_to_target()
if distance < 100:
    enemy.face_target()
```

### Request Attack Slot
```gdscript
if spawn_manager.request_attack_slot():
    # Do attack
    spawn_manager.release_attack_slot()
```

## Common Properties

### Player
```gdscript
player.health              # Current health
player.max_health          # Maximum health
player.speed               # Movement speed (150)
player.dash_speed          # Dash speed (400)
player.jump_height         # Jump visual height (100)
player.combo_step          # Current combo number (0-3)
player.star_count          # Number of stars available
player.facing_direction    # 1.0 or -1.0
player.is_alive            # true/false
player.is_invincible       # true/false
player.is_jumping          # true/false
player.is_grabbing         # true/false
player.grab_target         # Grabbed enemy reference
```

### Enemy
```gdscript
enemy.health               # Current health
enemy.max_health           # Maximum health
enemy.speed                # Movement speed
enemy.target               # Player reference
enemy.detection_range      # Range to detect player
enemy.attack_range         # Range to attack
enemy.facing_direction     # 1.0 or -1.0
enemy.is_alive             # true/false
enemy.has_attack_slot      # Currently attacking
enemy.can_attack           # Cooldown ready
```

## Enemy Stats Reference

### Goon
- Speed: 120
- Health: 60
- Damage: 8
- Behavior: Walk toward player, punch

### Heavy
- Speed: 60
- Health: 150
- Damage: 20
- Behavior: Tank with super armor, strong hits

### Slasher
- Speed: 200
- Health: 40
- Damage: 12
- Behavior: Dash attacks from distance

### Thrower
- Speed: 80
- Health: 45
- Damage: 10
- Behavior: Stay back and throw projectiles

## Animation Names Required

### Player
- idle
- walk
- punch1, punch2, punch3
- jump
- dash
- grab, grab_punch
- special_move
- star_move
- hit
- knockdown
- death

### Enemies
- idle
- walk
- attack
- (dash_attack for slasher)
- hit
- knockdown
- death

## Input Actions

```
move_left      - A / Left Arrow
move_right     - D / Right Arrow
move_up        - W / Up Arrow
move_down      - S / Down Arrow
attack         - Space / Z
jump           - J / X
dash           - Shift / C
grab           - G / V
special        - Q / E
star_move      - R / F
```

## Movement Formula

**Y-Speed Ratio Calculation:**
```
input_direction = (dx, dy).normalized()
adjusted_y = dy * 0.6
final_velocity = (input_direction.x * speed, adjusted_y * speed).normalized() * speed
```

## Collision Setup

```
Layer 1: World
Layer 2: Attacking (Hitboxes)
Layer 3: Hurtable (Hurtboxes)
Layer 4: Player
Layer 5: Enemies

Hitbox: Layer 2, Mask 3
Hurtbox: Layer 3, Mask 2
```

## Signals to Listen

```gdscript
player.died.connect(_on_player_died)
player.health_changed.connect(_on_health_changed)
player.took_damage.connect(_on_took_damage)

enemy.died.connect(_on_enemy_died)
enemy.health_changed.connect(_on_health_changed)
```

## State Transition Map

### Player States
```
Idle ←→ Walk
  ↓ (input)
  Attack → Idle
  Jump → Idle
  Dash → Idle
  Grab → Idle
  Special → Idle
  Star Move → Idle

Any state + damage → Hit → Idle
Any state + heavy damage → Knockdown → Idle
Any state (health <= 0) → Death
```

### Enemy States
```
Idle → Approach → Attack → Approach
         ↓ (out of range)
         Idle

Approach → Dash Attack (Slasher)
         → Retreat (Thrower)

Any + damage → Hit → Approach
Any + heavy damage → Knockdown → Approach
Any (health <= 0) → Death
```

## Tips for Implementation

1. **Enable Y-Sorting**: In your main scene/camera, enable Y-sorting so characters render in correct depth order.

2. **Set Initial States**: Make sure StateMachine has PlayerIdleState set as initial_state.

3. **Connect Signals Early**: Connect death signals in _ready() of spawn manager.

4. **Test Collision**: Use debug collision view to verify hitbox/hurtbox placement.

5. **Adjust Speeds**: Tweak speed values if movement feels too fast or slow.

6. **Combo Window**: 0.5 seconds is fast - test and adjust if needed.

7. **Knockback Direction**: Use Vector2(facing_direction * distance, vertical_component).

8. **Attack Slots**: Default 3 slots is good for most cases. Adjust based on difficulty.

## Debugging

```gdscript
# Print character state
print("Current state: %s" % state_machine.current_state.name)

# Print enemy count
print("Active enemies: %d" % spawn_manager.get_active_enemy_count())

# Print player status
print("Health: %d/%d, Stars: %d, Combo: %d" % [
    player.health, player.max_health, player.star_count, player.combo_step
])

# Check attack slots
print("Active attacks: %d/%d" % [
    spawn_manager.active_attack_count, spawn_manager.attack_slots
])

# Check distance
print("Distance to player: %.0f" % enemy.get_distance_to_target())
```

## Performance Notes

- Using Y-sort for 50+ characters may impact performance
- Consider culling off-screen enemies
- Attack slot system reduces simultaneous calculations
- State machines are lightweight (just enter/exit/process)

## Common Mistakes to Avoid

1. ❌ Forgetting to add states as children of StateMachine
2. ❌ Not setting Hitbox/Hurtbox collision layers/masks
3. ❌ Trying to move during grab state (should be blocked)
4. ❌ Not calling release_attack_slot() after enemy attacks
5. ❌ Animation names don't match the state code
6. ❌ Forgetting to enable Y-Sort in the viewport
7. ❌ Setting invincibility but never turning it off
8. ❌ Not connecting player reference to enemies

## Next Steps

1. Create character sprites/animations
2. Set up scene hierarchy with nodes
3. Assign scripts to nodes
4. Configure collision layers/masks
5. Create animations in AnimationPlayer
6. Test player movement and attacks
7. Spawn enemies and test AI
8. Balance stats and difficulty
9. Add visual polish (particles, camera shake, etc.)

## Resources

- **Godot Docs**: https://docs.godotengine.org/
- **GDScript Guide**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- **State Machine Pattern**: https://gameprogrammingpatterns.com/state.html
- **Beat 'em Up Design**: Classic games like Streets of Rage, Final Fight, Double Dragon
