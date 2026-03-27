local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

-- ─────────────────────────────────────────────────────────────────────────────
-- MythicPlus options — each function returns a DF:BuildMenu options table.
-- Exported via RRT_NS.UI.Options.MP_* so RRTUI.lua can include them
-- in the Mythic+ sidebar exactly like every other tab.
-- ─────────────────────────────────────────────────────────────────────────────

local OUTLINES       = { "NONE", "OUTLINE", "THICKOUTLINE" }
local OUTLINE_LABELS = { "None", "Outline", "Thick" }
local CHANNELS       = { "PARTY", "RAID", "SAY", "YELL" }

-- ─────────────────────────────────────────────────────────────────────────────
-- Popup "Copy Macro" — EditBox préselectionné, Ctrl+A / Ctrl+C pour copier
-- ─────────────────────────────────────────────────────────────────────────────
local FOCUS_INTERRUPT_MACRO =
    "#showtooltip Kick\n" ..
    "/focus [@focus,noexists,@mouseover,harm,nodead][@focus,noexists]\n" ..
    "/cast [@focus,exists] Kick"

local _copyFrame = nil

local function ShowCopyMacroPopup()
    if not _copyFrame then
        local f = CreateFrame("Frame", "RRTMacroCopyPopup", UIParent, "BackdropTemplate")
        f:SetSize(420, 115)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
        f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        f:SetScript("OnMouseDown", function(self) self:StartMoving() end)
        f:SetScript("OnMouseUp",   function(self) self:StopMovingOrSizing() end)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 10, -10)
        title:SetTextColor(1, 0.82, 0, 1)
        title:SetText("Copy Macro — Select all (Ctrl+A) then copy (Ctrl+C)")

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() f:Hide() end)

        local eb = CreateFrame("EditBox", "RRTMacroCopyEditBox", f, "InputBoxTemplate")
        eb:SetMultiLine(true)
        eb:SetSize(398, 65)
        eb:SetPoint("TOPLEFT", 10, -32)
        eb:SetAutoFocus(false)
        eb:SetFont(STANDARD_TEXT_FONT, 11, "")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        -- Empêcher l'édition
        eb:SetScript("OnChar", function(self) self:SetText(FOCUS_INTERRUPT_MACRO) end)

        f.editBox = eb
        f:Hide()
        _copyFrame = f
    end

    _copyFrame.editBox:SetText(FOCUS_INTERRUPT_MACRO)
    _copyFrame:Show()
    _copyFrame.editBox:SetFocus()
    _copyFrame.editBox:HighlightText()
end

local function SoundValues(setFn)
    local t = {}
    local sounds = RRT_NS.LSM and RRT_NS.LSM:List("sound") or {}
    for _, name in ipairs(sounds) do
        local n = name
        tinsert(t, { label = n, value = n, onclick = function() setFn(n) end })
    end
    return t
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Potion Alert
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildPotionAlertOptions()
    local function d() return RRT and RRT.MP_PotionAlert or {} end
    local function refresh() local m = RRT_NS.MP_PotionAlert; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Show an alert when your combat potion is ready.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="In Mythic Dungeons",
        desc="Show while inside a Mythic dungeon.",
        get=function() return d().enabledInDungeons end,
        set=function(_,_,v) d().enabledInDungeons=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="In Raids",
        desc="Show while in a raid (in combat).",
        get=function() return d().enabledInRaids end,
        set=function(_,_,v) d().enabledInRaids=v; refresh() end }
    opts[#opts+1] = { type="input", name="Display Text",
        desc="Text shown when the potion is ready.",
        get=function() return d().displayText or "Potion ready" end,
        set=function(_,_,v) d().displayText=v; refresh() end }
    opts[#opts+1] = { type="color", name="Text Color",
        get=function() local c=d().color or {}; return c.r or 1,c.g or 1,c.b or 1,c.a or 1 end,
        set=function(_,r,g,b,a) local db=d(); if not db.color then db.color={} end
            db.color.r=r; db.color.g=g; db.color.b=b; db.color.a=a; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=10, max=72, step=1,
        get=function() return d().fontSize or 18 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    for i,outline in ipairs(OUTLINES) do
        local o,l = outline, OUTLINE_LABELS[i]
        opts[#opts+1] = { type="button", name=l, desc="Set outline: "..l,
            func=function() d().fontOutline=o; refresh() end }
    end

    opts[#opts+1] = { type="label", get=function() return "Sound / TTS" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play Sound",
        get=function() return d().playSound end,
        set=function(_,_,v) d().playSound=v; refresh() end }
    opts[#opts+1] = { type="select", name="Sound",
        get=function() return d().sound or "" end,
        values=function() return SoundValues(function(v) d().sound=v; refresh() end) end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play TTS",
        get=function() return d().playTTS end,
        set=function(_,_,v) d().playTTS=v; refresh() end }
    opts[#opts+1] = { type="input", name="TTS Text",
        get=function() return d().tts or "" end,
        set=function(_,_,v) d().tts=v; refresh() end }
    opts[#opts+1] = { type="range", name="TTS Volume", min=0, max=100, step=1,
        get=function() return d().ttsVolume or 50 end,
        set=function(_,_,v) d().ttsVolume=v; refresh() end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_PotionAlert; if m then m:ResetPosition() end end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Focus Interrupt Indicator
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildFocusInterruptOptionsLeft()
    local function d() return RRT and RRT.MP_FocusInterrupt or {} end
    local function refresh() local m=RRT_NS.MP_FocusInterrupt; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="label", get=function() return "Recommended macro :" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="label", get=function() return "#showtooltip Kick" end }
    opts[#opts+1] = { type="label", get=function() return "/focus [@focus,noexists,@mouseover,harm,nodead][@focus,noexists]" end }
    opts[#opts+1] = { type="label", get=function() return "/cast [@focus,exists] Kick" end }
    opts[#opts+1] = { type="button", name="Copy Macro",
        desc="Open a box with the macro text — select all (Ctrl+A) then copy (Ctrl+C).",
        func=function() ShowCopyMacroPopup() end }
    opts[#opts+1] = { type="label", get=function() return
        "|cFFFFFF00Use this macro for simplicity: 1st click sets your focus target, next click launches your kick.|r"
    end, spacement=true }

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Show INTERRUPT when your focus is casting and your interrupt is ready.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Lock Position",
        get=function() return d().locked end,
        set=function(_,_,v) d().locked=v; refresh() end }
    opts[#opts+1] = { type="input", name="Display Text",
        get=function() return d().displayText or "INTERRUPT" end,
        set=function(_,_,v) d().displayText=v; refresh() end }
    opts[#opts+1] = { type="color", name="Text Color",
        get=function() local c=d().color or {}; return c.r or 1,c.g or 0.2,c.b or 0.2,c.a or 1 end,
        set=function(_,r,g,b,a) local db=d(); if not db.color then db.color={} end
            db.color.r=r; db.color.g=g; db.color.b=b; db.color.a=a; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=10, max=72, step=1,
        get=function() return d().fontSize or 22 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    for i,outline in ipairs(OUTLINES) do
        local o,l = outline, OUTLINE_LABELS[i]
        opts[#opts+1] = { type="button", name=l, desc="Set outline: "..l,
            func=function() d().fontOutline=o; refresh() end }
    end
    opts[#opts+1] = { type="label", get=function() return "Preview" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="button", name="Preview On",
        func=function() local m=RRT_NS.MP_FocusInterrupt; if m then m:SetPreviewMode(true) end end }
    opts[#opts+1] = { type="button", name="Preview Off",
        func=function() local m=RRT_NS.MP_FocusInterrupt; if m then m:SetPreviewMode(false) end end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_FocusInterrupt; if m then m:ResetPosition() end end }

    return opts
end

local function BuildFocusInterruptOptionsRight()
    local function d() return RRT and RRT.MP_FocusInterrupt or {} end
    local function refresh() local m=RRT_NS.MP_FocusInterrupt; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="label", get=function() return "Sound / TTS" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play Sound",
        get=function() return d().playSound end,
        set=function(_,_,v) d().playSound=v; refresh() end }
    opts[#opts+1] = { type="select", name="Sound",
        get=function() return d().sound or "" end,
        values=function() return SoundValues(function(v) d().sound=v; refresh() end) end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play TTS",
        get=function() return d().playTTS end,
        set=function(_,_,v) d().playTTS=v; refresh() end }
    opts[#opts+1] = { type="input", name="TTS Text",
        get=function() return d().tts or "" end,
        set=function(_,_,v) d().tts=v; refresh() end }
    opts[#opts+1] = { type="range", name="TTS Volume", min=0, max=100, step=1,
        get=function() return d().ttsVolume or 50 end,
        set=function(_,_,v) d().ttsVolume=v; refresh() end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Focus Target Marker
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildFocusMarkerOptions()
    local function d() return RRT and RRT.MP_FocusMarker or {} end
    local function refresh() local m=RRT_NS.MP_FocusMarker; if m then m:UpdateDisplay() end end
    local opts = {}

    local MARKER_NAMES = RRT_NS.MP_FocusMarker and RRT_NS.MP_FocusMarker.MARKER_NAMES
        or {[1]="Star",[2]="Circle",[3]="Diamond",[4]="Triangle",
            [5]="Moon",[6]="Square",[7]="Cross",[8]="Skull"}

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Show a button to mark your focus target with a raid marker.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Lock Position",
        get=function() return d().locked end,
        set=function(_,_,v) d().locked=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Only in Dungeons",
        desc="Only show the button when inside a dungeon or raid instance.",
        get=function() return d().onlyDungeon end,
        set=function(_,_,v) d().onlyDungeon=v; refresh() end }

    local markerValues = {}
    for i=1,8 do
        local idx=i
        tinsert(markerValues, { label=MARKER_NAMES[i], value=idx,
            onclick=function() d().markerIndex=idx; refresh() end })
    end
    opts[#opts+1] = { type="select", name="Marker",
        desc="Raid marker to apply to the focus target.",
        get=function() return MARKER_NAMES[d().markerIndex or 8] end,
        values=function() return markerValues end }

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Announce on Ready Check",
        desc="Send your kick marker to the group on ready check (e.g. \"My kick marker is {Skull}\").",
        get=function() return d().announce end,
        set=function(_,_,v) d().announce=v; refresh() end }

    opts[#opts+1] = { type="label", get=function() return "Button Size" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="range", name="Width", min=60, max=300, step=1,
        get=function() return d().buttonWidth or 110 end,
        set=function(_,_,v) d().buttonWidth=v; refresh() end }
    opts[#opts+1] = { type="range", name="Height", min=16, max=80, step=1,
        get=function() return d().buttonHeight or 24 end,
        set=function(_,_,v) d().buttonHeight=v; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=6, max=36, step=1,
        get=function() return d().fontSize or 10 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    opts[#opts+1] = { type="label", get=function() return "Preview" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="button", name="Preview On",
        desc="Show the marker button on screen.",
        func=function() local m=RRT_NS.MP_FocusMarker; if m then m:SetPreviewMode(true) end end }
    opts[#opts+1] = { type="button", name="Preview Off",
        desc="Hide the preview.",
        func=function() local m=RRT_NS.MP_FocusMarker; if m then m:SetPreviewMode(false) end end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_FocusMarker; if m then m:ResetPosition() end end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Death Alert — colonne gauche
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildDeathAlertOptionsLeft()
    local function d() return RRT and RRT.MP_DeathAlert or {} end
    local function refresh() local m=RRT_NS.MP_DeathAlert; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Flash an alert when a group member dies.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Lock Position",
        get=function() return d().locked end,
        set=function(_,_,v) d().locked=v; refresh() end }
    opts[#opts+1] = { type="range", name="Display Duration", min=1, max=15, step=1,
        desc="Seconds the alert stays visible.",
        get=function() return d().displayTime or 4 end,
        set=function(_,_,v) d().displayTime=v; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=10, max=72, step=1,
        get=function() return d().fontSize or 24 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    for i,outline in ipairs(OUTLINES) do
        local o,l = outline, OUTLINE_LABELS[i]
        opts[#opts+1] = { type="button", name=l, desc="Set outline: "..l,
            func=function() d().fontOutline=o; refresh() end }
    end

    opts[#opts+1] = { type="label", get=function() return "Per-Role Settings" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    local roles = { {key="tank",label="Tank"}, {key="healer",label="Healer"}, {key="damager",label="DPS"} }
    for _, ri in ipairs(roles) do
        local rk, rl = ri.key, ri.label
        opts[#opts+1] = { type="toggle", boxfirst=true, name="Alert for "..rl,
            get=function() local dr=d().byRole; return dr and dr[rk] and dr[rk].enabled end,
            set=function(_,_,v) local dr=d().byRole; if dr and dr[rk] then dr[rk].enabled=v; refresh() end end }
        opts[#opts+1] = { type="color", name=rl.." Color",
            get=function() local dr=d().byRole; local c=dr and dr[rk] and dr[rk].color or {}
                return c.r or 1,c.g or 1,c.b or 1,c.a or 1 end,
            set=function(_,r,g,b,a) local dr=d().byRole; if dr and dr[rk] then
                if not dr[rk].color then dr[rk].color={} end
                dr[rk].color.r=r; dr[rk].color.g=g; dr[rk].color.b=b; dr[rk].color.a=a; refresh() end end }
    end

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Death Alert — colonne droite (Sound / TTS / Preview)
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildDeathAlertOptionsRight()
    local function d() return RRT and RRT.MP_DeathAlert or {} end
    local function refresh() local m=RRT_NS.MP_DeathAlert; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="label", get=function() return "Sound / TTS" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play Sound",
        get=function() return d().playSound end,
        set=function(_,_,v) d().playSound=v; refresh() end }
    opts[#opts+1] = { type="select", name="Sound",
        get=function() return d().sound or "" end,
        values=function() return SoundValues(function(v) d().sound=v; refresh() end) end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play TTS",
        get=function() return d().playTTS end,
        set=function(_,_,v) d().playTTS=v; refresh() end }
    opts[#opts+1] = { type="input", name="TTS Text",
        desc="Use {name} to insert the player's name.",
        get=function() return d().tts or "" end,
        set=function(_,_,v) d().tts=v; refresh() end }
    opts[#opts+1] = { type="range", name="TTS Volume", min=0, max=100, step=1,
        get=function() return d().ttsVolume or 50 end,
        set=function(_,_,v) d().ttsVolume=v; refresh() end }

    opts[#opts+1] = { type="label", get=function() return "Preview" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="button", name="Preview On",
        desc="Show a sample death alert on screen.",
        func=function() local m=RRT_NS.MP_DeathAlert; if m then m:SetPreviewMode(true) end end }
    opts[#opts+1] = { type="button", name="Preview Off",
        desc="Hide the preview.",
        func=function() local m=RRT_NS.MP_DeathAlert; if m then m:SetPreviewMode(false) end end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_DeathAlert; if m then m:ResetPosition() end end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Healer Mana Indicator
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildHealerManaOptions()
    local function d() return RRT and RRT.MP_HealerMana or {} end
    local function refresh() local m=RRT_NS.MP_HealerMana; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Show each healer's mana percentage.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Lock Position",
        get=function() return d().locked end,
        set=function(_,_,v) d().locked=v; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=8, max=36, step=1,
        get=function() return d().fontSize or 14 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    for i,outline in ipairs(OUTLINES) do
        local o,l = outline, OUTLINE_LABELS[i]
        opts[#opts+1] = { type="button", name=l, desc="Set outline: "..l,
            func=function() d().fontOutline=o; refresh() end }
    end
    opts[#opts+1] = { type="range", name="Low Mana %", min=0, max=100, step=1,
        desc="Below this % the indicator turns orange.",
        get=function() return d().lowThreshold or 30 end,
        set=function(_,_,v) d().lowThreshold=v; refresh() end }
    opts[#opts+1] = { type="range", name="Critical Mana %", min=0, max=100, step=1,
        desc="Below this % the indicator turns red.",
        get=function() return d().critThreshold or 15 end,
        set=function(_,_,v) d().critThreshold=v; refresh() end }
    opts[#opts+1] = { type="label", get=function() return "Preview" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="button", name="Preview On",
        desc="Show sample healer mana bars on screen.",
        func=function() local m=RRT_NS.MP_HealerMana; if m then m:SetPreviewMode(true) end end }
    opts[#opts+1] = { type="button", name="Preview Off",
        desc="Hide the preview.",
        func=function() local m=RRT_NS.MP_HealerMana; if m then m:SetPreviewMode(false) end end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_HealerMana; if m then m:ResetPosition() end end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Group Joined — popup éditeur de message
-- ─────────────────────────────────────────────────────────────────────────────
local _editPopup = nil

local function ShowEditMessagePopup(title, getText, setText)
    if not _editPopup then
        local f = CreateFrame("Frame", "RRTGroupJoinedEditPopup", UIParent, "BackdropTemplate")
        f:SetSize(460, 110)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
        f:SetBackdropBorderColor(0.5, 0.3, 0.8, 1)
        f:SetScript("OnMouseDown", function(self) self:StartMoving() end)
        f:SetScript("OnMouseUp",   function(self) self:StopMovingOrSizing() end)

        local titleLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleLabel:SetPoint("TOPLEFT", 10, -10)
        titleLabel:SetTextColor(1, 0.82, 0, 1)
        f.titleLabel = titleLabel

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() f:Hide() end)

        local eb = CreateFrame("EditBox", "RRTGroupJoinedEditBox", f, "InputBoxTemplate")
        eb:SetSize(430, 22)
        eb:SetPoint("TOPLEFT", 12, -34)
        eb:SetAutoFocus(true)
        eb:SetFont(STANDARD_TEXT_FONT, 12, "")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        f.editBox = eb

        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", 12, -60)
        hint:SetTextColor(0.6, 0.6, 0.6, 1)
        hint:SetText("Variables : {name}  {dungeon}  {level}")
        f.hint = hint

        local applyBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        applyBtn:SetSize(100, 22)
        applyBtn:SetPoint("BOTTOMRIGHT", -10, 10)
        applyBtn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        applyBtn:SetBackdropColor(0.18, 0.35, 0.18, 0.9)
        applyBtn:SetBackdropBorderColor(0.3, 0.7, 0.3, 1)
        local applyLbl = applyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        applyLbl:SetPoint("CENTER")
        applyLbl:SetText("Apply")
        applyBtn:SetScript("OnClick", function()
            if f.onApply then f.onApply(f.editBox:GetText()) end
            f:Hide()
        end)
        f.applyBtn = applyBtn

        _editPopup = f
    end

    _editPopup.titleLabel:SetText(title)
    _editPopup.editBox:SetText(getText())
    _editPopup.editBox:SetFocus()
    _editPopup.editBox:HighlightText()
    _editPopup.onApply = setText
    _editPopup:Show()
end

local function BuildGroupJoinedOptions()
    local function d() return RRT and RRT.MP_GroupJoined or {} end
    local function refresh() local m=RRT_NS.MP_GroupJoined; if m then m:UpdateDisplay() end end
    local opts = {}

    -- ── Greeting ──────────────────────────────────────────────────────────────
    opts[#opts+1] = { type="label", get=function() return "Greeting" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="label", get=function() return
        "Message : \"" .. (d().message or "") .. "\"" end }
    opts[#opts+1] = { type="button", name="Change Greeting Message",
        func=function()
            ShowEditMessagePopup(
                "Greeting Message  —  {name}  {dungeon}",
                function() return d().message or "" end,
                function(v) d().message = v; refresh() end
            )
        end }
    opts[#opts+1] = { type="label", get=function() return "" end }
    opts[#opts+1] = { type="range", name="Delay (sec)", min=0, max=30, step=1,
        get=function() return d().delay or 2 end,
        set=function(_,_,v) d().delay=v; refresh() end }

    -- ── Farewell ──────────────────────────────────────────────────────────────
    opts[#opts+1] = { type="label", get=function() return "Farewell — Mythic+ Completed" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        get=function() return d().farewellEnabled end,
        set=function(_,_,v) d().farewellEnabled=v; refresh() end }
    opts[#opts+1] = { type="label", get=function() return
        "Message : \"" .. (d().farewellMessage or "") .. "\"" end }
    opts[#opts+1] = { type="button", name="Change Farewell Message",
        func=function()
            ShowEditMessagePopup(
                "Farewell Message  —  {name}  {dungeon}  {level}",
                function() return d().farewellMessage or "" end,
                function(v) d().farewellMessage = v; refresh() end
            )
        end }
    opts[#opts+1] = { type="label", get=function() return "" end }
    opts[#opts+1] = { type="range", name="Delay (sec)", min=0, max=30, step=1,
        get=function() return d().farewellDelay or 3 end,
        set=function(_,_,v) d().farewellDelay=v; refresh() end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Export — same pattern as every other module in this addon
-- ─────────────────────────────────────────────────────────────────────────────
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}

RRT_NS.UI.Options.MP_PotionAlert    = { BuildOptions = BuildPotionAlertOptions,    BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_FocusInterrupt = { BuildOptions = BuildFocusInterruptOptionsLeft, BuildOptionsRight = BuildFocusInterruptOptionsRight, BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_FocusMarker    = { BuildOptions = BuildFocusMarkerOptions,     BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_DeathAlert     = { BuildOptions = BuildDeathAlertOptionsLeft, BuildOptionsRight = BuildDeathAlertOptionsRight, BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_HealerMana     = { BuildOptions = BuildHealerManaOptions,      BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_GroupJoined    = { BuildOptions = BuildGroupJoinedOptions, singleColumn = true, BuildCallback = function() return function() end end }
