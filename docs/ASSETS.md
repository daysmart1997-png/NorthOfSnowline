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

```sh
git lfs ls-files
git lfs status
git lfs fsck
python tools/check_repository.py
```

首次本地提交之前没有 HEAD，`git lfs fsck` 不能检查该提交；应在提交完成后运行。暂存区检查工具会验证二进制是否已经转为 LFS 指针；`fsck` 再验证对应本地对象。

首次克隆必须执行 `git lfs pull`，然后等待 Godot 完成导入。如果模型文件打开后只有三行 `version / oid / size`，说明仍是指针，先修复 LFS 下载，不要让 Blender 或 Godot覆盖它。

没有为 LFS 配置额外外部存储地址，也没有添加远程仓库；首次推送由用户完成。不要同时在两台设备修改同一模型，LFS 不负责自动合并模型结构。GitHub 如何记录 LFS 规则见 [官方说明](https://docs.github.com/en/repositories/working-with-files/managing-large-files/configuring-git-large-file-storage)。
