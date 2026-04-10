-- TooManyAlts.lua
-- Slash commands
local AddonName, TooManyAlts_env = ...

SLASH_TOOMANYALTS1 = "/tma"
SlashCmdList["TOOMANYALTS"] = function(msg)
    msg = msg:lower()

    if msg == "clear" then
        TooManyAltsDB.characters = {}
        print("TooManyAlts: All character data cleared.")

    elseif msg == "help" then
        print("|cffffcc00TooManyAlts commands:|r")
        print("  /tma        - Toggle the main window")
        print("  /tma list   - Print all saved characters to chat")
        print("  /tma clear  - Clear all saved character data")
        print("  /tma help   - Show this help message")

    elseif msg =="dng" then
        local ok, err = pcall(TooManyAlts_env.getMythicPlusStats) -- Save characters M+ when dungeon completes -> update rating and new key if it was our key
        if not ok then print("TooManyAlts (getMythicPlusStats) ERROR: " .. tostring(err)) return end
        print(tostring(TooManyAlts_env.charKey))
        local card = TooManyAlts_env.getCharCard(TooManyAlts_env.charKey)
        if card then
            ok, err = pcall(TooManyAlts_env.updateCharCard, card, TooManyAltsDB.characters[TooManyAlts_env.charKey])
            if not ok then print("TooManyAlts ERROR: " .. tostring(err)) end
        end
    else
        if TooManyAlts_env.mainFrame:IsShown() then
            TooManyAlts_env.mainFrame:Hide()
        else
            TooManyAlts_env.OpenMainFrame()
        end
    end
end