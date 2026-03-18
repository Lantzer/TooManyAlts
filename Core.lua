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

    local totalIlvl = 0
    local itemCount = 0
    local gear = {}

    for _, slot in ipairs(TooManyAlts_env.SLOTS) do
        local itemLink = GetInventoryItemLink("player", slot.id)
        local ilvl = nil

        if itemLink then
            ilvl = C_Item.GetDetailedItemLevelInfo(itemLink)
            if ilvl then
                totalIlvl = totalIlvl + ilvl
                itemCount = itemCount + 1
            end
        end

        gear[slot.id] = {
            name = slot.name,
            link = itemLink,
            ilvl = ilvl,
        }
    end

    TooManyAltsDB.characters[charKey] = {
        name = name,
        realm = realm,
        level = UnitLevel("player"),
        class = select(2, UnitClass("player")),
        avgIlvl = itemCount > 0 and math.floor(totalIlvl / itemCount) or 0,
        gear = gear,
    }

    print("TooManyAlts: Gear saved for " .. charKey)
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