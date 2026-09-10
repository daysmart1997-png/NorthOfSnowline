"""Refine the existing Tripo locomotion; preserves original rigged export.
Blender --background --python tools/refine_tripo_motion.py
"""
import math
from pathlib import Path
import bpy
from mathutils import Matrix,Vector,Quaternion
R=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'source_art/tripo_ranger/ranger.blend'))
rig=bpy.data.objects['RangerRig'];scene=bpy.context.scene
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
ones=Vector((1,1,1))
def place(name,at,direction):
 bone=rig.data.bones[name]
 q=(bone.tail_local-bone.head_local).normalized().rotation_difference(direction.normalized())@rest[name].to_quaternion()
 rig.pose.bones[name].matrix=Matrix.LocRotScale(at,q,ones)
 bpy.context.view_layer.update()
for clip in ['Idle','Walk','Run','CrouchIdle','CrouchWalk']:
 action=bpy.data.actions['Ranger_'+clip]
 rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
 first,last=map(int,action.frame_range);samples=[]
 for frame in range(first,last+1):
  scene.frame_set(frame);bpy.context.view_layer.update()
  samples.append({p.name:p.matrix.copy() for p in rig.pose.bones})
 moving=clip in ['Walk','Run','CrouchWalk'];run=clip=='Run';crouch=clip.startswith('Crouch')
 for index,sample in enumerate(samples):
  frame=first+index;scene.frame_set(frame);t=index/(last-first)
  # Upright loaded stance: retain authored contact trajectories and cycle.
  hip=sample['hips'].copy();hip.translation.z+=.045 if not crouch else .015
  rig.pose.bones['hips'].matrix=hip;bpy.context.view_layer.update()
  spine=rig.pose.bones['spine']
  at=(spine.parent.matrix@rest[spine.parent.name].inverted()@rest['spine']).translation
  lean=.12 if run else (.22 if crouch else .025)
  sway=math.sin(t*math.tau)*(.045 if run else .016) if moving else 0
  q=Quaternion(Vector((0,0,1)),-sway)@Quaternion(Vector((1,0,0)),-lean)
  spine.matrix=Matrix.LocRotScale(at,q@rest['spine'].to_quaternion(),ones);bpy.context.view_layer.update()
  for side,sign in [('L',1),('R',-1)]:
   thigh,shin,foot=('thigh.'+side,'shin.'+side,'foot.'+side)
   h=(hip@rest['hips'].inverted()@rest[thigh]).translation;ankle=sample[foot].translation
   l1=(rest[shin].translation-rest[thigh].translation).length;l2=(rest[foot].translation-rest[shin].translation).length
   axis=(ankle-h).normalized();distance=min((ankle-h).length,l1+l2-.001)
   ankle=h+axis*distance;bend=Vector((0,1,0));bend=(bend-axis*bend.dot(axis)).normalized()
   along=(l1*l1-l2*l2+distance*distance)/(2*distance)
   knee=h+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
   place(thigh,h,knee-h);place(shin,knee,ankle-knee)
   m=sample[foot].copy();m.translation=ankle;rig.pose.bones[foot].matrix=m;bpy.context.view_layer.update()
   # Arms oppose the advancing foot, elbows remain flexed during running.
   swing=-sign*math.cos(t*math.tau)*(.52 if run else (.16 if crouch else .25)) if moving else 0
   arm=rig.pose.bones['upper_arm.'+side]
   shoulder=(arm.parent.matrix@rest[arm.parent.name].inverted()@rest[arm.name]).translation
   direction=Vector((sign*.12,math.sin(swing),-math.cos(swing))).normalized()
   place(arm.name,shoulder,direction)
   elbow=rig.pose.bones['forearm.'+side]
   at=(arm.matrix@rest[arm.name].inverted()@rest[elbow.name]).translation
   angle=swing+(.95 if run else (.48 if crouch else .18))
   place(elbow.name,at,Vector((sign*.05,math.sin(angle),-math.cos(angle))))
  for p in rig.pose.bones:
   p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame)
 rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
scene.frame_set(1);bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(R/'source_art/tripo_ranger/ranger_motion_v2.blend'))
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.data.objects['TripoRangerClothing'].select_set(True)
bpy.ops.export_scene.gltf(filepath=str(R/'assets/characters/ranger_tripo_motion_v2.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_anim_slide_to_zero=True,export_image_format='JPEG',export_jpeg_quality=92)
print('TRIPO_MOTION_V2_OK: source retained, eight clips, coherent locomotion torso and arms')
