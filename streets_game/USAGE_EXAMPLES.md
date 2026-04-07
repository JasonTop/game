# Level System Usage Examples

Complete code examples for integrating the level system with your game.

## Player Script Integration

### Basic Player with Combat

```gdscript
# player.gd
extends CharacterBody2D

class_name Player

@export var move_speed: float = 200.0
@export var max_health: int = 100
@export var current_health: int = 100

var _attack_box: Area2D
var _camera: CameraController

signal died


func _ready() -> void:
	add_to_group("player")

	# Setup attack box
	_setup_attack_box()

	# Find camera
	_camera = get_tree().get_first_node_in_group("camera") as CameraController
	if not _camera:
		push_error("Player: Camera not found!")


func _setup_attack_box() -> void:
	_attack_box = Area2D.new()
	_attack_box.name = "AttackBox"
	_attack_box.add_to_group("player_attack")

	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(50, 50)

	_attack_box.add_child(shape)
	add_child(_attack_box)


func _process(delta: float) -> void:
	_handle_input()
	velocity = Vector2.ZERO
	move_and_slide()


func _handle_input() -> void:
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * move_speed

	# Attack input
	if Input.is_action_just_pressed("attack"):
		perform_attack()


func perform_attack() -> void:
	var enemies_hit = _attack_box.get_overlapping_bodies()

	for body in enemies_hit:
		if body.is_in_group("enemy"):
			var damage = 10

			# Spawn effects
			EffectSpawner.spawn_hit_effect(body.global_position)
			EffectSpawner.spawn_damage_number(body.global_position, damage)

			# Damage enemy
			if body.has_method("take_damage"):
				body.take_damage(damage)

			# Screen shake
			if _camera:
				_camera.screen_shake(0.5)


func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)

	# Visual feedback
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if current_health <= 0:
		die()


func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	print("Player healed: +%d (now %d/%d)" % [amount, current_health, max_health])


func die() -> void:
	print("Player died!")
	EffectSpawner.spawn_particles(global_position, "blood")
	died.emit()
	queue_free()
```

## Enemy Script Integration

### Basic Enemy with AI

```gdscript
# goon.gd
extends CharacterBody2D

class_name Goon

@export var move_speed: float = 100.0
@export var max_health: int = 30
@export var damage: int = 5

var current_health: int = 30
var _player: Node2D
var _direction: float = 1.0

signal died
signal health_changed(new_health: int)


func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	_player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if not _player:
		return

	# Simple AI: move toward player
	var direction_to_player = sign(_player.global_position.x - global_position.x)
	velocity.x = direction_to_player * move_speed

	move_and_slide()


func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)

	if current_health <= 0:
		die()


func die() -> void:
	print("%s died!" % name)

	# Spawn visual effects
	EffectSpawner.spawn_particles(global_position, "blood")

	# Random drop
	if randf() < 0.5:
		EffectSpawner.spawn_pickup(
			global_position,
			Pickup.PickupType.HEALTH
		)

	died.emit()
	queue_free()
```

## Level Scene Integration

### Complete Level Setup Scene

```gdscript
# main_level.gd - Main scene script
extends Node2D

func _ready() -> void:
	# Ensure camera group exists
	if not get_tree().get_first_node_in_group("camera"):
		var camera = CameraController.new()
		camera.add_to_group("camera")
		add_child(camera)

	# Ensure player exists or is spawned
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = load("res://scenes/player/player.tscn").instantiate()
		add_child(player)

	# Setup Level01
	var level = Level01.new()
	level.add_to_group("level")
	add_child(level)

	# Listen to level completion
	level.level_complete.connect(_on_level_complete)
	level.zone_cleared.connect(_on_zone_cleared)


func _on_zone_cleared(zone_index: int) -> void:
	print("Zone %d complete!" % zone_index)
	# Update HUD, play sound, etc.


func _on_level_complete() -> void:
	print("Level complete!")
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/levels/level_02.tscn")
```

## Destructible Object Examples

### Custom Destructible Barrel

```gdscript
# Create a barrel in code
func create_barrel(position: Vector2) -> Destructible:
	var barrel = Destructible.new()
	barrel.name = "Barrel"
	barrel.global_position = position
	barrel.max_health = 3
	barrel.drop_chance = 0.7
	barrel.drop_scene = load("res://scenes/pickups/health_pickup.tscn")

	# Add sprite
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/barrel.png")
	barrel.sprite = sprite
	barrel.add_child(sprite)

	# Connect signals
	barrel.destroyed.connect(func():
		print("Barrel destroyed at ", position)
	)

	return barrel


# Usage
var barrel = create_barrel(Vector2(500, 350))
add_child(barrel)
```

### Wooden Crate

```gdscript
func create_crate(position: Vector2) -> Destructible:
	var crate = Destructible.new()
	crate.name = "Crate"
	crate.global_position = position
	crate.max_health = 2  # Easier to break than barrel
	crate.drop_chance = 0.4

	# Add sprite with frame support
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/crate.png")
	crate.sprite = sprite
	crate.add_child(sprite)

	return crate
```

## Effect Spawning Examples

### Multiple Effects on Big Hit

```gdscript
# In player or enemy script
func perform_power_attack(target: Node2D) -> void:
	var damage = 25
	var hit_pos = target.global_position

	# Multiple visual effects
	EffectSpawner.spawn_hit_effect(hit_pos)
	EffectSpawner.spawn_hit_effect(hit_pos + Vector2(20, 0))
	EffectSpawner.spawn_hit_effect(hit_pos + Vector2(-20, 0))

	# Large damage number
	EffectSpawner.spawn_damage_number(hit_pos, damage)

	# Screen flash and shake
	EffectSpawner.screen_flash(0.2, Color.YELLOW)
	_camera.screen_shake(1.5)

	# Sound
	EffectSpawner.play_sfx("res://sounds/impact.ogg", hit_pos, 3.0)

	# Apply damage
	target.take_damage(damage)
```

### Particle Effects on Different Damage Types

```gdscript
func hit_with_effect(target: Node2D, hit_type: String, damage: int) -> void:
	var pos = target.global_position

	EffectSpawner.spawn_damage_number(pos, damage)

	match hit_type:
		"melee":
			EffectSpawner.spawn_hit_effect(pos)
			EffectSpawner.spawn_particles(pos, "dust")
			EffectSpawner.play_sfx("res://sounds/melee_hit.ogg", pos)

		"slash":
			EffectSpawner.spawn_particles(pos, "spark")
			EffectSpawner.play_sfx("res://sounds/slash.ogg", pos)

		"explosive":
			EffectSpawner.screen_flash(0.3, Color.RED)
			EffectSpawner.spawn_particles(pos, "fire")
			EffectSpawner.play_sfx("res://sounds/explosion.ogg", pos)

	target.take_damage(damage)
```

## Custom Zone Configuration

### Create Dynamic Zone

```gdscript
# In Level01 or custom level
func create_custom_zone(
	position: Vector2,
	enemy_count: int,
	enemy_type: String
) -> CombatZone:
	var zone = CombatZone.new()
	zone.global_position = position
	zone.zone_width = 640.0
	zone.spawn_delay = 0.5
	zone.one_time_trigger = true

	# Load enemy scenes based on type
	var enemy_scenes: Array[PackedScene] = []
	for i in range(enemy_count):
		match enemy_type:
			"goon":
				enemy_scenes.append(load("res://scenes/enemies/goon.tscn"))
			"heavy":
				enemy_scenes.append(load("res://scenes/enemies/heavy.tscn"))
			"mixed":
				if i % 2 == 0:
					enemy_scenes.append(load("res://scenes/enemies/goon.tscn"))
				else:
					enemy_scenes.append(load("res://scenes/enemies/slasher.tscn"))

	zone.enemy_scenes = enemy_scenes

	# Add collision shape
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(zone.zone_width, 200)
	zone.add_child(shape)

	# Connect signals
	zone.zone_cleared.connect(func():
		print("Custom zone cleared!")
	)

	return zone
```

## HUD/UI Integration

### Health Display

```gdscript
# hud.gd
extends CanvasLayer

@onready var health_label = Label.new()
var _player: Player


func _ready() -> void:
	# Setup label
	health_label.position = Vector2(10, 10)
	health_label.add_theme_font_size_override("font_size", 24)
	add_child(health_label)

	# Find player
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player:
		_player.health_changed.connect(_on_player_health_changed)

	update_health_display()


func _process(delta: float) -> void:
	# Update in case health changes without signal
	if _player:
		update_health_display()


func update_health_display() -> void:
	if _player:
		health_label.text = "Health: %d/%d" % [_player.current_health, _player.max_health]


func _on_player_health_changed() -> void:
	update_health_display()
```

### Zone Completion Progress

```gdscript
# zone_progress.gd
extends CanvasLayer

@onready var progress_label = Label.new()
var _level: Level01


func _ready() -> void:
	progress_label.position = Vector2(10, 40)
	progress_label.add_theme_font_size_override("font_size", 20)
	add_child(progress_label)

	_level = get_tree().get_first_node_in_group("level") as Level01
	if _level:
		_level.zone_cleared.connect(_on_zone_cleared)

	update_progress()


func update_progress() -> void:
	if _level:
		var stats = _level.get_level_stats()
		progress_label.text = "Zones: %d/%d" % [stats.completed_zones, stats.zones]


func _on_zone_cleared(zone_index: int) -> void:
	update_progress()
```

### Enemy Wave Display

```gdscript
# wave_display.gd
extends CanvasLayer

@onready var wave_label = Label.new()
var _current_zone: CombatZone = null


func _ready() -> void:
	wave_label.position = Vector2(320, 20)
	wave_label.add_theme_font_size_override("font_size", 32)
	wave_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(wave_label)

	# Find level and listen to zones
	var level = get_tree().get_first_node_in_group("level") as Level01
	if level:
		level.zone_activated.connect(_on_zone_activated)


func _on_zone_activated(zone_index: int) -> void:
	wave_label.text = "ZONE %d" % (zone_index + 1)

	# Animate
	wave_label.scale = Vector2(0.5, 0.5)
	wave_label.modulate.a = 1.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(wave_label, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(wave_label, "modulate:a", 0.0, 0.3).set_delay(1.0)
```

## Game Manager Integration

### Basic Game Manager

```gdscript
# GameManager.gd (Autoload)
extends Node

signal screen_shake_requested(strength: float)

var current_level: Level01
var player: Player
var paused: bool = false


func _ready() -> void:
	name = "GameManager"


func set_paused(is_paused: bool) -> void:
	paused = is_paused
	get_tree().paused = paused


func request_screen_shake(strength: float = 1.0) -> void:
	screen_shake_requested.emit(strength)


func add_stars(amount: int) -> void:
	print("Player earned %d stars" % amount)


func add_money(amount: int) -> void:
	print("Player earned %d money" % amount)


func get_difficulty() -> int:
	return 1  # Easy, Normal, Hard
```

## Complete Scene Tree Example

```
Main (Node2D) [main_level.gd]
├─ Level01 [level_01.gd]
│  ├─ CameraController (Camera2D)
│  ├─ CombatZone[5]
│  ├─ Destructible[n]
│  ├─ Background
│  └─ ParallaxLayers
│
├─ Player (CharacterBody2D) [player.gd]
│  ├─ Sprite2D
│  ├─ CollisionShape2D
│  └─ AttackBox (Area2D)
│
├─ HUD (CanvasLayer) [hud.gd]
│  └─ Labels (Health, Score, etc)
│
└─ Camera2D (follows player)
```

## Testing Checklist

Before shipping your level:

- [ ] Player can move left/right within Y constraints
- [ ] Camera follows player smoothly
- [ ] First zone triggers when player enters
- [ ] Enemies spawn with proper delay
- [ ] Player can damage enemies
- [ ] Hit effects display correctly
- [ ] Enemies drop items when defeated
- [ ] Pickups heal/buff player
- [ ] Destructibles break and drop items
- [ ] Zone clears when all enemies dead
- [ ] Camera unlocks after zone clear
- [ ] "GO!" arrow displays
- [ ] Next zone triggers properly
- [ ] Level complete when all zones done
- [ ] Screen shake works
- [ ] All sounds play
- [ ] No console errors
