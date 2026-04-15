-- mythicPlusStats.lua
-- Handles getting characters M+ stats and updating their charCards.
local AddonName, TooManyAlts_env = ...

function TooManyAlts_env.getMythicPlusStats()
    --[[ fetches characters:
        keystone dungeon    "C_MythicPlus.GetOwnedKeystoneChallengeMapID()"
        keystone level      "C_MythicPlus.GetOwnedKeystoneLevel()"
        current highest level for each dungeon  "intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapChallengeModeID)"
        gv m+ progress      "intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapChallengeModeID)"o

    ]]
    if TooManyAlts_env.level < TooManyAlts_env.MAX_LEVEL then return end

    if not TooManyAlts_env.charKey then print("Error: no charKey in TMA_env") end

    local charData = TooManyAltsDB.characters[TooManyAlts_env.charKey]
    if not charData then print("Error: No character table entry for current character") end

    charData.mythicPlus = charData.mythicPlus or {}
    charData.mythicPlus.currentKey = charData.mythicPlus.currentKey or {}
    local mp = charData.mythicPlus
    local currentKey = mp.currentKey

    local mapId = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        if mapId then print("mapId: " .. tostring(mapId) .. " " .. tostring(TooManyAlts_env.getMapShortName(mapId).shortName)) end
    if mapId then currentKey.mapId = mapId or nil end

    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    print("level: " .. tostring(level))
    if level then currentKey.level = level or 0 end
    print("currentKey.level: " .. tostring(currentKey.level))

    C_Timer.After(3, function()
        local bestSeasonScore, bestSeason = C_MythicPlus.GetSeasonBestMythicRatingFromThisExpansion()
        if not bestSeasonScore then
            return
        else
            print("rating: " .. tostring(bestSeasonScore))
            mp.rating = bestSeasonScore
        end
    end)
end