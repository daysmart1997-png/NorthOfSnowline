extends RefCounted
# Serializable equipment instances and body conditions. Expedition owns this object.
const GEAR={
 "cap":{"name":"橙色毛线帽","slot":"head","warmth":8,"wind":2,"weight":.2,"color":"b76b39"},
 "coat":{"name":"旧棉衣","slot":"torso","warmth":18,"wind":8,"weight":1.4,"color":"283e58"},
 "gloves":{"name":"旧手套","slot":"hands","warmth":5,"wind":2,"weight":.2,"color":"364451"},
 "trousers":{"name":"棉裤","slot":"legs","warmth":10,"wind":4,"weight":.7,"color":"293b50"},
 "boots":{"name":"旧雪靴","slot":"feet","warmth":9,"wind":4,"weight":1.1,"color":"353e43"},
 "pack":{"name":"帆布行囊","slot":"pack","warmth":0,"wind":0,"weight":1.4,"color":"637064"},
 "wool_cap":{"name":"双层羊毛帽","slot":"head","warmth":12,"wind":3,"weight":.3,"color":"765a48"},
 "wind_coat":{"name":"巡林防风外套","slot":"torso","warmth":24,"wind":17,"weight":2.1,"color":"666c50"},
 "dry_gloves":{"name":"厚毛手套","slot":"hands","warmth":9,"wind":4,"weight":.3,"color":"89745c"},
 "lined_boots":{"name":"加衬雪靴","slot":"feet","warmth":15,"wind":6,"weight":1.3,"color":"6e5441"},
 "hide_coat":{"name":"皮革加衬外套","slot":"torso","warmth":29,"wind":19,"weight":2.8,"color":"79654e"}}
const SLOTS={"head":"头部","torso":"躯干","hands":"双手","legs":"双腿","feet":"双脚","pack":"背包"}
const CONDITIONS={"chill":"受寒","sprain":"扭伤","wound":"伤口","stomach":"食物不适","cough":"呼吸道刺激"}
var owned:Dictionary={}
var equipped:Dictionary={}
var conditions:Dictionary={}
var serial:=0
var wildlife:Dictionary={}
var weapon:="knife"
var meat_age:=0.0
var route_stage:=0
var module_ready:=false
var arrows:Array=[]
var flights:Array=[]

func _init()->void:
 for id in ["cap","coat","gloves","trousers","boots","pack"]:
  var instance:=acquire(id);equipped[GEAR[id].slot]=instance

func acquire(id:String)->String:
 if not GEAR.has(id):return ""
 serial+=1
 var key:="garment_%d"%serial
 owned[key]={"type":id,"wet":0.0,"condition":100.0}
 return key

func weight()->float:
 var total:=0.0
 for g in owned.values():total+=float(GEAR[g.type].weight)
 return total

func warmth()->float:
 var total:=0.0
 for key in equipped.values():
  var g:Dictionary=owned[key]
  total+=float(GEAR[g.type].warmth)*(.45+.55*float(g.condition)/100.0)*(1-.65*float(g.wet)/100.0)
 return total

func windproof()->float:
 var total:=0.0
 for key in equipped.values():
  var g:Dictionary=owned[key];total+=float(GEAR[g.type].wind)*float(g.condition)/100.0
 return clampf(total/90.0,0,.65)

func wear(key:String)->String:
 if not owned.has(key):return "找不到这件衣物。"
 equipped[GEAR[owned[key].type].slot]=key
 return "已换上%s，旧衣已收进行装。"%GEAR[owned[key].type].name

func salvage(s,key:String)->String:
 if not owned.has(key) or key in equipped.values():return "先换下这件衣物，才能拆解。"
 if s.weight()-float(GEAR[owned[key].type].weight)+.2>s.MAX_WEIGHT:return "背包余量不足。"
 owned.erase(key);s.items.cloth=s.count("cloth")+1
 return "旧衣已拆成布料 ×1，负重已减轻。"

func add_condition(kind:String,part:String,severity:float)->void:
 if not CONDITIONS.has(kind) or not SLOTS.has(part):return
 var key:=kind+":"+part
 var old:Dictionary=conditions.get(key,{"kind":kind,"part":part,"severity":0.0,"treated":false})
 old.severity=clampf(float(old.severity)+severity,0,100);old.treated=false;conditions[key]=old

func has_condition(kind:String)->bool:
 for c in conditions.values():
  if c.kind==kind:return true
 return false

func tick(s,delta:float,shelter:String)->void:
 var hot:bool=not shelter.is_empty() and float(s.fires.get(shelter,0))>0
 if s.temperature<22 and not has_condition("chill"):add_condition("chill","torso",20)
 for key in conditions.keys():
  var c:Dictionary=conditions[key]
  if c.kind=="wound" and not c.treated:s.health=maxf(0,s.health-delta*.035*float(c.severity)/25.0)
  if c.kind=="stomach":s.thirst=maxf(0,s.thirst-delta*.018)
  var recovery:=0.0
  if c.kind=="chill" and hot:recovery=.12
  elif c.kind=="cough" and not shelter.is_empty():recovery=.035
  elif c.treated and not shelter.is_empty():recovery=.022 if c.kind=="sprain" else .045
  c.severity=maxf(0,float(c.severity)-delta*recovery)
  if c.severity<=0:conditions.erase(key)
 if hot:
  for key in owned:owned[key].wet=maxf(0,float(owned[key].wet)-delta*.12)
 if hot and s.hunger>30 and s.thirst>30 and not has_condition("wound"):s.health=minf(100,s.health+delta*.018)
 if s.count("raw_meat")>0:meat_age+=delta
 else:meat_age=0

func exposure(delta:float,depth:float,moving:bool,storm:float)->void:
 if not moving:return
 for slot in equipped:
  var g:Dictionary=owned[equipped[slot]]
  var gain:=depth*.055 if slot=="feet" else (depth*.018 if slot=="legs" else storm*.004)
  g.wet=clampf(float(g.wet)+delta*gain,0,100)

func treatment_problem(s,key:String)->String:
 if not conditions.has(key):return "没有需要处理的状态。"
 var c:Dictionary=conditions[key]
 if c.treated:return "已经处理，保持安全休息即可逐步恢复。"
 if c.kind=="chill":return "靠近燃烧的火炉，换上干衣后逐步回暖。"
 var item:String="splint" if c.kind=="sprain" else ("medicine" if c.kind in ["stomach","cough"] else "bandage")
 return "" if s.count(item)>0 else "需要%s。"%s.ITEMS[item].name

func treat(s,key:String)->String:
 var problem:=treatment_problem(s,key)
 if not problem.is_empty():return problem
 var c:Dictionary=conditions[key]
 var item:String="splint" if c.kind=="sprain" else ("medicine" if c.kind in ["stomach","cough"] else "bandage")
 s.items[item]=s.count(item)-1;c.treated=true
 return "已处理%s，休息时逐步恢复。"%CONDITIONS[c.kind]

func data()->Dictionary:
 return {"owned":owned.duplicate(true),"equipped":equipped.duplicate(),"conditions":conditions.duplicate(true),"serial":serial,"wildlife":wildlife.duplicate(true),"weapon":weapon,"meat_age":meat_age,"route_stage":route_stage,"module_ready":module_ready,"arrows":arrows.duplicate(true),"flights":flights.duplicate(true)}

static func number(value,low:float,high:float)->bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)>=low and float(value)<=high

static func valid(d)->bool:
 if not d is Dictionary:return false
 for key in ["owned","equipped","conditions","wildlife"]:
  if not d.get(key) is Dictionary:return false
 if not number(d.get("serial"),6,10000) or float(d.serial)!=floorf(d.serial):return false
 if d.owned.size()>100 or d.conditions.size()>30 or d.wildlife.size()>20:return false
 if not d.get("weapon") in ["knife","bow","rifle"] or not number(d.get("meat_age"),0,864000):return false
 if not number(d.get("route_stage"),0,6) or float(d.route_stage)!=floorf(d.route_stage) or not d.get("module_ready") is bool:return false
 if not d.get("arrows",[]) is Array or d.get("arrows",[]).size()>64:return false
 for a in d.get("arrows",[]):
  if not a is Array or a.size()!=3:return false
  for v in a:
   if not number(v,-1000,1000):return false
 if not d.get("flights",[]) is Array or d.get("flights",[]).size()>16:return false
 for flight in d.get("flights",[]):
  if not flight is Dictionary or not number(flight.get("age"),0,5):return false
  for key in ["position","velocity"]:
   if not flight.get(key) is Array or flight[key].size()!=3:return false
   for v in flight[key]:
    if not number(v,-1000,1000):return false
 for key in d.owned:
  var g=d.owned[key]
  if not key is String or not key.begins_with("garment_") or not key.trim_prefix("garment_").is_valid_int():return false
  if int(key.trim_prefix("garment_"))<1 or int(key.trim_prefix("garment_"))>d.serial:return false
  if not g is Dictionary or not GEAR.has(g.get("type")) or not number(g.get("wet"),0,100) or not number(g.get("condition"),0,100):return false
 if d.equipped.size()!=6:return false
 for slot in SLOTS:
  if not d.owned.has(d.equipped.get(slot)):return false
  if GEAR[d.owned[d.equipped[slot]].type].slot!=slot:return false
 for key in d.conditions:
  var c=d.conditions[key]
  if not c is Dictionary or not CONDITIONS.has(c.get("kind")) or not SLOTS.has(c.get("part")):return false
  if key!=c.kind+":"+c.part or not number(c.get("severity"),0,100) or not c.get("treated") is bool:return false
 for key in d.wildlife:
  var a=d.wildlife[key]
  if not key in ["deer_0","deer_1","wolf_0","wolf_1","bear_0","carcass_0"] or not a is Dictionary:return false
  if not number(a.get("health"),0,160) or not number(a.get("meat"),0,12) or not number(a.get("hide"),0,2):return false
  if not a.get("position") is Array or a.position.size()!=3:return false
  for v in a.position:
   if not number(v,-1000,1000):return false
 return true

func restore(d:Dictionary)->void:
 owned=d.owned.duplicate(true);equipped=d.equipped.duplicate();conditions=d.conditions.duplicate(true);serial=int(d.serial)
 wildlife=d.wildlife.duplicate(true);weapon=d.weapon;meat_age=float(d.meat_age);route_stage=int(d.route_stage);module_ready=d.module_ready;arrows=d.get("arrows",[]).duplicate(true);flights=d.get("flights",[]).duplicate(true)
