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

    else
        if TooManyAlts_env.mainFrame:IsShown() then
            TooManyAlts_env.mainFrame:Hide()
        else
            TooManyAlts_env.OpenMainFrame()
        end
    end
end