"""Original south-route buildings and six field objects. Only writes arrival assets.
Run with Blender --background --python tools/build_arrival_assets.py.
"""
from pathlib import Path
ROOT_PATH=Path(__file__).resolve().parents[1]
helpers=(ROOT_PATH/'tools/build_architecture.py').read_text().split("root=start('ForestryCabin')")[0]
exec(compile(helpers,'architecture_helpers','exec'))
OUT=ROOT_PATH/'assets/arrival';OUT.mkdir(exist_ok=True)
SOURCE=ROOT_PATH/'source_art/arrival';SOURCE.mkdir(exist_ok=True)
linen=mat('Linen',(.60,.57,.46));paint=mat('FlaskEnamel',(.28,.37,.36),.25)
label=mat('RationPaper',(.53,.36,.20));silver=mat('BatteryMetal',(.46,.48,.45),.7)

def save(root,name):
 bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(name+'.blend')))
 # Keep editable source separate from runtime joins, retaining meaningful groups.
 for parent in [o for o in bpy.data.objects if o.type=='EMPTY']:
  buckets={}
  for o in list(parent.children):
   if o.type=='MESH' and o.name!='FireWindow':buckets.setdefault(o.data.materials[0].name,[]).append(o)
  for key,objects in buckets.items():
   if len(objects)<2:continue
   bpy.ops.object.select_all(action='DESELECT')
   for o in objects:o.select_set(True)
   bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=parent.name+'_'+key
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_animations=False,export_apply=True)
 print('ARRIVAL_ASSET',name,flush=True)

def shell(root,w,d,low=False):
 rear=group('Structure',root);front=group('CutawayFront',root);right=group('CutawayRight',root);roof=group('Roof',root)
 box('Floor',(0,-.07,0),(w*2,.14,d*2),floor,rear)
 for x in [-w,w]:
  wall=right if x>0 else rear
  # Broad real window opening and weathered framing, not painted signs.
  for y,h in [(.45,.9),(2.35,.5)]:box('Side wall',(x,y,0),(.16,h,d*2),rust if low else wood,wall)
  for z in [-d,-d*.45,d*.45,d]:box('Window post',(x,1.55,z),(.20,1.4,.14),wood,wall)
  box('Window sill',(x,1.0,0),(.28,.12,d*2),floor,wall)
  for z in [-d*.7,d*.7]:box('Window shutter',(x,1.55,z),(.17,1.05,d*.52),wood,wall)
 box('Back wall',(0,1.3,-d),(w*2,2.6,.17),wood,rear)
 for x in [-1,1]:box('Door side',(x*(w+.65)/2,1.3,d),(w-.65,2.6,.16),wood,front)
 box('Door header',(0,2.45,d),(1.3,.3,.18),wood,front)
 for x in [-.7,.7]:box('Door jamb',(x,1.2,d),(.12,2.4,.26),cutwood,front)
 if low:
  # Small single-slope service kiosk, with a visibly damaged window.
  r=box('Sloped metal roof',(0,2.82,0),(2*w+.55,.17,2*d+.6),iron,roof);r.rotation_euler.x=.07
  cap=box('Snow on roof',(0,2.94,0),(2*w+.55,.12,2*d+.6),snow,roof);cap.rotation_euler.x=.07
  beam('Broken brace',(-w,1.0,-.4),(-w,1.9,.6),.04,cutwood,rear,4)
  for z in [-.7,-.4,-.1]:box('Drift under window',(-w+.22,.025,z),(.40,.045,.24),snow,rear,.03)
 else:
  for side in [-1,1]:
   mesh('Roof timber',[(0,3.7,-d-.25),(side*(w+.3),2.65,-d-.25),(side*(w+.3),2.65,d+.25),(0,3.7,d+.25)],[(0,1,2,3)],wood,roof)
  snow_roof(roof,w*2+.65,d*2+.6,2.65,3.7)
 for x in [-w+.25,w-.25]:
  for z in [-d+.25,d-.25]:box('Stone foot',(x,-.18,z),(.5,.3,.55),stone,rear,.07)
 return rear,roof

root=start('RoadKiosk');inside,roof=shell(root,2.3,2.8,True)
box('Desk',(0,1,-2.2),(2.1,.12,.8),floor,inside)
for x in [-.85,.85]:box('Desk leg',(x,.46,-2.2),(.12,.92,.58),wood,inside)
for y in [.38,1.05,1.8]:box('Narrow shelf',(1.7,y,-1.6),(.6,.08,1.5),floor,inside)
box('Bench',(-1.65,.46,.6),(.58,.12,2.0),floor,inside)
for z in [0,1.2]:box('Bench leg',(-1.65,.2,z),(.42,.4,.12),wood,inside)
box('Folded route note',(-.55,1.08,-2.15),(.38,.025,.28),paper,inside)
box('Empty tin',(.64,1.11,-2.2),(.19,.12,.18),iron,inside)
save(root,'road_kiosk')

root=start('CharcoalLodge');inside,roof=shell(root,3.7,3.2)
# Partial partition makes a sleeping alcove without blocking the central path.
box('Sleeping partition',(-1.45,1.05,-1.2),(.12,2.1,2.3),wood,inside)
box('Bed frame',(-2.55,.29,-1.05),(1.35,.25,2.15),wood,inside)
box('Mattress',(-2.55,.48,-1.05),(1.28,.18,2.08),wool,inside,.065)
for i in range(8):box('Blanket folds',(-3.1+i*.16,.59,-.8),(.17,.04,1.5),canvas,inside,.025)
box('Pillow',(-2.55,.62,-1.79),(.98,.18,.43),linen,inside,.09)
box('Hearth',(2.35,.04,-1.9),(1.25,.08,1.25),stone,inside)
beam('Iron stove',(2.35,.12,-1.9),(2.35,1.02,-1.9),.4,iron,inside,12)
box('FireWindow',(2.35,.62,-1.49),(.30,.30,.025),fire,inside)
beam('Stove pipe',(2.35,1.03,-1.9),(2.35,2.7,-1.9),.13,iron,inside,12)
beam('Chimney',(2.35,2.7,-1.9),(2.35,4.0,-1.9),.13,iron,roof,12)
beam('Chimney cap',(2.35,4,-1.9),(2.35,4.12,-1.9),.23,iron,roof,12)
box('Packing table',(1.5,.82,1.3),(1.65,.13,.78),floor,inside)
for x in [.82,2.18]:box('Table leg',(x,.39,1.3),(.13,.78,.6),wood,inside)
for x in [-.85,.8]:box('Wall cupboard upright',(x,1.12,-2.9),(.09,2.12,.45),wood,inside)
for y in [.2,.9,1.6,2.15]:box('Cupboard shelf',(-.02,y,-2.9),(1.8,.1,.5),floor,inside)
box('Drying rail',(-2.5,2.2,1.4),(1.7,.07,.08),iron,inside)
box('Old drying cloth',(-2.5,1.84,1.4),(.68,.68,.035),canvas,inside)
box('Stove instruction',(.23,1.68,-2.82),(.38,.025,.24),paper,inside)
save(root,'charcoal_lodge')

for item in ['wood','water','food','cloth','bandage','battery']:
 root=start('Item_'+item)
 if item=='wood':
  log((-.26,.1,0),(.26,.1,0),.10,root)
  for z in [-.065,.01,.065]:beam('Split grain',(-.2,.18,z),(.21,.17,z+.01),.008,cutwood,root,4)
 elif item=='water':
  box('Enamel flask',(0,.20,0),(.26,.39,.16),paint,root,.065)
  for y in [.055,.32]:box('Canvas strap',(0,y,.092),(.27,.055,.03),canvas,root,.008)
  cap=group('Cap',root);beam('Threaded cap',(0,.40,0),(0,.45,0),.067,iron,cap,16)
  beam('Flask seam',(0,.03,-.085),(0,.35,-.085),.008,silver,root)
 elif item=='food':
  box('Paper ration',(0,.09,0),(.30,.18,.18),label,root,.024)
  box('Paper seam',(0,.09,.099),(.04,.16,.02),paper,root)
  box('Muted label',(-.065,.10,.101),(.08,.065,.006),linen,root,.001)
  seal=group('Seal',root);box('Folded top',(0,.187,0),(.28,.026,.17),paper,seal)
 elif item=='cloth':
  for i in range(4):box('Folded cloth',(0,.018+i*.028,0),(.32-i*.007,.025,.23),canvas if i%2 else linen,root,.013)
  for x in range(9):beam('Frayed edge',(-.14+x*.035,.1,.12),(-.14+x*.035,.095,.15),.003,linen,root,4)
 elif item=='bandage':
  beam('Linen roll',(0,.095,-.06),(0,.095,.06),.095,linen,root,24)
  beam('Roll core',(0,.095,.061),(0,.095,.064),.028,paper,root,16)
  for r in [.047,.068,.082]:
   pts=[(math.cos(i*math.tau/32)*r,.095+math.sin(i*math.tau/32)*r,.062) for i in range(33)]
   for a,b in zip(pts,pts[1:]):beam('Wound edge',a,b,.0025,canvas,root,4)
  box('Loose end',(.09,.018,0),(.17,.02,.12),linen,root)
 elif item=='battery':
  beam('Battery casing',(0,.02,0),(0,.19,0),.048,iron,root,16)
  beam('Paper band',(0,.06,0),(0,.13,0),.049,label,root,16)
  beam('Positive terminal',(0,.19,0),(0,.205,0),.021,silver,root,16)
  box('Identification stripe',(0,.09,.05),(.018,.046,.004),paper,root,.001)
 save(root,'item_'+item)
print('ARRIVAL_ASSETS_OK',flush=True)
