# 炭工聚落 · 第一晚

本目录三个 `.blend` 为可编辑源，运行导出在 `assets/settlement/`。制作于 Windows / Blender 5.2.1 LTS，2026-09-12。

- `canteen`：灰绿脱漆板墙、较高双坡雪顶、后墙食品架、拆走炉灶后的柜台和靠边餐桌。保留入口到食品架的连续通道。
- `woodshed`：矮雪顶、透风板条、两侧柴架和后方干柴台。架内固定少量受潮旧木，真正可领取的四根干柴由游戏状态显示/隐藏。
- `bunkhouse`：低长屋身、空床架与湿床垫、破隔挡、衣物桌和窗下积雪。床铺不能用于休息。

`tools/build_forestry_settlement.py` 只重建这三栋及其共用贴图。它读取已有架构脚本的几何辅助段，并通过 AST 选择材质辅助函数；不会执行历史批量建造脚本或重建旧模型。运行示例：

```
blender --background --python tools/build_forestry_settlement.py
```

模型保留 `Structure` / `Roof` / `CutawayFront` / `CutawayRight` 分组，源文件保存未合并物件；GLB 导出按组与材质合并。木材、脱漆和金属使用本项目原创程序生成的 1024 像素颜色、粗糙度、法线贴图，材质名为 Settlement 前缀以保留导入材质。源文件打包纹理；雪顶沿用项目 SnowCap / Snow004 材质流程。

没有下载新第三方模型、图片或音频，没有新增授权声明。沿用现有资源来源与许可记录。`.blend`、`.glb`、PNG 使用 Git LFS；Godot 提取贴图及 `.import` 一起保留。`.blend1` 为本地 Blender 备份，不提交。

运行碰撞、室内图层、物资与地图集中在 `arrival_catalog.gd` / `arrival_world.gd` / `interior_view.gd`，不要修改模型而遗漏这些边界。实际通行和第一晚存活验证见 `tools/first_night_check.gd`；静态艺术检视见 `tools/settlement_preview.gd`。
