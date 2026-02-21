local _, RRT = ...
local DF = _G["DetailsFramework"]

RRT.BuffReminders = RRT.BuffReminders or {}
RRT.UI = RRT.UI or {}
RRT.UI.BuffReminders = RRT.UI.BuffReminders or {}

local BR = RRT.BuffReminders
local Core = RRT.UI.Core
local options_switch_template = Core.options_switch_template
local options_button_template = Core.options_button_template
local options_text_template = Core.options_text_template
local apply_scrollbar_style = Core.apply_scrollbar_style

local ITEM_HEIGHT = 22
local CONTENT_TOP_OFFSET = -39
local SECTION_SPACING = 12
local COL_PADDING = 20

local function GetSpellTextureSafe(spellID)
    if not spellID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellID)
    end
    return GetSpellTexture(spellID)
end

local function GetSpellNameSafe(spellID)
    if not spellID then
        return nil
    end
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end
    return GetSpellInfo(spellID)
end

local function EnsureDB()
    RRTDB.BuffReminders = RRTDB.BuffReminders or {}
    local db = RRTDB.BuffReminders
    db.enabledBuffs = db.enabledBuffs or {}
    db.customBuffs = db.customBuffs or {}
    return db
end

local function SyncCustomBuffsFromDB()
    if not BR.BUFF_TABLES then
        return
    end

    BR.BUFF_TABLES.custom = {}
    for key, custom in pairs(RRTDB.BuffReminders.customBuffs or {}) do
        local row = {}
        for k, v in pairs(custom) do
            row[k] = v
        end
        row.key = key
        table.insert(BR.BUFF_TABLES.custom, row)
    end

    table.sort(BR.BUFF_TABLES.custom, function(a, b)
        return tostring(a.key) < tostring(b.key)
    end)
end

local function ResolveBuffIcons(displayIcon, spellIDs)
    if displayIcon then
        if type(displayIcon) == "table" then
            return displayIcon
        end
        return { displayIcon }
    end

    if not spellIDs then
        return nil
    end

    local icons = {}
    local seen = {}
    local spellList = type(spellIDs) == "table" and spellIDs or { spellIDs }
    for _, spellID in ipairs(spellList) do
        local texture = GetSpellTextureSafe(spellID)
        if texture and not seen[texture] then
            seen[texture] = true
            table.insert(icons, texture)
        end
    end

    if #icons > 0 then
        return icons
    end

    return nil
end


local function ApplyRRTFont(fontString, size)
    if not fontString then
        return
    end
    local fontName = (RRTDB and RRTDB.Settings and RRTDB.Settings.GlobalFont) or "Friz Quadrata TT"
    local fetched = RRT.LSM and RRT.LSM.Fetch and RRT.LSM:Fetch("font", fontName)
    if fetched then
        fontString:SetFont(fetched, size or 10, "OUTLINE")
    end
end
local function ParseTooltipText(tooltip)
    if not tooltip then
        return nil, nil
    end

    if type(tooltip) == "table" then
        return tooltip.title, tooltip.desc
    end

    if type(tooltip) == "string" then
        local pipe = string.find(tooltip, "|", 1, true)
        if pipe then
            return string.sub(tooltip, 1, pipe - 1), string.sub(tooltip, pipe + 1)
        end
        return tooltip, nil
    end

    return nil, nil
end

local function CreateRow(parent, width, labelText, icons, checked, onToggle, onRightClick, tooltipTitle, tooltipDesc)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(width, ITEM_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local switch = DF:CreateSwitch(row, function(self, _, value)
        onToggle(value and true or false)
    end, checked and true or false, 20, 20, nil, nil, nil, nil, nil, nil, nil, nil, options_switch_template)
    switch:SetAsCheckBox()
    switch:SetPoint("LEFT", row, "LEFT", -2, 0)
    if switch.Text then
        switch.Text:SetText("")
        switch.Text:Hide()
    end

    local iconX = 22
    if icons and #icons > 0 then
        local iconLimit = math.min(#icons, 3)
        for i = 1, iconLimit do
            local tex = row:CreateTexture(nil, "ARTWORK")
            tex:SetSize(15, 15)
            tex:SetPoint("LEFT", row, "LEFT", iconX, 0)
            tex:SetTexture(icons[i])
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            iconX = iconX + 17
        end
    end

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(label, 10)
    label:SetPoint("LEFT", row, "LEFT", iconX, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    label:SetJustifyH("LEFT")
    label:SetText(labelText or "")

    row:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" and onRightClick then
            onRightClick()
        elseif button == "LeftButton" then
            if switch and switch.Click then switch:Click() end
        end
    end)

    if tooltipTitle then
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipTitle, 1, 1, 1)
            if tooltipDesc then
                GameTooltip:AddLine(tooltipDesc, 0.75, 0.75, 0.75, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return row
end

local function CreateSectionHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyRRTFont(header, 11)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText("|cffffcc00" .. text .. "|r")
    return header, y - 18
end

local function GenerateCustomBuffKey(spellID)
    if type(spellID) == "table" then
        local parts = {}
        for i, id in ipairs(spellID) do
            parts[i] = tostring(id)
        end
        table.sort(parts)
        return "custom_" .. table.concat(parts, "_")
    end
    return "custom_" .. tostring(spellID)
end

local function ValidateSpellID(spellID)
    if not spellID then
        return false
    end

    local name = GetSpellNameSafe(spellID)
    local texture = GetSpellTextureSafe(spellID)
    if name and texture then
        return true, name, texture
    end

    return false
end

local function BuildCustomBuffModal(existingKey, refreshCallback)
    local db = EnsureDB()
    local existing = existingKey and db.customBuffs[existingKey] or nil

    local CLASS_IDS = {
        WARRIOR = 1,
        PALADIN = 2,
        HUNTER = 3,
        ROGUE = 4,
        PRIEST = 5,
        DEATHKNIGHT = 6,
        SHAMAN = 7,
        MAGE = 8,
        WARLOCK = 9,
        MONK = 10,
        DRUID = 11,
        DEMONHUNTER = 12,
        EVOKER = 13,
    }

    local function BuildClassOptions()
        return {
            { value = nil, label = "Any" },
            { value = "DEATHKNIGHT", label = "Death Knight" },
            { value = "DEMONHUNTER", label = "Demon Hunter" },
            { value = "DRUID", label = "Druid" },
            { value = "EVOKER", label = "Evoker" },
            { value = "HUNTER", label = "Hunter" },
            { value = "MAGE", label = "Mage" },
            { value = "MONK", label = "Monk" },
            { value = "PALADIN", label = "Paladin" },
            { value = "PRIEST", label = "Priest" },
            { value = "ROGUE", label = "Rogue" },
            { value = "SHAMAN", label = "Shaman" },
            { value = "WARLOCK", label = "Warlock" },
            { value = "WARRIOR", label = "Warrior" },
        }
    end

    local function BuildSpecOptions(classToken)
        local specs = { { value = nil, label = "Any" } }
        local classID = CLASS_IDS[classToken]
        if not classID then
            return specs
        end
        for i = 1, 4 do
            local specID, name = GetSpecializationInfoForClassID(classID, i)
            if specID and name then
                table.insert(specs, { value = specID, label = name })
            end
        end
        table.sort(specs, function(a, b)
            if a.value == nil then return true end
            if b.value == nil then return false end
            return a.label < b.label
        end)
        return specs
    end

    local function BuildDropdownValues(options, onSelect)
        local values = {}
        for _, opt in ipairs(options) do
            table.insert(values, {
                label = opt.label,
                value = opt.value,
                onclick = function(_, _, value)
                    if onSelect then
                        onSelect(value)
                    end
                end,
            })
        end
        return values
    end

    local modal = RRT.BuffRemindersCustomBuffModal
    if modal and modal:IsShown() then
        modal:Hide()
    end

    if not StaticPopupDialogs["RRT_BUFFREM_DELETE_CUSTOM"] then
        StaticPopupDialogs["RRT_BUFFREM_DELETE_CUSTOM"] = {
            text = 'Delete custom buff "%s"?',
            button1 = "Delete",
            button2 = "Cancel",
            OnAccept = function(_, data)
                if data and data.key then
                    db.customBuffs[data.key] = nil
                    db.enabledBuffs[data.key] = nil
                    SyncCustomBuffsFromDB()
                    if data.refresh then data.refresh() end
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    if not modal then
        modal = DF:CreateSimplePanel(UIParent, 460, 410, "Custom Buff", "RRT_BuffRemindersCustomBuffModal", {
            DontRightClickClose = true,
        })
        modal:SetFrameStrata("DIALOG")
        RRT.BuffRemindersCustomBuffModal = modal

        modal.rowFrames = {}
        modal.validatedRows = {}

        modal.spellIdsLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modal.spellIdsLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, -40)
        modal.spellIdsLabel:SetText("Spell IDs:")
        ApplyRRTFont(modal.spellIdsLabel, 10)

        modal.rowsAnchor = CreateFrame("Frame", nil, modal)
        modal.rowsAnchor:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, -60)
        modal.rowsAnchor:SetSize(420, 150)

        modal.addSpellBtn = DF:CreateButton(modal, function() end, 110, 20, "+ Add Spell ID")
        modal.addSpellBtn:SetTemplate(options_button_template)

        modal.nameLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modal.nameLabel:SetText("Name")
        ApplyRRTFont(modal.nameLabel, 10)

        modal.nameEdit = CreateFrame("EditBox", nil, modal, "InputBoxTemplate")
        modal.nameEdit:SetAutoFocus(false)
        modal.nameEdit:SetSize(200, 22)

        modal.textLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modal.textLabel:SetText("Text")
        ApplyRRTFont(modal.textLabel, 10)

        modal.textEdit = CreateFrame("EditBox", nil, modal, "InputBoxTemplate")
        modal.textEdit:SetAutoFocus(false)
        modal.textEdit:SetSize(200, 22)

        modal.textHint = modal:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        modal.textHint:SetText("(use \\n for line break)")
        ApplyRRTFont(modal.textHint, 9)

        modal.classLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modal.classLabel:SetText("Class")
        ApplyRRTFont(modal.classLabel, 10)

        modal.specLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modal.specLabel:SetText("Spec")
        ApplyRRTFont(modal.specLabel, 10)

        modal.showWhenPresent = DF:CreateSwitch(modal, function(self, _, value)
            if value then
                if modal.showWhenPresentLabel then modal.showWhenPresentLabel:SetText("When active") end
            else
                if modal.showWhenPresentLabel then modal.showWhenPresentLabel:SetText("When missing") end
            end
        end, false, 20, 20, nil, nil, nil, nil, nil, nil, nil, nil, options_switch_template)
        modal.showWhenPresent:SetAsCheckBox()

        modal.showWhenPresentLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modal.showWhenPresentLabel:SetText("When missing")
        ApplyRRTFont(modal.showWhenPresentLabel, 10)

        modal.requireKnown = DF:CreateSwitch(modal, function() end, false, 20, 20, nil, nil, nil, nil, nil, nil, nil, nil, options_switch_template)
        modal.requireKnown:SetAsCheckBox()

        modal.requireKnownLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modal.requireKnownLabel:SetText("Only if spell known")
        ApplyRRTFont(modal.requireKnownLabel, 10)

        modal.glowLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modal.glowLabel:SetText("Bar glow")
        ApplyRRTFont(modal.glowLabel, 10)

        modal.err = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        modal.err:SetTextColor(1, 0.25, 0.25, 1)
        modal.err:SetJustifyH("LEFT")
        modal.err:SetWidth(320)
        ApplyRRTFont(modal.err, 9)

        modal.saveBtn = DF:CreateButton(modal, function() end, 90, 22, "Save")
        modal.saveBtn:SetTemplate(options_button_template)
        modal.deleteBtn = DF:CreateButton(modal, function() end, 90, 22, "Delete")
        modal.deleteBtn:SetTemplate(options_button_template)
        modal.cancelBtn = DF:CreateButton(modal, function() modal:Hide() end, 90, 22, "Cancel")
        modal.cancelBtn:SetTemplate(options_button_template)

        modal.saveBtn:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 14)
        modal.deleteBtn:SetPoint("RIGHT", modal.saveBtn, "LEFT", -8, 0)
        modal.cancelBtn:SetPoint("RIGHT", modal.deleteBtn, "LEFT", -8, 0)

        modal.classOptions = BuildClassOptions()
        modal.classDropdown = DF:CreateDropDown(modal, function()
            return BuildDropdownValues(modal.classOptions, function(value)
                modal.selectedClass = value
                local specOptions = BuildSpecOptions(value)
                modal.specOptions = specOptions
                modal.selectedSpec = nil
                modal.specDropdown:Refresh()
                modal.specDropdown:Select(nil)
            end)
        end, nil, 150)
        modal.classDropdown:SetTemplate(Core.options_dropdown_template)

        modal.specOptions = { { value = nil, label = "Any" } }
        modal.specDropdown = DF:CreateDropDown(modal, function()
            return BuildDropdownValues(modal.specOptions, function(value)
                modal.selectedSpec = value
            end)
        end, nil, 150)
        modal.specDropdown:SetTemplate(Core.options_dropdown_template)

        modal.glowOptions = {
            { value = "whenGlowing", label = "Detect when glowing" },
            { value = "whenNotGlowing", label = "Detect when not glowing" },
            { value = "disabled", label = "Disabled" },
        }
        modal.glowDropdown = DF:CreateDropDown(modal, function()
            return BuildDropdownValues(modal.glowOptions, function(value)
                modal.selectedGlow = value
            end)
        end, nil, 190)
        modal.glowDropdown:SetTemplate(Core.options_dropdown_template)
        local function RaiseDropdownLayer(dropdown)
            if not dropdown then
                return
            end
            if dropdown.SetFrameStrata then dropdown:SetFrameStrata("TOOLTIP") end
            if dropdown.SetFrameLevel then dropdown:SetFrameLevel(modal:GetFrameLevel() + 30) end
            if dropdown.widget and dropdown.widget.SetFrameStrata then dropdown.widget:SetFrameStrata("TOOLTIP") end
            if dropdown.widget and dropdown.widget.SetFrameLevel then dropdown.widget:SetFrameLevel(modal:GetFrameLevel() + 31) end
            if dropdown.dropdown and dropdown.dropdown.SetFrameStrata then dropdown.dropdown:SetFrameStrata("TOOLTIP") end
            if dropdown.dropdown and dropdown.dropdown.SetFrameLevel then dropdown.dropdown:SetFrameLevel(modal:GetFrameLevel() + 32) end
        end
        RaiseDropdownLayer(modal.classDropdown)
        RaiseDropdownLayer(modal.specDropdown)
        RaiseDropdownLayer(modal.glowDropdown)

        local function CreateSpellRow(initialSpellID)
            local row = CreateFrame("Frame", nil, modal.rowsAnchor)
            row:SetSize(420, 22)

            row.edit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            row.edit:SetAutoFocus(false)
            row.edit:SetNumeric(true)
            row.edit:SetSize(70, 20)
            row.edit:SetPoint("LEFT", row, "LEFT", 0, 0)

            row.lookup = DF:CreateButton(row, function() end, 56, 20, "Lookup")
            row.lookup:SetTemplate(options_button_template)
            row.lookup:SetPoint("LEFT", row.edit, "RIGHT", 6, 0)

            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            row.icon:SetPoint("LEFT", row, "LEFT", 140, 0)
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.icon:Hide()

            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
            row.name:SetPoint("RIGHT", row, "RIGHT", -26, 0)
            row.name:SetJustifyH("LEFT")
            row.name:SetWordWrap(false)
            ApplyRRTFont(row.name, 9)

            row.remove = DF:CreateButton(row, function() end, 20, 20, "-")
            row.remove:SetTemplate(options_button_template)
            row.remove:SetPoint("RIGHT", row, "RIGHT", 0, 0)

            if initialSpellID then
                row.edit:SetText(tostring(initialSpellID))
            end

            row.validated = false
            row.spellID = nil
            row.spellName = nil

            row.lookup:SetScript("OnClick", function()
                local spellID = tonumber(row.edit:GetText())
                if not spellID then
                    row.validated, row.spellID, row.spellName = false, nil, nil
                    row.icon:Hide()
                    row.name:SetText("|cffff4d4dInvalid ID|r")
                    return
                end
                local valid, sName, tex = ValidateSpellID(spellID)
                if valid then
                    row.validated, row.spellID, row.spellName = true, spellID, sName
                    row.icon:SetTexture(tex)
                    row.icon:Show()
                    row.name:SetText(sName or "")
                else
                    row.validated, row.spellID, row.spellName = false, nil, nil
                    row.icon:Hide()
                    row.name:SetText("|cffff4d4dNot found|r")
                end
            end)

            row.remove:SetScript("OnClick", function()
                for i, rf in ipairs(modal.rowFrames) do
                    if rf == row then
                        table.remove(modal.rowFrames, i)
                        row:Hide()
                        break
                    end
                end
                modal.UpdateLayout()
            end)

            table.insert(modal.rowFrames, row)
        end

        modal.CreateSpellRow = CreateSpellRow

        function modal.UpdateLayout()
            local rowCount = #modal.rowFrames
            for i, row in ipairs(modal.rowFrames) do
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", modal.rowsAnchor, "TOPLEFT", 0, -((i - 1) * 24))
                row.remove:SetShown(rowCount > 1)
            end

            local addY = -60 - (rowCount * 24) - 2
            modal.addSpellBtn:ClearAllPoints()
            modal.addSpellBtn:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, addY)

            local formTop = addY - 30
            modal.nameLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, formTop)
            modal.nameEdit:SetPoint("TOPLEFT", modal.nameLabel, "BOTTOMLEFT", 0, -4)

            modal.textLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 240, formTop)
            modal.textEdit:SetPoint("TOPLEFT", modal.textLabel, "BOTTOMLEFT", 0, -4)
            modal.textHint:SetPoint("TOPLEFT", modal.textEdit, "BOTTOMLEFT", 0, -4)

            local restrictionsY = formTop - 58
            modal.classLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, restrictionsY)
            modal.classDropdown:SetPoint("TOPLEFT", modal.classLabel, "BOTTOMLEFT", 0, -3)
            modal.specLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 190, restrictionsY)
            modal.specDropdown:SetPoint("TOPLEFT", modal.specLabel, "BOTTOMLEFT", 0, -3)

            local visibilityY = restrictionsY - 58
            modal.showWhenPresent:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, visibilityY)
            modal.showWhenPresentLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 38, visibilityY - 1)
            modal.requireKnown:SetPoint("TOPLEFT", modal, "TOPLEFT", 190, visibilityY)
            modal.requireKnownLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 212, visibilityY - 1)

            local advancedY = visibilityY - 36
            modal.glowLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, advancedY)
            modal.glowDropdown:SetPoint("TOPLEFT", modal.glowLabel, "BOTTOMLEFT", 0, -3)

            modal.err:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 18, 44)

            local baseH = 410
            local extraH = math.max(0, rowCount - 1) * 24
            modal:SetHeight(baseH + extraH)
        end

        modal.addSpellBtn:SetScript("OnClick", function()
            modal.CreateSpellRow(nil)
            modal.UpdateLayout()
        end)

        modal.saveBtn:SetScript("OnClick", function()
            local validated = {}
            local firstName = nil
            for _, row in ipairs(modal.rowFrames) do
                if row.lookup and row.lookup.Click then
                    row.lookup:Click()
                end
                if row.validated and row.spellID then
                    table.insert(validated, row.spellID)
                    if not firstName then
                        firstName = row.spellName
                    end
                end
            end

            if #validated == 0 then
                modal.err:SetText("Please validate at least one spell ID")
                return
            end

            modal.err:SetText("")
            local spellIDValue = (#validated == 1) and validated[1] or validated

            local displayName = strtrim(modal.nameEdit:GetText() or "")
            if displayName == "" then
                displayName = firstName or ("Spell " .. tostring(validated[1]))
            end

            local missingText = strtrim(modal.textEdit:GetText() or "")
            if missingText ~= "" then
                missingText = missingText:gsub("\\n", "\n")
            else
                missingText = nil
            end

            local key = modal.editKey or GenerateCustomBuffKey(spellIDValue)
            if not modal.editKey and db.customBuffs[key] then
                local suffix = 2
                while db.customBuffs[key .. "_" .. suffix] do suffix = suffix + 1 end
                key = key .. "_" .. suffix
            end

            local glowMode = modal.selectedGlow
            if glowMode == "whenGlowing" then
                glowMode = nil
            end

            db.customBuffs[key] = {
                key = key,
                spellID = spellIDValue,
                name = displayName,
                missingText = missingText,
                class = modal.selectedClass,
                requireSpecId = modal.selectedSpec,
                showWhenPresent = modal.showWhenPresent:GetValue() and true or nil,
                requireSpellKnown = modal.requireKnown:GetValue() and true or nil,
                glowMode = glowMode,
            }

            if db.enabledBuffs[key] == nil then
                db.enabledBuffs[key] = true
            end

            SyncCustomBuffsFromDB()
            if refreshCallback then refreshCallback() end
            modal:Hide()
        end)

        modal.deleteBtn:SetScript("OnClick", function()
            if not modal.editKey then
                modal:Hide()
                return
            end
            local name = (db.customBuffs[modal.editKey] and db.customBuffs[modal.editKey].name) or modal.editKey
            modal:Hide()
            StaticPopup_Show("RRT_BUFFREM_DELETE_CUSTOM", name, nil, {
                key = modal.editKey,
                refresh = refreshCallback,
            })
        end)
    end

    modal.editKey = existingKey
    modal.err:SetText("")

    for _, row in ipairs(modal.rowFrames) do
        row:Hide()
    end
    wipe(modal.rowFrames)

    local spellIDs = {}
    if existing and type(existing.spellID) == "table" then
        for _, id in ipairs(existing.spellID) do table.insert(spellIDs, id) end
    elseif existing and existing.spellID then
        table.insert(spellIDs, existing.spellID)
    else
        table.insert(spellIDs, nil)
    end

    for _, id in ipairs(spellIDs) do
        modal.CreateSpellRow(id)
    end

    modal.nameEdit:SetText(existing and existing.name or "")
    modal.textEdit:SetText(existing and existing.missingText and existing.missingText:gsub("\n", "\\n") or "")

    modal.selectedClass = existing and existing.class or nil
    modal.classDropdown:Refresh()
    modal.classDropdown:Select(modal.selectedClass)

    modal.specOptions = BuildSpecOptions(modal.selectedClass)
    modal.selectedSpec = existing and existing.requireSpecId or nil
    modal.specDropdown:Refresh()
    modal.specDropdown:Select(modal.selectedSpec)

    local showPresent = existing and existing.showWhenPresent or false
    modal.showWhenPresent:SetValue(showPresent)
    modal.showWhenPresentLabel:SetText(showPresent and "When active" or "When missing")
    modal.requireKnown:SetValue(existing and existing.requireSpellKnown or false)

    modal.selectedGlow = existing and existing.glowMode or "whenGlowing"
    modal.glowDropdown:Refresh()
    modal.glowDropdown:Select(modal.selectedGlow)

    modal.deleteBtn:SetShown(existingKey and true or false)
    modal:SetTitle(existing and "Edit Custom Buff" or "Add Custom Buff")
    modal.UpdateLayout()
    modal:Show()
end

local function BuildBuffsTab(parent)
    local db = EnsureDB()
    SyncCustomBuffsFromDB()

    if parent.BuffsView then
        parent.BuffsView:Show()
        if parent.BuffsView.Refresh then
            parent.BuffsView:Refresh()
        end
        return parent.BuffsView
    end

    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()

    local scroll = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 6, CONTENT_TOP_OFFSET)
    scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -26, 6)
    if apply_scrollbar_style then
        apply_scrollbar_style(scroll)
    end

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT")
    content:SetSize(math.max(200, container:GetWidth() - 30), 900)
    scroll:SetScrollChild(content)

    container:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(math.max(200, width - 30))
    end)

    local BUFF_TABLES = BR.BUFF_TABLES or {}
    local BuffGroups = BR.BuffGroups or {}

    local RaidBuffs = BUFF_TABLES.raid or {}
    local PresenceBuffs = BUFF_TABLES.presence or {}
    local TargetedBuffs = BUFF_TABLES.targeted or {}
    local SelfBuffs = BUFF_TABLES.self or {}
    local PetBuffs = BUFF_TABLES.pet or {}
    local Consumables = BUFF_TABLES.consumable or {}

    local function RenderBuffCheckboxes(parentFrame, x, y, colWidth, buffArray)
        local groupSpells = {}
        local groupDisplaySpells = {}
        local groupIconOverrides = {}

        for _, buff in ipairs(buffArray) do
            if buff.groupId then
                groupSpells[buff.groupId] = groupSpells[buff.groupId] or {}
                groupDisplaySpells[buff.groupId] = groupDisplaySpells[buff.groupId] or {}

                if buff.spellID then
                    local spellList = type(buff.spellID) == "table" and buff.spellID or { buff.spellID }
                    for _, id in ipairs(spellList) do
                        table.insert(groupSpells[buff.groupId], id)
                    end
                end

                if buff.displaySpells then
                    local displayList = type(buff.displaySpells) == "table" and buff.displaySpells or { buff.displaySpells }
                    for _, id in ipairs(displayList) do
                        table.insert(groupDisplaySpells[buff.groupId], id)
                    end
                end

                if not groupIconOverrides[buff.groupId] then
                    groupIconOverrides[buff.groupId] = {}
                    groupIconOverrides[buff.groupId]._seen = {}
                end

                local seen = groupIconOverrides[buff.groupId]._seen
                if buff.displayIcon then
                    local overrides = type(buff.displayIcon) == "table" and buff.displayIcon or { buff.displayIcon }
                    for _, icon in ipairs(overrides) do
                        if not seen[icon] then
                            seen[icon] = true
                            table.insert(groupIconOverrides[buff.groupId], icon)
                        end
                    end
                elseif buff.displaySpells then
                    local displayList = type(buff.displaySpells) == "table" and buff.displaySpells or { buff.displaySpells }
                    for _, id in ipairs(displayList) do
                        local texture = GetSpellTextureSafe(id)
                        if texture and not seen[texture] then
                            seen[texture] = true
                            table.insert(groupIconOverrides[buff.groupId], texture)
                        end
                    end
                elseif buff.spellID then
                    local primarySpell = type(buff.spellID) == "table" and buff.spellID[1] or buff.spellID
                    local texture = GetSpellTextureSafe(primarySpell)
                    if texture and not seen[texture] then
                        seen[texture] = true
                        table.insert(groupIconOverrides[buff.groupId], texture)
                    end
                end
            end
        end

        local seenGroups = {}

        for _, buff in ipairs(buffArray) do
            if buff.groupId then
                if not seenGroups[buff.groupId] then
                    seenGroups[buff.groupId] = true
                    local groupInfo = BuffGroups[buff.groupId] or { displayName = buff.groupId }
                    local displayIcon = groupIconOverrides[buff.groupId]
                    if displayIcon and #displayIcon == 0 then
                        displayIcon = nil
                    end

                    local displaySpells = groupDisplaySpells[buff.groupId]
                    local spells = (displaySpells and #displaySpells > 0) and displaySpells or groupSpells[buff.groupId]
                    if spells and #spells == 0 then
                        spells = nil
                    end

                    local ttTitle, ttDesc = ParseTooltipText(buff.infoTooltip)
                    local row = CreateRow(
                        parentFrame,
                        colWidth,
                        groupInfo.displayName,
                        ResolveBuffIcons(displayIcon, spells),
                        db.enabledBuffs[buff.groupId] ~= false,
                        function(checked)
                            db.enabledBuffs[buff.groupId] = checked
                        end,
                        nil,
                        ttTitle,
                        ttDesc
                    )
                    row:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", x, y)
                    y = y - ITEM_HEIGHT
                end
            else
                local displaySpells = buff.displaySpells or buff.spellID
                local ttTitle, ttDesc = ParseTooltipText(buff.infoTooltip)
                local row = CreateRow(
                    parentFrame,
                    colWidth,
                    buff.name,
                    ResolveBuffIcons(buff.displayIcon, displaySpells),
                    db.enabledBuffs[buff.key] ~= false,
                    function(checked)
                        db.enabledBuffs[buff.key] = checked
                    end,
                    nil,
                    ttTitle,
                    ttDesc
                )
                row:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", x, y)
                y = y - ITEM_HEIGHT
            end
        end

        return y
    end

    local function RefreshLayout()
        for _, child in ipairs({ content:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end

        local totalWidth = content:GetWidth() - COL_PADDING * 4
        local colWidth = math.max(170, math.floor(totalWidth / 3))

        local col1X = COL_PADDING
        local col2X = COL_PADDING + colWidth + COL_PADDING
        local col3X = col2X + colWidth + COL_PADDING

        local col1Y = CONTENT_TOP_OFFSET + 4
        local col2Y = CONTENT_TOP_OFFSET + 4
        local col3Y = CONTENT_TOP_OFFSET + 4

        local function AddNote(x, y, text)
            local note = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            ApplyRRTFont(note, 9)
            note:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
            note:SetWidth(colWidth - 4)
            note:SetJustifyH("LEFT")
            note:SetText(text)
            return y - 14
        end

        _, col1Y = CreateSectionHeader(content, "Raid Buffs", col1X, col1Y)
        col1Y = AddNote(col1X, col1Y, "(for the whole group)")
        col1Y = RenderBuffCheckboxes(content, col1X, col1Y, colWidth, RaidBuffs)
        col1Y = col1Y - SECTION_SPACING

        _, col1Y = CreateSectionHeader(content, "Presence Buffs", col1X, col1Y)
        col1Y = AddNote(col1X, col1Y, "(at least 1 person needs)")
        col1Y = RenderBuffCheckboxes(content, col1X, col1Y, colWidth, PresenceBuffs)

        _, col2Y = CreateSectionHeader(content, "Targeted Buffs", col2X, col2Y)
        col2Y = AddNote(col2X, col2Y, "(buffs on someone else)")
        col2Y = RenderBuffCheckboxes(content, col2X, col2Y, colWidth, TargetedBuffs)
        col2Y = col2Y - SECTION_SPACING

        _, col2Y = CreateSectionHeader(content, "Self Buffs", col2X, col2Y)
        col2Y = AddNote(col2X, col2Y, "(buffs strictly on yourself)")
        col2Y = RenderBuffCheckboxes(content, col2X, col2Y, colWidth, SelfBuffs)

        _, col3Y = CreateSectionHeader(content, "Consumables", col3X, col3Y)
        col3Y = AddNote(col3X, col3Y, "(flasks, food, runes, oils)")
        col3Y = RenderBuffCheckboxes(content, col3X, col3Y, colWidth, Consumables)
        col3Y = col3Y - SECTION_SPACING

        _, col3Y = CreateSectionHeader(content, "Pet Reminders", col3X, col3Y)
        col3Y = AddNote(col3X, col3Y, "(pet summon reminders)")
        col3Y = RenderBuffCheckboxes(content, col3X, col3Y, colWidth, PetBuffs)
        col3Y = col3Y - SECTION_SPACING

        _, col3Y = CreateSectionHeader(content, "Custom Buffs", col3X, col3Y)
        col3Y = AddNote(col3X, col3Y, "(track any buff by spell ID)")

        local customKeys = {}
        for key in pairs(db.customBuffs) do
            table.insert(customKeys, key)
        end
        table.sort(customKeys)

        for _, key in ipairs(customKeys) do
            local custom = db.customBuffs[key]
            local row = CreateRow(
                content,
                colWidth,
                custom.name or ("Spell " .. tostring(custom.spellID)),
                ResolveBuffIcons(nil, custom.spellID),
                db.enabledBuffs[key] ~= false,
                function(checked)
                    db.enabledBuffs[key] = checked
                end,
                function()
                    BuildCustomBuffModal(key, function()
                        SyncCustomBuffsFromDB()
                        RefreshLayout()
                    end)
                end,
                "Custom Buff",
                "Right-click to edit or delete"
            )
            row:SetPoint("TOPLEFT", content, "TOPLEFT", col3X, col3Y)
            col3Y = col3Y - ITEM_HEIGHT
        end

        local addBtn = DF:CreateButton(content, function()
            BuildCustomBuffModal(nil, function()
                SyncCustomBuffsFromDB()
                RefreshLayout()
            end)
        end, 140, 22, "+ Add Custom Buff")
        addBtn:SetPoint("TOPLEFT", content, "TOPLEFT", col3X, col3Y - 4)
        addBtn:SetTemplate(options_button_template)
        col3Y = col3Y - 30

        local finalHeight = math.max(math.abs(col1Y), math.abs(col2Y), math.abs(col3Y)) + 30
        content:SetHeight(finalHeight)
    end

    container.Refresh = function()
        SyncCustomBuffsFromDB()
        RefreshLayout()
    end

    container:Refresh()
    parent.BuffsView = container
    return container
end

RRT.UI.BuffReminders.Buffs = {
    Build = BuildBuffsTab,
}
