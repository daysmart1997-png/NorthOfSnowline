# 炉火动画与暖光统一

2026-09-12，Windows，接续视觉 B 批。让玩家能从炉火看到点燃、添柴和燃料将尽；保留微缩雪原的克制暖色。

## 已实现

- 长期护林小屋、维修间、炭工木屋共用炉窗火焰：暗色炉膛、炭红底部和向上变化的金橙火舌。移除旧的小球粒子，封闭铁炉不再向屋内冒露天火星。
- 猎人营地和玩家新建营地共用同一调色和时间驱动，露天版本增加三片交错火舌与四颗小火星。火舌和火星使用世界竖直方向、米制尺寸，不继承导入炭床的轴向与缩放；风只轻推露天火焰和火星。
- 点燃有约 0.8 秒的起势，添柴有短暂增亮；最后 45 秒燃料逐渐降低火焰高度和灯光，零燃料立即关闭。炭工木屋窗外暖光跟随同一强度，减少室内火灭而雪地仍亮的状态不一致。
- 动画使用传入的生存太阳时间，暂停时火舌、火星、炉光都冻结；休息和读档跨时刻直接显示剩余燃料，不重放之前的添柴起势。
- 不改变木材消耗、燃烧时长、取暖强度、存档格式或现有火声混音；弱火的视觉提醒不另建一套生存规则。

## 接续实现

`scripts/hearth_effect.gd` 是展示控制器；`assets/shaders/hearth_fire.gdshader` 共用炉窗、火舌、炭床的调色与噪声。`world_expansion.gd` 管理 `fire_effects` 注册/清理，并在天气更新后传入真实燃料和时间。`arrival_world.gd` 为后建的炭工木屋注册效果、绑定窗外溢光，修复其原先漏用火焰粒子的问题。

室内阴影仍由 `interior_view.gd` 管理，仅当前有火房间启用；本轮没有增加投影灯。新建营地重建/删除时连同效果释放。没有新下载素材、覆盖模型或新增运行依赖；不需要 Blender 再生成。

Shader 接口参考 [Godot 官方 spatial shader 文档](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)，火焰实现为本项目编写，未复制第三方代码。使用显式 `fire_time`，不使用独立墙钟或自动粒子时钟。

## 验证与复现

```sh
python tools/run_checks.py --godot <Godot>
# 仅炉火专项
python tools/run_checks.py --godot <Godot> --suite hearth
# 原生近景捕获；使用隔离设置和测试场景，不写玩家存档
<Godot> --path . --resolution 1280x720 --fixed-fps 60 --quit-after 2400 tools/hearth_check.tscn -- --isolated-settings --hearth-capture
```

专项通过真实添柴操作核对木材/燃料、点燃与添柴响应、暂停冻结、燃料将尽和熄灭、窗光同步、玩家制作营地、存读档和新旅程清理，并断言导入模型不能让火舌横倒。

Windows / Godot 4.7.2 / Compatibility / RTX 3070 Ti 原生专项 `HEARTH_OK`；16 张近景位于 `artifacts/hearth/`，每个炉火有两个不同时间的旺火、弱火和熄灭状态，日志 `artifacts/hearth-native.log`。查看室内炉窗与露天炭床/火舌；近景检查不等于首次玩家试玩。全场景第一轮捕获在 `artifacts/visual-slice/hearth-pass1/`，露天轴向修正以后以 hearth 专项近景为准。

完整回归结果与候选索引审核见 PROGRESS 顶部最新记录。Mac、长时间听感/玩法、火光在所有未来营地布局中的遮挡仍需复验。当前露天火舌采用交错面片，极近距离仍会显露面片感；优先按实际游玩镜头评估，不把它称为体积火焰或流体模拟。下一轮继续树根/屋基交界、生活痕迹和实际游玩尺度的视觉一致性，再接磁带可听叙事。
