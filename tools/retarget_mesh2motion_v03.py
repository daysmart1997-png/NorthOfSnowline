"""Retarget selected CC0 Mesh2Motion clips to our existing ranger; no third-party code execution."""
import bpy, math, os, json
from mathutils import Matrix, Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1].as_posix()
bpy.ops.wm.open_mainfile(filepath=ROOT+'/source_art/ranger.blend')
target=bpy.data.objects['RangerRig']; original=set(bpy.data.objects)
target.animation_data_clear()
for a in list(bpy.data.actions): bpy.data.actions.remove(a)
bpy.ops.import_scene.gltf(filepath=ROOT+'/source_art/mesh2motion/human-base-animations.glb')
source=next(o for o in bpy.data.objects if o not in original and o.type=='ARMATURE')
clips={n:bpy.data.actions[n] for n in ['Idle_A','Walk','Sprint','Crouch_Idle','Crouch_Walk','PickUp_Table','Interact','Consume']}
source.animation_data_clear();source.animation_data_create()
scene=bpy.context.scene;scene.render.fps=30
mapping={'hips':'pelvis','spine':'spine_03','head':'head'}
for s in ['L','R']:
 for a,b in [('thigh','thigh'),('shin','calf'),('foot','foot'),('upper_arm','upperarm'),('forearm','lowerarm')]: mapping[a+'.'+s]=b+'_'+s.lower()
turn=Matrix.Rotation(math.pi,4,'Z')
def set_source(action,frame):
 source.animation_data.action=action
 source.animation_data.action_slot=action.slots[0]
 scene.frame_set(int(frame),subframe=frame-int(frame));bpy.context.view_layer.update()
set_source(clips['Idle_A'],0)
reference={n:(turn@source.pose.bones[s].matrix).to_quaternion() for n,s in mapping.items()}
base_z=source.pose.bones['pelvis'].matrix.translation.z
rest={b.name:b.matrix_local.copy() for b in target.data.bones}
ordered=sorted(target.pose.bones,key=lambda b:len(b.parent_recursive))
records=[]
names={'Idle_A':'Idle','Walk':'Walk','Sprint':'Run','Crouch_Idle':'CrouchIdle','Crouch_Walk':'CrouchWalk','PickUp_Table':'Pickup','Interact':'Interact','Consume':'Consume'}
for upstream,action in clips.items():
 target.animation_data_create();target.animation_data.action=None
 for p in target.pose.bones:p.rotation_mode='QUATERNION';p.matrix_basis=Matrix.Identity(4)
 first,last=action.frame_range;frames=int(math.ceil(last-first))
 for frame in range(frames+1):
  set_source(action,min(first+frame,last))
  for p in ordered:
   src=source.pose.bones[mapping[p.name]]
   q=(turn@src.matrix).to_quaternion()@reference[p.name].inverted()@rest[p.name].to_quaternion()
   if p.parent:
    head=(p.parent.matrix@rest[p.parent.name].inverted()@rest[p.name]).translation
   else:
    head=rest[p.name].translation.copy();head.z+=(source.pose.bones['pelvis'].matrix.translation.z-base_z)*.90
   p.matrix=Matrix.LocRotScale(head,q,Vector((1,1,1)))
  bpy.context.view_layer.update()
  # Ground the supporting boot after transferring between different leg proportions.
  sole=[]
  for s in ['L','R']:
   bn='foot.'+s;xx=.155 if s=='L' else -.155
   for yy in [-.09,.22]:sole.append((target.pose.bones[bn].matrix@rest[bn].inverted()@Vector((xx,yy,.013))).z)
  lift=.013-min(sole)
  hip=target.pose.bones['hips'];m=hip.matrix.copy();m.translation.z+=lift;hip.matrix=m
  for p in target.pose.bones:
   p.keyframe_insert('rotation_quaternion',frame=frame+1)
   p.keyframe_insert('location',frame=frame+1)
  bpy.context.view_layer.update()
 baked=target.animation_data.action;baked.name='Ranger_'+names[upstream]
 track=target.animation_data.nla_tracks.new();track.name=baked.name;track.strips.new(baked.name,1,baked);track.mute=True
 target.animation_data.action=None
 records.append({'source':upstream,'exported':baked.name,'frames':frames+1,'fps':30})
for o in list(bpy.data.objects):
 if o not in original:bpy.data.objects.remove(o,do_unlink=True)
for a in list(bpy.data.actions):
 if a in clips.values():bpy.data.actions.remove(a)
for p in target.pose.bones:p.matrix_basis=Matrix.Identity(4)
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/source_art/ranger_motion.blend')
bpy.ops.export_scene.gltf(filepath=ROOT+'/assets/characters/ranger_motion.glb',export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS')
json.dump({'source_url':'https://github.com/Mesh2Motion/mesh2motion-app/tree/main/static/animations','license':'CC0 (upstream README)','retarget':'World-space reference-pose correction, proportion adaptation, supporting-boot grounding','clips':records},open(ROOT+'/source_art/mesh2motion/retarget-manifest.json','w'),indent=2)
print('RETARGET_COMPLETE',records)
