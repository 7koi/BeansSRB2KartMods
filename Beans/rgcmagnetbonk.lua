local function FuckingMagnets(p)
	p.magnetsync = 1
	p.notouchy = 0
end

//local function MB_Debug(p)
	//local ks = p.kartstuff
	//if ks[k_spinouttimer] == nil return end
	//if ks[k_spinouttimer]
		//print("Speen: "..ks[k_spinouttimer].."Speed: "..p.speed.."Flash: "..p.powers[pw_flashing])
		//print("No Touch?: "..p.notouchy)
	//end
	
	//if (ks[k_spinouttimer] >= 0 and ks[k_spinouttimer] <= TICRATE)
	//and (p.powers[pw_flashing]) then
		//p.notouchy = 1
	//else
		//p.notouchy = 0
	//end
	
	//if p.speed >= 100*FRACUNIT and ks[k_spinouttimer]
		//p.mo.momx = 0
		//p.mo.momy = 0
	//end
//end

local bonkers = {MT_PLAYER, MT_ORBINAUT, MT_ORBINAUT_SHIELD, MT_JAWZ, MT_JAWZ_SHIELD, MT_JAWZ_DUD}
-- Prevents the dreaded Magnet Bonk(TM)
local function K_NoBonk(mo,mo2)
	if mo2 and mo2.valid and mo2.player
		if mo2.player.kartstuff[k_spinouttimer] > 0
		and mo2.player.kartstuff[k_spinouttimer] <= TICRATE
			mo2.player.mo.momx = 0
			mo2.player.mo.momy = 0
			mo2.player.mo.friction = FRACUNIT/32
			return false
		end
	end
end

for _,i in pairs(bonkers) do
addHook("MobjCollide", K_NoBonk, i)
addHook("MobjMoveCollide", K_NoBonk, i)
end

//addHook("ThinkFrame", do
//	for p in players.iterate
//		if not p.mo or not p.mo.valid continue end
//		if not p.magnetsync
//			FuckingMagnets(p)
//		end
//		MB_Debug(p)
//	end
//end)