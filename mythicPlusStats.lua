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

    if not TooManyAlts_env.charKey then
        error("TooManyAlts: no charKey in TMA_env")
    end

    local charData = TooManyAltsDB.characters[TooManyAlts_env.charKey]
    if not charData then return end

    charData.mythicPlus = charData.mythicPlus or {}
    charData.mythicPlus.currentKey = charData.mythicPlus.currentKey or {}
    local mp = charData.mythicPlus
    local currentKey = mp.currentKey

    local mapId = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()

    if mapId and level then
        currentKey.mapId = mapId
        currentKey.level = level
    else
        currentKey.mapId = nil
        currentKey.level = nil
    end

    local bestSeasonScore, bestSeason = C_MythicPlus.GetSeasonBestMythicRatingFromThisExpansion()
        if bestSeasonScore then print("rating: " .. tostring(bestSeasonScore)) end
    if bestSeasonScore then mp.rating = bestSeasonScore or 69 end
end