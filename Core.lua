-- Core.lua
-- Constants and data saving logic
local AddonName, TooManyAlts_env = ...

TooManyAlts_env.MAX_LEVEL = 90

TooManyAlts_env.SLOTS = {
    { id = 1,  name = "Head" },
    { id = 2,  name = "Neck" },
    { id = 3,  name = "Shoulder" },
    { id = 5,  name = "Chest" },
    { id = 6,  name = "Waist" },
    { id = 7,  name = "Legs" },
    { id = 8,  name = "Feet" },
    { id = 9,  name = "Wrist" },
    { id = 10, name = "Hands" },
    { id = 11, name = "Ring 1" },
    { id = 12, name = "Ring 2" },
    { id = 13, name = "Trinket 1" },
    { id = 14, name = "Trinket 2" },
    { id = 15, name = "Back" },
    { id = 16, name = "Main Hand" },
    { id = 17, name = "Off Hand" },
}

local function SaveGear()
    local name = UnitName("player")
    local realm = GetRealmName()
    local charKey = name .. "-" .. realm

    -- First pass: collect item links and request data for any items not cached
    local itemsToLoad = {}
    for _, slot in ipairs(TooManyAlts_env.SLOTS) do
        local itemLink = GetInventoryItemLink("player", slot.id)
        if itemLink then
            local itemID = C_Item.GetItemInfoInstant(itemLink)
            if itemID and not C_Item.IsItemDataCachedByID(itemID) then
                C_Item.RequestLoadItemDataByID(itemID)
                table.insert(itemsToLoad, {itemID = itemID, slotName = slot.name})
            end
        end
    end

    -- If items need loading, wait for them with retries
    local function AttemptSave(startIndex, retryCount)
        retryCount = retryCount or 0
        startIndex = startIndex or 1

        -- Check remaining items starting from startIndex
        local firstUncachedIndex = nil
        for i = startIndex, #itemsToLoad do
            if not C_Item.IsItemDataCachedByID(itemsToLoad[i].itemID) then
                firstUncachedIndex = i
                break
            end
        end

        -- If we found an uncached item and haven't exceeded retry limit, try again from that index
        -- Each item have 10 attempts to load
        if firstUncachedIndex ~= startIndex then
            retryCount = 0;
        end

        -- if an item is not cached after 10 attempts, print an error and move to next item
        if firstUncachedIndex and retryCount < 10 then
            C_Timer.After(0.1, function() AttemptSave(firstUncachedIndex, retryCount + 1) end)
            return
        elseif firstUncachedIndex then 
            --print an error message for any items that don't load after 10 attempts
            print(string.format("TooManyAlts WARNING: Failed to cache item ID %d in the '%s' slot after 10 attempts, skipping", itemsToLoad[firstUncachedIndex].itemID, itemsToLoad[firstUncachedIndex].slotName))
            -- Check if there are more items to process
            if firstUncachedIndex < #itemsToLoad then
                C_Timer.After(0.1, function() AttemptSave(firstUncachedIndex + 1, 0) end)
                return
            end
            -- If no more items, fall through to save
        end

        -- Now save the gear with all data loaded (or after timeout)
        local totalIlvl = 0
        local gear = {}

        for _, slot in ipairs(TooManyAlts_env.SLOTS) do
            local itemLink = GetInventoryItemLink("player", slot.id)
            local ilvl = nil

            if itemLink then
                ilvl = C_Item.GetDetailedItemLevelInfo(itemLink)
                if ilvl then -- if item failed to load, we add nothing
                    totalIlvl = totalIlvl + ilvl
                end
            end

            gear[slot.id] = {
                name = slot.name,
                link = itemLink,
                ilvl = ilvl,
            }
        end

        local avgItemLvl, avgILvlEquip = GetAverageItemLevel()

        TooManyAltsDB.characters[charKey] = {
            name = name,
            realm = realm,
            level = UnitLevel("player"),
            class = select(2, UnitClass("player")),
            avgItemLvl = avgItemLvl or 0,
            avgItemLvlEquip = avgILvlEquip or 0,
            gear = gear,
        }

        print("TooManyAlts: Gear saved for " .. charKey)
    end

    -- Start the save attempt from index 1
    AttemptSave(1, 0)
end

local function PreCacheAllGear()
    if not TooManyAltsDB.characters then return end
    for charKey, data in pairs(TooManyAltsDB.characters) do
        if data.gear then
            for _, slot in ipairs(TooManyAlts_env.SLOTS) do
                local slotData = data.gear[slot.id]
                if slotData and slotData.link then
                    C_Item.GetItemInfo(slotData.link)
                end
            end
        end
    end
end

local function Init() 
    -- Initialize DBs
    TooManyAltsDB = TooManyAltsDB or {}
    TooManyAltsDB.characters = TooManyAltsDB.characters or {} --Stores character info
    TooManyAltsDB.minimap = TooManyAltsDB.minimap or {} --Stores position of minimap button
    PreCacheAllGear()
    TooManyAlts_env.InitMinimap()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    -- Initalize
    Init()

    local ok, err = pcall(SaveGear)
    if not ok then
        print("TooManyAlts ERROR: " .. tostring(err))
    end
end)