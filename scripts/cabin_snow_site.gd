extends RefCounted
# Shared authored positions: visible trees and terrain accumulation agree.
const TREES:=[Vector3(-11,0,13),Vector3(12,0,15),Vector3(-9,0,33),Vector3(10,0,35),Vector3(-14,0,24),Vector3(14,0,29)]

static func gaussian(x:float,z:float,cx:float,cz:float,rx:float,rz:float)->float:
	return exp(-pow((x-cx)/rx,2)-pow((z-cz)/rz,2))

static func accumulation(x:float,z:float)->float:
	if absf(x)>19 or z<4 or z>44:return 0.0
	# Eave fall and lee-side drifts lie outside the foundation and clear doorway.
	var drift:=.48*gaussian(x,z,-5.6,18.0,1.5,4.8)
	drift+=.36*gaussian(x,z,5.5,17.0,1.6,4.1)
	drift+=.38*gaussian(x,z,0,12.5,4.0,1.35)
	drift+=.20*gaussian(x,z,-6.5,30.5,2.2,4.4)
	drift+=.16*gaussian(x,z,6.7,36,2.8,2.1)
	# Two low wind banks make the walked approach legible at the game camera's
	# scale, while the 3 m central corridor remains packed and unobstructed.
	drift+=.43*gaussian(x,z,-3.7,29.5,1.35,3.2)
	drift+=.38*gaussian(x,z,3.8,33.0,1.55,2.7)
	var foundation:=smoothstep(3.9,4.8,maxf(absf(x),absf(z-18)))
	var doorway:=smoothstep(1.5,3.2,absf(x)) if z>21 else 1.0
	drift*=foundation*doorway
	for tree in TREES:
		var dx:float=x-tree.x;var dz:float=z-tree.z
		var radius:=sqrt(dx*dx+dz*dz)
		if radius<2.6:
			# Low snow lip around a narrow trunk well; never a large buried hill.
			drift+=.10*exp(-pow((radius-.9)/.55,2))-.024*exp(-radius*radius/.20)
	return drift
