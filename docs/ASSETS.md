# 资产与 Git LFS 策略

2026-09-09 初次整理：需要保留的 LFS 二进制共 **89 个，47.30 MiB**（49,595,496 字节）。普通 Git 主要是源码、导入配置、文档和 LFS 指针；当前没有超过 100 MiB 的必要单文件。使用 LFS 的理由是二进制无法有意义地逐行合并，而且反复精修会扩大 Git 历史，并非已经碰到单文件限制。

| 内容 | 当前较大文件 | 处理 |
|---|---|---|
| 背景音乐与磁带 WAV | 背景音乐 9.77 MiB；每盘磁带约 5.86 MiB | LFS；游戏直接播放，必须保留 |
| Mesh2Motion 原始 GLB | 5.39 MiB | LFS；重新重定向所需，保留上游 README 和清单 |
| 建筑概念 PNG | 2.90 MiB | LFS；保留美术方向和建模参考 |
| 运行时 GLB | 小屋约 1.09 MiB，角色约 0.82 MiB | LFS；与编辑源文件一起保存 |
| Blender 源文件 | 最大约 0.83 MiB | LFS；即使当前较小也统一管理，防止后续版本膨胀 |
| 原始呼吸录音、42 个雪地 FLAC、音效 WAV | 多数小于 1 MiB | LFS；保留完整再制作输入和运行输出 |
| 着色器、脚本、场景、导入设置、资源 UID | 文本 | 普通 Git，保留可读差异 |

`.gitattributes` 已对 `.blend`、`.glb`、`.fbx`、常见位图、音频和视频扩展名配置 LFS。未来添加 SVG、JSON、GLTF 文本继续普通 Git；若新增 GLTF 的 `.bin` 配套文件或未覆盖的二进制格式，先补充 LFS 规则，再暂存。

## 留在本机，不进入仓库

- `tools/audio_deps/`：约 195 MB 的本地依赖，包含 Windows 平台实现。每台电脑用独立 Python 环境重新安装，不能迁移该目录充当 Mac 依赖。
- `.godot/`：约 7.3 MB 导入和编辑器缓存，克隆后重建。
- `artifacts/`：约 52.6 MB 的测试日志、截图、测试存档和旧备份 ZIP。保留 `.gdignore` 使引擎跳过该目录；历史文档中的旧截图和测试报告路径不会随克隆自动存在。
- `*.blend1` 等：Blender 自动备份，正式 `.blend` 保留。
- `source_art/audio/snow.7z`：原始下载压缩包，所含 42 个 FLAC 与许可说明已经解压并保留，无需重复上传。
- 桌面/项目 `.lnk`：绑定当前电脑路径，Mac 用 Godot 导入 `project.godot`。
- `tools/patch_v04.py`：已经执行过的一次性版本迁移脚本，非再制作工具；仅本地留档，避免另一台电脑重复套用。

本轮只通过忽略规则排除这些内容，没有删除用户文件。项目不需要 API Key；常见凭据路径由 `.gitignore` 排除，源码文本由 `tools/check_repository.py` 补充扫描。

## 协作检查

2026-09-09 简洁 HUD / 混音轮次未更改或新增运行音频二进制。`assets/audio/foley_levels.json` 为现有 24 个脚步录音的普通 Git 文本清单，含 SHA-256、RMS 与受限播放增益；`tools/measure_foley.py` 可复测。离线 A/B 试听 WAV 由 `tools/preview_foley.py` 写到 artifacts/presentation，不进入 Git，不替换素材或新增授权。

2026-09-09 环境与角色收尾新增：`source_art/ranger_refined.blend` 与 `assets/characters/ranger_refined.glb`，沿用 Git LFS。原创衣物/装备建立在项目原角色上，Mesh2Motion 上身及交互改编继续遵循 `source_art/mesh2motion/UPSTREAM-README.md` 的 CC0 来源说明；本轮下肢与鞋底滚动重新制作。`tools/refine_ranger.py` 从保留的 `ranger_motion.blend` 生成新资产，源文件独立部件，导出一个带权重网格 / 11 材质面。运行时已切换新模型；旧模型保留作为制作输入，不再直接用于主角。

2026-09-09 小屋视觉样板新增：ambientCG Snow004 原始 OpenGL 法线和粗糙度 PNG（1024×1024，CC0），来源、许可与文件哈希在 `assets/textures/snow004/README.md` 和 `source.json`。两张图约 5.96 MiB；未携带未使用的颜色、位移或 DX 法线图。新增原创 `source_art/cabin_dressing.blend` 与三个 `assets/props/*.glb`，源文件保留独立部件，游戏导出按材质合批。这六个新增二进制文件全部沿用 Git LFS。制作脚本为 `tools/build_cabin_dressing.py`，不涉及原小屋、桥梁、角色资产重建。

```sh
git lfs ls-files
git lfs status
git lfs fsck
python tools/check_repository.py
```

首次本地提交之前没有 HEAD，`git lfs fsck` 不能检查该提交；应在提交完成后运行。暂存区检查工具会验证二进制是否已经转为 LFS 指针；`fsck` 再验证对应本地对象。

首次克隆必须执行 `git lfs pull`，然后等待 Godot 完成导入。如果模型文件打开后只有三行 `version / oid / size`，说明仍是指针，先修复 LFS 下载，不要让 Blender 或 Godot覆盖它。

没有为 LFS 配置额外外部存储地址，也没有添加远程仓库；首次推送由用户完成。不要同时在两台设备修改同一模型，LFS 不负责自动合并模型结构。GitHub 如何记录 LFS 规则见 [官方说明](https://docs.github.com/en/repositories/working-with-files/managing-large-files/configuring-git-large-file-storage)。


## 本轮原创场景与角色重制（2026-09-09）

邮递车、标准物资箱、维修站线路设备为本项目原创 Blender 建模，未下载第三方模型。源与导出对应见 docs/18_LOST_CONTACT_AND_WORLD_REFINEMENT.md；小屋/桥/营地为原有原创概念的继续修改，角色继续基于已记录来源的 Mesh2Motion 适配并修改几何和动作。新增 timber/field_surface/bark 变化为项目原创 Shader，积雪继续使用已有 ambientCG Snow004；没有新增音频或配音授权。二进制均沿用 LFS，未另授开源许可证。

## 弓箭音效（2026-09-10）

`assets/audio/bow_draw.wav` 与 `bow_release.wav` 是本项目原创合成音效，分别为 0.95 / 0.34 秒、44.1 kHz 单声道 16-bit WAV。`tools/build_bow_audio.py` 使用 Python 标准库、固定随机种子、木质共振和滤波噪声制作，可重建。没有第三方采样或录音，也未另行授予开源许可证；WAV 与 .import 一起提交，二进制走 LFS。
