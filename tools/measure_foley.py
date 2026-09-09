"""Measure existing PCM foley and write conservative playback gains, without rewriting audio."""
from pathlib import Path
import array
import hashlib
import json
import math
import statistics
import wave

ROOT = Path(__file__).resolve().parents[1]
rows = {}
for surface in ('snow', 'deep', 'wood', 'ice'):
    bank = {}
    for path in sorted((ROOT / 'assets/audio').glob(f'step_{surface}_*.wav')):
        with wave.open(str(path)) as stream:
            assert stream.getsampwidth() == 2
            samples = array.array('h', stream.readframes(stream.getnframes()))
            import sys
            if sys.byteorder != 'little':
                samples.byteswap()
            rms = math.sqrt(sum(x*x for x in samples) / len(samples)) / 32768
            peak = max(abs(x) for x in samples) / 32768
            bank[path.stem] = {'rms_db': 20*math.log10(max(rms, 1e-9)),
                               'peak': peak, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    target = statistics.median(row['rms_db'] for row in bank.values())
    for name, row in bank.items():
        row['gain_db'] = round(min(4.0, max(-4.0, target-row['rms_db']),
                                   20*math.log10(.70/max(row['peak'], 1e-9))), 3)
        row['rms_db'] = round(row['rms_db'], 3)
        rows[name] = row
result = {'description': 'Existing PCM sample RMS compensation; +/-4 dB, normalized peak <=0.70 before mixer gain.',
          'samples': rows}
(ROOT / 'assets/audio/foley_levels.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf8', newline='\n')
print('FOLEY_LEVELS_OK', len(rows), 'unchanged WAV files')
