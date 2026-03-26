local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core = RRT_NS.UI.Core
local RRTUI = Core.RRTUI
local window_width = Core.window_width
local window_height = Core.window_height
local options_text_template = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template = Core.options_switch_template
local options_button_template = Core.options_button_template

-- Version check state
local component_type = "Addon"
local checkable_components = {"Addon", "Note", "Reminder", "ReversionRaidTools"}

-- Forward ref: updated after the button is created in BuildVersionCheckUI
local _checkButtonRef = nil
local function _UpdateCheckButton()
    if not _checkButtonRef then return end
    -- ReversionRaidTools check is open to everyone (checks own install)
    if component_type == "ReversionRaidTools"
    or UnitIsGroupLeader("player")
    or UnitIsGroupAssistant("player")
    or RRT.Settings["Debug"] then
        _checkButtonRef:Enable()
    else
        _checkButtonRef:Disable()
    end
end

local function build_checkable_components_options()
    local t = {}
    for i = 1, #checkable_components do
        tinsert(t, {
            label = checkable_components[i],
            value = checkable_components[i],
            onclick = function(_, _, value)
                component_type = value
                _UpdateCheckButton()
            end
        })
    end
    return t
end

local component_name = ""

-- Custom dark scrollbar for FauxScrollFrame-based DF scrollboxes
local function MakeFauxScrollBar(scrollBox, name, numLines)
    local scrollBar = _G[name .. "ScrollBar"]
    if scrollBar then
        scrollBar:SetAlpha(0)
        scrollBar:EnableMouse(false)
    end
    local upBtn = _G[name .. "ScrollBarScrollUpButton"]
    local dnBtn = _G[name .. "ScrollBarScrollDownButton"]
    if upBtn then upBtn:Hide() upBtn:EnableMouse(false) end
    if dnBtn then dnBtn:Hide() dnBtn:EnableMouse(false) end

    local track = CreateFrame("Frame", nil, scrollBox:GetParent(), "BackdropTemplate")
    track:SetWidth(8)
    track:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    track:SetBackdropColor(0.08, 0.08, 0.10, 0.85)
    track:SetBackdropBorderColor(0, 0, 0, 1)
    track:EnableMouse(true)

    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    thumb:SetBackdropColor(0.45, 0.45, 0.45, 0.75)
    thumb:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    thumb:EnableMouse(true)

    local function UpdateThumb()
        if not scrollBar then return end
        local _, maxV = scrollBar:GetMinMaxValues()
        local curV = scrollBar:GetValue()
        local trackH = track:GetHeight() or 1
        if maxV <= 0 then
            thumb:Hide()
            return
        end
        local thumbH = math.max(16, trackH * (numLines / (numLines + maxV)))
        thumb:Show()
        thumb:SetWidth(track:GetWidth() - 2)
        thumb:SetHeight(thumbH)
        local travel = trackH - thumbH
        local pct    = math.max(0, math.min(1, curV / maxV))
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -(travel * pct))
    end

    if scrollBar then
        scrollBar:HookScript("OnValueChanged", function() UpdateThumb() end)
    end

    track:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not scrollBar then return end
        local _, maxV = scrollBar:GetMinMaxValues()
        if maxV <= 0 then return end
        local cy  = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local top = track:GetTop()
        local bot = track:GetBottom()
        if not top or not bot or top == bot then return end
        local pct = 1 - ((cy - bot) / (top - bot))
        scrollBar:SetValue(math.max(0, math.min(maxV, pct * maxV)))
    end)

    local isDragging, dragStartY, dragStartVal = false, 0, 0
    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not scrollBar then return end
        isDragging   = true
        dragStartY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartVal = scrollBar:GetValue()
    end)
    thumb:SetScript("OnMouseUp", function() isDragging = false end)
    thumb:SetScript("OnUpdate", function()
        if not isDragging or not scrollBar then return end
        local _, maxV = scrollBar:GetMinMaxValues()
        if maxV <= 0 then return end
        local cy     = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local trackH = track:GetHeight() or 1
        local thumbH = thumb:GetHeight() or 1
        local travel = trackH - thumbH
        if travel <= 0 then return end
        local delta  = dragStartY - cy
        scrollBar:SetValue(math.max(0, math.min(maxV, dragStartVal + (delta / travel) * maxV)))
    end)
    thumb:SetScript("OnEnter", function(self) self:SetBackdropColor(0.65, 0.65, 0.65, 0.95) end)
    thumb:SetScript("OnLeave", function(self) self:SetBackdropColor(0.45, 0.45, 0.45, 0.75) end)

    track:HookScript("OnShow", UpdateThumb)
    scrollBox:HookScript("OnShow", UpdateThumb)

    return track
end

local function BuildVersionCheckUI(parent)

    local hide_version_response_button = DF:CreateSwitch(parent,
        function(self, _, value) RRT.Settings["VersionCheckRemoveResponse"] = value end,
        RRT.Settings["VersionCheckRemoveResponse"], 20, 20, nil, nil, nil, "VersionCheckResponseToggle", nil, nil, nil,
        "Hide Version Check Responses", options_switch_template, options_text_template)
    hide_version_response_button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -100)
    hide_version_response_button:SetAsCheckBox()
    hide_version_response_button:SetTooltip(
        "Hides Version Check Responses of Users that are on the correct version")
    local hide_version_response_label = DF:CreateLabel(parent, "Hide Version Check Responses", 10, "white", "", nil,
        "VersionCheckResponseLabel", "overlay")
    hide_version_response_label:SetTemplate(options_text_template)
    hide_version_response_label:SetPoint("LEFT", hide_version_response_button, "RIGHT", 2, 0)
    local component_type_label = DF:CreateLabel(parent, "Component Type", 9.5, "white")
    component_type_label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -130)

    local component_type_dropdown = DF:CreateDropDown(parent, function() return build_checkable_components_options() end, checkable_components[1])
    component_type_dropdown:SetTemplate(options_dropdown_template)
    component_type_dropdown:SetPoint("LEFT", component_type_label, "RIGHT", 5, 0)

    local component_name_label = DF:CreateLabel(parent, "Addon Name", 9.5, "white")
    component_name_label:SetPoint("LEFT", component_type_dropdown, "RIGHT", 10, 0)

    local component_name_entry = DF:CreateTextEntry(parent, function(_, _, value) component_name = value end, 250, 18)
    component_name_entry:SetTemplate(options_button_template)
    component_name_entry:SetPoint("LEFT", component_name_label, "RIGHT", 5, 0)
    component_name_entry:SetHook("OnEditFocusGained", function(self)
        component_name_entry.AddonAutoCompleteList = RRT.RRTUI.AutoComplete["Addon"] or {}
        local component_type = component_type_dropdown:GetValue()
        if component_type == "Addon" then
            component_name_entry:SetAsAutoComplete("AddonAutoCompleteList", _, true)
        end
    end)

    local version_check_button = DF:CreateButton(parent, function()
    end, 120, 20, "Check Versions")
    version_check_button:SetTemplate(options_button_template)
    version_check_button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -130)
    _checkButtonRef = version_check_button
    version_check_button:SetHook("OnShow", function(self)
        _UpdateCheckButton()
    end)

    local character_name_header = DF:CreateLabel(parent, "Character Name", 11)
    character_name_header:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -158)

    local version_number_header = DF:CreateLabel(parent, "Version Number", 11)
    version_number_header:SetPoint("LEFT", character_name_header, "RIGHT", 120, 0)

    local ignore_header = DF:CreateLabel(parent, "Ignore Check", 11)
    ignore_header:SetPoint("LEFT", version_number_header, "RIGHT", 50, 0)

    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local thisData = data[index]
            local line = self:GetLine(i)
            if not line then break end
            if thisData then
                local name = thisData.name
                local version = thisData.version
                local ignore = thisData.ignoreCheck
                local nickname = RRTAPI:Shorten(name)

                line.name:SetText(nickname or "")
                line.version:SetText(version or "")
                line.ignorelist:SetText(ignore and "Yes" or "No")

                if version and version == "Offline" then
                    line.version:SetTextColor(0.5, 0.5, 0.5, 1)
                elseif version and data[1] and data[1].version and version == data[1].version then
                    line.version:SetTextColor(0, 1, 0, 1)
                else
                    line.version:SetTextColor(1, 0, 0, 1)
                end

                if ignore then
                    line.ignorelist:SetTextColor(1, 0, 0, 1)
                else
                    line.ignorelist:SetTextColor(0, 1, 0, 1)
                end

            else
                line.name:SetText("")
                line.version:SetText("")
                line.ignorelist:SetText("")
            end
            if thisData then
                line:SetScript("OnClick", function(self)
                    local vc = RRT_NS.VersionCheckData
                    if not vc or not vc.lastclick then return end
                    local message = ""
                    local now = GetTime()
                    if (vc.lastclick[name] and now < vc.lastclick[name] + 5) or (thisData.version == vc.version and (not thisData.ignoreCheck)) or thisData.version == "No Response" then return end
                    vc.lastclick[name] = now
                    if vc.type == "ReversionRaidTools" then
                        if thisData.version == "Not Installed" then message = "Please install ReversionRaidTools"
                        elseif thisData.version == "Not Enabled" then message = "Please enable ReversionRaidTools"
                        elseif thisData.version == "No Response" then return
                        else message = "Please update ReversionRaidTools" end
                    elseif vc.type == "Addon" then
                        if thisData.version == "Addon not enabled" then message = "Please enable the Addon: '"..vc.name.."'"
                        elseif thisData.version == "Addon Missing" then message = "Please install the Addon: '"..vc.name.."'"
                        else message = "Please update the Addon: '"..vc.name.."'" end
                    elseif vc.type == "Note" then
                        if thisData.version == "MRT not enabled" then message = "Please enable MRT"
                        elseif thisData.version == "MRT not installed" then message = "Please install MRT"
                        else return end
                    end
                    if thisData.ignoreCheck then
                        if message == "" then
                            message = "You have someone from the raid on your ignore list. Please remove them fron the list."
                        else
                            message = message.." You also have someone from the raid on your ignore list."
                        end
                    end
                    vc.lastclick[name] = GetTime()
                    SendChatMessage(message, "WHISPER", nil, name)
                end)
            end
        end
    end

    local function createLineFunc(self, index)
        local line = CreateFrame("button", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index-1) * (self.LineHeight+1)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)
        DF:CreateHighlightTexture(line)
        line.index = index

        local name = line:CreateFontString(nil, "OVERLAY")
        name:SetWidth(100)
        name:SetJustifyH("LEFT")
        name:SetFont(RRT_NS.LSM:Fetch("font", RRT.Settings.GlobalFont), 12, "OUTLINE")
        name:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.name = name

        local version = line:CreateFontString(nil, "OVERLAY")
        version:SetWidth(100)
        version:SetJustifyH("LEFT")
        version:SetFont(RRT_NS.LSM:Fetch("font", RRT.Settings.GlobalFont), 12, "OUTLINE")
        version:SetPoint("LEFT", name, "RIGHT", 115, 0)
        line.version = version

        local ignorelist = line:CreateFontString(nil, "OVERLAY")
        ignorelist:SetWidth(100)
        ignorelist:SetJustifyH("LEFT")
        ignorelist:SetFont(RRT_NS.LSM:Fetch("font", RRT.Settings.GlobalFont), 12, "OUTLINE")
        ignorelist:SetPoint("LEFT", version, "RIGHT", 50, 0)
        line.ignorelist = ignorelist

        return line
    end

    -- Scrollbox starts at y=-188 (below controls + headers)
    -- Parent panel ≈ window_height - 22 (bottom chrome) = 618px
    -- Available height: 618 - 188 - 8 = 422px → 20 visible lines (21px/line)
    local SCROLL_Y    = -188
    local SCROLL_H    = window_height - 22 - math.abs(SCROLL_Y) - 8
    local scrollLines = math.floor(SCROLL_H / 21)

    local version_check_scrollbox = DF:CreateScrollBox(parent, "VersionCheckScrollBox", refresh, {},
        window_width - 50,
        SCROLL_H, scrollLines, 20, createLineFunc)
    version_check_scrollbox.ReajustNumFrames = false
    version_check_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, SCROLL_Y)
    local vcTrack = MakeFauxScrollBar(version_check_scrollbox, "VersionCheckScrollBox", scrollLines)
    vcTrack:SetPoint("TOPLEFT",    version_check_scrollbox, "TOPRIGHT",    2, 0)
    vcTrack:SetPoint("BOTTOMLEFT", version_check_scrollbox, "BOTTOMRIGHT", 2, 0)
    for i = 1, scrollLines do
        version_check_scrollbox:CreateLine(createLineFunc)
    end
    version_check_scrollbox:Refresh()

    local function DoScroll(delta)
        local scrollBar = _G["VersionCheckScrollBoxScrollBar"]
        if not scrollBar then return end
        local min, max = scrollBar:GetMinMaxValues()
        if max <= 0 then return end
        scrollBar:SetValue(math.max(min, math.min(max, scrollBar:GetValue() - delta)))
        version_check_scrollbox:Refresh()
    end

    -- Scrollbox itself (when hovering the empty area)
    version_check_scrollbox:EnableMouseWheel(true)
    version_check_scrollbox:SetScript("OnMouseWheel", function(_, delta) DoScroll(delta) end)

    -- Each line is a Button that captures wheel events — forward them
    for i = 1, scrollLines do
        local line = version_check_scrollbox:GetLine(i)
        if line then
            line:EnableMouseWheel(true)
            line:SetScript("OnMouseWheel", function(_, delta) DoScroll(delta) end)
        end
    end

    version_check_scrollbox.name_map = {}
    local addData = function(self, data, url)
        local currentData = self:GetData()
        if self.name_map[data.name] then
            if RRT.Settings["VersionCheckRemoveResponse"] and currentData[1] and currentData[1].version and data.version and data.version == currentData[1].version and data.version ~= "Addon Missing" and data.version ~= "Note Missing" and data.version ~= "Reminder Missing" and (not data.ignoreCheck) then
                table.remove(currentData, self.name_map[data.name])
                for k, v in pairs(self.name_map) do
                    if v > self.name_map[data.name] then
                        self.name_map[k] = v - 1
                    end
                end
            else
                currentData[self.name_map[data.name]] = data
            end
        else
            self.name_map[data.name] = #currentData + 1
            tinsert(currentData, data)
        end
        self:Refresh()
    end

    local wipeData = function(self)
        self:SetData({})
        wipe(self.name_map)
        self:Refresh()
    end

    version_check_scrollbox.AddData = addData
    version_check_scrollbox.WipeData = wipeData

    version_check_button:SetScript("OnClick", function(self)

        local text = component_name_entry:GetText()
        local component_type = component_type_dropdown:GetValue()
        local isNoName = component_type == "Note" or component_type == "Reminder" or component_type == "ReversionRaidTools"

        if text and text ~= "" and not isNoName and not tContains(RRT.RRTUI.AutoComplete[component_type], text) then
            tinsert(RRT.RRTUI.AutoComplete[component_type], text)
        end

        if not isNoName and (not text or text == "") then return end

        -- For RRT Addon checks, always use the addon name directly
        local checkName = (component_type == "ReversionRaidTools") and "ReversionRaidTools" or text

        local now = GetTime()
        if RRT_NS.LastVersionCheck and RRT_NS.LastVersionCheck > now-2 then return end
        RRT_NS.LastVersionCheck = now
        version_check_scrollbox:WipeData()
        local userData, url = RRT_NS:RequestVersionNumber(component_type, checkName)
        if userData then
            RRT_NS.VersionCheckData = { version = userData.version, type = component_type, name = checkName, url = url, lastclick = {} }
            version_check_scrollbox:AddData(userData, url)
        end
    end)

    -- version check presets
    local preset_label = DF:CreateLabel(parent, "Preset:", 9.5, "white")

    local sample_presets = {
        { "Addon: Plater",                            { "Addon", "Plater" } }
    }

    local function build_version_check_presets_options()
        RRT.Settings["VersionCheckPresets"] = RRT.Settings["VersionCheckPresets"] or {}
        local t = {}
        for i = 1, #RRT.Settings["VersionCheckPresets"] do
            local v = RRT.Settings["VersionCheckPresets"][i]
            tinsert(t, {
                label = v[1],
                value = v[2],
                onclick = function(_, _, value)
                    component_type_dropdown:Select(value[1])
                    component_name_entry:SetText(value[2])
                end
            })
        end
        return t
    end
    local version_check_preset_dropdown = DF:CreateDropDown(parent,
        function() return build_version_check_presets_options() end)
    version_check_preset_dropdown:SetTemplate(options_dropdown_template)

    local version_presets_edit_frame = DF:CreateSimplePanel(parent, 400, window_height / 2, "Version Preset Management",
        "VersionPresetsEditFrame", {
            DontRightClickClose = true,
            NoScripts = true
        })
    version_presets_edit_frame:ClearAllPoints()
    version_presets_edit_frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 2)
    version_presets_edit_frame:Hide()

    local version_presets_edit_button = DF:CreateButton(parent, function()
        if version_presets_edit_frame:IsShown() then
            version_presets_edit_frame:Hide()
        else
            version_presets_edit_frame:Show()
        end
    end, 120, 20, "Edit Version Presets")
    version_presets_edit_button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -100)
    version_presets_edit_button:SetTemplate(options_button_template)
    version_check_preset_dropdown:SetPoint("RIGHT", version_presets_edit_button, "LEFT", -10, 0)
    preset_label:SetPoint("RIGHT", version_check_preset_dropdown, "LEFT", -5, 0)

    local function refreshPresets(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local presetData = data[index]
            if presetData then
                local line = self:GetLine(i)

                local label = presetData[1]
                local value = presetData[2]
                local component_type = value[1]
                local component_name = value[2]

                line.index = index

                line.value = value
                line.component_type = component_type
                line.component_name = component_name

                line.type:SetText(component_type)
                line.name:SetText(component_name)
            end
        end
    end

    local function createPresetLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.type = DF:CreateLabel(line, "", 9.5, "white")
        line.type:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.type:SetTemplate(options_text_template)

        line.name = DF:CreateLabel(line, "", 9.5, "white")
        line.name:SetTemplate(options_text_template)
        line.name:SetPoint("LEFT", line, "LEFT", 50, 0)

        line.deleteButton = DF:CreateButton(line, function()
            tremove(RRT.Settings["VersionCheckPresets"], line.index)
            self:SetData(RRT.Settings["VersionCheckPresets"])
            self:Refresh()
            version_check_preset_dropdown:Refresh()
        end, 12, 12)
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])

        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        return line
    end

    local presetScrollLines = 9
    local version_presets_edit_scrollbox = DF:CreateScrollBox(version_presets_edit_frame,
        "$parentVersionPresetsEditScrollBox", refreshPresets, RRT.Settings["VersionCheckPresets"], 360,
        window_height / 2 - 75, presetScrollLines, 20, createPresetLineFunc)
    version_presets_edit_scrollbox:SetPoint("TOPLEFT", version_presets_edit_frame, "TOPLEFT", 10, -30)
    DF:ReskinSlider(version_presets_edit_scrollbox)

    for i = 1, presetScrollLines do
        version_presets_edit_scrollbox:CreateLine(createPresetLineFunc)
    end

    version_presets_edit_scrollbox:Refresh()

    local new_preset_type_label = DF:CreateLabel(version_presets_edit_frame, "Type:", 11)
    new_preset_type_label:SetPoint("TOPLEFT", version_presets_edit_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_preset_type_dropdown = DF:CreateDropDown(version_presets_edit_frame,
        function() return build_checkable_components_options() end, checkable_components[1], 65)
    new_preset_type_dropdown:SetPoint("LEFT", new_preset_type_label, "RIGHT", 5, 0)
    new_preset_type_dropdown:SetTemplate(options_dropdown_template)

    local new_preset_name_label = DF:CreateLabel(version_presets_edit_frame, "Name:", 11)
    new_preset_name_label:SetPoint("LEFT", new_preset_type_dropdown, "RIGHT", 10, 0)

    local new_preset_name_entry = DF:CreateTextEntry(version_presets_edit_frame, function() end, 165, 20)
    new_preset_name_entry:SetPoint("LEFT", new_preset_name_label, "RIGHT", 5, 0)
    new_preset_name_entry:SetTemplate(options_dropdown_template)

    local add_button = DF:CreateButton(version_presets_edit_frame, function()
        local name = new_preset_name_entry:GetText()
        local type = new_preset_type_dropdown:GetValue()
        tinsert(RRT.Settings["VersionCheckPresets"], { type .. ": " .. name, { type, name } })
        version_presets_edit_scrollbox:SetData(RRT.Settings["VersionCheckPresets"])
        version_presets_edit_scrollbox:Refresh()
        version_check_preset_dropdown:Refresh()
        new_preset_name_entry:SetText("")
        new_preset_type_dropdown:Select(checkable_components[1])
    end, 60, 20, "New")
    add_button:SetPoint("LEFT", new_preset_name_entry, "RIGHT", 10, 0)
    add_button:SetTemplate(options_button_template)
    return version_check_scrollbox
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.VersionCheck = {
    BuildVersionCheckUI = BuildVersionCheckUI,
}
