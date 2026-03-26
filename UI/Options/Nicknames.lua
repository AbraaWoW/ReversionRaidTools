local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core  = RRT_NS.UI.Core
local RRTUI = Core.RRTUI

-- ─────────────────────────────────────────────────────────────────────────────
-- Nicknames options panel (DF:BuildMenu table)
-- ─────────────────────────────────────────────────────────────────────────────

local function BuildNicknamesOptions()

    -- ── Dropdown value builders ──────────────────────────────────────────────
    local function MakeSelect(labels, settingKey)
        local t = {}
        for i, label in ipairs(labels) do
            tinsert(t, { label = label, value = i, onclick = function(_, _, value)
                RRT.Settings[settingKey] = value
            end })
        end
        return t
    end

    local share_labels    = { "Raid", "Guild", "Both", "None" }
    local accept_labels   = { "Raid", "Guild", "Both", "None" }
    local syncsend_labels = { "Raid", "Guild", "None" }
    local syncaccept_labels = { "Raid", "Guild", "Both", "None" }

    -- ── Wipe confirmation popup ──────────────────────────────────────────────
    local function WipeNickNames()
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Wipe Nicknames", "RRTWipeNicknamesPopup")
        popup:SetFrameStrata("DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = DF:CreateLabel(popup, "Are you sure you want to wipe all nicknames?", 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local btn_confirm = DF:CreateButton(popup, function()
            RRT_NS:WipeNickNames()
            if RRTUI.nickname_frame then
                RRTUI.nickname_frame.scrollbox:MasterRefresh()
            end
            popup:Hide()
        end, 100, 20, "Confirm")
        btn_confirm:SetPoint("BOTTOMLEFT",  popup, "BOTTOM",  5, 10)
        btn_confirm:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local btn_cancel = DF:CreateButton(popup, function() popup:Hide() end, 100, 20, "Cancel")
        btn_cancel:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        btn_cancel:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        popup:Show()
    end

    -- ── Options table ────────────────────────────────────────────────────────
    return {
        { type = "label", get = function() return "Nicknames Options" end,
          text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        { type = "textentry",
          name = "Nickname",
          desc = "Set your nickname visible to others and used in assignments.",
          get  = function() return RRT.Settings["MyNickName"] or "" end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["NICKNAME"] = true
              RRT.Settings["MyNickName"] = RRT_NS:Utf8Sub(value, 1, 12)
          end,
          hooks = {
              OnEditFocusLost   = function(self) self:SetText(RRT.Settings["MyNickName"] or "") end,
              OnEnterPressed    = function(self) end,
          },
          nocombat = true },

        { type = "toggle", boxfirst = true,
          name = "Enable Nicknames",
          desc = "Globally enable nicknames.",
          get  = function() return RRT.Settings["GlobalNickNames"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["GLOBAL_NICKNAMES"] = true
              RRT.Settings["GlobalNickNames"] = value
          end,
          nocombat = true },

        { type = "toggle", boxfirst = true,
          name = "Translit Names",
          desc = "Transliterate Russian/Cyrillic names to Latin.",
          get  = function() return RRT.Settings["Translit"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["TRANSLIT"] = true
              RRT.Settings["Translit"] = value
          end,
          nocombat = true },

        { type = "label", get = function() return "Automated Nickname Share Options" end,
          text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        { type = "select",
          get    = function() return RRT.Settings["ShareNickNames"] end,
          values = function() return MakeSelect(share_labels,  "ShareNickNames")  end,
          name   = "Nickname Sharing",
          desc   = "Choose who you share your nickname with.",
          nocombat = true },

        { type = "select",
          get    = function() return RRT.Settings["AcceptNickNames"] end,
          values = function() return MakeSelect(accept_labels, "AcceptNickNames") end,
          name   = "Nickname Accept",
          desc   = "Choose who you accept nicknames from.",
          nocombat = true },

        { type = "label", get = function() return "Manual Nickname Sync Options" end,
          text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        { type = "select",
          get    = function() return RRT.Settings["NickNamesSyncSend"] end,
          values = function() return MakeSelect(syncsend_labels,   "NickNamesSyncSend")   end,
          name   = "Nickname Sync Send",
          desc   = "Who to sync nicknames to when pressing the sync button.",
          nocombat = true },

        { type = "select",
          get    = function() return RRT.Settings["NickNamesSyncAccept"] end,
          values = function() return MakeSelect(syncaccept_labels, "NickNamesSyncAccept") end,
          name   = "Nickname Sync Accept",
          desc   = "Who to accept nickname sync requests from.",
          nocombat = true },

        { type = "breakline" },
        { type = "label", get = function() return "Unit Frame Compatibility" end,
          text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        { type = "toggle", boxfirst = true,
          name = "Enable Blizzard / Reskin Addons Nicknames",
          desc = "Apply nicknames to Blizzard raid frames and any addon that reskins them (e.g. RaidFrameSettings).",
          get  = function() return RRT.Settings["Blizzard"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["BLIZZARD_NICKNAMES"] = true
              RRT.Settings["Blizzard"] = value
          end, nocombat = true },

        { type = "toggle", boxfirst = true,
          name = "Enable Cell Nicknames",
          desc = "Apply nicknames to Cell unit frames (requires enabling nicknames inside Cell).",
          get  = function() return RRT.Settings["Cell"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["CELL_NICKNAMES"] = true
              RRT.Settings["Cell"] = value
          end, nocombat = true },

        { type = "toggle", boxfirst = true,
          name = "Enable Grid2 Nicknames",
          desc = "Apply nicknames to Grid2 (select the 'RRTNickName' indicator inside Grid2).",
          get  = function() return RRT.Settings["Grid2"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] = true
              RRT.Settings["Grid2"] = value
          end, nocombat = true },

        { type = "toggle", boxfirst = true,
          name = "Enable DandersFrames Nicknames",
          desc = "Apply nicknames to DandersFrames unit frames.",
          get  = function() return RRT.Settings["DandersFrames"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["DANDERS_FRAMES_NICKNAMES"] = true
              RRT.Settings["DandersFrames"] = value
          end, nocombat = true },

        { type = "toggle", boxfirst = true,
          name = "Enable ElvUI Nicknames",
          desc = "Apply nicknames to ElvUI frames. Use [RRTNickName] or [RRTNickName:1-12] tags.",
          get  = function() return RRT.Settings["ElvUI"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["ELVUI_NICKNAMES"] = true
              RRT.Settings["ElvUI"] = value
          end, nocombat = true },

        { type = "toggle", boxfirst = true,
          name = "Enable VuhDo Nicknames",
          desc = "Apply nicknames to VuhDo unit frames.",
          get  = function() return RRT.Settings["VuhDo"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["VUHDO_NICKNAMES"] = true
              RRT.Settings["VuhDo"] = value
          end, nocombat = true },

        { type = "toggle", boxfirst = true,
          name = "Enable Unhalted UF Nicknames",
          desc = "Apply nicknames to Unhalted Unit Frames (use 'RRTNickName' tag).",
          get  = function() return RRT.Settings["Unhalted"] end,
          set  = function(self, _, value)
              RRTUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] = true
              RRT.Settings["Unhalted"] = value
          end, nocombat = true },

        { type = "breakline" },

        { type = "button",
          name = "Wipe Nicknames",
          desc = "Remove all nicknames from the local database.",
          func = function() WipeNickNames() end,
          nocombat = true },

        { type = "button",
          name = "Edit Nicknames",
          desc = "Open the nicknames database editor.",
          func = function()
              if RRTUI.nickname_frame and not RRTUI.nickname_frame:IsShown() then
                  RRTUI.nickname_frame:Show()
              end
          end,
          nocombat = true },
    }
end

local function BuildNicknamesCallback()
    return function()
        if RRTUI.OptionsChanged.nicknames["NICKNAME"] then
            RRT_NS:NickNameUpdated(RRT.Settings["MyNickName"])
        end
        if RRTUI.OptionsChanged.nicknames["GLOBAL_NICKNAMES"] then
            RRT_NS:GlobalNickNameUpdate()
        end
        if RRTUI.OptionsChanged.nicknames["TRANSLIT"] then
            RRT_NS:UpdateNickNameDisplay(true)
        end
        if RRTUI.OptionsChanged.nicknames["BLIZZARD_NICKNAMES"] then
            RRT_NS:BlizzardNickNameUpdated()
        end
        if RRTUI.OptionsChanged.nicknames["CELL_NICKNAMES"] then
            RRT_NS:CellNickNameUpdated(true)
        end
        if RRTUI.OptionsChanged.nicknames["ELVUI_NICKNAMES"] then
            RRT_NS:ElvUINickNameUpdated()
        end
        if RRTUI.OptionsChanged.nicknames["VUHDO_NICKNAMES"] then
            RRT_NS:VuhDoNickNameUpdated()
        end
        if RRTUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] then
            RRT_NS:Grid2NickNameUpdated(true)
        end
        if RRTUI.OptionsChanged.nicknames["DANDERS_FRAMES_NICKNAMES"] then
            RRT_NS:DandersFramesNickNameUpdated(true)
        end
        if RRTUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] then
            RRT_NS:UnhaltedNickNameUpdated()
        end
        wipe(RRTUI.OptionsChanged["nicknames"])
    end
end

-- Export
RRT_NS.UI          = RRT_NS.UI or {}
RRT_NS.UI.Options  = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Nicknames = {
    BuildOptions  = BuildNicknamesOptions,
    BuildCallback = BuildNicknamesCallback,
}
