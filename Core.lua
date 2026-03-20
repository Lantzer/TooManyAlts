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

-- O(1) lookup of slot metadata by slot ID
local slotByID = {}
for _, slot in ipairs(TooManyAlts_env.SLOTS) do
    slotByID[slot.id] = slot
end

-- slotsToSave: nil = full save (login), table of slotID→true = partial save (equipment change)
local function SaveGear(slotsToSave)
    local name = UnitName("player")
    local realm = GetRealmName()
    local charKey = name .. "-" .. realm

    -- Partial save with no existing record: fall back to full save
    if slotsToSave and not TooManyAltsDB.characters[charKey] then
        SaveGear(nil)
        return
    end

    -- Resolve the list of slots to process
    -- slotsToProcess is populated when we equip new items, only requiring the ensure those items are cached before saving them.
    local slotsToProcess = {}
    if slotsToSave then
        for slotID in pairs(slotsToSave) do
            local slot = slotByID[slotID]
            if slot then
                table.insert(slotsToProcess, slot)
            end
        end
    else
        slotsToProcess = TooManyAlts_env.SLOTS
    end

    -- First pass: request data for any uncached items in the affected slots
    local itemsToLoad = {}
    for _, slot in ipairs(slotsToProcess) do
        local itemLink = GetInventoryItemLink("player", slot.id)
        if itemLink then
            local itemID = C_Item.GetItemInfoInstant(itemLink)
            if itemID and not C_Item.IsItemDataCachedByID(itemID) then
                C_Item.RequestLoadItemDataByID(itemID)
                table.insert(itemsToLoad, {itemID = itemID, slotName = slot.name})
            end
        end
    end

    local function AttemptSave(startIndex, retryCount)
        retryCount = retryCount or 0
        startIndex = startIndex or 1

        local firstUncachedIndex = nil
        for i = startIndex, #itemsToLoad do
            if not C_Item.IsItemDataCachedByID(itemsToLoad[i].itemID) then
                firstUncachedIndex = i
                break
            end
        end

        -- Reset retry count when we advance to a new item
        if firstUncachedIndex ~= startIndex then
            retryCount = 0
        end

        if firstUncachedIndex and retryCount < 10 then
            C_Timer.After(0.1, function() AttemptSave(firstUncachedIndex, retryCount + 1) end)
            return
        elseif firstUncachedIndex then
            print(string.format("TooManyAlts WARNING: Failed to cache item ID %d slot after 10 attempts, skipping", itemsToLoad[firstUncachedIndex].itemID))
            if firstUncachedIndex < #itemsToLoad then
                C_Timer.After(0.1, function() AttemptSave(firstUncachedIndex + 1, 0) end)
                return
            end
        end

        local avgItemLvl, avgILvlEquip = GetAverageItemLevel()

        if slotsToSave then
            -- Partial save: update only the changed slots in the existing record
            local charData = TooManyAltsDB.characters[charKey]
            for _, slot in ipairs(slotsToProcess) do
                charData.gear[slot.id] = {
                    name = slot.name,
                    link = GetInventoryItemLink("player", slot.id),
                    ilvl = nil,
                }
            end
            charData.level = UnitLevel("player")
            charData.avgItemLvl = avgItemLvl or 0
            charData.avgItemLvlEquip = avgILvlEquip or 0
        else
            -- Full save: rebuild the entire character record
            local gear = {}
            for _, slot in ipairs(TooManyAlts_env.SLOTS) do
                gear[slot.id] = {
                    name = slot.name,
                    link = GetInventoryItemLink("player", slot.id),
                    ilvl = nil,
                }
            end
            TooManyAltsDB.characters[charKey] = {
                name = name,
                realm = realm,
                level = UnitLevel("player"),
                class = select(2, UnitClass("player")),
                avgItemLvl = avgItemLvl or 0,
                avgItemLvlEquip = avgILvlEquip or 0,
                gear = gear,
            }
        end

        print("TooManyAlts: REFACTOR Gear saved for " .. charKey)
    end

    AttemptSave(1, 0)
end

--Save Character M+ Stats

local changedSlots = {}  -- slotID → true, accumulates changed slots until debounce fires

-- If we save multiple pieces of gear within .5 seconds of eachother, we wait to call SaveGear until after .5 seconds pass since we changed an item
local saveTimer = nil
local function ScheduleSaveGear()
    if saveTimer then
        saveTimer:Cancel()
    end
    saveTimer = C_Timer.NewTimer(0.5, function()
        saveTimer = nil
        local snapshot = changedSlots
        changedSlots = {}
        local ok, err = pcall(SaveGear, snapshot)
        if not ok then
            print("TooManyAlts ERROR: " .. tostring(err))
        end
    end)
end

local function Init()
    -- Initialize DBs
    TooManyAltsDB = TooManyAltsDB or {}
    TooManyAltsDB.characters = TooManyAltsDB.characters or {} --Stores character info
    TooManyAltsDB.minimap = TooManyAltsDB.minimap or {} --Stores position of minimap button
    TooManyAlts_env.InitMinimap()
end

local updateFrame = CreateFrame("Frame")
updateFrame:RegisterEvent("PLAYER_LOGIN")
updateFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
updateFrame:SetScript("OnEvent", function(self, event, slot)
    -- Update gear on login or when equipment changes
    if event == "PLAYER_LOGIN" then
        local ok, err = pcall(SaveGear)
        if not ok then
            print("TooManyAlts ERROR: " .. tostring(err))
        end
    end

    -- We save all gear when any piece of gear is changed, this saves us from having multiple instances of SaveGear running when we update multiple pieces at a time
    -- Normal use case includes swapping 1 or 2 items (trinkets/rings), or many pieces with a gear swap addon.
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        changedSlots[slot] = true
        ScheduleSaveGear()
    end
    
end)

-- Initalize addon when savedVariables is ready
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == AddonName then
       Init()
       self:UnregisterEvent("ADDON_LOADED")
    end
end)