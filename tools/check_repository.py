"""Audit the staged snapshot without displaying credential values. Standard library only."""
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
LFS_EXTENSIONS = set(".blend .glb .fbx .png .jpg .jpeg .webp .tga .exr .hdr .psd .wav .flac .ogg .mp3 .mp4 .mov .webm".split())
SECRET_PATTERNS = {
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
    "OpenAI-like token": re.compile(r"\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{24,}\b"),
    "GitHub token": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})\b"),
    "AWS access ID": re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"),
    "Google API key": re.compile(r"\bAIza[A-Za-z0-9_-]{30,}\b"),
    "Slack token": re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    "credential assignment": re.compile(r'''(?i)["']?\b(?:api[_-]?key|access[_-]?token|client[_-]?secret|password)["']?\s*[:=]\s*["']([A-Za-z0-9_+/=-]{20,})["']'''),
}

def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])

def main():
    files = git("ls-files", "-z").decode("utf-8").rstrip("\0").split("\0")
    files = [name for name in files if name]
    if not files:
        print("FAIL: no staged files; run git add before auditing.")
        return 1
    errors = []
    seen = {}
    lfs_bytes = 0
    lfs_count = 0
    regular_bytes = 0
    largest = []
    for name in files:
        path = PurePosixPath(name)
        lower = name.casefold()
        if lower in seen:
            errors.append(f"case-insensitive path collision: {seen[lower]} / {name}")
        seen[lower] = name
        forbidden = {".git", ".godot", "node_modules", ".venv", "venv", "__pycache__", "audio_deps", "secrets", ".ssh", ".aws"}
        if any(part.casefold() in forbidden for part in path.parts):
            errors.append(f"excluded directory staged: {name}")
        base = path.name.casefold()
        sensitive = (base == ".env" or base.startswith(".env.")) and not base.endswith(".example")
        sensitive |= base in {"credentials.json", "id_rsa", "id_ed25519", ".npmrc", ".pypirc", ".netrc", "export_credentials.cfg"}
        if sensitive or path.suffix.lower() in {".pem", ".key", ".p12", ".pfx"}:
            errors.append(f"credential file staged: {name}")
        if name.startswith("artifacts/") and name != "artifacts/.gdignore":
            errors.append(f"local artifact staged: {name}")
        if base.startswith("savegame.json") or re.search(r"\.blend\d+$", base):
            errors.append(f"local save/backup staged: {name}")
        data = git("show", ":" + name)
        if path.suffix.lower() in LFS_EXTENSIONS:
            pointer = re.fullmatch(rb"version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n", data)
            if not pointer:
                errors.append(f"binary asset is not an LFS pointer: {name}")
            else:
                size = int(pointer.group(2)); lfs_bytes += size; lfs_count += 1
                largest.append({"path": name, "bytes": size})
            continue
        regular_bytes += len(data)
        if len(data) > 10 * 1024 * 1024:
            errors.append(f"large regular Git blob (>10 MiB): {name}")
        if b"\0" in data:
            continue
        try:
            text = data.decode("utf-8-sig")
        except UnicodeDecodeError:
            errors.append(f"non-UTF-8 text or unclassified binary: {name}")
            continue
        for label, pattern in SECRET_PATTERNS.items():
            for match in pattern.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                errors.append(f"possible {label}: {name}:{line}")
    result = {"staged_files": len(files), "lfs_files": lfs_count, "lfs_bytes": lfs_bytes,
              "regular_git_bytes": regular_bytes, "largest_assets": sorted(largest, key=lambda x: -x["bytes"])[:10], "findings": errors}
    output = ROOT / "artifacts"
    output.mkdir(exist_ok=True)
    (output / "repository-audit.json").write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    if errors:
        print("\n".join("FAIL: " + item for item in errors))
        return 1
    print(f"PASS: {len(files)} staged files; {lfs_count} LFS assets / {lfs_bytes / 1024**2:.2f} MiB; regular Git {regular_bytes / 1024**2:.2f} MiB; no matched credentials or case collisions.")
    print("Scope: staged text, filename policy and LFS pointers; heuristic detection, not a guarantee against every possible secret.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
