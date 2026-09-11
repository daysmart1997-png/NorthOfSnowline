"""Targeted, original building refinements. Run with Blender --background --python.
Only writes cabin_lived / station_workshop; never rebuilds legacy architecture.
Coordinates use Godot X/right, Y/up, Z/front. Source stays unmerged/editable.
"""
from pathlib import Path
import json

ROOT_PATH = Path(__file__).resolve().parents[1]
legacy = (ROOT_PATH / 'tools/build_architecture.py').read_text(encoding='utf-8')
# Reuse reviewed geometry helpers and the original cabin construction only.
# No legacy export invocation or subsequent bridge/camp/prop construction runs.
exec(compile(legacy.split("root=start('ForestryCabin')")[0], 'architecture_helpers', 'exec'))
home_source = "root=start('ForestryCabin')" + legacy.split("root=start('ForestryCabin')", 1)[1].split("export(root,'cabin')", 1)[0]

LAYOUTS = {
 'home': {'asset': 'cabin_lived', 'half_width': 4.0, 'obstructions': [
  [[-2.4,.53,-2.57],[1.5,.58,2.2]], [[2.6,.79,-2],[.90,1.1,.90]],
  [[1.22,.64,1.44],[1.45,.8,1.35]], [[-2.43,.68,-1],[1.45,.88,1.0]],
  [[-2.7,.69,2.5],[1.48,.90,.83]], [[.3,1.32,-3.68],[2.2,2.16,.45]],
  [[2.55,.72,1.0],[.52,.96,.56]]]},
 'station': {'asset': 'station_workshop', 'half_width': 5.0, 'obstructions': [
  [[-2.6,.71,-1],[3.4,.94,1.0]], [[2.6,.79,-2],[.90,1.1,.90]],
  [[4.12,.50,1.5],[.96,.52,1.92]], [[-4.45,.96,1.7],[.64,1.44,2.2]],
  [[-.35,1.30,-3.60],[2.4,2.12,.64]]]},
}


def drop(prefixes):
 for o in list(bpy.data.objects):
  if o.type == 'MESH' and any(o.name == p or o.name.startswith(p + '.') for p in prefixes):
   bpy.data.objects.remove(o, do_unlink=True)


def cloth(name, center, width, length, material, parent, drape=.18):
 x,y,z=center;verts=[];faces=[];nx=16;nz=20
 for j in range(nz+1):
  t=j/nz
  for i in range(nx+1):
   s=i/nx
   edge=max(0,(abs(s-.5)-.39)/.11)
   yy=y-drape*edge+.014*math.sin(t*17+s*5)+.010*math.cos(s*19+t*4)
   verts.append((x+(s-.5)*width,yy,z+(t-.5)*length))
 for j in range(nz):
  for i in range(nx):
   a=j*(nx+1)+i;faces.append((a,a+nx+1,a+nx+2,a+1))
 o=mesh(name,verts,faces,material,parent)
 for p in o.data.polygons:p.use_smooth=True
 mod=o.modifiers.new('Wool thickness','SOLIDIFY');mod.thickness=.023
 bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o


def stove(parent, roof_parent=None):
 stove_group=group('CastIronStove',parent)
 box('Hearth slab',(2.6,.04,-2),(1.14,.08,1.18),stone,stove_group,.035)
 beam('Stove body',(2.6,.15,-2),(2.6,1.10,-2),.40,iron,stove_group,16)
 for y in [.22,1.10]:beam('Stove cast rim',(2.6,y,-2),(2.6,y+.065,-2),.44,iron,stove_group,16)
 box('Iron door',(2.6,.65,-1.60),(.46,.51,.065),iron,stove_group,.04)
 box('FireWindow',(2.6,.66,-1.555),(.29,.29,.024),fire,stove_group,.026)
 beam('Door latch',(2.83,.64,-1.52),(2.83,.80,-1.52),.026,iron,stove_group)
 box('Ash drawer',(2.6,.27,-1.54),(.36,.09,.17),iron,stove_group)
 for x in [2.33,2.87]:
  for z in [-2.23,-1.77]:beam('Stove foot',(x,.075,z),(x,.25,z),.04,iron,stove_group)
 beam('StovepipeInside',(2.6,1.18,-2),(2.6,3.05,-2),.13,iron,stove_group,12)
 for y in [1.22,1.95,2.70]:beam('Pipe collar',(2.6,y,-2),(2.6,y+.065,-2),.15,iron,stove_group,12)
 beam('Kettle belly',(2.6,1.18,-1.89),(2.6,1.36,-1.89),.17,iron,stove_group,12)
 beam('Kettle handle',(2.43,1.42,-1.89),(2.77,1.42,-1.89),.022,iron,stove_group)
 if roof_parent:
  beam('StovepipeRoof',(2.6,3.05,-2),(2.6,4.1,-2),.13,iron,roof_parent,12)
  beam('Chimney cap',(2.6,4.1,-2),(2.6,4.22,-2),.24,iron,roof_parent,12)


def chair(at,parent):
 x,y,z=at;g=group('KitchenChair',parent)
 for dx in [-.20,.20]:
  for dz in [-.21,.21]:beam('Splayed chair leg',(x+dx*1.15,y,z+dz*1.1),(x+dx,y+.45,z+dz),.033,wood,g,4)
 for dz in [-.20,0,.20]:box('Seat board',(x,y+.47,z+dz),(.52,.065,.18),floor,g)
 for dx in [-.21,.21]:beam('Chair back post',(x+dx,y+.42,z+.22),(x+dx,y+1.0,z+.29),.032,wood,g,4)
 for yy in [.75,.94]:box('Back slat',(x,y+yy,z+.27),(.47,.10,.045),floor,g)
 beam('Chair stretcher',(x-.2,y+.20,z),(x+.2,y+.20,z),.025,wood,g,4)


def save_asset(root,name):
 source=ROOT_PATH/'source_art/architecture_v2';source.mkdir(exist_ok=True)
 bpy.ops.object.select_all(action='DESELECT')
 bpy.ops.wm.save_as_mainfile(filepath=str(source/(name+'.blend')))
 # Keep structural cutaway groups and individually meaningful furniture groups.
 for parent in [o for o in bpy.data.objects if o.type=='EMPTY']:
  buckets={}
  for o in list(parent.children):
   if o.type=='MESH' and o.name!='FireWindow':buckets.setdefault(o.data.materials[0].name,[]).append(o)
  for material,objects in buckets.items():
   if len(objects)<2:continue
   bpy.ops.object.select_all(action='DESELECT')
   for o in objects:o.select_set(True)
   bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=parent.name+'_'+material
 bpy.ops.export_scene.gltf(filepath=str(ROOT_PATH/'assets/architecture'/ (name+'.glb')),export_format='GLB',export_animations=False,export_apply=True)
 print('BUILDING_REFINED',name,flush=True)


# Home: keep the recognizable shell, bring warmth and human-scale irregularity.
exec(compile(home_source,'home_shell','exec'))
root.name='LivedInCabin'
drop(['Blanket folds','Extra wool quilt','Jar','Jar lid','Mattress','Pillow',
      'Stove body','Stove rim','Stove legs','FireWindow','StovepipeInside'])
# Separate the bed from the receiver desk; preserve the existing rest interaction.
for o in bpy.data.objects:
 if o.name.startswith(('Bed leg','Bed frame')):o.location += v((0,0,-.35))
bedding=group('HomeBedding',inside)
box('Soft mattress',(-2.4,.52,-2.57),(1.39,.23,2.06),wool,bedding,.095)
pillow=box('Uneven pillow',(-2.46,.72,-3.24),(.95,.21,.43),paper,bedding,.08);pillow.rotation_euler.z=.065
cloth('Draped blanket',(-2.4,.666,-2.29),1.54,1.48,canvas,bedding,.16)
cloth('Extra wool quilt',(-2.4,.716,-2.02),1.57,.98,wool,bed_upgrade,.18)
for x in [-3.07,-1.73]:box('Bed head post',(x,.47,-3.62),(.10,.94,.10),wood,bedding)
box('Headboard',(-2.4,.68,-3.62),(1.42,.29,.08),floor,bedding)
# The shelves mix provisions, a folded textile, cups and deliberate empty space.
supplies=group('HomeSupplies',inside)
for x,y,z,r,h,m in [(-.39,.74,-3.68,.12,.27,paper),(-.05,.74,-3.65,.095,.20,canvas),(.70,1.40,-3.66,.105,.25,iron)]:
 beam('Provision tin',(x,y,z),(x,y+h,z),r,m,supplies,12)
 beam('Tin lid',(x,y+h,z),(x,y+h+.025,z),r*1.04,iron,supplies,12)
box('Linen bundle',(.60,.83,-3.67),(.69,.20,.34),wool,supplies,.05)
box('Tea box',(-.35,1.56,-3.68),(.43,.32,.32),wood,supplies)
for i in range(3):box('Folded towel',(.14,2.08+i*.042,-3.67),(.56,.044,.33),patch,supplies,.014)
box('Enamel bowl',(.92,2.12,-3.66),(.30,.14,.28),paper,supplies,.055)
# Aprons, a drawer and stretchers make the writing table different from a bench.
for x in [.60,1.84]:box('Table apron',(x,.59,1.44),(.055,.20,1.16),wood,inside)
box('Table drawer',(1.22,.58,.83),(1.22,.22,.075),floor,inside)
beam('Drawer pull',(1.09,.58,.77),(1.35,.58,.77),.019,iron,inside)
beam('Table stretcher',(.68,.24,1.44),(1.76,.24,1.44),.035,wood,inside,4)
chair((2.55,0,1.0),inside)
box('Closed field book',(1.03,.81,1.83),(.30,.065,.23),canvas,inside)
beam('Enamel mug',(1.64,.78,1.03),(1.64,.94,1.03),.075,paper,inside,12)
stove(inside)
trace=group('DepartureTrace',inside)
box('Unpaired mitten',(-3.78,1.72,-.02),(.13,.33,.21),wool,trace,.06)
beam('Mitten thumb',(-3.75,1.66,.08),(-3.72,1.78,.16),.044,wool,trace)
beam('Empty shoulder loop',(-3.79,1.95,-.38),(-3.73,1.42,-.38),.022,rope,trace)
box('Faded hook patch',(-3.91,1.53,-.37),(.012,.67,.29),patch,trace,.01)
save_asset(root,'cabin_lived')

# Station: a low, broad utility building with horizontal weatherboards.
root=start('LineMaintenanceWorkshop');inside=group('Interior',root);roof=group('Roof',root)
front=group('CutawayFront',root);right=group('CutawayRight',root);frame=group('PermanentFrame',root)
station_wood=mat('TimberWorkshop',(.235,.25,.24));faded=mat('TimberWorkshopFaded',(.30,.305,.28))
for i in range(25):box('Workshop floorboard',(-4.8+i*.4,-.035,0),(.39,.07,8),floor,inside,.006)
for z in [-4.04,4.04]:
 for i in range(19):ellipsoid('Stone foundation',(-4.8+i*.53,-.30,z),(.30,.25,.25),stone,frame)
for i in range(15):ellipsoid('Side foundation',(-5,-.30,-3.8+i*.54),(.26,.25,.30),stone,frame)
for z in [-4,4]:
 wall=frame if z<0 else front
 for row in range(13):
  y=.11+row*.205
  if z>0 and y<2.42:
   for x in [-3.02,3.02]:box('Horizontal siding',(x,y,z),(3.96,.197,.12),station_wood if row%4 else faded,wall,.009)
  else:box('Horizontal siding',(0,y,z),(10,.197,.12),station_wood if row%4 else faded,wall,.009)
 mesh('Shallow gable',[(-5,2.72,z),(5,2.72,z),(0,3.55,z)],[(0,1,2)],station_wood,roof)
 for side in [-1,1]:beam('Low gable beam',(0,3.56,z),(side*5.15,2.7,z),.10,wood,roof,4)
for x in [-5,5]:
 wall=frame if x<0 else right
 for row in range(13):box('Side weatherboard',(x,.11+row*.205,0),(.12,.197,8),station_wood if row%4 else faded,wall,.009)
 for z in [-4,4]:box('Corner post',(x,1.36,z),(.19,2.72,.19),wood,wall)
for side in [-1,1]:mesh('Low roof boarding',[(0,3.55,-4.5),(side*5.5,2.65,-4.5),(side*5.5,2.65,4.5),(0,3.55,4.5)],[(0,1,2,3)],wood,roof)
snow_roof(roof,width=11,length=9,eave=2.65,ridge=3.55)
for z in [-4.35,0,4.35]:
 for side in [-1,1]:beam('Workshop roof rafter',(0,3.55,z),(side*5.5,2.65,z),.095,wood,roof,4)
# A ribbon window and boarded service hatch form an asymmetric front.
box('Workshop window casing',(-2.95,1.81,4.1),(2.45,.86,.16),wood,front)
box('Workshop window glass',(-2.95,1.81,4.2),(2.22,.65,.02),glass,front)
for x in [-4.04,-3.31,-2.58,-1.85]:box('Window divider',(x,1.81,4.23),(.045,.73,.03),iron,front,.004)
box('Long sill',(-2.95,1.34,4.16),(2.59,.09,.31),floor,front)
box('Sill snow',(-2.95,1.42,4.20),(2.57,.08,.29),snow,front,.025)
for x in [2.55,3.24,3.93]:box('Closed service shutter',(x,1.54,4.10),(.65,1.48,.12),wood,front)
for y in [1.04,2.06]:box('Shutter brace',(3.24,y,4.19),(2.13,.11,.08),iron,front)
for x in [-.98,.98]:box('Door jamb',(x,1.22,4.12),(.15,2.44,.23),wood,front)
box('Door lintel',(0,2.5,4.1),(2.22,.18,.23),wood,front)
for i in range(8):box('Porch plank',(0,-.028,4.18+i*.22),(2.65,.06,.21),floor,frame,.007)
for x in [-1.35,1.35]:
 for z in [4.2,5.65]:box('Porch post',(x,.64,z),(.14,1.3,.14),wood,frame)
 box('Porch handrail',(x,1.02,4.9),(.12,.12,1.55),wood,frame)
lantern((1.31,2.1,4.26),front)
# Repair island against the left/rear zone. Front edge retains module reach.
bench=group('RepairWorkbench',inside)
# Explicit exported anchors keep feedback and pickup above the thicker surface.
group('ModuleSurface',bench).location=v((-2.45,.97,-1.0))
group('ModulePickup',bench).location=v((-2.45,1.02,-.70))
for x in [-4.08,-1.12]:
 for z in [-1.37,-.63]:box('Heavy bench leg',(x,.43,z),(.15,.86,.15),wood,bench)
for z in [-1.32,-1.0,-.68]:box('Thick bench plank',(-2.6,.86,z),(3.40,.14,.30),floor,bench,.023)
box('Bench stretcher',(-2.6,.23,-1),(3.18,.11,.13),wood,bench)
box('Lower tool shelf',(-2.6,.29,-1),(3.18,.065,.73),wood,bench)
for x in [-3.86,-3.31,-1.28]:box('Toolbox',(x,.47,-1),(.46,.28,.52),iron,bench)
box('Bench vice base',(-3.77,.97,-.82),(.36,.09,.35),iron,bench)
for z in [-.91,-.70]:box('Vice jaw',(-3.77,1.12,z),(.34,.21,.09),iron,bench)
beam('Vice screw',(-3.77,1.04,-.71),(-3.77,1.04,-.47),.034,iron,bench)
beam('Vice handle',(-3.90,1.04,-.45),(-3.64,1.04,-.45),.018,iron,bench)
box('Repair mat',(-2.51,.942,-1.08),(1.10,.027,.54),canvas,bench)
box('Open tool tray',(-1.28,.987,-1.10),(.44,.11,.46),iron,bench)
# Tool silhouettes on a board; no unreadable text or decorative nameplate.
tools_group=group('ToolWall',inside)
box('Tool board',(-3.2,1.77,-3.84),(2.55,1.38,.08),wood,tools_group)
for i in range(5):
 x=-4.20+i*.42;y=1.61+(i%2)*.15
 beam('Hanging tool handle',(x,y-.29,-3.72),(x,y+.14,-3.72),.024,cutwood if i%2 else iron,tools_group)
 box('Tool head',(x,y+.15,-3.72),(.18,.09,.06),iron,tools_group)
for i in range(4):
 box('Parts drawer',(-4.45,.20+i*.34,1.7),(.64,.31,2.20),station_wood,inside)
 for z in [1.13,2.24]:beam('Side drawer pull',(-4.09,.20+i*.34,z-.10),(-4.09,.20+i*.34,z+.10),.019,iron,inside)
cab=group('ElectricalPartsCabinet',inside)
# Hollow carcass, exported hinges and stock: searchable without removing the cabinet.
box('Cabinet back',(-.35,1.06,-3.88),(2.40,2.12,.08),wood,cab)
for x in [-1.51,.81]:box('Cabinet side',(x,1.06,-3.60),(.08,2.12,.64),wood,cab)
for y in [.06,1.02,2.08]:box('Cabinet shelf',(-.35,y,-3.60),(2.32,.08,.64),wood,cab)
for name,x,direction in [('CabinetDoorLeft',-1.55,1),('CabinetDoorRight',.85,-1)]:
 door=group(name,cab);door.location=v((x,0,-3.24))
 box('Cabinet door',(direction*.59,1.06,0),(1.12,1.97,.06),station_wood,door)
 beam('Cabinet grip',(direction*1.00,.97,.05),(direction*1.00,1.19,.05),.018,iron,door)
stock=group('CabinetStock',cab)
box('Dry cloth bundle',(-.80,1.14,-3.56),(.62,.16,.42),wool,stock,.04)
for x in [-.42,-.20,.02]:log((x,.24,-3.78),(x,.24,-3.40),.10,stock)
box('Canvas tool roll',(-.35,2.19,-3.6),(.73,.14,.38),canvas,cab,.06)
# Fold-away camp cot: visually and spatially different from the home bed.
cot=group('FoldingCot',inside)
for x in [3.69,4.55]:
 beam('Tubular cot rail',(x,.41,.55),(x,.41,2.45),.035,iron,cot)
 for z in [.82,2.15]:
  beam('Crossed cot leg',(x-.05,.02,z-.22),(x+.05,.42,z+.22),.027,iron,cot)
  beam('Crossed cot leg',(x-.05,.02,z+.22),(x+.05,.42,z-.22),.027,iron,cot)
cloth('Cot canvas',(4.12,.425,1.5),.89,1.90,canvas,cot,.06)
box('Rolled sleeping bag',(4.12,.57,2.12),(.75,.24,.42),wool,cot,.10)
box('Cot pillow',(4.12,.53,.80),(.65,.17,.36),patch,cot,.065)
for x in [3.93,4.31]:box('Bag strap',(x,.69,2.12),(.035,.02,.39),rope,cot)
stove(inside,roof)
for i in range(3):log((3.4,.12+i*.16,-2.6),(4.20,.12+i*.16,-2.6),.075,inside)
box('Scuffed entrance mat',(0,.012,2.85),(1.50,.018,.82),canvas,inside,.006)
save_asset(root,'station_workshop')
# Both collision layout and selected prefab are generated from this single plan.
layout_text='extends RefCounted\n# Generated by tools/refine_buildings.py; coordinates relative to building origin.\nconst DATA = '+json.dumps(LAYOUTS,indent=2)+'\n'
(ROOT_PATH/'scripts/building_layouts.gd').write_text(layout_text,encoding='utf-8',newline='\n')
print('BUILDING_REFINEMENT_OK',flush=True)
