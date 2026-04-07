extends Sprite2D
## 命中视觉效果 | Hit visual effect

class_name HitEffect

# 动画帧 | Animation frame
@export var animation_frames: int = 4
# 每帧持续时间 | Time per frame
@export var frame_duration: float = 0.05
# 扩展速度 | Expansion speed
@export var expansion_speed: float = 1.5

# 内部状态 | Internal state
var _elapsed_time: float = 0.0
var _current_frame: int = 0


func _ready() -> void:
	# 如果没有纹理，创建简单的圆形 | If no texture, create simple circle
	if not texture:
		_create_simple_hit_sprite()


func _process(delta: float) -> void:
	_elapsed_time += delta

	# 计算当前帧 | Calculate current frame
	var frame_index = int(_elapsed_time / frame_duration)

	# 更新缩放（扩展效果）| Update scale (expansion effect)
	var progress = float(frame_index) / float(animation_frames)
	scale = Vector2.ONE * (1.0 + progress * expansion_speed)

	# 淡出 | Fade out
	modulate.a = 1.0 - progress

	# 动画完成时删除 | Remove when animation completes
	if frame_index >= animation_frames:
		queue_free()


## 创建简单的命中精灵 | Create simple hit sprite
func _create_simple_hit_sprite() -> void:
	# 创建一个简单的圆形图像 | Create simple circular image
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)

	# 绘制圆形 | Draw circle
	for y in range(32):
		for x in range(32):
			var dx = x - 16
			var dy = y - 16
			var distance = sqrt(dx * dx + dy * dy)

			if distance < 16 and distance > 12:
				image.set_pixel(x, y, Color.YELLOW)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)

	# 创建纹理 | Create texture
	var image_texture = ImageTexture.create_from_image(image)
	texture = image_texture
	centered = true


## 静态工厂方法 | Static factory method
static func create_at(position: Vector2, parent: Node) -> HitEffect:
	var effect = HitEffect.new()
	effect.position = position
	effect.centered = true
	parent.add_child(effect)
	return effect


## 设置位置并播放 | Set position and play
func play_at(pos: Vector2) -> void:
	global_position = pos
	_elapsed_time = 0.0
