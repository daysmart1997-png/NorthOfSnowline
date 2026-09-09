"""Offline A/B of the same existing footsteps; not a game or microphone recording."""
from pathlib import Path
import array
import json
import math
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
levels = json.loads((ROOT/'assets/audio/foley_levels.json').read_text())['samples']
rate = 32000
mix = [0.0] * int(rate*18)
sections = []
for part, (surface, revised) in enumerate([('snow', False), ('snow', True), ('deep', False), ('deep', True)]):
    start = part*4.5
    sections.append({'start_seconds': start, 'surface': surface, 'revised': revised})
    for i in range(8):
        name = f'step_{surface}_{i}'
        with wave.open(str(ROOT/'assets/audio'/f'{name}.wav')) as stream:
            assert stream.getframerate() == rate and stream.getnchannels() == 1 and stream.getsampwidth() == 2
            samples = array.array('h', stream.readframes(stream.getnframes()))
            if sys.byteorder != 'little': samples.byteswap()
        gain_db = (-18.0 if surface == 'snow' else -18.5) + levels[name]['gain_db'] if revised else -17.0
        gain = math.pow(10, gain_db/20)*3.0  # Same listening gain for every section.
        offset = round((start+.2+i*.4)*rate)
        for j, value in enumerate(samples): mix[offset+j] += value/32768*gain
peak = max(abs(value) for value in mix)
assert peak < .98
out = ROOT/'artifacts/presentation'
out.mkdir(parents=True, exist_ok=True)
pcm = array.array('h', (round(value*32767) for value in mix))
if sys.byteorder != 'little': pcm.byteswap()
with wave.open(str(out/'footsteps-ab.wav'), 'wb') as stream:
    stream.setparams((1, 2, rate, 0, 'NONE', 'not compressed'));stream.writeframes(pcm.tobytes())
(out/'footsteps-ab.json').write_text(json.dumps({'sections': sections, 'listening_gain_db': 20*math.log10(3), 'peak': peak}, indent=2)+'\n')
print('FOLEY_PREVIEW_OK', round(peak, 4), 'peak; snow before/after, deep snow before/after; 18 seconds')
