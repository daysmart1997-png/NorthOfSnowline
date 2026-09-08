import math,random,array,wave,os
from pathlib import Path
root=(Path(__file__).resolve().parents[1]/'assets'/'audio').as_posix()
rate=22050
def write(name,seconds,mode):
 random.seed(293);samples=array.array('h');low=0.;click=0.
 for i in range(int(seconds*rate)):
  t=i/rate;noise=random.uniform(-1,1);low=low*.96+noise*.04
  if mode=='wind':v=low*(.4+.25*math.sin(t*.63)**2)+noise*.008
  elif mode=='fire':
   if random.random()<.00015:click=random.uniform(.15,.55)
   click*=.85;v=low*.35+click*noise
  else:v=(low*.9+noise*.18)*math.exp(-t*17)*min(1,t/.012)
  v*=min(1,t/.03,(seconds-t)/.06)
  samples.append(int(max(-1,min(1,v))*28000))
 with wave.open(os.path.join(root,name+'.wav'),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(samples.tobytes())
write('wind',20,'wind');write('fire',12,'fire');write('snow_step',.35,'step')
print('SOUNDSCAPE_COMPLETE')
