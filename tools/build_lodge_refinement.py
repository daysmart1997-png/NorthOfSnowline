"""Build only the charcoal lodge v3; existing assets are never regenerated.
Blender --background --python tools/build_lodge_refinement.py
"""
from pathlib import Path
import ast
import numpy as np
ROOT_PATH=Path(__file__).resolve().parents[1]
exec(compile((ROOT_PATH/'tools/build_architecture.py').read_text().split("root=start('ForestryCabin')")[0],'geometry_helpers','exec'))
# Reuse pure texture functions, never execute the kiosk builder's scene or writes.
tree=ast.parse((ROOT_PATH/'tools/build_mountain_kiosk.py').read_text())
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['value_noise','png','textured']],type_ignores=[]),'texture_helpers','exec'))
OUT=ROOT_PATH/'assets/lodge_refinement';OUT.mkdir(exist_ok=True)
SOURCE=ROOT_PATH/'source_art/lodge_refinement';SOURCE.mkdir(exist_ok=True)
random.seed(9211)
timber=textured('LodgeTimber',(.32,.285,.235),'wood')
metal=textured('LodgeIron',(.145,.17,.18),'metal')
end=mat('LodgeEndgrain',(.13,.105,.075));joints=mat('LodgeChinking',(.21,.225,.205));slate=mat('LodgeStone',(.08,.10,.11));cloth=mat('LodgeCanvas',(.31,.34,.30));blanket=mat('LodgeWool',(.39,.37,.31));linen=mat('LodgeLinen',(.52,.51,.43))
# Quiet woven relief: high roughness, tiny thread normal, no oversized stripes.
size=512;yy,xx=np.mgrid[0:1:complex(size),0:1:complex(size)]
weave=png('canvas_normal',np.dstack((.5+.025*np.sin(xx*math.tau*190),.5+.025*np.sin(yy*math.tau*190),np.ones_like(xx))),True)
for material in [cloth,blanket,linen]:
 p=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED');p.inputs['Roughness'].default_value=.96
 tex=material.node_tree.nodes.new('ShaderNodeTexImage');tex.image=weave
 normal=material.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.18
 material.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color']);material.node_tree.links.new(normal.outputs['Normal'],p.inputs['Normal'])
root=start('CharcoalLodgeV3');inside=group('Structure',root);front=group('CutawayFront',root);right=group('CutawayRight',root);roof=group('Roof',root)
w=3.7;d=3.2

def timber_log(name,a,b,r,parent):
 obj=beam(name,a,b,r,timber,parent,10)
 for poly in obj.data.polygons:poly.use_smooth=len(poly.vertices)==4
 direction=(Vector(b)-Vector(a)).normalized()
 for tip,sign in [(a,-1),(b,1)]:
  p=Vector(tip)+direction*.012*sign;q=p+direction*.009*sign
  beam('Exposed endgrain',p,q,r*.87,end,parent,10)
 return obj

for i in range(22):box('Uneven floorboard',(-3.53+i*.337,-.075,0),(.33,.15,6.4),timber,inside,.006)
# Small windows keep this sleeping shelter sheltered, unlike the kiosk's broad gaps.
for row in range(10):
 y=.15+row*.245;r=.143+(row%3-1)*.004
 for x in [-w,w]:
  parent=inside if x<0 else right
  intervals=[(-d-.15,d+.15)] if row not in [5,6,7] else [(-d-.15,-.8),(.65,d+.15)]
  for a,b in intervals:timber_log('Side wall course',(x,y,a),(x,y,b),r,parent)
 timber_log('Rear course',(-w-.17,y,-d),(w+.17,y,-d),r,inside)
 for side in [-1,1]:
  a,b=sorted([side*.76,side*(w+.15)])
  intervals=[(a,b)] if side>0 or row not in [5,6,7] else [(a,-2.95),(-1.55,b)]
  for aa,bb in intervals:timber_log('Front door course',(aa,y,d),(bb,y,d),r,front)
 if row>=9:timber_log('Door lintel',(-.78,y,d),(.78,y,d),r,front)
for side in [-1,1]:
 parent=inside if side<0 else right
 for z in [-.83,.68]:box('Window frame',(side*(w+.035),1.62,z),(.32,.85,.10),end,parent)
 for y in [1.17,2.04]:box('Deep sill',(side*(w+.035),y,-.075),(.36,.10,1.7),timber,parent)
 box('Window mullion',(side*(w+.04),1.62,-.075),(.16,.80,.047),metal,parent,.003)
 # Closed lower shutter slats leave an honest opening; no permanent warm emissive glass.
 for z in [.26,.42,.58]:box('Weathered shutter',(side*(w+.16),1.60,z),(.075,.75,.15),timber,parent,.006)
for x in [-3.0,-1.5]:box('Front window jamb',(x,1.6,d+.07),(.10,.88,.27),end,front)
for y in [1.17,2.04]:box('Front window sill',(-2.25,y,d+.07),(1.65,.10,.30),timber,front)
box('Front window mullion',(-2.25,1.61,d+.07),(.045,.8,.08),metal,front,.003)
for x in [-.72,.72]:box('Door jamb',(x,1.15,d+.03),(.16,2.3,.35),end,front)
# Low broad pitched roof, visible timber gables and non-repeating snow edge.
eave=2.55;ridge=3.65;length=7.2;half=4.05
for z in [-d,d]:
 mesh('Closed gable',[(-w,2.46,z),(w,2.46,z),(0,ridge,z)],[(0,1,2)],timber,roof)
 for side in [-1,1]:timber_log('Gable rafter',(0,ridge,z),(side*half,eave,z),.10,roof)
for side in [-1,1]:
 for i in range(19):
  z=-3.42+i*.38
  beam('Roof plank',(0,ridge-.04,z),(side*half,eave-.04,z),.17,timber,roof,4)
 verts=[];faces=[];nx=16;nz=36
 for iz in range(nz+1):
  z=-length/2+length*iz/nz
  edge=half-.03+.055*math.sin(z*2.4)+.045*math.cos(z*4.9)
  for ix in range(nx+1):
   t=ix/nx;x=side*t*edge
   y=ridge+(eave-ridge)*abs(x)/half+.24+.035*math.sin(z*1.8+t*4)*(t*.7+.3)
   verts.append((x,y,z))
 for iz in range(nz):
  for ix in range(nx):
   a=iz*(nx+1)+ix;f=(a,a+1,a+nx+2,a+nx+1);faces.append(f if side<0 else tuple(reversed(f)))
 mantle=mesh('Continuous roof snow',verts,faces,snow,roof)
 for p in mantle.data.polygons:p.use_smooth=True
 mod=mantle.modifiers.new('Thin snow edge','SOLIDIFY');mod.thickness=.09;bpy.context.view_layer.objects.active=mantle;bpy.ops.object.modifier_apply(modifier=mod.name)
# Foundation courses are individual irregular stones, grounded below the existing floor.
for z in [-d,d]:
 for i in range(15):
  if z>0 and abs(-3.5+i*.5)<.7:continue
  ellipsoid('Foundation',(-3.5+i*.5,-.15,z),(.29,.22,.25),slate,front if z>0 else inside)
for x in [-w,w]:
 for i in range(12):ellipsoid('Side foundation',(x,-.15,-2.95+i*.54),(.24,.22,.30),slate,right if x>0 else inside)
# Side lean-to contains tools, not unlimited decorative fuel. It is outside the room bounds.
shed=group('SideShelter',right)
for x in [4.2,5.4]:
 for z in [-3.05,.25]:box('Lean-to post',(x,1.08,z),(.14,2.16,.14),timber,shed)
for i in range(9):
 z=-3.0+i*.39
 plank=box('Lean-to roof',(4.65,2.20,z),(2.05,.10,.385),timber,shed);plank.rotation_euler.y=.14
 cap=box('Lean-to snow',(4.65,2.29,z),(2.02,.09,.38),snow,shed,.035);cap.rotation_euler.y=.14
beam('Cross brace',(5.4,.22,-3.05),(5.4,2.03,.25),.05,timber,shed,4)
# Restrained traces of its former use, no labels or resource-looking stacks.
for x in [4.25,4.85]:
 beam('Empty iron tub',(x,.03,-2.5),(x,.52,-2.5),.24,metal,shed,12)
 beam('Tub dark opening',(x,.525,-2.5),(x,.532,-2.5),.205,dark,shed,12)
beam('Shovel handle',(5.1,.18,-.6),(5.0,1.65,-.9),.035,timber,shed)
box('Shovel blade',(5.1,.17,-.6),(.28,.34,.045),metal,shed,.025)
# Sleeping bay: lowered slatted divider, sagging canvas rather than full tall slab.
for z in [-2.3,-.18]:box('Alcove upright',(-1.45,.72,z),(.11,1.44,.11),timber,inside)
for y in [.22,1.35]:box('Alcove rail',(-1.45,y,-1.24),(.10,.10,2.2),timber,inside)
verts=[];faces=[]
for i in range(17):
 z=-2.27+i*2.04/16
 for y in [.35,1.23]:verts.append((-1.45+.025*math.sin(i*1.8),y-.08*math.sin(i*math.pi/16),z))
for i in range(16):faces.append((i*2,i*2+1,i*2+3,i*2+2))
curtain=mesh('Canvas privacy screen',verts,faces,cloth,inside)
mod=curtain.modifiers.new('Canvas thickness','SOLIDIFY');mod.thickness=.012;bpy.context.view_layer.objects.active=curtain;bpy.ops.object.modifier_apply(modifier=mod.name)
box('Low bed',(-2.55,.27,-1.05),(1.35,.26,2.15),timber,inside)
for x in [-3.08,-2.02]:
 for z in [-1.95,-.15]:box('Bed foot',(x,.16,z),(.11,.32,.11),timber,inside)
box('Mattress',(-2.55,.46,-1.05),(1.28,.17,2.08),cloth,inside,.065)
verts=[];faces=[]
for iz in range(25):
 z=-1.7+iz*1.66/24
 for ix in range(17):
  x=-3.27+ix*1.44/16;over=max(0,abs(x+2.55)-.53)
  y=.56-over*1.15+.021*math.sin(z*9+x*4)+.012*math.cos(x*16-z*3)
  verts.append((x,y,z))
for iz in range(24):
 for ix in range(16):
  a=iz*17+ix;faces.append((a,a+17,a+18,a+1))
cover=mesh('Draped blanket',verts,faces,blanket,inside)
for poly in cover.data.polygons:poly.use_smooth=True
box('Pillow',(-2.55,.61,-1.9),(.91,.18,.40),linen,inside,.09)
# Existing hearth and interaction coordinates retained; add working stove details.
box('Hearth',(2.35,.04,-1.9),(1.25,.08,1.25),slate,inside)
beam('Iron stove',(2.35,.15,-1.9),(2.35,1.02,-1.9),.4,metal,inside,16)
for y in [.18,.97]:beam('Stove rim',(2.35,y,-1.9),(2.35,y+.055,-1.9),.42,metal,inside,16)
box('Stove door frame',(2.35,.62,-1.49),(.4,.43,.065),metal,inside)
box('FireWindow',(2.35,.62,-1.445),(.28,.29,.025),fire,inside,.006)
box('Door latch',(2.59,.61,-1.435),(.09,.045,.06),metal,inside)
beam('Stove pipe',(2.35,1.03,-1.9),(2.35,2.7,-1.9),.13,metal,inside,12)
beam('Chimney',(2.35,2.7,-1.9),(2.35,4.15,-1.9),.13,metal,roof,12)
beam('Rain cap',(2.35,4.13,-1.9),(2.35,4.22,-1.9),.24,metal,roof,12)
for x in [2.20,2.50]:beam('Drying rail mount',(x,1.45,-2.3),(x,1.45,-2.75),.022,metal,inside)
beam('Drying rail',(2.15,1.45,-2.3),(2.55,1.45,-2.3),.025,metal,inside)
# Packing table has an accessible lower fuel shelf, clear top and thin legs.
for i in range(4):box('Table top board',(1.5,.82,1.0+i*.2),(1.65,.13,.195),timber,inside,.007)
for x in [.82,2.18]:
 for z in [1.02,1.58]:box('Table leg',(x,.39,z),(.11,.78,.11),timber,inside)
box('Fuel shelf',(1.5,.23,1.3),(1.58,.08,.7),timber,inside)
for x in [-.85,.8]:box('Wall cupboard upright',(x,1.12,-2.9),(.09,2.12,.45),timber,inside)
for y in [.2,.9,1.6,2.15]:box('Cupboard shelf',(-.02,y,-2.9),(1.8,.1,.5),timber,inside)
box('Stove instruction',(.23,1.68,-2.82),(.38,.025,.24),paper,inside)
# Correct object transforms before assigning UVs, for grain following each log's axis.
for obj in list(bpy.data.objects):
 if obj.type!='MESH':continue
 uv=obj.data.uv_layers.active or obj.data.uv_layers.new(name='UVMap')
 for face in obj.data.polygons:
  axis=max(range(3),key=lambda a:abs(face.normal[a]));axes=[a for a in range(3) if a!=axis]
  for li in face.loop_indices:
   co=obj.data.vertices[obj.data.loops[li].vertex_index].co
   uv.data[li].uv=(co[axes[0]]*.4+.13,co[axes[1]]*.4+.27)
for image in bpy.data.images:
 if image.source=='FILE' and Path(image.filepath).is_file():
  image.pack();image.filepath='//../../assets/lodge_refinement/'+Path(image.filepath).name
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'charcoal_lodge_v3.blend'))
for parent in [o for o in bpy.data.objects if o.type=='EMPTY']:
 buckets={}
 for o in list(parent.children):
  if o.type=='MESH' and o.name!='FireWindow':buckets.setdefault(o.data.materials[0].name,[]).append(o)
 for key,objects in buckets.items():
  if len(objects)<2:continue
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:o.select_set(True)
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=parent.name+'_'+key
bpy.ops.export_scene.gltf(filepath=str(OUT/'charcoal_lodge_v3.glb'),export_format='GLB',export_animations=False,export_apply=True)
print('LODGE_ASSET_OK',flush=True)
