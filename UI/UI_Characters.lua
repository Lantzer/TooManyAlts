-- UI_Characters.lua
-- Characters tab: per-character gear display
local AddonName, TooManyAlts_env = ...

-- Two column slot layout mirroring the character pane
local LEFT_SLOTS  = { 1, 2, 3, 15, 5, 9, 16, 17}
local RIGHT_SLOTS = { 10, 6, 7, 8, 11, 12, 13, 14}

local EMPTY_SLOT_TEXTURES = {
    [1]  = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Head",
    [2]  = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Neck",
    [3]  = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Shoulder",
    [5]  = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Chest",
    [6]  = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Waist",
    [7]  = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Legs",
    [8]  = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Feet",
    [9]  = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Wrist",
    [10] = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Hands",
    [11] = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Finger",
    [12] = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Finger",
    [13] = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Trinket",
    [14] = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Trinket",
    [15] = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-Back",
    [16] = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-MainHand",
    [17] = "Interface\\PaperDollInfoFrame\\UI-PaperDoll-Slot-SecondaryHand",
}

-- Creates a slot row once and stores references to its components
local function CreateSlotRow(parent, slotID, xOffset, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 32)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -yOffset)

    local iconBtn = CreateFrame("Button", nil, container)
    iconBtn:SetSize(26, 26)
    iconBtn:SetPoint("LEFT", container, "LEFT", 0, 0)
    iconBtn:SetFrameLevel(parent:GetFrameLevel() + 2)

    local icon = iconBtn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()

    local ilvlText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ilvlText:SetPoint("LEFT", container, "LEFT", 28, 0)
    ilvlText:SetWidth(30) -- right side = 58/200 total width
    ilvlText:SetJustifyH("CENTER")

    local upgradeText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    upgradeText:SetPoint("TOPLEFT", container, "TOPLEFT", 60, 0)
    upgradeText:SetWidth(140)
    upgradeText:SetHeight(container:GetHeight()/2)
    upgradeText:SetJustifyH("LEFT")

    local gemIcons = {}
    for i = 1, 4 do
        local gemIcon = CreateFrame("Frame", nil, container)
        gemIcon:SetSize(14, 14)
        gemIcon:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 60 + (i - 1) * 16, 1)
        local gemTex = gemIcon:CreateTexture(nil, "ARTWORK")
        gemTex:SetAllPoints()
        gemTex:SetTexture("Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
        gemIcon.tex = gemTex
        gemIcon:Hide()
        gemIcons[i] = gemIcon
    end

    -- Store references so we can update them later
    return {
        container   = container,
        iconBtn     = iconBtn,
        icon        = icon,
        ilvlText    = ilvlText,
        upgradeText = upgradeText,
        gemIcons    = gemIcons,
        slotID      = slotID,
    }
end

-- Each item frame has hidden gem icons, we show as many as the items has sockets. We fill in any sockets with the items gem links
local function ResetGemIcon(gemIcon)
    gemIcon.tex:SetTexture("Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
    gemIcon:EnableMouse(false)
    gemIcon:SetScript("OnEnter", nil)
    gemIcon:SetScript("OnLeave", nil)
end

local function SetGemIcon(gemIcon, gemLink)
    local gemItem = Item:CreateFromItemLink(gemLink)
    gemItem:ContinueOnItemLoad(function()
        gemIcon.tex:SetTexture(gemItem:GetItemIcon())
        gemIcon:EnableMouse(true)
        gemIcon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(gemLink)
            GameTooltip:Show()
        end)
        gemIcon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end)
end

-- Updates an existing slot row with new data
local function UpdateSlotRow(row, slotData)
    local slotID = row.slotID

    if slotData and slotData.link then

        -- texture
        row.icon:SetTexture(slotData.itemTexture)

        -- display item tooltip
        row.iconBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(slotData.link)
            GameTooltip:Show()
        end)
        row.iconBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- ilvl text
        if slotData.ilvl then
            row.ilvlText:SetText("|cffffcc00" .. slotData.ilvl .. "|r")
        else
            row.ilvlText:SetText("|cff888888--|r")
        end

        -- item upgrade info
        if slotData.upgradeTrack then
            row.upgradeText:SetText("|cffffcc00" .. slotData.upgradeTrack .. " " .. slotData.upgradeCur .. "/" .. slotData.upgradeMax .. "|r")
        else
            row.upgradeText:SetText("|cff888888--|r")
        end

        -- item gem info
        if slotData.numSockets > 0 then
            -- displays the valid # of gem sockets + clears old data
            for num = 1, slotData.numSockets do
                ResetGemIcon(row.gemIcons[num])
                row.gemIcons[num]:Show()
            end

            -- sets each icon with new data
            for gem = 1, #slotData.gemLinks do
                SetGemIcon(row.gemIcons[gem], slotData.gemLinks[gem])
            end
        else    -- if no gems hide the icons
            for i = 1, #row.gemIcons do
                row.gemIcons[i]:Hide()
            end
        end

    else -- no item
        row.icon:SetTexture(EMPTY_SLOT_TEXTURES[slotID])
        row.iconBtn:SetScript("OnEnter", nil)
        row.iconBtn:SetScript("OnLeave", nil)
        for i = 1, 4 do
            row.gemIcons[i]:Hide()
        end
        row.ilvlText:SetText("|cff888888--|r")
        row.upgradeText:SetText("|cff888888empty|r")
    end
end

-- Initializes all slot rows once when the frame is created
local function InitSlotRows(rightPanel)
    local slotRows = {}

    local leftYOffset = 35
    for _, slotID in ipairs(LEFT_SLOTS) do
        slotRows[slotID] = CreateSlotRow(rightPanel, slotID, 10, leftYOffset)
        leftYOffset = leftYOffset + 32
    end

    local rightYOffset = 35
    for _, slotID in ipairs(RIGHT_SLOTS) do
        slotRows[slotID] = CreateSlotRow(rightPanel, slotID, 220, rightYOffset)
        rightYOffset = rightYOffset + 32
    end

    return slotRows
end

-- ---------------------------------------------------------------------------
-- Characters tab registration
-- ---------------------------------------------------------------------------

TooManyAlts_env.RegisterTab("characters", "Characters", function(parent)
    local layout = TooManyAlts_env.CreateSideCharacterTabLayout(parent, function(rightPanel) -- this function is BuildContent from CreateSideCharacterTabLayout
        -- Build the gear view into rightPanel once, then return onSelect

        local charHeader = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        charHeader:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -10)
        charHeader:SetText("")

        -- Divider
        local divider = rightPanel:CreateTexture(nil, "ARTWORK")
        divider:SetHeight(1)
        divider:SetPoint("TOPLEFT",  charHeader, "BOTTOMLEFT",  0,  -6)
        divider:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT",   -10,  0)
        divider:SetColorTexture(0.3, 0.3, 0.3, 0.8)

        -- Initialize slot rows once
        local slotRows = InitSlotRows(rightPanel)

        -- Called by the layout whenever the selected character changes
        return function(charKey)
            local data = TooManyAltsDB.characters[charKey]
            if not data then return end

            -- Update character header
            charHeader:SetText(
                TooManyAlts_env.ColorWithClass(data.class, data.name) ..
                string.format(" |cffffcc00avg ilvl: %.1f (%.1f)|r", data.avgItemLvlEquip, data.avgItemLvl)
            )

            -- Update all slot rows
            for _, slotID in ipairs(LEFT_SLOTS) do
                UpdateSlotRow(slotRows[slotID], data.gear[slotID])
            end
            for _, slotID in ipairs(RIGHT_SLOTS) do
                UpdateSlotRow(slotRows[slotID], data.gear[slotID])
            end
        end
    end)

    layout.frame:SetScript("OnShow", layout.populate)
    return layout.frame
end)
