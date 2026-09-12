extends RefCounted
# Compact former service lanes. Authored once for terrain and physical wayfinding.
const LANES=[
 [Vector2(-11,78),Vector2(-11,83),Vector2(-2,85),Vector2(10,85),Vector2(10,82)],
 [Vector2(-11,83),Vector2(-16,88),Vector2(-23,92),Vector2(-23,90)],
 [Vector2(10,85),Vector2(17,85),Vector2(17,65),Vector2(12,65),Vector2(12,62)]
]
const MARKERS=[Vector2(-6,84.8),Vector2(8,86.3),Vector2(-18,90.5),Vector2(18.3,67)]
static func distance_to_lane(x:float,z:float)->float:
 if x< -28 or x>22 or z<58 or z>97:return INF
 var p:=Vector2(x,z);var nearest:=INF
 for lane in LANES:
  for i in range(lane.size()-1):
   var a:Vector2=lane[i];var b:Vector2=lane[i+1];var v:=b-a
   var t:=clampf((p-a).dot(v)/v.length_squared(),0,1)
   nearest=minf(nearest,p.distance_to(a+v*t))
 return nearest
static func snow_depth(x:float,z:float,original:float)->float:
 var d:=distance_to_lane(x,z)
 if d>3.0:return original
 # Snow-filled shallow ruts and soft shoulders, not a painted line above terrain.
 var packed:=.065+.009*sin(x*.6+z*.31)
 return lerpf(original,packed,1.0-smoothstep(.65,1.7,d))+.045*exp(-pow((d-1.9)/.48,2))
