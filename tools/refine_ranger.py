"""Targeted, repeatable refinement of ranger_motion.blend; preserves its source.

Run with Blender --background --python tools/refine_ranger.py. Only writes
ranger_refined.blend / .glb; original Mesh2Motion adaptation stays available.
"""
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'source_art/ranger_motion.blend'))
rig = bpy.data.objects['RangerRig']
scene = bpy.context.scene
rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}


def material(name, color):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    node = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Roughness'].default_value = .93
    return mat


navy = material('Wool_Navy', (.038, .068, .11))
hat = material('Wool_Ochre', (.48, .155, .038))
seam = material('Wool_Seam', (.065, .105, .145))
canvas = material('Canvas_Backpack', (.14, .17, .15))
roll_mat = material('Canvas_Bedroll', (.22, .235, .20))
fur = material('Fur', (.23, .235, .205))
leather = material('Leather', (.038, .042, .044))
skin = material('Skin', (.38, .245, .17))
for name in ['Wool cap', 'Cap cuff']:
    obj = bpy.data.objects[name]
    obj.data.materials.clear()
    obj.data.materials.append(hat)
for obj in list(bpy.data.objects):
    # Duplicate coincident buttons existed in the base model.
    if obj.name in ['Fastener.004', 'Fastener.005', 'Fastener.006', 'Fastener.007', 'Hood fur']:
        bpy.data.objects.remove(obj, do_unlink=True)

# Model-space sole contract: 0.205 m wide, 0.328 m long, ankle at z .18.
# Transform authored vertices around each ankle, preserving the rig and weights.
for obj in bpy.data.objects:
    if obj.type != 'MESH' or not obj.name.startswith(('Boot', 'Lace')):
        continue
    center_x = .155 if obj.matrix_world.translation.x > 0 else -.155
    origin = Vector((center_x, 0, .18))
    scale = Vector((.82, .82, .93)) if not obj.name.startswith('Boot cuff') else Vector((.88, .88, 1))
    inverse = obj.matrix_world.inverted()
    for vertex in obj.data.vertices:
        offset = obj.matrix_world @ vertex.co - origin
        vertex.co = inverse @ (origin + Vector(tuple(offset[i] * scale[i] for i in range(3))))


def bind(obj, name, mat, bone='spine'):
    obj.name = name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(mat)
    obj.vertex_groups.new(name=bone).add(list(range(len(obj.data.vertices))), 1, 'REPLACE')
    modifier = obj.modifiers.new('Ranger deformation', 'ARMATURE')
    modifier.object = rig
    obj.parent = rig
    return obj


def box(name, at, size, mat, bone='spine'):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    obj = bpy.context.object
    obj.scale = size
    bind(obj, name, mat, bone)
    bevel = obj.modifiers.new('Soft stitched edges', 'BEVEL')
    bevel.width = .009
    bevel.segments = 2
    bpy.ops.object.modifier_move_up(modifier=bevel.name)
    return obj


bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=.115, depth=.56,
                                  location=(0, -.40, .83), rotation=(0, math.pi / 2, 0))
bind(bpy.context.object, 'Rolled blanket', roll_mat)
for x in [-.18, .18]:
    box('Blanket lash', (x, -.509, .83), (.038, .018, .19), leather)
box('Field radio', (-.285, .235, 1.00), (.12, .09, .19), leather)
box('Radio face', (-.285, .284, 1.03), (.078, .009, .057), seam)
box('Radio antenna', (-.323, .23, 1.17), (.013, .013, .18), leather)

# Broad tailoring remains legible at the game camera: shoulder panels, knee
# reinforcement and pack piping. Avoid tiny facial geometry at this distance.
for side, sign in [('L', 1), ('R', -1)]:
    box('Knee reinforcement', (sign*.155, .100, .47), (.14, .012, .14), seam, 'shin.'+side)
    box('Shoulder storm flap', (sign*.24, .115, 1.375), (.13, .15, .020), seam)
    box('Pack edge binding', (sign*.212, -.433, 1.16), (.020, .023, .37), roll_mat)
for z in [1.13, 1.25]:
    for sign in [-1,1]:
        box('Quilt seam', (sign*.12, .235, z), (.20, .008, .010), seam)

# Rebuild only the locomotion legs. All eight original clip names and all
# original interaction actions remain intact; sampled upper-body local poses
# retain the Mesh2Motion adaptation. Small authored weight transfer replaces the fixed pelvis, without a limp.
report = {}
for clip in ['Idle', 'Walk', 'Run', 'CrouchIdle', 'CrouchWalk']:
    action = bpy.data.actions['Ranger_' + clip]
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]
    first, last = map(int, action.frame_range)
    source_last = last
    # Equal sample counts in both half cycles prevent an odd-length source
    # (25-frame sprint) from rounding one contact differently from the other.
    if (last - first) % 2:
        last += 1
    poses = []
    for frame in range(first, last + 1):
        source_frame = first + (frame - first) * (source_last - first) / (last - first)
        scene.frame_set(int(source_frame), subframe=source_frame % 1)
        bpy.context.view_layer.update()
        poses.append({p.name: p.matrix_basis.copy() for p in rig.pose.bones})
    moving = clip in ['Walk', 'Run', 'CrouchWalk']
    crouch = clip.startswith('Crouch')
    run = clip == 'Run'
    duty = .43 if run else (.64 if crouch else .60)
    duration = .60 if run else (1.25 if crouch else .80)
    speed = 3.8 if run else (.85 if crouch else 1.65)
    stride = speed * duration * duty / 2
    report[clip] = []
    for index, pose in enumerate(poses):
        frame = first + index
        scene.frame_set(frame)
        for name, basis in pose.items():
            rig.pose.bones[name].matrix_basis = basis
        t = index / (last - first)
        pelvis = .59 if crouch else (.76 if run else .79)
        if moving:
            pelvis += (.022 if run else .006) * (1 - math.cos(t * math.tau * 2))
        hips = rig.pose.bones['hips']
        wave = math.sin(t * math.tau) if moving else 0.0
        hip_q = Quaternion(Vector((0, 0, 1)), math.radians(3.0 if run else 1.4)*wave)
        hip_q = hip_q @ Quaternion(Vector((1, 0, 0)), -.045 if run else 0)
        hips.matrix = Matrix.LocRotScale(Vector((wave*.007, 0, pelvis)),
                                         hip_q @ rest['hips'].to_quaternion(), Vector((1, 1, 1)))
        if moving:
            spine = rig.pose.bones['spine']
            spine.rotation_quaternion = Quaternion(Vector((0, 0, 1)), -wave*math.radians(5 if run else 2)) @ spine.rotation_quaternion
            for side, sign in [('L', 1), ('R', -1)]:
                arm = rig.pose.bones['upper_arm.'+side]
                arm.rotation_quaternion = Quaternion(Vector((1, 0, 0)), sign*wave*(.27 if run else .08)) @ arm.rotation_quaternion
                elbow = rig.pose.bones['forearm.'+side]
                elbow.rotation_quaternion = Quaternion(Vector((1, 0, 0)), -.30 if run else -.04) @ elbow.rotation_quaternion
        bpy.context.view_layer.update()
        samples = []
        for side in ['L', 'R']:
            phase = (t + (0 if side == 'L' else .5)) % 1
            lift = y = pitch = 0.0
            if moving:
                if phase < duty:
                    u = phase / duty
                    y = stride * (1 - 2 * u)
                    # Small heel-to-toe roll, flat through mid stance.
                    pitch = math.radians(9) * max(0, 1 - u / .18) ** 2
                    pitch -= math.radians(12) * max(0, (u - .77) / .23) ** 2
                else:
                    u = (phase - duty) / (1 - duty)
                    y = -stride + 2 * stride * u * u * (3 - 2 * u)
                    lift = (.21 if run else (.065 if crouch else .085)) * math.sin(math.pi * u) ** 2
                    pitch = math.radians(-12 + 21 * u)
            thigh, shin, foot = ('thigh.' + side, 'shin.' + side, 'foot.' + side)
            hip = (hips.matrix @ rest['hips'].inverted() @ rest[thigh]).translation
            roll = Quaternion(Vector((1, 0, 0)), pitch)
            # Resized sole: y [-.10988,.21812], bottom z .02376; ankle z .18.
            # Lift the ankle by the lowest rolled corner so boots cannot dig
            # into flat ground during heel strike or toe-off.
            corner = min((roll @ Vector((0, v, -.15624))).z for v in [-.10988, .21812])
            ankle = Vector((.155 if side == 'L' else -.155, y, .011 - corner + lift))
            l1, l2 = rig.data.bones[thigh].length, rig.data.bones[shin].length
            axis = (ankle - hip).normalized()
            distance = min((ankle - hip).length, l1 + l2 - .001)
            ankle = hip + axis * distance
            bend = Vector((0, 1, 0))
            bend = (bend - axis * bend.dot(axis)).normalized()
            along = (l1 * l1 - l2 * l2 + distance * distance) / (2 * distance)
            knee = hip + axis * along + bend * math.sqrt(max(0, l1 * l1 - along * along))
            for name, a, b in [(thigh, hip, knee), (shin, knee, ankle)]:
                bone = rig.data.bones[name]
                q = (bone.tail_local - bone.head_local).normalized().rotation_difference((b - a).normalized()) @ rest[name].to_quaternion()
                rig.pose.bones[name].matrix = Matrix.LocRotScale(a, q, Vector((1, 1, 1)))
                bpy.context.view_layer.update()
            rig.pose.bones[foot].matrix = Matrix.LocRotScale(ankle, roll @ rest[foot].to_quaternion(), Vector((1, 1, 1)))
            bpy.context.view_layer.update()
            samples.append({'ankle': list(ankle), 'sole_min': ankle.z + corner, 'phase': phase})
        for bone in rig.pose.bones:
            bone.keyframe_insert('location', frame=frame)
            bone.keyframe_insert('rotation_quaternion', frame=frame)
        report[clip].append({'t': t, 'pelvis': pelvis, 'feet': samples})
    for track in rig.animation_data.nla_tracks:
        for strip in track.strips:
            if strip.action == action:
                strip.action_frame_end = last
                strip.frame_end = last

rig.animation_data.action = None
for bone in rig.pose.bones:
    bone.matrix_basis = Matrix.Identity(4)
scene.frame_set(1)
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'source_art/ranger_refined.blend'))

# The editable source retains separate clothes/equipment. Merge the exported
# skin into material surfaces, applying bevels but retaining bone weights.
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
for obj in meshes:
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    for modifier in list(obj.modifiers):
        if modifier.type != 'ARMATURE':
            bpy.ops.object.modifier_apply(modifier=modifier.name)
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes:
    obj.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.join()
bpy.context.object.name = 'RangerClothingAndEquipment'
bpy.ops.export_scene.gltf(filepath=str(ROOT / 'assets/characters/ranger_refined.glb'),
                         export_format='GLB', export_animations=True, export_animation_mode='NLA_TRACKS',
                         export_anim_slide_to_zero=True)
output = ROOT / 'artifacts/ranger-finish'
output.mkdir(parents=True, exist_ok=True)
(output / 'authored-gait.json').write_text(json.dumps(report, indent=2), encoding='utf8')
print('RANGER_REFINED_OK: source retained, eight clips, editable clothing, merged weighted export')
