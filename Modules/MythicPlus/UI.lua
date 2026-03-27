local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core = RRT_NS.UI.Core
local window_height = Core.window_height
local options_text_template     = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template   = Core.options_switch_template
local options_slider_template   = Core.options_slider_template
local options_button_template   = Core.options_button_template

local SIDEBAR_WIDTH      = 130
local SIDEBAR_ITEM_H     = 20
local SIDEBAR_PADDING    = 4
local SUB_BTN_HEIGHT     = 20
local SUB_BTN_WIDTH      = 110
local SUB_BTN_PAD        = 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared: horizontal sub-nav (same as Raid/UI.lua BuildSubNav)
-- ─────────────────────────────────────────────────────────────────────────────
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
            bgFile   = "Interface\\Buttons\\WHITE8X8",
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

        local subPanel = CreateFrame("Frame", "RRTMPGenSub_" .. def.key, parent)
        subPanel:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0, -(SUB_BTN_HEIGHT + SUB_BTN_PAD * 2 + 4))
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

    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
        if subActive then
            subActive:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
            subActive:SetBackdropBorderColor(r, g, b, 1)
        end
    end)

    return subPanels
end

-- ─────────────────────────────────────────────────────────────────────────────
-- General section — sub-nav with the 6 features
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildGeneralContent(panel)
    -- Available height: tab minus top header (100) and bottom margin (22),
    -- minus sub-nav bar, minus BuildMenu's own y offset (-10)
    local subMenuH = window_height - 100 - 22 - SUB_BTN_HEIGHT - SUB_BTN_PAD * 2 - 4 - 10

    local subDefs = {
        { name = "Focus Interrupt", key = "focusint" },
        { name = "Focus Marker",    key = "focusmrk" },
        { name = "Healer Mana",     key = "mana"     },
        { name = "Potion Alert",    key = "potion"   },
        { name = "Death Alert",     key = "death"    },
        { name = "Group Joined",    key = "joined"   },
    }

    local subPanels = BuildSubNav(panel, subDefs)

    local MP = RRT_NS.UI.Options

    local sections = {
        { key = "focusint", mod = MP.MP_FocusInterrupt },
        { key = "focusmrk", mod = MP.MP_FocusMarker    },
        { key = "mana",     mod = MP.MP_HealerMana      },
        { key = "potion",   mod = MP.MP_PotionAlert    },
        { key = "death",    mod = MP.MP_DeathAlert      },
        { key = "joined",   mod = MP.MP_GroupJoined     },
    }

    for _, sec in ipairs(sections) do
        if sec.mod then
            if sec.mod.BuildOptionsRight then
                -- Layout deux colonnes : gauche + droite
                local leftPanel = CreateFrame("Frame", "RRTMPLeft_"..sec.key, subPanels[sec.key])
                leftPanel:SetPoint("TOPLEFT",     subPanels[sec.key], "TOPLEFT",  0, 0)
                leftPanel:SetPoint("BOTTOMRIGHT", subPanels[sec.key], "BOTTOM",  -2, 0)

                local rightPanel = CreateFrame("Frame", "RRTMPRight_"..sec.key, subPanels[sec.key])
                rightPanel:SetPoint("TOPLEFT",     subPanels[sec.key], "TOP",         2, 0)
                rightPanel:SetPoint("BOTTOMRIGHT", subPanels[sec.key], "BOTTOMRIGHT", 0, 0)

                DF:BuildMenu(leftPanel,  sec.mod.BuildOptions(),      10, -10, subMenuH, true,
                    options_text_template, options_dropdown_template, options_switch_template,
                    true, options_slider_template, options_button_template, sec.mod.BuildCallback())
                DF:BuildMenu(rightPanel, sec.mod.BuildOptionsRight(), 10, -10, subMenuH, true,
                    options_text_template, options_dropdown_template, options_switch_template,
                    true, options_slider_template, options_button_template, sec.mod.BuildCallback())
            else
                local singleCol = sec.mod.singleColumn or false
                DF:BuildMenu(subPanels[sec.key], sec.mod.BuildOptions(), 10, -10, subMenuH, singleCol,
                    options_text_template, options_dropdown_template, options_switch_template,
                    true, options_slider_template, options_button_template, sec.mod.BuildCallback())
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Main builder — called from RRTUI.lua
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildMythicPlusUI(parent)
    local SECTIONS = {
        { name = "General",  key = "general"  },
        { name = "Midnight", key = "midnight" },
    }

    -- Breadcrumb
    local breadcrumb = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    breadcrumb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -76)
    breadcrumb:SetText("|cFFBB66FF" .. SECTIONS[1].name .. "|r")

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",    parent, "TOPLEFT",    4, -100)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4,  22)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    -- Content area
    local contentArea = CreateFrame("Frame", nil, parent)
    contentArea:SetPoint("TOPLEFT",     parent, "TOPLEFT",     SIDEBAR_WIDTH + 8, -100)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 22)

    -- One panel per sidebar section
    local panels = {}
    for _, sec in ipairs(SECTIONS) do
        local panel = CreateFrame("Frame", "RRTMythicPlusSection_" .. sec.key, contentArea)
        panel:SetAllPoints(contentArea)
        panel:Hide()
        panels[sec.key] = panel
    end

    -- Build section content
    BuildGeneralContent(panels["general"])
    -- panels["midnight"] is empty for now (future use)

    -- Sidebar buttons + SelectSection
    local activeButton        = nil
    local currentSectionName  = SECTIONS[1].name

    local function SelectSection(key, btn, sectionName)
        for k, p in pairs(panels) do p:SetShown(k == key) end
        if activeButton then
            activeButton:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            activeButton:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
        end
        local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        btn:SetBackdropColor(c[1]*0.4, c[2]*0.4, c[3]*0.4, 0.8)
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        activeButton        = btn
        currentSectionName  = sectionName
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
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then btnText:SetFont(f, 9, fl or "") end end
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(section.name)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)

        local key  = section.key
        local name = section.name
        btn:SetScript("OnClick", function(self) SelectSection(key, self, name) end)
        btn:SetScript("OnEnter", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end
        end)

        if i == 1 then SelectSection(key, btn, name) end
    end

    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
        if activeButton then
            activeButton:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
            activeButton:SetBackdropBorderColor(r, g, b, 1)
        end
        local hex = string.format("%02X%02X%02X",
            math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. currentSectionName .. "|r")
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Export
-- ─────────────────────────────────────────────────────────────────────────────
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.MythicPlus = RRT_NS.UI.MythicPlus or {}
RRT_NS.UI.MythicPlus.BuildMythicPlusUI = BuildMythicPlusUI
