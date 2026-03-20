-- UI.lua
-- Main frame, tabs, and gear display
local AddonName, TooManyAlts_env = ...

local selectedChar = nil
local tabButtons = {}
local slotRows = {}  -- reusable slot row frames

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
    ilvlText:SetPoint("LEFT", iconBtn, "RIGHT", 4, 0)
    ilvlText:SetWidth(30)
    ilvlText:SetJustifyH("LEFT")

    local itemText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemText:SetPoint("LEFT", ilvlText, "RIGHT", 4, 0)
    itemText:SetWidth(120)
    itemText:SetJustifyH("LEFT")

    -- Store references so we can update them later
    return {
        container = container,
        iconBtn   = iconBtn,
        icon      = icon,
        ilvlText  = ilvlText,
        itemText  = itemText,
        slotID    = slotID,
    }
end

-- Updates an existing slot row with new data
local function UpdateSlotRow(row, slotData)
    local slotID = row.slotID

    if slotData and slotData.link then
        row.icon:SetTexture(slotData.itemTexture)

        row.iconBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(slotData.link)
            GameTooltip:Show()
        end)
        row.iconBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        if slotData.ilvl then
            row.ilvlText:SetText("|cffffcc00" .. slotData.ilvl .. "|r")
        else
            row.ilvlText:SetText("|cff888888--|r")
        end

        row.itemText:SetText(slotData.link)
    else
        row.icon:SetTexture(EMPTY_SLOT_TEXTURES[slotID])
        row.iconBtn:SetScript("OnEnter", nil)
        row.iconBtn:SetScript("OnLeave", nil)
        row.ilvlText:SetText("|cff888888--|r")
        row.itemText:SetText("|cff888888empty|r")
    end
end

-- Initializes all slot rows once when the frame is created
local function InitSlotRows(rightPanel)
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
end

local function ShowGearForChar(charKey)
    local data = TooManyAltsDB.characters[charKey]
    if not data then return end

    local rightPanel = TooManyAlts_env.mainFrame.rightPanel

    -- Update character header
    TooManyAlts_env.mainFrame.charHeader:SetText(
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

local function SelectCharacter(charKey)
    selectedChar = charKey

    for key, btn in pairs(tabButtons) do
        if key == charKey then
            btn:SetNormalFontObject("GameFontNormal")
            btn.bg:Show()
        else
            btn:SetNormalFontObject("GameFontNormalSmall")
            btn.bg:Hide()
        end
    end

    ShowGearForChar(charKey)
end

local function PopulateTabs()
    for _, btn in pairs(tabButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    tabButtons = {}

    local yOffset = 25
    for charKey, data in pairs(TooManyAltsDB.characters or {}) do
        local btn = CreateFrame("Button", nil, TooManyAlts_env.mainFrame.leftPanel)
        btn:SetSize(110, 30)
        btn:SetPoint("TOPLEFT", TooManyAlts_env.mainFrame.leftPanel, "TOPLEFT", 4, -yOffset)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.5, 1, 0.2)
        bg:Hide()
        btn.bg = bg

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.1)

        btn:SetNormalFontObject("GameFontNormalSmall")
        btn:SetText(TooManyAlts_env.ColorWithClass(data.class, data.name))
        btn.charKey = charKey

        btn:SetScript("OnClick", function(self)
            SelectCharacter(self.charKey)
        end)

        tabButtons[charKey] = btn
        yOffset = yOffset + 35
    end

    local firstKey = next(tabButtons)
    if firstKey then
        SelectCharacter(firstKey)
    end
end

local function CreateMainFrame()
    local f = CreateFrame("Frame", "TooManyAltsFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(600, 500)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(10)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    f.TitleText:SetText("TooManyAlts")

    local leftPanel = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
    leftPanel:SetPoint("TOPLEFT", f.InsetBg, "TOPLEFT", 4, -4)
    leftPanel:SetPoint("BOTTOMLEFT", f.InsetBg, "BOTTOMLEFT", 4, 4)
    leftPanel:SetWidth(120)
    f.leftPanel = leftPanel

    local charLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -8)
    charLabel:SetText("Characters")
    charLabel:SetTextColor(1, 0.82, 0, 1)

    local rightPanel = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0)
    rightPanel:SetPoint("BOTTOMRIGHT", f.InsetBg, "BOTTOMRIGHT", -4, 4)
    f.rightPanel = rightPanel

    -- Character header stored on frame so ShowGearForChar can update it
    local charHeader = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    charHeader:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -10)
    charHeader:SetText("")
    f.charHeader = charHeader

    -- Divider
    local divider = rightPanel:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", charHeader, "BOTTOMLEFT", 0, -6)
    divider:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -10, 0)
    divider:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    -- Initialize slot rows once
    InitSlotRows(rightPanel)

    return f
end

TooManyAlts_env.mainFrame = CreateMainFrame()

TooManyAlts_env.OpenMainFrame = function()
    PopulateTabs()
    TooManyAlts_env.mainFrame:Show()
end

-- Returns the class color as a hex string
function TooManyAlts_env.GetClassColor(class)
    local color = RAID_CLASS_COLORS[class]
    if color then
        return string.format("|cff%02x%02x%02x",
            color.r * 255,
            color.g * 255,
            color.b * 255)
    end
    return "|cffffffff"
end

-- Applies a class color to any string you pass in
function TooManyAlts_env.ColorWithClass(class, text)
    return TooManyAlts_env.GetClassColor(class) .. text .. "|r"
end