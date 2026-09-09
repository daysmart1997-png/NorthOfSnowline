#!/bin/bash
set -euo pipefail

GAME_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$GAME_ROOT"

godot_bin="${GODOT_BIN:-}"
if [[ -z "$godot_bin" ]]; then
    for candidate in "$HOME/Applications/Godot.app/Contents/MacOS/Godot" "/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/.local/bin/godot"; do
        if [[ -x "$candidate" ]]; then
            godot_bin="$candidate"
            break
        fi
    done
fi
if [[ -z "$godot_bin" ]]; then
    godot_bin="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$godot_bin" || ! -x "$godot_bin" ]]; then
    echo "未找到 Godot。请安装 Godot 4.7.2，或将 GODOT_BIN 设为可执行文件路径。"
    read -r -p "按回车关闭。" || true
    exit 1
fi

mkdir -p artifacts
echo "正在准备《雪线以北》……"
if ! "$godot_bin" --headless --path "$GAME_ROOT" --editor --import --quit > artifacts/mac-launch-import.log 2>&1; then
    echo "资源导入失败，请查看 artifacts/mac-launch-import.log。"
    read -r -p "按回车关闭。" || true
    exit 1
fi
if /usr/bin/grep -Eq 'SCRIPT ERROR|ERROR:' artifacts/mac-launch-import.log; then
    echo "资源导入发现错误，请查看 artifacts/mac-launch-import.log，并确认已执行 git lfs pull。"
    read -r -p "按回车关闭。" || true
    exit 1
fi
exec "$godot_bin" --path "$GAME_ROOT" "$@"
