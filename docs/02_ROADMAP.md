# 开发路线与验收

采用完成标准驱动，以下为工作顺序，不承诺未经评估的工期。

| 阶段 | 交付物 | 完成标准 |
|---|---|---|
| M0 策划冻结 | 玩法文档、范围、资产规范 | 核心任务和失败/成功定义清晰，首版范围可执行 |
| M1 斜俯视原型 | 屏幕方向移动、正交镜头、雪地地图 | 能完成小屋→车站→小屋；室内切开屋顶；移动不穿碰撞 |
| M2 生存闭环 | 天气、体温、体力、物品、火炉、任务、保存 | 能成功也能失败；补给不无限重复领取；暂停冻结模拟；读档恢复状态 |
| M3 人物生产 | Blender 主角 + Mesh2Motion 动作 | 原地 idle/walk/run/crouch 四类先通过；肩膝不明显塌陷；脚底高度正确 |
| M4 美术与声音 | 手工关卡、美术资产、粒子、环境声 | 远近层次、冷暖辨识和路标成立；雪粒不遮挡核心信息 |
| M5 20～30 分钟 Demo | 支线补给点、途中事件、引导、平衡、Windows 导出 | 第一次玩家无需口头指导完成；完整往返没有阻断；发布包独立启动 |

## 本轮实现目标

M0～M2 已有可运行且通过验证的原型。v0.2 扩充探索、饥渴、制作、庇护所和磁带机；M3 已导入原创 Blender 骨骼角色与三段循环动作，M4 已有第一轮材质与声景，二者仍需精修。M5 的完整事件、试玩平衡与独立导出尚未完成。验证结果见 `03_BUILD_STATUS.md`。

v0.3 已推进雪地形变、树形差异、8 段 Mesh2Motion 动作、实录脚步与呼吸、分层配乐和分类行囊。具体完成情况及剩余边界以 `06_POLISH.md` 为准。

下一轮顺序：试玩物资和电池经济及音量比例；打磨动作脚滑、手部对准和更多手工场景；加入磁带留言和天气事件，使探索、返回庇护所和剧情形成更长体验。

## 技术组织

- Godot 4.7.2 标准版，GDScript，Compatibility 渲染器作为原型基线。
- `scripts/expedition.gd`：v0.2 生存、背包、制作、音乐增益与存档；`survival.gd` 保留旧版规则参考。
- `scripts/player_ranger.gd` 继承 `player.gd`：移动、正交镜头、脚印与 GLB 动画播放。
- `scripts/world_polish.gd` 继承 `world_expansion.gd` / `world.gd`：新版雪地与局部形变、树木、探索地点、营地、修缮和碰撞。
- `scripts/backpack.gd` / `inventory_slot.gd` / `item_icon.gd`：物品、拖放、制作与探索日志。
- `scripts/cassette_audio.gd`：磁带循环、环境声与脚步。
- `scripts/main.gd`：任务、交互、菜单、HUD、保存与地图。
- `tests/expedition_test.gd`：v0.2 的 36 项规则检查；主程序 `--integration` 检查真实场景与磁盘保存。
- 场景/资源进入 Godot 前保持米制、应用缩放、检查法线与碰撞。正式资产通过 GLB 导入。

## 角色动作制作路线

用户提出的 meshtomotion 按 Mesh2Motion（https://mesh2motion.org/）理解。已核对官方资料：支持模型绑定和选择动作，多个动作可打包为 GLB；其仓库内美术/骨架/动作采用 CC0，代码 MIT。外部导入模型按各自来源记录授权。

1. Blender 制作穿固定服装的人形角色，A/T 姿势，约 1.75 米高；应用旋转和缩放。
2. 导出干净 GLB，导入 Mesh2Motion，选择人形骨架并调整肩、肘、手、髋、膝、足的位置。
3. 优先 idle、walk、run、crouch（以实际库中可选动作为准）。抖冷、跛行、护脸和添柴等不假定现成，需要检查或 Blender 补作。
4. 导出同一骨架的模型与动作；回 Blender 检查穿模、脚滑、膝关节和背包权重。
5. Godot 导入后制作玩家外观子场景。原型程序移动负责位移，循环动画采用原地动作，避免根运动双重位移。
6. 用 AnimationTree 以水平速度混合 idle/walk/run，蹲行单独状态；交互动作分阶段接入。
7. 导入资源放 `assets/characters/`，以来源、日期、动画列表、修改记录建资产台账。必须先拿真实 GLB 完成一次导入测试，再认为管线验收。

v0.2 建立原创角色，v0.3 从 Mesh2Motion 官方动画库取得 8 段动作并在本地 Blender 重定向、烘焙和导出。v0.4 重建对称腿部步态，加入运行时足部 IK 与坡面鞋底对齐。当前源文件 `source_art/ranger_motion.blend`，导入资源 `assets/characters/ranger_motion.glb`；包含独立蹲行与基础交互。手部对准和更细致的交互阶段仍待制作，来源与映射见 `06_POLISH.md` 和 `07_FRONTIER.md`。

## 验证清单

- 自动：温度变化、室内/炉火回暖、物品容量、一次性拾取、零件任务、保存恢复、失败状态。
- 引擎：无脚本解析错误，运行时无错误日志，真实渲染截帧目检。
- 人工试玩：屏幕方向移动、缩放、前景树遮挡、室内进出、两条路线、交互视线、暂停/读档/失败重试。
- 性能目标：用户 R5 5600 / RTX 3070 Ti / 16GB，1080p 目标 60 FPS。只有实际测量后才能报告达标；原型不能代表最终美术负载。

## 参考来源（2026-09-08 核对）

- Mesh2Motion：https://mesh2motion.org/
- 官方项目与许可：https://github.com/Mesh2Motion/mesh2motion-app
- Godot 第三人称镜头：https://docs.godotengine.org/en/4.7/tutorials/3d/spring_arm.html
