# Tripo 主角 · 来源与接入（2026-09-10）

最新的带贴图、绑定版已接入游戏。此前灰模检查保留供追溯；用户下载的文件均未修改。

## 原始素材

- `original.glb`：用户最初提供的 `冬季人物3d模型.glb`。5442 顶点、10783 三角面，灰色单材质，没有 UV、骨架、动画；`inspection.blend` / `inspection.json` 保留当时的检查。89 条开放边、9 个连通分量，未自动焊接补洞。
- `rigged-original.glb`：用户最新提供的 `tripo_convert_0bcbfe0e-64fe-47e2-870f-4e3267511f91.glb`，原样保存。12702 个含 UV/法线分裂的顶点、10783 三角面、41 骨骼及权重、一张 8192×8192 JPEG，没有动画。SHA-256 和元数据在 `adaptation.json`。
- 中间的 `tripo_convert_729fe96a-9a2a-4401-9b26-b3301f194195.glb` 已只读检查：有相同贴图但无骨架，因此采用后一个更完整的文件。
- 模型由用户使用 Tripo 制作/提供，元信息为 Beijing VAST AIGC Content；没有收到额外许可文件，不将其标为 CC0，不为原模型另行授权。参考图来源见 `../ranger_tripo_v1/README.md`。
- 动作来自本仓库 `ranger_equipment.blend` 已有八段动作，沿用既有 Mesh2Motion CC0 上身/交互素材和本项目步态修改。上游许可存档在 `../mesh2motion/UPSTREAM-README.md`，详细出处见 `../../docs/06_POLISH.md`。这不改变 Tripo 模型自身的权利状态。

## 可编辑源与运行资源

- `ranger.blend`：Blender 5.2.1 LTS 可编辑源，保留 41 骨骼、蒙皮、UV、七个材质分区和八段动作。图片已打包；NLA 动作以 `Ranger_` 命名并静音，打开后可从 Action Editor 选择查看。
- `../../assets/characters/ranger_tripo.glb`：独立游戏导出，约 1.5 MiB。旧角色源/导出完整保留。
- `ranger_tripo_Ranger_Tripo_Atlas.jpg` 和相邻 `.import`：Godot 从 GLB 提取的 2K 贴图，应与 GLB 一并保留，不依赖下载目录。完整 8K 版本仍在原始 GLB 内。
- Blender 导入时生成的骨骼显示用 Icosphere 已排除，导出只有角色网格；没有通过细分虚增面数。

## 制作方式与约定

从仓库根目录使用 Blender `--background --python tools/prepare_tripo_ranger.py`。工具从自身文件定位仓库，只读取两个源文件并生成上述 Tripo 源/导出，不执行历史批量资产重建工具。

统一高度 1.88 m，Blender 朝 +Y / Godot 朝 -Z；游戏沿用 `.L` 为 +X 的历史骨骼约定，与 Tripo 原左右命名交换。修正自动绑定的脚底附近踝关节，校准对称髋膝踝；保留辅助扭转骨骼。八段动作适配到新休止姿势，走/跑/蹲行用两节腿 IK 重建支撑与摆动，背包权重固定到躯干。

六个装备区域共享同一 UV 图集，面部/围巾细节另保留原材质；运行时按衣物实例的配色和湿度调整，默认装备保持原始贴图颜色。换装仍为同版型颜色/属性变化，不是独立服装模型。面片区域由制作工具依据空间/权重划分，后续独立衣服制作应在 Blender 手工细化分区。

当前没有手指骨骼、面部表情或持弓专用动作，武器沿用已有挂点。本轮不声称专业手部握持、全动作穿插处理或完整章节人工试玩已完成。

Mac 原生静态检查与回归证据见 `../../docs/23_TRIPO_RANGER.md`，Windows 须拉取完整 LFS 后独立复验。未录屏、未写玩家存档、未提交或推送。

## 本轮动作调整 v2（2026-09-10）

当前游戏改用 `../../assets/characters/ranger_tripo_motion_v2.glb`，可编辑源为 `ranger_motion_v2.blend`，2K 图集的 Godot 提取图及 `.import` 一并保留。原 `ranger.blend` / `ranger_tripo.glb` 没有覆盖。

`tools/refine_tripo_motion.py` 从 `ranger.blend` 读取既有动作，调整 Idle / Walk / Run / CrouchIdle / CrouchWalk 的髋部高度、躯干前倾和反向摆臂，保留脚轨迹重新求解腿链；保留原 41 骨骼、10783 三角面、八段动作、UV 和装备分区。只在明确重制本轮动作时运行 Blender `--background --python tools/refine_tripo_motion.py`。

这仍是本地制作的步态修订，不是 Tripo 官方新动作；尚未收到用户的官方动作文件。运行时足部 IK 另修正膝盖弯曲平面与坡面法线归一化。实际检查、尚待真人动态验收的边界详见 `../../docs/25_CHAPTER_POLISH.md`。
