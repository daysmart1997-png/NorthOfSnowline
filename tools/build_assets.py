"""Original modeled ranger and original synthesized cassette loops. Run with Blender -b."""
import bpy, math, random, wave, array, os
from mathutils import Vector
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1].as_posix()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
random.seed(71)

def material(name, color, roughness=.85, metal=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p is None:
        p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
        out=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs[0],out.inputs['Surface'])
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=roughness; p.inputs['Metallic'].default_value=metal
    return m
wool=material('Wool_Navy',(.075,.115,.17)); trim=material('Wool_Seam',(.14,.19,.24))
scarf=material('Wool_Rust',(.48,.15,.065)); leather=material('Leather',(.055,.07,.085))
canvas=material('Canvas_Backpack',(.20,.235,.205)); buckle=material('Brass',(.43,.32,.15),.38,.65)
skin=material('Skin',(.47,.32,.23)); fur=material('Fur',(.49,.48,.40)); dark=material('Dark',(.014,.022,.032))
pieces=[]

def finish(obj,name,mat,bone,smooth=True):
    obj.name=name; obj.data.materials.append(mat)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for p in obj.data.polygons: p.use_smooth=smooth
    pieces.append((obj,bone)); return obj
def ellipsoid(name,at,scale,mat,bone):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,location=at)
    o=bpy.context.object; o.scale=scale
    return finish(o,name,mat,bone)
def cube(name,at,scale,mat,bone,bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at); o=bpy.context.object; o.scale=scale
    finish(o,name,mat,bone)
    mod=o.modifiers.new('Rounded fabric edges','BEVEL'); mod.width=bevel; mod.segments=3
    bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    return o
def segment(name,a,b,radius,mat,bone):
    mid=(Vector(a)+Vector(b))*.5; d=Vector(b)-Vector(a)
    o=ellipsoid(name,mid,(radius,radius,d.length*.62),mat,bone)
    o.rotation_euler=d.to_track_quat('Z','Y').to_euler(); return o
def torus(name,at,major,minor,mat,bone,rotation=(0,0,0),scale=(1,1,1)):
    bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=8,location=at,major_radius=major,minor_radius=minor,rotation=rotation)
    o=bpy.context.object; o.scale=scale; return finish(o,name,mat,bone)

# Coat has a tailored waist, curved shoulder silhouette, skirt and stitched panels.
verts=[]; faces=[]
rings=[(.77,.29,.22),(.86,.32,.23),(1.02,.285,.225),(1.20,.29,.235),(1.36,.335,.235),(1.46,.27,.20)]
for z,rx,ry in rings:
    for k in range(24):
        a=k*math.tau/24; verts.append((math.cos(a)*rx,math.sin(a)*ry,z))
for r in range(len(rings)-1):
    for k in range(24): faces.append((r*24+k,r*24+(k+1)%24,(r+1)*24+(k+1)%24,(r+1)*24+k))
faces.extend([tuple(range(23,-1,-1)),tuple((len(rings)-1)*24+k for k in range(24))])
mesh=bpy.data.meshes.new('TailoredCoat');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('Coat',mesh);bpy.context.collection.objects.link(o);finish(o,'Coat',wool,'spine')
cube('Zipper',(0,.234,1.13),(.022,.018,.53),buckle,'spine',.006)
for s in [-1,1]:
    cube('Pocket',(.18*s,.205,.98),(.19,.08,.17),wool,'spine',.028)
    cube('Pocket flap',(.18*s,.249,1.05),(.19,.024,.035),trim,'spine',.009)
    for z in [.86,1.02,1.18,1.34]:
        ellipsoid('Fastener',(.037,.252,z),(.015,.012,.015),buckle,'spine')
ellipsoid('Head',(0,.02,1.67),(.185,.168,.22),skin,'head')
ellipsoid('Wool cap',(0,-.025,1.80),(.205,.188,.14),wool,'head')
torus('Cap cuff',(0,-.017,1.755),.172,.035,trim,'head',scale=(1,1,.8))
for x in [-.064,.064]: ellipsoid('Eye',(x,.174,1.702),(.012,.012,.012),dark,'head')
ellipsoid('Nose',(0,.187,1.655),(.032,.04,.039),skin,'head')
torus('Scarf',(0,.015,1.492),.213,.065,scarf,'spine',scale=(1,1,.65))
cube('Scarf tail',(.19,.20,1.32),(.12,.055,.32),scarf,'spine',.025)
for i in range(5): segment('Scarf fringe',(.145+i*.022,.205,1.17),(.145+i*.022,.21,1.125),.009,scarf,'spine')
ellipsoid('Hood',(0,-.17,1.42),(.26,.13,.20),wool,'spine')
torus('Hood fur',(0,-.265,1.45),.20,.045,fur,'spine',rotation=(math.pi/2,0,0),scale=(1,1,.75))
cube('Backpack',(0,-.30,1.15),(.46,.27,.55),canvas,'spine',.08)
cube('Backpack flap',(0,-.34,1.41),(.48,.26,.13),canvas,'spine',.06)
cube('Backpack pocket',(0,-.46,1.06),(.28,.07,.23),canvas,'spine',.03)
for s in [-1,1]:
    cube('Pack strap',(s*.16,-.475,1.22),(.04,.016,.32),leather,'spine',.007)
    cube('Pack buckle',(s*.16,-.493,1.17),(.062,.012,.065),buckle,'spine',.01)
    segment('Shoulder strap',(s*.22,.185,1.38),(s*.22,.225,1.03),.025,leather,'spine')
    suffix='.L' if s>0 else '.R'
    segment('Upper sleeve',(s*.32,0,1.40),(s*.41,.005,1.12),.122,wool,'upper_arm'+suffix)
    segment('Fore sleeve',(s*.41,.005,1.12),(s*.43,.045,.94),.108,wool,'forearm'+suffix)
    ellipsoid('Cuff',(s*.43,.045,.96),(.108,.106,.05),trim,'forearm'+suffix)
    ellipsoid('Mitten',(s*.44,.052,.87),(.09,.075,.105),leather,'forearm'+suffix)
    ellipsoid('Thumb',(s*.37,.085,.895),(.046,.045,.067),leather,'forearm'+suffix)
    segment('Trousers',(s*.155,0,.87),(s*.155,.014,.48),.128,wool,'thigh'+suffix)
    segment('Lower trousers',(s*.155,.014,.48),(s*.155,0,.18),.10,wool,'shin'+suffix)
    ellipsoid('Boot',(s*.155,.055,.125),(.125,.205,.122),leather,'foot'+suffix)
    cube('Boot sole',(s*.155,.066,.037),(.25,.40,.05),dark,'foot'+suffix,.028)
    for z in [.20,.25]: torus('Boot cuff',(s*.155,0,z),.095,.018,trim,'shin'+suffix,scale=(1,1,.7))
    for yy in [.045,.095,.145]: cube('Lace',(s*.155,yy,.232-yy*.3),(.12,.012,.009),fur,'foot'+suffix,.003)

# Original simple deform rig. Each articulated garment section is weighted to its bone.
bpy.ops.object.armature_add(enter_editmode=True,location=(0,0,0));rig=bpy.context.object;rig.name='RangerRig'
eb=rig.data.edit_bones;eb.remove(eb[0])
def bone(name,head,tail,parent=None):
    b=eb.new(name);b.head=head;b.tail=tail
    if parent:b.parent=eb[parent]
bone('hips',(0,0,.87),(0,0,1.05))
bone('spine',(0,0,1.05),(0,0,1.45),'hips')
bone('head',(0,0,1.45),(0,0,1.86),'spine')
for s in [-1,1]:
    sf='.L' if s>0 else '.R'
    bone('upper_arm'+sf,(s*.32,0,1.40),(s*.41,.005,1.12),'spine')
    bone('forearm'+sf,(s*.41,.005,1.12),(s*.43,.045,.87),'upper_arm'+sf)
    bone('thigh'+sf,(s*.155,0,.87),(s*.155,.014,.48),'hips')
    bone('shin'+sf,(s*.155,.014,.48),(s*.155,0,.18),'thigh'+sf)
    bone('foot'+sf,(s*.155,0,.18),(s*.155,.22,.10),'shin'+sf)
bpy.ops.object.mode_set(mode='OBJECT')
for o,bn in pieces:
    vg=o.vertex_groups.new(name=bn);vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
    mod=o.modifiers.new('RangerSkin','ARMATURE');mod.object=rig;o.parent=rig
scene=bpy.context.scene;scene.render.fps=30
for name,amplitude,length in [('Idle',0,90),('Walk',.40,36),('Run',.65,24)]:
    rig.animation_data_create();rig.animation_data.action=None
    for frame in range(1,length+2,3):
        t=(frame-1)/length*math.tau
        for p in rig.pose.bones:
            p.rotation_mode='XYZ';p.rotation_euler=(0,0,0);p.location=(0,0,0)
        for s in [-1,1]:
            sf='.L' if s>0 else '.R';swing=math.sin(t+(0 if s>0 else math.pi))*amplitude
            rig.pose.bones['thigh'+sf].rotation_euler.x=swing
            rig.pose.bones['shin'+sf].rotation_euler.x=max(0,-swing)*.85
            rig.pose.bones['upper_arm'+sf].rotation_euler.x=-swing*.65
            rig.pose.bones['forearm'+sf].rotation_euler.x=-.12-abs(swing)*.15
        rig.pose.bones['hips'].location.y=math.sin(t*2)*(.016 if amplitude else .003)
        rig.pose.bones['spine'].rotation_euler.x=math.sin(t)*(.012 if not amplitude else .024)
        for p in rig.pose.bones:
            p.keyframe_insert('rotation_euler',frame=frame)
            p.keyframe_insert('location',frame=frame)
    action=rig.animation_data.action;action.name=name
    track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,action);track.mute=True
    rig.animation_data.action=None
for p in rig.pose.bones:p.rotation_euler=(0,0,0);p.location=(0,0,0)
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'source_art','ranger.blend'))
props=bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
opts=dict(filepath=os.path.join(ROOT,'assets','characters','ranger.glb'),export_format='GLB',export_animations=True)
if 'export_animation_mode' in props:opts['export_animation_mode']='NLA_TRACKS'
bpy.ops.export_scene.gltf(**opts)

# Three 16-second original loops, generated offline without any external music.
rate=22050;seconds=16
def music(name,notes,beat,timbre):
    out=array.array('h');phases=[0.0]*len(notes)
    for i in range(rate*seconds):
        t=i/rate;bar=int(t/beat);a=(t%beat)/beat
        freq=440*2**((notes[bar%len(notes)]-69)/12)
        env=math.sin(math.pi*min(a*5,1)) if a<.2 else math.exp(-3*(a-.2))
        env=max(0,env)
        pad=math.sin(math.tau*freq*.5*t)*.07+math.sin(math.tau*freq*.75*t)*.04
        bell=(math.sin(math.tau*freq*t)+.20*math.sin(math.tau*freq*2.002*t))*env*.15
        flutter=1+.002*math.sin(t*math.tau*3)
        value=(bell+pad)*flutter
        # Seam fades prevent clicks on looping playback.
        value*=min(1,t/.08,(seconds-t)/.25)
        out.append(int(max(-1,min(1,value))*23000))
    with wave.open(os.path.join(ROOT,'assets','audio',name+'.wav'),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(out.tobytes())
music('embers',[57,60,64,67,64,60,55,60],2,'bell')
music('stride',[62,69,66,69,64,71,67,69],.5,'pulse')
music('homeward',[60,64,67,71,67,64,62,59],2,'pad')
print('ASSETS_COMPLETE: ranger.blend, ranger.glb, three original loops')
