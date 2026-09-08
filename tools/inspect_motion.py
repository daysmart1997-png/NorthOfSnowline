import bpy, os, json
from pathlib import Path
root=Path(__file__).resolve().parents[1].as_posix()
bpy.ops.wm.open_mainfile(filepath=root+'/source_art/ranger.blend')
before=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=root+'/source_art/mesh2motion/human-base-animations.glb')
rig=next(o for o in bpy.data.objects if o not in before and o.type=='ARMATURE')
print('SOURCE_RIG',rig.name,rig.matrix_world)
for n in ['root','pelvis','spine_01','spine_03','head','upperarm_l','lowerarm_l','thigh_l','calf_l','foot_l']:
 b=rig.data.bones[n]; print(n,tuple(round(x,3) for x in b.head_local),tuple(round(x,3) for x in b.tail_local))
print('ACTIONS',[(a.name,tuple(a.frame_range),[(s.identifier) for s in a.slots]) for a in bpy.data.actions if a.name in ['Idle_A','Walk','Sprint','Crouch_Idle','Crouch_Walk','PickUp_Table','Interact','Walk.001']])
