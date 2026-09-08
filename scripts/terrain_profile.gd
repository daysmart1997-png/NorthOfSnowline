extends RefCounted

static func mound(x:float,z:float,cx:float,cz:float,rx:float,rz:float)->float:
	return exp(-pow((x-cx)/rx,2)-pow((z-cz)/rz,2))

static func lake_weight(x:float,z:float)->float:
	var ellipse:=sqrt(pow((x+31)/23.0,2)+pow((z+89)/15.0,2))
	var lake:=1.0-smoothstep(.85,1.06,ellipse)
	var channel:float=(1.0-smoothstep(5.5,8.5,absf(z+86)))*(1.0-smoothstep(72,88,absf(x)))
	return maxf(lake,channel)

static func pad_mask(x:float,z:float)->float:
	var home:=smoothstep(6.4,11.5,Vector2(x,z-18).length())*smoothstep(6.4,11.5,Vector2(x,z+170).length())
	var road:=smoothstep(4.8,9.0,absf(x))
	var east:=smoothstep(2.7,6,absf(x-22))
	return home*road*east

static func bedrock(x:float,z:float)->float:
	var ridge:=6.3*mound(x,z,-34,-36,22,28)+9.0*mound(x,z,45,-137,23,32)+4.6*mound(x,z,-56,-158,31,24)
	var hollows:=-2.3*mound(x,z,40,-43,16,22)-2.2*mound(x,z,-47,-111,20,19)
	var rolling:=(.42*sin(x*.071+z*.039)+.28*sin(z*.099-x*.024))*pad_mask(x,z)
	var land:=(ridge+hollows)*pad_mask(x,z)+rolling
	return lerpf(land,-1.65,lake_weight(x,z))

static func slope(x:float,z:float)->float:
	var dx:=(bedrock(x+.5,z)-bedrock(x-.5,z))
	var dz:=(bedrock(x,z+.5)-bedrock(x,z-.5))
	return Vector2(dx,dz).length()

static func snow(x:float,z:float)->float:
	var ice:=lake_weight(x,z)
	if ice>.96:return 0
	# Accumulation is independent of altitude: hollows collect snow; exposed slopes shed it.
	var shelter:=.38*mound(x,z,39,-43,17,24)+.30*mound(x,z,-47,-110,19,17)
	var drifts:=.13+.10*(sin(x*.57+z*.21)*.5+.5)+.07*(sin(z*.87-x*.24)*.5+.5)
	var exposure:=.17*mound(x,z,-34,-36,16,19)+.18*mound(x,z,45,-137,20,25)
	var thickness:=clampf(drifts+shelter-exposure-slope(x,z)*.21,.035,.65)
	return thickness*pad_mask(x,z)*(1-ice)

static func height(x:float,z:float)->float:
	return bedrock(x,z)+snow(x,z)

static func normal(x:float,z:float)->Vector3:
	return Vector3(height(x-.2,z)-height(x+.2,z),.4,height(x,z-.2)-height(x,z+.2)).normalized()
