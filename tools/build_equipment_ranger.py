"""Split existing ranger materials by clothing region without rebuilding animation."""
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source_art/ranger_refined.blend'))
materials={}
for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    name = obj.name.lower()
    slot = None
    if any(x in name for x in ['boot', 'lace']): slot='feet'
    elif any(x in name for x in ['glove', 'mitten', 'hand']): slot='hands'
    elif any(x in name for x in ['cap', 'hat']): slot='head'
    elif any(x in name for x in ['thigh', 'shin', 'knee', 'trouser']): slot='legs'
    elif any(x in name for x in ['backpack', 'pack ', 'bedroll', 'blanket']): slot='pack'
    elif any(x in name for x in ['torso', 'coat', 'parka', 'jacket', 'sleeve', 'arm', 'shoulder', 'hood', 'quilt']): slot='torso'
    if slot:
        for material_slot in obj.material_slots:
            if material_slot.material:
                key=(slot,material_slot.material.name)
                if key not in materials:
                    mat=material_slot.material.copy();mat.name='Gear_'+slot+'_'+material_slot.material.name;materials[key]=mat
                material_slot.material=materials[key]
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source_art/ranger_equipment.blend'))
meshes=[o for o in bpy.data.objects if o.type=='MESH']
for o in meshes:
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    for modifier in list(o.modifiers):
        if modifier.type!='ARMATURE':bpy.ops.object.modifier_apply(modifier=modifier.name)
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join()
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/characters/ranger_equipment.glb'),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_anim_slide_to_zero=True)
print('EQUIPMENT_RANGER_OK')
