"""Capture twelve native-rendered views or a bounded performance sample."""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--label', default='after')
    parser.add_argument('--profile', action='store_true')
    parser.add_argument('--profile-room', choices=['home', 'lodge', 'station'], help='Profile a lit interior including its backdrop.')
    parser.add_argument('--terrain-shadow-off', action='store_true', help='Diagnostic only: omit terrain shadow casting.')
    args = parser.parse_args()
    if args.profile_room and not args.profile:
        parser.error('--profile-room requires --profile.')
    if not args.label or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_' for c in args.label):
        parser.error('Label must contain only letters, digits, hyphens or underscores.')
    out = ROOT / 'artifacts' / 'visual-slice' / args.label
    out.mkdir(parents=True, exist_ok=True)
    startup = None
    if sys.platform == 'win32':
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    command = [args.godot, '--path', str(ROOT), '--resolution', '1280x720',
               'tools/visual_slice_preview.tscn', '--', '--isolated-settings', '--slice-output=' + args.label]
    if args.profile:
        command.append('--slice-profile')
    if args.profile_room:
        command.append('--slice-profile-room=' + args.profile_room)
    if args.terrain_shadow_off:
        command.append('--slice-terrain-shadow-off')
    try:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, timeout=120, startupinfo=startup)
    except subprocess.TimeoutExpired:
        print('FAIL: native visual slice timed out')
        return 1
    log = (result.stdout + result.stderr).decode('utf8', errors='replace')
    (out / ('profile.log' if args.profile else 'capture.log')).write_text(log, encoding='utf8')
    bad = any(token in log for token in ['SCRIPT ERROR', 'ERROR:', 'Assertion failed', 'leaked at exit'])
    if result.returncode or bad or 'VISUAL_SLICE_OK' not in log:
        print(log)
        return 1
    print(log.strip())
    return 0

if __name__ == '__main__':
    sys.exit(main())
