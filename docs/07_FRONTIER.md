# v0.4 · 地形、步态与林场建筑

2026-09-09。本轮保持斜俯视正交镜头，继续在 Godot 4.7.2 项目中开发。

## 已接入游戏

- 地形：西岭高地、东北高地、背风洼地、湖湾与连接两岸的旧木桥。积雪厚度由背风积雪、风口暴露、坡度和地表类型决定，不再把海拔当成雪深。上坡与深雪会减缓移动。新增三个发现地点和三处补给，探索地点共九处。
- 步态：保留 Mesh2Motion 上身和交互动作来源，重新烘焙左右对称的行走、奔跑、蹲行腿部轨迹；骨盆连续起伏，步幅与实际速度匹配。修复父骨骼未刷新引起的脚掌异常翻转。运行时两条脚下射线驱动双腿 IK，并让鞋底随坡面倾斜。
- 雪痕：根据脚下雪深、坡度、奔跑/蹲行和负重计算凹陷。落脚位置来自实际骨骼脚下的地面接触点。深雪中同侧连续落脚留下带宽度变化和轻微摆动的拖痕；进入冰面或木地板会断开。痕迹随降雪填平，当前最多保留 240 条鞋印或沟痕记录。
- 美术：按本轮生成的林场建筑概念图，在 Blender 中重建小屋、室内、木桁架桥和帆布营地。保留可编辑 `.blend` 和运行时 `.glb`。共同使用风化木板、暗铁连接件、石基、灰绿帆布、厚雪檐和小范围暖灯。
- 室内：木地板、床褥与被子、无线电桌、物资架和罐子、铸铁炉与烟管、写字桌、工作台与修理工具、挂衣与铁锹、柴堆。屋顶及近侧墙切开，修床、储物箱、封窗会显示对应模型。门廊和桥头有连续斜坡碰撞。
- 界面：灰蓝帆布、旧纸色地图、暖褐选中状态；标题使用宋体风格，正文使用清晰无衬线字体，常用文字至少 14 px。菜单与行囊打开后压暗场景、隐藏外围 HUD。六类物品、拖放磁带与帆布展开/收起动画保留；地图加入示意等高线、冻湖和新地点。

## 建筑源文件与生成记录

- 概念图：`source_art/concepts/forestry-architecture-v04.png`。
- Blender：`source_art/architecture_cabin.blend`、`architecture_bridge.blend`、`architecture_camp.blend`。
- 导出模型：`assets/architecture/cabin.glb`、`bridge.glb`、`camp.glb`。
- 可重复建模脚本：`tools/build_architecture.py`。它按概念图重建可读的结构与陈设，并非由图片自动推断的精确三维扫描。
- 生图方式：内置 Image Gen，原创建筑风格板，无参考图片输入。本轮最终提示词如下。

> Use case: stylized-concept. Asset type: original 3D game architecture production reference sheet for the winter survival game North of the Snowline. Create a coherent architectural style sheet showing four complementary isometric studies on a quiet blue-gray paper background: a small northern forestry ranger cabin exterior, a cutaway of its furnished interior, a sturdy timber trestle footbridge crossing a frozen lake inlet, and a survival camp with patched canvas ridge tent and low log windbreak. Style: restrained painterly stylized 3D, simple readable silhouettes and hand-hewn construction, desaturated blue-gray winter snow, aged dark timber, muted rust-red boards, dull iron fasteners, olive-gray waxed canvas, tiny amber lantern/window accents. Camera: consistent angled overhead orthographic game view, around 50 degree pitch. Architecture: steep gabled roof with thick uneven snowy eaves, stone footings, visible rafters, porch railing, firewood rack, shuttered small windows, iron stove chimney; interior with plank floor, pot-belly stove, stovepipe, cot with wool blanket, small radio desk, shelves with jars, hanging coat, tools and log basket; bridge with cross-bracing timber bents, solid plank deck, simple railings, metal joining plates and snow on beams; camp with sagging canvas seams, rolled door, ropes and stakes, bedroll, kettle and firepit. Design should be feasible to model and visibly share materials and joinery across all four structures. No people, no brands, no watermarks, no typography, no modern glass building, no fantasy ornament, no UI. Clean production concept art with enough clear construction detail for rebuilding in Blender. Wide landscape composition.

Mesh2Motion 与音频的来源、许可沿用 `06_POLISH.md`。本轮新增腿部步态由项目自行烘焙；没有将新步态冒充上游原动画。

## 验证与体验路线

从桌面“雪线以北 Demo”启动。先在小屋内查看工作台、炉具和陈设，再出门向北走过桥；向西可以走上高地，向东到背风洼地比较深雪阻力与拖痕。Tab 查看地图，B 整理行囊。老存档仍可读取，地面高度重新适配；玩家存档未被开发测试覆盖。

- `tests/expedition_test.gd`：36 项生存与物品规则检查。
- `--integration`：真实输入出入建筑、墙体碰撞、过桥、拾取与无线电任务、建造、储物、声音、存档覆盖和读取。
- `--polish-test`：动作与落脚/声音联动、脚印深浅与覆盖、六类物品、真实鼠标点击和拖放磁带、开合中断、暂停恢复及呼吸音频。
- `--frontier-test`：高地/洼地/冻湖高度与积雪差异、连续沟痕中点形变、冰面断痕、坡地实时 IK、连续步态鞋底朝向、冰面碰撞、室内模块与九处发现地点。
- `artifacts/v04-gait-55.png` 等为实际 Godot 连续行走的不同帧；建筑、背包、地图与深雪均有实际渲染截图。`v04-*.log` 保存本轮检查记录。

## 当前边界

地形有真实碰撞，脚印是周围 24 米区域内的渲染形变；微小雪坑不重建物理碰撞，也不写入存档。足部贴坡限制在约 22 cm 校正范围内，尚未实现攀爬或精确踩台阶。冻湖目前是可行走的完整冰层，尚无破冰落水。地图等高线是地形示意，未输出精确测量图。

建造仍采用有选址校验的预制营地和小屋修缮；木桥是已有场景建筑，尚不能由玩家逐段建桥。背包为二维帆布开合，尚无三维卷曲。角色造型、手部精准交互、更多故事事件仍需要后续制作。

本轮修改前备份：`artifacts/before-v04.zip`。
