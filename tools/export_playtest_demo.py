"""Encode a completed, uncut Godot playtest recording with audio and chapters."""
import argparse
import json
import math
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', default=shutil.which('ffmpeg'))
    parser.add_argument('--folder', type=Path, default=ROOT / 'artifacts/playtest-demo')
    parser.add_argument('--title', default='雪线以北 · 完整试玩 Demo')
    parser.add_argument('--audio-gain-db', type=float, default=0.0,
                        help='Constant gain after measuring source peaks; preserves the game mix.')
    args = parser.parse_args()
    if not args.ffmpeg:
        parser.error('Provide --ffmpeg or install ffmpeg on PATH.')
    if not math.isfinite(args.audio_gain_db) or not -24 <= args.audio_gain_db <= 12:
        parser.error('--audio-gain-db must be finite and between -24 and 12.')
    folder = args.folder.resolve()
    report = json.loads((folder / 'report.json').read_text(encoding='utf-8'))
    if report['status'] != 'complete':
        parser.error('The playtest did not complete; preserve its failure evidence instead.')
    title = args.title.replace('\\', '\\\\').replace('=', '\\=').replace(';', '\\;').replace('#', '\\#').replace('\n', ' ').replace('\r', ' ')
    metadata = [';FFMETADATA1', 'title=' + title, 'comment=Scripted in-engine recording with native game audio; any lighting study is labelled on screen.']
    events = report['events']
    for index, event in enumerate(events):
        end = events[index + 1]['video_seconds'] if index + 1 < len(events) else report['duration_seconds']
        metadata += ['[CHAPTER]', 'TIMEBASE=1/1000', f"START={round(event['video_seconds'] * 1000)}", f'END={round(end * 1000)}', 'title=' + event['title'].replace('=', '\\=')]
    chapters = folder / 'chapters.ffmetadata'
    chapters.write_text('\n'.join(metadata) + '\n', encoding='utf-8')
    output = folder / 'north-of-snowline-demo.mp4'
    command = [args.ffmpeg, '-hide_banner', '-n', '-i', str(folder / 'north-of-snowline-full.avi'), '-i', str(chapters), '-map', '0:v:0', '-map', '0:a:0', '-map_metadata', '1', '-map_chapters', '1', '-c:v', 'libx264', '-preset', 'fast', '-crf', '20', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart', str(output)]
    if args.audio_gain_db:
        command[-1:-1] = ['-af', f'volume={args.audio_gain_db}dB']
    with (folder / 'encode.log').open('w') as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
    with (folder / 'decode-check.log').open('w') as log:
        subprocess.run([args.ffmpeg, '-hide_banner', '-v', 'error', '-xerror', '-i', str(output), '-f', 'null', '-'], stdout=log, stderr=subprocess.STDOUT, check=True)
    # A decodable file may still contain a frozen macOS background window.
    # The scripted sessions have no intentional static holds above 20 seconds.
    freeze_log = folder / 'freeze-check.log'
    with freeze_log.open('w') as log:
        subprocess.run([args.ffmpeg, '-hide_banner', '-i', str(output), '-an', '-vf', 'fps=2,scale=320:-2,freezedetect=n=0.0001:d=20', '-f', 'null', '-'], stdout=log, stderr=subprocess.STDOUT, check=True)
    if b'freeze_start' in freeze_log.read_bytes():
        raise RuntimeError('Long frozen image detected; do not deliver this recording.')
    print(f'EXPORT_OK: {output} ({output.stat().st_size / 1024**2:.1f} MiB); full video/audio decode passed.')

if __name__ == '__main__':
    main()
