local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local RRTUI = Core.RRTUI

local function BuildNicknamesOptions()
    local nickname_share_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_share_options = function()
        local t = {}
        for i = 1, #nickname_share_options do
            tinsert(t, {
                label = nickname_share_options[i],
                value = i,
                onclick = function(_, _, value)
                    RRTDB.Settings["ShareNickNames"] = value
                end
            })
        end
        return t
    end

    local nickname_accept_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_accept_options = function()
        local t = {}
        for i = 1, #nickname_accept_options do
            tinsert(t, {
                label = nickname_accept_options[i],
                value = i,
                onclick = function(_, _, value)
                    RRTDB.Settings["AcceptNickNames"] = value
                end
            })
        end
        return t
    end

    local nickname_syncaccept_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_syncaccept_options = function()
        local t = {}
        for i = 1, #nickname_syncaccept_options do
            tinsert(t, {
                label = nickname_syncaccept_options[i],
                value = i,
                onclick = function(_, _, value)
                    RRTDB.Settings["NickNamesSyncAccept"] = value
                end
            })
        end
        return t
    end

    local nickname_syncsend_options = { "Raid", "Guild", "None"}
    local build_nickname_syncsend_options = function()
        local t = {}
        for i = 1, #nickname_syncsend_options do
            tinsert(t, {
                label = nickname_syncsend_options[i],
                value = i,
                onclick = function(_, _, value)
                    RRTDB.Settings["NickNamesSyncSend"] = value
                end
            })
        end
        return t
    end

    local function WipeNickNames()
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, "Confirm Wipe Nicknames", "RRTWipeNicknamesPopup")
        popup:SetFrameStrata("DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = DF:CreateLabel(popup,
            "Are you sure you want to wipe all nicknames?", 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            RRT:WipeNickNames()
            RRTUI.nickname_frame.scrollbox:MasterRefresh()
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

    return {
        { type = "label", get = function() return "Nicknames Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "textentry",
            name = "Nickname",
            desc = "Set your nickname to be seen by others and used in assignments",
            get = function() return RRTDB.Settings["MyNickName"] or "" end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["NICKNAME"] = true
                RRTDB.Settings["MyNickName"] = RRT:Utf8Sub(value, 1, 12)
            end,
            hooks = {
                OnEditFocusLost = function(self)
                    self:SetText(RRTDB.Settings["MyNickName"])
                end,
                OnEnterPressed = function(self) return end
            },
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Nicknames",
            desc = "Globaly enable nicknames.",
            get = function() return RRTDB.Settings["GlobalNickNames"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["GLOBAL_NICKNAMES"] = true
                RRTDB.Settings["GlobalNickNames"] = value
            end,
            nocombat = true
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Translit Names",
            desc = "Translit Russian Names",
            get = function() return RRTDB.Settings["Translit"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["TRANSLIT"] = true
                RRTDB.Settings["Translit"] = value
            end,
            nocombat = true
        },

        { type = "label", get = function() return "Automated Nickname Share Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "select",
            get = function() return RRTDB.Settings["ShareNickNames"] end,
            values = function() return build_nickname_share_options() end,
            name = "Nickname Sharing",
            desc = "Choose who you share your nickname with.",
            nocombat = true
        },
        {
            type = "select",
            get = function() return RRTDB.Settings["AcceptNickNames"] end,
            values = function() return build_nickname_accept_options() end,
            name = "Nickname Accept",
            desc = "Choose who you are accepting Nicknames from",
            nocombat = true
        },

        { type = "label", get = function() return "Manual Nickname Sync Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        {
            type = "select",
            get = function() return RRTDB.Settings["NickNamesSyncSend"] end,
            values = function() return build_nickname_syncsend_options() end,
            name = "Nickname Sync Send",
            desc = "Choose who you are synching nicknames to when pressing on the sync button",
            nocombat = true
        },

        {
            type = "select",
            get = function() return RRTDB.Settings["NickNamesSyncAccept"] end,
            values = function() return build_nickname_syncaccept_options() end,
            name = "Nickname Sync Accept",
            desc = "Choose who you are accepting Nicknames sync requests to come from",
            nocombat = true
        },

        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Unit Frame compatibility" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return RRTDB.Settings["Blizzard"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["BLIZZARD_NICKNAMES"] = true
                RRTDB.Settings["Blizzard"] = value
            end,
            name = "Enable Blizzard/Reskin Addons Nicknames",
            desc = "Enable Nicknames to be used with Blizzard unit frames. This should automatically work for any Addon that reskins Blizzard Frames instead of creating their own frames. This for example includes RaidFrameSettings.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return RRTDB.Settings["Cell"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["CELL_NICKNAMES"] = true
                RRTDB.Settings["Cell"] = value
            end,
            name = "Enable Cell Nicknames",
            desc = "Enable Nicknames to be used with Cell unit frames. This requires enabling nicknames within Cell.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return RRTDB.Settings["Grid2"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] = true
                RRTDB.Settings["Grid2"] = value
            end,
            name = "Enable Grid2 Nicknames",
            desc = "Enable Nicknames to be used with Grid2 unit frames. This requires selecting the 'NSNickName' indicator within Grid2.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return RRTDB.Settings["DandersFrames"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["DANDERS_FRAMES_NICKNAMES"] = true
                RRTDB.Settings["DandersFrames"] = value
            end,
            name = "Enable DandersFrames Nicknames",
            desc = "Enable Nicknames to be used with DandersFrames unit frames.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return RRTDB.Settings["ElvUI"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["ELVUI_NICKNAMES"] = true
                RRTDB.Settings["ElvUI"] = value
            end,
            name = "Enable ElvUI Nicknames",
            desc = "Enable Nicknames to be used with ElvUI unit frames. This requires editing your Tags. Available options are [NSNickName] and [NSNickName:1-12]",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return RRTDB.Settings["VuhDo"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["VUHDO_NICKNAMES"] = true
                RRTDB.Settings["VuhDo"] = value
            end,
            name = "Enable VuhDo Nicknames",
            desc = "Enable Nicknames to be used with VuhDo unit frames.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return RRTDB.Settings["Unhalted"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] = true
                RRTDB.Settings["Unhalted"] = value
            end,
            name = "Enable Unhalted UF Nicknames",
            desc = "Enable Nicknames to be used with Unhalted Unit Frames. You can choose 'NSNickName' as a tag within UUF.",
            nocombat = true
        },

        {
            type = "breakline"
        },
        {
            type = "button",
            name = "Wipe Nicknames",
            desc = "Wipe all nicknames from the database.",
            func = function(self)
                WipeNickNames()
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Edit Nicknames",
            desc = "Edit the nicknames database stored locally.",
            func = function(self)
                if not RRTUI.nickname_frame:IsShown() then
                    RRTUI.nickname_frame:Show()
                end
            end,
            nocombat = true
        }
    }
end

local function BuildNicknamesCallback()
    return function()
        if RRTUI.OptionsChanged.nicknames["NICKNAME"] then
            RRT:NickNameUpdated(RRTDB.Settings["MyNickName"])
        end

        if RRTUI.OptionsChanged.nicknames["GLOBAL_NICKNAMES"] then
            RRT:GlobalNickNameUpdate()
        end

        if RRTUI.OptionsChanged.nicknames["TRANSLIT"] then
            RRT:UpdateNickNameDisplay(true)
        end

        if RRTUI.OptionsChanged.nicknames["BLIZZARD_NICKNAMES"] then
            RRT:BlizzardNickNameUpdated()
        end

        if RRTUI.OptionsChanged.nicknames["CELL_NICKNAMES"] then
            RRT:CellNickNameUpdated(true)
        end

        if RRTUI.OptionsChanged.nicknames["ELVUI_NICKNAMES"] then
            RRT:ElvUINickNameUpdated()
        end

        if RRTUI.OptionsChanged.nicknames["VUHDO_NICKNAMES"] then
            RRT:VuhDoNickNameUpdated()
        end

        if RRTUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] then
            RRT:Grid2NickNameUpdated()
        end

        if RRTUI.OptionsChanged.nicknames["DANDERS_FRAMES_NICKNAMES"] then
            RRT:DandersFramesNickNameUpdated(true)
        end

        if RRTUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] then
            RRT:UnhaltedNickNameUpdated()
        end

        if RRTUI.OptionsChanged.nicknames["MRT_NICKNAMES"] then
            RRT:MRTNickNameUpdated(true)
        end

        wipe(RRTUI.OptionsChanged["nicknames"])
    end
end

-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.Nicknames = {
    BuildOptions = BuildNicknamesOptions,
    BuildCallback = BuildNicknamesCallback,
}



