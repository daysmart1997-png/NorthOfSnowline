# 山口与岗亭样板 · 2026-09-11

设计依据：`../concepts/architecture_v3/direction-board.png` 与 `docs/33_ART_DIRECTION_AND_MOUNTAIN_OPENING.md`。效果板由图像生成工具制作，只作美术方向参考；运行模型和贴图由本仓库脚本生成，不是效果图直接转出的资产。

- `road_kiosk_v3.blend` → `assets/mountain_pass/road_kiosk_v3.glb`：独立单坡铁檐岗亭，灰绿脱漆板墙、木框、窗洞、侧工具柜；保留原交互桌架与门口尺度。
- `mountain_ridge.blend` → 同名 GLB：三组远景山体。
- `cliff_ribs.blend` → 同名 GLB：近景不规则岩组，运行时复用并添加静态碰撞。
- wood / paint / metal 各三张 1024 PNG：color、roughness、normal。用 NumPy 程序生成，Blender 材质接线并随 GLB 导出；没有使用 Cycles 烘焙，也没有下载第三方纹理。贴图打包到 Blender 源，外部路径同时设置为仓库相对路径。

制作工具为 Blender 5.2.1 LTS。定向重建命令：

```sh
blender --background --python tools/build_mountain_kiosk.py
```

脚本从自身位置定位仓库，只读取旧建筑脚本的辅助函数定义，不运行旧脚本的场景构建段。仅在需要重建本目录资产时运行；它会覆盖上述三个源、三个导出与九张贴图。修改后同时审核源、导出、`.import`、材质保留与实际游戏画面。

造型与程序贴图为本项目制作，未新增开源许可证。Github 材质项目仅为先前技术调研参考，本批未复制代码/素材。原雪地贴图来源保持现有说明。二进制资产使用 Git LFS，Blender 备份不提交。
