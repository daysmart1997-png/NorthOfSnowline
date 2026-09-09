"""Sequential, same-route GPU ablations using the native renderer."""
from pathlib import Path
import subprocess, json
from datetime import datetime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/exploration'/('profile-'+datetime.now().strftime('%Y%m%d-%H%M%S'))
OUT.mkdir(parents=True,exist_ok=True)
for name, flags in [('baseline',[]),('no-shadows',['--no-shadows']),('no-detail',['--no-detail']),('snow-255',['--snow-255'])]:
    p=subprocess.run([str(Path.home()/'.local/bin/godot'),'--path',str(ROOT),'--resolution','1280x720','tools/performance_probe.tscn','--','--performance-check',*flags],capture_output=True,text=True,timeout=90)
    log=p.stdout+p.stderr
    (OUT/f'profile-{name}.log').write_text(log)
    if p.returncode or 'ERROR' in log or 'PERFORMANCE_SAMPLE' not in log: raise RuntimeError(log)
    data=json.loads((ROOT/'artifacts/v04-performance.json').read_text())
    (OUT/f'profile-{name}.json').write_text(json.dumps(data,indent=2))
    print(name,data,flush=True)
