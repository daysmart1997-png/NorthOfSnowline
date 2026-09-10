# Tripo 主角接入 · 2026-09-10

用用户提供的彩色绑定版替换游戏主角外观，保留原有移动、生存、脚印和装备状态。运行时与人物页共用 `player_ranger.gd` 的 `MODEL`，避免只替换世界角色、人物页仍显示旧模型。

## 资源与动作

- 最新原文件为 `source_art/tripo_ranger/rigged-original.glb`；加工源 `source_art/tripo_ranger/ranger.blend`；运行资源 `assets/characters/ranger_tripo.glb`。以前的 ranger_equipment 系列完整保留。
- 原文件是 10783 三角面 / 41 骨骼的蒙皮模型，有 8K 贴图但无动画。没有将此前界面的 Quad 面数当作 GLB 面数。
- `tools/prepare_tripo_ranger.py` 单独制作此角色：统一 1.88 m 与前向、调整踝关节/对称腿链、保留扭转辅助骨、放松 A 姿势手臂、八段动作迁移和步态重建。背包刚性跟随躯干，避免蹲行时被腿骨拉扯。
- 步态保留 Walk / Run / CrouchWalk 相位约定，沿用运行时地面取样、坡面 IK、接触事件与脚印，不改生存步速。Idle / CrouchIdle / Pickup / Interact / Consume 同时保留。
- 游戏图集缩为 2048，GLB 约 1.5 MiB；8K 原图仍内嵌于原始 GLB。Blender 源已打包，没有引用用户下载路径。

## 材质与换装

七个材质面共享图集：六装备位加面部/围巾细节。`tripo_clothing.gdshader` 保留 UV 明暗/缝线，换衣服改变相对染色，湿衣适度变暗；躯干等分区保留暖色围巾与皮革细节。`character_sheet.gd` 仍从统一 FieldKit 读取衣物实例，不另建状态。

旧角色材质处理保留。若需要对比旧模型，只改 `player_ranger.gd` 的 `MODEL` 到 `ranger_equipment.glb`，世界和人物页一起切回；Tripo 专项测试针对新资产，此时不应期望其通过。

## 实际验证

工具环境：Apple M2 / macOS / Godot 4.7.2.stable.official.ed1daf0bf，Compatibility（OpenGL 4.1 Metal）；Blender 5.2.1 LTS。

- 新增 `tools/tripo_asset_check.gd`：直接检查 Godot 导入资产的骨骼/足部名、10783 三角面、1.88 m 尺度、全部 UV/归一化权重、共享 2K 图集、六分区默认色/湿度/换装、面部保护、原材质不可变以及八动作。
- `ranger`：导入模型 80 相位左右半周期对称，实际走跑蹲/停止重启、交替接触、足印和坡面修正。
- 原生 1280×720：正背面、走/跑/蹲行分相、三种交互、呼气阶段；人物衣着/身体页；真实移动路线上的走跑蹲截图。素材为新导出后的实景渲染，不是概念图。证据在 `artifacts/ranger-finish/tripo`、`artifacts/ranger-finish/live`、`artifacts/tripo-ranger/field`。
- 人物页截图工具改为显式绘制后读取，避免 macOS 遮挡窗口时等待 `frame_post_draw` 而无输出；原生 field 成功标记已检查。
- 全套检查、源文件检查和仓库审计的最终结果见 `PROGRESS.md` 最新节；日志在 `artifacts/tripo-ranger` 与 `artifacts/checks-*.log`。

## 限制与接续

保留用户此前的小鹿修复与参考素材。未录屏、未写玩家 savegame.json、未提交或推送。没有此次帧率数据，也不把静态分相检查当完整人工通关或动画专业验收。

现阶段换装仍是同版型染色，面片分区并非逐件手工拆衣。自动生成网格和权重可继续精修，特别是肘部厚衣、蹲行裤褶、手掌握持；无手指/表情/持弓专用动画。Windows 拉取源码与 LFS 资源后运行全套检查，并复看人物页和行走，不能将 Mac 通过报告为 Windows 已通过。
