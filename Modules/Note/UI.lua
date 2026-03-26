local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core         = RRT_NS.UI.Core
local window_width  = Core.window_width
local window_height = Core.window_height

local SIDEBAR_WIDTH     = 130
local SIDEBAR_ITEM_HEIGHT = 20
local SIDEBAR_PADDING   = 4

-- ─────────────────────────────────────────────────────────────────────────────
-- BuildNoteUI — sidebar + content area, same pattern as Raid tab
-- Sections: Create Note | Send Note | Save Note | Readme
-- ─────────────────────────────────────────────────────────────────────────────

local function MakeSections()
    return {
        { name = "Create Note", key = "createnote" },
        { name = "Send Note",   key = "sendnote"   },
        { name = "Save Note",   key = "savenote"   },
        { name = "Readme",      key = "readme"      },
    }
end

local function BuildNoteUI(parent)
    local SECTIONS = MakeSections()

    -- Breadcrumb label
    local breadcrumb = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    breadcrumb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -76)
    breadcrumb:SetText("|cFFBB66FF" .. SECTIONS[1].name .. "|r")

    -- Sidebar background
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",    parent, "TOPLEFT",    4, -100)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4,  22)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    -- Content area
    local contentArea = CreateFrame("Frame", nil, parent)
    contentArea:SetPoint("TOPLEFT",     parent, "TOPLEFT",     SIDEBAR_WIDTH + 8, -100)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4,                 22)

    -- One panel per section
    local panels = {}
    for _, section in ipairs(SECTIONS) do
        local panel = CreateFrame("Frame", "RRTNoteSection_" .. section.key, contentArea)
        panel:SetAllPoints(contentArea)
        panel:Hide()
        panels[section.key] = panel
    end

    -- Send Note — CDNote panel
    if RRT_NS.UI.BuildCDNotePanel then
        RRT_NS.UI.BuildCDNotePanel(panels["sendnote"])
    end

    -- Readme — MRTMemo panel
    if RRT_NS.UI.BuildMRTMemoPanel then
        RRT_NS.UI.BuildMRTMemoPanel(panels["readme"])
    end

    -- Create Note
    if RRT_NS.UI.BuildCreateNotePanel then
        RRT_NS.UI.BuildCreateNotePanel(panels["createnote"])
    end

    -- Save Note
    if RRT_NS.UI.BuildSaveNotePanel then
        RRT_NS.UI.BuildSaveNotePanel(panels["savenote"])
    end

    -- Sidebar button selection logic
    local activeButton = nil
    local currentSectionName = SECTIONS[1].name
    local sidebarBtns = {}   -- keyed by section.key

    local function SelectSection(key, btn, sectionName)
        for k, p in pairs(panels) do p:SetShown(k == key) end
        if activeButton then
            activeButton:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            activeButton:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
        end
        local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        btn:SetBackdropColor(c[1]*0.4, c[2]*0.4, c[3]*0.4, 0.8)
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        activeButton = btn
        currentSectionName = sectionName
        local hex = string.format("%02X%02X%02X",
            math.floor(c[1]*255+0.5), math.floor(c[2]*255+0.5), math.floor(c[3]*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. sectionName .. "|r")
    end

    for i, section in ipairs(SECTIONS) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(SIDEBAR_WIDTH - SIDEBAR_PADDING * 2, SIDEBAR_ITEM_HEIGHT)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT",
            SIDEBAR_PADDING, -(SIDEBAR_PADDING + (i - 1) * (SIDEBAR_ITEM_HEIGHT + 4)))
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then btnText:SetFont(f, 9, fl or "") end end
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(section.name)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)

        local key  = section.key
        local name = section.name
        sidebarBtns[key] = btn
        btn:SetScript("OnClick", function(self) SelectSection(key, self, name) end)
        btn:SetScript("OnEnter", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end
        end)

        if i == 1 then SelectSection(key, btn, name) end
    end

    -- Programmatic navigation (used by CreateNote "Send Note" button)
    RRT_NS.UI.Note = RRT_NS.UI.Note or {}
    RRT_NS.UI.Note.NavigateToSection = function(key)
        local btn  = sidebarBtns[key]
        local name = ""
        for _, s in ipairs(SECTIONS) do if s.key == key then name = s.name break end end
        if btn then SelectSection(key, btn, name) end
    end

    -- Theme color callback
    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
        if activeButton then
            activeButton:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
            activeButton:SetBackdropBorderColor(r, g, b, 1)
        end
        local hex = string.format("%02X%02X%02X",
            math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. currentSectionName .. "|r")
    end)

    return panels
end

-- Export
RRT_NS.UI      = RRT_NS.UI or {}
RRT_NS.UI.Note = RRT_NS.UI.Note or {}
RRT_NS.UI.Note.BuildNoteUI = BuildNoteUI
