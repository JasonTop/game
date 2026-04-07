# Streets of Rage Style Beat 'Em Up Character System
# 街头快打风格扯皮游戏角色系统

Complete GDScript implementation for a 2D beat 'em up game with Y-sort depth ordering.

## Files Created

### Core Character Scripts

#### `/scripts/characters/base_character.gd`
Base class for all characters (player and enemies)
- Health system with signals
- Invincibility mechanics
- Damage and knockback handling
- Hitbox/Hurtbox management
- Direction facing and speed control
- Flash white effect on hit

#### `/scripts/characters/player_controller.gd`
Player character controller extending BaseCharacter
- 8-directional movement with perspective ratio (Y = 60% of X)
- Combo system (punch1 → punch2 → punch3)
- Jump (visual effect, sprite moves up, shadow stays)
- Dash with invincibility startup
- Grab mechanics for stunned enemies
- Special move (costs HP, recovers on hits)
- Star move (super move, fully invincible)
- Input handling and buffering

#### `/scripts/characters/enemy_base.gd`
Base AI class for all enemies
- Target detection and tracking
- Attack slot system (limits simultaneous attacks)
- Distance calculations and range checking
- Face target direction
- Drop items on death (for subclasses)
- AI state management

### Enemy Variants

#### `/scripts/characters/enemy_goon.gd`
Basic thug enemy
- Speed: 120
- Health: 60
- Damage: 8
- Walks toward player, performs punch attacks

#### `/scripts/characters/enemy_heavy.gd`
Heavy/tank enemy
- Speed: 60
- Health: 150
- Damage: 20
- Super armor (low damage doesn't cause knockdown)
- Strong knockback on attacks

#### `/scripts/characters/enemy_slasher.gd`
Fast dashing enemy
- Speed: 200
- Health: 40
- Damage: 12
- Dashes at player from distance
- Uses attack slot for dash attack

#### `/scripts/characters/enemy_thrower.gd`
Ranged projectile enemy
- Speed: 80
- Health: 45
- Damage: 10
- Maintains distance and throws projectiles
- Uses attack slot for throwing

### Player States

Each state file handles one aspect of player behavior:

#### `player_idle_state.gd`
- Default state
- Listens for input to transition to other states
- Plays idle animation

#### `player_walk_state.gd`
- 8-directional movement
- Y-axis speed is 60% of X-axis
- Transitions to attack/jump/dash on input

#### `player_attack_state.gd`
- Combo chain system (punch1 → punch2 → punch3)
- Hitbox enabled during attack window
- Combo window timer for chaining attacks
- Returns to idle or continues combo

#### `player_jump_state.gd`
- Visual jump with parabolic arc
- Sprite moves up, shadow stays on ground
- Can attack mid-air
- Can move horizontally while jumping

#### `player_dash_state.gd`
- Quick forward dash
- Startup invincibility (0.2 seconds)
- Speed decay over 0.3 seconds
- Can attack during dash

#### `player_grab_state.gd`
- Hold grabbed enemy
- Pummel with attack button
- Throw with direction + attack button
- Can't move while grabbing

#### `player_special_state.gd`
- Costs 25 HP to use
- Flashy AoE attack
- Brief invincibility
- Recovers 5 HP per enemy hit
- Can't move during animation

#### `player_star_move_state.gd`
- Consumes 1 star power
- Fully invincible during attack
- Powerful damage (80)
- Higher knockback than special move
- Brief forward dash

#### `player_hit_state.gd`
- Hit stun state
- Applied when taking damage
- Brief invincibility during stun
- Applies knockback

#### `player_knockdown_state.gd`
- Knocked to ground
- Longer duration than hit state
- Invincible during getup (0.6 seconds)
- Returns to idle after animation

### Enemy States

#### `enemy_idle_state.gd`
- Wait state with timer
- Transitions to approach when target in range

#### `enemy_approach_state.gd`
- Moves toward target with Y-speed ratio
- Requests attack slot when in range
- Handles special enemy types:
  - Slasher: Triggers dash attack
  - Thrower: Handles retreat/throw logic

#### `enemy_attack_state.gd`
- Executes attack animation
- Deals damage mid-attack based on enemy type
- Releases attack slot when done
- Returns to approach state

#### `enemy_dash_attack_state.gd`
- Fast dash attack (for Slasher)
- Moves toward target during dash
- Deals damage mid-dash
- Decays speed over duration

#### `enemy_retreat_state.gd`
- Moves away from target
- Used by thrower to maintain distance
- Can throw projectiles while retreating

#### `enemy_hit_state.gd`
- Staggered by player attack
- Brief stun duration
- Releases attack slot
- Brief invincibility
- Returns to approach

#### `enemy_knockdown_state.gd`
- Knocked down state
- Longer duration than hit
- Invincible during getup (0.7 seconds)
- Releases attack slot

#### `enemy_death_state.gd`
- Death animation
- Fades out over time
- Queue_free after animation
- Releases attack slot

### State Machine

#### `/scripts/state_machine/state.gd`
Base state class (abstract)
- enter() - Called on state entry
- exit() - Called on state exit
- physics_process(delta) - Physics updates
- input_process(event) - Input handling

#### `/scripts/state_machine/state_machine.gd`
State machine manager
- Manages state caching
- Handles transitions
- Forwards physics and input to current state
- Supports string-based and direct state transitions

### Managers and Utilities

#### `/scripts/managers/spawn_manager.gd`
Enemy spawning and coordination
- Spawns enemies from prefabs
- Manages attack slots (limits simultaneous attacks)
- Tracks active enemies
- Handles spawn waves
- Connects enemies to player target

#### `/scripts/projectiles/stone_projectile.gd`
Projectile for thrower enemy
- Simple movement with direction
- Lifetime and auto-despawn
- Damage on collision with player
- Won't damage owner or other enemies

### Documentation

#### `SETUP_GUIDE.md`
Complete setup instructions including:
- Scene hierarchy structure
- Node configuration (Sprite2D, Hitbox, Hurtbox, AnimationPlayer, StateMachine)
- Input map setup
- Collision layer/mask configuration
- Movement system explanation
- Combo and special move mechanics

#### `CHARACTER_SYSTEM_README.md` (this file)
Overview of all files and their purposes

## Key Features

### Movement System
- 2D plane movement (no gravity)
- 8-directional input
- Y-axis speed is 60% of X-axis (perspective simulation)
- Works with Y-sorting for proper depth ordering

### Combat System
- Hitbox/Hurtbox collision detection
- Combo chaining for player
- Knockback with direction and magnitude
- Invincibility frames
- Various damage amounts per attack type

### AI System
- Attack slot management (prevent attack spam)
- Distance-based behavior
- Target tracking
- State-based decision making

### Character Variety
- 4 enemy types with different behaviors
- Player with multiple attack options
- Boss-like heavy enemy with super armor
- Ranged thrower with retreat behavior

## Animation Requirements

### Player Animations Needed
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

### Enemy Animations Needed
- idle
- walk
- attack
- (dash_attack for slasher)
- hit
- knockdown
- death

## Input Actions Required
- move_left, move_right, move_up, move_down
- attack
- jump
- dash
- grab
- special
- star_move

## Collision Setup

### Hitbox
- Layer: 2 (Attacking)
- Mask: 3 (Hurtable)

### Hurtbox
- Layer: 3 (Hurtable)
- Mask: 2 (Attacking)

## Signal Documentation

### BaseCharacter
- `died` - Emitted when health reaches 0
- `health_changed(new_health, max_health)` - Emitted when health changes
- `took_damage(amount)` - Emitted when taking damage

### State
- No built-in signals (states communicate via state_machine.transition_to)

## Usage Example

```gdscript
# Spawn an enemy in code
var spawn_manager = get_node("SpawnManager")
var enemy = spawn_manager.spawn_enemy("goon", Vector2(500, 300))

# Get player reference
var player = get_tree().get_first_child_in_group("player")

# Access player properties
print("Player health: %d/%d" % [player.health, player.max_health])
print("Player stars: %d" % player.star_count)

# Manually damage player
player.take_damage(10, Vector2(-200, 0))

# Request attack slot for custom attacks
if spawn_manager.request_attack_slot():
    # Perform attack
    spawn_manager.release_attack_slot()
```

## Design Notes

1. **Movement**: All characters move on a 2D plane. The Y-speed ratio creates perspective without 3D.

2. **Jumping**: Jumping is purely visual - the sprite moves up but the shadow stays on ground. No physics involved.

3. **Attack Slots**: Limits how many enemies can attack simultaneously to prevent overwhelming the player.

4. **Combos**: Player combo timing is tight (0.5 seconds) to reward skill.

5. **Special Moves**: Balanced with health costs that are recovered through hitting enemies.

6. **Super Armor**: Heavy enemy resists low-damage attacks, making weight matter in combat.

7. **AI Behavior**: Simple state machines allow for emergent behavior without complex code.

## File Structure

```
scripts/
├── characters/
│   ├── base_character.gd
│   ├── player_controller.gd
│   ├── enemy_base.gd
│   ├── enemy_goon.gd
│   ├── enemy_heavy.gd
│   ├── enemy_slasher.gd
│   └── enemy_thrower.gd
├── state_machine/
│   ├── state.gd
│   ├── state_machine.gd
│   └── states/
│       ├── player_idle_state.gd
│       ├── player_walk_state.gd
│       ├── player_attack_state.gd
│       ├── player_jump_state.gd
│       ├── player_dash_state.gd
│       ├── player_grab_state.gd
│       ├── player_special_state.gd
│       ├── player_star_move_state.gd
│       ├── player_hit_state.gd
│       ├── player_knockdown_state.gd
│       ├── enemy_idle_state.gd
│       ├── enemy_approach_state.gd
│       ├── enemy_attack_state.gd
│       ├── enemy_dash_attack_state.gd
│       ├── enemy_retreat_state.gd
│       ├── enemy_hit_state.gd
│       ├── enemy_knockdown_state.gd
│       └── enemy_death_state.gd
├── managers/
│   └── spawn_manager.gd
└── projectiles/
    └── stone_projectile.gd

SETUP_GUIDE.md
CHARACTER_SYSTEM_README.md
```

## Total Files Created: 32

- 1 Base character script
- 1 Player controller script
- 1 Enemy base script
- 4 Enemy variant scripts
- 1 State base class
- 1 State machine class
- 10 Player state scripts
- 8 Enemy state scripts
- 1 Spawn manager
- 1 Projectile script
- 2 Documentation files

All scripts use Godot 4.x syntax with full type hints and comprehensive comments in both English and Chinese.
