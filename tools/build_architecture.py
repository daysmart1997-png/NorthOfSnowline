"""Editable Blender reconstruction of source_art/concepts/forestry-architecture-v04.png.
All modeling coordinates below are Godot X/right, Y/up, Z/front; converted for Blender export.
"""
import bpy,math,random,os
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1].as_posix();random.seed(44)
def v(p):return Vector((p[0],-p[2],p[1]))
def start(name):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 root=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(root)
 return root
def group(name,parent):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.parent=parent;return o
def mat(name,color,metal=0,emission=0):
 m=bpy.data.materials.get(name) or bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.86;p.inputs['Metallic'].default_value=metal
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 return m
wood=mat('TimberDark',(.16,.135,.11));rust=mat('TimberRust',(.27,.16,.125));floor=mat('TimberFloor',(.30,.265,.21));cutwood=mat('TimberEndgrain',(.39,.32,.225))
iron=mat('IronOxide',(.085,.105,.115),.50);snow=mat('SnowCap',(.65,.70,.76));stone=mat('FoundationStone',(.22,.255,.28));canvas=mat('WaxedCanvas',(.255,.28,.25));patch=mat('CanvasPatch',(.35,.34,.28));rope=mat('HempRope',(.43,.39,.29));wool=mat('BlanketWool',(.28,.32,.31));glass=mat('WindowAmber',(.50,.34,.14),0,.32);fire=mat('FireAmber',(.92,.34,.045),0,1.5);paper=mat('OldPaper',(.60,.56,.44));dark=mat('RadioDark',(.08,.105,.11))
def finish(o,name,material,parent):
 o.name=name;o.data.materials.append(material);o.parent=parent
 return o
def box(name,at,size,material,parent,bevel=.014):
 bpy.ops.mesh.primitive_cube_add(size=1,location=v(at));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);finish(o,name,material,parent)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Worn edges','BEVEL');mod.width=bevel;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def beam(name,a,b,r,material,parent,sides=8):
 delta=v(b)-v(a);bpy.ops.mesh.primitive_cylinder_add(vertices=sides,radius=r,depth=delta.length,location=(v(a)+v(b))/2)
 o=bpy.context.object;o.rotation_euler=delta.to_track_quat('Z','Y').to_euler();return finish(o,name,material,parent)
def ellipsoid(name,at,size,material,parent):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=v(at));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);return finish(o,name,material,parent)
def mesh(name,verts,faces,material,parent):
 m=bpy.data.meshes.new(name);m.from_pydata([v(p) for p in verts],[],faces);m.update();o=bpy.data.objects.new(name,m);bpy.context.collection.objects.link(o);return finish(o,name,material,parent)
def log(a,b,r,parent):
 beam('Bark log',a,b,r,wood,parent,10)
 axis=(v(b)-v(a)).normalized();bb=v(b)+axis*.004
 # Flat lighter end grain closes the log and makes the construction readable.
 bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=r*.87,depth=.008,location=bb);o=bpy.context.object;o.rotation_euler=axis.to_track_quat('Z','Y').to_euler();finish(o,'Cut end',cutwood,parent)
def bolts(at,parent):
 box('Gusset plate',at,(.27,.28,.025),iron,parent,.006)
 for x in [-.08,.08]:
  for y in [-.085,.085]:ellipsoid('Iron bolt',(at[0]+x,at[1]+y,at[2]+.023),(.021,.021,.012),iron,parent)
def lantern(at,parent):
 x,y,z=at
 box('Lantern cage',(x,y,z),(.20,.31,.19),iron,parent)
 box('Lantern glass',(x,y,z+.105),(.14,.21,.018),glass,parent,.002)
 beam('Lantern handle',(x-.07,y+.19,z),(x+.07,y+.19,z),.013,iron,parent)
def chest(at,parent,name='SupplyChest'):
 x,y,z=at
 for i in range(6):box(name+' plank',(x-.5+i*.20,y+.35,z),(.19,.66,.72),wood,parent)
 box(name+' lid',(x,y+.72,z),(1.22,.13,.82),floor,parent)
 for dx in [-.40,.40]:
  box('Iron band',(x+dx,y+.39,z+.376),(.075,.70,.025),iron,parent,.004)
  box('Lid band',(x+dx,y+.798,z),(.075,.018,.83),iron,parent,.004)
 box('Chest clasp',(x,y+.57,z+.40),(.10,.21,.035),iron,parent,.004)
def snow_roof(parent,width=9.0,length=9.1,eave=3.25,ridge=5.25):
 for side in [-1,1]:
  verts=[];faces=[];nx=8;nz=20
  for iz in range(nz+1):
   z=-length/2+length*iz/nz
   for ix in range(nx+1):
    t=ix/nx;x=side*t*width/2
    y=ridge+(eave-ridge)*t+.20+.055*math.sin(z*2.1+t*5)+.035*math.cos(z*4+t*8)
    verts.append((x,y,z))
  for iz in range(nz):
   for ix in range(nx):
    a=iz*(nx+1)+ix;faces.append((a,a+1,a+nx+2,a+nx+1) if side>0 else (a+1,a,a+nx+1,a+nx+2))
  mantle=mesh('Thick snow mantle',verts,[tuple(reversed(f)) for f in faces],snow,parent)
  for polygon in mantle.data.polygons:polygon.use_smooth=True
  # Snow eave has thickness and an irregular edge, not an infinitely thin plane.
  for iz in range(nz):
   z=-length/2+length*(iz+.5)/nz
   box('Snow lip',(side*width/2,eave+.12,z),(.15,.20+.04*math.sin(z*3),length/nz+.01),snow,parent,.03)
  for z in [-3.8,-2.1,.7,2.4,3.9]:beam('Icicle',(side*width/2,eave+.02,z),(side*width/2,eave-.16-random.random()*.13,z),.027,snow,parent,5)
def export(root,name):
 # Merge by structural group/material while retaining cutaway and interactive nodes.
 for parent in [o for o in bpy.data.objects if o.type=='EMPTY']:
  buckets={}
  for o in list(parent.children):
   if o.type=='MESH' and o.name not in ['FireWindow','FireBed']:buckets.setdefault(o.data.materials[0].name,[]).append(o)
  for material,objects in buckets.items():
   if len(objects)<2:continue
   bpy.ops.object.select_all(action='DESELECT')
   for o in objects:o.select_set(True)
   bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=parent.name+'_'+material
 bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/source_art/architecture_'+name+'.blend')
 bpy.ops.export_scene.gltf(filepath=ROOT+'/assets/architecture/'+name+'.glb',export_format='GLB',export_animations=False,export_apply=True)
 print('ARCHITECTURE_ASSET',name)

root=start('ForestryCabin');inside=group('Interior',root);roof=group('Roof',root);front=group('CutawayFront',root);right=group('CutawayRight',root);frame=group('PermanentFrame',root)
for i in range(20):box('Floorboard',(-3.8+i*.4,-.035,0),(.39,.07,8.0),floor,inside,.006)
for i in range(15):
 for z in [-4.07,4.07]:ellipsoid('Stone footing',(-3.8+i*.54,-.32,z),(.29,.28,.24),stone,frame)
for i in range(15):ellipsoid('Stone footing',(-4.05,-.32,-3.8+i*.54),(.25,.28,.28),stone,frame)
for z in [-4,4]:
 wall=frame if z<0 else front
 for i in range(22):
  x=-3.85+i*.367
  if z>0 and abs(x)<1.16:continue
  box('Vertical siding',(x,1.53,z),(.355,3.06,.13),rust if i%4 else wood,wall)
 if z>0:box('Door lintel',(0,2.92,z),(2.45,.35,.23),wood,wall)
 mesh('Gable', [(-4,3.1,z),(4,3.1,z),(0,5.05,z)],[(0,1,2)],rust,roof)
 for a,b in [((-4,3.1,z),(0,5.05,z)),((0,5.05,z),(4,3.1,z)),((-4,3.1,z),(4,3.1,z))]:beam('Gable timber',a,b,.13,wood,roof,4)
for x in [-4,4]:
 wall=frame if x<0 else right
 for i in range(22):box('Side siding',(x,1.53,-3.85+i*.367),(.13,3.06,.355),rust if i%3 else wood,wall)
 for z in [-4,4]:box('Corner post',(x,1.57,z),(.23,3.18,.23),wood,wall)
for z in [-4.3,-2.2,0,2.2,4.3]:
 for side in [-1,1]:beam('Roof rafter',(0,5.06,z),(side*4.45,3.08,z),.105,wood,roof,4)
for side in [-1,1]:mesh('Roof boarding',[(0,5.10,-4.5),(side*4.5,3.1,-4.5),(side*4.5,3.1,4.5),(0,5.10,4.5)],[(0,1,2,3)],wood,roof)
snow_roof(roof)
for x in [-2.55,2.55]:
 box('Window frame',(x,1.88,4.10),(1.20,1.25,.16),wood,front)
 box('Window glass',(x,1.88,4.20),(.97,.98,.025),glass,front)
 for dx in [-.5,0,.5]:box('Window mullion',(x+dx,1.88,4.235),(.045,1.05,.045),wood,front,.005)
 box('Window sill',(x,1.24,4.22),(1.34,.12,.38),floor,front)
 box('Sill snow',(x,1.33,4.24),(1.34,.09,.31),snow,front)
for x in [-.98,.98]:box('Door jamb',(x,1.25,4.12),(.15,2.5,.23),wood,front)
for i in range(8):box('Porch plank',(0,-.028,4.18+i*.22),(2.65,.06,.21),floor,frame,.007)
for x in [-1.35,1.35]:
 for z in [4.2,5.65]:box('Porch post',(x,.66,z),(.14,1.36,.14),wood,frame)
 box('Porch rail',(x,1.04,4.9),(.12,.12,1.55),wood,frame)
lantern((1.31,2.1,4.26),front)
for dx in range(4):
 for yy in range(4-dx//2):log((4.3+dx*.22,.15+yy*.20,1.3),(4.3+dx*.22,.15+yy*.20,2.2),.095,frame)
box('Woodrack cover',(4.65,1.15,1.8),(1.1,.13,1.4),snow,frame)
# Furnished interior leaves a clear central approach to the door and back of the cabin.
for x in [-3.25,-2.15]:
 for z in [2.20,2.80]:box('Workbench leg',(x,.39,z),(.10,.78,.10),wood,inside)
box('Workbench top',(-2.7,.83,2.5),(1.48,.13,.83),floor,inside)
box('Repair fabric',(-2.99,.925,2.45),(.45,.055,.33),canvas,inside)
beam('Hammer handle',(-2.66,.929,2.40),(-2.27,.929,2.60),.028,cutwood,inside)
box('Hammer head',(-2.27,.955,2.60),(.13,.075,.24),iron,inside)
for z in [.2,.7,1.2]:
 beam('Wall hook',(-3.90,2.25,z),(-3.66,2.25,z),.025,iron,inside)
box('Hanging coat',(-3.77,1.58,.7),(.17,1.05,.46),canvas,inside,.075)
for z in [.37,1.03]:beam('Coat sleeve',(-3.76,1.96,z),(-3.73,1.34,z),.085,canvas,inside)
beam('Tool handle',(-3.77,.58,1.2),(-3.77,2.06,1.2),.031,cutwood,inside)
box('Shovel blade',(-3.76,.51,1.2),(.075,.34,.23),iron,inside,.025)
for x in [-3.02,-1.78]:
 for z in [-3.12,-1.35]:box('Bed leg',(x,.22,z),(.11,.44,.11),wood,inside)
box('Bed frame',(-2.4,.36,-2.22),(1.5,.18,2.2),wood,inside)
box('Mattress',(-2.4,.51,-2.22),(1.39,.18,2.05),wool,inside,.065)
box('Pillow',(-2.4,.64,-2.94),(1.12,.20,.43),paper,inside,.07)
for i in range(6):box('Blanket folds',(-2.4,.624,-2.45+i*.19),(1.4,.045,.10),canvas,inside,.014)
bed_upgrade=group('UpgradeBed',root);box('Extra wool quilt',(-2.4,.665,-1.81),(1.43,.09,1.1),wool,bed_upgrade,.05)
storage=group('StorageChest',root);chest((2.4,0,2.4),storage)
repair=group('WindowRepairs',root)
for x in [-2.55,2.55]:
 for y in [1.50,1.84,2.17]:box('Window repair boards',(x,y,4.30),(1.36,.22,.07),floor,repair)
for x in [-3.0,-1.85]:
 for z in [-1.43,-.58]:box('Radio desk leg',(x,.38,z),(.085,.76,.085),wood,inside)
box('Radio desk',(-2.43,.80,-1),(1.45,.10,1.0),floor,inside)
box('Radio case',(-2.4,1.03,-1.1),(.72,.36,.34),dark,inside)
box('Radio dial',(-2.45,1.04,-.915),(.29,.12,.025),glass,inside)
for x in [-2.68,-2.19]:beam('Radio knob',(x,.96,-.90),(x,.96,-.85),.033,iron,inside)
beam('Antenna',(-2.69,1.21,-1.12),(-2.69,1.69,-1.12),.011,iron,inside)
for y in [.68,1.34,1.99]:
 box('Shelf board',(.30,y,-3.68),(2.18,.10,.43),floor,inside)
 for x in [-.43,.12,.65,1.1]:
  beam('Jar',(x,y+.08,-3.66),(x,y+.27,-3.66),.09,paper if x<.5 else canvas,inside,10)
  beam('Jar lid',(x,y+.27,-3.66),(x,y+.31,-3.66),.095,iron,inside,10)
for x in [-.72,1.4]:box('Shelf uprights',(x,1.15,-3.76),(.075,2.4,.08),wood,inside)
for x in [.68,1.76]:
 for z in [.94,1.94]:box('Table leg',(x,.34,z),(.09,.68,.09),wood,inside)
box('Writing table',(1.22,.72,1.44),(1.45,.10,1.35),floor,inside)
box('Map on table',(1.14,.779,1.40),(.64,.006,.51),paper,inside,.002);lantern((1.65,.98,1.55),inside)
beam('Stove body',(2.6,.15,-2),(2.6,1.10,-2),.40,iron,inside,12)
beam('Stove rim',(2.6,1.08,-2),(2.6,1.17,-2),.44,iron,inside,12)
box('FireWindow',(2.6,.66,-1.60),(.34,.36,.028),fire,inside,.025)
for x in [2.34,2.86]:beam('Stove legs',(x,.02,-2),(x,.20,-2),.05,iron,inside)
beam('StovepipeInside',(2.6,1.18,-2),(2.6,3.2,-2),.13,iron,inside,12)
beam('StovepipeRoof',(2.6,3.2,-2),(2.6,4.5,-2),.13,iron,roof,12)
beam('Chimney cap',(2.6,4.50,-2),(2.6,4.63,-2),.23,iron,roof,12)
for i in range(4):log((3.2,.12+i*.14,-1),(3.8,.12+i*.14,-1),.075,inside)
box('Woven rug',(0,.012,.05),(1.72,.016,1.35),wool,inside,.008)
for x in [-.76,.76]:box('Rug trim',(x,.024,.05),(.028,.008,1.28),rope,inside,.001)
export(root,'cabin')

root=start('ForestryBridge');frame=group('BridgeTimbers',root)
for x in [-1.7,1.7]:box('Longitudinal girder',(x,-.28,0),(.25,.42,18.5),wood,frame)
for i in range(48):box('Deck plank',(0,.03,-8.81+i*.375),(4.7,.14,.353),floor,frame,.012)
for z in [-7.5,-3.75,0,3.75,7.5]:
 box('Cross beam',(0,-.44,z),(5.3,.30,.30),wood,frame)
 for x in [-2.2,2.2]:
  box('Trestle post',(x,-1.27,z),(.25,2.8,.25),wood,frame)
  box('Railing post',(x,.65,z),(.18,1.4,.18),wood,frame)
  bolts((x,-.42,z+.18),frame)
  for sx in [-1,1]:ellipsoid('Pier stone',(x+sx*.13,-2.45,z),(.29,.25,.34),stone,frame)
 for a,b in [((-2.2,-2.2,z),(2.2,-.5,z)),((2.2,-2.2,z),(-2.2,-.5,z))]:beam('Cross brace',a,b,.11,wood,frame,4)
for x in [-2.2,2.2]:
 for y in [.59,1.20]:box('Continuous rail',(x,y,0),(.13,.14,18.4),wood,frame)
 for z in [-6,-2.2,1.7,5.8]:box('Rail snow',(x,1.32,z),(.21,.10,3.4),snow,frame,.03)
export(root,'bridge')

root=start('ForestryCamp');roof=group('CampRoof',root);gear=group('CampGear',root)
for side in [-1,1]:
 verts=[];faces=[];nx=8;nz=14
 for iz in range(nz+1):
  z=-1.9+3.8*iz/nz
  for ix in range(nx+1):
   t=ix/nx;x=side*t*1.75;y=2.22*(1-t)+.13-math.sin(math.pi*t)*.13*(math.sin(math.pi*iz/nz)**2)
   verts.append((x,y,z))
 for iz in range(nz):
  for ix in range(nx):
   a=iz*(nx+1)+ix;faces.append((a,a+1,a+nx+2,a+nx+1) if side>0 else (a+1,a,a+nx+1,a+nx+2))
 canopy=mesh('Sagging canvas',verts,[tuple(reversed(f)) for f in faces],canvas,roof)
 for polygon in canopy.data.polygons:polygon.use_smooth=True
 for z in [-1.85,0,1.85]:beam('Canvas seam',(0,2.36,z),(side*1.75,.14,z),.012,rope,roof,6)
 for z in [-1.75,1.75]:
  beam('Guy line',(side*1.73,.30,z),(side*2.65,.06,z+.3),.012,rope,gear,6)
  beam('Tent peg',(side*2.65,-.06,z+.3),(side*2.71,.22,z+.3),.025,wood,gear,6)
 mesh('Door flap',[(side*.1,2.28,1.93),(side*1.72,.16,1.93),(side*.60,.12,1.96)],[(0,1,2)],patch,roof)
for z in [-2.0,2.0]:
 beam('A frame',(-1.2,0,z),(.2,2.65,z),.065,wood,gear,8)
 beam('A frame',(1.2,0,z),(-.2,2.65,z),.065,wood,gear,8)
beam('Ridge pole',(0,2.38,-2.25),(0,2.38,2.25),.07,wood,gear)
for i in range(5):
 log((-2.15,.12+i*.22,-2.15),(2.15,.12+i*.22,-2.15),.12,gear)
 log((-2.15,.12+i*.22,-2.1),(-2.15,.12+i*.22,1.3),.12,gear)
beam('Wall snow',(-2.15,1.2,-2.15),(2.15,1.2,-2.15),.10,snow,gear)
box('Bedroll',(-.55,.10,-.5),(.95,.16,1.9),wool,gear,.06)
beam('Rolled blanket',(-1.02,.23,-1.26),(-.12,.23,-1.26),.16,wool,gear,12)
for i in range(9):
 a=i*math.tau/9;ellipsoid('Fire ring',(1.1+math.cos(a)*.45,.10,2.65+math.sin(a)*.45),(.18,.13,.15),stone,gear)
for z in [2.52,2.77]:log((.77,.11,z),(1.4,.11,z),.07,gear)
box('FireBed',(1.1,.19,2.65),(.43,.06,.35),fire,gear,.015)
for x in [.55,1.65]:beam('Kettle tripod',(x,0,2.65),(1.1,1.35,2.65),.035,wood,gear)
beam('Kettle hook',(1.1,1.32,2.65),(1.1,.77,2.65),.012,iron,gear)
beam('Kettle',(1.1,.51,2.65),(1.1,.75,2.65),.17,iron,gear,12)
lantern((-.9,.28,1.5),gear)
export(root,'camp')
print('ARCHITECTURE_COMPLETE: cabin, bridge, camp; editable .blend sources')
