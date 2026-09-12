# 标题画面与真实落脚同步

2026-09-11，Windows / Godot 4.7.2 Compatibility。本轮响应玩家反馈：奔跑脚印与脚部错位、开始界面缺少游戏特色。

## 脚印与声音

旧逻辑在动画周期的两个半段边界生成脚印，地面采样也发生在当前动画与脚部修正之前。模型换用提供的动作后，半周期边界并不等于实际落地，奔跑时上一帧的位置误差尤其明显。

- `player_ranger.gd` 的 AnimationPlayer 与 Skeleton3D modifier 都按物理帧更新。`grounded_feet.gd` 在当前动画姿态上采样地形，在完成双腿修正后调用落脚检测；平滑也使用物理帧时间。
- 每只脚离地超过 0.105 米后重新允许触发，回到地面上方 0.075 米以内才产生一次接触。数值针对当前模型接近鞋底的 foot 骨骼标定，不是任意角色通用的踝高。左右脚交替、最小时间间隔和位移共同抑制重复印记；停走重启会重新允许下一只脚触发。
- 印记位置取当前最终脚骨骼向下射线的交点，旋转取脚部相对绑定姿态的实际朝向。脚步声与雪印使用同一次落地事件；保留雪深、压力、坡度、深雪连痕及高处物体不向下穿透印雪的规则。
- 保留提供的站立、行走、跑步动画及现有衍生动作，没有重新导出角色或更换声音资产。本轮解决事件时机和空间对齐；不是整套脚底锁定、滑步消除或任意高台攀爬 IK。

工具：`tools/inspect_contacts.gd` 可测量模型各步态的脚部高度；`tools/ranger_check.gd` 在真实移动、走跑/蹲行切换、停走和连续奔跑转向时，独立检查当前骨骼、落地采样及雪印位置，不只检查事件数量。

## 开始画面

`scripts/title_screen.gd` 是展示层，由 `main.gd` 接入现有 Canvas 和菜单。设计主题为“风雪中的守听”：左侧大字宋体、短引言和留白菜单；右侧实际三维小屋与暖窗；冷色渐变保证文字对比，底部无线电刻度和克制的金色指针延续失联故事。

- 使用现有世界、木屋、雪粒和冬季音乐，加入极轻的镜头漂移、音乐淡入及按钮焦点反馈；无需新增位图或第三方素材。
- 标题镜头隐藏主角，仅设置展示用天气/光照，不推进生存时钟或改变背包。开始旅程后交还山口开场镜头，开场结束后交还玩家镜头；读档和暂停使用真实旅程状态。
- 标题页收起快捷键说明，暂停页保留两行操作提示；新旅程、手动存档、安全节点、设置、退出与原逻辑连接。音乐继续经过 SnowMusic 总线，遵守已有音量设置。
- 中文标题按 Songti SC → SimSun → Noto Serif CJK SC 选择系统字体；Windows 已查看，Mac 的字体实际效果还需复验。现有视口缩放策略保持不变。

## 验证与证据

- Windows / RTX 3070 Ti / Godot 4.7.2：原生 60 FPS 与 headless 30 FPS 固定调度的角色专项均 `RANGER_CHECK_OK`，最终各记录 22 次落脚；走、跑、蹲、停走和转向期间印记中心与同帧脚部水平坐标误差小于 0.001 米，触发高度不超过 0.0751 米。固定调度检查不是设备性能测量。
- 原生 1280×720 和 1920×1080：`TITLE_CHECK_OK`。检查标题、设置、暂停、开始旅程、镜头交接、隔离存读档及生存时钟，并实际查看开始页、设置页、暂停页与角色运动截图。
- 专项日志：`artifacts/foot-sync-native.log`、`artifacts/foot-sync-30.log`、`artifacts/title-native-check.log`；菜单截图在 `artifacts/title-review/`，角色截图在 `artifacts/ranger-finish/live/`。日志、截图、测试存档均为本机忽略文件。
- 完整回归与最终状态见 `PROGRESS.md` 本轮记录。新 `tools/title_check.tscn` 已纳入 `tools/run_checks.py`，累计 26 组。所有本轮检查使用隔离设置，不写玩家存档。
- 本轮未在 Mac、超宽屏或长时间实际游玩中验证，也未重跑完整求援往返。未增加模型资源、未录制视频、未提交或推送。

## 实现参考

Godot 官方 [Skeleton3D 更新回调](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html)、[AnimationMixer 更新模式](https://docs.godotengine.org/en/4.5/classes/class_animationmixer.html) 和 [SkeletonModifier3D 更新顺序说明](https://godotengine.org/article/design-of-the-skeleton-modifier-3d/)。本轮查证更新顺序，未复制外部项目代码。

后续接续：先在 Mac 检查标题字体与走跑印迹；角色若更换骨架或动作，重新测量脚部高度再调整接触阈值。建筑细化继续按长期护林小屋 → 维修间顺序推进。
