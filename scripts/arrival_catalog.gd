extends RefCounted
# Authored locations and supply identities shared by rules, world and map.
const START=Vector3(0,0,130)
const ITEMS=["wood","water","food","cloth","bandage","battery"]
const SITES={
 "gatehouse":{"asset":"road_kiosk","path":"res://assets/mountain_pass/road_kiosk_v3.glb","at":Vector3(12,0,109),"half_width":2.3,"half_depth":2.8,"layer":256,"bed":false,"heat":false,"loss":2.0,"title":"废弃岗亭","description":"破窗漏风，能短暂躲雪；没有火炉与卧铺。","exterior_obstacles":[[Vector3(2.9,.8,-.45),Vector3(1.05,1.6,2.35)],[Vector3(-2.4,1.15,3.9),Vector3(.1,2.3,.1)],[Vector3(2.62,1.15,3.9),Vector3(.1,2.3,.1)]],"obstacles":[[Vector3(0,.5,-2.2),Vector3(2.1,1,.8)],[Vector3(1.7,.9,-1.6),Vector3(.6,1.8,1.5)],[Vector3(-1.65,.25,.6),Vector3(.6,.5,2.0)]]},
 "lodge":{"asset":"charcoal_lodge","path":"res://assets/lodge_refinement/charcoal_lodge_v3.glb","at":Vector3(-11,0,73),"half_width":3.7,"half_depth":3.2,"layer":512,"bed":true,"heat":true,"loss":1.25,"title":"旧炭工木屋","description":"炉子与简陋卧铺尚能使用，燃料有限。补水、休整后再找护林小屋。","exterior_obstacles":[[Vector3(5.4,1.08,-1.4),Vector3(.18,2.16,3.5)],[Vector3(4.2,1.08,-3.05),Vector3(.14,2.16,.14)],[Vector3(4.2,1.08,.25),Vector3(.14,2.16,.14)],[Vector3(4.55,.3,-2.5),Vector3(1.1,.6,.55)]],"obstacles":[[Vector3(-1.45,.72,-1.2),Vector3(.12,1.44,2.3)],[Vector3(-2.55,.45,-1.05),Vector3(1.35,.9,2.15)],[Vector3(2.35,.55,-1.9),Vector3(.85,1.1,.85)],[Vector3(1.5,.43,1.3),Vector3(1.65,.86,.78)],[Vector3(0,1.1,-2.9),Vector3(1.8,2.2,.5)]]}
}
const SUPPLIES={
 "gate_desk":{"site":"gatehouse","at":Vector3(.25,1.12,-2.15),"title":"值班桌上的旧包","contents":{"food":1,"water":1,"cloth":1}},
 "lodge_stores":{"site":"lodge","at":Vector3(1.5,.95,1.3),"title":"桌边的干燥补给","contents":{"wood":3,"bandage":1,"battery":1}}
}
static func room_layer(id:String)->int:
 return int(SITES[id].layer) if SITES.has(id) else ({"home":2,"station":4}.get(id,1))
