# 完整试玩 Demo · 2026-09-09

本轮按用户要求试玩并录制，不修改正式游戏玩法。使用单独场景 `tools/playtest_demo.tscn` 和脚本驱动一段可复跑的游戏操作；实际经过角色移动、物理碰撞、目标距离/视线检查、背包按钮与生存规则。不是人工连续按键试玩，也不是剪辑拼接的预设镜头。

## 范围

从新旅程开始：小屋出门 → 搜寻门口工具箱 → 收集倒木 → 打开路线地图 → 奔跑和雪坡脚印 → 发现邮递车与磁带机 → 行囊装入/播放余烬 → 沿铁路旁返程 → 修床、封窗、添柴 → 饮水、进食 → 四次正常休息推进到夜晚 → 夜间出门观察 → 回小屋。

不瞬移，不发放物品，不修改状态数值，也不直接改时钟；日夜跳转来自四次正常的 2 小时休息。没有保存操作，玩家 `savegame.json` 未写入；演示脚本的备用存档路径也限制在 artifacts。

此段覆盖南侧探索与庇护所循环，未完成北岭车站无线电任务，也未覆盖桥梁、冻湖、营地建造或长期生存平衡。不要把本段完成描述为全游戏通关。

## 文件

- `artifacts/playtest-demo/north-of-snowline-demo.mp4`：完整 MP4，保留原声与全部试玩过程，附章节索引。
- `artifacts/playtest-demo/north-of-snowline-full.avi`：Godot 原始录像。
- `artifacts/playtest-demo/report.json`：各章节时间、游戏时刻、位置、状态与最终结果。
- `artifacts/playtest-demo/试玩记录.md`：此次录像的实际时间点、检查结果与待改善项。
- `artifacts/playtest-demo/chapter-*.png`：在实际渲染后截取的章节画面。
- `artifacts/playtest-demo/recording.log`、`encode.log`、`decode-check.log`：录制、编码和完整解码检查。

## 观察

- 自动操作预跑曾在返程碰到树干，停在约 `(-7.7, -7.8)`；调整为绕行铁路附近后通过。碰撞仍然有效，没有为录制移走树木或取消碰撞。
- 白天屋顶亮部偏白，屋面积雪层次不足；门口薄雪脚印在树影下不够醒目。雪坡连续脚印在实际截图中可辨认。这些列为视觉调校建议，未在录制中临时修改。
- 本轮只增加独立的试玩、录制与导出工具。预跑退出曾因加速执行下音频尚未清理而报告资源仍占用，现与项目检查入口一致，停止更新、关闭音频并等待混音器后退出；不更改正式游戏音频逻辑。

上述屋顶与薄雪脚印建议已在后续材质优化中处理，见 [雪面材质优化](11_SNOW_FINISH.md)；本录像仍保留优化前版本。

## 复现

先按开发文档导入项目资源，然后运行：

```sh
godot --headless --path . --fixed-fps 30 --quit-after 24000 tools/playtest_demo.tscn
godot --path . --resolution 1280x720 --fixed-fps 30 --disable-vsync \
  --write-movie artifacts/playtest-demo/north-of-snowline-full.avi tools/playtest_demo.tscn
python3 tools/export_playtest_demo.py --ffmpeg /path/to/ffmpeg
```

预跑/录制成功必须出现 `DEMO_COMPLETE`、报告状态为 `complete` 且无 `ERROR`。失败时脚本会保留真实原因，不会把失败录像导出成成功 Demo。再次录制应先将已有输出移到独立目录，导出器默认拒绝覆盖现有 MP4。

使用 Godot Movie Maker 捕获引擎画面和混合音频，再用 FFmpeg 编码；输出设为 1280×720 / 30 FPS。Movie Maker 按固定时间步进输出，因此录像流畅度不等同于本机实时性能测试。[Godot 官方录制说明](https://docs.godotengine.org/en/4.5/tutorials/animation/creating_movies.html)

`tools/` 的 `.gdignore` 保持不变，这些独立命令行场景不进入正常导入/启动流程。视频和截图属于本地 artifacts，不纳入 Git。没有提交或推送。
