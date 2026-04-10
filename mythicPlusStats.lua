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

    local charData = TooManyAltsDB.characters[TooManyAlts_env.charKey]
    print("charData: " .. tostring(charData))
    if not charData then return end

    charData.mythicPlus = charData.mythicPlus or {}
    charData.mythicPlus.currentKey = charData.mythicPlus.currentKey or {}
    local mp = charData.mythicPlus
    local currentKey = mp.currentKey

    local mapId = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    print("mapId: " .. tostring(mapId))
    if mapId then currentKey.mapId = mapId or nil end

    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    print("level: " .. tostring(level))
    if level then currentKey.level = level or 0 end
    print("currentKey.level: " .. tostring(currentKey.level))

    local bestSeasonScore, bestSeason = C_MythicPlus.GetSeasonBestMythicRatingFromThisExpansion()
    if bestSeasonScore then mp.rating = bestSeasonScore or 69 end
end