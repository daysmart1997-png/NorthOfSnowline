"""Read a supplied GLB in Blender; emit rest and animation measurements only."""
import bpy, json, sys
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
path=sys.argv[sys.argv.index('--')+1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=path)
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.vertex_groups)
scene=bpy.context.scene
report={'fps':scene.render.fps,'rig':rig.name,'rig_matrix':[list(r) for r in rig.matrix_world], 'mesh_matrix':[list(r) for r in mesh.matrix_world], 'bounds':[list(min(v.co[k] for v in mesh.data.vertices) for k in range(3)),list(max(v.co[k] for v in mesh.data.vertices) for k in range(3))], 'bones':{b.name:{'head':list(b.head_local),'tail':list(b.tail_local),'parent':b.parent.name if b.parent else None} for b in rig.data.bones},'actions':{}}
rig.animation_data_create()
for track in rig.animation_data.nla_tracks:track.mute=True
for action in bpy.data.actions:
 rig.animation_data.action=action;rig.animation_data.action_slot=action.slots[0]
 first,last=action.frame_range
 values=[]
 for i in range(9):
  scene.frame_set(int(first+(last-first)*i/8));bpy.context.view_layer.update()
  values.append({name:list(rig.pose.bones[name].matrix.translation) for name in ['Root','Hip','Head','L_Foot','R_Foot','L_Hand','R_Hand']})
 report['actions'][action.name]={'range':[first,last],'samples':values}
out=root/'artifacts/supplied-motion';out.mkdir(parents=True,exist_ok=True)
(out/'inspection.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('SUPPLIED_INSPECT_OK',json.dumps(report))
