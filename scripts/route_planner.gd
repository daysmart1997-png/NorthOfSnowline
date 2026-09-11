extends RefCounted
# Planning reads a cloned Expedition. It never reserves items or alters the clock.
const Survival=preload("res://scripts/expedition.gd")
const DayCycle=preload("res://scripts/day_cycle.gd")
const PATHS={
 "direct":[Vector2(0,-166),Vector2(0,-100),Vector2(0,-74),Vector2(0,8),Vector2(-6,8),Vector2(-6,27),Vector2(0,27),Vector2(0,21)],
 "sheltered":[Vector2(0,-166),Vector2(6,-153),Vector2(22,-138),Vector2(22,-102),Vector2(0,-100),Vector2(0,-74),Vector2(18,-72),Vector2(22,-40),Vector2(22,-24),Vector2(12,-24),Vector2(0,-14),Vector2(0,8),Vector2(-6,8),Vector2(-6,27),Vector2(0,27),Vector2(0,21)],
 "ridge":[Vector2(0,-166),Vector2(0,-100),Vector2(0,-74),Vector2(0,-30),Vector2(-18,-28),Vector2(-31,-33.3),Vector2(-18,-28),Vector2(0,-14),Vector2(0,8),Vector2(-6,8),Vector2(-6,27),Vector2(0,27),Vector2(0,21)]
}

static func forecast(state,route:String,world)->Dictionary:
 if not PATHS.has(route):return {}
 var s=Survival.new()
 if not s.restore(state.data()):return {}
 var initial_temperature:float=s.temperature;var initial_thirst:float=s.thirst
 var initial_health:float=s.health;var initial_time:float=s.elapsed
 var at:Vector2=PATHS[route][0];var distance:=0.0;var sheltered_seconds:=0.0;var ticks:=0
 for destination in PATHS[route].slice(1):
  while at.distance_to(destination)>.01 and ticks<1800 and s.health>0:
   var direction:Vector2=at.direction_to(destination)
   var position:=Vector3(at.x,world.terrain_height(at.x,at.y)+.24,at.y)
   var speed:float=maxf(.2,1.65*s.speed_factor()*world.travel_factor(position,Vector3(direction.x,0,direction.y)))
   var dt:float=minf(1.0,at.distance_to(destination)/speed)
   var shelter:String=world.shelter_at(position)
   var protected:bool=world.windbreak_at(position)
   if protected:sheltered_seconds+=dt
   s.tick(dt,shelter,protected,false)
   var step:float=speed*dt;at+=direction*step;distance+=step;ticks+=1
 var duration:float=s.elapsed-initial_time
 return {"minutes":ceili(duration),"arrival":DayCycle.clock_text(s.elapsed),"temperature_loss":roundi(maxf(0,initial_temperature-s.temperature)),"water_loss":roundi(initial_thirst-s.thirst),"temperature":s.temperature,"thirst":s.thirst,"health_loss":maxf(0,initial_health-s.health),"distance":distance,"protected_seconds":sheltered_seconds,"unsafe":s.health<initial_health or s.temperature<20 or s.thirst<15,"finished":at.distance_to(PATHS[route][-1])<.1}

static func line(name:String,p:Dictionary)->String:
 if p.is_empty():return name+" · 暂无估算"
 return "%s · 约 %d小时%02d分 · 体温 -%d / 水分 -%d%s"%[name,p.minutes/60,p.minutes%60,p.temperature_loss,p.water_loss," · 需先补给" if p.unsafe else ""]
