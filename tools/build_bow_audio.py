"""Original synthesized bow foley, deterministic and stdlib-only. No recordings."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]

def render(name, duration, release=False):
    rng = random.Random(914)
    rate = 44100
    samples = []
    smooth = 0.0
    for i in range(int(duration * rate)):
        t = i / rate
        smooth += (rng.uniform(-1, 1) - smooth) * .18
        if release:
            # Short string snap, decaying wood resonance, then arrow air rush.
            value = .34 * math.sin(2 * math.pi * (175*t + 42*t*t)) * math.exp(-t*22)
            value += smooth * (.7*math.exp(-t*70) + .25*math.sin(math.pi*t/duration)**2)
        else:
            envelope = math.sin(math.pi*t/duration)**.75
            value = envelope * (.24*smooth + .045*math.sin(2*math.pi*(95*t+30*t*t)))
            value *= .65 + .35*math.sin(t*31)**2
        # Avoid discontinuities at file boundaries.
        value *= min(1, t/.004, (duration-t)/.018)
        samples.append(struct.pack('<h', round(max(-.95, min(.95, value))*32767)))
    path = ROOT / 'assets' / 'audio' / name
    with wave.open(str(path), 'wb') as wav:
        wav.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        wav.writeframes(b''.join(samples))

if __name__ == '__main__':
    render('bow_draw.wav', .95)
    render('bow_release.wav', .34, True)
