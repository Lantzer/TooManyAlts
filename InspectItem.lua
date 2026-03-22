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

-- Returns number of sockets in the item, and any gems in that item.
-- If numSockets > #gemLinks, there are |numSockets - #gemLinks| unsocketed gems
function TooManyAlts_env.GetGemInfo(itemLink)
    if not itemLink then return nil end
    local numSockets = 0
    local gemLinks = {}
    local itemInfo = C_Item.GetItemStats(itemLink)  -- ContinueOnItemLoad? We will  always call this after the itemLink is loaded already.
    if itemInfo then    --Counts number of sockets on an item
        for infoLine in pairs(itemInfo) do
            if string.find(infoLine, "EMPTY_SOCKET_") then
                numSockets = numSockets + 1
            end
        end
    end
    -- Get gemLinks for # of gems in item
    if numSockets > 0 then
        for i = 1, numSockets do
            local gemName, curGem = C_Item.GetItemGem(itemLink, i) -- ContinueOnItemLoad here?
            if curGem then
                gemLinks[#gemLinks+1] = curGem
            end
        end
    end
    return numSockets, gemLinks
end