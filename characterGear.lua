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

-- slotsToSave: nil = full save (login), table of slotID→true = partial save (equipment change)
function TooManyAlts_env.saveGear(slotsToSave)
    local name = UnitName("player")
    local realm = GetRealmName()
    local charKey = name .. "-" .. realm

    -- Partial save with no existing record: fall back to full save
    if slotsToSave and not TooManyAltsDB.characters[charKey] then
        TooManyAlts_env.saveGear(nil)
        return
    end

    local function writeToDatabase(gear)
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
            writeToDatabase(gear)
        end
    end

    -- 
    local function processSlot(slotID)
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            pending = pending + 1
            local item = Item:CreateFromItemLink(itemLink) -- Ensures item is in cache so that below functions don't return nil during async calls.
            item:ContinueOnItemLoad(function()
                local _, _, _, ilvl, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemLink)
                local track, cur, max = TooManyAlts_env.GetItemUpgradeTrack(itemLink)
                local numSockets = TooManyAlts_env.getSocketCount(itemLink)
                local gemLinks = {}
                -- store items gems item links in list. Don't save gear until all gems are loaded into gemLinks table
                if numSockets > 0 then
                    local gemIDs = TooManyAlts_env.getGemIDs(itemLink)
                    for i = 1, numSockets do
                        local gemID = tonumber(gemIDs[i])
                        if gemID then
                            pending = pending + 1
                            local gemItem = Item:CreateFromItemID(gemID)
                            gemItem:ContinueOnItemLoad(function()
                                gemLinks[#gemLinks + 1] = gemItem:GetItemLink()
                                pending = pending - 1
                                tryWrite()
                            end)
                        end
                    end
                end
                gear[slotID] = { link = itemLink, itemTexture = itemTexture, ilvl = ilvl, upgradeTrack = track, upgradeCur = cur, upgradeMax = max, numSockets = numSockets, gemLinks = gemLinks}
                pending = pending - 1
                tryWrite() --inside callback function because of async, so that it is only triggered when the last item is done loading.
            end)
        else -- if no item is equipped
            gear[slotID] = { link = nil, itemTexture = nil, ilvl = nil, upgradeTrack = nil, upgradeCur = nil, upgradeMax = nil, numSockets = nil, gemLinks = nil}
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

local saveTimer = nil -- If we save multiple pieces of gear within .4 seconds of eachother, we wait to call SaveGear until after .5 seconds pass since we changed an item
function TooManyAlts_env.scheduleSaveGear(changedSlots)
    if saveTimer then
        saveTimer:Cancel()
    end
    saveTimer = C_Timer.NewTimer(0.5, function()
        saveTimer = nil
        local snapshot = changedSlots
        changedSlots = {}
        local ok, err = pcall(TooManyAlts_env.saveGear, snapshot)
        if not ok then
            print("TooManyAlts ERROR: " .. tostring(err))
        end
    end)
end
