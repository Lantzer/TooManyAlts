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





local changedSlots = {}  -- slotID → true, accumulates changed slots until debounce fires
local eventFrame = CreateFrame("Frame")

local function Init()
    eventFrame:UnregisterEvent("ADDON_LOADED")
    TooManyAltsDB = TooManyAltsDB or {}
    TooManyAltsDB.characters = TooManyAltsDB.characters or {} --Stores character info
    TooManyAltsDB.minimap = TooManyAltsDB.minimap or {} --Stores position of minimap button
    TooManyAlts_env.InitMinimap()
end

local eventHandlers = {
    ADDON_LOADED = function(addonName)
        if addonName == AddonName then Init() end
    end,
    PLAYER_LOGIN = function()
        local ok, err = pcall(TooManyAlts_env.saveGear)
        if not ok then print("TooManyAlts ERROR: " .. tostring(err)) end
    end,
    PLAYER_EQUIPMENT_CHANGED = function(slot)
        changedSlots[slot] = true
        if slot == 16 or slot == 17 then
            changedSlots[16] = true
            changedSlots[17] = true
        end
        TooManyAlts_env.scheduleSaveGear(changedSlots)
    end,
}

for event in pairs(eventHandlers) do
    eventFrame:RegisterEvent(event)
end
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if eventHandlers[event] then
        eventHandlers[event](...)
    end
end)