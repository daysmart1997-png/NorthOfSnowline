# 体验视频录制 · 2026-09-10

入口为 `tools/experience_demo.tscn`，不改变正式游戏入口。继承原有试玩脚本，以输入、碰撞、目标识别、背包按钮和正常休息完成路线：开场 → 七号小屋/值守簿 → 补给与人物页 → 收集木柴 → 奔跑与路线地图 → 邮递车磁带机 → 播放《余烬》返程 → 修床、生火、补水和休息 → 傍晚的小屋。

最后 50 秒单独标注“昼夜光影 · 延时展示”：保持同一雪原构图，从正午过渡至次日晨光。该段暂停生存，使用展示用太阳时间和轻雪参数；不代表玩家能瞬间改变天气，也不推进或写入玩家存档。音轨来自游戏，包含环境、脚步、呼吸、交互及磁带音乐；不录麦克风。离线固定帧率录制不能用于判断实时游戏性能。

## 复现

使用同版本 Godot 4.7.2，先确保资源已导入。运行时必须带 `--isolated-settings`，以关闭玩家自动存档并隔离设置。预演输出在带 `-rehearsal` 后缀的目录中。

```sh
godot --headless --path . --fixed-fps 30 --quit-after 18000 tools/experience_demo.tscn -- --isolated-settings
```

先创建 `artifacts/experience-demo-2026-09-10`，再运行录制（同路径已有录制时先自行保留旧文件）：

```sh
godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie artifacts/experience-demo-2026-09-10/north-of-snowline-full.avi --quit-after 18000 tools/experience_demo.tscn -- --isolated-settings --recording
python tools/export_playtest_demo.py --ffmpeg /path/to/ffmpeg --folder artifacts/experience-demo-2026-09-10
```

Windows 保留正常渲染循环；只在非 Windows 上沿用旧脚本的覆盖窗口绘制兼容处理。录制器会自动把按钮滚到可见区域，再激活实际按钮回调，避免原生鼠标与提示框吞掉合成点击；物品、制作和休息仍走正式逻辑。Mac 尚未复验此录制入口。

导出工具要求报告 `status=complete`，输出 H.264/AAC MP4、章节、完整解码检查和长冻结画面检查。视频、原始 AVI、截图、日志和本地 FFmpeg 依赖都放在忽略的 `artifacts/` 中，不纳入 Git LFS 或提交。本轮的 FFmpeg 来自本地安装的 imageio-ffmpeg 0.6.0 Windows wheel，仅用于视频转换。

可通过 `--title` 指定视频标题，通过 `--audio-gain-db` 做恒定增益；默认不改变原音量。先测完整音轨峰值，再选择保留余量的增益，导出后复查音频；不单独改变音乐/音效比例。
