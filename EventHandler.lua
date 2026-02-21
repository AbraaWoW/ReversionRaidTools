local _, RRT = ... -- Internal namespace
local f = RRT.RRTFrame
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("GROUP_FORMED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
f:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")
f:RegisterEvent("START_PLAYER_COUNTDOWN")
f:RegisterEvent("ENCOUNTER_WARNING")
f:RegisterEvent("RAID_BOSS_WHISPER")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, e, ...)
    RRT:EventHandler(e, true, false, ...)
end)

function RRT:EventHandler(e, wowevent, internal, ...) -- internal checks whether the event comes from addon comms. We don't want to allow blizzard events to be fired manually
    if e == "ADDON_LOADED" and wowevent then
        local name = ...
        if name == "ReversionRaidTools" then
            if not RRTDB then
                if type(ReversionRaidToolsDB) == "table" then
                    RRTDB = ReversionRaidToolsDB
                elseif type(AbraaRaidToolsDB) == "table" then
                    RRTDB = AbraaRaidToolsDB
                else
                    RRTDB = {}
                end
            end
            _G.ReversionRaidToolsDB = RRTDB
            _G.AbraaRaidToolsDB = RRTDB
            if not RRTDB.RRTUI then RRTDB.RRTUI = {scale = 1} end

            -- Bridge BuffReminders runtime DB to unified RRT saved variables
            RRTDB.BuffReminders = RRTDB.BuffReminders or {}
            if not RRTDB.RRTUI.timeline_window then RRTDB.RRTUI.timeline_window = { scale = 1 } end
            -- if not RRTDB.RRTUI.main_frame then RRTDB.RRTUI.main_frame = {} end
            -- if not RRTDB.RRTUI.external_frame then RRTDB.RRTUI.external_frame = {} end
            if not RRTDB.NickNames then RRTDB.NickNames = {} end
            if not RRTDB.Settings then RRTDB.Settings = {} end
            RRTDB.Reminders = RRTDB.Reminders or {}
            RRTDB.PersonalReminders = RRTDB.PersonalReminders or {}
            RRTDB.InviteList = RRTDB.InviteList or {}
            RRTDB.ActiveReminder = RRTDB.ActiveReminder or nil
            RRTDB.ActivePersonalReminder = RRTDB.ActivePersonalReminder or nil
            if not RRTDB.Settings.GlobalFont then RRTDB.Settings.GlobalFont = "Expressway" end
            self.Reminder = ""
            self.PersonalReminder = ""
            self.DisplayedReminder = ""
            self.DisplayedPersonalReminder = ""
            self.DisplayedExtraReminder = ""
            RRTDB.EncounterAlerts = RRTDB.EncounterAlerts or {}
            RRTDB.AssignmentSettings = RRTDB.AssignmentSettings or {}
            RRTDB.ReminderSettings = RRTDB.ReminderSettings or {}
            if RRTDB.ReminderSettings.enabled == nil then RRTDB.ReminderSettings.enabled = true end -- enable for note from raidleader
            RRTDB.ReminderSettings.Sticky = RRTDB.ReminderSettings.Sticky or 5
            if RRTDB.ReminderSettings.SpellTTS == nil then RRTDB.ReminderSettings.SpellTTS = true end
            if RRTDB.ReminderSettings.TextTTS == nil then RRTDB.ReminderSettings.TextTTS = true end
            RRTDB.ReminderSettings.SpellDuration = RRTDB.ReminderSettings.SpellDuration or 10
            RRTDB.ReminderSettings.TextDuration = RRTDB.ReminderSettings.TextDuration or 10
            RRTDB.ReminderSettings.SpellCountdown = RRTDB.ReminderSettings.SpellCountdown or 0
            RRTDB.ReminderSettings.TextCountdown = RRTDB.ReminderSettings.TextCountdown or 0
            if RRTDB.ReminderSettings.SpellName == nil then RRTDB.ReminderSettings.SpellName = true end -- Keep SpellName enable on first installation, then load from config
            RRTDB.ReminderSettings.SpellTTSTimer = RRTDB.ReminderSettings.SpellTTSTimer or 5
            RRTDB.ReminderSettings.TextTTSTimer = RRTDB.ReminderSettings.TextTTSTimer or 5
            if RRTDB.ReminderSettings.AutoShare == nil then RRTDB.ReminderSettings.AutoShare = true end
            if not RRTDB.ReminderSettings.PersonalReminderFrame then
                RRTDB.ReminderSettings.PersonalReminderFrame = {enabled = true, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 500, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if not RRTDB.ReminderSettings.ReminderFrame then
                RRTDB.ReminderSettings.ReminderFrame = {enabled = false, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 0, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if not RRTDB.ReminderSettings.ExtraReminderFrame then
                RRTDB.ReminderSettings.ExtraReminderFrame = {enabled = false, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 0, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if (not RRTDB.ReminderSettings.IconSettings) or (not RRTDB.ReminderSettings.IconSettings.GrowDirection) then
                RRTDB.ReminderSettings.IconSettings = {GrowDirection = "Down", Anchor = "CENTER", relativeTo = "CENTER", colors = {1, 1, 1, 1}, xOffset = -500, yOffset = 400, xTextOffset = 0, yTextOffset = 0, xTimer = 0, yTimer = 0, Font = "Expressway", FontSize = 30, TimerFontSize = 40, Width = 80, Height = 80, Spacing = -1}
            end
            if not RRTDB.ReminderSettings.IconSettings.colors then RRTDB.ReminderSettings.IconSettings.colors = {1, 1, 1, 1} end
            if not RRTDB.ReminderSettings.IconSettings.Glow then RRTDB.ReminderSettings.IconSettings.Glow = 0 end
            if (not RRTDB.ReminderSettings.BarSettings) or (not RRTDB.ReminderSettings.BarSettings.GrowDirection) then
                RRTDB.ReminderSettings.BarSettings = {GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", Width = 300, Height = 40, xIcon = 0, yIcon = 0, colors = {1, 0, 0, 1}, Texture = "Atrocity", xOffset = -400, yOffset = 0, xTextOffset = 2, yTextOffset = 0, xTimer = -2, yTimer = 0, Font = "Expressway", FontSize = 22, TimerFontSize = 22, Spacing = -1}
            end
            if (not RRTDB.ReminderSettings.TextSettings) or (not RRTDB.ReminderSettings.TextSettings.GrowDirection) then
                RRTDB.ReminderSettings.TextSettings =  {colors = {1, 1, 1, 1}, GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", xOffset = 0, yOffset = 200, Font = "Expressway", FontSize = 50, Spacing = 1}
            end
            if not RRTDB.ReminderSettings.TextSettings.colors then RRTDB.ReminderSettings.TextSettings.colors = {1, 1, 1, 1} end
            if (not RRTDB.ReminderSettings.UnitIconSettings) or (not RRTDB.ReminderSettings.UnitIconSettings.Position) then
                RRTDB.ReminderSettings.UnitIconSettings = {Position = "CENTER", xOffset = 0, yOffset = 0, Width = 25, Height = 25}
            end
            if not RRTDB.ReminderSettings.GlowSettings then
                RRTDB.ReminderSettings.GlowSettings = {colors = {0, 1, 0, 1}, Lines = 10, Frequency = 0.2, Length = 10, Thickness = 4, xOffset = 0, yOffset = 0}
            end
            if not RRTDB.PASettings then
                RRTDB.PASettings = {Spacing = -1, Limit = 5, GrowDirection = "RIGHT", enabled = false, Width = 100, Height = 100, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -450, yOffset = -100}
            end
            RRTDB.PASettings.Spacing = RRTDB.PASettings.Spacing or -1
            RRTDB.PASettings.Limit = RRTDB.PASettings.Limit or 5
            if not RRTDB.PATankSettings then
                RRTDB.PATankSettings = {Spacing = -1, Limit = 5, MultiTankGrowDirection = "UP", GrowDirection = "LEFT", enabled = false, Width = 100, Height = 100, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -549, yOffset = -199}
            end
            RRTDB.PATankSettings.Spacing = RRTDB.PATankSettings.Spacing or -1
            RRTDB.PATankSettings.Limit = RRTDB.PATankSettings.Limit or 5
            if not RRTDB.PARaidSettings then
                RRTDB.PARaidSettings = {PerRow = 3, RowGrowDirection = "UP", Spacing = -1, Limit = 5, GrowDirection = "RIGHT", enabled = false, Width = 25, Height = 25, Anchor = "BOTTOMLEFT", relativeTo = "BOTTOMLEFT", xOffset = 0, yOffset = 0}
            end
            if not RRTDB.PARaidSettings.PerRow then
                RRTDB.PARaidSettings.PerRow = 3
                RRTDB.PARaidSettings.RowGrowDirection = "UP"
                RRTDB.PASettings.PerRow = 10
                RRTDB.PASettings.RowGrowDirection = "UP"
            end
            if not RRTDB.PATextSettings then
                RRTDB.PATextSettings = {Scale = 2.5, xOffset = 0, yOffset = -200, enabled = false, Anchor = "TOP", relativeTo = "TOP"}
            end
            RRTDB.PARaidSettings.Spacing = RRTDB.PARaidSettings.Spacing or -1
            RRTDB.PARaidSettings.Limit = RRTDB.PARaidSettings.Limit or 5
            if not RRTDB.PASounds then RRTDB.PASounds = {} end
            RRTDB.Settings["MyNickName"] = RRTDB.Settings["MyNickName"] or nil
            RRTDB.Settings["ShareNickNames"] = RRTDB.Settings["ShareNickNames"] or 4 -- none default
            RRTDB.Settings["AcceptNickNames"] = RRTDB.Settings["AcceptNickNames"] or 4 -- none default
            RRTDB.Settings["NickNamesSyncAccept"] = RRTDB.Settings["NickNamesSyncAccept"] or 2 -- guild default
            RRTDB.Settings["NickNamesSyncSend"] = RRTDB.Settings["NickNamesSyncSend"] or 3 -- guild default
            if RRTDB.Settings["TTS"] == nil then RRTDB.Settings["TTS"] = true end
            RRTDB.Settings["TTSVolume"] = RRTDB.Settings["TTSVolume"] or 50
            RRTDB.Settings["TTSVoice"] = RRTDB.Settings["TTSVoice"] or 1
            RRTDB.Settings["Minimap"] = RRTDB.Settings["Minimap"] or {hide = false}
            RRTDB.Settings["VersionCheckPresets"] = RRTDB.Settings["VersionCheckPresets"] or {}
            RRTDB.Settings["CooldownThreshold"] = RRTDB.Settings["CooldownThreshold"] or 20
            if RRTDB.Settings["MissingRaidBuffs"] == nil then RRTDB.Settings["MissingRaidBuffs"] = true end
            if not RRTDB.ReadyCheckSettings then RRTDB.ReadyCheckSettings = {} end
            RRTDB.CooldownList = RRTDB.CooldownList or {}
            RRTDB.RRTUI.AutoComplete = RRTDB.RRTUI.AutoComplete or {}
            RRTDB.RRTUI.AutoComplete["Addon"] = RRTDB.RRTUI.AutoComplete["Addon"] or {}

            if RRTDB.ReminderSettings.ReminderFrame.enabled == nil then -- convert to different format
                RRTDB.ReminderSettings.ReminderFrame.enabled = RRTDB.ReminderSettings.ShowReminderFrame
                RRTDB.ReminderSettings.PersonalReminderFrame.enabled = RRTDB.ReminderSettings.ShowPersonalReminderFrame
                RRTDB.ReminderSettings.ExtraReminderFrame.enabled = RRTDB.ReminderSettings.ShowExtraReminderFrame
            end
            if RRTDB.UseDefaultPASounds then RRTDB.PASounds.UseDefaultPASounds = true end -- migrate old setting
            if not RRTDB.Settings.GenericDisplay then
                RRTDB.Settings.GenericDisplay = {Anchor = "CENTER", relativeTo = "CENTER", xOffset = -200, yOffset = 400}
            end
            if not RRTDB.QoL then
                RRTDB.QoL = {
                    TextDisplay = {
                        Anchor = "CENTER",
                        relativeTo = "CENTER",
                        xOffset = 0,
                        yOffset = 0,
                        FontSize = 30,
                    },
                    IconDisplay = {
                        Anchor = "TOP",
                        relativeTo = "TOP",
                        GrowDirection = "DOWN",
                        Scpaing = 5,
                        xOffset = 0,
                        yOffset = -350,
                        Width = 40,
                        Height = 40,
                    },
                    TradeableItems = {
                        Anchor = "TOP",
                        relativeTo = "TOP",
                        GrowDirection = "DOWN",
                        Spacing = 5,
                        xOffset = 0,
                        yOffset = -400,
                        FontSize = 18,
                        Width = 30,
                        Height = 30,
                    },
                }
            end
            if RRTDB.QoL.AutoBuyDecorItems == nil then RRTDB.QoL.AutoBuyDecorItems = false end
            if RRTDB.QoL.AutoSkipGossipDialogs == nil then RRTDB.QoL.AutoSkipGossipDialogs = false end
            if RRTDB.QoL.AutoAcceptGroupInvites == nil then RRTDB.QoL.AutoAcceptGroupInvites = false end
            if RRTDB.QoL.AutoConfirmRoleChecks == nil then RRTDB.QoL.AutoConfirmRoleChecks = false end
            if RRTDB.QoL.AchievementScreenshot == nil then RRTDB.QoL.AchievementScreenshot = false end
            if RRTDB.QoL.AutoCombatLogInInstance == nil then RRTDB.QoL.AutoCombatLogInInstance = false end
            self.BlizzardNickNamesHook = false
            self.MRTNickNamesHook = false
            self.ReminderTimer = {}
            self.PlayedSound = {}
            self.StartedCountdown = {}
            self.GlowStarted = {}
            self:CreateMoveFrames()
            self:InitNickNames()
            -- Migrate legacy lower-case keys from earlier Abraa-based storage format.
            if type(RRTDB.battleRez) == "table" and type(RRTDB.BattleRez) ~= "table" then
                RRTDB.BattleRez = RRTDB.battleRez
            end
            if type(RRTDB.combatTimer) == "table" and type(RRTDB.CombatTimer) ~= "table" then
                RRTDB.CombatTimer = RRTDB.combatTimer
            end
            if type(RRTDB.marksBar) == "table" and type(RRTDB.MarksBar) ~= "table" then
                RRTDB.MarksBar = RRTDB.marksBar
            end
            if type(RRTDB.raidGroups) == "table" and type(RRTDB.RaidGroups) ~= "table" then
                RRTDB.RaidGroups = RRTDB.raidGroups
            end
            if type(RRTDB.note) == "table" and type(RRTDB.Note) ~= "table" then
                RRTDB.Note = RRTDB.note
            end
            -- Setup Manager module DB defaults
            RRTDB.BattleRez  = RRTDB.BattleRez  or { enabled = false, position = nil, hideOutOfCombat = false, locked = false, scale = 1.0, showWhenUnlocked = true }
            RRTDB.CombatTimer = RRTDB.CombatTimer or { enabled = false, position = nil, hideOutOfCombat = false, locked = false, scale = 1.0 }
            RRTDB.MarksBar   = RRTDB.MarksBar    or { enabled = false, position = nil, locked = false, scale = 1.0, pullTimer = 10, showTargetMarks = true, showWorldMarks = true, showRaidTools = true }
            RRTDB.RaidGroups = RRTDB.RaidGroups  or { profiles = {}, currentSlots = {} }
            RRTDB.Note       = RRTDB.Note        or { text = "", title = "", saved = {} }
        end
    elseif e == "PLAYER_LOGIN" and wowevent then
        self.RRTUI:Init()
        self:InitLDB()
        self:InitQoL()
        self.RRTFrame:SetAllPoints(UIParent)
        local MyFrame = self.LGF.GetUnitFrame("player") -- need to call this once to init the library properly I think
        if RRTDB.PASettings.enabled then self:InitPA() end
        self:InitTextPA()
        if RRTDB.PARaidSettings.enabled then C_Timer.After(5, function() self:InitRaidPA(not UnitInRaid("player"), true) end) end
        if RRTDB.PASounds.UseDefaultPASounds then self:ApplyDefaultPASounds() end
        if RRTDB.PASounds.UseDefaultMPlusPASounds then self:ApplyDefaultPASounds(false, true) end
        for spellID, info in pairs(RRTDB.PASounds) do
            if type(info) == "table" and info.sound then -- prevents user settings
                self:AddPASound(spellID, info.sound)
            end
        end
        -- only running this on login if enabled. It will only run with false when actively disabling the setting. Doing it this way should prevent conflicts with other addons.
        if RRTDB.PASettings.DebuffTypeBorder then C_UnitAuras.TriggerPrivateAuraShowDispelType(true) end
        self:SetReminder(RRTDB.ActiveReminder, false, true) -- loading active reminder from last session
        self:SetReminder(RRTDB.ActivePersonalReminder, true, true) -- loading active personal reminder from last session
        self:FireCallback("RRT_REMINDER_CHANGED", self.PersonalReminder, self.Reminder)
        if self.Reminder == "" then -- if user doesn't have their own active Reminder, load shared one from last session. This should cover disconnects/relogs
            self.Reminder = RRTDB.StoredSharedReminder or ""
        end
        self:UpdateReminderFrame(true)
        if RRTDB.Settings["Debug"] then
            print("|cFF00FFFFRRT|r Debug mode is currently enabled. Please disable it with '/ns debug' unless you are specifically testing something.")
        end
        if RRTDB.HasLoggedIntoMidnight == nil then -- delete old macros on first login after update
            RRTDB.HasLoggedIntoMidnight = true
            local todelete = {}
            for i=1, 120 do
                local macroname = C_Macro.GetMacroName(i)
                if not macroname then break end
                if macroname == "NS PA Macro" or macroname == "NS Ext Macro" or macroname == "NS Innervate" then
                    table.insert(todelete, i)
                end
            end
            if #todelete > 0 then
                print("deleting", #todelete, "old RRTDB macros as they are no longer beinng used.")
                for i=#todelete, 1, -1 do
                    DeleteMacro(todelete[i])
                end
            end
        end
        if self:Restricted() then return end
        if RRTDB.Settings["MyNickName"] then self:SendNickName("Any") end -- only send nickname if it exists. If user has ever interacted with it it will create an empty string instead which will serve as deleting the nickname
        if RRTDB.Settings["GlobalNickNames"] then -- add own nickname if not already in database (for new characters)
            local name, realm = UnitName("player")
            if not realm then
                realm = GetNormalizedRealmName()
            end
            if (not RRTDB.NickNames[name.."-"..realm]) or (RRTDB.Settings["MyNickName"] ~= RRTDB.NickNames[name.."-"..realm]) then
                self:NewNickName("player", RRTDB.Settings["MyNickName"], name, realm)
            end
        end
    elseif e == "PLAYER_ENTERING_WORLD" then
        if not self:DifficultyCheck(14) then self:HideAllReminders(true) end
        local IsLogin, IsReload = ...
        if RRTDB.PARaidSettings.enabled and not (IsLogin or IsReload) then
            C_Timer.After(5, function() self:InitRaidPA(not UnitInRaid("player"), true) end)
        end
    elseif e == "ENCOUNTER_START" and wowevent then -- allow sending fake encounter_start if in debug mode, only send spec info in mythic, heroic and normal raids
        local diff = select(3, GetInstanceInfo()) or 0
        if  RRTDB.PATankSettings.enabled and diff <= 17 and diff >= 14 and UnitGroupRolesAssigned("player") == "TANK" then -- enabled in lfr, normal, heroic, mythic
            self:InitTankPA()
        end
        if diff < 14 and diff > 17 and diff ~= 220 then return end -- everything else is enabled in lfr, normal, heroic, mythic and story mode because people like to test in there.
        self.RRTFrame.generic_display:Hide()
        if RRTDB.PARaidSettings.enabled then self:InitRaidPA(false) end
        if not self.ProcessedReminder then -- should only happen if there was never a ready check, good to have this fallback though in case the user connected/zoned in after a ready check or they never did a ready check
            self:ProcessReminder()
        end
        self.TestingReminder = false
        self.IsInPreview = false
        for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
            self:ToggleMoveFrames(self[v], false)
        end
        self.EncounterID = ...
        self.Phase = 1
        self.PhaseSwapTime = GetTime()
        self.ReminderText = self.ReminderText or {}
        self.ReminderIcon = self.ReminderIcon or {}
        self.ReminderBar = self.ReminderBar or {}
        self.ReminderTimer = self.ReminderTimer or {}
        self.AllGlows = self.AllGlows or {}
        self.PlayedSound = {}
        self.StartedCountdown = {}
        self.GlowStarted = {}
        self.Timelines = {}
        self.DefaultAlertID = 10000
        if self.AddAssignments[self.EncounterID] then self.AddAssignments[self.EncounterID](self) end
        if self.EncounterAlertStart[self.EncounterID] then self.EncounterAlertStart[self.EncounterID](self) end
        self:StartReminders(self.Phase)
    elseif e == "ENCOUNTER_END" and wowevent and self:DifficultyCheck(14) then
        local encID, encounterName = ...
        if RRTDB.PATankSettings.enabled and UnitGroupRolesAssigned("player") == "TANK" then
            self:RemoveTankPA()
        end
        self:HideAllReminders(true)
        C_Timer.After(1, function()
            if self:Restricted() then return end
            if self.SyncNickNamesStore then
                self:EventHandler("RRT_NICKNAMES_SYNC", false, true, self.SyncNickNamesStore.unit, self.SyncNickNamesStore.nicknametable, self.SyncNickNamesStore.channel)
                self.SyncNickNamesStore = nil
            end
        end)
    elseif e == "START_PLAYER_COUNTDOWN" and wowevent then -- do basically the same thing as ready check in case one of them is skipped
        if self.LastBroadcast and self.LastBroadcast > GetTime() - 30 then return end -- only do this if there was no recent ready check basically
        self.LastBroadcast = GetTime()
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        self:Broadcast("RRT_SPEC", "RAID", specid)
        if UnitIsGroupLeader("player") and UnitInRaid("player") then
            local tosend = false
            if RRTDB.ReminderSettings.AutoShare then
                tosend = self.Reminder
            end
            self:Broadcast("RRT_REM_SHARE", "RAID", tosend, RRTDB.AssignmentSettings, false)
            self.Assignments = RRTDB.AssignmentSettings
        end
    elseif e == "READY_CHECK" and wowevent then
        if self:DifficultyCheck(14) or diff == 23 then
            C_Timer.After(1, function()
                self:EventHandler("RRT_READY_CHECK", false, true)
            end)
        end
        if UnitIsGroupLeader("player") and UnitInRaid("player") then
            -- always doing this, even outside of raid to allow outside raidleading to work. The difficulty check will instead happen client-side
            local tosend = false
            if RRTDB.ReminderSettings.AutoShare then
                tosend = self.Reminder
            end
            self:Broadcast("RRT_REM_SHARE", "RAID", tosend, RRTDB.AssignmentSettings, false)
            self.Assignments = RRTDB.AssignmentSettings
        end
        -- broadcast spec info
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        self:Broadcast("RRT_SPEC", "RAID", specid)
        if C_ChatInfo.InChatMessagingLockdown() then return end
        self.LastBroadcast = GetTime()
        local diff= select(3, GetInstanceInfo()) or 0
        self.specs = {}
        self.GUIDS = {}
        self.HasRRT = {}
        for u in self:IterateGroupMembers() do
            if UnitIsVisible(u) then
                self.HasRRT[u] = false
                self.specs[u] = false
                local G = UnitGUID(u)
                self.GUIDS[u] = issecretvalue(G) and "" or G
            end
        end
        if self:Restricted() then return end
        if RRTDB.Settings["CheckCooldowns"] and self:DifficultyCheck(15) and UnitInRaid("player") then -- only heroic& mythic because in normal you just wanna go fast and don't care about someone having a cd
            self:CheckCooldowns()
        end
    elseif e == "RRT_REM_SHARE"  and internal then
        local unit, reminderstring, assigntable, skipcheck = ...
        if (UnitIsGroupLeader(unit) or (UnitIsGroupAssistant(unit) and skipcheck)) and (self:DifficultyCheck(14) or skipcheck) then -- skipcheck allows manually sent reminders to bypass difficulty checks
            if (RRTDB.ReminderSettings.enabled or RRTDB.ReminderSettings.UseTimelineReminders) and reminderstring and type(reminderstring) == "string" and reminderstring ~= "" then
                RRTDB.StoredSharedReminder = self.Reminder -- store in SV to reload on next login
                self.Reminder = reminderstring
                self:ProcessReminder()
                self:UpdateReminderFrame(true)
                if skipcheck then self:FlashNoteBackgrounds() end -- only show animation if reminder was manually shared
                self:FireCallback("RRT_REMINDER_CHANGED", self.PersonalReminder, self.Reminder)
            end
            if assigntable then self.Assignments = assigntable end
        end
    elseif e == "RRT_READY_CHECK" and internal then
        local text = ""
        if UnitLevel("player") < 80 then return end
        if RRTDB.ReadyCheckSettings.RaidBuffCheck and not self:Restricted() then
            local buff = self:BuffCheck()
            if buff and buff ~= "" then text = buff end
        end
        if RRTDB.ReadyCheckSettings.SoulstoneCheck and not self:Restricted() then
            local Soulstone = self:SoulstoneCheck()
            if Soulstone and Soulstone ~= "" then
                if text == "" then
                    text = Soulstone
                else
                    text = text.."\n"..Soulstone
                end
            end
        end
        if UnitLevel("player") >= 80 then
            local Gear = self:GearCheck()
            if Gear and Gear ~= "" then
                if text == "" then
                    text = Gear
                else
                    text = text.."\n"..Gear
                end
            end
        end
        if text ~= "" then
            self:DisplayText(text)
        end
    elseif e == "GROUP_FORMED" and wowevent then
        if self:Restricted() then return end
        if RRTDB.Settings["MyNickName"] then self:SendNickName("Any", true) end -- only send nickname if it exists. If user has ever interacted with it it will create an empty string instead which will serve as deleting the nickname
    elseif e == "RRT_VERSION_CHECK" and internal then
        if self:Restricted() then return end
        local unit, ver, ignoreCheck = ...
        self:VersionResponse({name = UnitName(unit), version = ver, ignoreCheck = ignoreCheck})
    elseif e == "RRT_VERSION_REQUEST" and internal then
        local unit, type, name = ...
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't send to yourself
        if UnitExists(unit) then
            local u, ver, _, ignoreCheck = self:GetVersionNumber(type, name, unit)
            self:Broadcast("RRT_VERSION_CHECK", "WHISPER", unit, ver, ignoreCheck)
        end
    elseif e == "RRT_NICKNAMES_COMMS" and internal then
        if self:Restricted() then return end
        local unit, nickname, name, realm, requestback, channel = ...
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't add new nickname if it's yourself because already adding it to the database when you edit it
        if requestback and (UnitInRaid(unit) or UnitInParty(unit)) then self:SendNickName(channel, false) end -- send nickname back to the person who requested it
        self:NewNickName(unit, nickname, name, realm, channel)

    elseif e == "PLAYER_REGEN_ENABLED" and wowevent then
        C_Timer.After(1, function()
            if self:Restricted() then return end
            if self.SyncNickNamesStore then
                self:EventHandler("RRT_NICKNAMES_SYNC", false, true, self.SyncNickNamesStore.unit, self.SyncNickNamesStore.nicknametable, self.SyncNickNamesStore.channel)
                self.SyncNickNamesStore = nil
            end
            if self.WAString and self.WAString.unit and self.WAString.string then
                self:EventHandler("RRT_WA_SYNC", false, true, self.WAString.unit, self.WAString.string)
                self.WAString = nil
            end
        end)
    elseif e == "RRT_NICKNAMES_SYNC" and internal then
        local unit, nicknametable, channel = ...
        local setting = RRTDB.Settings["NickNamesSyncAccept"]
        if (setting == 3 or (setting == 2 and channel == "GUILD") or (setting == 1 and channel == "RAID") and (not C_ChallengeMode.IsChallengeModeActive())) then
            if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't accept sync requests from yourself
            if self:Restricted() or UnitAffectingCombat("player") then
                self.SyncNickNamesStore = {unit = unit, nicknametable = nicknametable, channel = channel}
            else
                self:NickNamesSyncPopup(unit, nicknametable)
            end
        end
    elseif e == "RRT_WA_SYNC" and internal then
        local unit, str = ...
        local setting = RRTDB.Settings["WeakAurasImportAccept"]
        if setting == 3 then return end
        if UnitExists(unit) and not UnitIsUnit("player", unit) then
            if setting == 2 or (GetGuildInfo(unit) == GetGuildInfo("player")) then -- only accept this from same guild to prevent abuse
                if self:Restricted() or UnitAffectingCombat("player") then
                    self.WAString = {unit = unit, string = str}
                else
                    self:WAImportPopup(unit, str)
                end
            end
        end

    elseif e == "RRT_SPEC" and internal then -- renamed for Midnight
        local unit, spec = ...
        self.specs = self.specs or {}
        local G = UnitGUID(unit)
        G = issecretvalue(G) and "" or G
        self.specs[unit] = tonumber(spec)
        self.HasRRT = self.HasRRT or {}
        self.HasRRT[unit] = true
        if G ~= "" then
            self.GUIDS = self.GUIDS or {}
            self.GUIDS[unit] = G
        end
    elseif e == "RRT_SPEC_REQUEST" then
        local specid = GetSpecializationInfo(GetSpecialization())
        self:Broadcast("RRT_SPEC", "RAID", specid)
    elseif e == "GROUP_ROSTER_UPDATE" and wowevent then
        self:ArrangeGroups()
        if RRTDB.PARaidSettings.enabled then
            C_Timer.After(5, function() self:InitRaidPA(not UnitInRaid("player"), true) end)
        end

        self:UpdateRaidBuffFrame()
        if self:Restricted() then return end

        if self.InviteInProgress then
            if not UnitInRaid("player") then
                C_PartyInfo.ConvertToRaid()
                C_Timer.After(1, function() -- send invites again if player is now in a raid
                    if UnitInRaid("player") then
                        self:InviteList(self.CurrentInviteList)
                        self.InviteInProgress = nil
                    end
                end)
            end
        end

        if not self:DifficultyCheck(14) then return end
    elseif (e == "ENCOUNTER_TIMELINE_EVENT_ADDED" or e == "ENCOUNTER_TIMELINE_EVENT_REMOVED") and wowevent then
        if not self:DifficultyCheck(14) then return end
        local info = ...
        if self:Restricted() and self.EncounterID and self.DetectPhaseChange[self.EncounterID] then self.DetectPhaseChange[self.EncounterID](self, e, info) end
    elseif e == "ENCOUNTER_WARNING" and wowevent then
        local info = ...
        if not self:DifficultyCheck(14) then return end
        if self.ShowWarningAlert[self.EncounterID] then self.ShowWarningAlert[self.EncounterID](self, self.EncounterID, self.Phase, self.PhaseSwapTime, info) end
    elseif e == "RAID_BOSS_WHISPER" and wowevent then
        local text, name, dur = ...
        if not self:DifficultyCheck(14) then return end
        if self.ShowBossWhisperAlert[self.EncounterID] then self.ShowBossWhisperAlert[self.EncounterID](self, self.EncounterID, self.Phase, self.PhaseSwapTime, text, name, dur) end
    end
end









