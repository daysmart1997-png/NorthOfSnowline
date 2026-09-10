"""Preserve supplied Tripo locomotion; retarget five existing secondary clips.
Blender --background --python tools/adapt_supplied_ranger.py
Input source is archived unchanged; only writes the supplied_v3 outputs.
"""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Matrix, Vector, Quaternion
R=Path(__file__).resolve().parents[1]
OUT=R/'source_art/tripo_supplied_v3'
SOURCE=OUT/'original.glb'
scene=bpy.context.scene
bpy.ops.wm.open_mainfile(filepath=str(R/'source_art/tripo_ranger/ranger_motion_v2.blend'))
old=bpy.data.objects['RangerRig'];scene=bpy.context.scene
old_rest={b.name:b.matrix_local.copy() for b in old.data.bones}
secondary={}
for clip in ['CrouchIdle','CrouchWalk','Pickup','Interact','Consume']:
 action=bpy.data.actions['Ranger_'+clip]
 old.animation_data.action=action;old.animation_data.action_slot=action.slots[0]
 first,last=map(int,action.frame_range);samples=[]
 for frame in range(first,last+1):
  scene.frame_set(frame);bpy.context.view_layer.update()
  samples.append({p.name:p.matrix.copy() for p in old.pose.bones})
 secondary[clip]=(samples,(last-first)/scene.render.fps)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
scene=bpy.context.scene;scene.render.fps=24
rig=next(o for o in scene.objects if o.type=='ARMATURE')
mesh=next(o for o in scene.objects if o.type=='MESH' and o.vertex_groups)
for obj in list(bpy.data.objects):
 if obj not in [rig,mesh]:bpy.data.objects.remove(obj,do_unlink=True)
rig.name='RangerRig';mesh.name='TripoRangerClothing'
for track in rig.animation_data.nla_tracks:track.mute=True
source_rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
supplied={}
for action in list(bpy.data.actions):
 clip=next((v for k,v in [('standing_relax','Idle'),('walk','Walk'),('run','Run')] if k in action.name),None)
 if clip is None:continue
 rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
 first,last=map(int,action.frame_range);samples=[]
 for frame in range(first,last+1):
  scene.frame_set(frame);bpy.context.view_layer.update()
  samples.append({p.name:p.matrix.copy() for p in rig.pose.bones})
 supplied[clip]={'samples':samples,'source_name':action.name,'duration':(last-first)/24}
assert set(supplied)=={'Idle','Walk','Run'}
rig.animation_data_clear()
for a in list(bpy.data.actions):bpy.data.actions.remove(a)
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4);p.custom_shape=None
height=max(v.co.z for v in mesh.data.vertices)-min(v.co.z for v in mesh.data.vertices)
base=min(v.co.z for v in mesh.data.vertices);s=1.88/height
center=source_rest['Hip'].translation
T=Matrix.Scale(s,4)@Matrix.Rotation(math.pi/2,4,'Z')@Matrix.Translation((-center.x,-center.y,-base))
mesh.data.transform(T);rig.data.transform(T)
mapping={'Hip':'hips','Spine01':'spine','Head':'head'}
for src,dst in [('L','R'),('R','L')]:
 for a,b in [('Thigh','thigh'),('Calf','shin'),('Foot','foot'),('Upperarm','upper_arm'),('Forearm','forearm')]:mapping[src+'_'+a]=b+'.'+dst
for src,dst in mapping.items():
 rig.data.bones[src].name=dst
 if src in mesh.vertex_groups:mesh.vertex_groups[src].name=dst
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
for p in rig.pose.bones:p.rotation_mode='QUATERNION'
mat=mesh.data.materials[0]
image=next(n.image for n in mat.node_tree.nodes if n.type=='TEX_IMAGE')
source_size=list(image.size)
image.scale(2048,2048);image.name='Ranger_Supplied_Atlas';image.pack()
slots=['detail','head','torso','hands','legs','feet','pack'];mesh.data.materials.clear()
for slot in slots:
 m=mat.copy();m.name='Tripo_Detail' if slot=='detail' else 'Gear_'+slot+'_Tripo';mesh.data.materials.append(m)
counts={slot:0 for slot in slots}
for polygon in mesh.data.polygons:
 c=sum((mesh.data.vertices[i].co for i in polygon.vertices),Vector())/len(polygon.vertices)
 groups={}
 for i in polygon.vertices:
  for g in mesh.data.vertices[i].groups:
   name=mesh.vertex_groups[g.group].name;groups[name]=groups.get(name,0)+g.weight
 if c.y<-.16 and .66<c.z<1.60:slot='pack'
 elif c.z>1.71:slot='head'
 elif c.z>1.48 and abs(c.x)<.20:slot='detail'
 elif c.z<.285:slot='feet'
 elif c.z<.925 and abs(c.x)<.29:slot='legs'
 elif any('Hand' in k and v>1 for k,v in groups.items()):slot='hands'
 else:slot='torso'
 polygon.material_index=slots.index(slot);counts[slot]+=1
# Preserve supplied skin weights and rest bones, including twist helpers.
rig.animation_data_create();order=sorted(rig.pose.bones,key=lambda p:len(p.parent_recursive))
report={'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'height':1.88,'atlas_source':source_size,'atlas_runtime':[2048,2048],'surfaces':counts,'clips':{},'bones':len(rest),'triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons)}

def begin(clip):
 action=bpy.data.actions.new('Ranger_'+clip);rig.animation_data.action=action
 return action

def key(frame):
 for p in rig.pose.bones:
  p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)

def finish(clip,action):
 track=rig.animation_data.nla_tracks.new();track.name='Ranger_'+clip
 track.strips.new('Ranger_'+clip,1,action);track.mute=True;rig.animation_data.action=None

for clip,data in supplied.items():
 frames=data['samples'];total=len(frames)-1
 # Supplied walk and run contain two strides. Retain a complete stride and
 # align phase zero to the left support foot (source R_Foot).
 period=total if clip=='Idle' else total//2
 start=0
 if clip!='Idle':
  heights=[f['R_Foot'].translation.z for f in frames[:period]]
  low=min(heights);high=max(heights);threshold=low+(high-low)*.18
  candidates=[i for i in range(1,period) if heights[i]<=threshold and heights[i-1]>threshold]
  start=candidates[0] if candidates else heights.index(low)
 speed=(frames[-1]['Hip'].translation.x-frames[0]['Hip'].translation.x)*s/data['duration'] if clip!='Idle' else 0
 action=begin(clip);poses=[]
 for index in range(period+1):
  source_index=(start+index)%total if clip!='Idle' else index
  sample=frames[source_index]
  phase=source_index/total
  initial=frames[0]['Hip'].translation
  final=frames[-1]['Hip'].translation
  displacement=Vector((initial.x-center.x,initial.y-center.y,0))
  if clip!='Idle':displacement+=Vector((final.x-initial.x,final.y-initial.y,0))*phase
  desired={}
  for name,matrix in sample.items():
   m=matrix.copy()
   if name!='Root':m.translation-=displacement
   desired[mapping.get(name,name)]=T@m@Matrix.Scale(1/s,4)
  poses.append(desired)
  if clip=='Idle' and index==0:idle_reference={n:m.copy() for n,m in desired.items()}
 # A short seam blend removes export end-frame mismatch without remaking gait.
 seam=min(4,period//8)
 for index,desired in enumerate(poses):
  if index>period-seam:
   t=(index-(period-seam))/seam
   desired={name:m.lerp(poses[0][name],t) for name,m in desired.items()}
  scene.frame_set(index+1)
  for p in order:
   p.matrix=desired[p.name];bpy.context.view_layer.update()
  key(index+1)
 finish(clip,action)
 report['clips'][clip]={'source':data['source_name'],'source_duration':data['duration'],'frames':period+1,'duration':period/24,'phase_start_frame':start,'reference_speed':speed,'seam_frames':seam}

def aim_bone(name,a,b):
 bone=rig.data.bones[name]
 q=(bone.tail_local-bone.head_local).normalized().rotation_difference((b-a).normalized())@rest[name].to_quaternion()
 rig.pose.bones[name].matrix=Matrix.LocRotScale(a,q,Vector((1,1,1)));bpy.context.view_layer.update()

for clip,(samples,duration) in secondary.items():
 action=begin(clip);frames=round(duration*24)
 for i in range(frames+1):
  sample=samples[round(i/frames*(len(samples)-1))];scene.frame_set(i+1)
  for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
  bpy.context.view_layer.update()
  for p in order:
   if p.name not in sample:continue
   delta=sample[p.name].to_quaternion()@old_rest[p.name].to_quaternion().inverted()
   at=(p.parent.matrix@rest[p.parent.name].inverted()@rest[p.name]).translation if p.parent else rest[p.name].translation
   if p.name=='hips':at=rest[p.name].translation+sample[p.name].translation-old_rest[p.name].translation
   p.matrix=Matrix.LocRotScale(at,delta@rest[p.name].to_quaternion(),Vector((1,1,1)));bpy.context.view_layer.update()
  gesture=clip in ['Pickup','Interact','Consume']
  envelope=math.sin(math.pi*i/frames)**2
  if gesture:
   # Secondary gestures start from this model's own relaxed standing pose.
   for p in order:p.matrix=idle_reference[p.name];bpy.context.view_layer.update()
   if clip=='Pickup':
    hip=rig.pose.bones['hips'].matrix.copy();hip.translation.z-=.30*envelope
    rig.pose.bones['hips'].matrix=hip;bpy.context.view_layer.update()
    spine=rig.pose.bones['spine'];m=spine.matrix.copy()
    spine.matrix=Matrix.LocRotScale(m.translation,Quaternion(Vector((1,0,0)),-.55*envelope)@m.to_quaternion(),Vector((1,1,1)))
    bpy.context.view_layer.update()
  # Match the old authored sole trajectories to the supplied ankle heights.
  for side in ['L','R']:
   thigh,shin,foot=('thigh.'+side,'shin.'+side,'foot.'+side)
   h=rig.pose.bones[thigh].matrix.translation.copy()
   ankle=idle_reference[foot].translation.copy() if gesture else sample[foot].translation-old_rest[foot].translation+rest[foot].translation
   l1=(rest[shin].translation-rest[thigh].translation).length;l2=(rest[foot].translation-rest[shin].translation).length
   axis=(ankle-h).normalized();distance=min((ankle-h).length,l1+l2-.001);ankle=h+axis*distance
   bend=Vector((0,1,0));bend=(bend-axis*bend.dot(axis)).normalized()
   along=(l1*l1-l2*l2+distance*distance)/(2*distance)
   knee=h+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
   aim_bone(thigh,h,knee);aim_bone(shin,knee,ankle)
   q=idle_reference[foot].to_quaternion() if gesture else sample[foot].to_quaternion()@old_rest[foot].to_quaternion().inverted()@rest[foot].to_quaternion()
   rig.pose.bones[foot].matrix=Matrix.LocRotScale(ankle,q,Vector((1,1,1)));bpy.context.view_layer.update()
  if gesture:
   for side,sign,hand in [('R',-1,'L_Hand'),('L',1,'R_Hand')]:
    if clip!='Interact' and side=='L':continue
    upper,lower='upper_arm.'+side,'forearm.'+side
    shoulder=rig.pose.bones[upper].matrix.translation.copy()
    neutral=idle_reference[hand].translation
    target=Vector((sign*.17,.36,1.08+.025*math.sin(i/frames*math.tau*2)))
    if clip=='Consume':target=idle_reference['head'].translation+Vector((-.07,.20,-.09))
    if clip=='Pickup':target=Vector((-.17,.42,.47))
    wrist=neutral.lerp(target,envelope)
    l1=(rest[lower].translation-rest[upper].translation).length;l2=(rest[hand].translation-rest[lower].translation).length
    axis=(wrist-shoulder).normalized();distance=min((wrist-shoulder).length,l1+l2-.002);wrist=shoulder+axis*distance
    bend=Vector((sign,.05,-.4));bend=(bend-axis*bend.dot(axis)).normalized()
    along=(l1*l1-l2*l2+distance*distance)/(2*distance)
    elbow=shoulder+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
    aim_bone(upper,shoulder,elbow);aim_bone(lower,elbow,wrist)
  key(i+1)
 finish(clip,action)
 report['clips'][clip]={'source':'supplied idle with authored reach targets' if clip in ['Pickup','Interact','Consume'] else 'local motion_v2 retarget','frames':frames+1,'duration':frames/24}
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
scene.frame_set(1);bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ranger.blend'))
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(R/'assets/characters/ranger_supplied_v3.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_anim_slide_to_zero=True,export_image_format='JPEG',export_jpeg_quality=92)
(OUT/'adaptation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('SUPPLIED_RANGER_OK',json.dumps(report))
