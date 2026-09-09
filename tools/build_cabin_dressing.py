"""Build only the original cabin dressing kit; never rebuild existing architecture."""
from pathlib import Path
import math
import random
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
random.seed(731)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    node = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Roughness'].default_value = .95
    return mat

bark = material('WeatheredBark', (.12, .14, .16))
cut = material('OldCutWood', (.29, .235, .17))
snow = material('SnowCap', (.52, .58, .62))

def vec(p):
    return Vector((p[0], -p[2], p[1]))

def parent(name):
    node = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(node)
    return node

def log(root, start, end, r1, r2):
    a, b = vec(start), vec(end)
    direction = b-a
    bpy.ops.mesh.primitive_cone_add(vertices=9, radius1=r1, radius2=r2, depth=direction.length, location=(a+b)/2)
    obj = bpy.context.object
    obj.name = 'Weathered timber'
    obj.rotation_euler = direction.to_track_quat('Z', 'Y').to_euler()
    obj.parent = root
    obj.data.materials.append(bark)
    obj.data.materials.append(cut)
    for face in obj.data.polygons:
        if len(face.vertices) > 4:
            face.material_index = 1
    bevel = obj.modifiers.new('Soft broken edge', 'BEVEL')
    bevel.width = .018
    bevel.segments = 1
    return obj

def snow_patch(root, start, end, width):
    # An open feathered mantle, thinner at the edges; no row of snowballs.
    a, b = Vector(start), Vector(end)
    axis = (b-a).normalized()
    across = Vector((-axis.z, 0, axis.x)).normalized()
    vertices, faces = [], []
    for row in range(9):
        t = row / 8
        center = a.lerp(b,t)
        for col in range(5):
            s = (col-2)/2
            taper = .72+.28*math.sin(t*math.pi)
            p = center + across*s*width*taper
            p.y += .065*(1-s*s)*math.sin(t*math.pi)+.008*math.sin(row*1.8+col)
            vertices.append(vec(p))
    for row in range(8):
        for col in range(4):
            i=row*5+col
            faces.append((i,i+5,i+6,i+1))
    mesh=bpy.data.meshes.new('Feathered mantle');mesh.from_pydata(vertices,[],faces);mesh.update()
    obj=bpy.data.objects.new('Wind settled snow',mesh);bpy.context.collection.objects.link(obj);obj.parent=root;mesh.materials.append(snow)
    for face in mesh.polygons:face.use_smooth=True

fallen=parent('FallenTimber')
log(fallen,(-1.6,.09,0),(1.6,.18,.24),.22,.14)
log(fallen,(-.4,.14,.05),(-.7,.26,-.66),.09,.018)
log(fallen,(.65,.16,.17),(1.15,.31,.74),.075,.012)
snow_patch(fallen,(-1.38,.28,.01),(1.42,.30,.23),.16)

stump=parent('OldStump')
log(stump,(0,-.12,0),(.06,.48,.03),.32,.26)
for i in range(5):
    angle=i*math.tau/5
    log(stump,(math.cos(angle)*.48,-.02,math.sin(angle)*.48),(0,.21,0),.025,.13)
snow_patch(stump,(-.20,.49,0),(.23,.50,.025),.21)

stack=parent('FirewoodStack')
for row,count in [(0,5),(1,4),(2,3)]:
    for i in range(count):
        x=(i-(count-1)/2)*.27
        y=.12+row*.23
        log(stack,(x,y,-.43),(x+.02,y+.01,.45+random.random()*.08),.135,.12)
snow_patch(stack,(-.53,.68,.02),(.55,.68,.02),.44)

source=ROOT/'source_art'/'cabin_dressing.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(source))
output=ROOT/'assets'/'props';output.mkdir(parents=True,exist_ok=True)
for node,name in [(fallen,'fallen_timber'),(stump,'old_stump'),(stack,'firewood_stack')]:
    # Keep individual editable timbers in .blend; batch the runtime geometry
    # into one mesh / three material surfaces to avoid a draw call per log.
    children=[obj for obj in node.children_recursive if obj.type=='MESH']
    for obj in children:
        bpy.context.view_layer.objects.active=obj
        for modifier in list(obj.modifiers):
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in children:obj.select_set(True)
    bpy.context.view_layer.objects.active=children[0]
    bpy.ops.object.join()
    bpy.context.object.name=name+'_batched'
    bpy.ops.object.select_all(action='DESELECT')
    node.select_set(True)
    for child in node.children_recursive:child.select_set(True)
    bpy.context.view_layer.objects.active=node
    bpy.ops.export_scene.gltf(filepath=str(output/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_animations=False)
    print('CABIN_DRESSING',name)
