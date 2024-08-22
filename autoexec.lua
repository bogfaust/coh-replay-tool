--[=====[

Mini tool for replays :: Specially for Angrade :: Angrade's channel https://youtube.com/channel/UCjaG4wIJxdKQLZPy3uDC9pg

This script requires the -dev launch option.

Place this script in ...\steamapps\common\Company of Heroes Relaunch\autoexec.lua for automatic execution when starting a replay (autorun of autoexec.lua is available only in -dev mode).

For manual execution, use:
dofile('autoexec.lua')

Tested on version: 2.700.2.43 (Lua 5.1)

GitHub: https://github.com/bogfaust

--]=====]



-- Configuration
local CONFIG = {
    OUTPUT_FILE = "replay_info.txt",
	CONSOLE_OUTPUT_PREFIX = "[CONSOLE] ",
	HIDE_MESSAGE_REPLAY = true,
	HIDE_ALL_MESSAGES = false
}

-- Localisation
local L = {
    MAP_NAME = "Map Name: ",
    PLAYER_NAME = "Player Name: ",
    FACTION = "Faction: "
}

-- Global constants
-- Table of factions
local RACES = {
    BRITISH = "British",
    US = "United States",
    WEHRMACHT = "Wehrmacht",
    PANZER_ELITE = "Panzer Elite",
	
    UNKNOWN = "Unknown Race"
}

-- Table of teams
local TEAMS = {
    ALLIES = "Allies",
    AXIS = "Axis",
	
    UNKNOWN = "Unknown Faction"
}


-- Local references to global functions
local World_GetPlayerCount = World_GetPlayerCount
local World_GetPlayerAt = World_GetPlayerAt
local Player_GetDisplayName = Player_GetDisplayName
local Player_GetRace = Player_GetRace
local Player_GetTeam = Player_GetTeam
local getmapname = getmapname
local getgametype = getgametype
local message_hide = message_hide
local message_show = message_show


local function isWatchingReplay()
    local gameType = getgametype()

    local gameTypes = {
        GT_PLAYBACK = 4,
        GT_MULTIPLAYER = 3,
        GT_SINGLEPLAYER_CAMPAIGN = 1,
        GT_SINGLEPLAYER_SKIRMISH = 2,
        GT_NETPLAYBACK = 6,
        GT_SAVEGAME = 5
    }

    if gameType == gameTypes.GT_PLAYBACK then
        return true
    else
        return false
    end
end


local function getRaceName(raceId)
    local RACE_ID_TO_KEY = {
		[0] = "BRITISH",
		[1] = "US",
		[2] = "WEHRMACHT",
		[3] = "PANZER_ELITE"
	}
    return RACES[RACE_ID_TO_KEY[raceId]] or RACES.UNKNOWN
end

local function getFactionName(factionId)
    local FACTION_ID_TO_KEY = {
		[0] = "ALLIES",
		[1] = "AXIS"
	}
    return TEAMS[FACTION_ID_TO_KEY[factionId]] or TEAMS.UNKNOWN
end

-- Function to convert a table to a string
local function tableToString(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, tostring(k) .. ": " .. tostring(v))
    end
    return table.concat(result, ", ")
end

-- Function to format player information
local function formatPlayerInfo(player)
    return string.format("%s%s, %s%s\n",
        L.PLAYER_NAME, tostring(player.name),
        L.FACTION, tostring(player.race)
    )
end

-- Function to write team information
local function writeTeamInfo(file, teamName, players)
    file:write(teamName .. ":\n")
    for _, player in ipairs(players) do
        file:write(formatPlayerInfo(player))
    end
    file:write("\n")
end


-- Checking for required features
local required_functions = {
    "World_GetPlayerCount",
    "World_GetPlayerAt",
    "Player_GetDisplayName",
    "Player_GetRace",
    "Player_GetTeam",
    "getmapname",
    "getgametype",
    "message_hide",
    "message_show"
}

local function check_functions()
    local missing_functions = {}
    for _, func_name in ipairs(required_functions) do
        if _G[func_name] == nil then
            table.insert(missing_functions, func_name)
        end
    end
    return #missing_functions == 0, missing_functions
end


local function main()
	-- This should run only when watching a replay
    if not isWatchingReplay() then return end
	
	if CONFIG.HIDE_ALL_MESSAGES then
		-- Hide "Playback" and "Pause", "Playback over.", etc messages
		message_hide();
	elseif CONFIG.HIDE_MESSAGE_REPLAY then
		-- Hide only "Playback" message
		message_hide();
		message_show();
	end
	
	local functions_available, missing_functions = check_functions()
		if not functions_available then
			print(CONFIG.CONSOLE_OUTPUT_PREFIX .. " [no -dev mode?] Error: The following required functions are not available:")
			for _, func_name in ipairs(missing_functions) do
				print(func_name)
			end
			return
		end

    local playerCount = World_GetPlayerCount()
    local teams = {[TEAMS.ALLIES] = {}, [TEAMS.AXIS] = {}, [TEAMS.UNKNOWN] = {}}

	-- Iterate over all players
    for i = 1, playerCount do
        local playerId = World_GetPlayerAt(i)
        local playerName = tableToString(Player_GetDisplayName(playerId)):sub(4)
        local playerRace = getRaceName(Player_GetRace(playerId))
        local playerTeam = getFactionName(Player_GetTeam(playerId))
        
        table.insert(teams[playerTeam], {name = playerName, race = playerRace})
    end

    local file, errorMsg = io.open(CONFIG.OUTPUT_FILE, "w")
    if not file then
        print(CONFIG.CONSOLE_OUTPUT_PREFIX .. "Error opening file: " .. tostring(errorMsg))
        return
    end

	-- Write info about players
    file:write(L.MAP_NAME .. getmapname() .. "\n\n")
    for teamName, players in pairs(teams) do
        if #players > 0 then
            writeTeamInfo(file, teamName, players)
        end
    end

    file:close()
end


main()