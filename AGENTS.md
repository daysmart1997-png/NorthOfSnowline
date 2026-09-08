# 雪线以北 · Codex 协作约定

## 开始工作

- 此目录（包含 project.godot）是唯一的游戏仓库根目录。不要依赖 Windows 的 D 盘路径、用户目录或桌面快捷方式。
- 先读 docs/PROGRESS.md 和 docs/DEVELOPMENT.md，再检查 git status --short --branch。历史设计和素材来源在 docs/01～07 文档。
- 保留用户已有修改；不重置、清理或覆盖不属于当前任务的工作。不创建远程仓库、不推送，除非用户明确要求。当前任务若授权提交，可完成本地提交。
- 不自动启动其他 Codex 任务或子代理。完成一个可检查的小范围改动后记录进度，避免两台设备同时修改同一二进制资源。

## 项目与美术

- Godot 4 项目，GDScript、Compatibility 渲染、固定斜俯视正交镜头。延续冷灰蓝雪林、克制的暖灯、风化木材与帆布风格。
- 当前入口 scripts/main.gd；当前世界为 world_frontier.gd，角色为 player_ranger.gd。旧基类仍被继承，不可按文件版本名字直接删除。
- 生存规则主要位于 expedition.gd。不要让 UI 各自维护另一份背包或生存状态。
- Blender 源文件放 source_art/，游戏导出资源放 assets/；修改模型时同一提交包含源文件、导出文件及必要 .import 设置。
- .blend、.glb、位图与音视频走 Git LFS。不要把大二进制转换成普通 Git 文件；不要手动编辑 LFS 指针来代替真实资源。
- .godot 缓存不得提交；*.uid、资源旁 *.import 和各目录 .gdignore 必须保留。
- 不自动执行 tools/build_assets.py 或历史 retarget_mesh2motion_v03.py，它们会覆盖当前资产。只有明确需要重建对应资产时才运行，并审核生成差异。
- 新素材记录来源与许可；沿用 docs/06_POLISH.md、source_art 中上游说明。原始源码和原创美术尚未选择开源许可证，不自行添加授权。

## 跨平台与验证

- GDScript 使用 res:// / user://；工具从 __file__ 定位仓库；可执行文件使用参数、PATH 或 GODOT_BIN。文件名大小写与引用一致，统一 UTF-8 / LF。
- 运行项目只需要相应平台的 Godot 和完整 LFS 资源；Blender、Python 音频依赖仅用于资产再制作。不得提交 node_modules、venv 或 tools/audio_deps。
- 运行 python tools/check_repository.py 检查暂存文件、凭据模式和 LFS 指针。
- 涉及玩法、场景、UI 或角色时，运行 python tools/run_checks.py --godot <Godot executable>；按改动进行实际渲染检查。纯文档修改不重复运行全套游戏测试。
- 检查日志中的成功标记和错误，不能仅凭 Godot 的进程退出码判断断言通过。测试输出只写 artifacts/，不得覆盖玩家 savegame.json。
- Mac 上尚未完成实际运行验证；不得把 Windows 检查结果报告为 Mac 已通过。记录工具版本、平台、检查内容和剩余问题。

## 结束工作

- 更新 docs/PROGRESS.md：完成项、关键架构变化、实际测试、已知问题、下一步。让另一台设备的 Codex 单独阅读仓库即可接续。
- 提交前检查 git diff --cached、python tools/check_repository.py、git lfs status；用清晰的提交说明。
- 切换设备前由用户推送；另一台开始修改前拉取并执行 git lfs pull。发生分歧时先检查双方提交，禁止用强制推送解决。
