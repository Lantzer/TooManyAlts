-- UI.lua
-- Main frame and top-level tab system
local AddonName, TooManyAlts_env = ...

local registeredTabs = {}  -- array of { name, label, createFn }
local contentPanels  = {}  -- name -> content frame
local topTabButtons  = {}  -- name -> button
local activeTabName  = nil
local tabBarBuilt    = false

-- Registers a top-level tab. createFn(parent) must return a Frame.
-- Set OnShow on the returned frame to handle any populate/refresh logic.
-- Called by each UI_*.lua file at load time, before the frame is built.
function TooManyAlts_env.RegisterTab(name, label, createFn)
    assert(type(name)     == "string",   "RegisterTab: name must be a string")
    assert(type(label)    == "string",   "RegisterTab: label must be a string")
    assert(type(createFn) == "function", "RegisterTab: createFn must be a function")
    table.insert(registeredTabs, {name=name, label=label, createFn=createFn})
end

local function SwitchToTab(name)
    if activeTabName == name then return end
    if activeTabName then
        contentPanels[activeTabName]:Hide()
        topTabButtons[activeTabName].activeLine:Hide()
    end
    activeTabName = name
    contentPanels[name]:Show()
    topTabButtons[name].activeLine:Show()
end

-- Built lazily on first OpenMainFrame call so all RegisterTab calls have run.
local function BuildTabSystem()
    if tabBarBuilt then return end
    tabBarBuilt = true

    local f = TooManyAlts_env.mainFrame
    local tabBarHeight = 28

    -- Tab bar strip anchored to the top of the inset area
    local tabBar = CreateFrame("Frame", nil, f)
    tabBar:SetPoint("TOPLEFT",  f.InsetBg, "TOPLEFT",  0, 0)
    tabBar:SetPoint("TOPRIGHT", f.InsetBg, "TOPRIGHT", 0, 0)
    tabBar:SetHeight(tabBarHeight)

    -- Thin separator line under the tab bar
    local sep = tabBar:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT",  tabBar, "BOTTOMLEFT",  0, 0)
    sep:SetPoint("BOTTOMRIGHT", tabBar, "BOTTOMRIGHT", 0, 0)
    sep:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    -- Content area fills the space below the tab bar
    local contentArea = CreateFrame("Frame", nil, f)
    contentArea:SetPoint("TOPLEFT",     f.InsetBg, "TOPLEFT",     0, -tabBarHeight)
    contentArea:SetPoint("BOTTOMRIGHT", f.InsetBg, "BOTTOMRIGHT", 0,  0)

    -- Build one button and one content panel per registered tab
    local xOffset = 4
    for _, tab in ipairs(registeredTabs) do
        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(90, tabBarHeight)
        btn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOffset, 0)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetText(tab.label)

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.1)

        -- Gold underline shown on the active tab
        local activeLine = btn:CreateTexture(nil, "ARTWORK")
        activeLine:SetHeight(2)
        activeLine:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  2, 0)
        activeLine:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
        activeLine:SetColorTexture(1, 0.82, 0, 1)
        activeLine:Hide()
        btn.activeLine = activeLine

        local tabName = tab.name
        btn:SetScript("OnClick", function() SwitchToTab(tabName) end)
        topTabButtons[tab.name] = btn

        local panel = tab.createFn(contentArea)
        assert(type(panel) == "table", tab.name .. ": createFn must return a Frame")

        panel:SetAllPoints(contentArea)
        panel:Hide()
        contentPanels[tab.name] = panel

        xOffset = xOffset + 94
    end

    -- Show the first registered tab by default
    if #registeredTabs > 0 then
        SwitchToTab(registeredTabs[1].name)
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
    return f
end

TooManyAlts_env.mainFrame = CreateMainFrame()
tinsert(UISpecialFrames, "TooManyAltsFrame")

TooManyAlts_env.OpenMainFrame = function()
    BuildTabSystem()
    -- Re-trigger OnShow on the active panel so it repopulates its data
    if activeTabName and contentPanels[activeTabName] then
        contentPanels[activeTabName]:Hide()
        contentPanels[activeTabName]:Show()
    end
    TooManyAlts_env.mainFrame:Show()
end

-- ---------------------------------------------------------------------------
-- Reusable side character tab layout
--
-- Creates a left character list panel and a right content area, then calls
-- buildContent(rightPanel) once so the caller can populate the right side.
-- buildContent must return onSelect(charKey), which the layout calls whenever
-- the selected character changes.
--
-- Returns { populate } where populate() rebuilds the character button list
-- from TooManyAltsDB and auto-selects a character (restoring the previous
-- selection if it still exists, otherwise defaulting to the first entry).
-- ---------------------------------------------------------------------------
--optional show under max level char
function TooManyAlts_env.CreateSideCharacterTabLayout(parent, buildContent, maxLevelOnly)
    local charButtons  = {}
    local selectedChar = nil
    local onSelect     = nil  -- set after buildContent runs

    -- Container frame so BuildTabSystem can anchor/show/hide without self-anchoring
    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints(parent)

    -- Left panel: character list
    local leftPanel = CreateFrame("Frame", nil, container, "InsetFrameTemplate")
    leftPanel:SetPoint("TOPLEFT",    container, "TOPLEFT",    4, -4)
    leftPanel:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 4,  4)
    leftPanel:SetWidth(120)

    local charLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -8)
    charLabel:SetText("Characters")
    charLabel:SetTextColor(1, 0.82, 0, 1)

    -- Right panel: owned entirely by the caller via buildContent
    local rightPanel = CreateFrame("Frame", nil, container, "InsetFrameTemplate")
    rightPanel:SetPoint("TOPLEFT",     leftPanel,  "TOPRIGHT",     4, 0)
    rightPanel:SetPoint("BOTTOMRIGHT", container,  "BOTTOMRIGHT", -4, 4)

    -- Hand the right panel to the caller; get back their onSelect handler
    onSelect = buildContent(rightPanel)

    local function SelectCharacter(charKey)
        selectedChar = charKey

        for key, btn in pairs(charButtons) do
            if key == charKey then
                btn:SetNormalFontObject("GameFontNormal")
                btn.bg:Show()
            else
                btn:SetNormalFontObject("GameFontNormalSmall")
                btn.bg:Hide()
            end
        end

        onSelect(charKey)
    end

    -- Rebuilds the character button list from TooManyAltsDB.
    -- Restores the previous selection when possible; otherwise picks the first entry.
    local function populate()
        for _, btn in pairs(charButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        charButtons = {}

        local yOffset = 25
        for charKey, data in pairs(TooManyAltsDB.characters or {}) do
            if not maxLevelOnly == true or data.level >= TooManyAlts_env.MAX_LEVEL then
                local btn = CreateFrame("Button", nil, leftPanel)
                btn:SetSize(110, 30)
                btn:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 4, -yOffset)

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


            charButtons[charKey] = btn
            yOffset = yOffset + 35
            end
        end

        -- Restore previous selection or fall back to the first entry
        local keyToSelect = (selectedChar and charButtons[selectedChar]) and selectedChar or next(charButtons)
        if keyToSelect then
            SelectCharacter(keyToSelect)
        end
    end

    return { frame = container, populate = populate }
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
