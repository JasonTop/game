# Godot 4.x — 2.5D 橫向捲軸街機遊戲入門指南

> 適用對象：Godot 完全新手 ｜ 目標：做出類似 Metal Slug 風格的 2.5D 動作遊戲

---

## 一、環境準備

### 1. 下載 Godot 4.x
前往 [godotengine.org/download](https://godotengine.org/download) 下載最新穩定版 Godot 4。
建議選擇 **Standard** 版本（不需要 .NET 版，除非你想用 C#）。

### 2. 第一次啟動
Godot 是免安裝的，解壓後直接執行即可。啟動後會看到「專案管理器」，點擊 **Create** 建立新專案。

---

## 二、核心概念速覽

### Scene（場景）與 Node（節點）
Godot 的一切都由 **Node** 組成，多個 Node 組合成一個 **Scene**。
你可以把 Scene 想像成「可重複使用的積木」，例如：玩家是一個 Scene、敵人是一個 Scene、整個關卡也是一個 Scene。

### GDScript
Godot 的主要程式語言，語法接近 Python，容易上手：

```gdscript
extends CharacterBody2D

var speed = 300.0

func _physics_process(delta):
    var direction = Input.get_axis("move_left", "move_right")
    velocity.x = direction * speed
    move_and_slide()
```

---

## 三、什麼是「2.5D」？

2.5D 指的是 **看起來有立體感的 2D 遊戲**。在 Godot 中最推薦的做法：

| 方法 | 說明 | 適合場景 |
|------|------|---------|
| **2D + Parallax（推薦）** | 用 2D 引擎 + 多層視差滾動營造深度感 | Metal Slug、快打旋風 |
| 3D + 正交攝影機 | 用 3D 場景但鎖定攝影機角度 | 2.5D 平台跳躍 |

**對新手來說，強烈建議用第一種方法**——用 2D 引擎配合視差背景，開發效率高、效能好、學習曲線平緩。

---

## 四、推薦的專案資料夾結構

```
my_arcade_game/
├── project.godot          # Godot 專案設定檔
├── scenes/                # 場景檔案
│   ├── player/            # 玩家相關場景
│   ├── enemies/           # 敵人場景
│   ├── levels/            # 關卡場景
│   └── ui/                # UI 介面場景
├── scripts/               # GDScript 腳本
│   ├── player/
│   ├── enemies/
│   └── globals/           # Autoload 全域腳本
├── assets/                # 美術與音效資源
│   ├── sprites/           # 角色與物件圖片
│   ├── tilesets/          # 地圖圖塊
│   ├── audio/             # 音效與音樂
│   └── fonts/             # 字型
└── addons/                # 第三方插件（如有）
```

---

## 五、關鍵節點介紹

以下是做 2.5D 橫向動作遊戲最常用的節點：

### 玩家角色
- **CharacterBody2D** — 角色物理本體，提供 `move_and_slide()` 方法處理移動與碰撞
- **CollisionShape2D** — 碰撞形狀（通常是矩形或膠囊形）
- **AnimatedSprite2D** — 播放角色的走路、跳躍、攻擊等動畫
- **Camera2D** — 跟隨玩家的攝影機

### 關卡地圖
- **TileMapLayer**（Godot 4.3+）— 用圖塊拼出地形、平台、障礙物
- **Parallax2D** — 視差滾動背景，營造 2.5D 深度感

### 敵人與互動
- **Area2D** — 用於傷害判定區域、拾取物、觸發器
- **AnimationPlayer** — 更精細的動畫控制（可同時控制位置、透明度等）

### 音效
- **AudioStreamPlayer2D** — 有方位感的音效播放

---

## 六、第一步：建立玩家角色

### Step 1：建立場景
1. 新增場景，根節點選擇 **CharacterBody2D**
2. 加入子節點：**CollisionShape2D**（設定碰撞範圍）
3. 加入子節點：**AnimatedSprite2D**（放入角色圖片）
4. 加入子節點：**Camera2D**（讓攝影機跟隨玩家）

### Step 2：撰寫移動腳本

在 CharacterBody2D 上附加腳本：

```gdscript
extends CharacterBody2D

# === 參數設定 ===
@export var speed: float = 300.0
@export var jump_force: float = -500.0
@export var gravity: float = 1200.0

func _physics_process(delta: float) -> void:
    # 重力
    if not is_on_floor():
        velocity.y += gravity * delta

    # 跳躍
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force

    # 左右移動
    var direction := Input.get_axis("move_left", "move_right")
    velocity.x = direction * speed

    # 翻轉角色面向
    if direction != 0:
        $AnimatedSprite2D.flip_h = direction < 0

    move_and_slide()
```

### Step 3：設定輸入對應
到 **Project → Project Settings → Input Map** 新增：
- `move_left` → 鍵盤 A 或 ←
- `move_right` → 鍵盤 D 或 →
- `jump` → 空白鍵
- `shoot` → 鍵盤 J 或 Z

---

## 七、加入視差背景（2.5D 深度感的關鍵）

### 使用 Parallax2D（Godot 4.3+）

```
Level（Node2D）
├── Parallax2D（scroll_scale = 0.1）  ← 最遠的天空
│   └── Sprite2D（天空背景圖）
├── Parallax2D（scroll_scale = 0.3）  ← 遠山
│   └── Sprite2D（山脈背景圖）
├── Parallax2D（scroll_scale = 0.6）  ← 中景建築
│   └── Sprite2D（建築背景圖）
├── TileMapLayer                       ← 主要遊玩地形
└── Player                             ← 玩家角色
```

`scroll_scale` 值越小，滾動越慢，看起來越遠。這就是營造 2.5D 縱深感的核心技巧。

---

## 八、建立關卡地圖

1. 新增 **TileMapLayer** 節點
2. 在 Inspector 中建立新的 **TileSet**
3. 將 tileset 圖片拖入 TileSet 編輯器
4. 在 TileSet 的 **Physics Layer** 中為地面圖塊加上碰撞形狀
5. 用畫筆工具在場景中繪製關卡

**小提示：**
- 在 Project Settings 中將 **Textures → Default Texture Filter** 設為 **Nearest**，這對像素風格遊戲很重要
- 設定 One-Way Collision 可以做出「只能從下往上跳的平台」

---

## 九、常見問題與陷阱

| 問題 | 解決方法 |
|------|---------|
| 角色圖片模糊 | Project Settings → Rendering → Textures → Default Texture Filter 改為 **Nearest** |
| TileMap 出現接縫 | 確保圖塊尺寸一致，使用 Texture Filter: Nearest |
| 角色卡在地形邊角 | 調整 CollisionShape2D 的形狀，避免用太尖銳的矩形 |
| 動畫不流暢 | 在 AnimatedSprite2D 中確認 FPS 設定，通常 8-12 fps 適合像素動畫 |
| 跳躍手感差 | 嘗試加入「土狼時間」(Coyote Time) 和「跳躍緩衝」(Jump Buffer) |

---

## 十、學習資源推薦

### 官方文件（英文）
- [Godot 官方文件](https://docs.godotengine.org/en/stable/)
- [GDScript 基礎教學](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [CharacterBody2D 教學](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html)
- [2D Parallax 教學](https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html)

### YouTube 頻道
- **Brackeys**（已回歸，有 Godot 4 系列）
- **GDQuest**（深度 Godot 教學）
- **Heartbeast**（Action RPG 系列，概念可參考）

### 社群
- [Godot 官方 Discord](https://discord.gg/godotengine)
- [Reddit r/godot](https://reddit.com/r/godot)

---

## 十一、下一步建議

作為完全新手，建議按這個順序推進：

1. **先跟著官方 "Your First 2D Game" 教學做一次**（熟悉編輯器操作）
2. **做出能移動和跳躍的角色**（本指南第六節）
3. **加入簡單地形和視差背景**（第七、八節）
4. **加入一個基本敵人**（用 Area2D 做碰撞判定）
5. **加入射擊功能**（實例化子彈場景）
6. **加入 UI**（血量條、分數顯示）
7. **加入音效和畫面特效**（爆炸、螢幕震動）

每一步都先做到「能動」就好，不要追求完美，慢慢迭代改進。祝你開發順利！
