"""Retarget selected CC0 Mesh2Motion clips to our existing ranger; no third-party code execution."""
import bpy, math, os, json
from mathutils import Matrix, Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1].as_posix()
Path(ROOT+'/artifacts').mkdir(exist_ok=True)
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
gait_report={}
def balanced_legs(clip,t):
 moving=clip in ['Walk','Sprint','Crouch_Walk']
 crouch=clip in ['Crouch_Idle','Crouch_Walk'];run=clip=='Sprint'
 pelvis=.58 if crouch else (.73 if run else .77)
 pelvis+=(.026 if run else .009)*(1-math.cos(t*math.tau*2)) if moving else 0
 # Continuous pelvis trajectory: never jump between whichever boot happens to be lowest.
 p=target.pose.bones['hips'];m=p.matrix.copy();m.translation.z=pelvis;p.matrix=m
 bpy.context.view_layer.update()
 heights=[]
 for side in ['L','R']:
  phase=(t+(0 if side=='L' else .5))%1
  duty=.4 if run else (.60 if crouch else .55)
  stride=.43 if run else (.32 if crouch else .36)
  lift=0.0;y=0.0
  if moving:
   if phase<duty:y=stride*(1-2*phase/duty)
   else:
    u=(phase-duty)/(1-duty);ease=u*u*(3-2*u);y=-stride+2*stride*ease
    lift=(.20 if run else (.07 if crouch else .105))*math.sin(math.pi*u)**2
  thigh='thigh.'+side;shin='shin.'+side;foot='foot.'+side
  hip=(p.matrix@rest['hips'].inverted()@rest[thigh]).translation
  ankle=Vector((.155 if side=='L' else -.155,y,.18+lift))
  l1=target.data.bones[thigh].length;l2=target.data.bones[shin].length
  direction=(ankle-hip).normalized();distance=min((ankle-hip).length,l1+l2-.001)
  ankle=hip+direction*distance
  bend=Vector((0,1,0));bend=(bend-direction*bend.dot(direction)).normalized()
  along=(l1*l1-l2*l2+distance*distance)/(2*distance)
  knee=hip+direction*along+bend*math.sqrt(max(0,l1*l1-along*along))
  for name,a,b in [(thigh,hip,knee),(shin,knee,ankle)]:
   r=target.data.bones[name];q=(r.tail_local-r.head_local).normalized().rotation_difference((b-a).normalized())@rest[name].to_quaternion()
   target.pose.bones[name].matrix=Matrix.LocRotScale(a,q,Vector((1,1,1)))
   bpy.context.view_layer.update()
  target.pose.bones[foot].matrix=Matrix.LocRotScale(ankle,rest[foot].to_quaternion(),Vector((1,1,1)))
  bpy.context.view_layer.update()
  heights.append(round(ankle.z-.18,5))
 return pelvis,heights
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
  bpy.context.view_layer.update()
  if upstream in ['Idle_A','Walk','Sprint','Crouch_Idle','Crouch_Walk']:
   pelvis,heights=balanced_legs(upstream,frame/frames)
   gait_report.setdefault(upstream,[]).append({'t':frame/frames,'pelvis':pelvis,'feet':heights})
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
json.dump({'source_url':'https://github.com/Mesh2Motion/mesh2motion-app/tree/main/static/animations','license':'CC0 (upstream README)','retarget':'Mesh2Motion upper-body and interaction adaptation; v04 locomotion legs rebuilt with symmetric analytic IK and continuous pelvis trajectory','clips':records},open(ROOT+'/source_art/mesh2motion/retarget-manifest.json','w'),indent=2)
json.dump(gait_report,open(ROOT+'/artifacts/v04-gait-curves.json','w'),indent=2)
print('RETARGET_COMPLETE',records)
