extends Node3D
# Authored junctions, not live predator markers. Supplies/AI remain unchanged.
const STOPS=[Vector2(4,-151),Vector2(6,-71)]
var game
var shown:Array[int]=[]
func setup(main)->void:
 game=main;name="ReturnWayfinding"
 build_station_board()
 for index in range(STOPS.size()):
  var at:Vector2=STOPS[index]
  var post:=Node3D.new();post.name="ReturnPost%d"%index;add_child(post)
  post.position=Vector3(at.x,game.world.terrain_height(at.x,at.y),at.y)
  game.world.box(Vector3(0,.8,0),Vector3(.12,1.6,.12),"514c43",true,post)
  var board=game.world.box(Vector3(0,1.3,.02),Vector3(1.3,.38,.10),"696052",false,post)
  var wood:=ShaderMaterial.new();wood.shader=load("res://assets/shaders/timber.gdshader");wood.set_shader_parameter("timber_color",Color("696052"));board.material_override=wood
  game.world.box(Vector3(0,1.5,.02),Vector3(1.32,.035,.12),"a5b3be",false,post)
  # Painted arrow, geometry attached to the board, no floating text.
  game.world.box(Vector3(.12,1.3,.076),Vector3(.65,.035,.008),"bcb49d",false,post)
  for angle in [-.7,.7]:
   var stroke=game.world.box(Vector3(.38,1.3+(.075 if angle<0 else -.075),.076),Vector3(.24,.035,.008),"bcb49d",false,post);stroke.rotation.z=angle
  game.world.box(Vector3(-.34,1.02,.03),Vector3(.18,.3,.025),"99794e",false,post)
  var id:String="return_post_%d"%index
  var words:="巡林告示 · 东侧林道"
  var text:="铁轨西侧见过狼踪。返家可从这里向东找布条，沿林道向南；旧桥仍是过河通道。\n\n林道能挡些风，不保证没有野兽。听到低吼先停下观察，拉开距离；冲刺和携带生肉更容易引起注意。屋内可以隔开追赶，绷带只能处理伤口，不能让野兽退走。"
  game.world.points.append({"id":id,"kind":"clue","position":post.position+Vector3(0,1,.2),"title":"查看 · "+words,"node":null,"story":text})
  game.world.pois.append({"id":id,"title":words,"at":post.position,"story":text,"inspect":true})

func build_station_board()->void:
 var board:=Node3D.new();board.name="WorkshopRouteBoard";game.world.buildings.station.add_child(board)
 board.position=Vector3(-4.72,2.22,1.7);board.rotation.y=PI*.5
 game.world.box(Vector3.ZERO,Vector3(1.45,.94,.055),"574f42",false,board)
 game.world.box(Vector3(0,0,.033),Vector3(1.26,.75,.012),"aaa38c",false,board)
 # Faded railway and the ochre eastern detour, pinned above the storage unit.
 game.world.box(Vector3(-.24,0,.043),Vector3(.017,.61,.006),"5d655e",false,board)
 for y in [-.3,0,.3]:game.world.box(Vector3(-.24,y,.05),Vector3(.075,.035,.009),"666558",false,board)
 for row in [[Vector3(.03,.28,.044),Vector3(.54,.018,.006)],[Vector3(.3,0,.044),Vector3(.018,.56,.006)],[Vector3(.03,-.28,.044),Vector3(.54,.018,.006)]]:
  game.world.box(row[0],row[1],"927147",false,board)
 for x in [-.55,.55]:
  for y in [-.31,.31]:game.world.box(Vector3(x,y,.05),Vector3(.025,.025,.012),"61554a",false,board)
 for visual in board.find_children("*","VisualInstance3D",true,false):visual.layers=4
 var at:=Vector3(-3.85,1.4,-168.3)
 var words:="维修间墙图 · 返家前"
 var text:="褪色的直线是铁路，赭色折线绕向东侧林道。西侧空白处写着：‘见狼，别带生肉赶夜路。’\n\n炉子和水壶仍能用。离开前先暖身，检查绷带与食水；到岔口可临时改道，交接单上的选择不会锁住道路。"
 game.world.points.append({"id":"workshop_route_board","kind":"clue","position":at,"title":"查看 · "+words,"node":null,"story":text})
 game.world.pois.append({"id":"workshop_route_board","title":words,"at":at,"story":text,"inspect":true})
func update()->void:
 if not game.survival.parts:shown.clear();return
 if not game.active:return
 var p:=Vector2(game.player.position.x,game.player.position.z)
 for i in range(STOPS.size()):
  if i not in shown and p.distance_to(STOPS[i])<8:
   shown.append(i)
   game.notify("岔口的旧布条指向东侧林道。铁路西侧有狼踪；靠近木牌可查看巡林告示。")
