"""Original parked postal van. Writes only its editable source and GLB."""
from pathlib import Path
import math
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def vec(p):
    return Vector((p[0], -p[2], p[1]))

def mat(name, color, metallic=0):
    m = bpy.data.materials.new(name); m.diffuse_color = (*color, 1); m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = .82
    p.inputs['Metallic'].default_value = metallic
    return m

paint = mat('PostalPaint', (.10,.18,.21), .15)
iron = mat('IronOxide', (.075,.09,.10), .4)
rubber = mat('TireRubber', (.026,.031,.033))
glass = mat('FrostedGlass', (.14,.23,.27), .25)
snow = mat('SnowCap', (.62,.69,.74))
trim = mat('PostalCream', (.48,.45,.35))
red = mat('RearReflector', (.34,.065,.035))

def box(name, at, size, material, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=vec(at))
    o=bpy.context.object; o.name=name; o.scale=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(material)
    if bevel:
        m=o.modifiers.new('Soft formed panel', 'BEVEL'); m.width=bevel; m.segments=3
    return o

def mesh(name, vertices, faces, material):
    m=bpy.data.meshes.new(name); m.from_pydata([vec(p) for p in vertices],[],faces); m.update()
    o=bpy.data.objects.new(name,m); bpy.context.collection.objects.link(o); m.materials.append(material)
    return o

box('Chassis',(0,.47,0),(1.64,.26,3.82),iron,.08)
box('Cargo body',(0,1.10,.70),(1.86,1.35,2.40),paint,.14)
box('Cab lower',(0,.77,-1.24),(1.84,.64,1.43),paint,.11)
box('Bonnet',(0,1.06,-1.57),(1.81,.17,.72),paint,.07)
mesh('Tapered cab', [(-.88,1.04,-1.30),(.88,1.04,-1.30),(-.77,1.79,-.95),(.77,1.79,-.95),(-.82,1.79,-.25),(.82,1.79,-.25),(-.92,1.04,-.25),(.92,1.04,-.25)], [(0,1,3,2),(2,3,5,4),(0,2,4,6),(1,7,5,3),(6,4,5,7)],paint)
mesh('Windshield', [(-.73,1.18,-1.239),(.73,1.18,-1.239),(.65,1.70,-.996),(-.65,1.70,-.996)],[(0,1,2,3)],glass)
for side in [-1,1]:
    mesh('Side window', [(side*.879,1.17,-1.13),(side*.802,1.70,-.91),(side*.846,1.70,-.35),(side*.914,1.17,-.35)],[(0,1,2,3)] if side>0 else [(3,2,1,0)],glass)
    box('Cab door seam',(side*.928,.86,-.36),(.012,.50,.017),iron,.004)
    box('Door handle',(side*.949,1.08,-.48),(.035,.035,.16),trim,.009)
    box('Mirror stem',(side*1.00,1.34,-1.08),(.20,.025,.035),iron,.007)
    box('Mirror',(side*1.10,1.37,-1.10),(.10,.20,.085),iron,.028)
    box('Postal stripe',(side*.94,1.16,.70),(.013,.12,2.05),trim,.004)
    box('Sliding door seam',(side*.943,1.03,1.12),(.012,1.12,.015),iron,.003)
    box('Sliding handle',(side*.961,1.27,1.25),(.028,.034,.18),iron,.009)
    for z in [-1.22,1.22]:
        # Curved arch lips frame dark wheel wells; lower body is visually recessed.
        vertices=[];faces=[]
        for i in range(13):
            a=math.pi*i/12
            for r in [.37,.44]:vertices.append((side*.96,.41+math.sin(a)*r,z+math.cos(a)*r))
        for i in range(12):faces.append((i*2,i*2+1,i*2+3,i*2+2))
        mesh('Wheel arch lip',vertices,faces,paint)
        for x, radius, depth, material, name in [(side*.89,.36,.24,rubber,'Winter tire'),(side*1.018,.19,.018,iron,'Wheel hub'),(side*1.03,.08,.02,trim,'Hub cap')]:
            bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=radius,depth=depth,location=vec((x,.36,z)),rotation=(0,math.pi/2,0))
            o=bpy.context.object; o.name=name; o.data.materials.append(material)
        box('Mud flap',(side*.87,.25,z+.40),(.27,.32,.025),rubber,.009)
    box('Headlight',(side*.62,.89,-1.966),(.32,.23,.035),trim,.04)
    box('Rear lamp',(side*.78,.78,1.914),(.15,.25,.030),red,.022)
for z in [-2.02,1.97]:box('Bumper',(0,.53,z),(1.98,.15,.14),iron,.04)
for y in [.71,.77,.83,.89]:box('Grille slat',(0,y,-1.973),(.72,.021,.032),iron,.006)
box('Rear door split',(0,1.17,1.909),(.018,1.06,.018),iron,.004)
for x in [-.42,.42]:box('Rear door inset',(x,1.28,1.918),(.71,.65,.014),paint,.04)
box('Rear handle',(.09,.94,1.942),(.04,.16,.03),trim,.012)
for x in [-.38,.28]:
    w=box('Wiper',(x,1.24,-1.22),(.36,.018,.018),iron,.004); w.rotation_euler.y=.20
# Uneven snow blanket follows the roof; no floating rectangular white slab.
vertices=[];faces=[]
for iz in range(17):
    z=-1.02+2.89*iz/16
    for ix in range(9):
        x=-.87+1.74*ix/8
        y=1.82+.075*(1-(x/.91)**2)+.022*math.sin(z*3+x*4)
        vertices.append((x,y,z))
for iz in range(16):
    for ix in range(8):
        a=iz*9+ix;faces.append((a,a+9,a+10,a+1))
mantle=mesh('Settled roof snow',vertices,faces,snow)
for f in mantle.data.polygons:f.use_smooth=True
box('Bonnet snow',(0,1.16,-1.63),(1.61,.055,.53),snow,.045)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source_art/delivery_van.blend'))
meshes=[o for o in bpy.data.objects if o.type=='MESH']
for o in meshes:
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    for m in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=m.name)
bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join()
bpy.context.object.name='WeatheredPostalVan'
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/architecture/delivery_van.glb'),export_format='GLB',export_animations=False)
print('DELIVERY_VAN_OK: original editable source and merged material surfaces')
