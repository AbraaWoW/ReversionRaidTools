local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core = RRT_NS.UI.Core
local RRTUI = Core.RRTUI
local window_width = Core.window_width
local window_height = Core.window_height
local options_text_template = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template = Core.options_switch_template
local options_slider_template = Core.options_slider_template
local options_button_template = Core.options_button_template
local L = RRT_NS.L

local SIDEBAR_WIDTH = 130
local SIDEBAR_ITEM_HEIGHT = 20
local SIDEBAR_PADDING = 4
local CONTENT_X = SIDEBAR_WIDTH + 10

local SUB_BTN_HEIGHT = 20
local SUB_BTN_WIDTH = 110
local SUB_BTN_PAD = 4

local function MakeSections()
    return {
        { name = L["raid_general"],    key = "general"      },
        { name = "Raid Inspect",       key = "raidinspect"  },
        { name = "Raid Groups",        key = "raidgroups"   },
        { name = L["raid_midnight"],   key = "midnight"     },
    }
end

local function BuildSubNav(parent, subDefs, onSelect)
    local subPanels = {}
    local subActive = nil

    local function SelectSub(key, btn)
        for k, p in pairs(subPanels) do p:SetShown(k == key) end
        if subActive then
            subActive:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            subActive:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
        end
        local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        btn:SetBackdropColor(c[1]*0.4, c[2]*0.4, c[3]*0.4, 0.8)
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        subActive = btn
        if onSelect then onSelect(key) end
    end

    for i, def in ipairs(subDefs) do
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(SUB_BTN_WIDTH, SUB_BTN_HEIGHT)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", SUB_BTN_PAD + (i - 1) * (SUB_BTN_WIDTH + 4), -SUB_BTN_PAD)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then label:SetFont(f, 9, fl or "") end end
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        label:SetText(def.name)
        label:SetTextColor(0.9, 0.9, 0.9, 1)

        local subPanel = CreateFrame("Frame", "RRTRaidGenSub_" .. def.key, parent)
        subPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(SUB_BTN_HEIGHT + SUB_BTN_PAD * 2 + 4))
        subPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
        subPanel:Hide()
        subPanels[def.key] = subPanel

        local key = def.key
        btn:SetScript("OnClick", function(self) SelectSub(key, self) end)
        btn:SetScript("OnEnter", function(self)
            if subActive ~= self then self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end
        end)
        btn:SetScript("OnLeave", function(self)
            if subActive ~= self then self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end
        end)

        if i == 1 then SelectSub(key, btn) end
    end

    -- Register theme color callback for this sub-nav's active button
    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
        if subActive then
            subActive:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
            subActive:SetBackdropBorderColor(r, g, b, 1)
        end
    end)

    return subPanels
end

local function BuildGeneralContent(panel)
    local subMenuHeight = window_height - SUB_BTN_HEIGHT - SUB_BTN_PAD * 2 - 4 - 10

    local subDefs = {
        { name = L["raid_reminders"],      key = "reminders"      },
        { name = L["raid_reminders_note"], key = "reminders_note" },
        { name = L["midnight_setup"],      key = "setupmanager"   },
        { name = L["tab_ready_check"],     key = "readycheck"     },
    }

    local subPanels = BuildSubNav(panel, subDefs)

    local Opt   = RRT_NS.UI.Options.Reminders
    local OptSM = RRT_NS.UI.Options.SetupManager
    local OptRC = RRT_NS.UI.Options.ReadyCheck
    DF:BuildMenu(subPanels["reminders"], Opt.BuildOptions(), 10, -10, subMenuHeight, false,
        options_text_template, options_dropdown_template, options_switch_template,
        true, options_slider_template, options_button_template, Opt.BuildCallback())
    DF:BuildMenu(subPanels["reminders_note"], Opt.BuildNoteOptions(), 10, -10, subMenuHeight, false,
        options_text_template, options_dropdown_template, options_switch_template,
        true, options_slider_template, options_button_template, Opt.BuildNoteCallback())
    DF:BuildMenu(subPanels["setupmanager"], OptSM.BuildOptions(), 10, -10, subMenuHeight, false,
        options_text_template, options_dropdown_template, options_switch_template,
        true, options_slider_template, options_button_template, OptSM.BuildCallback())
    DF:BuildMenu(subPanels["readycheck"], OptRC.BuildOptions(), 10, -10, subMenuHeight, false,
        options_text_template, options_dropdown_template, options_switch_template,
        true, options_slider_template, options_button_template, OptRC.BuildCallback())

end

local function BuildRaidUI(parent)
    -- Active sub-menu label
    local breadcrumb = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    breadcrumb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -76)
    local SECTIONS = MakeSections()
    breadcrumb:SetText("|cFFBB66FF" .. SECTIONS[1].name .. "|r")

    -- Sidebar background
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -100)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 22)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    -- Content area
    local contentArea = CreateFrame("Frame", nil, parent)
    contentArea:SetPoint("TOPLEFT", parent, "TOPLEFT", SIDEBAR_WIDTH + 8, -100)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 22)

    -- Content panels (one per section)
    local panels = {}
    for _, section in ipairs(SECTIONS) do
        local panel = CreateFrame("Frame", "RRTRaidSection_" .. section.key, contentArea)
        panel:SetAllPoints(contentArea)
        panel:Hide()
        panels[section.key] = panel
    end

    -- Build content for General panel
    BuildGeneralContent(panels["general"])

    -- Build content for Midnight panel (3 sub-tabs: Raidframe / PA Filter / Profiles)
    local function BuildMidnightContent(panel)
        local subDefs = {
            { name = L["midnight_frame"],     key = "raidframe" },
            { name = L["midnight_pa_filter"], key = "pafilter"  },
            { name = L["midnight_profiles"],  key = "profiles"  },
        }
        local subPanels = BuildSubNav(panel, subDefs)
        local subMenuH  = window_height - SUB_BTN_HEIGHT - SUB_BTN_PAD * 2 - 4 - 10
        local Opt = RRT_NS.UI.Options.RaidFrame

        DF:BuildMenu(subPanels["raidframe"], Opt.BuildAllOptions(), 10, -10, subMenuH, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, Opt.BuildCallback())

        local paPicker = Opt.BuildPAPickerPanel(subPanels["pafilter"])
        paPicker:SetPoint("TOPLEFT",     subPanels["pafilter"], "TOPLEFT",     8,  0)
        paPicker:SetPoint("BOTTOMRIGHT", subPanels["pafilter"], "BOTTOMRIGHT", -8, 4)

        -- Profiles: left menu (fixed 370px) + right overview panel
        local MENU_W = 370
        local menuHolder = CreateFrame("Frame", "RRTProfileMenuHolder", subPanels["profiles"])
        menuHolder:SetPoint("TOPLEFT",    subPanels["profiles"], "TOPLEFT", 0, 0)
        menuHolder:SetPoint("BOTTOMLEFT", subPanels["profiles"], "BOTTOMLEFT", 0, 0)
        menuHolder:SetWidth(MENU_W)

        DF:BuildMenu(menuHolder, Opt.BuildProfileOptions(), 10, -10, subMenuH, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, Opt.BuildCallback())
        Opt.SetMenuRefreshCallback(function()
            menuHolder:Hide()
            menuHolder:Show()
            menuHolder:RefreshOptions()
        end)

        local overview = Opt.BuildProfileOverview(subPanels["profiles"])
        overview:SetPoint("TOPLEFT",     menuHolder, "TOPRIGHT",               10,  0)
        overview:SetPoint("BOTTOMRIGHT", subPanels["profiles"], "BOTTOMRIGHT", -8,  4)
    end
    BuildMidnightContent(panels["midnight"])

    -- Build Raid Inspect panel
    if RRT_NS.UI.RaidInspect and RRT_NS.UI.RaidInspect.BuildRaidInspectPanel then
        RRT_NS.UI.RaidInspect.BuildRaidInspectPanel(panels["raidinspect"])
    end

    -- Build Raid Groups panel
    if RRT_NS.UI.RaidGroups and RRT_NS.UI.RaidGroups.BuildRaidGroupsPanel then
        RRT_NS.UI.RaidGroups.BuildRaidGroupsPanel(panels["raidgroups"])
    end

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
        local hex = string.format("%02X%02X%02X", math.floor(c[1]*255+0.5), math.floor(c[2]*255+0.5), math.floor(c[3]*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. sectionName .. "|r")
    end

    for i, section in ipairs(SECTIONS) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(SIDEBAR_WIDTH - SIDEBAR_PADDING * 2, SIDEBAR_ITEM_HEIGHT)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", SIDEBAR_PADDING, -(SIDEBAR_PADDING + (i - 1) * (SIDEBAR_ITEM_HEIGHT + 4)))
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
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

        local key = section.key
        local name = section.name
        btn:SetScript("OnClick", function(self)
            SelectSection(key, self, name)
        end)
        btn:SetScript("OnEnter", function(self)
            if activeButton ~= self then
                self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeButton ~= self then
                self:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            end
        end)

        if i == 1 then
            SelectSection(key, btn, name)
        end
    end

    -- Register theme color callback for sidebar active button + breadcrumb
    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
        if activeButton then
            activeButton:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
            activeButton:SetBackdropBorderColor(r, g, b, 1)
        end
        local hex = string.format("%02X%02X%02X", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. currentSectionName .. "|r")
    end)

    return panels
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Raid = {
    BuildRaidUI = BuildRaidUI,
}
