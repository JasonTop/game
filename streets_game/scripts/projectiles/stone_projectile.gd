## 石块投掷物 / Stone Projectile
## 投掷敌人投掷的远程攻击 / Ranged attack thrown by thrower enemy
extends Area2D
class_name StoneProjectile

# 运动参数 / Movement parameters
@export var speed: float = 300.0
@export var lifetime: float = 3.0

# 伤害参数 / Damage parameters
var damage: int = 10
var owner_enemy: EnemyBase = null
var direction: Vector2 = Vector2.ZERO

var travel_time: float = 0.0


func _ready() -> void:
	"""初始化投掷物 / Initialize projectile"""
	# 连接信号 / Connect signals
	area_entered.connect(_on_area_entered)

	# 设置物理 / Set up physics
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	"""更新投掷物位置 / Update projectile position"""
	# 移动投掷物 / Move projectile
	position += direction * speed * delta

	# 更新生命时间 / Update lifetime
	travel_time += delta
	if travel_time >= lifetime:
		queue_free()


## 设置方向 / Set direction
func set_direction(new_direction: Vector2) -> void:
	"""设置投掷物的方向 / Set projectile direction"""
	direction = new_direction.normalized()


## 设置伤害 / Set damage
func set_damage(new_damage: int) -> void:
	"""设置投掷物的伤害值 / Set projectile damage"""
	damage = new_damage


## 设置拥有者 / Set owner
func set_owner(enemy: EnemyBase) -> void:
	"""设置投掷物的拥有者敌人 / Set the owner enemy"""
	owner_enemy = enemy


## 区域进入 / Area entered
func _on_area_entered(area: Area2D) -> void:
	"""当投掷物击中区域时 / When projectile hits an area"""
	# 只伤害敌人，不伤害投掷者 / Only damage enemies, not thrower
	if area is Hurtbox or (area.get_parent() is BaseCharacter):
		var target = area.get_parent() as BaseCharacter

		# 不伤害拥有者 / Don't damage owner
		if target == owner_enemy:
			return

		# 不伤害其他敌人（友方伤害） / Don't damage other enemies (friendly fire)
		if target is EnemyBase:
			return

		# 对玩家造成伤害 / Deal damage to player
		if target is Player:
			var knockback = direction * 200.0
			target.take_damage(damage, knockback)
			queue_free()


## 显示投掷物的视觉效果（可选）/ Visual effect display (optional)
func show_impact() -> void:
	"""显示撞击效果 / Show impact effect"""
	# 这里可以添加粒子效果或其他视觉效果
	# Add particle effects or other visual effects here
	pass
