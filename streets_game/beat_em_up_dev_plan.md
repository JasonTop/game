# Streets of Rage 風格 Beat 'em Up — 開發計畫

> 引擎：Godot 4.x ｜ 類型：2.5D 橫向捲軸格鬥 ｜ 參考：Streets of Rage 4

---

## 一、技術架構總覽

### 核心技術選型

| 項目 | 選擇 | 理由 |
|------|------|------|
| 維度 | **2D 引擎 + Y-Sort 模擬深度** | 開發效率高，符合 Beat 'em Up 的操作邏輯 |
| 物理 | **CharacterBody2D** | 完全控制角色移動，不依賴物理引擎 |
| 角色狀態 | **Node-based State Machine** | 狀態多且複雜，節點式架構易擴展、易除錯 |
| 動畫 | **AnimationPlayer + AnimationTree** | 支援狀態混合與過渡，適合格鬥動畫 |
| 深度排序 | **CanvasItem Y Sort Enabled** | Godot 4 內建，無需額外處理 |
| 攝影機 | **Camera2D + 自訂滾動鎖定邏輯** | 控制戰鬥區域鎖屏與推進 |

### 專案結構

```
beat_em_up/
├── project.godot
├── scenes/
│   ├── characters/
│   │   ├── player/          # 玩家角色場景
│   │   └── enemies/         # 各種敵人場景
│   ├── levels/              # 關卡場景
│   ├── ui/                  # HUD、選單、過場
│   ├── pickups/             # 武器、回血、星星
│   └── effects/             # 打擊特效、爆炸
├── scripts/
│   ├── characters/
│   │   ├── base_character.gd        # 角色基底類別
│   │   ├── player_controller.gd     # 玩家輸入控制
│   │   └── enemy_ai.gd             # 敵人 AI 基底
│   ├── state_machine/
│   │   ├── state_machine.gd         # 狀態機核心
│   │   ├── state.gd                 # 狀態基底類別
│   │   └── states/                  # 各狀態實作
│   │       ├── idle_state.gd
│   │       ├── walk_state.gd
│   │       ├── attack_state.gd
│   │       ├── grab_state.gd
│   │       ├── hit_state.gd
│   │       ├── knockdown_state.gd
│   │       └── special_state.gd
│   ├── combat/
│   │   ├── hitbox.gd               # 攻擊判定
│   │   ├── hurtbox.gd              # 受擊判定
│   │   ├── combo_manager.gd        # 連段系統
│   │   └── damage_calculator.gd    # 傷害計算
│   ├── systems/
│   │   ├── game_manager.gd         # 全域遊戲狀態（Autoload）
│   │   ├── score_manager.gd        # 計分系統
│   │   ├── camera_controller.gd    # 攝影機與鎖屏控制
│   │   ├── spawn_manager.gd        # 敵人生成管理
│   │   └── input_manager.gd        # 多人輸入管理
│   └── level/
│       ├── combat_zone.gd          # 戰鬥區域觸發器
│       └── hazard.gd               # 環境危害
├── assets/
│   ├── sprites/
│   │   ├── players/
│   │   ├── enemies/
│   │   └── effects/
│   ├── tilesets/
│   ├── audio/
│   │   ├── bgm/
│   │   ├── sfx/
│   │   └── voice/
│   └── fonts/
└── addons/
```

---

## 二、角色節點架構

每個角色（玩家 & 敵人）共用同一套節點結構：

```
CharacterBody2D（角色根節點）
├── Sprite2D "Shadow"            ← 地面影子（固定在腳底）
├── Sprite2D "Body"              ← 角色身體圖像
│   ├── AnimationPlayer          ← 動畫播放器
│   └── AnimationTree            ← 動畫狀態樹
├── CollisionShape2D             ← 物理碰撞（移動用）
├── Area2D "Hurtbox"             ← 受擊區域
│   └── CollisionShape2D
├── Area2D "Hitbox"              ← 攻擊區域（平時關閉，攻擊時開啟）
│   └── CollisionShape2D
├── Area2D "GrabZone"            ← 抓取判定範圍
│   └── CollisionShape2D
├── StateMachine                 ← 狀態機節點
│   ├── IdleState
│   ├── WalkState
│   ├── AttackState
│   ├── GrabState
│   ├── HitState
│   ├── KnockdownState
│   └── SpecialState
├── Timer "CoyoteTimer"          ← 連段寬限時間
├── Timer "InvincibilityTimer"   ← 無敵幀計時
└── AudioStreamPlayer2D          ← 音效播放
```

### Y-Sort 深度排序

```
Level（Node2D, Y Sort Enabled = true）
├── 背景層（Parallax）
├── Enemy_A（Y=200 → 畫面較上方 → 渲染在後面）
├── Player （Y=250 → 畫面較下方 → 渲染在前面）
├── Enemy_B（Y=260 → 最下方 → 渲染在最前面）
└── 前景層
```

角色的 Y 座標越大（越靠近畫面下方），就會畫在越前面，自動產生「前後」的深度感。

---

## 三、開發階段規劃

### Phase 0：原型驗證（1-2 週）

> 目標：證明核心玩法可行，做出「一個角色能在場景中打幾隻敵人」的最小可玩原型

- [ ] 搭建專案、設定解析度（1280×720）、輸入對應
- [ ] 實作 State Machine 框架（state.gd + state_machine.gd）
- [ ] 做出一個方塊玩家：移動（八方向）、基本三連擊
- [ ] 做出一個方塊敵人：接近玩家、被打會後退、會死
- [ ] 實作 Hitbox / Hurtbox 判定系統
- [ ] Y-Sort 深度排序驗證
- [ ] **里程碑：能在場景中走動、打敵人、敵人會倒**

### Phase 1：戰鬥系統（2-3 週）

> 目標：Streets of Rage 的靈魂是「打擊感」，這個階段專注讓戰鬥好玩

**連段系統**
- [ ] 基本連擊鏈（輕攻擊 → 輕攻擊 → 重攻擊）
- [ ] 連段計數器 & 連段獎分機制
- [ ] 空中攻擊（跳躍中攻擊）
- [ ] 打擊硬直（Hit Stun）— 被打時短暫無法行動

**抓取系統**
- [ ] 接近敵人自動進入抓取
- [ ] 抓取中可連打或投擲（前投 / 後投）
- [ ] 抓取中無敵幀

**必殺技系統**
- [ ] 攻擊型必殺技（消耗生命值，可透過後續攻擊回復）
- [ ] 防禦型必殺技（原地無敵 + 範圍攻擊）
- [ ] Star Move（消耗星星的大招，全程無敵）

**打擊感回饋**
- [ ] Hit Stop（擊中瞬間暫停 2-3 幀）
- [ ] 螢幕震動（Screen Shake）
- [ ] 擊中閃白特效（Sprite 閃白 shader）
- [ ] 擊飛 & 牆壁反彈（Wall Bounce）
- [ ] 打擊音效分層（輕擊、重擊、擊飛不同音效）

### Phase 2：敵人 AI（2-3 週）

> 目標：做出有策略深度的敵人，而不只是沙包

**AI 基底架構**
- [ ] 敵人狀態機：巡邏 → 接近 → 攻擊 → 撤退
- [ ] 敵人管理器：控制同時攻擊的敵人數量上限（防止圍毆）
- [ ] 敵人之間的間距管理（避免全部疊在一起）

**敵人類型**（由簡到難）
- [ ] **小嘍囉（Thug）**：直線走向玩家、出拳、被打就後退
- [ ] **衝刺型（Charger）**：從遠處衝撞，需要閃避
- [ ] **遠程型（Thrower）**：投擲物品攻擊，優先處理
- [ ] **胖子型（Heavy）**：高血量、霸體、攻擊慢但傷害高
- [ ] **敏捷型（Acrobat）**：會跳躍攻擊、閃避玩家攻擊

**Boss 設計**
- [ ] Boss 多階段行為模式（血量降低 → 進入狂暴模式）
- [ ] Boss 特殊攻擊模式（可預判、可閃避）
- [ ] Boss 對玩家策略的適應（偵測玩家是否重複同一招）

### Phase 3：關卡系統（2-3 週）

> 目標：完成從「一個房間打怪」到「完整關卡體驗」的進化

**攝影機與滾動系統**
- [ ] Camera2D 跟隨玩家（有 Drag Margin）
- [ ] 戰鬥區域鎖定（進入區域 → 攝影機鎖定 → 清完敵人 → 解鎖前進）
- [ ] 前進箭頭提示（GO!）

**CombatZone 系統**
```
CombatZone（Area2D）
├── 進入觸發器
├── 左邊界 & 右邊界（限制玩家移動範圍）
├── SpawnPoint_1（敵人生成點）
├── SpawnPoint_2
└── SpawnPoint_3
```

**關卡元素**
- [ ] TileMapLayer 建構地形
- [ ] 可破壞物件（木箱 → 掉落武器或食物）
- [ ] 環境危害（陷阱、電擊區域、毒氣）
- [ ] 視差背景（3-4 層營造深度感）

**武器系統**
- [ ] 撿起武器（靠近 + 按鈕）
- [ ] 武器耐久度（使用次數有限）
- [ ] 武器類型：揮砍類（球棒）、突刺類（小刀）、投擲類（瓶子）

### Phase 4：UI 與遊戲流程（1-2 週）

**HUD**
- [ ] 生命值條（含必殺技消耗的綠色區段）
- [ ] Star（大招）數量顯示
- [ ] 連段計數器（Combo Counter）
- [ ] 分數顯示
- [ ] Boss 血量條

**選單系統**
- [ ] 標題畫面（開始、設定、離開）
- [ ] 角色選擇畫面
- [ ] 暫停選單
- [ ] 關卡結算畫面（分數、評級 S/A/B/C）
- [ ] Game Over 畫面

**遊戲流程**
- [ ] 標題 → 角色選擇 → 關卡 → 結算 → 下一關 的完整循環
- [ ] 生命與續關系統
- [ ] 分數累積 → 解鎖隱藏角色

### Phase 5：多人本地合作（1-2 週）

- [ ] InputManager 支援多個控制器 / 鍵盤分配
- [ ] 第二玩家加入 / 退出機制
- [ ] 共享 Combo 計數器
- [ ] 友軍傷害開關（可選）
- [ ] 攝影機框住所有玩家（動態調整範圍）

### Phase 6：美術與音效（持續進行）

**視覺**
- [ ] 角色動畫幀繪製（每角色約 100-200 幀起步）
- [ ] 敵人動畫
- [ ] 打擊特效（漫畫風爆炸光效）
- [ ] 環境美術 & 視差背景
- [ ] Sprite 閃白 / 受傷 Shader

**音效**
- [ ] 打擊音效（拳頭、武器、擊飛各不同）
- [ ] 環境音效
- [ ] 背景音樂（每關一首，Boss 戰切換）
- [ ] 角色語音（攻擊、受傷、必殺技）

### Phase 7：打磨與測試（2 週）

- [ ] 難度平衡調整（敵人數量、傷害、AI 積極度）
- [ ] 手感微調（Hit Stop 時長、擊退距離、連段窗口）
- [ ] 效能優化（物件池、減少不必要的物理運算）
- [ ] Bug 修復
- [ ] 手把支援測試
- [ ] 匯出各平台測試

---

## 四、關鍵技術實作概要

### 4.1 State Machine 核心

```gdscript
# state.gd — 所有狀態的基底類別
class_name State extends Node

var character: CharacterBody2D

func enter() -> void:
    pass

func exit() -> void:
    pass

func process_input(event: InputEvent) -> void:
    pass

func process_frame(delta: float) -> void:
    pass

func process_physics(delta: float) -> void:
    pass
```

```gdscript
# state_machine.gd
class_name StateMachine extends Node

@export var initial_state: State
var current_state: State

func _ready() -> void:
    for child in get_children():
        if child is State:
            child.character = owner as CharacterBody2D
    transition_to(initial_state)

func transition_to(new_state: State) -> void:
    if current_state:
        current_state.exit()
    current_state = new_state
    current_state.enter()

func _unhandled_input(event: InputEvent) -> void:
    current_state.process_input(event)

func _process(delta: float) -> void:
    current_state.process_frame(delta)

func _physics_process(delta: float) -> void:
    current_state.process_physics(delta)
```

### 4.2 Hitbox / Hurtbox 碰撞層規劃

| Layer | 名稱 | 用途 |
|-------|------|------|
| 1 | World | 地形碰撞 |
| 2 | Player Body | 玩家物理碰撞 |
| 3 | Enemy Body | 敵人物理碰撞 |
| 4 | Player Hitbox | 玩家攻擊判定 |
| 5 | Player Hurtbox | 玩家受擊判定 |
| 6 | Enemy Hitbox | 敵人攻擊判定 |
| 7 | Enemy Hurtbox | 敵人受擊判定 |
| 8 | Pickup | 拾取物 |
| 9 | Combat Zone | 戰鬥區域觸發 |

規則：Player Hitbox（Layer 4）的 Mask 偵測 Enemy Hurtbox（Layer 7），反之亦然。

### 4.3 Hit Stop 實作

```gdscript
# 在 game_manager.gd（Autoload）中
func hit_stop(duration: float = 0.05) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
```

### 4.4 戰鬥區域鎖屏

```gdscript
# combat_zone.gd
class_name CombatZone extends Area2D

@export var enemy_scenes: Array[PackedScene]
@export var spawn_points: Array[Marker2D]

var enemies_alive: int = 0

func _on_body_entered(body: Node2D) -> void:
    if body is Player:
        lock_camera()
        spawn_enemies()

func lock_camera() -> void:
    var cam = get_viewport().get_camera_2d()
    cam.limit_left = int(global_position.x - 640)
    cam.limit_right = int(global_position.x + 640)

func spawn_enemies() -> void:
    for i in enemy_scenes.size():
        var enemy = enemy_scenes[i].instantiate()
        enemy.global_position = spawn_points[i % spawn_points.size()].global_position
        enemy.tree_exited.connect(_on_enemy_defeated)
        get_parent().add_child(enemy)
        enemies_alive += 1

func _on_enemy_defeated() -> void:
    enemies_alive -= 1
    if enemies_alive <= 0:
        unlock_camera()

func unlock_camera() -> void:
    var cam = get_viewport().get_camera_2d()
    cam.limit_left = -10000000
    cam.limit_right = 10000000
    # 顯示 "GO!" 提示
```

---

## 五、推薦參考資源

### 開源專案（直接學習）
- **Quiver Beat 'em Up Template**：github.com/quiver-dev/template-beat-em-up（Godot 4 完整範本）
- **WIL-TZY Retro Beat 'em Up**：github.com/WIL-TZY/beat-em-up（Godot 4.3，正交 3D 方案）

### 教學
- **QuestGameDev**：10 小時完整 Beat 'em Up 教學（questgamedev.com）
- **GDQuest Hitbox/Hurtbox**：gdquest.com/library/hitbox_hurtbox_godot4/

### 美術資源（原型期可用）
- **OpenGameArt.org**：免費遊戲素材
- **itch.io Asset Store**：大量像素風格角色 spritesheet

---

## 六、時程預估總覽

| 階段 | 預估時間 | 累計 |
|------|---------|------|
| Phase 0：原型驗證 | 1-2 週 | 2 週 |
| Phase 1：戰鬥系統 | 2-3 週 | 5 週 |
| Phase 2：敵人 AI | 2-3 週 | 8 週 |
| Phase 3：關卡系統 | 2-3 週 | 11 週 |
| Phase 4：UI 與流程 | 1-2 週 | 13 週 |
| Phase 5：多人合作 | 1-2 週 | 15 週 |
| Phase 6：美術音效 | 持續進行 | — |
| Phase 7：打磨測試 | 2 週 | 17 週 |

**預估總開發時間：4-5 個月**（一人開發、每天投入 2-3 小時）

---

> 最重要的建議：**Phase 0 做完就開始找人試玩**。打擊感對不對、操作順不順，越早驗證越好。
