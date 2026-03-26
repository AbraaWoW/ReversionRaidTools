local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core = RRT_NS.UI.Core
local RRTUI = Core.RRTUI
local options_dropdown_template = Core.options_dropdown_template
local options_button_template = Core.options_button_template

local ImportReminderStringFrame
local function ImportReminderString(name, IsUpdate)
    local popup = ImportReminderStringFrame
    if not popup then
        popup = DF:CreateSimplePanel(RRTUI, 800, 800, "Import Reminder String", "RRTReminderImport", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameLevel(100)
        ImportReminderStringFrame = popup
    end

    if not popup.test_string_text_box then
        popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "ReminderTextEdit", true, false, true)
        popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
        popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.test_string_text_box)
        DF:ReskinSlider(popup.test_string_text_box.scroll)
        popup.test_string_text_box:SetScript("OnMouseDown", function(self)
            self:SetFocus()
        end)
    end
    popup.test_string_text_box.editbox:SetFont(RRT_NS.LSM:Fetch("font", RRT.Settings.GlobalFont), 13, "OUTLINE")
    popup.test_string_text_box:SetText(name and RRT.Reminders[name] or "")
    popup.test_string_text_box:SetFocus()
    local importtext = IsUpdate and "Update" or "Import"
    if not popup.import_confirm_button then
        popup.import_confirm_button = DF:CreateButton(popup, function()
            local import_string = popup.test_string_text_box:GetText()
            if popup._isUpdate then
                RRT_NS:ImportReminder(popup._name, import_string, false, false, true)
            else
                RRT_NS:ImportFullReminderString(import_string, false, false, popup._name)
            end
            if popup._isUpdate and RRT.ActiveReminder then
                RRT_NS:SetReminder(RRT.ActiveReminder) -- refresh active reminder
            end
            popup.test_string_text_box:SetText("")
            RRTUI.reminders_frame:Hide()
            RRTUI.reminders_frame:Show()
            popup:Hide()
        end, 280, 20, importtext)
        popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
        popup.import_confirm_button:SetTemplate(options_button_template)
    end
    popup.import_confirm_button:SetText(importtext)
    popup._name = name
    popup._isUpdate = IsUpdate
    popup:Show()
    return popup
end

local function ImportPersonalReminderString(name, IsUpdate)
    local popup = ImportPersonalReminderStringFrame
    if not popup then
        popup = DF:CreateSimplePanel(RRTUI, 800, 800, "Import Personal Reminder String", "RRTPersonalReminderImport", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameLevel(100)
        ImportPersonalReminderStringFrame = popup
    end

    if not popup.test_string_text_box then
        popup.test_string_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "PersonalReminderTextEdit", true, false, true)
        popup.test_string_text_box:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
        popup.test_string_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.test_string_text_box)
        DF:ReskinSlider(popup.test_string_text_box.scroll)
        popup.test_string_text_box:SetScript("OnMouseDown", function(self)
            self:SetFocus()
        end)
    end
    popup.test_string_text_box.editbox:SetFont(RRT_NS.LSM:Fetch("font", RRT.Settings.GlobalFont), 13, "OUTLINE")
    popup.test_string_text_box:SetText(name and RRT.PersonalReminders[name] or "")
    popup.test_string_text_box:SetFocus()
    local importtext = IsUpdate and "Update" or "Import"
    if not popup.import_confirm_button then
        popup.import_confirm_button = DF:CreateButton(popup, function()
            local import_string = popup.test_string_text_box:GetText()
            if popup._isUpdate then
                RRT_NS:ImportReminder(popup._name, import_string, false, true, true)
            else
                RRT_NS:ImportFullReminderString(import_string, true, false, popup._name)
            end
            if popup._isUpdate and RRT.ActivePersonalReminder then
                RRT_NS:SetReminder(RRT.ActivePersonalReminder, true) -- refresh active personal reminder
            end
            popup.test_string_text_box:SetText("")
            RRTUI.personal_reminders_frame:Hide()
            RRTUI.personal_reminders_frame:Show()
            popup:Hide()
        end, 280, 20, importtext)
        popup.import_confirm_button:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
        popup.import_confirm_button:SetTemplate(options_button_template)
    end
    popup.import_confirm_button:SetText(importtext)
    popup._name = name
    popup._isUpdate = IsUpdate
    popup:Show()
    return popup
end

local function BuildRemindersEditUI()
    local reminders_edit_frame = DF:CreateSimplePanel(UIParent, 460, 410, "Reminders Management", "RemindersEditFrame", {
        DontRightClickClose = true
    })
    reminders_edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local function MasterRefresh(self)
        local data = RRT_NS:GetAllReminderNames()
        self:SetData(data)
        self:Refresh()
    end
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local reminderData = data[index]
            if reminderData then
                local line = self:GetLine(i)
                line.name = reminderData.name
                line.nameTextEntry.text = reminderData.hasencID and reminderData.name or (reminderData.name.." (No Encounter)")
                if RRT.InviteList[reminderData.name] then
                    line.InviteButton:Show()
                    line.ArrangeButton:Show()
                else
                    line.InviteButton:Hide()
                    line.ArrangeButton:Hide()
                end
                if line.name == RRT.ActiveReminder then
                    local colors = reminderData.hasencID and {0, 1, 0, 1} or {1, 0, 0, 1}
                    line.nameTextEntry:SetBackdropBorderColor(unpack(colors))
                    line.nameTextEntry.BorderColorR = colors[1]
                    line.nameTextEntry.BorderColorG = colors[2]
                else
                    line.nameTextEntry:SetBackdropBorderColor(0, 0, 0, 1)
                    line.nameTextEntry.BorderColorR = 0
                    line.nameTextEntry.BorderColorG = 0
                end
                line.nameTextEntry.BorderColorB = 0
                line.nameTextEntry.BorderColorA = 1
            end
        end
    end

    local Active_Text = DF:CreateLabel(reminders_edit_frame, "Active Reminder", 11)
    Active_Text:SetPoint("BOTTOMLEFT", reminders_edit_frame, "BOTTOMLEFT", 5, 50)
    Active_Text:SetWidth(380)
    if RRT.ActiveReminder and RRT.ActiveReminder ~= "" then
        Active_Text.text = "Active Reminder: |cFFFFFFFF" .. RRT.ActiveReminder
    else
        Active_Text.text = "Active Reminder: |cFFFFFFFFNone"
    end

    local ImportButton = DF:CreateButton(reminders_edit_frame, function()
        ImportReminderString(nil, false)
        end, 100, 24, "Import Reminder"
    )
    ImportButton:SetPoint("BOTTOMLEFT", reminders_edit_frame, "BOTTOMLEFT", 5, 10)
    ImportButton:SetTemplate(options_button_template)

    local ClearButton = DF:CreateButton(reminders_edit_frame, function()
        RRT_NS:SetReminder(nil)
        RRT_NS:Broadcast("RRT_REM_SHARE", "RAID", " ", nil, true)
        reminders_edit_frame.scrollbox:MasterRefresh()
        Active_Text.text = "Active Reminder: |cFFFFFFFFNone"
        end, 100, 24, "Clear Reminder"
    )
    ClearButton:SetPoint("LEFT", ImportButton, "RIGHT", 5, 0)
    ClearButton:SetTemplate(options_button_template)


    local function DeleteBossReminder(self, line, all)
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Reminder Deletion", "RRTDeleteReminderPopup")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = all and DF:CreateLabel(popup, "Are you sure you want to \ndelete ALL reminders?", 12, "orange") or DF:CreateLabel(popup,
            "Are you sure you want to \ndelete this reminder?", 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            if line and RRT.ActiveReminder and RRT.ActiveReminder == line.name then
                Active_Text.text = "Active Reminder: |cFFFFFFFFNone"
            end
            if all then
                Active_Text.text = "Active Reminder: |cFFFFFFFFNone"
                for _, reminder in ipairs(RRT_NS:GetAllReminderNames()) do
                    RRT_NS:RemoveReminder(reminder.name)
                end
            else
                RRT_NS:RemoveReminder(line.name)
            end
            self:SetData(RRT_NS:GetAllReminderNames())
            self:MasterRefresh()
            popup:Hide()
        end, 100, 30, "Confirm")
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, "Cancel")
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end

    local alldeletecreated = false
    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        if not alldeletecreated then
            alldeletecreated = true
            local DeleteAllButton = DF:CreateButton(reminders_edit_frame, function()
                DeleteBossReminder(self, line, true)
                parent:MasterRefresh()
                end, 100, 24, "Delete ALL Reminders"
            )
            DeleteAllButton:SetPoint("LEFT", ClearButton, "RIGHT", 5, 0)
            DeleteAllButton:SetTemplate(options_button_template)
        end

        line.nameTextEntry = DF:CreateTextEntry(line, function() end, line:GetWidth()-210, line:GetHeight())
        line.nameTextEntry:SetTemplate(options_dropdown_template)
        line.nameTextEntry:SetPoint("LEFT", line, "LEFT", 0, 0)
        local saveNewName = function(self)
            local oldname = line.name
            if not oldname then return end
            local newname = self:GetText()
            if oldname == newname then return end
            if RRT.Reminders[newname] then return end
            RRT.Reminders[newname] = RRT.Reminders[oldname]
            RRT.InviteList[newname] = RRT.InviteList[oldname]
            if RRT.ActiveReminder == oldname then
                Active_Text.text = "Active Reminder: |cFFFFFFFF" .. newname
                RRT.ActiveReminder = newname
            end
            RRT.Reminders[oldname] = nil
            RRT.InviteList[oldname] = nil
            line.name = newname
            parent:MasterRefresh()
        end
        line.nameTextEntry:SetScript("OnEnterPressed", saveNewName)
        line.nameTextEntry:SetScript("OnEditFocusLost", saveNewName)

        line.nameTextEntry:SetScript("OnEnter", function(self)
            if self.BorderColorR then
                self:SetBackdropBorderColor(self.BorderColorR, self.BorderColorG, self.BorderColorB, self.BorderColorA)
            end
        end)
        line.nameTextEntry:SetScript("OnLeave", function(self)
            if self.BorderColorR then
                self:SetBackdropBorderColor(self.BorderColorR, self.BorderColorG, self.BorderColorB, self.BorderColorA)
            end
        end)

        line.deleteButton = DF:CreateButton(line, function()
            DeleteBossReminder(self, line, false)
        end, 12, 12)
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        line.LoadButton = DF:CreateButton(line, function()
            local name = line.name
            if name ~= "" then
                RRT_NS:SetReminder(name)
                Active_Text.text = "Active Reminder: |cFFFFFFFF" .. name
                RRT_NS:UpdateReminderFrame(true)
                RRT_NS:Broadcast("RRT_REM_SHARE", "RAID", RRT_NS.Reminder, nil, true)
                parent:MasterRefresh()
            end
        end, 40, 20, "Load")
        line.LoadButton:SetPoint("RIGHT", line.deleteButton, "LEFT", 0, 0)
        line.LoadButton:SetTemplate(options_button_template)

        line.ShowButton = DF:CreateButton(line, function()
            local name = line.name
            ImportReminderString(name, true)
        end, 40, 20, "Show")
        line.ShowButton:SetPoint("RIGHT", line.LoadButton, "LEFT", 0, 0)
        line.ShowButton:SetTemplate(options_button_template)

        line.InviteButton = DF:CreateButton(line, function(self)
            RRT_NS:InviteFromReminder(line.name, true)
        end, 40, 20, "Invite")
        line.InviteButton:SetPoint("RIGHT", line.ShowButton, "LEFT", 0, 0)
        line.InviteButton:SetTemplate(options_button_template)

        line.ArrangeButton = DF:CreateButton(line, function(self)
            RRT_NS:ArrangeFromReminder(line.name)
        end, 40, 20, "Arrange")
        line.ArrangeButton:SetPoint("RIGHT", line.InviteButton, "LEFT", 0, 0)
        line.ArrangeButton:SetTemplate(options_button_template)
        return line
    end

    local scrollLines = 15
    local reminders_edit_scrollbox = DF:CreateScrollBox(reminders_edit_frame, "$parentRemindersEditScrollBox", refresh,
        {},
        420, 300, scrollLines, 20, createLineFunc)
    reminders_edit_frame.scrollbox = reminders_edit_scrollbox
    reminders_edit_scrollbox:SetPoint("TOPLEFT", reminders_edit_frame, "TOPLEFT", 10, -40)
    reminders_edit_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(reminders_edit_scrollbox)
    reminders_edit_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    for i = 1, scrollLines do
        reminders_edit_scrollbox:CreateLine(createLineFunc)
    end

    reminders_edit_frame:Hide()
    return reminders_edit_frame
end

local function BuildPersonalRemindersEditUI()
    local reminders_edit_frame = DF:CreateSimplePanel(UIParent, 460, 410, "Personal Reminders Management", "RemindersEditFrame", {
        DontRightClickClose = true
    })
    reminders_edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local function MasterRefresh(self)
        local data = RRT_NS:GetAllReminderNames(true)
        self:SetData(data)
        self:Refresh()
    end
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local reminderData = data[index]
            if reminderData then
                local line = self:GetLine(i)
                line.name = reminderData.name
                line.nameTextEntry.text = reminderData.hasencID and reminderData.name or (reminderData.name.." (No Encounter)")

                if line.name == RRT.ActivePersonalReminder then
                    local colors = reminderData.hasencID and {0, 1, 0, 1} or {1, 0, 0, 1}
                    line.nameTextEntry:SetBackdropBorderColor(unpack(colors))
                    line.nameTextEntry.BorderColorR = colors[1]
                    line.nameTextEntry.BorderColorG = colors[2]
                else
                    line.nameTextEntry:SetBackdropBorderColor(0, 0, 0, 1)
                    line.nameTextEntry.BorderColorR = 0
                    line.nameTextEntry.BorderColorG = 0
                end
                line.nameTextEntry.BorderColorB = 0
                line.nameTextEntry.BorderColorA = 1
            end
        end
    end

    local Active_Text = DF:CreateLabel(reminders_edit_frame, "Active Personal Reminder", 11)
    Active_Text:SetPoint("BOTTOMLEFT", reminders_edit_frame, "BOTTOMLEFT", 5, 50)
    Active_Text:SetWidth(380)
    if RRT.ActivePersonalReminder and RRT.ActivePersonalReminder ~= "" then
        Active_Text.text = "Active Personal Reminder: |cFFFFFFFF" .. RRT.ActivePersonalReminder
    else
        Active_Text.text = "Active Personal Reminder: |cFFFFFFFFNone"
    end

    local ImportButton = DF:CreateButton(reminders_edit_frame, function()
        ImportPersonalReminderString(nil, false)
        end, 100, 24, "Import Personal Reminder"
    )
    ImportButton:SetPoint("BOTTOMLEFT", reminders_edit_frame, "BOTTOMLEFT", 5, 10)
    ImportButton:SetTemplate(options_button_template)

    local ClearButton = DF:CreateButton(reminders_edit_frame, function()
        RRT_NS:SetReminder(nil, true)
        reminders_edit_frame.scrollbox:MasterRefresh()
        Active_Text.text = "Active Personal Reminder: |cFFFFFFFFNone"
        end, 100, 24, "Clear Reminder"
    )
    ClearButton:SetPoint("LEFT", ImportButton, "RIGHT", 5, 0)
    ClearButton:SetTemplate(options_button_template)

    local function DeleteBossReminder(self, line, all)
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Personal Reminder Deletion", "RRTDeletePersonalReminderPopup")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = all and DF:CreateLabel(popup,
            "Are you sure you want to \ndelete ALL reminders?", 12, "orange") or DF:CreateLabel(popup,
            "Are you sure you want to \ndelete this Personal Reminder?", 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            if RRT.ActivePersonalReminder and RRT.ActivePersonalReminder == line.name then
                Active_Text.text = "Active Personal Reminder: |cFFFFFFFFNone"
            end
            if all then
                Active_Text.text = "Active Personal Reminder: |cFFFFFFFFNone"
                for _, reminder in ipairs(RRT_NS:GetAllReminderNames(true)) do
                    RRT_NS:RemoveReminder(reminder.name, true)
                end
            else
                RRT_NS:RemoveReminder(line.name, true)
            end
            self:SetData(RRT_NS:GetAllReminderNames(true))
            self:MasterRefresh()
            popup:Hide()
        end, 100, 30, "Confirm")
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, "Cancel")
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end
    local alldeletecreated
    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.nameTextEntry = DF:CreateTextEntry(line, function() end, line:GetWidth()-129, line:GetHeight())
        line.nameTextEntry:SetTemplate(options_dropdown_template)
        line.nameTextEntry:SetPoint("LEFT", line, "LEFT", 0, 0)
        local saveNewName = function(self)
            local oldname = line.name
            if not oldname then return end
            local newname = self:GetText()
            if oldname == newname then return end
            if RRT.PersonalReminders[newname] then return end
            RRT.PersonalReminders[newname] = RRT.PersonalReminders[oldname]
            if RRT.ActivePersonalReminder == oldname then
                Active_Text.text = "Active Personal Reminder: |cFFFFFFFF" .. newname
                RRT.ActivePersonalReminder = newname
            end
            RRT.PersonalReminders[oldname] = nil
            line.name = newname
            parent:MasterRefresh()
        end
        line.nameTextEntry:SetScript("OnEnterPressed", saveNewName)
        line.nameTextEntry:SetScript("OnEditFocusLost", saveNewName)

        line.nameTextEntry:SetScript("OnEnter", function(self)
            if self.BorderColorR then
                self:SetBackdropBorderColor(self.BorderColorR, self.BorderColorG, self.BorderColorB, self.BorderColorA)
            end
        end)
        line.nameTextEntry:SetScript("OnLeave", function(self)
            if self.BorderColorR then
                self:SetBackdropBorderColor(self.BorderColorR, self.BorderColorG, self.BorderColorB, self.BorderColorA)
            end
        end)
        if not alldeletecreated then
            alldeletecreated = true
            local DeleteAllButton = DF:CreateButton(reminders_edit_frame, function()
                DeleteBossReminder(self, line, true)
                parent:MasterRefresh()
                end, 100, 24, "Delete ALL Reminders"
            )
            DeleteAllButton:SetPoint("LEFT", ClearButton, "RIGHT", 5, 0)
            DeleteAllButton:SetTemplate(options_button_template)
        end

        line.deleteButton = DF:CreateButton(line, function()
            DeleteBossReminder(self, line, false)
        end, 12, 12)
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        line.LoadButton = DF:CreateButton(line, function()
            local name = line.name
            if name ~= "" then
                RRT_NS:SetReminder(name, true)
                Active_Text.text = "Active Personal Reminder: |cFFFFFFFF" .. name
                RRT_NS:UpdateReminderFrame(true)
                parent:MasterRefresh()
            end
        end, 55, 20, "Load")
        line.LoadButton:SetPoint("RIGHT", line.deleteButton, "LEFT", 0, 0)
        line.LoadButton:SetTemplate(options_button_template)

        line.ShowButton = DF:CreateButton(line, function()
            local name = line.name
            ImportPersonalReminderString(name, true)
        end, 55, 20, "Show")
        line.ShowButton:SetPoint("RIGHT", line.LoadButton, "LEFT", 0, 0)
        line.ShowButton:SetTemplate(options_button_template)
        return line
    end

    local scrollLines = 15
    local reminders_edit_scrollbox = DF:CreateScrollBox(reminders_edit_frame, "$parentRemindersEditScrollBox", refresh,
        {},
        420, 300, scrollLines, 20, createLineFunc)
    reminders_edit_frame.scrollbox = reminders_edit_scrollbox
    reminders_edit_scrollbox:SetPoint("TOPLEFT", reminders_edit_frame, "TOPLEFT", 10, -40)
    reminders_edit_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(reminders_edit_scrollbox)
    reminders_edit_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    for i = 1, scrollLines do
        reminders_edit_scrollbox:CreateLine(createLineFunc)
    end

    reminders_edit_frame:Hide()
    return reminders_edit_frame
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Reminders = {
    ImportReminderString = ImportReminderString,
    ImportPersonalReminderString = ImportPersonalReminderString,
    BuildRemindersEditUI = BuildRemindersEditUI,
    BuildPersonalRemindersEditUI = BuildPersonalRemindersEditUI,
}
