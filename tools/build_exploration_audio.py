"""Two original synthesized mechanical cues; no voice recordings or external samples.
Only creates cabinet_open / memory_tape; does not rebuild existing chapter audio.
"""
import math,random,struct,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
for name,duration in [('cabinet_open',.8),('memory_tape',1.2)]:
 rng=random.Random(911);values=[];filtered=0.0
 for i in range(int(duration*22050)):
  t=i/22050;u=t/duration;filtered+=.13*(rng.uniform(-1,1)-filtered)
  envelope=math.sin(math.pi*u)**2
  if name=='cabinet_open':
   value=(filtered*.32+math.sin(math.tau*(150*t+55*t*t))*.07)*envelope
  else:
   # Paper movement followed by a soft cup-on-wood click; not fabricated speech.
   value=filtered*.20*envelope+math.sin(math.tau*430*t)*.12*math.exp(-max(0,t-.7)*48)*(1 if t>=.7 else 0)
  values.append(round(max(-.9,min(.9,value))*32767))
 path=ROOT/'assets/audio/chapter'/(name+'.wav')
 with wave.open(str(path),'wb') as f:
  f.setparams((1,2,22050,0,'NONE','not compressed'));f.writeframes(struct.pack('<'+'h'*len(values),*values))
print('EXPLORATION_AUDIO_OK: original mechanical cues, mono PCM 22050 Hz')
