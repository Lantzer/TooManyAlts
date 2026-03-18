-- Minimap.lua
-- Minimap button using LibDBIcon
local AddonName, TooManyAlts_env = ...

local minimapIcon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1")

local TooManyAltsLDB = LDB:NewDataObject("TooManyAlts", {
    type = "data source",
    text = "TooManyAlts",
    icon = "Interface\\Icons\\INV_Misc_Bag_07",

    OnClick = function(_, buttonName)
        if buttonName == "LeftButton" then
            if TooManyAlts_env.mainFrame:IsShown() then
                TooManyAlts_env.mainFrame:Hide()
            else
                TooManyAlts_env.OpenMainFrame()
            end
        end
    end,

    OnTooltipShow = function(tooltip)
        if not tooltip then return end
        tooltip:AddLine("TooManyAlts", 1, 0.82, 0, 1)
        tooltip:AddLine(" ")

        if not TooManyAltsDB or not TooManyAltsDB.characters or not next(TooManyAltsDB.characters) then
            tooltip:AddLine("No max level characters saved yet.", 1, 1, 1)
        else
            for charKey, data in pairs(TooManyAltsDB.characters) do
                if data.level == TooManyAlts_env.MAX_LEVEL then
                    tooltip:AddDoubleLine(
                        TooManyAlts_env.ColorWithClass(data.class, data.name .. "-" .. data.realm),
                        "Ilvl:" .. data.avgIlvl,
                        1, 1, 1,
                        1, 0.82, 0
                    )
                end
            end
        end
    end,
})

-- Called from Core.lua's Init() after DB is ready
function TooManyAlts_env.InitMinimap() 
    -- Initialize the minimap button
    minimapIcon:Register("TooManyAlts", TooManyAltsLDB, TooManyAltsDB.minimap)
    minimapIcon:Show("TooManyAlts")
end