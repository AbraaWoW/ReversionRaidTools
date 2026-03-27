local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateNote — MRT note editor
-- Toolbar row 1 : RT icons  |  role/faction icons  |  spell-ID search  |  |r
-- Toolbar row 2 : class icons  |  25-color palette  |  |r
-- Toolbar row 3 : timer builder  |  {everyone}
-- Left  : multiline editor (shares RRT.CDNote.noteText with Send Note)
-- Right : boss spell browser (RRT_NS.BossTimelines)
-- ─────────────────────────────────────────────────────────────────────────────

local SBAR_W    = 8
local ICON_W    = 22   -- toolbar icon button size
local BTN_H     = 20
local BTN_PAD   = 4
local LBL_H     = 18
-- toolbar = top-pad + row1 + gap + row2 + gap + row3 + bottom-pad
local TOOLBAR_H = BTN_PAD + ICON_W + BTN_PAD + ICON_W + BTN_PAD + BTN_H + BTN_PAD  -- 80

-- ── 25-color palette (MRT VisNote) — {r,g,b,hex,name} ──────────────────────
local PALETTE = {
    {0,      0,      0,      "000000", "Black"},
    {0.498,  0.498,  0.498,  "7F7F7F", "Gray"},
    {0.533,  0,      0.082,  "880015", "Dark Red"},
    {0.929,  0.11,   0.141,  "ED1C24", "Red"},
    {1,      0.498,  0.153,  "FF7F27", "Orange"},
    {1,      0.949,  0,      "FFF200", "Yellow"},
    {0.133,  0.694,  0.298,  "22B14C", "Green"},
    {0,      0.635,  0.91,   "00A2E8", "Blue"},
    {0.247,  0.282,  0.8,    "3F48CC", "Indigo"},
    {0.639,  0.286,  0.643,  "A349A4", "Purple"},
    {1,      1,      1,      "FFFFFF", "White"},
    {0.765,  0.765,  0.765,  "C3C3C3", "Light Gray"},
    {0.725,  0.478,  0.341,  "B97A57", "Brown"},
    {1,      0.682,  0.788,  "FFB6C9", "Pink"},
    {1,      0.788,  0.055,  "FFC90E", "Gold"},
    {0.937,  0.894,  0.69,   "EFE4B0", "Pale Yellow"},
    {0.71,   0.902,  0.114,  "B5E61D", "Yellow-Green"},
    {0.6,    0.851,  0.918,  "99D9EA", "Sky Blue"},
    {0.439,  0.573,  0.745,  "7092BE", "Steel Blue"},
    {0.784,  0.749,  0.906,  "C8BFE7", "Lavender"},
    {0.67,   0.83,   0.45,   "ABD473", "Mint"},
    {0,      1,      0.592,  "00FF97", "Cyan-Green"},
    {0.529,  0.529,  0.929,  "8787ED", "Periwinkle"},
    {0.639,  0.188,  0.788,  "A330C9", "RRT Purple"},
    {0.2,    0.58,   0.5,    "339480", "Teal"},
}

-- ── Raid-target icons ────────────────────────────────────────────────────────
local RT_ICONS = {
    {tag="{rt1}", tex="Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"},
    {tag="{rt2}", tex="Interface\\TargetingFrame\\UI-RaidTargetingIcon_2"},
    {tag="{rt3}", tex="Interface\\TargetingFrame\\UI-RaidTargetingIcon_3"},
    {tag="{rt4}", tex="Interface\\TargetingFrame\\UI-RaidTargetingIcon_4"},
    {tag="{rt5}", tex="Interface\\TargetingFrame\\UI-RaidTargetingIcon_5"},
    {tag="{rt6}", tex="Interface\\TargetingFrame\\UI-RaidTargetingIcon_6"},
    {tag="{rt7}", tex="Interface\\TargetingFrame\\UI-RaidTargetingIcon_7"},
    {tag="{rt8}", tex="Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"},
}

-- ── Role / faction icons ─────────────────────────────────────────────────────
local ROLE_ICONS = {
    {tag="{tank}",     tex="Interface\\LFGFrame\\UI-LFG-ICON-ROLES", l=0,           r=0.26171875, t=0.26171875, b=0.5234375},
    {tag="{healer}",   tex="Interface\\LFGFrame\\UI-LFG-ICON-ROLES", l=0.26171875,  r=0.5234375,  t=0,          b=0.26171875},
    {tag="{dps}",      tex="Interface\\LFGFrame\\UI-LFG-ICON-ROLES", l=0.26171875,  r=0.5234375,  t=0.26171875, b=0.5234375},
    {tag="{alliance}", tex="Interface\\FriendsFrame\\PlusManz-Alliance"},
    {tag="{horde}",    tex="Interface\\FriendsFrame\\PlusManz-Horde"},
}

-- ── Class icons ──────────────────────────────────────────────────────────────
local CS = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local CLASS_ICONS = {
    {tag="{warrior}",     tex=CS, l=0,           r=0.25,        t=0,     b=0.25},
    {tag="{paladin}",     tex=CS, l=0,           r=0.25,        t=0.5,   b=0.75},
    {tag="{hunter}",      tex=CS, l=0,           r=0.25,        t=0.25,  b=0.5},
    {tag="{rogue}",       tex=CS, l=0.49609375,  r=0.7421875,   t=0,     b=0.25},
    {tag="{priest}",      tex=CS, l=0.49609375,  r=0.7421875,   t=0.25,  b=0.5},
    {tag="{deathknight}", tex=CS, l=0.25,        r=0.5,         t=0.5,   b=0.75},
    {tag="{shaman}",      tex=CS, l=0.25,        r=0.49609375,  t=0.25,  b=0.5},
    {tag="{mage}",        tex=CS, l=0.25,        r=0.49609375,  t=0,     b=0.25},
    {tag="{warlock}",     tex=CS, l=0.7421875,   r=0.98828125,  t=0.25,  b=0.5},
    {tag="{monk}",        tex=CS, l=0.5,         r=0.73828125,  t=0.5,   b=0.75},
    {tag="{druid}",       tex=CS, l=0.7421875,   r=0.98828125,  t=0,     b=0.25},
    {tag="{demonhunter}", tex=CS, l=0.7421875,   r=0.98828125,  t=0.5,   b=0.75},
    {tag="{evoker}",      tex="interface/icons/classicon_evoker"},
}

-- ── Raid / Heal cooldowns (type=4) — organised by category ──────────────────
local RAID_CDS = {
    {
        header = "Healer",
        spells = {
            -- Druid
            {"DRUID",   740,    "Tranquility"},
            {"DRUID",   33891,  "Incarnation: Tree of Life"},
            {"DRUID",   323764, "Convoke the Spirits"},
            -- Shaman
            {"SHAMAN",  98008,  "Spirit Link Totem"},
            {"SHAMAN",  114052, "Ascendance"},
            {"SHAMAN",  108280, "Healing Tide Totem"},
            -- Monk
            {"MONK",    115310, "Revival"},
            {"MONK",    198664, "Invoke Chi-Ji"},
            {"MONK",    322118, "Invoke Yu'lon"},
            -- Priest
            {"PRIEST",  64844,  "Divine Hymn"},
            {"PRIEST",  200183, "Apotheosis"},
            {"PRIEST",  120517, "Halo"},
            {"PRIEST",  246287, "Evangelism"},
            {"PRIEST",  421453, "Ultimate Penitence"},
            {"PRIEST",  62618,  "Power Word: Barrier"},
            -- Paladin
            {"PALADIN", 31821,  "Aura Mastery"},
            {"PALADIN", 31884,  "Avenging Wrath"},
            {"PALADIN", 216331, "Avenging Crusader"},
            -- Evoker
            {"EVOKER",  370537, "Stasis"},
            {"EVOKER",  359816, "Dream Flight"},
            {"EVOKER",  363534, "Rewind"},
        },
    },
    {
        header = "Mobility",
        spells = {},
    },
    {
        header = "Defensive",
        spells = {},
    },
    {
        header = "Other",
        spells = {},
    },
}

-- ── Encounter data — Extension > Instance > Boss ─────────────────────────────
local function BuildEncounters()
    return RRT_NS.RaidData
end

-- ── Custom scrollbar (same pattern as NotePanel) ────────────────────────────
local function MakeScrollBar(sf)
    local track = CreateFrame("Frame", nil, sf:GetParent(), "BackdropTemplate")
    track:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
                       edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    track:SetBackdropColor(0.08, 0.08, 0.10, 0.90)
    track:SetBackdropBorderColor(0, 0, 0, 0.6)
    track:SetWidth(SBAR_W)

    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
    thumb:SetBackdropColor(0.45, 0.45, 0.45, 0.75)
    thumb:SetWidth(SBAR_W - 2)
    thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, 0)
    thumb:EnableMouse(true)

    local function Update()
        local trackH = track:GetHeight()
        local range  = sf:GetVerticalScrollRange()
        if range <= 0 then
            thumb:SetHeight(math.max(1, trackH))
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, 0)
            return
        end
        local thumbH = math.max(16, trackH * trackH / (trackH + range))
        thumb:SetHeight(thumbH)
        local pos = -(sf:GetVerticalScroll() / range) * (trackH - thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, pos)
    end

    sf:SetScript("OnScrollRangeChanged", function() Update() end)
    sf:HookScript("OnVerticalScroll", Update)

    local dragging, startY, startScroll = false, 0, 0
    thumb:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        dragging = true; startY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        startScroll = sf:GetVerticalScroll()
    end)
    thumb:SetScript("OnMouseUp", function() dragging = false end)
    thumb:SetScript("OnUpdate", function()
        if not dragging then return end
        local trackH = track:GetHeight()
        local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local range  = sf:GetVerticalScrollRange()
        local avail  = trackH - thumb:GetHeight()
        if avail <= 0 then return end
        sf:SetVerticalScroll(math.max(0, math.min(range, startScroll + (startY - curY) * range / avail)))
    end)
    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        local trackH = track:GetHeight()
        local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local bounds = {track:GetBoundsRect()}
        local frac   = math.max(0, math.min(1, (bounds[4] - curY) / trackH))
        sf:SetVerticalScroll(frac * sf:GetVerticalScrollRange())
    end)
    thumb:SetScript("OnEnter", function(self) self:SetBackdropColor(0.65, 0.65, 0.65, 0.95) end)
    thumb:SetScript("OnLeave", function(self) self:SetBackdropColor(0.45, 0.45, 0.45, 0.75) end)
    return track
end

-- ── Main panel builder ───────────────────────────────────────────────────────
local function BuildCreateNotePanel(panel)
    local Core                    = RRT_NS.UI.Core
    local options_button_template = Core.options_button_template
    local options_dropdown_template = Core.options_dropdown_template

    local W = Core.window_width  - 130 - 12  -- 908
    local H = Core.window_height - 100 - 22  -- 518

    local EDITOR_W = math.floor(W * 0.62)     -- ~563
    local BOSS_W   = W - EDITOR_W - 8         -- ~337
    local bossX    = EDITOR_W + 8

    -- Gap between toolbar and editor/boss sections
    local CONTENT_TOP_Y = -(TOOLBAR_H + 6)

    -- ── Forward declarations ─────────────────────────────────────────────────
    local editBox
    -- Snapshot saved on every cursor move so toolbar clicks (which steal focus)
    -- can still read the last known cursor position and text selection.
    local savedSel = { pos = 0, selStart = 0, selEnd = 0 }

    -- General insertion — uses saved cursor pos (editBox may have lost focus)
    local function InsertAtCursor(text)
        if not editBox then return end
        local pos  = savedSel.pos
        local full = editBox:GetText()
        editBox:SetText(full:sub(1, pos) .. text .. full:sub(pos + 1))
        editBox:SetCursorPosition(pos + #text)
        editBox:SetFocus()
    end

    -- Color insertion — wraps saved selection if any, else inserts tag+|r
    -- with cursor between them (same logic as MRT AddTextToEditBox)
    local function InsertColorAtCursor(colorTag)
        if not editBox then return end
        local full     = editBox:GetText()
        local selStart = savedSel.selStart
        local selEnd   = savedSel.selEnd
        if selStart ~= selEnd then
            -- Wrap the previously-selected text
            local newText = full:sub(1, selStart)
                          .. colorTag
                          .. full:sub(selStart + 1, selEnd)
                          .. "|r"
                          .. full:sub(selEnd + 1)
            editBox:SetText(newText)
            editBox:SetCursorPosition(selEnd + #colorTag + 2)
        else
            local pos = savedSel.pos
            editBox:SetText(full:sub(1, pos) .. colorTag .. "|r" .. full:sub(pos + 1))
            editBox:SetCursorPosition(pos + #colorTag)  -- cursor sits between tag and |r
        end
        editBox:SetFocus()
    end

    -- ── Toolbar background ───────────────────────────────────────────────────
    local toolbarBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    toolbarBg:SetPoint("TOPLEFT",  panel, "TOPLEFT",  0, 0)
    toolbarBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    toolbarBg:SetHeight(TOOLBAR_H)
    DF:ApplyStandardBackdrop(toolbarBg)

    -- ── Helper: icon button ─────────────────────────────────────────────────
    local function MakeIconBtn(parent, xOff, yOff, iconData, tag, tooltip)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(ICON_W, ICON_W)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
                         edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

        local t = btn:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT",     btn, "TOPLEFT",     1, -1)
        t:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1,  1)
        t:SetTexture(iconData.tex)
        if iconData.l then t:SetTexCoord(iconData.l, iconData.r, iconData.t, iconData.b) end

        btn:SetScript("OnClick", function() InsertAtCursor(tag) end)
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            if tooltip then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            GameTooltip:Hide()
        end)
        return btn
    end

    -- ── Helper: plain backdrop button (no DF icon region) ───────────────────
    local function MakePlainBtn(parent, w, h, label, onClick)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(w, h)
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
                         edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then lbl:SetFont(f, 9, fl or "") end end
        lbl:SetPoint("CENTER")
        lbl:SetText(label)
        lbl:SetTextColor(0.9, 0.9, 0.9, 1)
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end)
        btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end)
        return btn
    end

    -- ── Helper: small inline button ─────────────────────────────────────────
    local function MakeTagBtn(parent, xOff, yOff, w, label, tag)
        local btn = MakePlainBtn(parent, w, BTN_H, label, function() InsertAtCursor(tag) end)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
        return btn
    end

    -- ── Row 1: Y offsets ────────────────────────────────────────────────────
    local r1Y  = -BTN_PAD          -- -4  (row-1 icon top)
    local r1BtnY = -(BTN_PAD + 1)  -- -5  (vertically centres BTN_H=20 in ICON_W=22)

    local xPos = 4

    -- RT icons ({rt1}-{rt8})
    for _, rt in ipairs(RT_ICONS) do
        MakeIconBtn(toolbarBg, xPos, r1Y, {tex=rt.tex}, rt.tag, rt.tag)
        xPos = xPos + ICON_W + 2
    end
    xPos = xPos + 6  -- separator

    -- Role & faction icons
    for _, ri in ipairs(ROLE_ICONS) do
        MakeIconBtn(toolbarBg, xPos, r1Y, ri, ri.tag, ri.tag)
        xPos = xPos + ICON_W + 2
    end
    xPos = xPos + 10  -- separator

    -- Spell-ID search
    local SPELLLBL_X = xPos  -- alignment anchor: Row 2 "Players" will match this
    local spellLbl = toolbarBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellLbl:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r1BtnY - 3)
    spellLbl:SetText("Spell ID :")
    spellLbl:SetTextColor(1, 0.82, 0, 1)
    xPos = xPos + 52

    local spellInput = DF:CreateTextEntry(toolbarBg, function() end, 88, BTN_H)
    spellInput:SetTemplate(options_button_template)
    spellInput:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r1BtnY)
    xPos = xPos + 92

    local btnInsertSpell = MakePlainBtn(toolbarBg, 66, BTN_H, "Insert", function()
        local id = spellInput:GetText()
        if id and id:match("^%d+$") then
            InsertAtCursor("{spell:" .. id .. "}")
            spellInput:SetText("")
        end
    end)
    btnInsertSpell:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r1BtnY)
    xPos = xPos + 70

    xPos = xPos + 10  -- gap before Color
    local COLOR_X = xPos  -- alignment anchor: Row 2 "CD Raid" will match this

    -- Color label (row 1 — same line as Spell ID)
    local colorLbl = toolbarBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colorLbl:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r1BtnY - 3)
    colorLbl:SetText((L["createnote_color"] or "Color") .. " :")
    colorLbl:SetTextColor(1, 0.82, 0, 1)
    xPos = xPos + 52

    -- Color dropdown (row 1)
    local CLASS_ORDER = {
        "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT",
        "SHAMAN","MAGE","WARLOCK","MONK","DRUID","DEMONHUNTER","EVOKER",
    }
    local CLASS_LABELS = {
        WARRIOR="Guerrier", PALADIN="Paladin", HUNTER="Chasseur",
        ROGUE="Voleur", PRIEST="Pretre", DEATHKNIGHT="Chevalier de la mort",
        SHAMAN="Chaman", MAGE="Mage", WARLOCK="Demoniste",
        MONK="Moine", DRUID="Druide", DEMONHUNTER="Chasseur de demons",
        EVOKER="Evocateur",
    }

    local colorDrop = DF:CreateDropDown(toolbarBg, function()
        local t = {}
        -- Class colors first
        if RAID_CLASS_COLORS then
            for _, cls in ipairs(CLASS_ORDER) do
                local cd = RAID_CLASS_COLORS[cls]
                if cd then
                    local hex = string.format("%02X%02X%02X",
                        math.floor((cd.r or 0) * 255 + 0.5),
                        math.floor((cd.g or 0) * 255 + 0.5),
                        math.floor((cd.b or 0) * 255 + 0.5))
                    local lbl = CLASS_LABELS[cls] or cls
                    tinsert(t, {
                        label   = "|cFF" .. hex .. lbl .. "|r",
                        value   = hex,
                        onclick = function(_, _, val) InsertColorAtCursor("|cFF" .. val) end,
                    })
                end
            end
        end
        -- Separator then palette
        tinsert(t, {label = "|cFF888888--- Couleurs ---|r", value = "", onclick = function() end})
        for _, clr in ipairs(PALETTE) do
            local h = clr[4]; local n = clr[5]
            tinsert(t, {
                label   = "|cFF" .. h .. n .. "|r",
                value   = h,
                onclick = function(_, _, val) InsertColorAtCursor("|cFF" .. val) end,
            })
        end
        return t
    end, nil, 150)
    colorDrop:SetTemplate(options_dropdown_template)
    colorDrop:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r1BtnY)
    if colorDrop.SetText then colorDrop:SetText(L["createnote_color"] or "Color") end
    xPos = xPos + 154

    -- ── Row 2: class icons + Players dropdown (below Spell ID) ──────────────
    local r2Y    = -(BTN_PAD + ICON_W + BTN_PAD)  -- -30
    local r2BtnY = r2Y - 1                          -- -31, centres BTN_H in ICON_W

    xPos = 4
    for _, ci in ipairs(CLASS_ICONS) do
        MakeIconBtn(toolbarBg, xPos, r2Y, ci, ci.tag, ci.tag)
        xPos = xPos + ICON_W + 2
    end

    -- Players dropdown — aligned with "Spell ID" in Row 1
    xPos = SPELLLBL_X
    local playersLbl = toolbarBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playersLbl:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r2BtnY - 2)
    playersLbl:SetText("Players :")
    playersLbl:SetTextColor(1, 0.82, 0, 1)
    xPos = xPos + 52

    local playersDrop = DF:CreateDropDown(toolbarBg, function()
        local t = {}
        local function addUnit(unit)
            local name = UnitName(unit)
            if not name or name == "Unknown" or name == UNKNOWNOBJECT then return end
            name = name:match("^([^%-]+)") or name
            local _, classFile = UnitClass(unit)
            local cd = RAID_CLASS_COLORS and classFile and RAID_CLASS_COLORS[classFile]
            local hex = cd and string.format("%02X%02X%02X",
                math.floor(cd.r*255+0.5), math.floor(cd.g*255+0.5), math.floor(cd.b*255+0.5))
                or "FFFFFF"
            local tag = "|cFF" .. hex .. name .. "|r"
            tinsert(t, {label=tag, value=#t+1, onclick=function() InsertAtCursor(tag) end})
        end
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do addUnit("raid" .. i) end
        elseif IsInGroup() then
            addUnit("player")
            for i = 1, GetNumGroupMembers() - 1 do addUnit("party" .. i) end
        else
            addUnit("player")
        end
        if #t == 0 then
            tinsert(t, {label="|cFF888888Pas en groupe|r", value="", onclick=function() end})
        end
        return t
    end, nil, 140)
    playersDrop:SetTemplate(options_dropdown_template)
    playersDrop:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r2BtnY)
    if playersDrop.SetText then playersDrop:SetText("Players") end
    xPos = xPos + 144

    -- CD Heal/Raid dropdown — aligned with "Color" in Row 1
    xPos = COLOR_X
    local cdsLbl = toolbarBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cdsLbl:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r2BtnY - 2)
    cdsLbl:SetText("CD Raid :")
    cdsLbl:SetTextColor(1, 0.82, 0, 1)
    xPos = xPos + 56

    local cdsDrop = DF:CreateDropDown(toolbarBg, function()
        local t = {}
        for _, cat in ipairs(RAID_CDS) do
            if #cat.spells > 0 then
                tinsert(t, {label = "|cFFAAAAAA-- " .. cat.header .. " --|r", value = "", onclick = function() end})
                for _, entry in ipairs(cat.spells) do
                    local cls, id, name = entry[1], entry[2], entry[3]
                    local cd = RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
                    local hex = cd and string.format("%02X%02X%02X",
                        math.floor(cd.r*255+0.5), math.floor(cd.g*255+0.5), math.floor(cd.b*255+0.5))
                        or "FFFFFF"
                    local tag = "{spell:" .. id .. "}"
                    tinsert(t, {
                        label   = "|cFF" .. hex .. name .. "|r",
                        value   = tag,
                        onclick = function(_, _, val) InsertAtCursor(val) end,
                    })
                end
            end
        end
        return t
    end, nil, 150)
    cdsDrop:SetTemplate(options_dropdown_template)
    cdsDrop:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", xPos, r2BtnY)
    if cdsDrop.SetText then cdsDrop:SetText("CD Raid") end

    -- ── Row 3 : timer builder ─────────────────────────────────────────────────
    -- Inserts {time:M:SS} or {time:M:SS,pN} at cursor
    local r3Y = -(BTN_PAD + ICON_W + BTN_PAD + ICON_W + BTN_PAD)  -- -56

    local timerLbl = toolbarBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerLbl:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", 4, r3Y - 3)
    timerLbl:SetText("Timer :")
    timerLbl:SetTextColor(1, 0.82, 0, 1)

    local timerMinInput = DF:CreateTextEntry(toolbarBg, function() end, 34, BTN_H)
    timerMinInput:SetTemplate(options_button_template)
    timerMinInput:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", 52, r3Y)
    timerMinInput:SetText("0")

    local colonLbl = toolbarBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colonLbl:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", 88, r3Y - 3)
    colonLbl:SetText(":")
    colonLbl:SetTextColor(0.9, 0.9, 0.9, 1)

    local timerSecInput = DF:CreateTextEntry(toolbarBg, function() end, 34, BTN_H)
    timerSecInput:SetTemplate(options_button_template)
    timerSecInput:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", 96, r3Y)
    timerSecInput:SetText("00")

    local phaseLbl = toolbarBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    phaseLbl:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", 136, r3Y - 3)
    phaseLbl:SetText("Phase :")
    phaseLbl:SetTextColor(1, 0.82, 0, 1)

    local PHASE_OPTS = {
        {label="—",    value=""},
        {label="P 1",  value=",p1"},
        {label="P 2",  value=",p2"},
        {label="P 3",  value=",p3"},
        {label="P 4",  value=",p4"},
        {label="P 5",  value=",p5"},
    }
    local curPhase = ""

    local phaseDrop = DF:CreateDropDown(toolbarBg, function()
        local t = {}
        for _, opt in ipairs(PHASE_OPTS) do
            local v = opt.value
            tinsert(t, {label=opt.label, value=v, onclick=function(_, _, val)
                curPhase = val
            end})
        end
        return t
    end, "", 70)
    phaseDrop:SetTemplate(options_dropdown_template)
    phaseDrop:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", 182, r3Y)

    local btnInsertTimer = MakePlainBtn(toolbarBg, 80, BTN_H, "Insert Timer", function()
        local rawMin = timerMinInput:GetText():match("^%s*(%d+)%s*$") or "0"
        local rawSec = timerSecInput:GetText():match("^%s*(%d+)%s*$") or "0"
        local m = tonumber(rawMin) or 0
        local s = math.max(0, math.min(59, tonumber(rawSec) or 0))
        InsertAtCursor(string.format("{time:%d:%02d%s}", m, s, curPhase))
    end)
    btnInsertTimer:SetPoint("TOPLEFT", toolbarBg, "TOPLEFT", 258, r3Y)

    -- {everyone} shortcut
    MakeTagBtn(toolbarBg, 346, r3Y, 80, "{everyone}", "{everyone}")


    -- ── Left: editor ─────────────────────────────────────────────────────────
    local editorBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    editorBg:SetPoint("TOPLEFT",    panel, "TOPLEFT",    0, CONTENT_TOP_Y)
    editorBg:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    editorBg:SetWidth(EDITOR_W)
    DF:ApplyStandardBackdrop(editorBg)

    local editLbl = editorBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editLbl:SetPoint("TOPLEFT", editorBg, "TOPLEFT", 6, -BTN_PAD)
    editLbl:SetText("Note (format MRT) :")
    editLbl:SetTextColor(1, 0.82, 0, 1)

    local editScroll = CreateFrame("ScrollFrame", "RRTCreateNoteEditScroll", editorBg)
    editScroll:SetPoint("TOPLEFT",    editorBg, "TOPLEFT",    4,             -LBL_H)
    editScroll:SetPoint("BOTTOMRIGHT", editorBg, "BOTTOMRIGHT", -(SBAR_W + 6), BTN_PAD + BTN_H + BTN_PAD)
    editScroll:EnableMouseWheel(true)
    editScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 30)))
    end)

    editBox = CreateFrame("EditBox", "RRTCreateNoteEditBox", editScroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:EnableKeyboard(true)
    editBox:SetMaxLetters(0)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(EDITOR_W - 4 - SBAR_W - 6)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
        -- Snapshot cursor + selection while focus is still on the editBox
        savedSel.pos = self:GetCursorPosition()
        if self.GetTextHighlight then
            local s, e = self:GetTextHighlight()
            savedSel.selStart = s or 0
            savedSel.selEnd   = e or 0
        end
        -- Keep cursor visible while scrolling
        local sf  = editScroll
        local top = sf:GetVerticalScroll()
        local bot = top + sf:GetHeight()
        if -y < top then
            sf:SetVerticalScroll(math.max(0, -y))
        elseif -(y + h) > bot then
            sf:SetVerticalScroll(-(y + h) - sf:GetHeight())
        end
    end)
    editScroll:SetScrollChild(editBox)
    editScroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)

    local editSbar = MakeScrollBar(editScroll)
    editSbar:SetPoint("TOPLEFT",    editorBg, "TOPLEFT",    EDITOR_W - SBAR_W - 4, -LBL_H)
    editSbar:SetPoint("BOTTOMLEFT", editorBg, "BOTTOMLEFT", EDITOR_W - SBAR_W - 4,  BTN_PAD + BTN_H + BTN_PAD)
    editSbar:SetWidth(SBAR_W)

    local btnClear = MakePlainBtn(editorBg, 60, BTN_H, L["cdn_clear"] or "Clear", function()
        editBox:SetText("")
        if RRT and RRT.CDNote then RRT.CDNote.noteText = "" end
    end)
    btnClear:SetPoint("BOTTOMRIGHT", editorBg, "BOTTOMRIGHT", -4, BTN_PAD)

    -- Navigate to Send Note (text already shared via RRT.CDNote.noteText)
    local btnGoSend = MakePlainBtn(editorBg, 110, BTN_H, "Send Note >>", function()
        if RRT_NS.UI.Note and RRT_NS.UI.Note.NavigateToSection then
            RRT_NS.UI.Note.NavigateToSection("sendnote")
        end
    end)
    btnGoSend:SetPoint("BOTTOMLEFT", editorBg, "BOTTOMLEFT", 4, BTN_PAD)

    -- Theme color: keep Send Note / Clear hover border in sync with UI Appearance color
    do
        local _tc = RRT and RRT.Settings and RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        local tR, tG, tB = _tc[1], _tc[2], _tc[3]
        btnClear:SetScript("OnEnter",  function(self) self:SetBackdropBorderColor(tR, tG, tB, 1) end)
        btnGoSend:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(tR, tG, tB, 1) end)
        RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
        tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
            tR, tG, tB = r, g, b
        end)
    end

    -- Share noteText with Send Note panel
    editBox:SetScript("OnTextChanged", function(self)
        if RRT and RRT.CDNote then RRT.CDNote.noteText = self:GetText() end
    end)

    panel:HookScript("OnShow", function()
        local saved = (RRT and RRT.CDNote and RRT.CDNote.noteText) or ""
        if editBox:GetText() ~= saved then editBox:SetText(saved) end
    end)

    -- ── Right: boss spell browser ────────────────────────────────────────────
    local bossBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    bossBg:SetPoint("TOPLEFT",     panel, "TOPLEFT",     bossX, CONTENT_TOP_Y)
    bossBg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0,      0)
    DF:ApplyStandardBackdrop(bossBg)

    local bossLbl = bossBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bossLbl:SetPoint("TOPLEFT", bossBg, "TOPLEFT", 6, -BTN_PAD)
    bossLbl:SetText("Boss Spells :")
    bossLbl:SetTextColor(1, 0.82, 0, 1)

    -- State (initialized from BuildEncounters on first show)
    local curExtension = nil
    local curInstance  = nil
    local curBoss      = nil
    local spellRowPool = {}
    local RefreshSpellList  -- forward
    local extDrop, instDrop, bossDrop  -- forward refs for cross-refresh

    -- Initialise or reset state from current encounter data
    local function InitBossState(enc)
        if not enc or #enc == 0 then return false end
        local ext = enc[1]
        if not ext or not ext.instances or #ext.instances == 0 then return false end
        local inst = ext.instances[1]
        if not inst or not inst.bosses or #inst.bosses == 0 then return false end
        curExtension = ext
        curInstance  = inst
        curBoss      = inst.bosses[1]
        if extDrop  and extDrop.SetText  then pcall(extDrop.SetText,  extDrop,  curExtension.extension) end
        if instDrop and instDrop.SetText then pcall(instDrop.SetText, instDrop, curInstance.instance)   end
        if bossDrop and bossDrop.SetText then pcall(bossDrop.SetText, bossDrop, curBoss.name)           end
        return true
    end

    -- No-profile message (shown when debuffProfiles empty)
    local noDataLbl = bossBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noDataLbl:SetPoint("TOP", bossBg, "TOP", 0, -80)
    noDataLbl:SetText("|cFF888888Importe les raids depuis\nRaid > Midnight > Profiles|r")
    noDataLbl:SetJustifyH("CENTER")
    noDataLbl:Hide()

    -- Extension dropdown (row 1)
    extDrop = DF:CreateDropDown(bossBg, function()
        local enc = BuildEncounters()
        local t = {}
        if enc then
            for i, ext in ipairs(enc) do
                local ei = i
                tinsert(t, {label=ext.extension, value=ei, onclick=function(_, _, v)
                    local e = BuildEncounters()
                    if not e or not e[v] then return end
                    curExtension = e[v]
                    curInstance  = curExtension.instances[1]
                    curBoss      = curInstance.bosses[1]
                    if instDrop and instDrop.SetText then instDrop:SetText(curInstance.instance) end
                    if bossDrop and bossDrop.SetText then bossDrop:SetText(curBoss.name) end
                    if instDrop and instDrop.Refresh then instDrop:Refresh() end
                    if bossDrop and bossDrop.Refresh then bossDrop:Refresh() end
                    if RefreshSpellList then RefreshSpellList() end
                end})
            end
        end
        return t
    end, 1, BOSS_W - 8)
    extDrop:SetTemplate(options_dropdown_template)
    extDrop:SetPoint("TOPLEFT", bossBg, "TOPLEFT", 4, -(BTN_PAD + LBL_H))

    -- Instance dropdown (row 2)
    instDrop = DF:CreateDropDown(bossBg, function()
        local t = {}
        if curExtension then
            for i, inst in ipairs(curExtension.instances) do
                local ii = i
                tinsert(t, {label=inst.instance, value=ii, onclick=function(_, _, v)
                    curInstance = curExtension.instances[v]
                    curBoss     = curInstance.bosses[1]
                    if bossDrop and bossDrop.SetText then bossDrop:SetText(curBoss.name) end
                    if bossDrop and bossDrop.Refresh then bossDrop:Refresh() end
                    if RefreshSpellList then RefreshSpellList() end
                end})
            end
        end
        return t
    end, 1, BOSS_W - 8)
    instDrop:SetTemplate(options_dropdown_template)
    instDrop:SetPoint("TOPLEFT", bossBg, "TOPLEFT", 4, -(BTN_PAD + LBL_H + BTN_PAD + BTN_H))

    -- Boss dropdown (row 3)
    bossDrop = DF:CreateDropDown(bossBg, function()
        local t = {}
        if curInstance then
            for i, boss in ipairs(curInstance.bosses) do
                local bi = i
                tinsert(t, {label=boss.name, value=bi, onclick=function(_, _, v)
                    curBoss = curInstance.bosses[v]
                    if RefreshSpellList then RefreshSpellList() end
                end})
            end
        end
        return t
    end, 1, BOSS_W - 8)
    bossDrop:SetTemplate(options_dropdown_template)
    bossDrop:SetPoint("TOPLEFT", bossBg, "TOPLEFT", 4, -(BTN_PAD + LBL_H + (BTN_PAD + BTN_H) * 2))

    -- Spell list starts right after boss dropdown (row 3)
    local spellListTopY = -(BTN_PAD + LBL_H + (BTN_PAD + BTN_H) * 3)
    local spellContentW = BOSS_W - 4 - SBAR_W - 6
    local SPELL_ROW_H   = 22

    local spellScroll = CreateFrame("ScrollFrame", "RRTCreateNoteBossScroll", bossBg)
    spellScroll:SetPoint("TOPLEFT",     bossBg, "TOPLEFT",     4,             spellListTopY)
    spellScroll:SetPoint("BOTTOMRIGHT", bossBg, "BOTTOMRIGHT", -(SBAR_W + 6), 4)
    spellScroll:EnableMouseWheel(true)
    spellScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 30)))
    end)

    local spellContent = CreateFrame("Frame", nil, spellScroll)
    spellContent:SetWidth(spellContentW)
    spellContent:SetHeight(1)
    spellScroll:SetScrollChild(spellContent)

    local spellSbar = MakeScrollBar(spellScroll)
    spellSbar:SetPoint("TOPRIGHT",    bossBg, "TOPRIGHT",    -4, spellListTopY)
    spellSbar:SetPoint("BOTTOMRIGHT", bossBg, "BOTTOMRIGHT", -4, 4)
    spellSbar:SetWidth(SBAR_W)

    -- Empty label
    local emptySpellLbl = spellContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    emptySpellLbl:SetPoint("TOP", spellContent, "TOP", 0, -8)
    emptySpellLbl:SetText("|cFF666666" .. L["createnote_no_boss_data"] .. "|r")

    RefreshSpellList = function()
        if not curBoss then return end

        -- Use hardcoded spells if available, otherwise fall back to BossTimelines
        local unique = {}
        if curBoss.spells then
            unique = curBoss.spells
        else
            local timeline = RRT_NS.BossTimelines and RRT_NS.BossTimelines[curBoss.id]
            local seen = {}
            for _, diff in ipairs({"Heroic", "Mythic", "Normal"}) do
                local abilities = (timeline and timeline[diff] and timeline[diff].abilities) or {}
                for _, ab in ipairs(abilities) do
                    if not seen[ab.spellID] then
                        seen[ab.spellID] = true
                        unique[#unique + 1] = ab
                    end
                end
            end
        end

        emptySpellLbl:SetShown(#unique == 0)

        for i, ab in ipairs(unique) do
            if not spellRowPool[i] then
                local row = CreateFrame("Button", nil, spellContent, "BackdropTemplate")
                row:SetHeight(SPELL_ROW_H)
                row:SetWidth(spellContentW)
                row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
                row:SetBackdropColor(0, 0, 0, 0)

                local sep = row:CreateTexture(nil, "BACKGROUND")
                sep:SetColorTexture(0.3, 0.3, 0.3, 0.2)
                sep:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  0, 0)
                sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
                sep:SetHeight(1)

                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(18, 18)
                icon:SetPoint("LEFT", row, "LEFT", 2, 0)
                row.icon = icon

                local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                nameLbl:SetPoint("LEFT",  row, "LEFT",  24, 0)
                nameLbl:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                nameLbl:SetJustifyH("LEFT")
                row.nameLbl = nameLbl

                spellRowPool[i] = row
            end

            local row  = spellRowPool[i]
            local spID = ab.spellID

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", spellContent, "TOPLEFT", 0, -((i - 1) * SPELL_ROW_H))
            row:Show()

            local tex = C_Spell and C_Spell.GetSpellTexture(spID)
            row.icon:SetTexture(tex or "Interface\\Icons\\INV_MISC_QUESTIONMARK")

            row.nameLbl:SetText(ab.name)
            row.nameLbl:SetTextColor(0.9, 0.9, 0.9, 1)

            local capturedID = spID
            row:SetScript("OnClick", function()
                InsertAtCursor("{spell:" .. capturedID .. "}")
            end)
            row:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.15, 0.15, 0.15, 0.7)
                row.nameLbl:SetTextColor(1, 1, 1, 1)
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                pcall(function() GameTooltip:SetSpellByID(capturedID) end)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0)
                row.nameLbl:SetTextColor(0.9, 0.9, 0.9, 1)
                GameTooltip:Hide()
            end)
        end

        for i = #unique + 1, #spellRowPool do spellRowPool[i]:Hide() end
        spellContent:SetHeight(math.max(1, #unique * SPELL_ROW_H))
        spellScroll:UpdateScrollChildRect()
        spellScroll:SetVerticalScroll(0)
    end

    panel:HookScript("OnShow", function()
        local enc = BuildEncounters()
        local hasData = InitBossState(enc)
        noDataLbl:SetShown(not hasData)
        RefreshSpellList()
    end)
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.BuildCreateNotePanel = BuildCreateNotePanel
