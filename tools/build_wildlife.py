"""Original articulated miniature deer, wolf and bear; no external assets."""
import math
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
(ROOT/'assets/wildlife').mkdir(exist_ok=True)

def mat(name,color):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    n.inputs['Base Color'].default_value=(*color,1);n.inputs['Roughness'].default_value=.95
    return m
def empty(name,at,parent=None):
    o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=at;o.parent=parent;return o
def ell(name,at,scale,material,parent=None):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=at)
    o=bpy.context.object;o.name=name;o.scale=scale;o.data.materials.append(material)
    if parent:o.parent=parent
    return o
def branch(a,b,r,material,parent):
    mid=(Vector(a)+Vector(b))/2;direction=Vector(b)-Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=7,radius1=r,radius2=r*.6,depth=direction.length,location=mid)
    o=bpy.context.object;o.rotation_mode='QUATERNION';o.rotation_quaternion=direction.to_track_quat('Z','Y');o.data.materials.append(material);o.parent=parent

for species in ['deer','wolf','bear']:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    deer=species=='deer';bear=species=='bear'
    fur=mat('Winter_fur',(.25,.20,.15) if deer else ((.12,.10,.085) if bear else (.28,.30,.30)))
    pale=mat('Pale_fur',(.51,.46,.35) if deer else (.45,.46,.43));dark=mat('Hooves_nose',(.045,.048,.05));horn=mat('Antler',(.32,.29,.24))
    torso_z=1.16 if deer else (1.0 if bear else .67)
    root=empty('Animal', (0,0,0));body=empty('Body',(0,0,0),root)
    ell('Ribcage',(0,0,torso_z),(.34 if deer else (.58 if bear else .25),.76 if bear else .61,.42 if bear else .30),fur,body)
    ell('Haunch',(0,-.44,torso_z-.03),(.35 if deer else (.51 if bear else .27),.35,.35),fur,body)
    ell('Shoulders',(0,.36,torso_z),(.35 if deer else (.54 if bear else .33),.40,.41),fur,body)
    head=empty('Head',(0,.48,torso_z+.20),body)
    ell('Neck',(0,.06,.14),(.18 if deer else .30,.22,.35),fur,head)
    ell('Skull',(0,.24,.43 if deer else .14),(.17 if deer else .28,.30,.20),fur,head)
    ell('Muzzle',(0,.49,.35 if deer else .04),(.12 if deer else .17,.23,.12),pale,head)
    ell('Nose',(0,.67,.36 if deer else .05),(.10,.06,.08),dark,head)
    for side in [-1,1]:
        ell('Eye',(side*(.14 if deer else .24),.35,.49 if deer else .21),(.025,.025,.025),dark,head)
        if bear:ell('Ear',(side*.23,.10,.35),(.10,.065,.12),fur,head)
        else:
            branch((side*.14,.13,.57 if deer else .29),(side*.24,.15,.91 if deer else .56),.09,fur,head)
        if deer:
            for a,b in [((side*.11,.17,.64),(side*.20,.12,1.13)),((side*.20,.12,1.13),(side*.39,.07,1.47)),((side*.20,.12,1.13),(side*.36,.35,1.33)),((side*.29,.09,1.30),(side*.48,-.03,1.43))]:branch(a,b,.028,horn,head)
    for i,(x,y) in enumerate([(-1,.38),(1,.38),(-1,-.44),(1,-.44)]):
        hip_z=torso_z-.03;hip_x=x*(.23 if deer else (.37 if bear else .18))
        leg=empty('Leg%d'%i,(hip_x,y,hip_z),body)
        upper=hip_z*.48
        ell('Upper',(0,0,-upper*.5),(.11 if deer else (.19 if bear else .10),.13,upper*.61),fur,leg)
        shin=empty('Shin%d'%i,(0,.03 if i<2 else -.06,-upper),leg)
        ell('Lower',(0,0,-(hip_z-upper)*.45),(.065 if deer else (.13 if bear else .065),.08,(hip_z-upper)*.53),fur,shin)
        ell('Hoof' if deer else 'Paw',(0,.06,-(hip_z-upper)+.075),(.085 if deer else (.17 if bear else .105),.12 if deer else .17,.08),dark,shin)
    tail=ell('Tail',(0,-.77,torso_z-.09),(.10,.10 if deer or bear else .37,.15 if deer else .10),pale if deer else fur,body)
    if not deer and not bear:tail.rotation_euler.x=-.6
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f'source_art/wildlife_{species}.blend'))
    # Join rigid pieces per articulated parent, retaining head and leg pivots.
    parents={o.parent for o in bpy.data.objects if o.type=='MESH'}
    for parent in parents:
        meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==parent]
        bpy.ops.object.select_all(action='DESELECT')
        for o in meshes:o.select_set(True)
        bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join()
    bpy.ops.export_scene.gltf(filepath=str(ROOT/f'assets/wildlife/{species}.glb'),export_format='GLB')
print('WILDLIFE_ASSETS_OK')
