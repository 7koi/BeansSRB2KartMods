//original maplist.lua by Dr_Nope#0037
//freeman#7626 tinkering with it now

local function getmapid(n)
    if n<100 then
        return (n<10) and ("0"..n) or tostring(n)
    end

    local x= n-100
    local p= x/36
    local q= x-(36*p)
    local a= string.char(string.byte('A')+p)
    local b= (q<10) and tostring(q) or string.char(string.byte('A')+q-10)

    return a..b
end

local maptable = {}
local gametypes = {
	"\133SOLO\128",
	"\133SP\128",
	"\133SINGLE\128",
	"\133SINGLE\128",
	"COOP",
	"CO-OP",
	"COMPETITION",
	"\132RACE\128",
	"MATCH",
	"NIGHTS", // SRB2kart
	"TAG",
	"CTF",
	"CUSTOM",
	"2D",
	"MARIO",
	"\135BATL\128",
	"TV",
	"XMAS",
	"CHRISTMAS",
	"WINTER"}

//map table key:
//id = map ID
//name = full map name and titles
//sprint = (true/false) if its a sprint track
//gametype = Singleplayer, Race, Battle, etc.
//hell = (true/false) hell map or no

//ID: HELL | SPRNT | GAMETYPEAA | MAP NAME AND TITLE

local function printmaps(p, maptable)
	if not #maptable then
		CONS_Printf(p, "\133No maps returned! Revise your query.")
		return
	end
	CONS_Printf(p, "\130ID\128|\133HELL \128|\131SPNT \128|\135TYPE\128 | NAME [returned "..#maptable.." total maps]")
	CONS_Printf(p, "-----------------------------------")
	for i=1,#maptable
		local msg = "\130"..maptable[i].id.."\128:"
		if maptable[i].hell then msg = $+"\133HELL\128 |" else msg = $+"     |" end
		if maptable[i].sprint then msg = $+"\131SPNT\128 |" else msg = $+"     |" end
		local modestr = gametypes[maptable[i].gametype] or gametypes[maptable[i].gametype-TOL_TV]
		msg = $+string.format("%-7s",modestr).."| "
		msg = $+maptable[i].name
		CONS_Printf(p, msg)
	end
end

//HAHA OKAY so I am pretty sure I ran into the issue of snek eats its own tail
//dont try to truncate a list that you're running a for loop on cause the loop will run over :HAAH:
//protip running it in reverse doesn't run into the same issue :OMEGALUL:
local function hellmaps(maptable, hide)
	//print("proc'd hell map hider")
	if not maptable then return end
	//if not hide then return end
	local count = 0
	if hide >= 1 then
		//print("hiding hell maps...")
		for i=#maptable,1,-1
			
			if maptable[i].hell then
				//print("removed "..maptable[i].name)
				table.remove(maptable, i)
				count = $+1
			end
		end
	else
		//print("hiding non-hell maps...")
		for i=#maptable,1,-1
			if not maptable[i].hell then
				//print("removed "..maptable[i].name)
				table.remove(maptable, i)
				count = $+1
			end
		end
	end
	//print("hid "..count.." maps")
	return maptable
end

local function sprintmaps(maptable, hide)
	if not maptable then return end
	//if not hide then return end
	if hide >= 1 then
		for i=#maptable,1,-1
			if maptable[i].sprint then table.remove(maptable, i) end
		end
	else
		for i=#maptable,1,-1
			if not maptable[i].sprint then table.remove(maptable, i) end
		end
	end
	return maptable
end

local function racemaps(maptable, hide)
	if not maptable then return end
	//if not hide then return end
	if hide >= 1 then
		for i=#maptable,1,-1
			if maptable[i].gametype == 8 or maptable[i].gametype-TOL_TV == 8 then table.remove(maptable, i) end
		end //in the interest of readability I DONT FUCKING CARE
	else
		for i=#maptable,1,-1
			if not(maptable[i].gametype == 8 or maptable[i].gametype-TOL_TV == 8) then table.remove(maptable, i) end
		end
	end
	return maptable
end

local function battlemaps(maptable, hide)
	if not maptable then return end
	//if not hide then return end
	if hide >= 1 then
		for i=#maptable,1,-1
			if maptable[i].gametype == 16 or maptable[i].gametype-TOL_TV == 16 then table.remove(maptable, i) end
		end //in the interest of readability I DONT FUCKING CARE
	else
		for i=#maptable,1,-1
			if not(maptable[i].gametype == 16 or maptable[i].gametype-TOL_TV == 16) then table.remove(maptable, i) end
		end
	end
	return maptable
end

local function solomaps(maptable, hide)
	if not maptable then return end
	//if not hide then return end
	if hide >= 1 then
		for i=#maptable,1,-1
			if maptable[i].gametype <= 4 then table.remove(maptable, i) end
		end //in the interest of readability I DONT FUCKING CARE
	else
		for i=#maptable,1,-1
			if not(maptable[i].gametype <= 4) then table.remove(maptable, i) end
		end
	end
	return maptable
end

local function namefilter(maptable, namestr)
	if not maptable then return end
	if not namestr then return end
	for i=#maptable,1,-1
		if not string.find(string.lower(maptable[i].name),namestr) then table.remove(maptable, i) end
	end
	return maptable
end

local function sortmaps(maptable, sorttype)
	if not maptable then return end
	if sorttype == "id" then 
		table.sort(maptable,function(a,b) return a.id < b.id end)
	elseif sorttype == "name" then
		table.sort(maptable,function(a,b) return a.name < b.name end)
	elseif sorttype == "gametype" then
		table.sort(maptable,function(a,b) return a.gametype > b.gametype end)
	elseif sorttype == "sprint" then
		table.sort(maptable,function(a,b) return a.sprint > b.sprint end)
	elseif sorttype == "hell" then
		table.sort(maptable,function(a,b) return a.hell > b.hell end)
	end
	return maptable
end	
	
local function listallmaps(p, ...)
	if not ... then
		CONS_Printf(p, "\133Usage:   \128Provide the command followed by one or more of these arguments:")
		CONS_Printf(p, "\130hell     \128Shown maps must be \130hell maps\128 (use -hell to hide hell maps).")
		CONS_Printf(p, "\130sprint   \128Shown maps must be \130sprint tracks\128 (use -sprint to hide sprint tracks).")
		CONS_Printf(p, "\130gametype \128List a gametype to only show maps of this gametype (\130use RACE, BATTLE, or SOLO. \128Prefix the gametype with - to hide maps of that type).")
		CONS_Printf(p, "\130sort:    \128List a field to \130sort the list\128 on after it has been created (ex: sort:id). Valid sort fields are id, name, gametype, sprint, hell. You can specify multiple sorts in sequence to more finely control the list of maps ex: sort:id sort:hell.")
		CONS_Printf(p, "\130any word \128Any other word will try to be used as a \130name filter\128. I am lazy, so only use a single word right now. Sorry.")
		CONS_Printf(p, "Arguments can be combined for more complex queries, ex: 'listmaps -hell -sprint race sort:name' will show all RACE tracks in alphabetical order that are not sprint or hell maps. You get the idea.")
		return
	end
	local args = {...}
    local max= (36*26+26)+100
	maptable = {}
    for i=0,max do
        local map= mapheaderinfo[i]
        if map and map.lvlttl then
			table.insert(maptable,
						{id=getmapid(i),
						name=map.lvlttl.." "..(map.subttl and map.subtt1 or "")..(map.zonttl and map.zonttl or "")..(map.actnum and (" "..map.actnum) or ""),
						sprint=map.levelflags&LF_SECTIONRACE,
						gametype=map.typeoflevel,
						hell=map.menuflags & LF2_HIDEINMENU}
						)
            //print(getmapid(i).." "..map.lvlttl.." "..(map.subttl and map.subttl or ""))
        end
    end
	for i=1,#args
		local hidevar = 0
		local testarg = string.lower(args[i])
		//print("arg number: "..i.." - "..testarg)
		if string.sub(testarg,1,1) == "-" then hidevar = 1 end
		if testarg == "hell" or testarg == "-hell" then maptable = hellmaps(maptable, hidevar)
		elseif testarg == "sprint" or testarg == "-sprint" then maptable = sprintmaps(maptable, hidevar)
		elseif testarg == "race" or testarg == "-race" then maptable = racemaps(maptable, hidevar)
		elseif testarg == "solo" or testarg == "-solo" then maptable = solomaps(maptable, hidevar)
		elseif testarg == "battle" or testarg == "-battle" then maptable = battlemaps(maptable, hidevar)
		elseif string.sub(testarg,1,5) == "sort:" then maptable = sortmaps(maptable,string.sub(testarg,6))
		else maptable = namefilter(maptable, testarg)
		end
	end
	printmaps(p, maptable)
end

COM_AddCommand("listmaps", listallmaps, 0)