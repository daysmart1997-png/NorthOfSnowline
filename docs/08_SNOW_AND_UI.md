# 门外脚印、雪面与界面优化 · 2026-09-09

本轮基于用户提供的三张截图，修改 v0.4 游戏；保留原有玩法、存档格式、建筑和角色资产。UI 参考所给《漫漫长夜》截图的简洁信息层级，使用原创绘制的单色图标，没有引入其游戏资产。

## 脚印规则

问题来源是 `terrain_profile.gd` 将地形平整遮罩同时乘在雪深上：门外、铁路和东侧林道的平地雪深变成零，`stamp_snow()` 因此跳过落脚。现在平地保留约 4.5–5.5 cm 的压实薄雪，地形高度与表层积雪分别计算。

- 使用左右脚射线接触点判断表面；清除丢失命中的旧采样，不在高于雪面的物件下方生成印迹。
- 薄雪留下较浅的独立鞋印。深雪的压缩深度随压力、雪深及坡度变化，最高 17 cm，且始终不超过可用雪深。
- 木屋、门廊、木桥和冰面排除；跨过薄雪会中断深雪拖痕，避免拖出横跨清理区域的长沟。
- 深雪脚印有较柔和的外扩边缘；拖痕压缩量为鞋印的 30%，逐步被降雪填平。仍保留最多 240 条记录，显示在玩家附近的 24 m 区域；没有把微小雪坑加入物理碰撞或存档。

## 雪面

- 路肩采用变化的过渡宽度，雪堆使用扰动后的空间波形，减少笔直重复的长条。
- 高度纹理按实际半米采样点映射到纹素中心。近处细分雪面在边缘回到远处三角网格高度，避免接缝；两种网格使用统一的逐像素法线。
- 增加克制的雪粒、粗糙度和不规则风纹，压实鞋底有局部明暗；弱化深沟过硬的法线反差。
- 小雪花不再投射硬边点状阴影。树木、角色、建筑阴影保留。
- 法线坐标实现遵循 [Godot 4.7 spatial shader 文档](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html) 对 fragment NORMAL 的视图空间定义。

## UI

统一规则在根目录 `DESIGN.md`，共享实现为 `field_theme.gd`、`field_icon.gd`、`survival_hud.gd`。

- 常驻画面移除大标题、版本号、多色状态卡和重复物资清单；目标在左上，环境在右上，生存状态在底部。
- 六项状态保留中文短标签，低值使用颜色加“低”字提示；全部详细数值、负重和探索时间可在行囊查看。
- 行囊、制作、手记、地图、暂停菜单统一炭蓝底、雪白前景、冷灰辅助文字和暗金选择色；去掉装饰缝线、皮边、宋体混排。
- 原创单色图标、可见键盘焦点、禁用/悬停/按下状态。暂停菜单优先继续探索，再提供存取档和重新开始。
- 行囊改为 180 ms 淡入、140 ms 淡出，不再拉伸字体；生存暂停、途中反向开合和磁带拖放逻辑保留。不同页签提供对应操作提示。

## Mac 验证

Apple M2 / macOS 26.5.2 / Godot 4.7.2，Compatibility。

- `tools/run_checks.py`：import、snow_ui、rules、integration、polish、frontier 全部 PASS。最终细化后完成一轮全套检查，最后的页签提示与菜单焦点改动另跑 polish。
- 新增 `snow_ui` 回归：门外、轨道和林道薄雪进入实际印迹纹理；排除木屋/门廊/桥/冰；角色真实走出门后产生左右交替脚印；验证 HUD、行囊、地图显示状态。
- 实际渲染并检查门外连续脚印、深雪、地图、主菜单、暂停、行囊、制作、手记及低状态。1280×720 与 1920×1080 渲染均检查中文和布局。截图与日志在 `artifacts/`，不提交。
- 最后一次 1280×720 移动样本：241 帧，平均 24.93 ms（约 40.1 FPS），中位数 23.81 ms，P95 26.38 ms。属于 6 秒样本，不是长期/全地图基准；同轮其他短样本约 43.6 FPS，迁移初始样本约 42.2 FPS。尚未达到稳定 60 FPS。
- UI 通用检测器返回空列表；该工具不完整理解 GDScript，不能替代以上 Godot 测试与截图检查。
- 测试未写入玩家 savegame.json，未重建或修改 LFS 二进制资源。本轮更改未提交、未推送。

## 检查入口

```sh
python3 tools/run_checks.py --godot ~/.local/bin/godot
~/.local/bin/godot --path . -- --capture --approach-preview
~/.local/bin/godot --path . -- --capture --hollow-preview
~/.local/bin/godot --path . -- --capture --backpack-preview
~/.local/bin/godot --path . -- --capture --craft-preview
~/.local/bin/godot --path . -- --capture --journal-preview
~/.local/bin/godot --path . -- --capture --pause-preview
~/.local/bin/godot --path . -- --capture --map-preview
~/.local/bin/godot --path . -- --capture --low-status-preview
```

人工长期试玩仍需留意地图不同地点的密集标签、极端坡地/转身时足底接触，以及超出本次两种 16:9 尺寸的窗口。
