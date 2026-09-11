# 低矮原木屋 · 2026-09-11

设计沿用 `source_art/concepts/architecture_v3/direction-board.png` 的第二栋建筑：低矮横向原木、小窗、宽屋檐、石基和侧棚。该图是已确认的生成式概念参考，不是实机截图。

本批 `charcoal_lodge_v3.blend` 与 `assets/lodge_refinement/charcoal_lodge_v3.glb` 为本项目定向制作；旧 arrival 资产保留。木材、铁材的颜色/粗糙度/法线由程序生成，布料共享微弱织物法线。没有下载第三方素材或移植第三方 shader，也未新增开源许可证。

工具：Blender 5.2.1 LTS，执行 `blender --background --python tools/build_lodge_refinement.py`。脚本从自身位置定位仓库，读取历史脚本辅助函数和山口脚本中的纯纹理函数，不执行它们的场景生成部分。该命令会覆盖本目录源和对应导出/贴图，仅在需要再制作此屋时运行。

Blender 源保留未合并部件并打包贴图；外部路径是仓库相对路径。GLB 按结构组/材质合并，保留 FireWindow、Roof、CutawayFront、CutawayRight；侧棚属于 CutawayRight，进入房间后一起隐藏。导入后需检查木材和铁材仍保留颜色/粗糙度/法线，布料保留法线；不应被旧 Timber 材质覆盖。

补给台下层的三根木柴由游戏按实际余量生成，不在 Blender 中放无限装饰柴。绷带和电池留在台面。炉、床、路线纸坐标保持原交互范围，外部侧棚碰撞单独登记在 ArrivalCatalog；修改模型必须同时复验进门/拿柴/点炉/卧铺/路线纸/绕屋路线。

源文件、导出 GLB、PNG 和资源旁 .import 使用 Git LFS/既有 Git 规则；不要提交 .blend1、.godot 或测试存档。
