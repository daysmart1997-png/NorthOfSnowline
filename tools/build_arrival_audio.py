"""Original material foley sketches; no external recordings. Writes arrival only."""
import math,random,struct,wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'assets/arrival'
for name in ['wood','water','food','cloth','bandage','battery']:
 rng=random.Random(name);samples=[];slow=0
 for i in range(17640):
  t=i/22050;noise=rng.uniform(-1,1);slow+=.06*(noise-slow)
  if name=='water':v=.19*math.sin(2*math.pi*(280*t+20*math.sin(t*21)))*math.exp(-t*5)+slow*.7*math.sin(t*6)**2
  elif name=='wood':v=(slow*.9+math.sin(t*2*math.pi*180)*.15)*math.exp(-t*15)
  elif name=='battery':v=(math.sin(t*2*math.pi*1200)*.13+math.sin(t*2*math.pi*1960)*.07)*math.exp(-t*35)
  else:v=noise*(.05 if name=='food' else .022)*math.sin(t*math.pi/.8)**2*(.6+.4*math.sin(t*48)**2)
  samples.append(int(max(-.8,min(.8,v))*32767))
 with wave.open(str(root/('foley_'+name+'.wav')),'wb') as out:
  out.setparams((1,2,22050,0,'NONE','not compressed'));out.writeframes(struct.pack('<'+'h'*len(samples),*samples))
print('ARRIVAL_AUDIO_OK')
