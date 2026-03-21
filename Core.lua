-- Core.lua
-- Constants and data saving logic
local AddonName, TooManyAlts_env = ...

TooManyAlts_env.MAX_LEVEL = 90

TooManyAlts_env.SLOTS = {
    { id = 1,  name = "Head", enchantable = true},
    { id = 2,  name = "Neck", enchantable = false},
    { id = 3,  name = "Shoulder", enchantable = true},
    { id = 5,  name = "Chest", enchantable = true },
    { id = 6,  name = "Waist", enchantable = false},
    { id = 7,  name = "Legs", enchantable = true },
    { id = 8,  name = "Feet", enchantable = true },
    { id = 9,  name = "Wrist", enchantable = false},
    { id = 10, name = "Hands", enchantable = false },
    { id = 11, name = "Ring 1", enchantable = true },
    { id = 12, name = "Ring 2", enchantable = true },
    { id = 13, name = "Trinket 1", enchantable = false },
    { id = 14, name = "Trinket 2", enchantable = false },
    { id = 15, name = "Back", enchantable = false },
    { id = 16, name = "Main Hand", enchantable = true },
    { id = 17, name = "Off Hand", enchantable = false },
}



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

    local function WriteToDatabase(gear)
        local avgItemLvl, avgILvlEquip = GetAverageItemLevel()

        if slotsToSave then
            local charData = TooManyAltsDB.characters[charKey]
            for slotID, slotData in pairs(gear) do
                charData.gear[slotID] = slotData
            end
            charData.level = UnitLevel("player")
            charData.avgItemLvl = avgItemLvl or 0
            charData.avgItemLvlEquip = avgILvlEquip or 0
        else
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

        print("TooManyAlts: Gear saved for " .. charKey)
    end

    local pending = 0
    local gear = {}
    local loopDone = false

    -- Only write once all slots are registered AND all async loads are complete
    local function tryWrite()
        if loopDone and pending == 0 then
            WriteToDatabase(gear)
        end
    end

    local function processSlot(slotID)
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            pending = pending + 1
            local item = Item:CreateFromItemLink(itemLink)
            item:ContinueOnItemLoad(function()
                local _, _, _, ilvl, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemLink)
                local track, cur, max = TooManyAlts_env.GetItemUpgradeTrack(itemLink)
                gear[slotID] = { link = itemLink, itemTexture = itemTexture, ilvl = ilvl, upgradeTrack = track, upgradeCur = cur, upgradeMax = max }
                pending = pending - 1
                tryWrite() --inside callback function because of async, so that it is only triggered when the last item is done loading.
            end)
        else -- if no item is equipped
            gear[slotID] = { link = nil, itemTexture = nil, ilvl = nil, upgradeTrack = nil, upgradeCur = nil, upgradeMax = nil }
        end
    end

    if slotsToSave then
        for slotID in pairs(slotsToSave) do processSlot(slotID) end
    else
        for slotID = 1, 17 do processSlot(slotID) end
    end

    loopDone = true
    tryWrite() -- if we unequip only, then no async function is called, update empty slot in db
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

    -- When an item is changed, save it's slotID, and only change those that are changed
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