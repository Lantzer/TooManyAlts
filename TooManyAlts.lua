-- TooManyAlts.lua
-- Slash commands
local AddonName, TooManyAlts_env = ...

SLASH_TOOMANYALTS1 = "/tma"
SlashCmdList["TOOMANYALTS"] = function(msg)
    msg = msg:lower()

    if msg == "clear" then
        TooManyAltsDB.characters = {}
        print("TooManyAlts: All character data cleared.")

    elseif msg == "list" then
        if not TooManyAltsDB.characters or not next(TooManyAltsDB.characters) then
            print("TooManyAlts: No characters saved yet.")
            return
        end
        for charKey, data in pairs(TooManyAltsDB.characters) do
            print("--- " .. charKey .. " (Level " .. data.level .. ") avg ilvl: " .. data.avgIlvl .. " ---")
            for _, slot in ipairs(TooManyAlts_env.SLOTS) do
                local slotData = data.gear[slot.id]
                local itemName = slotData and slotData.link and slotData.link or "empty"
                local ilvlText = slotData and slotData.ilvl and (" [" .. slotData.ilvl .. "]") or " [--]"
                print(slot.name .. ": " .. itemName .. ilvlText)
            end
        end

    elseif msg == "help" then
        print("|cffffcc00TooManyAlts commands:|r")
        print("  /tma        - Toggle the main window")
        print("  /tma list   - Print all saved characters to chat")
        print("  /tma clear  - Clear all saved character data")
        print("  /tma help   - Show this help message")

    else
        if TooManyAlts_env.mainFrame:IsShown() then
            TooManyAlts_env.mainFrame:Hide()
        else
            TooManyAlts_env.OpenMainFrame()
        end
    end
end