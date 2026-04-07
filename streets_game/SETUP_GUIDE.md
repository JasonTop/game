# Streets of Fury — Godot 4 快速設定指南

## 操作方式

| 按鍵 | 功能 |
|------|------|
| WASD / 方向鍵 | 八方向移動 |
| J / Z | 攻擊（連按 = 三連段） |
| K / X | 必殺技（消耗 HP） |
| L / C | 衝刺 |
| 空白鍵 | 跳躍 |

## 在 Godot 中開啟專案

1. 開啟 Godot 4.x
2. 點擊 **Import** → 選擇 `starter_project` 資料夾中的 `project.godot`
3. 專案會自動載入

## 需要在 Godot 編輯器中完成的設定

由於 `.tscn` 場景檔需要在 Godot 編輯器中建立（包含 UID 和資源引用），以下是你需要手動建立的場景：

### 1. 建立玩家場景 `scenes/characters/player/player.tscn`

```
Player (CharacterBody2D) → 腳本: scripts/characters/player_controller.gd
├── Shadow (Sprite2D) → 貼圖: assets/sprites/effects/shadow.png
├── Body (Sprite2D) → 貼圖: assets/sprites/players/player.png
│   ├── 設定 Hframes = 30（水平切割為 30 幀）
│   └── Frame = 0
├── CollisionShape2D → RectangleShape2D (24x12)
├── Hurtbox (Area2D) → 腳本: scripts/combat/hurtbox.gd
│   ├── CollisionShape2D → RectangleShape2D (20x40)
│   ├── Collision Layer = 5 (PlayerHurtbox)
│   └── Collision Mask = 6 (EnemyHitbox)
├── Hitbox (Area2D) → 腳本: scripts/combat/hitbox.gd
│   ├── CollisionShape2D → RectangleShape2D (30x20), 偏移 X=25
│   ├── Collision Layer = 4 (PlayerHitbox)
│   ├── Collision Mask = 7 (EnemyHurtbox)
│   └── 預設 Disabled = true
├── GrabZone (Area2D)
│   ├── CollisionShape2D → CircleShape2D (radius=30)
│   └── Collision Mask = 3 (EnemyBody)
├── StateMachine → 腳本: scripts/state_machine/state_machine.gd
│   ├── IdleState → 腳本: scripts/state_machine/states/player_idle_state.gd
│   ├── WalkState → player_walk_state.gd
│   ├── AttackState → player_attack_state.gd
│   ├── JumpState → player_jump_state.gd
│   ├── DashState → player_dash_state.gd
│   ├── GrabState → player_grab_state.gd
│   ├── SpecialState → player_special_state.gd
│   ├── HitState → player_hit_state.gd
│   └── KnockdownState → player_knockdown_state.gd
└── Camera2D → 腳本: scripts/systems/camera_controller.gd
    ├── Limit Top = 0, Bottom = 720
    └── Position Smoothing = Enabled
```

**CharacterBody2D 設定：**
- Collision Layer = 2 (PlayerBody)
- Collision Mask = 1 (World) + 3 (EnemyBody)

### 2. 建立敵人場景（以 Goon 為例）`scenes/characters/enemies/goon.tscn`

```
Goon (CharacterBody2D) → 腳本: scripts/characters/enemy_goon.gd
├── Shadow (Sprite2D) → shadow.png
├── Body (Sprite2D) → assets/sprites/enemies/goon.png, Hframes=15
├── CollisionShape2D → RectangleShape2D (24x12)
├── Hurtbox (Area2D) → 腳本: scripts/combat/hurtbox.gd
│   ├── Collision Layer = 7 (EnemyHurtbox)
│   └── Collision Mask = 4 (PlayerHitbox)
├── Hitbox (Area2D) → 腳本: scripts/combat/hitbox.gd
│   ├── Collision Layer = 6 (EnemyHitbox)
│   ├── Collision Mask = 5 (PlayerHurtbox)
│   └── Disabled = true
└── StateMachine → 腳本: scripts/state_machine/state_machine.gd
    ├── IdleState → enemy_idle_state.gd
    ├── ApproachState → enemy_approach_state.gd
    ├── AttackState → enemy_attack_state.gd
    ├── RetreatState → enemy_retreat_state.gd
    ├── HitState → enemy_hit_state.gd
    ├── KnockdownState → enemy_knockdown_state.gd
    └── DeathState → enemy_death_state.gd
```

**同樣方式建立 Heavy、Slasher、Thrower，只換腳本和貼圖：**
- Heavy: enemy_heavy.gd, heavy.png (Hframes=16)
- Slasher: enemy_slasher.gd, slasher.png (Hframes=16)，多加一個 DashAttackState
- Thrower: enemy_thrower.gd, thrower.png (Hframes=16)

### 3. 建立關卡場景 `scenes/levels/level_01.tscn`

```
Level_01 (Node2D, Y Sort Enabled = true) → 腳本: scripts/level/level_01.gd
├── ParallaxBackground
│   ├── ParallaxLayer (motion_scale = 0.1, 0.1)
│   │   └── Sprite2D → bg_sky.png (重複鋪滿)
│   ├── ParallaxLayer (motion_scale = 0.3, 0.3)
│   │   └── Sprite2D → bg_buildings_far.png
│   └── ParallaxLayer (motion_scale = 0.6, 0.6)
│       └── Sprite2D → bg_buildings_near.png
├── Ground (ColorRect 或 TileMapLayer) → 4000x440, Y=280
├── Player (實例化 player.tscn) → 位置 (100, 400)
├── CombatZone1 (Area2D) → combat_zone.gd, 位置 X=400
├── CombatZone2 → X=1200
├── CombatZone3 → X=2000
├── CombatZone4 → X=2800
├── CombatZone5 → X=3600
├── Destructibles
│   ├── Barrel (StaticBody2D) → destructible.gd
│   └── Crate (StaticBody2D) → destructible.gd
└── HUD (CanvasLayer) → scripts/ui/hud.gd
```

### 4. 建立 UI 場景

**Title Screen** `scenes/ui/title_screen.tscn`:
- Control 根節點 → 腳本: scripts/ui/title_screen.gd

**Game Over** `scenes/ui/game_over.tscn`:
- Control → 腳本: scripts/ui/game_over_screen.gd

**Stage Clear** `scenes/ui/stage_clear.tscn`:
- Control → 腳本: scripts/ui/stage_clear_screen.gd

## 碰撞層速查表

| Layer | 名稱 | 用途 |
|-------|------|------|
| 1 | World | 地形邊界 |
| 2 | PlayerBody | 玩家物理碰撞 |
| 3 | EnemyBody | 敵人物理碰撞 |
| 4 | PlayerHitbox | 玩家攻擊 → 偵測 Layer 7 |
| 5 | PlayerHurtbox | 玩家受擊 → 偵測 Layer 6 |
| 6 | EnemyHitbox | 敵人攻擊 → 偵測 Layer 5 |
| 7 | EnemyHurtbox | 敵人受擊 → 偵測 Layer 4 |
| 8 | Pickup | 拾取物 |
| 9 | CombatZone | 戰鬥區域觸發 |
| 10 | Destructible | 可破壞物件 |

## 系統架構圖

```
GameManager (Autoload) ← 全域分數、生命、Hit Stop
SpawnManager (Autoload) ← 敵人攻擊槽位管理
EffectSpawner (Autoload) ← 生成打擊特效、傷害數字

Player ←→ StateMachine (10 個狀態)
  ├── Hitbox → 攻擊時啟用 → 碰到 Enemy Hurtbox → 造成傷害
  └── Hurtbox → 被 Enemy Hitbox 碰到 → 受傷/擊退

Enemy ←→ StateMachine (7 個狀態)
  ├── 向 SpawnManager 請求攻擊槽位
  └── 死亡時 → 通知 CombatZone → 全清後解鎖攝影機

CombatZone → 玩家進入 → 鎖定攝影機 → 生成敵人 → 全清 → 解鎖 → GO!
```

## 檔案總覽

### GDScript 腳本（47 個檔案）

**核心框架：**
- `scripts/state_machine/state.gd` — 狀態基底類別
- `scripts/state_machine/state_machine.gd` — 狀態機管理器
- `scripts/combat/hitbox.gd` — 攻擊判定
- `scripts/combat/hurtbox.gd` — 受擊判定
- `scripts/combat/combo_manager.gd` — 連段追蹤

**角色：**
- `scripts/characters/base_character.gd` — 角色基底
- `scripts/characters/player_controller.gd` — 玩家控制器
- `scripts/characters/enemy_base.gd` — 敵人 AI 基底
- `scripts/characters/enemy_goon.gd` — 小兵
- `scripts/characters/enemy_heavy.gd` — 重裝
- `scripts/characters/enemy_slasher.gd` — 衝鋒者
- `scripts/characters/enemy_thrower.gd` — 投擲者

**玩家狀態（10 個）：** idle、walk、attack、jump、dash、grab、special、star_move、hit、knockdown
**敵人狀態（8 個）：** idle、approach、attack、dash_attack、retreat、hit、knockdown、death

**系統：**
- `scripts/systems/game_manager.gd` — 全域遊戲管理（Autoload）
- `scripts/systems/camera_controller.gd` — 攝影機控制
- `scripts/systems/effect_spawner.gd` — 特效生成（Autoload）
- `scripts/managers/spawn_manager.gd` — 敵人生成管理（Autoload）

**關卡：**
- `scripts/level/level_01.gd` — 第一關：城市街道
- `scripts/level/combat_zone.gd` — 戰鬥區域
- `scripts/level/destructible.gd` — 可破壞物件
- `scripts/level/pickup.gd` — 拾取物
- `scripts/level/hit_effect.gd` — 打擊特效

**UI：**
- `scripts/ui/hud.gd` — 遊戲內 HUD
- `scripts/ui/damage_number.gd` — 浮動傷害數字
- `scripts/ui/title_screen.gd` — 標題畫面
- `scripts/ui/game_over_screen.gd` — Game Over
- `scripts/ui/stage_clear_screen.gd` — 關卡結算

### 像素圖片素材（16 個檔案）
- 玩家 spritesheet（30 幀）
- 4 種敵人 spritesheet（15-16 幀各）
- 投擲物、打擊特效、影子
- 木桶、木箱（3 幀破壞動畫）
- 回血、星星拾取物
- 城市 tileset
- 3 層視差背景（夜空、遠景、近景）
