"""Original short mechanical/cassette cues. No downloaded or recorded samples."""
import math,random,struct,wave,json
from pathlib import Path
R=Path(__file__).resolve().parents[1];out=R/'assets/audio/chapter';out.mkdir(exist_ok=True)
random.seed(910)
for name,length in [('contact',.65),('wire',.45),('test',1.1),('radio_connect',1.8),('radio_received',1.5),('tape_button',.22),('pack_rustle',.23)]:
 values=[];low=0.0
 for i in range(int(length*22050)):
  t=i/22050;u=t/length;low+=.18*(random.uniform(-1,1)-low)
  env=math.sin(math.pi*u)**2
  if name in ['contact','pack_rustle']:v=low*env*.30*(.5+.5*math.sin(t*49)**2)
  elif name in ['wire','tape_button']:v=(math.sin(t*math.tau*740)*.15+low*.3)*math.exp(-t*32)*env
  elif name=='test':v=(math.sin(t*math.tau*(450 if t<.45 else 650))*.11+low*.05)*env
  elif name=='radio_connect':v=low*.22*env+math.sin(t*math.tau*730)*.09*max(0,1-abs(t-.22)/.09)
  else:v=(math.sin(t*math.tau*510)+math.sin(t*math.tau*640))*.035*env+low*.07*env
  values.append(int(max(-.9,min(.9,v))*32767))
 with wave.open(str(out/(name+'.wav')),'wb') as w:
  w.setparams((1,2,22050,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(values),*values))
print('CHAPTER_AUDIO_OK: seven original mechanical cues, PCM mono 22050 Hz')
