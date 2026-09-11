extends RefCounted
const Catalog=preload("res://scripts/arrival_catalog.gd")
static func whole(value:Variant,maximum:int)->bool:
 return (value is int or value is float) and is_finite(float(value)) and value>=0 and value<=maximum and float(value)==floorf(float(value))
static func valid(d:Dictionary)->bool:
 if not d.get("arrival_journey",false) is bool:return false
 var taken:Variant=d.get("supply_taken",{})
 if not taken is Dictionary:return false
 for source in taken:
  if not Catalog.SUPPLIES.has(source) or not taken[source] is Dictionary:return false
  for item in taken[source]:
   if not Catalog.SUPPLIES[source].contents.has(item) or not whole(taken[source][item],Catalog.SUPPLIES[source].contents[item]):return false
 var serial:Variant=d.get("placed_serial",0)
 if not whole(serial,1000000):return false
 var entries:Variant=d.get("placed_items",[])
 if not entries is Array or entries.size()>128:return false
 var ids:Array=[]
 for entry in entries:
  if not entry is Dictionary or not whole(entry.get("id"),999999) or entry.id>=serial or ids.has(entry.id) or entry.get("item") not in Catalog.ITEMS:return false
  var p:Variant=entry.get("position")
  if not p is Array or p.size()!=3:return false
  for value in p:
   if not (value is int or value is float) or not is_finite(float(value)):return false
  if absf(p[0])>91 or p[2]<-212 or p[2]>140 or p[1]<-5 or p[1]>16:return false
  ids.append(entry.id)
 return true
static func take_supply(s,source:String,item:String)->String:
 if not Catalog.SUPPLIES.has(source) or not Catalog.SUPPLIES[source].contents.has(item):return "这里没有这件物资。"
 var taken:int=int(s.supply_taken.get(source,{}).get(item,0))
 if taken>=Catalog.SUPPLIES[source].contents[item]:return "这一份已经取走了。"
 if s.weight()+s.ITEMS[item].weight>s.MAX_WEIGHT:return "背包余量不足；可以留在这里，下次再取。"
 if not s.supply_taken.has(source):s.supply_taken[source]={}
 s.supply_taken[source][item]=taken+1;s.items[item]=s.count(item)+1
 return "收好："+s.ITEMS[item].name+" ×1"
static func place(s,item:String,at:Vector3)->String:
 if item not in Catalog.ITEMS or s.count(item)<=0:return "没有可放下的物资。"
 if s.placed_items.size()>=128 or s.placed_serial>=1000000:return "已留下足够多的散放物资，请先收回或使用储物箱。"
 var entry:Dictionary={"id":s.placed_serial,"item":item,"position":[at.x,at.y,at.z]}
 if not valid({"placed_serial":s.placed_serial+1,"placed_items":[entry]}):return "这里无法放置。"
 s.placed_serial+=1;s.placed_items.append(entry);s.items[item]=s.count(item)-1
 return "放下："+s.ITEMS[item].name+" · 可再次拾取"
static func recover(s,key:int)->String:
 for entry in s.placed_items:
  if entry.id!=key:continue
  if s.weight()+s.ITEMS[entry.item].weight>s.MAX_WEIGHT:return "背包余量不足。"
  s.items[entry.item]=s.count(entry.item)+1;s.placed_items.erase(entry)
  return "收回："+s.ITEMS[entry.item].name
 return "物品已经收回。"
