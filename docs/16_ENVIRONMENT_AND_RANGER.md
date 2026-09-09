# 环境与角色收尾 · 2026-09-09

接续 [小屋视觉样板](15_VISUAL_SLICE.md)，本轮完成约定的环境收尾与角色精修。保持固定高位正交镜头、生存规则、地图规模和既有八段动作；新的 HUD、混音调整与剧情另排开发。

## 环境

- 树冠保留主干、粗枝与有选择的末梢，移除约四分之一主分枝、每簇中间叉和大多数三级细枝，让树形出现疏密。生成器仍消费相同随机数，树群位置、后续随机物资与碰撞不会因为删枝而洗牌。
- 桦树黑斑从密集硬条纹改为低频柔边、不连续的伤痕；树枝上积雪继续可见，但不重复投射细条阴影。没有增加树木网格绘制批次。
- 保持真实昼夜太阳方向，阴影不透明度按太阳高度连续变化（晨昏 0.34 到高太阳 0.84），风雪再降低最多 24%。保留长影作为时间线索，减轻满屏硬线。使用 Godot 的 [shadow_opacity](https://docs.godotengine.org/en/stable/classes/class_light3d.html#class-light3d-property-shadow-opacity)，没有引入另一套阴影插件或额外阴影贴图。
- 雪纹取样增加缓慢的世界坐标扰动，打散同一法线图的重复；复用原有低频噪声，不增加贴图采样，保留 3.5 m / 0.22 强度、压实与冰面抑制及物理高度。

## 角色

- 新运行模型 `assets/characters/ranger_refined.glb`；源文件 `source_art/ranger_refined.blend` 保留独立服装/装备，`ranger_motion.blend` 和历史导出完整保留。新制作入口 `tools/refine_ranger.py` 从旧精修源读取，只输出新文件，不重新下载/运行 Mesh2Motion，也不执行全量资产生成器。
- 深蓝外衣、橙帽、低饱和帆布背包、束带卷毯与腰间无线电；降低白色领边与金属感。新增装备是人物造型，不自动发放物品、磁带机或生存加成。
- 导出合并为一个带骨骼权重的网格、11 个材质面；源文件保留可编辑部件。清除旧模型四个重合扣子。布料纹理按像素覆盖淡出细线，降低微缩镜头下的摩尔纹与闪烁风险，不把高频噪声当作质感。
- 保留原 Mesh2Motion 适配的上身与三段交互动作，重做 Idle / Walk / Run / CrouchIdle / CrouchWalk 下肢。骨盆不再继承左右晃动，步幅按速度/周期/支撑时间匹配；双脚加入小角度脚跟着地、脚尖离地与摆动抬脚，计算鞋底最低点以避免平地滚脚穿地。
- 修正导出循环前多出的 1/30 秒静止段；跑/蹲行循环使用偶数采样间隔，确保左右半周期对齐。实际动作快慢仍由运行时根据速度设置，不通过延长循环改变人物移动速度。
- 走、跑、蹲行切换保留当前归一化步态位置；停下再起步交替落脚。低速时动画可继续降速，不被旧最低倍率拉着滑脚。负重产生小幅前倾，坡面鞋底法线平滑；原 ±22 cm 地形修正范围保持。
- 原生奔跑检查定位并修复白气偶发黑色圆斑：新 breath.gdshader 明确色彩/透明度、保留粒子尺度，粒子不投影。没有更换呼吸音或混音；工具增加一次呼气的四阶段画面，确认黑斑消失。

## 复验

```sh
python tools/run_checks.py --godot <Godot executable>
python tools/run_visual_slice.py --godot <Godot executable> --label finish
python tools/run_visual_slice.py --godot <Godot executable> --label finish --profile
godot --path . --resolution 1280x720 tools/ranger_preview.tscn -- --isolated-settings --ranger-output=finish
godot --path . --resolution 1280x720 --fixed-fps 60 tools/ranger_check.tscn -- --isolated-settings --ranger-capture
```

新增 ranger 检查直接验证导入模型八个动作、80 相位左右半周期对称、真实物理行走/奔跑/蹲行/停止重启的交替落脚与脚印。静态动作分解图保存在 artifacts/ranger-finish/finish；实际输入路线的三张近景在 live。两种证据分别保留，不把手工设定动作姿态的截图说成连续试玩或录像。

最终平台、性能、全套检查和仓库审计结果见 [PROGRESS.md](PROGRESS.md) 顶部最新条目。脚印仍只修改局部渲染网格；手部尚无逐目标 IK，陡坎没有攀爬或专用跨步。Mac 需要独立检查导入、渲染和 M2 性能，不能用 Windows 样本代替。
