-- UI_MythicPlus.lua
-- Mythic+ tab: full-width card overview of all characters' M+ data.
-- Each character gets one card showing their current key, Great Vault progress,
-- and season-best per dungeon. Falls back to "--" until a data layer exists.
local AddonName, TooManyAlts_env = ...

local CARD_HEIGHT  = 60
local CARD_PADDING = 6
local DUNGEON_W    = 48
local DUNGEON_H    = 36
local KEY_W        = 30
local KEY_H        = 30
local NAME_BLOCK_W = 80   -- width reserved for name + rating on the left
local RATE_BLOCK_W = 45
local NUM_DUNGEONS = 8

-- List of current season dungeons
local mapId = {239, 161, 560, 557, 556, 402, 558, 559}

local dungeonData = {
    {shortName = "SEAT", },
    {shortName = "SKY ", },
    {shortName = "MAIS", },
    {shortName = "WIND", },
    {shortName = "PIT ", },
    {shortName = "ACAD", },
    {shortName = "MAGI", },
    {shortName = "NEXU", },
}

for i in dungeonData do
    dungeonData.data = C_ChallengeMode.GetMapUIInfo(i.mapId)
end


-- ---------------------------------------------------------------------------
-- CreateDungeonBox
-- Reusable widget: dungeon artwork bg + dark overlay + centered level text.
-- Tooltip shows dungeon name when the caller sets box.dungeonName.
-- ---------------------------------------------------------------------------
local function CreateDungeonBox(parent, w, h, dungeonData)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(w, h)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if dungeonData then
        local _,_,_,texture,_ = C_ChallengeMode.GetMapUIInfo(dungeonData.mapId)
        bg:SetTexture(texture or 134400) -- test

    end

    local overlay = frame:CreateTexture(nil, "BORDER")
    overlay:SetAllPoints()
    overlay:SetColorTexture(0, 0, 0, 0.5)

    local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    levelText:SetText("--")

    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if self.dungeonName then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.dungeonName)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return { frame = frame, bg = bg, overlay = overlay, levelText = levelText }
end

-- ---------------------------------------------------------------------------
-- CreateCharCard
-- One card per character. All children are created and positioned once.
-- Layout (left to right, all vertically centered):
--   [name / rating]  [keyBox]  [gvTxt]  [dungeonBoxes 1..8]
-- ---------------------------------------------------------------------------
local function CreateCharCard(parent)
    local frame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    frame:SetHeight(CARD_HEIGHT)

    -- Name + rating stacked on the left
    local nameTxt = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameTxt:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -5)
    nameTxt:SetWidth(NAME_BLOCK_W)
    nameTxt:SetJustifyH("LEFT")

    local ratingTxt = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ratingTxt:SetPoint("TOPLEFT", nameTxt, "BOTTOMLEFT", 0, -4)
    ratingTxt:SetWidth(RATE_BLOCK_W)
    ratingTxt:SetJustifyH("LEFT")

    -- Current keystone box
    local keyBox = CreateDungeonBox(frame, KEY_W, KEY_H)
    keyBox.frame:SetPoint("LEFT", frame, "LEFT", RATE_BLOCK_W + 10, -8)

    -- Great Vault fraction (e.g. "3/8")
    local gvTxt = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gvTxt:SetPoint("TOPLEFT", ratingTxt, "BOTTOMLEFT", 0, -4)
    gvTxt:SetWidth(RATE_BLOCK_W)
    gvTxt:SetJustifyH("LEFT")

    -- 8 season-best dungeon boxes in a row
    local dungeonBoxes = {}
    local xStart = RATE_BLOCK_W + KEY_W + 25  -- after name + keyBox + gvTxt gap
    for _,mapId ipairs(dungeonData) do
        local box = CreateDungeonBox(frame, DUNGEON_W, DUNGEON_H, dungeonData)
        box.frame:SetPoint("LEFT", frame, "LEFT", xStart + (i - 1) * (DUNGEON_W + 4), 0)
        dungeonBoxes[i] = box
    end

    return {
        frame       = frame,
        nameTxt     = nameTxt,
        ratingTxt   = ratingTxt,
        gvTxt       = gvTxt,
        keyBox      = keyBox,
        dungeonBoxes = dungeonBoxes,
    }
end

-- ---------------------------------------------------------------------------
-- UpdateCharCard
-- Fills a card with live data. Falls back to "--" / no texture when
-- data.mythicplus is nil (data layer not yet implemented).
-- ---------------------------------------------------------------------------
local function UpdateCharCard(card, charKey, data)
    local mp = data.mythicplus  -- may be nil

    -- Name and rating
    card.nameTxt:SetText(TooManyAlts_env.ColorWithClass(data.class, data.name))
    -- card.ratingTxt:SetText(mp and tostring(mp.rating) or "|cff888888--|r")
    card.ratingTxt:SetText(mp and tostring(mp.rating) or "|cff8888882403|r")
    
    -- Great Vault
    -- card.gvTxt:SetText(mp and (mp.greatVault.completed .. "/8") or "|cff888888--|r")
    card.gvTxt:SetText(mp and (mp.greatVault.completed .. "/8") or "|cff8888883/8|r")

    -- Current keystone box
    if mp and mp.currentKey then
        card.keyBox.levelText:SetText("|cffffcc00+" .. mp.currentKey.level .. "|r")
        card.keyBox.frame.dungeonName = mp.currentKey.mapName
    else
        -- card.keyBox.bg:SetTexture(nil)
        card.keyBox.levelText:SetText("|cff888888--|r")
        card.keyBox.frame.dungeonName = nil
    end

    -- Season-best dungeon boxes in season order
    local mapTable = C_ChallengeMode.GetMapTable() or {}
    for i = 1, NUM_DUNGEONS do
        local box = card.dungeonBoxes[i]
        local mapID = mapTable[i]
        local best = mp and mapID and mp.seasonBests and mp.seasonBests[mapID]

        if best then
            local color = best.timed and "|cffffcc00" or "|cffff4444"
            box.levelText:SetText(color .. "+" .. best.level .. "|r")
            box.frame.dungeonName = best.mapName or nil
        else
            -- box.bg:SetTexture(nil)
            box.levelText:SetText("|cff888888--|r")
            box.frame.dungeonName = nil

        end
    end
end

-- ---------------------------------------------------------------------------
-- PopulateCards
-- Creates cards once per character, updates all on each call.
-- Sorts characters alphabetically by name, repositions cards, sets scroll height.
-- ---------------------------------------------------------------------------
local function PopulateCards(scrollChild, cards)
    -- Create a card for any character not yet seen
    for charKey, data in pairs(TooManyAltsDB.characters or {}) do
        if not cards[charKey] then
            cards[charKey] = CreateCharCard(scrollChild)
        end
    end

    -- Sort charKeys alphabetically by character name
    local sorted = {}
    for charKey, data in pairs(TooManyAltsDB.characters or {}) do
        sorted[#sorted + 1] = charKey
    end
    table.sort(sorted, function(a, b)
        return TooManyAltsDB.characters[a].name < TooManyAltsDB.characters[b].name
    end)

    -- Reposition and update each card
    local yOffset = CARD_PADDING
    for _, charKey in ipairs(sorted) do
        local card = cards[charKey]
        local data = TooManyAltsDB.characters[charKey]

        card.frame:ClearAllPoints()
        card.frame:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  4, -yOffset)
        card.frame:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, -yOffset)
        card.frame:Show()

        UpdateCharCard(card, charKey, data)
        yOffset = yOffset + CARD_HEIGHT + CARD_PADDING
    end

    scrollChild:SetHeight(math.max(yOffset, 1))
end

-- ---------------------------------------------------------------------------
-- Tab registration
-- Full content area — no side panel.
-- ---------------------------------------------------------------------------
TooManyAlts_env.RegisterTab("mythicplus", "Mythic+", function(parent)
    local f = CreateFrame("Frame", nil, parent)

    local inset = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT",     f, "TOPLEFT",      4, -4)
    inset:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4,  4)

    local scrollFrame = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     inset, "TOPLEFT",      4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -26,  4)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Width is unknown at creation time; OnSizeChanged fires when the frame is first laid out
    scrollFrame:SetScript("OnSizeChanged", function(self, width)
        scrollChild:SetWidth(width)
    end)

    local cards = {}  -- charKey -> card (created once, updated on each show)

    f:SetScript("OnShow", function()
        PopulateCards(scrollChild, cards)
    end)

    return f
end)
