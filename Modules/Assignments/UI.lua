local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core = RRT_NS.UI.Core
local window_height          = Core.window_height
local options_text_template      = Core.options_text_template
local options_dropdown_template  = Core.options_dropdown_template
local options_switch_template    = Core.options_switch_template
local options_slider_template    = Core.options_slider_template
local options_button_template    = Core.options_button_template
local L = RRT_NS.L

local SIDEBAR_WIDTH    = 130
local SIDEBAR_PADDING  = 4
local SIDEBAR_ITEM_H   = 20

local function BuildAssignmentsUI(parent)
    local Opt = RRT_NS.UI.Options.Assignments

    -- Breadcrumb
    local breadcrumb = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    breadcrumb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -76)

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",    parent, "TOPLEFT",    4, -100)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4,   22)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    -- Content area
    local contentArea = CreateFrame("Frame", nil, parent)
    contentArea:SetPoint("TOPLEFT",     parent, "TOPLEFT",     SIDEBAR_WIDTH + 8, -100)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4,                  22)

    local SECTIONS = {
        { name = L["raid_general"],  key = "general"  },
        { name = L["raid_midnight"], key = "midnight" },
    }

    -- Content panels
    local panels = {}
    for _, section in ipairs(SECTIONS) do
        local panel = CreateFrame("Frame", "RRTAssignSection_" .. section.key, contentArea)
        panel:SetAllPoints(contentArea)
        panel:Hide()
        panels[section.key] = panel
    end

    -- Build General panel
    local menuH = window_height - 10
    DF:BuildMenu(panels["general"], Opt.BuildGeneralOptions(), 10, -10, menuH, false,
        options_text_template, options_dropdown_template, options_switch_template,
        true, options_slider_template, options_button_template, Opt.BuildCallback())

    -- Build Midnight panel
    DF:BuildMenu(panels["midnight"], Opt.BuildMidnightOptions(), 10, -10, menuH, false,
        options_text_template, options_dropdown_template, options_switch_template,
        true, options_slider_template, options_button_template, Opt.BuildCallback())

    -- Sidebar buttons
    local activeButton = nil
    local currentSectionName = SECTIONS[1].name

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
        btn:SetSize(SIDEBAR_WIDTH - SIDEBAR_PADDING * 2, SIDEBAR_ITEM_H)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT",
            SIDEBAR_PADDING, -(SIDEBAR_PADDING + (i - 1) * (SIDEBAR_ITEM_H + 4)))
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(section.name)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)

        local key         = section.key
        local sectionName = section.name
        btn:SetScript("OnClick", function(self) SelectSection(key, self, sectionName) end)
        btn:SetScript("OnEnter", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end
            btnText:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end
            btnText:SetTextColor(0.9, 0.9, 0.9, 1)
        end)

        if i == 1 then SelectSection(key, btn, sectionName) end
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
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Assignments = {
    BuildAssignmentsUI = BuildAssignmentsUI,
}
