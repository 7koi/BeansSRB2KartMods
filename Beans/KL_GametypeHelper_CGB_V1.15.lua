/* Variables */
local roundnumcounter = -1		-- The amount of rounds remaining to play
local cooldowncounter = -1		-- The amount of cooldown remaining to replay
local roundnumset = -1			-- The total amount of rounds set to play
local roundnummax = 5			-- The maximum possible amount of rounds to play at once.
local roundprepared = false	-- Whether or not PrepareNextRound needs to run.
local roundextended = false 
local remindercounter = -1		-- Counter to display a chat message reminding players they can vote for certain gamemodes.
local remindercountermax = 3
local massesreminded = false	-- Whether or not the oblivious masses have been reminded that they can vote for certain gamemodes.
local currentgametype = nil	-- The current gametype.
local gametypes = {			-- Table of mod-specific values
	elimination	= {name = "elimination",fullname = "Elimination",	detect = "elimination",		toggleon = "elimination On",	toggleoff = "elimination Off",	suggestedrounds = 2,	extraoff1 = "basenumlaps \"map default\"",	extraoff2 = "allowteamchange 1"},
	elim_200cc 	= {name = "elim_200cc", fullname = "Elim+Expert",	detect = "elimination",		toggleon = "elimination On; cgb_200cc Force", toggleoff = "elimination Off; cgb_200cc Off", suggestedrounds = 3,	extraoff1 = "basenumlaps \"map default\"", 	extraoff2 = "allowteamchange 1"},
	teambattle	= {name = "teambattle",	fullname = "Friendmod",		detect = "fr_enabled",		toggleon = "fr_enabled On",		toggleoff = "fr_enabled Off",	suggestedrounds = 3,	extraon1 = "fr_bosschance 0",			extraon2 = "fr_teamattack Off"},
	team_elim	= {name = "team_elim",	fullname = "Team Race+Elim",detect = "fr_enabled",		toggleon = "elimination On; fr_enabled On",	toggleoff = "elimination Off; fr_enabled Off",	suggestedrounds = 2,	extraon1 = "fr_bosschance 0",	extraon2 = "fr_teamattack Off",	extraoff1 = "basenumlaps \"map default\"",	extraoff2 = "allowteamchange 1"},
	bossbattle	= {name = "bossbattle",	fullname = "Friendmod Boss",detect = "fr_enabled",		toggleon = "fr_enabled On",		toggleoff = "fr_enabled Off",	suggestedrounds = 3,	extraon1 = "fr_bosschance 100",			extraon2 = "fr_teamattack On"},
	hpmod		= {name = "hpmod",		fullname = "HPMod",			detect = "hpmod_enabled",	toggleon = "hpmod_enabled On",	toggleoff = "hpmod_enabled Off",suggestedrounds = 3,	extraon1 = "hpmod_maxhpperplayer 3",	extraon2 = "hpmod_maxhp 50"},
	hpmod_elim	= {name = "hpmod_elim",	fullname = "HPMod+Elim",	detect = "hpmod_enabled",	toggleon = "elimination On; hpmod_enabled On",	toggleoff = "elimination Off; hpmod_enabled Off",	suggestedrounds = 2,	extraon1 = "hpmod_maxhpperplayer 3",		extraon2 = "hpmod_maxhp 50",extraoff1 = "basenumlaps \"map default\"",	extraoff2 = "allowteamchange 1"},
	suddendeath	= {name = "suddendeath",fullname = "Sudden Death",	detect = "hpmod_enabled",	toggleon = "hpmod_enabled On; elimination On",	toggleoff = "hpmod_enabled Off; elimination Off",	suggestedrounds = 1,	extraon1 = "hpmod_maxhpperplayer 0",		extraon2 = "hpmod_maxhp 1",	extraoff1 = "basenumlaps \"map default\"",	extraoff2 = "allowteamchange 1"},
	mimic		= {name = "mimic",		fullname = "Mimic",			detect = "mimic",			toggleon = "mimic On",			toggleoff = "mimic Off",		suggestedrounds = 3, 	extraon1 = "hm_restat Off",	extraoff1 = "hm_restat On"},
	mimic_elim	= {name = "mimic_elim",	fullname = "Mimic+Elim",	detect = "mimic",			toggleon = "elimination On; mimic On",	toggleoff = "elimination Off; mimic Off",	suggestedrounds = 2,	extraon1 = "hm_restat Off",	extraoff1 = "basenumlaps \"map default\"",	extraoff2 = "allowteamchange 1; hm_restat On"},
	mimic_200cc	= {name = "mimic_200cc",fullname = "Mimic+Expert",	detect = "mimic",			toggleon = "mimic On; cgb_200cc Force", toggleoff = "mimic Off; cgb_200cc Off",		suggestedrounds = 4,  	extraon1 = "hm_restat Off",	extraoff1 = "hm_restat On"},
	force200cc	= {name = "force200cc",	fullname = "Expert Speed",	detect = "cgb_200cc",		toggleon = "cgb_200cc Force", 	toggleoff = "cgb_200cc Off",	suggestedrounds = 4},
	daredevil	= {name = "daredevil",	fullname = "Acro HELL",		detect = "ac_acrohell",		toggleon = "ac_acrohell forced", 	toggleoff = "ac_acrohell hellmap",	suggestedrounds = 3}
}

 /* Special print functions */
local function CheckServerPrint(player, printstring)
	if (player == server) then
		chatprint("\n\130* \128" .. printstring .. "\n", 1)
	else
		CONS_Printf(player, "\n" .. printstring .. "\n")
	end
end -- Close function

local function CheckHOSTMODPrint(player, commandname)
	if (CV_FindVar("hm_vote_timer")) then
		CONS_Printf(player, "Try using \'\130vote " .. commandname .. "\128\' instead!\n")
	else
		CONS_Printf(player, "\n") -- This is dumb but...
	end
end -- Close function

/*=======*/
/* Cvars */
/*=======*/

CV_RegisterVar({
	name = "GH_Reminder",
	defaultvalue = 3,
	flags = CV_CALL|CV_NETVAR,
	PossibleValue = {MIN = -1, MAX = 20},
	func = function(playerinput)
		remindercountermax = playerinput
	end -- Close function
})

CV_RegisterVar({
	name = "GH_RoundNumMax",
	defaultvalue = 5,
	flags = CV_CALL|CV_NETVAR,
	PossibleValue = {MIN = 1, MAX = 50},
	func = function(playerinput)
		roundnummax = playerinput
	end -- Close function
})

/*==========*/
/* Commands */
/*==========*/
COM_AddCommand("SetGametype", function(player, gametypeinput, roundnuminput)
	if (gametypeinput == nil and roundnuminput == nil) then -- Player types command with no inputs
		CONS_Printf(player, "\nSetGametype \130<Gametype> \135<Number of rounds>\n            \133*Required   \134Optional\n\n\128ExtendGametype \130<Number of rounds>\n               \133*Required\n\n\128ResetGametype\n\n\128The currently loaded gametypes are:\n")
		for k,v in pairs(gametypes)
			if (CV_FindVar(v.detect)) then
				CONS_Printf(player, "\130" .. v.fullname .. " (" .. v.name .. ")")
			end
		end
		CONS_Printf(player, "\n")
		return
	end
	if (IsPlayerAdmin(player) or player == server) then
		if (gametypes[gametypeinput] and CV_FindVar(gametypes[gametypeinput].detect)) then -- Check if gametypeinput exists
			if not (G_BattleGametype()) then --Check Battle Mode
				if (cooldowncounter <= 0) then --Check the cooldown
					if (roundnumcounter == -1) then -- Check if no other gametype is being played
						currentgametype = gametypeinput
						if (tonumber(roundnuminput) == nil) then
							roundnumcounter = gametypes[currentgametype].suggestedrounds
							roundnumset		= gametypes[currentgametype].suggestedrounds
						else
							roundnumcounter = max(min(tonumber(roundnuminput), roundnummax.value), 1)
							roundnumset		= max(min(tonumber(roundnuminput), roundnummax.value), 1)
							if (tonumber(roundnuminput) > roundnummax.value) then
								CONS_Printf(player, "Requested number of rounds is above the maximum allowed of " .. roundnummax.value)
							end
						end
						if (tonumber(roundnumcounter) == 1) then -- Pluralization check
							CheckServerPrint(player, gametypes[currentgametype].fullname .. " will be set for " .. roundnumcounter .. " round.")
						else
							CheckServerPrint(player, gametypes[currentgametype].fullname .. " will be set for " .. roundnumcounter .. " rounds.")
						end
						roundprepared = false
					else
						CheckServerPrint(player, "Please wait for this gametype to end before voting for another.\nYou can use \"\130ResetGametype\128\" to return to normal races.")
					end
				else
					CheckServerPrint(player, "Please wait the cooldown to be over before voting for another.\nDo\130 "..cooldowncounter.." more normal race(s)\128, then try again.")
				end
			else
				CheckServerPrint(player, "You are in Battle Mode!\n\130Leave the Battle First\128, then try again during the race.")
			end
		else
			CheckServerPrint(player, "This gametype does not exist or is not loaded.")
		end
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")
		CheckHOSTMODPrint(player, "SetGametype")
	end
end, 0)

COM_AddCommand("ExtendGametype", function(player, roundnuminput)
	if (tonumber(roundnuminput) == nil) then
		CONS_Printf(player, "\nExtendGametype \130<Number of rounds>\n               \133*Required\n")
	end
	if (IsPlayerAdmin(player) or player == server) then
		if (currentgametype) then -- Check if there's a gametype to extend
			if not (roundextended) then
				if (tonumber(roundnuminput) == 0) then
					CheckServerPrint(player, "Ok...?")
				elseif (tonumber(roundnuminput) < 0) then
					CheckServerPrint(player, "You cannot shorten the current gamemode.\nYou can use \'\130ResetGametype\128\' to return to normal races.")
				else
					roundnumcounter	= min($ + tonumber(roundnuminput), roundnummax.value)
					roundnumset 	= min($ + tonumber(roundnuminput), roundnummax.value)
					CheckServerPrint(player, "The current gametype has been extended to " .. roundnumcounter .. " rounds.")
					roundprepared = false
					roundextended = true
				end
			else
				CheckServerPrint(player, "You already Extend the Gametype. It's time to move on.")
			end
		else
			CheckServerPrint(player, "You must be playing a custom gamemode to extend it.")
		end
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")
		CheckHOSTMODPrint(player, "ExtendGametype")
	end
end, 0)

COM_AddCommand("ResetGametype", function(player)
	if (IsPlayerAdmin(player) or player == server) then
		roundnumcounter = -1
		roundprepared = false
		CheckServerPrint(player, "The gametype will be reset after this round.")
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")
		CheckHOSTMODPrint(player, "ResetGametype")
	end
 end, 0)

COM_AddCommand("DebugPrint", function(player)
	print("=== Current Gametype ===")
	print(currentgametype)
	print("==== Round Counters ====")
	print(roundnumcounter+1 .. " / " .. roundnumset+1)
	print("=== Round Prepared? ====")
	print(roundprepared)
end, 1)

/*===========*/
/* Functions */
/*===========*/
local function PrepareNextRound()
	if (roundprepared == false) then
		if (currentgametype) then -- Check if a gametype is set, and it's not battle mode
			if (roundnumcounter == roundnumset) then -- Check if we need to turn it on
				COM_BufInsertText(server, gametypes[currentgametype].toggleon)
				if (gametypes[currentgametype].extraon1) then COM_BufInsertText(server, gametypes[currentgametype].extraon1) end
				if (gametypes[currentgametype].extraon2) then COM_BufInsertText(server, gametypes[currentgametype].extraon2) end
				COM_BufAddText(server, "gh_gamestart") --Alias
			end
			if (roundnumcounter <= 0) then -- Check if we need to turn it off
				COM_BufInsertText(server, gametypes[currentgametype].toggleoff)
				if (gametypes[currentgametype].extraoff1) then COM_BufInsertText(server, gametypes[currentgametype].extraoff1) end
				if (gametypes[currentgametype].extraoff2) then COM_BufInsertText(server, gametypes[currentgametype].extraoff2) end
				COM_BufAddText(server, "gh_gameend") --Alias
				chatprint("\139<AriaBot>\130 "..gametypes[currentgametype].fullname.." is over!\131 Back to normal Race.", true)
				cooldowncounter = 3
				roundextended = false
				currentgametype = nil
				roundnumcounter = -1 -- Double make sure shit isn't fucked
				roundnumset = -1
			end
			if (currentgametype) then -- Check currentgametype again now that it's potentially been set
				roundnumcounter = $ - 1 -- Decrement Round Number
			end
		else
			if (cooldowncounter) then
				cooldowncounter = $ - 1
			else
				cooldowncounter = -1
			end
		end
		roundprepared = true -- Finish preparing for the next round
	end
end -- Close function

local function ModExistsRemind()
	if (remindercounter <= 0 and massesreminded == false and remindercountermax.value != -1 and CV_FindVar("hm_vote_timer")) then
		chatprint("\n\130* \128You can vote for your favorite gamemodes with \134'vote setgametype <gamemode>'\128!\nType \134'setgametype' \128in the console to see which are loaded!\n", true)
		remindercounter = remindercountermax.value
		massesreminded = true
	end
end -- Close function

local function ResetVars()
	roundprepared = false
	massesreminded = false
	if (remindercounter > 0) then
		remindercounter = $ - 1
	end
end -- Close function

local function BattleModeFailsafe()
	if (currentgametype) then 
		if (G_BattleGametype()) then
			--chatprint("\139<AriaBot>\131 FailSafe! You can't load a custom gametype for Race,\130 in Battle Mode!", true)
			G_ExitLevel()
		end
	end
end -- Close function

/* HUD function (((very scary))) */
local function RoundNumRemind(v, p)
	local hudfadeinoutflags = V_10TRANS * min(max(0, leveltime-(TICRATE*2)), 10)
	if (currentgametype) then -- Check if a gametype is even set
		if (roundnumcounter == 0) then -- Pluralization check
			v.drawString(160, 50, "\133FINAL \128round of " .. gametypes[currentgametype].fullname .. ".", V_SNAPTOTOP|V_ALLOWLOWERCASE|hudfadeinoutflags, "center")
		else
			v.drawString(160, 50, "\133" .. (roundnumcounter+1) .. " \128rounds of " .. gametypes[currentgametype].fullname .. " remaining.", V_SNAPTOTOP|V_ALLOWLOWERCASE|hudfadeinoutflags, "center")
		end
	end
end -- Close function

/*=======*/
/* Hooks */
/*=======*/
hud.add(RoundNumRemind,	"game")
addHook("ThinkFrame",	BattleModeFailsafe)
addHook("IntermissionThinker",	PrepareNextRound)
addHook("VoteThinker",	PrepareNextRound)
addHook("VoteThinker",	ModExistsRemind)
addHook("MapLoad",		ResetVars)

/* Netsync ya vars */
addHook("NetVars", function(n)
	currentgametype = n($)
	roundnumcounter = n($)
	cooldowncounter = n($)
	roundnumset		= n($)
	roundprepared	= n($)
	roundextended	= n($)
end)