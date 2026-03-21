-- UpgradeTrack.lua
-- Handles determining gear's upgrade level
local AddonName, TooManyAlts_env = ...

-- Frame used to parse tooltips
TooManyAlts_env.tooltipScan = CreateFrame("GameTooltip", "TooManyAltsTooltipScan", nil, "GameTooltipTemplate")
TooManyAlts_env.tooltipScan:SetOwner(WorldFrame, "ANCHOR_NONE")

function TooManyAlts_env.GetItemUpgradeTrack(itemLink)
    if not itemLink then return nil end
    TooManyAlts_env.tooltipScan:ClearLines()
    TooManyAlts_env.tooltipScan:SetHyperlink(itemLink)
    for i = 3, 4 do
        local text = _G["TooManyAltsScanTipTextLeft" .. i]:GetText()
        if text then
            local track, cur, max = text:match("Upgrade Level: (%a+)%s+(%d+)/(%d+)")
            if track then
                return track, tonumber(cur), tonumber(max)
            end
        end
    end
    return nil
end