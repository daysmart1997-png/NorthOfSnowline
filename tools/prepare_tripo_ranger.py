"""Adapt the supplied Tripo rig without overwriting earlier characters.

Blender --background --python tools/prepare_tripo_ranger.py
Inputs: rigged-original.glb and ranger_equipment.blend. Only writes the
tripo_ranger/ranger.blend source and assets/characters/ranger_tripo.glb.
"""
import json
import math
from pathlib import Path
import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'source_art/tripo_ranger'
REPORT = ROOT / 'artifacts/tripo-ranger'
REPORT.mkdir(parents=True, exist_ok=True)
# Sample the existing, locally authored/CC0-derived eight clips first.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'source_art/ranger_equipment.blend'))
old = bpy.data.objects['RangerRig']
scene = bpy.context.scene
fps = scene.render.fps
old_rest = {b.name: b.matrix_local.copy() for b in old.data.bones}
clips = {}
for action in list(bpy.data.actions):
    if not action.name.startswith('Ranger_'):
        continue
    old.animation_data.action = action
    old.animation_data.action_slot = action.slots[0]
    first, last = map(int, action.frame_range)
    samples = []
    for frame in range(first, last + 1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        samples.append({b.name: b.matrix.copy() for b in old.pose.bones})
    clips[action.name] = samples
assert len(clips) == 8
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(OUT / 'rigged-original.glb'))
scene = bpy.context.scene
scene.render.fps = fps
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
mesh = next(o for o in scene.objects if o.type == 'MESH' and o.vertex_groups)
# glTF importer creates a bone-display Icosphere. It is not character geometry.
for obj in list(bpy.data.objects):
    if obj not in [rig, mesh]:
        bpy.data.objects.remove(obj, do_unlink=True)
rig.name = 'RangerRig'
mesh.name = 'TripoRangerClothing'
height = max(v.co.z for v in mesh.data.vertices) - min(v.co.z for v in mesh.data.vertices)
base_z = min(v.co.z for v in mesh.data.vertices)
center = rig.data.bones['Hip'].head_local.copy()
# Blender +Y forward, +Z up; Godot receives -Z forward and +Y up.
transform = Matrix.Scale(1.88 / height, 4) @ Matrix.Rotation(math.pi / 2, 4, 'Z') @ Matrix.Translation((-center.x, -center.y, -base_z))
mesh.data.transform(transform)
rig.data.transform(transform)
name_map = {'Hip': 'hips', 'Spine01': 'spine', 'Head': 'head'}
for src, dst in [('L', 'R'), ('R', 'L')]:
    for a, b in [('Thigh','thigh'),('Calf','shin'),('Foot','foot'),('Upperarm','upper_arm'),('Forearm','forearm')]:
        name_map[src+'_'+a] = b+'.'+dst
for source, target in name_map.items():
    rig.data.bones[source].name = target
    # Renaming the bone may already propagate to vertex groups.
    if source in mesh.vertex_groups:
        mesh.vertex_groups[source].name = target
# Correct the auto-rigger's near-sole ankle placement. Keep the supplied rest
# mesh/UV unchanged; rest-pose edits rebind through the exported inverse binds.
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for side, sign in [('L',1),('R',-1)]:
    thigh = rig.data.edit_bones['thigh.'+side]
    shin = rig.data.edit_bones['shin.'+side]
    foot = rig.data.edit_bones['foot.'+side]
    thigh.head = (sign*.110, 0, .89)
    thigh.tail = (sign*.145, .025, .50)
    shin.head = thigh.tail
    shin.tail = (sign*.180, 0, .16)
    foot.head = shin.tail
    foot.tail = (sign*.180, .16, .12)
    # Toe helper follows as part of a stiff hiking boot, no toe articulation.
    for child in foot.children:
        child.head = foot.tail
        child.tail = foot.tail + Vector((0,.07,0))
bpy.ops.object.mode_set(mode='OBJECT')
rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}
for p in rig.pose.bones:
    p.rotation_mode = 'QUATERNION'
    p.custom_shape = None
# Keep the original atlas. 2048 is sufficient at the fixed game camera; the
# untouched source GLB retains the original texture for later close-up work.
material = mesh.data.materials[0]
tex_node = next(n for n in material.node_tree.nodes if n.type == 'TEX_IMAGE')
image = tex_node.image
original_size = list(image.size)
if max(image.size) > 2048:
    factor = 2048 / max(image.size)
    image.scale(round(image.size[0]*factor), round(image.size[1]*factor))
image.name = 'Ranger_Tripo_Atlas'
image.pack()
# Material surfaces keep the same atlas and UVs. The runtime tint shader
# affects cloth while protecting orange scarf, skin and hardware pixels.
mesh.data.materials.clear()
slots = ['detail','head','torso','hands','legs','feet','pack']
for slot in slots:
    mat = material.copy()
    mat.name = 'Tripo_Detail' if slot == 'detail' else 'Gear_'+slot+'_Tripo'
    mesh.data.materials.append(mat)
counts = {s:0 for s in slots}
for polygon in mesh.data.polygons:
    c = sum((mesh.data.vertices[i].co for i in polygon.vertices), Vector()) / len(polygon.vertices)
    groups = {}
    for index in polygon.vertices:
        for group in mesh.data.vertices[index].groups:
            name = mesh.vertex_groups[group.group].name
            groups[name] = groups.get(name, 0) + group.weight
    # Back-mounted bag/bedroll keep their weight on the torso, never legs.
    if c.y < -.16 and .66 < c.z < 1.60:
        slot = 'pack'
    elif c.z > 1.71:
        slot = 'head'
    elif c.z > 1.48 and abs(c.x) < .20:
        slot = 'detail'
    elif c.z < .285:
        slot = 'feet'
    elif c.z < .925 and abs(c.x) < .29:
        slot = 'legs'
    elif any('Hand' in k and v > 1.0 for k,v in groups.items()):
        slot = 'hands'
    else:
        slot = 'torso'
    polygon.material_index = slots.index(slot)
    counts[slot] += 1
# Avoid a backpack stretching between hip and shoulders during crouching.
pack_vertices = {i for p in mesh.data.polygons if slots[p.material_index]=='pack' for i in p.vertices}
for group in mesh.vertex_groups:
    group.remove(list(pack_vertices))
mesh.vertex_groups['spine'].add(list(pack_vertices), 1.0, 'REPLACE')
# Automatic twist helpers remain bound; exported weights are normalized by
# Blender/glTF. Audit all vertices before animation/export.
for v in mesh.data.vertices:
    assert sum(g.weight for g in v.groups) > .99, f'Unweighted vertex {v.index}'
rig.animation_data_create()
order = sorted(rig.pose.bones, key=lambda p: len(p.parent_recursive))
report = {'height': 1.88, 'bones': len(rest), 'atlas_source': original_size,
          'atlas_runtime': list(image.size), 'surfaces': counts, 'clips': {}}
for clip_name, samples in clips.items():
    action = bpy.data.actions.new(clip_name)
    rig.animation_data.action = action
    clip = clip_name.removeprefix('Ranger_')
    moving = clip in ['Walk','Run','CrouchWalk']
    crouch = clip.startswith('Crouch')
    run = clip == 'Run'
    gait = clip in ['Idle','Walk','Run','CrouchIdle','CrouchWalk']
    duty = .43 if run else (.64 if crouch else .60)
    duration = .60 if run else (1.25 if crouch else .80)
    speed = 3.8 if run else (.85 if crouch else 1.65)
    stride = speed * duration * duty / 2
    for index, sample in enumerate(samples):
        frame = index + 1
        scene.frame_set(frame)
        for p in rig.pose.bones:
            p.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
        for p in order:
            if p.name not in old_rest:
                continue
            source = sample[p.name]
            delta = source.to_quaternion() @ old_rest[p.name].to_quaternion().inverted()
            # Bring the export A-pose arms toward the existing relaxed pose.
            correction = Quaternion()
            if p.name.startswith(('upper_arm','forearm')):
                src_dir = old_rest[p.name].to_3x3() @ Vector((0,1,0))
                dst_dir = rest[p.name].to_3x3() @ Vector((0,1,0))
                correction = dst_dir.rotation_difference(src_dir)
            q = delta @ correction @ rest[p.name].to_quaternion()
            at = (p.parent.matrix @ rest[p.parent.name].inverted() @ rest[p.name]).translation if p.parent else rest[p.name].translation
            if p.name == 'hips':
                at = rest[p.name].translation + source.translation - old_rest[p.name].translation
            p.matrix = Matrix.LocRotScale(at, q, Vector((1,1,1)))
            bpy.context.view_layer.update()
        if gait:
            t = index / (len(samples)-1)
            wave = math.sin(t*math.tau) if moving else 0
            pelvis = .62 if crouch else (.79 if run else .82)
            if moving:
                pelvis += (.022 if run else .006)*(1-math.cos(t*math.tau*2))
            hips = rig.pose.bones['hips']
            q = Quaternion(Vector((0,0,1)), math.radians(3 if run else 1.4)*wave) @ Quaternion(Vector((1,0,0)), -.045 if run else 0)
            hips.matrix = Matrix.LocRotScale(Vector((wave*.007,0,pelvis)), q @ rest['hips'].to_quaternion(), Vector((1,1,1)))
            bpy.context.view_layer.update()
            for side, sign in [('L',1),('R',-1)]:
                phase = (t + (0 if side=='L' else .5))%1
                y = pitch = lift = 0.0
                if moving:
                    if phase < duty:
                        u = phase/duty
                        y = stride*(1-2*u)
                        pitch = math.radians(9)*max(0,1-u/.18)**2-math.radians(12)*max(0,(u-.77)/.23)**2
                    else:
                        u = (phase-duty)/(1-duty)
                        y = -stride+2*stride*u*u*(3-2*u)
                        lift = (.21 if run else (.065 if crouch else .085))*math.sin(math.pi*u)**2
                        pitch = math.radians(-12+21*u)
                thigh, shin, foot = ('thigh.'+side,'shin.'+side,'foot.'+side)
                hip = (hips.matrix @ rest['hips'].inverted() @ rest[thigh]).translation
                roll = Quaternion(Vector((1,0,0)), pitch)
                corner = min((roll @ Vector((0,v,-.16))).z for v in [-.105,.22])
                ankle = Vector((sign*.180,y,.012-corner+lift))
                l1 = (rest[shin].translation-rest[thigh].translation).length
                l2 = (rest[foot].translation-rest[shin].translation).length
                axis = (ankle-hip).normalized()
                distance = min((ankle-hip).length,l1+l2-.001)
                ankle = hip+axis*distance
                bend = Vector((0,1,0));bend=(bend-axis*bend.dot(axis)).normalized()
                along = (l1*l1-l2*l2+distance*distance)/(2*distance)
                knee = hip+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
                for name,a,b in [(thigh,hip,knee),(shin,knee,ankle)]:
                    bone = rig.data.bones[name]
                    q=(bone.tail_local-bone.head_local).normalized().rotation_difference((b-a).normalized()) @ rest[name].to_quaternion()
                    rig.pose.bones[name].matrix=Matrix.LocRotScale(a,q,Vector((1,1,1)))
                    bpy.context.view_layer.update()
                rig.pose.bones[foot].matrix=Matrix.LocRotScale(ankle,roll@rest[foot].to_quaternion(),Vector((1,1,1)))
                bpy.context.view_layer.update()
        for p in rig.pose.bones:
            p.keyframe_insert('location', frame=frame)
            p.keyframe_insert('rotation_quaternion', frame=frame)
    track=rig.animation_data.nla_tracks.new();track.name=clip_name
    track.strips.new(clip_name,1,action);track.mute=True
    rig.animation_data.action=None
    report['clips'][clip]=len(samples)
for p in rig.pose.bones:
    p.matrix_basis=Matrix.Identity(4)
scene.frame_set(1)
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ranger.blend'))
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True);mesh.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/characters/ranger_tripo.glb'),
    export_format='GLB',use_selection=True,export_animations=True,
    export_animation_mode='NLA_TRACKS',export_anim_slide_to_zero=True,
    export_image_format='JPEG',export_jpeg_quality=92)
(REPORT/'adaptation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('TRIPO_RANGER_OK',json.dumps(report))
