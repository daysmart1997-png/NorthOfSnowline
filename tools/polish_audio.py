"""CC0 recorded foley cleanup plus original layered ambient score. See docs/06_POLISH.md."""
import sys,os,json,glob
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1].as_posix()
Path(ROOT+'/artifacts').mkdir(exist_ok=True)
import numpy as np, soundfile as sf
from scipy.signal import butter,sosfilt,resample_poly
OUT=ROOT+'/assets/audio';SR=32000;rng=np.random.default_rng(1703)
def clean(path,cut=6200):
 x,r=sf.read(path,always_2d=True);x=x.mean(axis=1);x=resample_poly(x,SR,r)
 x=sosfilt(butter(2,70,fs=SR,btype='highpass',output='sos'),x)
 x=sosfilt(butter(2,cut,fs=SR,output='sos'),x)
 threshold=max(np.max(abs(x))*.015,.0001);ids=np.where(abs(x)>threshold)[0]
 if len(ids):x=x[max(0,ids[0]-int(.014*SR)):min(len(x),ids[-1]+int(.05*SR))]
 return x
def write(name,x,peak=.55,fade=.014):
 x=np.array(x);x-=x.mean(axis=0)
 if np.max(abs(x))>0:x*=peak/np.max(abs(x))
 n=min(int(fade*SR),len(x)//3);window=np.ones(len(x));window[:n]=np.linspace(0,1,n);window[-n:]=np.linspace(1,0,n)
 x*=window[:,None] if x.ndim>1 else window
 sf.write(OUT+'/'+name+'.wav',x,SR,subtype='PCM_16')
files=sorted(glob.glob(ROOT+'/source_art/audio/snow/**/*.flac',recursive=True))
snow=[p for p in files if 'and_ice' not in p];ice=[p for p in files if 'and_ice' in p]
for i in range(8):
 x=clean(snow[i],4800);write('step_snow_'+str(i),x,.52)
 # Snow with greater depth has a softer contact and more body, not a random pitch shift.
 x=sosfilt(butter(2,2100,fs=SR,output='sos'),x);write('step_deep_'+str(i),x,.52)
for i in range(4):write('step_ice_'+str(i),clean(ice[i],5800),.45)
breath=clean(ROOT+'/source_art/audio/breathing_tired.wav',5000)
write('breath_pant',breath,.44,.055)
calm=breath[:int(len(breath)*.52)];calm=sosfilt(butter(2,2700,fs=SR,output='sos'),calm)
write('breath_calm',calm,.32,.07)
for i in range(4):
 t=np.arange(int(SR*.28))/SR
 noise=sosfilt(butter(2,950,fs=SR,output='sos'),rng.normal(0,1,len(t)))
 wood=(np.sin(2*np.pi*(105+i*13)*t)*.35+np.sin(2*np.pi*237*t)*.13+noise*.34)*np.exp(-t*24)*(1-np.exp(-t*350))
 write('step_wood_'+str(i),wood,.32)
t=np.arange(int(SR*.5))/SR;noise=rng.normal(0,1,len(t))
rustle=sosfilt(butter(2,[350,3800],fs=SR,btype='bandpass',output='sos'),noise)
rustle*=np.sin(np.pi*t/.5)**2*(.20+.8*np.sin(t*51)**2)
write('bag_unroll',rustle,.20)

def score(name,roots,melody,seconds,bright=False):
 n=int(seconds*SR);out=np.zeros((n,2));bar=seconds/len(roots)
 for j,root in enumerate(roots):
  # Sustained harmony overlaps changes; no repeated short bell at every beat.
  start=j*bar;dur=min(bar+4,seconds-start);t=np.arange(int(dur*SR))/SR
  env=np.minimum(1,t/3)*np.minimum(1,(dur-t)/3)
  for k,interval in enumerate([0,7,12,15]):
   f=440*2**((root+interval-69)/12)
   pad=(np.sin(2*np.pi*f*t)+.19*np.sin(2*np.pi*f*2.001*t)+.07*np.sin(2*np.pi*f*3*t))*.034*env
   for c in range(2):out[int(start*SR):int(start*SR)+len(t),c]+=pad*(.72 if (k+c)%2 else 1)
 for j,note in enumerate(melody):
  start=2+j*(seconds-8)/len(melody);dur=min(5.5,seconds-start);t=np.arange(int(dur*SR))/SR;f=440*2**((note-69)/12)
  env=(1-np.exp(-t*42))*np.exp(-t*(1.25 if bright else .83))
  tone=sum(np.sin(2*np.pi*f*h*t)*np.exp(-t*h*.12)/(h*h) for h in range(1,5))*.16*env
  pan=.35+.3*(j%3)/2
  for c,gain in [(0,1-pan),(1,pan)]:
   at=int(start*SR);out[at:at+len(t),c]+=tone*gain
   for delay,amount in [(.19,.17),(.43,.11),(.81,.07)]:
    d=at+int(delay*SR);length=min(len(t),n-d)
    if length>0:out[d:d+length,1-c]+=tone[:length]*amount
 write(name,out,.48,2.5)
score('winter_ambient',[45,41,48,43,45,41,48,40],[69,72,76,71,67,64,69,72,67,64,62,64],80)
score('embers',[45,41,48,43],[64,69,72,76,72,69,65,64,60,64,67,64],48)
score('stride',[50,45,47,43],[74,69,74,78,76,71,76,79,74,69,71,67,74,78,76,74],48,True)
score('homeward',[48,45,41,43],[72,76,79,76,72,69,65,69,72,67,71,72],48)
report={}
for f in glob.glob(OUT+'/*.wav'):
 x,r=sf.read(f);report[os.path.basename(f)]={'seconds':round(len(x)/r,3),'peak':round(float(np.max(abs(x))),4),'rms':round(float(np.sqrt(np.mean(x*x))),4)}
json.dump(report,open(ROOT+'/artifacts/audio-quality.json','w'),indent=2)
print('AUDIO_POLISH_OK',len(report),'files; recorded snow, ice, breathing; original wood, rustle, 80s score, 48s cassettes')
