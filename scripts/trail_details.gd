extends Node3D
# Hand-placed evidence belongs to the landscape. Long text lives in the journal.
const Chapter=preload("res://scripts/chapter_one.gd")
const Palette=preload("res://scripts/field_theme.gd")
var world

func build(w)->void:
	world=w;name="TrailEvidence"
	waypost(Vector2(5,-16),false)
	waypost(Vector2(5,-101),true)
	# Muted cloth catches the eye through the trees without naming a building.
	for at in [Vector2(14,-25),Vector2(22,-42),Vector2(24,-53)]:
		var root:=anchor(at,"TrailCloth")
		world.box(Vector3(0,.48,0),Vector3(.07,.96,.06),"524b40",false,root)
		var cloth=world.box(Vector3(.14,.78,.03),Vector3(.30,.12,.018),"987854",false,root)
		cloth.rotation.z=-.16;cloth.rotation.y=.2
	var sled:=anchor(Vector2(-18,-30),"AbandonedSled");sled.rotation.y=-.55
	for x in [-.38,.38]:world.box(Vector3(x,.13,0),Vector3(.09,.09,1.7),"605848",false,sled)
	for z in [-.55,0,.55]:world.box(Vector3(0,.24,z),Vector3(.86,.10,.22),"6c6251",false,sled)
	world.box(Vector3(.08,.42,.1),Vector3(.50,.26,.55),"555b54",false,sled)
	world.box(Vector3(.08,.57,.1),Vector3(.52,.025,.57),"929eaa",false,sled)
	paper(sled,Vector3(-.20,.32,.53))
	var rope:=[Vector2(-18.4,-30.3),Vector2(-19.1,-30.0),Vector2(-19.9,-30.3),Vector2(-20.5,-30.8)]
	for i in range(rope.size()-1):
		var a:=Vector3(rope[i].x,world.terrain_height(rope[i].x,rope[i].y)+.035,rope[i].y)
		var b:=Vector3(rope[i+1].x,world.terrain_height(rope[i+1].x,rope[i+1].y)+.035,rope[i+1].y)
		var strand=world.box((a+b)*.5,Vector3(.035,.025,a.distance_to(b)),"796c53",false,self)
		strand.look_at(b)
	var cache_cloth:=anchor(Vector2(-32,-35),"RidgeCanvas")
	var fold=world.box(Vector3(.46,.28,0),Vector3(.46,.035,.68),"87785d",false,cache_cloth);fold.rotation.z=.8
	var register:=anchor(Vector2(-30.8,-34.5),"WrappedRegister")
	world.box(Vector3(0,.10,0),Vector3(.62,.20,.58),"606b70",false,register)
	world.box(Vector3(0,.215,0),Vector3(.56,.025,.52),"87785d",false,register)
	world.box(Vector3(0,.24,0),Vector3(.30,.04,.32),"696455",false,register)
	paper(register,Vector3(0,.267,0))
	clue("ridge_register",register.position+Vector3(0,.35,0),"收信簿","帆布下的记录")
	# A closed ledger beside the existing radio and a folded dispatch on the module box.
	var lamp=world.box(Vector3(-2.45,1.28,17.103),Vector3(.295,.125,.010),"343e3e",false,self)
	lamp.name="RadioTransmitLamp"
	var home_page:=Node3D.new();home_page.name="DutyLedger";add_child(home_page)
	world.box(Vector3(-2.05,1.11,17.3),Vector3(.30,.04,.36),"645e4e",false,home_page)
	paper(home_page,Vector3(-2.05,1.138,17.3),false)
	var dispatch:=Node3D.new();dispatch.name="StationDispatch";add_child(dispatch)
	paper(dispatch,Vector3(-2.45,1.302,-170.70),false)
	# Keep the paper attached to the module container; pickup removes both.
	for point in world.points:
		if point.id=="radio_parts":dispatch.reparent(point.node,true)
	clue("sled_note",sled.position+Vector3(0,.5,.5),"断绳与雪橇","断绳朝西岭拖去。箱子没在这里；坡上露着一截旧帆布。风很硬，绕过去前先摸摸水壶。")
	var camp_note:=anchor(Vector2(20,-57),"FoldedCampNote")
	world.box(Vector3(0,.15,0),Vector3(.65,.30,.50),"534c42",false,camp_note)
	paper(camp_note,Vector3(0,.31,0))
	clue("hunter_note",camp_note.position+Vector3(0,.35,0),"压在石下的纸页","“柴放在帐棚后。过桥以后，沿林道走；维修间的炉子还好用。别等天黑才往回赶。”末尾的日期被水泡掉了。")

func anchor(at:Vector2,title:String)->Node3D:
	var root:=Node3D.new();root.name=title;root.position=Vector3(at.x,world.terrain_height(at.x,at.y),at.y);add_child(root);return root

func waypost(at:Vector2,north:bool)->void:
	var root:=anchor(at,"WeatheredWaypost");root.rotation.z=.035 if north else -.045
	world.box(Vector3(0,.87,0),Vector3(.13,1.74,.12),"554e43",false,root)
	var wood:=ShaderMaterial.new();wood.shader=load("res://assets/shaders/timber.gdshader");wood.set_shader_parameter("timber_color",Color("635d4e"))
	for row in range(2 if not north else 1):
		var board=world.box(Vector3(0,1.60-row*.36,.09),Vector3(1.38,.28,.10),"635d4e",false,root);board.material_override=wood
		var text:=Label3D.new();text.name="PaintedRoute";text.font=Palette.font();text.text="旧桥  ↓" if north else ("沿线  ↑" if row==0 else "林道  →")
		text.font_size=40;text.pixel_size=.0045;text.outline_size=0;text.shaded=true;text.modulate=Color("c2c2ac");text.position=Vector3(0,1.60-row*.36,.146);root.add_child(text)
		# A thin settled snow edge and two dark nails keep the paint part of the object.
		world.box(Vector3(0,1.746-row*.36,.09),Vector3(1.39,.025,.105),"9facb5",false,root)
		for x in [-.55,.55]:world.box(Vector3(x,1.60-row*.36,.145),Vector3(.025,.025,.012),"333b3b",false,root)
	if not north:
		paper(root,Vector3(.12,.19,.30))
		clue("fork_note",root.position+Vector3(0,.6,.3),"褪色的巡林路线","铁轨直通北面，风也直灌过来。东侧林道绕远一点，却有树挡风；布条往旧营地方向延伸。")

func paper(root:Node3D,at:Vector3,weighted:bool=true)->void:
	var page=world.box(at,Vector3(.23,.008,.30),"b3afa0",false,root);page.rotation.y=.18
	if weighted:world.box(at+Vector3(.05,.04,-.07),Vector3(.12,.08,.10),"65717a",false,root)
	for row in range(3):world.box(at+Vector3(-.025,.005,-.045+row*.035),Vector3(.13,.001,.006),"777c76",false,root)

func clue(id:String,at:Vector3,title:String,story:String)->void:
	if Chapter.CLUES.has(id):
		title=Chapter.CLUES[id].title;story=Chapter.CLUES[id].text
	world.points.append({"id":id,"kind":"clue","position":at,"title":"查看 · "+title,"node":null,"story":story})
	world.pois.append({"id":id,"title":title,"at":at,"story":story,"inspect":true})
