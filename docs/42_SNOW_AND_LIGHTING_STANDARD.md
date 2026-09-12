# 视觉标准场景：雪、木材与炉火

2026-09-12，Windows，接续 docs/40 的 B 批。范围为长期护林小屋、维修间、炭工木屋与相邻雪面。延续固定斜俯视和 Compatibility；这是一次视觉精修，不代表整个试玩版已达到发行品质。

## 实际改变

- **雪丘光照**：原高度图每半米采样，却用 6.5 cm 间隔计算地形坡面法线，在黄昏侧光下暴露出连续格状条带。改为地形梯度 0.50 m（山体平滑过渡至 0.65 m）、脚印梯度仍独立用 0.065 m。没有改动地形顶点、碰撞、雪深、脚印位置或压痕深度。关闭地形投影的隔离对照未消除主要条带，因此没有把关闭地形阴影当作修复。
- **积雪微表面**：沿用已记录来源的 ambientCG Snow004 1K 法线/粗糙度。地面与旧小屋雪顶共用 `snow_detail.gdshaderinc`，混合两种不同周期、旋转后的采样，并将法线旋转回世界坐标；通过世界米/像素抑制远景和小视口里的细颗粒。压实脚印和冰面仍单独抑制松雪细节。
- **木、布、金属**：长期小屋、维修间及沿用这组材质的箱体，木纹改用沿板方向的低对比非周期变化，避免贯穿整面墙/地面的正弦带；布料、金属按表面方向生成织纹/不规则磨损，并抑制亚像素条纹。保留原有底色、材质职责，以及新聚落/其他模型自带的 PBR 贴图。没有重建或替换 GLB/Blender 文件。
- **夜晚与暖光**：稍抬高冷色夜间补光，降低近地平线长影的支配程度，太阳路径和生存时刻不变。护林小屋门灯的照明范围略增；炭工木屋的窗外光补入雪面/人物图层，仍严格跟随真实炉火燃料亮灭。
- **室内落地感**：火炉光源移到炉身前面，避免被自己的铁壳遮住；只为玩家当前所在且已点火的房间启用一盏炉火动态阴影。投影者限该房间与人物，屋外树木不能向剖切室内投影；熄火、换屋和离开时释放不用的阴影。背景视口、室内家具与玩家仍维持原图层隔离。

## 可继续调整的尺度

| 控制 | 当前值 | 约束 |
|---|---|---|
| 地面/屋顶雪纹理世界尺度 | 2.8 m | 两种周期混合；不是新增几何位移 |
| 松雪/雪顶法线强度 | 0.18 / 0.10 | 压实区、冰面额外抑制 |
| 雪粒衰减 | 0.075～0.18 m/像素 | 适应正交镜头缩放，不能只看相机距离 |
| 地面雪粗糙度 | 0.86～0.97 | 冰面保留自己的粗糙度分支 |
| 地形/脚印法线差分间隔 | 0.50～0.65 m / 0.065 m | 不能把脚印一起抹平 |
| 室内炉火阴影浓度 | 0.72 | 火灭关闭；只开当前房间 |
| 夜间环境能量/补光峰值 | 0.36 / 0.30 | 保留夜晚明暗差；不是提升体温或降低风险 |

## 固定取景与复现

捕获前明确结束可能存在的开场并断言玩家镜头归属；旧工具的 `elapsed` 已不再等于新旅程太阳时间，现在生存太阳时间、天气和室内环境使用同一时刻，保留新旅程 `clock_offset`。等待室内切换按时间而非固定渲染帧数，防止机器帧率影响取景。静态设置时刻/燃料仅发生在隔离检查场景中，不能把它当作真实走完章节的证据。

```sh
python tools/run_visual_slice.py --godot <Godot> --label material-final
python tools/run_visual_slice.py --godot <Godot> --label material-final --profile
python tools/run_visual_slice.py --godot <Godot> --label material-interior --profile --profile-room lodge
python tools/run_checks.py --godot <Godot>
```

截图包括小屋清晨 06:00、正午 12:00、暮色 17:30、夜晚 23:00、暴雪、室内，聚落暮色/夜晚，炭工木屋冷屋/有火，维修间，以及正常游玩缩放的 17:00 HUD。输出在 `artifacts/visual-slice/<label>/`，共 12 张。诊断开关 `--terrain-shadow-off` 仅供排查，正式对照不能携带此参数。

本地修改前同条件基线为 `material-baseline`，最终为 `material-final`；中间 `shadow-probe`、`terrain-shadow-probe`、`softer-shadow` 和 `material-pass1/2` 留作诊断记录，不当成最终结果。

## 技术参考与素材边界

查阅 Godot 官方 [spatial shader](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)、[shader preprocessor](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shader_preprocessor.html)、[Light3D](https://docs.godotengine.org/en/stable/classes/class_light3d.html) 和 [lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)，用于核对坐标空间、共享着色器、投影偏移与图层。没有复制外部实现、下载新资产或引入插件。Snow004 的许可、源链接和哈希仍见 `assets/textures/snow004/source.json`。

## 后续

本轮 Windows 验证：import + 30 组一次完整通过，`artifacts/material-polish-regression.log`；原生动作接触检查 `artifacts/material-ranger-native.log` 通过。新视觉专项涵盖三屋投影者图层、换屋、灭火及室外释放，原有雪深/碰撞/脚印和场景检查保留。

RTX 3070 Ti、1280×720、VSync 关闭、原生强制绘制、2 秒预热 + 6 秒样本：

| 静止场景 | 平均 / P95 帧耗时 | 样本数 | 边界 |
|---|---|---|---|
| 小屋外正午，修改前 | 2.035 / 2.397 ms | 2948 | 修正取景工具后、改动材质之前 |
| 小屋外正午，最终 | 2.118 / 2.556 ms | 2833 | 绘制调用同为 409，三角形同为 1,168,697 |
| 炭工木屋有火，最终 | 1.592 / 2.052 ms | 3769 | 包括室外背景；无修改前同条件室内样本 |

报告在对应目录的 `performance.json`；室内目录为 `material-interior`。短样本包括调度波动，不据此承诺整章帧率。候选索引 735 文件、252 LFS 资产，凭据/大小写/LFS/空白审核通过；真实暂存区保持不变，无提交/推送。

本轮没有制作新树型、补完所有屋内陈设、重制角色或接入新声音。场景空地组织、自然/建筑交界的微叙事、人物近景、动物接地与磁带的可听叙事仍需下一批处理。Mac 实景、长时连续移动、不同显卡/分辨率和陌生玩家试玩须分别验证；静态截图和短时性能样本不能替代它们。
