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
        local text = _G["TooManyAltsTooltipScanTextLeft" .. i]:GetText()
        if text then
            local track, cur, max = text:match("Upgrade Level: (%a+)%s+(%d+)/(%d+)")
            if track then
                return track, tonumber(cur), tonumber(max)
            end
        end
    end
    return nil
end

-- Assumes itemLink is already cached.
function TooManyAlts_env.getSocketCount(itemLink)
    if not itemLink then return nil end
    local numSockets = 0
    local itemInfo = C_Item.GetItemStats(itemLink)  -- ContinueOnItemLoad? We will  always call this after the itemLink is loaded already.
    if itemInfo then    --Counts number of sockets on an item
        for infoLine in pairs(itemInfo) do
            if string.find(infoLine, "EMPTY_SOCKET_") then
                numSockets = numSockets + 1
            end
        end
    end
    return numSockets
end

-- Assumes itemLink is already cached.
-- Parses gem IDs from positions 3-6 of the item data payload:
-- itemID : enchantID : gemID1 : gemID2 : gemID3 : gemID4 : ...
-- *API Note: gemID4 is unused* https://wowpedia.fandom.com/wiki/ItemLink#Gem_IDs
function TooManyAlts_env.getGemIDs(itemLink)
    local itemData = itemLink:match("|Hitem:([^|]+)|h")
    if not itemData then return {} end
    local parts = {}
    for part in (itemData .. ":"):gmatch("([^:]*):") do
        parts[#parts + 1] = part
    end
    return { parts[3], parts[4], parts[5], parts[6] }
end