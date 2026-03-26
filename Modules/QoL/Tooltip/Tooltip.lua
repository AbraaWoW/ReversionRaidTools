local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled         = false,
    showMount       = true,
    showItemID      = true,
    showItemSpellID = true,
    showSpellID     = true,
    showNodeID      = true,
    copyOnCtrlC     = true,
}

local function db()
    if not RRT or not RRT.Tooltip then return {} end
    return RRT.Tooltip
end

local function IsEnabled() return db().enabled end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function HasLine(tooltip, label)
    local name = tooltip:GetName()
    if not name then return false end
    for i = 1, tooltip:NumLines() do
        local left = _G[name .. "TextLeft" .. i]
        if left then
            local text = left:GetText()
            if text and not issecretvalue(text) and text:find(label, 1, true) then
                return true
            end
        end
    end
    return false
end

local function AddID(tooltip, label, id)
    if issecretvalue(id) then return end
    if not id or id == 0 then return end
    if HasLine(tooltip, label) then return end
    tooltip:AddDoubleLine(label, tostring(id), 1, 0.82, 0, 1, 1, 1)
    tooltip:Show()
end

local function GetUnitMount(unit)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil end
    if not C_MountJournal or not C_MountJournal.GetMountFromSpell then return nil end
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not aura then break end
        local spellId = aura.spellId
        if spellId and not issecretvalue(spellId) then
            local mountID = C_MountJournal.GetMountFromSpell(spellId)
            if mountID then
                local mountName = C_MountJournal.GetMountInfoByID(mountID)
                return mountName
            end
        end
        i = i + 1
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Ctrl+C copy popup
-- ─────────────────────────────────────────────────────────────────────────────

local lastTooltipName    = nil
local lastTooltipEntries = {}
local copyPopup          = nil

local function CreateIDRow(parent, popup, index)
    local BTN_W  = 54
    local EDIT_H = 24
    local LABEL_W = 56
    local PAD    = 12

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(EDIT_H)
    row:SetPoint("LEFT",  parent, "LEFT",  PAD, 0)
    row:SetPoint("RIGHT", parent, "RIGHT", -PAD, 0)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_W)
    label:SetJustifyH("LEFT")
    label:SetTextColor(1, 0.82, 0)
    row._label = label

    local editBox = CreateFrame("EditBox", nil, row, "BackdropTemplate")
    editBox:SetHeight(EDIT_H)
    editBox:SetPoint("LEFT",  label, "RIGHT", 4, 0)
    editBox:SetPoint("RIGHT", row,   "RIGHT", -(BTN_W + 6), 0)
    editBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    editBox:SetFontObject("GameFontNormalSmall")
    editBox:SetTextColor(0.9, 0.9, 0.9, 1)
    editBox:SetTextInsets(6, 6, 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(0)
    editBox:SetScript("OnEscapePressed",   function() popup:Hide() end)
    editBox:SetScript("OnEnterPressed",    function() popup:Hide() end)
    editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    editBox:SetScript("OnEditFocusLost",   function(self) self:HighlightText(0, 0) end)
    editBox:SetScript("OnKeyUp", function(_, key)
        if IsControlKeyDown() and (key == "C" or key == "X") then popup:Hide() end
    end)
    row._editBox = editBox

    local copyBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
    copyBtn:SetSize(BTN_W, EDIT_H)
    copyBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    copyBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    copyBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    copyBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    local btnText = copyBtn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    btnText:SetPoint("CENTER")
    btnText:SetText("Select")
    btnText:SetTextColor(0.9, 0.9, 0.9, 1)
    copyBtn:SetScript("OnEnter", function()
        copyBtn:SetBackdropBorderColor(1, 1, 1, 1)
        btnText:SetTextColor(1, 1, 1, 1)
    end)
    copyBtn:SetScript("OnLeave", function()
        copyBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    copyBtn:SetScript("OnClick", function() editBox:SetFocus() end)

    return row
end

local function ShowCopyPopup(tooltipName, entries)
    if not entries or #entries == 0 then return end

    if not copyPopup then
        local POPUP_W = 300
        local TITLE_H = 28

        local popup = CreateFrame("Frame", "RRTTooltipCopyPopup", UIParent, "BackdropTemplate")
        popup:SetWidth(POPUP_W)
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
        popup:SetFrameStrata("DIALOG")
        popup:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        popup:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
        popup:SetBackdropBorderColor(0.639, 0.188, 0.788, 0.8)
        popup:EnableMouse(true)
        popup:EnableKeyboard(true)
        popup:SetPropagateKeyboardInput(true)
        popup:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false)
                self:Hide()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)

        local titleBar = CreateFrame("Frame", nil, popup)
        titleBar:SetHeight(TITLE_H)
        titleBar:SetPoint("TOPLEFT")
        titleBar:SetPoint("TOPRIGHT")

        local title = titleBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        title:SetPoint("LEFT",  titleBar, "LEFT",  12, 0)
        title:SetPoint("RIGHT", titleBar, "RIGHT", -TITLE_H, 0)
        title:SetJustifyH("LEFT")
        title:SetWordWrap(false)
        title:SetTextColor(1, 0.82, 0)
        popup._title = title

        local closeBtn = CreateFrame("Button", nil, titleBar)
        closeBtn:SetSize(TITLE_H, TITLE_H)
        closeBtn:SetPoint("TOPRIGHT")
        closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        closeBtn:GetNormalTexture():SetVertexColor(0.5, 0.5, 0.5, 1)
        closeBtn:SetScript("OnEnter", function() closeBtn:GetNormalTexture():SetVertexColor(1, 0.3, 0.3, 1) end)
        closeBtn:SetScript("OnLeave", function() closeBtn:GetNormalTexture():SetVertexColor(0.5, 0.5, 0.5, 1) end)
        closeBtn:SetScript("OnClick", function() popup:Hide() end)

        local rows = {}
        for i = 1, 2 do
            local row = CreateIDRow(popup, popup, i)
            row:SetPoint("TOP", popup, "TOP", 0, -(TITLE_H + 8 + (i - 1) * 32))
            rows[i] = row
        end
        popup._rows = rows

        local hint = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        hint:SetPoint("BOTTOMLEFT",  popup, "BOTTOMLEFT",  12, 10)
        hint:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -12, 10)
        hint:SetTextColor(0.5, 0.5, 0.5, 1)
        hint:SetText("Click 'Select', then press Ctrl+C to copy.")

        copyPopup = popup
    end

    copyPopup._title:SetText(tooltipName or "")

    local numRows = math.min(#entries, 2)
    for i = 1, 2 do
        local row   = copyPopup._rows[i]
        local entry = entries[i]
        if entry then
            row._label:SetText(entry.label)
            row._editBox:SetText(tostring(entry.id))
            row:Show()
        else
            row:Hide()
        end
    end

    copyPopup:SetHeight(28 + 8 + numRows * 32 + 32)
    copyPopup:Show()
    copyPopup._rows[1]._editBox:SetFocus()
    copyPopup._rows[1]._editBox:HighlightText()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Keyboard handler (Ctrl+C)
-- ─────────────────────────────────────────────────────────────────────────────

local _copyHandlerSetup = false

local function SetupCopyHandler()
    if _copyHandlerSetup then return end
    _copyHandlerSetup = true

    local copyFrame = CreateFrame("Frame", "RRTTooltipCopyFrame", UIParent)
    copyFrame:EnableKeyboard(false)
    copyFrame:SetPropagateKeyboardInput(true)

    GameTooltip:HookScript("OnShow", function()
        if not InCombatLockdown() then copyFrame:EnableKeyboard(true) end
    end)
    GameTooltip:HookScript("OnHide", function()
        if not InCombatLockdown() then copyFrame:EnableKeyboard(false) end
        lastTooltipName    = nil
        lastTooltipEntries = {}
    end)

    copyFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    copyFrame:SetScript("OnEvent", function(self)
        if GameTooltip:IsShown() then self:EnableKeyboard(true) end
    end)

    copyFrame:SetScript("OnKeyDown", function(self, key)
        if InCombatLockdown() then return end
        self:SetPropagateKeyboardInput(true)
        if not IsEnabled() or not db().copyOnCtrlC then return end
        if key == "C" and IsControlKeyDown() and not IsShiftKeyDown() then
            if lastTooltipName and #lastTooltipEntries > 0 then
                ShowCopyPopup(lastTooltipName, lastTooltipEntries)
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Tooltip hooks (registered once, gated by IsEnabled())
-- ─────────────────────────────────────────────────────────────────────────────

local _hooksSetup = false

local function SetupHooks()
    if _hooksSetup then return end
    if not TooltipDataProcessor or not TooltipDataProcessor.AddTooltipPostCall then return end
    _hooksSetup = true

    SetupCopyHandler()

    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
        if not IsEnabled() then return end
        if not data then return end
        local ok, _ = pcall(tooltip.GetName, tooltip)
        if not ok then return end

        local settings = db()
        local dataType = data.type

        -- Mount name on player unit tooltips (skip in instances / combat)
        if not IsInInstance() and not InCombatLockdown()
            and dataType == Enum.TooltipDataType.Unit and tooltip.GetUnit then
            local _, unit = tooltip:GetUnit()
            if unit and not issecretvalue(unit) and UnitIsPlayer(unit) and settings.showMount then
                local mountName = GetUnitMount(unit)
                if mountName and not HasLine(tooltip, "Mount") then
                    tooltip:AddDoubleLine("Mount", mountName, 1, 0.82, 0, 1, 1, 1)
                    tooltip:Show()
                end
            end
        end

        -- Item tooltips: ItemID + item use-effect SpellID
        if dataType == Enum.TooltipDataType.Item or dataType == Enum.TooltipDataType.Toy then
            if settings.showItemID and data.id then
                AddID(tooltip, "ItemID", data.id)
            end
            local itemSpellID
            if settings.showItemSpellID and data.id then
                local getSpell = (C_Item and C_Item.GetItemSpell) or GetItemSpell
                if getSpell then
                    local _, sid = getSpell(data.id)
                    if sid then
                        AddID(tooltip, "SpellID", sid)
                        itemSpellID = sid
                    end
                end
            end
            if tooltip == GameTooltip and data.id then
                local itemName = GetItemInfo(data.id)
                lastTooltipName    = itemName or ("Item " .. data.id)
                lastTooltipEntries = {}
                if settings.showItemID then
                    lastTooltipEntries[#lastTooltipEntries + 1] = { label = "ItemID", id = data.id }
                end
                if itemSpellID then
                    lastTooltipEntries[#lastTooltipEntries + 1] = { label = "SpellID", id = itemSpellID }
                end
                if settings.copyOnCtrlC and #lastTooltipEntries > 0 and not HasLine(tooltip, "Ctrl+C") then
                    tooltip:AddLine("|cFF888888Ctrl+C to copy|r")
                    tooltip:Show()
                end
            end
        end

        -- Spell / aura tooltips: SpellID
        if settings.showSpellID then
            local isTalent = false
            if dataType == Enum.TooltipDataType.Spell and tooltip.GetOwner then
                local owner = tooltip:GetOwner()
                isTalent = owner and owner.GetNodeID
            end
            if not isTalent then
                if dataType == Enum.TooltipDataType.Spell
                    or dataType == Enum.TooltipDataType.UnitAura
                    or dataType == Enum.TooltipDataType.Totem then
                    if data.id and not issecretvalue(data.id) then
                        AddID(tooltip, "SpellID", data.id)
                        if tooltip == GameTooltip then
                            local spellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(data.id)
                            lastTooltipName    = spellName or ("Spell " .. data.id)
                            lastTooltipEntries = { { label = "SpellID", id = data.id } }
                            if settings.copyOnCtrlC and not HasLine(tooltip, "Ctrl+C") then
                                tooltip:AddLine("|cFF888888Ctrl+C to copy|r")
                                tooltip:Show()
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Talent tree: SpellID + NodeID via EventRegistry
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("TalentDisplay.TooltipCreated", function(_, button, tooltip)
            if not IsEnabled() then return end
            local settings = db()

            local spellID
            if settings.showSpellID then
                spellID = button.GetSpellID and button:GetSpellID()
                if spellID then AddID(tooltip, "SpellID", spellID) end
            end

            local nodeID
            if settings.showNodeID then
                nodeID = (button.GetNodeID and button:GetNodeID())
                    or (button.GetNodeInfo and button:GetNodeInfo() and button:GetNodeInfo().ID)
                if nodeID then AddID(tooltip, "NodeID", nodeID) end
            end

            if spellID or nodeID then
                local spellName = spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
                lastTooltipName    = spellName or "Talent"
                lastTooltipEntries = {}
                if spellID then lastTooltipEntries[#lastTooltipEntries + 1] = { label = "SpellID", id = spellID } end
                if nodeID  then lastTooltipEntries[#lastTooltipEntries + 1] = { label = "NodeID",  id = nodeID  } end
                if settings.copyOnCtrlC and not HasLine(tooltip, "Ctrl+C") then
                    tooltip:AddLine("|cFF888888Ctrl+C to copy|r")
                    tooltip:Show()
                end
            end
        end)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────

local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    SetupHooks()
end

RRT_NS.Tooltip = module
