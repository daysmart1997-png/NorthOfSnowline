"""Build only the approved mountain-pass/kiosk sample; leave previous exports intact.
Blender --background --python tools/build_mountain_kiosk.py
Coordinates use the project's Godot-to-Blender helpers, without executing old builds.
"""
from pathlib import Path
import numpy as np
ROOT_PATH=Path(__file__).resolve().parents[1]
exec(compile((ROOT_PATH/'tools/build_architecture.py').read_text().split("root=start('ForestryCabin')")[0],'geometry_helpers','exec'))
OUT=ROOT_PATH/'assets/mountain_pass';OUT.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT_PATH/'source_art/mountain_pass';SOURCE.mkdir(parents=True,exist_ok=True)
random.seed(113)

def value_noise(size,cells,seed):
 rng=np.random.default_rng(seed);grid=rng.random((cells+1,cells+1))
 q=np.arange(size)*cells/size;i=q.astype(int);t=q-i;t=t*t*(3-2*t)
 return (grid[i[:,None],i[None,:]]*(1-t[:,None])*(1-t[None,:])+grid[i[:,None]+1,i[None,:]]*t[:,None]*(1-t[None,:])+grid[i[:,None],i[None,:]+1]*(1-t[:,None])*t[None,:]+grid[i[:,None]+1,i[None,:]+1]*t[:,None]*t[None,:])

def png(name,rgb,data=False):
 if rgb.ndim==2:rgb=np.repeat(rgb[:,:,None],3,axis=2)
 size=rgb.shape[0];pixels=np.ones((size,size,4),dtype=np.float32);pixels[:,:,:3]=np.clip(rgb,0,1)
 image=bpy.data.images.new(name,width=size,height=size,alpha=False)
 image.colorspace_settings.name='Non-Color' if data else 'sRGB'
 image.pixels.foreach_set(pixels.ravel());image.filepath_raw=str(OUT/(name+'.png'));image.file_format='PNG';image.save()
 return image

def textured(name,color,kind):
 size=1024;yy,xx=np.mgrid[0:1:complex(size),0:1:complex(size)]
 broad=value_noise(size,4,31);medium=value_noise(size,11,13);fine=value_noise(size,180,62)
 grain=(np.sin(xx*460+np.sin(yy*11+xx*14)*2.5+medium*3)*.5+.5)
 variation=.91+broad*.15+medium*.055
 rgb=np.array(color)[None,None,:]*variation[:,:,None]
 if kind=='wood':
  rgb*=((.955+grain*.055)[:,:,None]);rough=np.clip(.84+medium*.13,0,1);height=grain*.08+fine*.025
 elif kind=='paint':
  # Broad islands of exposed timber, with small broken boundaries instead of stripes.
  chip=np.clip((medium*.65+broad*.35+fine*.045-.66)*14,0,1)
  rgb=rgb*(1-chip[:,:,None])+np.array([.34,.30,.235])[None,None,:]*chip[:,:,None]
  rough=.76+chip*.18+fine*.035;height=chip*.12+fine*.018
 else:
  rust_mask=np.clip((medium*.55+broad*.45-.56)*4,0,1)
  rgb=rgb*(1-rust_mask[:,:,None]*.42)+np.array([.34,.235,.17])[None,None,:]*rust_mask[:,:,None]*.42
  rough=.62+rust_mask*.32;height=medium*.1+fine*.018
 albedo=png(kind+'_color',rgb);r=png(kind+'_roughness',rough,True)
 dy,dx=np.gradient(height);normal=np.dstack((-dx*8,-dy*8,np.ones_like(dx)));normal/=np.linalg.norm(normal,axis=2)[:,:,None]
 normalmap=png(kind+'_normal',normal*.5+.5,True)
 m=mat(name,(1,1,1),.15 if kind=='metal' else 0);nodes=m.node_tree.nodes;links=m.node_tree.links;p=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
 for image,socket in [(albedo,'Base Color'),(r,'Roughness')]:
  tex=nodes.new('ShaderNodeTexImage');tex.image=image;links.new(tex.outputs['Color'],p.inputs[socket])
 tex=nodes.new('ShaderNodeTexImage');tex.image=normalmap;n=nodes.new('ShaderNodeNormalMap');n.inputs['Strength'].default_value=.35;links.new(tex.outputs['Color'],n.inputs['Color']);links.new(n.outputs['Normal'],p.inputs['Normal'])
 return m

paint3=textured('KioskPaint',(.35,.43,.39),'paint')
wood3=textured('KioskWood',(.43,.385,.315),'wood')
metal3=textured('KioskMetal',(.34,.385,.39),'metal')
stone3=mat('KioskStone',(.235,.265,.27));dark3=mat('KioskDark',(.065,.078,.075))

def uv_objects():
 # Project each polygon along its dominant normal, maintaining vertical timber grain.
 for obj in bpy.data.objects:
  if obj.type!='MESH':continue
  uv=obj.data.uv_layers.active or obj.data.uv_layers.new(name='UVMap')
  for face in obj.data.polygons:
   axis=max(range(3),key=lambda a:abs(face.normal[a]))
   axes=[a for a in range(3) if a!=axis]
   for li in face.loop_indices:
    co=obj.data.vertices[obj.data.loops[li].vertex_index].co+obj.location
    uv.data[li].uv=(co[axes[0]]*.18+.5,co[axes[1]]*.18+.5)

def save(root,name):
 uv_objects()
 for image in bpy.data.images:
  if image.source=='FILE' and Path(image.filepath).is_file():
   image.pack();image.filepath='//../../assets/mountain_pass/'+Path(image.filepath).name
 bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(name+'.blend')))
 for parent in [o for o in bpy.data.objects if o.type=='EMPTY']:
  buckets={}
  for o in list(parent.children):
   if o.type=='MESH':buckets.setdefault(o.data.materials[0].name,[]).append(o)
  for key,objects in buckets.items():
   if len(objects)<2:continue
   bpy.ops.object.select_all(action='DESELECT')
   for o in objects:o.select_set(True)
   bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=parent.name+'_'+key
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_animations=False,export_apply=True)
 print('MOUNTAIN_SAMPLE_ASSET',name,flush=True)

root=start('RoadKioskV3');inside=group('Structure',root);front=group('CutawayFront',root);right=group('CutawayRight',root);roof=group('Roof',root)
w=2.3;d=2.8
for i in range(14):box('Real floor boards',(-2.13+i*.327,-.07,0),(.322,.14,5.6),wood3,inside,.005)
# Board joints are actual geometry, while surface grain follows UVs.
for side in [-1,1]:
 parent=inside if side<0 else right
 for j in range(12):
  z=-2.57+j*.465
  for y,h in [(.48,.96),(2.40,.56)]:box('Painted wall panel',(side*w,y,z),(.17,h,.458),paint3,parent,.008)
 for z in [-d,-1.55,0,1.55,d]:box('Window upright',(side*w,1.55,z),(.20,1.25,.12),wood3,parent)
 for y in [1.02,2.09]:box('Wide sill',(side*w,y,0),(.27,.11,5.7),wood3,parent)
 # Broken slats and one boarded window make a cold, abandoned working structure.
 for z in [-2.35,2.2]:
  shutter=box('Old shutter',(side*w,1.52,z),(.19,.92,.7),paint3,parent);shutter.rotation_euler.x=.06*side
 for z in [-.12,.10]:beam('Broken window muntin',(side*w,1.05,z),(side*w,1.46,z+.035),.025,wood3,parent,4)
for i in range(12):box('Rear boards',(-2.10+i*.38,1.32,-d),(.374,2.64,.18),paint3,inside,.007)
for side in [-1,1]:
 for i in range(4):box('Door surround',(side*(.86+i*.40),1.31,d),(.392,2.62,.18),paint3,front,.007)
box('Door header',(0,2.42,d),(1.4,.36,.24),wood3,front)
for x in [-.72,.72]:box('Door jamb',(x,1.17,d),(.13,2.34,.28),wood3,front)
for x in [-w,w]:
 for z in [-d,d]:box('Corner flashing',(x,1.32,z),(.22,2.68,.22),metal3,front if z>0 else inside,.012)
# Full corrugated shed roof; deep, off-centre front canopy changes the silhouette.
verts=[];faces=[];nx=140;nz=8
for j in range(nz+1):
 z=-3.10+j*7.25/nz
 for i in range(nx+1):
  x=-2.64+i*5.52/nx;y=2.94-(z+3.1)*.065+.033*math.sin(i*math.pi/2)
  verts.append((x,y,z))
for j in range(nz):
 for i in range(nx):
  a=j*(nx+1)+i;faces.append((a,a+nx+1,a+nx+2,a+1))
metalroof=mesh('Folded zinc canopy',verts,faces,metal3,roof)
solid=metalroof.modifiers.new('Sheet thickness','SOLIDIFY');solid.thickness=.035;bpy.context.view_layer.objects.active=metalroof;bpy.ops.object.modifier_apply(modifier=solid.name)
for x in [-2.40,2.62]:
 box('Canopy leg',(x,1.15,3.9),(.10,2.3,.10),metal3,front)
 beam('Canopy bracket',(x,1.65,3.9),(x,2.50,3.0),.045,metal3,roof,4)
for z in [-2.9,2.4,3.85]:box('Canopy crossbeam',(.12,2.83-(z+3.1)*.065,z),(5.35,.1,.12),wood3,roof)
# A continuous, thin snow mantle fades toward the exposed front/eastern roof edge.
vs=[];fs=[];sx=30;sz=38
for j in range(sz+1):
 t=j/sz;z=-3.09+t*6.65
 snow_left=-2.58+.10*math.sin(z*2.1)+.06*math.cos(z*4.7)
 snow_right=2.76-.36*t-.15*math.sin(z*1.7)-.12*math.cos(z*3.9)
 for i in range(sx+1):
  u=i/sx;x=snow_left+(snow_right-snow_left)*u
  edge=min(1,u*8,(1-u)*8,t*8,(1-t)*8)
  y=3.005-(z+3.1)*.065+edge*(.09+.023*math.sin(x*2.1+z*.8))
  vs.append((x,y,z+.08*math.sin(x*3)*t*t))
for j in range(sz):
 for i in range(sx):
  a=j*(sx+1)+i;fs.append((a,a+sx+1,a+sx+2,a+1))
snowmesh=mesh('Continuous wind snow mantle',vs,fs,snow,roof)
for face in snowmesh.data.polygons:face.use_smooth=True
mod=snowmesh.modifiers.new('Tapered powder edge','SOLIDIFY');mod.thickness=.04;bpy.context.view_layer.objects.active=snowmesh;bpy.ops.object.modifier_apply(modifier=mod.name)
# Closed side utility cupboard, not a second enterable room.
box('Side utility locker',(2.90,.80,-.45),(1.05,1.60,2.35),metal3,right)
for z in [-1.25,-.88,-.51,-.14,.23,.60]:box('Locker corrugation',(3.45,.8,z),(.04,1.60,.055),metal3,right,.004)
top=box('Locker pitched cover',(2.95,1.73,-.45),(1.35,.10,2.65),metal3,right);top.rotation_euler.y=.08
for x,z in [(-2.0,-2.45),(2,-2.45),(-2,2.45),(2,2.45)]:box('Cut stone foundation',(x,-.22,z),(.65,.42,.66),stone3,inside,.06)
# Preserve the accepted reachable furniture footprints and contact heights.
box('Duty desk',(0,1,-2.2),(2.1,.13,.8),wood3,inside,.035)
for x in [-.85,.85]:box('Desk leg',(x,.47,-2.2),(.11,.94,.58),metal3,inside)
for y in [.38,1.05,1.8]:box('File shelf',(1.7,y,-1.6),(.6,.07,1.5),metal3,inside)
for z in [-2.1,-1.6]:box('Empty file box',(1.7,.62,z),(.48,.35,.30),canvas,inside)
box('Bench',(-1.65,.46,.6),(.58,.12,2),wood3,inside)
for z in [0,1.2]:box('Bench leg',(-1.65,.2,z),(.42,.4,.12),metal3,inside)
box('Route paper',(-.55,1.08,-2.15),(.38,.018,.28),paper,inside)
beam('Empty tin',(.72,1.075,-2.25),(.72,1.22,-2.25),.085,metal3,inside,12)
for z in [-.6,0,.8]:box('Blown snow under broken window',(-2.08,.025,z),(.25,.04,.48),snow,inside,.025)
save(root,'road_kiosk_v3')

# Authored asymmetric background ridge, outside the walkable terrain boundary.
root=start('MountainRidge');rockmat=mat('PassRock',(.20,.255,.29))
for index,(cx,cz,h,rx,rz) in enumerate([(-39,153,27,20,18),(-62,128,38,24,21),(-72,91,30,23,26)]):
 parent=group('RidgePeak_'+str(index),root);vs=[];fs=[];nx=28;nz=28
 for j in range(nz+1):
  z=-rz+j*rz*2/nz
  for i in range(nx+1):
   x=-rx+i*rx*2/nx;r=math.sqrt((x/rx)**2+(z/rz)**2)
   angle=math.atan2(z,x);shape=max(0,1-r*(1+.14*math.sin(angle*3+index)+.08*math.cos(angle*7)))
   y=h*shape**1.4*(.90+.10*math.sin(x*.31+z*.13))
   vs.append((cx+x,y-.55,cz+z))
 for j in range(nz):
  for i in range(nx):
   a=j*(nx+1)+i;fs.extend([(a,a+nx+1,a+1),(a+1,a+nx+1,a+nx+2)])
 mesh('Layered rock and snow ridge',vs,fs,rockmat,parent)
save(root,'mountain_ridge')
# A few interlocking bedrock ribs interrupt the near shoulder's smooth silhouette.
root=start('CliffRibs');parent=group('Rock',root)
for i,(x,y,z,w,h,d) in enumerate([(-.6,1.2,0,1.5,2.4,1.6),(.65,.8,.5,1.3,1.6,1.4),(-.15,2.8,-.6,1.6,1.4,1.1)]):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=v((x,y,z)))
 crag=bpy.context.object;finish(crag,'Weather fractured bedrock',rockmat,parent)
 for vertex in crag.data.vertices:
  co=vertex.co.copy();warp=1+.10*math.sin(co.x*9+i)+.065*math.sin(co.y*11+co.z*5)
  vertex.co=Vector((co.x*w*.73*warp,co.y*d*.72*warp,co.z*h*.65*warp))
 crag.data.update()
save(root,'cliff_ribs')
print('MOUNTAIN_KIOSK_ASSETS_OK',flush=True)
