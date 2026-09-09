# Windows / macOS 开发与 Git 协作

仓库根目录就是包含 `project.godot` 的目录。Windows 当前副本在 `D:\GodotProjects\NorthOfSnowline`；Mac 可以放在 `~/Developer/NorthOfSnowline` 或其他可写目录。不要只迁移 Codex 原工作区里的说明 README。

## 工具与首次打开

| 工具 | 已验证的 Windows 版本 | 用途 |
|---|---|---|
| Godot | 4.7.2 stable，标准版 | 打开项目、运行、测试；两台设备尽量一致 |
| Blender | 5.2.1 LTS | 编辑 `.blend` 或重新生成模型；运行游戏不需要 |
| Python | 3.12.14 | 测试脚本、音频制作；运行游戏不需要 |
| Git / Git LFS | 2.53.0 / 3.7.1 | 源码与大型二进制资产同步 |

Mac 请安装适配该设备芯片的应用。当前没有原生 DLL、Godot C# 或 Windows 专有插件依赖。2026-09-09 已在 Apple M2 / macOS 26.5.2 / Godot 4.7.2 上通过四组检查并实际运行；中文、角色、小屋和背包画面已检查。声音听感和长时间探索仍待人工试玩。正文配置了 PingFang SC、标题配置了 Songti SC 作为 Mac 字体候选。

### 此次 Mac 工作副本

- 目录：`/Users/leoduan/Documents/ChatGPT/北`，从 `main` 的 `d22ec96` 克隆，保留原仓库历史。
- Godot：`~/Applications/Godot.app`，命令行入口 `~/.local/bin/godot`。
- Git LFS 3.8.0：官方 Apple Silicon 二进制安装到 `~/.local/bin/git-lfs`，下载包 SHA-256 与官方 release digest 一致；只执行了仓库本地 `git lfs install --local`。
- 89 个 LFS 资产已下载，`git lfs fsck` 通过。首次下载使用了此 Mac 已有系统代理 `127.0.0.1:7897` 的单次命令参数，没有写入仓库或全局代理配置。
- 双击 `启动游戏.command`：自动查找用户 Applications、系统 Applications 或 PATH 中的 Godot，先导入资源再启动。也支持 `GODOT_BIN` 指定引擎；导入日志在 `artifacts/mac-launch-import.log`。
- 编辑项目：`~/.local/bin/godot --editor --path '/Users/leoduan/Documents/ChatGPT/北'`。
- 玩家存档不会随 Git 自动迁移；当前 Mac 工作副本不包含 Windows 的旧存档。

Git LFS 必须在克隆前安装；只下载 GitHub 的源码 ZIP 不作为这里的迁移流程。LFS 使用指针管理实际二进制内容，克隆后需要取得对应对象。[Git LFS 官方说明](https://git-lfs.com/)

Mac（已安装 Homebrew 时）：

```sh
brew install git git-lfs
git lfs install
mkdir -p ~/Developer
cd ~/Developer
git clone git@github.com:YOUR_ACCOUNT/NorthOfSnowline.git
cd NorthOfSnowline
git lfs pull
git lfs fsck
```

当前仓库地址为 https://github.com/daysmart1997-png/NorthOfSnowline.git ，已完成 Windows 首次推送。将示例地址替换为该地址即可克隆；SSH 方式需要先在 GitHub 配好 SSH 公钥，也可以直接使用上述 HTTPS 地址。

在 Godot 项目管理器导入 `project.godot`。第一次打开会重建 `.godot/`，等导入完成再按 F5；关卡由代码生成，编辑器空场景不代表资源缺失。也可以运行：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
```

在 Mac 的 Codex 中把**克隆目录本身**添加为项目，首先让它阅读 `AGENTS.md` 和 `docs/PROGRESS.md`。Codex 本地聊天记录不在 Git 中；后续上下文以仓库文档为准。

## 第一次上传 GitHub（已完成，以下留作操作参考）

首次整理只初始化并提交本地仓库。随后用户建立了远程空仓库，并授权配置 origin 与首次推送；现已完成，当前副本无需重复添加 origin。首次上传命令如下：

```powershell
Set-Location 'D:\GodotProjects\NorthOfSnowline'
git status
git remote add origin git@github.com:YOUR_ACCOUNT/NorthOfSnowline.git
git push -u origin main
```

空仓库不要额外生成 README、`.gitignore` 或 LICENSE，以免产生另一份初始历史。正常 `git push` 会通过 LFS hook 上传所需资源；无需先手动上传图片或 GLB。LFS 存储和流量按远程服务的账户政策计算。

若已经有 `origin`，先 `git remote -v` 核对，不要重复添加或未经核实覆盖地址。

## 两台设备的日常顺序

离开一台电脑前完成可检查的改动、更新进度、提交并推送；另一台电脑确认工作区干净后再拉取。不要把同一个工作副本放进网盘并同时打开。

开始工作：

```sh
git status --short --branch
git pull --ff-only
git lfs pull
```

若有未提交的本地修改，先处理自己的修改；若 `--ff-only` 提示分歧，检查两侧提交并正常合并，不要强制覆盖。

完成工作：

```sh
git add -A
python tools/check_repository.py
git diff --cached --stat
git lfs status
git commit -m "Describe the completed change"
git push
```

Mac 如果只有 `python3`，将 `python` 替换为 `python3`。每台设备自行设置提交姓名/邮箱；配置保存在本地 `.git/config` 或全局配置，不会随 Git 克隆。

较大任务可以使用 `git switch -c codex/具体任务名`，在另一台设备 `git fetch origin` 后检出同一远程分支。不要两边同时编辑同一个 `.blend` 或 `.glb`；LFS 不会自动合并二进制文件。修改模型时同时提交 `.blend`、对应 GLB 和必要的导入设置。

## 验证

Windows：

```powershell
python tools/run_checks.py --godot 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
```

Mac：

```sh
python3 tools/run_checks.py --godot /Applications/Godot.app/Contents/MacOS/Godot
```

也可以设置 `GODOT_BIN` 或把 Godot 加入 PATH。脚本先无界面导入，然后执行界面/声音、角色步态、视觉样板、室内视野、章节、探索、生存昼夜、雪面/UI、规则、集成、细节与地形十二组检查；可用 `--suite presentation`、`--suite ranger`、`--suite rules`、`--suite day_cycle` 等只选一组。它同时检查退出码、成功标记和错误信息，输出保存在不提交的 `artifacts/checks-*.log`。

图形改动还应实际启动游戏检查中文布局、开合背包、行走贴坡、脚印、木屋切顶、声音和帧率。首次 Mac 试玩后将结果写入 `PROGRESS.md`。测试存档与玩家存档分开；玩家存档留在本地，不随 Git 自动同步。

## 资产制作工具

所有保留的 Python 工具均由自身位置推导项目根目录，不要求 D 盘。运行 Godot 直接使用已提交的 GLB、WAV 和着色器，不需要先重建资产。

按需重建示例（会覆盖对应源文件/导出文件，先检查工作区）：

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/build_architecture.py
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/retarget_mesh2motion.py
```

Windows 使用本机 Blender 可执行文件执行相同参数。`build_assets.py` 是初始角色/早期音频生成器，`retarget_mesh2motion_v03.py` 是历史参考，均不要作为开机初始化步骤；会覆盖精修资产。

音频再制作使用独立环境（仅当需要运行 `polish_audio.py` 时）：

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r tools/requirements-audio.txt
python tools/polish_audio.py
```

Windows 可以直接使用 `.venv\Scripts\python.exe` 执行 pip 和脚本，无需改变 PowerShell 执行策略。依赖版本来自当前已工作的 Windows 环境；Mac 原生依赖安装及声音再生成尚待实测。当前解压后的 FLAC 与原始呼吸录音已保留，不需要再次下载或解压 `snow.7z`。

## 纳入 / 排除原则

- 纳入源码、场景、着色器、`project.godot`、`.uid`、资源旁 `.import`、制作脚本、原始素材及许可说明。Godot 4 的 `.godot/` 是缓存，`.uid` 则应版本控制。[Godot UID 说明](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
- 大型二进制的选择与规模见 `ASSETS.md`；LFS 规则保存在 `.gitattributes`，随仓库克隆。[GitHub LFS 配置说明](https://docs.github.com/en/repositories/working-with-files/managing-large-files/configuring-git-large-file-storage)
- 排除 `.env`、密钥与私钥文件、依赖安装目录、缓存、导出包、OS 文件、快捷方式、测试输出、玩家存档、Blender 自动备份和重复下载压缩包；只忽略，不删除本机文件。
- `.gitignore` 无法识别写在源码里的 API Key；提交前的本地扫描是补充保护，不是所有凭据的完备证明。实际项目当前运行不需要 API Key，不创建虚假的 `.env` 配置。
- `docs/01～07` 是历史开发记录，其中旧 D 盘路径、日志和截图描述属于制作历史；日志与临时截图不随克隆。最新接续说明以 `PROGRESS.md` 为准。
- 未替原创代码、美术选择开源许可证；保留第三方 CC0 说明。是否公开仓库和采用何种许可证由项目所有者决定。


### 第一章失联与碰撞回归

新版状态、资产重建入口和边界见 [18_LOST_CONTACT_AND_WORLD_REFINEMENT.md](18_LOST_CONTACT_AND_WORLD_REFINEMENT.md)。run_checks.py 已纳入 revision，共十三组。原生画面可运行 tools/revision_preview.tscn（--revision-output=revision-1080 可分开输出）、tools/ranger_check.tscn -- --ranger-capture。测试输出写 artifacts，不覆盖玩家存档。
