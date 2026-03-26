local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core  = RRT_NS.UI.Core
local RRTUI = Core.RRTUI
local options_dropdown_template = Core.options_dropdown_template
local options_button_template   = Core.options_button_template

-- ─────────────────────────────────────────────────────────────────────────────
-- BuildNicknameEditUI — floating panel to manage the nicknames database
-- ─────────────────────────────────────────────────────────────────────────────

local function BuildNicknameEditUI()
    local edit_frame = DF:CreateSimplePanel(UIParent, 485, 420, "Nicknames Management", "RRTNicknamesEditFrame", {
        DontRightClickClose = true
    })
    edit_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    -- ── Prepare data (sorted by nickname) ───────────────────────────────────
    local function PrepareData()
        local data = {}
        for player, nickname in pairs(RRT.NickNames) do
            tinsert(data, { player = player, nickname = nickname })
        end
        table.sort(data, function(a, b) return a.nickname < b.nickname end)
        return data
    end

    local function MasterRefresh(self)
        self:SetData(PrepareData())
        self:Refresh()
    end

    -- ── ScrollBox refresh ───────────────────────────────────────────────────
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index    = i + offset
            local nickData = data[index]
            if nickData then
                local line = self:GetLine(i)
                local player, realm = strsplit("-", nickData.player)
                line.fullName              = nickData.player
                line.player                = player
                line.realm                 = realm
                line.playerText.text       = nickData.player
                line.nicknameEntry.text    = nickData.nickname
            end
        end
    end

    local function createLineFunc(self, index)
        local parent = self
        local line = CreateFrame("Frame", "$parentLine"..index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * self.LineHeight) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.playerText = DF:CreateLabel(line, "")
        line.playerText:SetPoint("LEFT", line, "LEFT", 5, 0)

        line.nicknameEntry = DF:CreateTextEntry(line, function(self2, _, value)
            RRT_NS:AddNickName(line.player, line.realm, string.sub(value, 1, 12))
            line.nicknameEntry.text = string.sub(value, 1, 12)
            parent:MasterRefresh()
        end, 120, 20)
        line.nicknameEntry:SetTemplate(options_dropdown_template)
        line.nicknameEntry:SetPoint("LEFT", line, "LEFT", 185, 0)

        line.deleteButton = DF:CreateButton(line, function()
            RRT_NS:AddNickName(line.player, line.realm, "")
            self:MasterRefresh()
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

    local scrollLines = 15
    local scrollbox = DF:CreateScrollBox(edit_frame, "$parentScrollBox", refresh, {}, 445, 300, scrollLines, 20, createLineFunc)
    edit_frame.scrollbox = scrollbox
    scrollbox:SetPoint("TOPLEFT", edit_frame, "TOPLEFT", 10, -50)
    scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(scrollbox)
    for i = 1, scrollLines do scrollbox:CreateLine(createLineFunc) end

    -- ── Column headers ───────────────────────────────────────────────────────
    local header_player = DF:CreateLabel(edit_frame, "Player Name", 11)
    header_player:SetPoint("TOPLEFT", edit_frame, "TOPLEFT", 20, -30)

    local header_nick = DF:CreateLabel(edit_frame, "Nickname", 11)
    header_nick:SetPoint("TOPLEFT", edit_frame, "TOPLEFT", 200, -30)

    -- Refresh on show
    scrollbox:SetScript("OnShow", function(self) self:MasterRefresh() end)

    -- ── Add new entry row ────────────────────────────────────────────────────
    local label_player = DF:CreateLabel(edit_frame, "New Player:", 11)
    label_player:SetPoint("TOPLEFT", scrollbox, "BOTTOMLEFT", 0, -20)

    local entry_player = DF:CreateTextEntry(edit_frame, function() end, 120, 20)
    entry_player:SetPoint("LEFT", label_player, "RIGHT", 10, 0)
    entry_player:SetTemplate(options_dropdown_template)

    local label_nick = DF:CreateLabel(edit_frame, "Nickname:", 11)
    label_nick:SetPoint("LEFT", entry_player, "RIGHT", 10, 0)

    local entry_nick = DF:CreateTextEntry(edit_frame, function() end, 120, 20)
    entry_nick:SetPoint("LEFT", label_nick, "RIGHT", 10, 0)
    entry_nick:SetTemplate(options_dropdown_template)

    local btn_add = DF:CreateButton(edit_frame, function()
        local name     = entry_player:GetText()
        local nickname = entry_nick:GetText()
        if name ~= "" and nickname ~= "" then
            local player, realm = strsplit("-", name)
            if not realm then realm = GetNormalizedRealmName() end
            RRT_NS:AddNickName(player, realm, nickname)
            entry_player:SetText("")
            entry_nick:SetText("")
            scrollbox:MasterRefresh()
        end
    end, 60, 20, "Add")
    btn_add:SetPoint("LEFT", entry_nick, "RIGHT", 10, 0)
    btn_add:SetTemplate(options_button_template)

    -- ── Bottom buttons ───────────────────────────────────────────────────────
    local btn_sync = DF:CreateButton(edit_frame, function()
        RRT_NS:SyncNickNames()
    end, 225, 20, "Sync Nicknames")
    btn_sync:SetPoint("BOTTOMLEFT", edit_frame, "BOTTOMLEFT", 10, 10)
    btn_sync:SetTemplate(options_button_template)

    -- ── Import popup ─────────────────────────────────────────────────────────
    local function CreateImportPopup()
        local popup = DF:CreateSimplePanel(edit_frame, 300, 150, "Import Nicknames", "RRTImportNicknamesPopup", {
            DontRightClickClose = true
        })
        popup:SetPoint("CENTER", edit_frame, "CENTER", 0, 0)
        popup:SetFrameLevel(100)

        popup.import_text_box = DF:NewSpecialLuaEditorEntry(popup, 280, 80, nil, "RRTImportNicknamesTextBox", true, false, true)
        popup.import_text_box:SetPoint("TOPLEFT",    popup, "TOPLEFT",    10, -30)
        popup.import_text_box:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
        DF:ApplyStandardBackdrop(popup.import_text_box)
        DF:ReskinSlider(popup.import_text_box.scroll)
        popup.import_text_box:SetFocus()

        popup.btn_confirm = DF:CreateButton(popup, function()
            local str = popup.import_text_box:GetText()
            RRT_NS:ImportNickNames(str)
            popup.import_text_box:SetText("")
            popup:Hide()
            scrollbox:MasterRefresh()
        end, 280, 20, "Import")
        popup.btn_confirm:SetPoint("BOTTOM", popup, "BOTTOM", 0, 10)
        popup.btn_confirm:SetTemplate(options_button_template)

        popup:Hide()
        return popup
    end

    local import_popup = CreateImportPopup()

    local btn_import = DF:CreateButton(edit_frame, function()
        if not import_popup:IsShown() then import_popup:Show() end
    end, 225, 20, "Import Nicknames")
    btn_import:SetPoint("BOTTOMRIGHT", edit_frame, "BOTTOMRIGHT", -10, 10)
    btn_import:SetTemplate(options_button_template)

    edit_frame:Hide()
    return edit_frame
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Nicknames = { BuildNicknameEditUI = BuildNicknameEditUI }
