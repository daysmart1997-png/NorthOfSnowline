# 用户提供的带动作 Tripo 主角 · v3

- 用户原文件：`tripo_convert_97352c66-5e8a-44b8-9646-f187011f4bea.glb`，本目录 `original.glb` 为逐字节副本。
- SHA-256：`5c6197b9fd67d5f686780d15090606a3c22f8827118e2891103d5a10d6347a9a`；15,868,676 字节。
- 原始文件：11,000 三角面、41 骨骼、蒙皮、8K 颜色图集；三段 `preset:biped:standing_relax.001` / `walk.001` / `run.001`。原始数据与已有 v1/v2 完整保留。用户提供素材，不据此宣称 CC0 或另授开源许可。
- `ranger.blend` 为 Blender 5.2.1 LTS 适配源，运行导出为 `assets/characters/ranger_supplied_v3.glb`，2K JPEG 图集。身高统一 1.88 m，朝向转为 Godot -Z，骨骼兼容名映射；不重排原始关节位置，不替换原始蒙皮权重。
- 自带三段保留原始姿态。Walk/Run 原文件各含两周期，选取完整单周期并对齐落脚，去除髋骨的线性平移，保留重心/摆臂/腿部细节；循环接缝做短过渡。Idle 保留约 17.58 秒放松动作。详细裁剪帧与尺度后参考速度见 adaptation.json。
- CrouchIdle/CrouchWalk 从已记录来源的本地 motion_v2 转到新骨架，按新踝高修正足部轨迹；Pickup/Interact/Consume 以用户 Idle 姿态为底，加入本地俯身、屈膝及双臂到达目标位置的动作。后五段不是声称来自 Tripo 的额外预设。
- 重建：从仓库根目录运行 Blender `--background --python tools/adapt_supplied_ranger.py`。只更新此目录适配源/报告与新运行资产，不运行旧批量制作或旧骨盆/腿部重写脚本。
- 原始 GLB、Blender 与运行 GLB/JPEG 走 LFS；`.blend1` 仅本机备份，测试截图/日志在忽略目录 artifacts。
