"""Build only three first-night settlement buildings; never rebuild earlier assets."""
from pathlib import Path
import ast
import numpy as np
ROOT_PATH=Path(__file__).resolve().parents[1]
exec(compile((ROOT_PATH/'tools/build_architecture.py').read_text().split("root=start('ForestryCabin')")[0],'geometry_helpers','exec'))
tree=ast.parse((ROOT_PATH/'tools/build_mountain_kiosk.py').read_text())
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['value_noise','png','textured','uv_objects']],type_ignores=[]),'texture_helpers','exec'))
OUT=ROOT_PATH/'assets/settlement';OUT.mkdir(exist_ok=True)
SOURCE=ROOT_PATH/'source_art/settlement';SOURCE.mkdir(exist_ok=True)
timber=textured('SettlementWood',(.34,.30,.24),'wood')
paint=textured('SettlementPaint',(.26,.34,.31),'paint')
metal=textured('SettlementIron',(.20,.23,.24),'metal')
random.seed(912)

def shell(name,w,d,shed=False):
 root=start(name);rear=group('Structure',root);front=group('CutawayFront',root);right=group('CutawayRight',root);roof=group('Roof',root)
 for i in range(round(w*6)):
  x=-w+(i+.5)*2*w/round(w*6)
  box('Floor board',(x,-.07,0),(2*w/round(w*6)-.008,.14,d*2),timber,rear,.005)
 for side in [-1,1]:
  parent=right if side>0 else rear
  for i in range(round(d*5)):
   z=-d+(i+.5)*2*d/round(d*5)
   for y,h in ([(1.25,2.5)] if shed or abs(z)>1 else [(.5,1.0),(2.27,.46)]):
    box('Weathered siding',(side*w,y,z),(.14,h,2*d/round(d*5)-(.05 if shed else .014)),timber if shed else paint,parent,.006)
  for z in [-d,0,d]:box('Wall upright',(side*w,1.25,z),(.21,2.55,.15),timber,parent)
  if not shed:
   for y in [1,2.05]:box('Window sill',(side*w,y,0),(.3,.09,2.0),timber,parent)
   beam('Broken diagonal shutter',(side*w,1.08,-.8),(side*w,1.92,.35),.04,timber,parent,4)
 box('Back wall',(0,1.25,-d),(w*2,2.5,.15),paint if not shed else timber,rear)
 for side in [-1,1]:
  box('Door surround',(side*(w+.7)/2,1.25,d),(w-.7,2.5,.15),paint if not shed else timber,front)
  box('Thick jamb',(side*.73,1.2,d+.04),(.14,2.4,.26),timber,front)
 box('Header',(0,2.4,d),(1.4,.2,.2),timber,front)
 # Dense snow is a continuous uneven mantle; roof silhouette varies by building.
 ridge=2.8 if shed else (3.65 if name=='MessHall' else 3.1)
 for side in [-1,1]:
  mesh('Roof deck',[(0,ridge,-d-.25),(side*(w+.3),2.5,-d-.25),(side*(w+.3),2.5,d+.25),(0,ridge,d+.25)],[(0,1,2,3)],metal,roof)
  beam('Barge board',(0,ridge,d+.25),(side*(w+.3),2.5,d+.25),.065,timber,roof)
 snow_roof(roof,w*2+.65,d*2+.6,2.5,ridge)
 for z in [-d,d]:mesh('Gable',[(-w,2.48,z),(w,2.48,z),(0,ridge,z)],[(0,1,2)],timber,roof)
 for x in [-w+.3,w-.3]:
  for z in [-d+.3,d-.3]:box('Foundation',(x,-.2,z),(.6,.35,.6),stone,rear,.06)
 return root,rear,roof

def save(root,name):
 uv_objects()
 for image in bpy.data.images:
  if image.source=='FILE' and Path(image.filepath).is_file():image.pack()
 bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(name+'.blend')))
 for parent in [o for o in bpy.data.objects if o.type=='EMPTY']:
  buckets={}
  for o in list(parent.children):
   if o.type=='MESH':buckets.setdefault(o.data.materials[0].name,[]).append(o)
  for objects in buckets.values():
   if len(objects)<2:continue
   bpy.ops.object.select_all(action='DESELECT')
   for o in objects:o.select_set(True)
   bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_animations=False,export_apply=True)
 print('SETTLEMENT_ASSET',name,flush=True)

root,inside,roof=shell('MessHall',3.2,3.1)
for y in [.2,.95,1.7]:box('Pantry shelf',(0,y,-2.65),(4.4,.10,.6),timber,inside)
for x in [-2.12,2.12]:box('Pantry post',(x,.9,-2.65),(.12,1.8,.6),timber,inside)
box('Chipped enamel counter',(-2.4,.75,-.8),(.8,1.5,1.6),paint,inside)
for y in [.1,1.42]:box('Counter trim',(-2.4,y,-.8),(.85,.06,1.65),metal,inside)
box('Long dining table',(-1.6,.85,1.0),(2.2,.12,1.0),timber,inside)
for x in [-2.4,-.8]:box('Table trestle',(x,.4,1),(.12,.8,.85),timber,inside)
for i in range(4):beam('Empty ration tin',(-1.5+i*.5,1.02,-2.55),(-1.5+i*.5,1.25,-2.55),.10,metal,inside,12)
box('Pantry list',(.75,1.04,-2.45),(.34,.025,.3),paper,inside)
save(root,'canteen')

root,inside,roof=shell('FuelShed',2.8,2.4,True)
for side in [-1,1]:
 for y in [.25,.8,1.35]:box('Firewood rack',(side*2.05,y,-.1),(1.05,.10,3.8),timber,inside)
 for z in [-1.9,1.7]:box('Rack brace',(side*2.05,.8,z),(.95,1.6,.10),timber,inside)
# Empty rack spaces are intentional; actual collectible dry logs come from game state.
for i in range(5):
 log((-2.3+i*.2,.35,-1.4),(-2.3+i*.2,.35,.15),.08,inside)
box('Oilcloth cover',(1.95,1.63,-.1),(1.15,.045,3.7),canvas,inside)
box('Bundle shelf',(0,.65,-1.65),(2.3,.12,.9),timber,inside)
for x in [-1,1]:box('Shelf leg',(x,.32,-1.65),(.12,.64,.85),timber,inside)
save(root,'woodshed')

root,inside,roof=shell('WorkersQuarters',4.0,2.8)
for x in [-2.85,2.85]:
 box('Empty bunk frame',(x,.3,-.6),(1.45,.45,2.5),timber,inside)
 box('Torn mattress',(x,.57,-.6),(1.38,.14,2.4),wool,inside,.04)
 for z in [-1.8,.6]:box('Bed post',(x,.52,z),(1.45,.10,.10),metal,inside)
box('Collapsed dividing panel',(-1.5,.32,-1.6),(.17,.64,1.6),timber,inside)
for i in range(5):ellipsoid('Indoor snow drift',(3.3,.06,1+i*.2),(.55,.06,.2),snow,inside)
box('Personal effects table',(0,.8,-2.2),(2.2,.12,.7),timber,inside)
for x in [-.9,.9]:box('Table support',(x,.39,-2.2),(.1,.78,.65),timber,inside)
box('Shift card',(.75,.88,-2.2),(.3,.025,.24),paper,inside)
save(root,'bunkhouse')
print('SETTLEMENT_ASSETS_OK',flush=True)
