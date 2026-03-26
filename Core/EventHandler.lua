local _, RRT_NS = ... -- Internal namespace
local f = RRT_NS.RRTFrame
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
f:RegisterEvent("UNIT_AURA")

f:SetScript("OnEvent", function(self, e, ...)
    RRT_NS:EventHandler(e, true, false, ...)
end)

function RRT_NS:EventHandler(e, wowevent, internal, ...) -- internal checks whether the event comes from addon comms. We don't want to allow blizzard events to be fired manually
    if e == "ADDON_LOADED" and wowevent then
        local name = ...
        if name == "ReversionRaidTools" then
            if not RRT then RRT = {} end
            if not RRT.RRTUI then RRT.RRTUI = {scale = 1} end
            if not RRT.RRTUI.timeline_window then RRT.RRTUI.timeline_window = { scale = 1 } end
            -- if not RRT.RRTUI.main_frame then RRT.RRTUI.main_frame = {} end
            -- if not RRT.RRTUI.external_frame then RRT.RRTUI.external_frame = {} end
            if not RRT.Settings then RRT.Settings = {} end
            RRT.NickNames = RRT.NickNames or {}
            RRT.Reminders = RRT.Reminders or {}
            RRT.PersonalReminders = RRT.PersonalReminders or {}
            RRT.InviteList = RRT.InviteList or {}
            RRT.ActiveReminder = RRT.ActiveReminder or nil
            RRT.ActivePersonalReminder = RRT.ActivePersonalReminder or nil
            if not RRT.Settings.GlobalFont then RRT.Settings.GlobalFont = "Expressway" end
            if not RRT.Settings.TabSelectionColor then RRT.Settings.TabSelectionColor = {0.639, 0.188, 0.788, 1} end
            if not RRT.Settings.Language then RRT.Settings.Language = (GetLocale() == "frFR" and "FR" or "EN") end
            if RRT.Settings.RLAlias == nil then RRT.Settings.RLAlias = true end
            RRT_NS.RaidFrame:Init()
            self.Reminder = ""
            self.PersonalReminder = ""
            self.DisplayedReminder = ""
            self.DisplayedPersonalReminder = ""
            self.DisplayedExtraReminder = ""
            RRT.EncounterAlerts = RRT.EncounterAlerts or {}
            RRT.AssignmentSettings = RRT.AssignmentSettings or {}
            RRT.ReminderSettings = RRT.ReminderSettings or {}
            if RRT.ReminderSettings.enabled == nil then RRT.ReminderSettings.enabled = true end -- enable for note from raidleader
            if RRT.ReminderSettings.PersNote == nil then RRT.ReminderSettings.PersNote = true end
            RRT.ReminderSettings.Sticky = RRT.ReminderSettings.Sticky or 5
            if RRT.ReminderSettings.SpellTTS == nil then RRT.ReminderSettings.SpellTTS = true end
            if RRT.ReminderSettings.TextTTS == nil then RRT.ReminderSettings.TextTTS = true end
            RRT.ReminderSettings.SpellDuration = RRT.ReminderSettings.SpellDuration or 10
            RRT.ReminderSettings.TextDuration = RRT.ReminderSettings.TextDuration or 10
            RRT.ReminderSettings.SpellCountdown = RRT.ReminderSettings.SpellCountdown or 0
            RRT.ReminderSettings.TextCountdown = RRT.ReminderSettings.TextCountdown or 0
            if RRT.ReminderSettings.SpellName == nil then RRT.ReminderSettings.SpellName = true end -- Keep SpellName enable on first installation, then load from config
            RRT.ReminderSettings.SpellTTSTimer = RRT.ReminderSettings.SpellTTSTimer or 5
            RRT.ReminderSettings.TextTTSTimer = RRT.ReminderSettings.TextTTSTimer or 5
            if RRT.ReminderSettings.AutoShare == nil then RRT.ReminderSettings.AutoShare = true end
            if not RRT.ReminderSettings.PersonalReminderFrame then
                RRT.ReminderSettings.PersonalReminderFrame = {enabled = true, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 500, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if not RRT.ReminderSettings.ReminderFrame then
                RRT.ReminderSettings.ReminderFrame = {enabled = false, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 0, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if not RRT.ReminderSettings.ExtraReminderFrame then
                RRT.ReminderSettings.ExtraReminderFrame = {enabled = false, Width = 500, Height = 600, Anchor = "TOPLEFT", relativeTo = "TOPLEFT", xOffset = 0, yOffset = 0, Font = "Expressway", FontSize = 14, BGcolor = {0, 0, 0, 0.3},}
            end
            if (not RRT.ReminderSettings.IconSettings) or (not RRT.ReminderSettings.IconSettings.GrowDirection) then
                RRT.ReminderSettings.IconSettings = {GrowDirection = "Down", Anchor = "CENTER", relativeTo = "CENTER", colors = {1, 1, 1, 1}, xOffset = -500, yOffset = 400, xTextOffset = 0, yTextOffset = 0, xTimer = 0, yTimer = 0, Font = "Expressway", FontSize = 30, TimerFontSize = 40, Width = 80, Height = 80, Spacing = -1}
            end
            if not RRT.ReminderSettings.IconSettings.colors then RRT.ReminderSettings.IconSettings.colors = {1, 1, 1, 1} end
            if not RRT.ReminderSettings.IconSettings.Glow then RRT.ReminderSettings.IconSettings.Glow = 0 end
            if (not RRT.ReminderSettings.BarSettings) or (not RRT.ReminderSettings.BarSettings.GrowDirection) then
                RRT.ReminderSettings.BarSettings = {GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", Width = 300, Height = 40, xIcon = 0, yIcon = 0, colors = {1, 0, 0, 1}, Texture = "Atrocity", xOffset = -400, yOffset = 0, xTextOffset = 2, yTextOffset = 0, xTimer = -2, yTimer = 0, Font = "Expressway", FontSize = 22, TimerFontSize = 22, Spacing = -1}
            end
            if (not RRT.ReminderSettings.TextSettings) or (not RRT.ReminderSettings.TextSettings.GrowDirection) then
                RRT.ReminderSettings.TextSettings =  {colors = {1, 1, 1, 1}, GrowDirection = "Up", Anchor = "CENTER", relativeTo = "CENTER", xOffset = 0, yOffset = 200, Font = "Expressway", FontSize = 50, Spacing = 1}
            end
            if not RRT.ReminderSettings.TextSettings.colors then RRT.ReminderSettings.TextSettings.colors = {1, 1, 1, 1} end
            if (not RRT.ReminderSettings.UnitIconSettings) or (not RRT.ReminderSettings.UnitIconSettings.Position) then
                RRT.ReminderSettings.UnitIconSettings = {Position = "CENTER", xOffset = 0, yOffset = 0, Width = 25, Height = 25}
            end
            if not RRT.ReminderSettings.GlowSettings then
                RRT.ReminderSettings.GlowSettings = {colors = {0, 1, 0, 1}, Lines = 10, Frequency = 0.2, Length = 10, Thickness = 4, xOffset = 0, yOffset = 0}
            end
            if not RRT.PASettings then
                RRT.PASettings = {Spacing = -1, Limit = 5, GrowDirection = "RIGHT", enabled = false, Width = 100, Height = 100, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -450, yOffset = -100}
            end
            RRT.PASettings.Spacing = RRT.PASettings.Spacing or -1
            RRT.PASettings.Limit = RRT.PASettings.Limit or 5
            if not RRT.PATankSettings then
                RRT.PATankSettings = {Spacing = -1, Limit = 5, MultiTankGrowDirection = "UP", GrowDirection = "LEFT", enabled = false, Width = 100, Height = 100, Anchor = "CENTER", relativeTo = "CENTER", xOffset = -549, yOffset = -199}
            end
            RRT.PATankSettings.Spacing = RRT.PATankSettings.Spacing or -1
            RRT.PATankSettings.Limit = RRT.PATankSettings.Limit or 5
            if not RRT.PARaidSettings then
                RRT.PARaidSettings = {PerRow = 3, RowGrowDirection = "UP", Spacing = -1, Limit = 5, GrowDirection = "RIGHT", enabled = false, Width = 25, Height = 25, Anchor = "BOTTOMLEFT", relativeTo = "BOTTOMLEFT", xOffset = 0, yOffset = 0}
            end
            if not RRT.PARaidSettings.PerRow then
                RRT.PARaidSettings.PerRow = 3
                RRT.PARaidSettings.RowGrowDirection = "UP"
                RRT.PASettings.PerRow = 10
                RRT.PASettings.RowGrowDirection = "UP"
            end
            if not RRT.PATextSettings then
                RRT.PATextSettings = {Scale = 2.5, xOffset = 0, yOffset = -200, enabled = false, Anchor = "TOP", relativeTo = "TOP"}
            end
            RRT.PARaidSettings.Spacing = RRT.PARaidSettings.Spacing or -1
            RRT.PARaidSettings.Limit = RRT.PARaidSettings.Limit or 5
            if not RRT.PASounds then RRT.PASounds = {} end
            -- Nicknames settings defaults
            RRT.Settings["MyNickName"]         = RRT.Settings["MyNickName"]         -- nil = no nickname
            RRT.Settings["ShareNickNames"]     = RRT.Settings["ShareNickNames"]     or 4 -- None
            RRT.Settings["AcceptNickNames"]    = RRT.Settings["AcceptNickNames"]    or 4 -- None
            RRT.Settings["NickNamesSyncAccept"]= RRT.Settings["NickNamesSyncAccept"]or 2 -- Guild
            RRT.Settings["NickNamesSyncSend"]  = RRT.Settings["NickNamesSyncSend"]  or 3 -- None
            if RRT.Settings["TTS"] == nil then RRT.Settings["TTS"] = true end
            RRT.Settings["TTSVolume"] = RRT.Settings["TTSVolume"] or 50
            RRT.Settings["TTSVoice"] = RRT.Settings["TTSVoice"] or 1
            RRT.Settings["Minimap"] = RRT.Settings["Minimap"] or {hide = false}
            RRT.Settings["VersionCheckPresets"] = RRT.Settings["VersionCheckPresets"] or {}
            RRT.Settings["CooldownThreshold"] = RRT.Settings["CooldownThreshold"] or 20
            if RRT.Settings["MissingRaidBuffs"] == nil then RRT.Settings["MissingRaidBuffs"] = true end
            if not RRT.ReadyCheckSettings then RRT.ReadyCheckSettings = {} end
            RRT.CooldownList = RRT.CooldownList or {}
            RRT.RRTUI.AutoComplete = RRT.RRTUI.AutoComplete or {}
            RRT.RRTUI.AutoComplete["Addon"] = RRT.RRTUI.AutoComplete["Addon"] or {}

            if RRT.ReminderSettings.ReminderFrame.enabled == nil then -- convert to different format
                RRT.ReminderSettings.ReminderFrame.enabled = RRT.ReminderSettings.ShowReminderFrame or false
                RRT.ReminderSettings.PersonalReminderFrame.enabled = RRT.ReminderSettings.ShowPersonalReminderFrame or false
                RRT.ReminderSettings.ExtraReminderFrame.enabled = RRT.ReminderSettings.ShowExtraReminderFrame or false
            end
            if RRT.PASounds.UseDefaultPASounds == nil then -- convert old setting
                RRT.PASounds.UseDefaultPASounds = RRT.UseDefaultPASounds or false
            end
            if not RRT.BuffSounds then RRT.BuffSounds = {} end
            if not RRT.DebuffSounds then RRT.DebuffSounds = {} end
            if RRT_NS.RaidGroups then RRT_NS.RaidGroups:InitDB() end
            if not RRT.Settings.GenericDisplay then
                RRT.Settings.GenericDisplay = {Anchor = "CENTER", relativeTo = "CENTER", xOffset = -200, yOffset = 400}
            end
            if not RRT.QoL then
                RRT.QoL = {
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
            if RRT.QoL.ShowSpellIDTooltip == nil then RRT.QoL.ShowSpellIDTooltip = false end
            if not RRT.MouseRing then RRT.MouseRing = {} end
            if not RRT.Crosshair then RRT.Crosshair = {} end
            if RRT_NS.Crosshair and RRT_NS.Crosshair.DEFAULTS then
                for k, v in pairs(RRT_NS.Crosshair.DEFAULTS) do
                    if RRT.Crosshair[k] == nil then RRT.Crosshair[k] = v end
                end
            end
            if RRT.QoL.DurabilityWarning == nil then RRT.QoL.DurabilityWarning = false end
            RRT.QoL.DurabilityThreshold = RRT.QoL.DurabilityThreshold or 50
            if RRT.QoL.ChatFilter == nil then RRT.QoL.ChatFilter = false end
            if RRT.QoL.ChatFilterLoginMessage == nil then RRT.QoL.ChatFilterLoginMessage = true end
            if not RRT.QoL.ChatFilterKeywords then
                RRT.QoL.ChatFilterKeywords = {}
                for _, kw in ipairs({"wts gold","buy gold","cheap gold","wts boost","wts carry","wts run","boost cheap","carry cheap","piloted","selfplay","powerleveling"}) do
                    RRT.QoL.ChatFilterKeywords[kw] = true
                end
            end
            if RRT.QoL.DeleteConfirm == nil then RRT.QoL.DeleteConfirm = false end
            if RRT.QoL.DisableAutoAddSpells == nil then RRT.QoL.DisableAutoAddSpells = false end
            if not RRT.Tooltip then RRT.Tooltip = {} end
            if RRT_NS.Tooltip and RRT_NS.Tooltip.DEFAULTS then
                for k, v in pairs(RRT_NS.Tooltip.DEFAULTS) do
                    if RRT.Tooltip[k] == nil then RRT.Tooltip[k] = v end
                end
            end
            if RRT.QoL.FasterLoot == nil then RRT.QoL.FasterLoot = false end
            if RRT.QoL.SkipCinematics == nil then RRT.QoL.SkipCinematics = false end
            if RRT.QoL.SkipCinematicsMessage == nil then RRT.QoL.SkipCinematicsMessage = true end
            if not RRT.AutoQuest then RRT.AutoQuest = {} end
            if RRT_NS.Questing and RRT_NS.Questing.DEFAULTS_AUTOQUEST then
                for k, v in pairs(RRT_NS.Questing.DEFAULTS_AUTOQUEST) do
                    if RRT.AutoQuest[k] == nil then RRT.AutoQuest[k] = v end
                end
            end
            if not RRT.CombatTimer then RRT.CombatTimer = {} end
            if RRT_NS.CombatTimer and RRT_NS.CombatTimer.DEFAULTS then
                for k, v in pairs(RRT_NS.CombatTimer.DEFAULTS) do
                    if RRT.CombatTimer[k] == nil then RRT.CombatTimer[k] = v end
                end
            end
            if not RRT.Dragonriding then RRT.Dragonriding = {} end
            if RRT_NS.Dragonriding and RRT_NS.Dragonriding.DEFAULTS then
                for k, v in pairs(RRT_NS.Dragonriding.DEFAULTS) do
                    if RRT.Dragonriding[k] == nil then RRT.Dragonriding[k] = v end
                end
            end
            if not RRT.CombatAlert then RRT.CombatAlert = {} end
            if RRT_NS.CombatAlert and RRT_NS.CombatAlert.DEFAULTS then
                for k, v in pairs(RRT_NS.CombatAlert.DEFAULTS) do
                    if RRT.CombatAlert[k] == nil then
                        if type(v) == "table" then
                            RRT.CombatAlert[k] = { r = v.r, g = v.g, b = v.b }
                        else
                            RRT.CombatAlert[k] = v
                        end
                    end
                end
            end
            if not RRT.CombatLogger then RRT.CombatLogger = { enabled = false, instances = {} } end
            if not RRT.BattleRez then RRT.BattleRez = {} end
            if RRT_NS.BattleRez and RRT_NS.BattleRez.DEFAULTS then
                for k, v in pairs(RRT_NS.BattleRez.DEFAULTS) do
                    if RRT.BattleRez[k] == nil then RRT.BattleRez[k] = v end
                end
            end
            if RRT.QoL.PetTrackerEnabled == nil then RRT.QoL.PetTrackerEnabled = false end
            if not RRT.PetTracker then RRT.PetTracker = {} end
            if RRT_NS.PetTracker and RRT_NS.PetTracker.DEFAULTS then
                for k, v in pairs(RRT_NS.PetTracker.DEFAULTS) do
                    if RRT.PetTracker[k] == nil then RRT.PetTracker[k] = v end
                end
            end
            if not RRT.DontRelease then RRT.DontRelease = { enabled = false } end
            if not RRT.TalentReminder then RRT.TalentReminder = {} end
            if RRT_NS.TalentReminder and RRT_NS.TalentReminder.DEFAULTS then
                for k, v in pairs(RRT_NS.TalentReminder.DEFAULTS) do
                    if RRT.TalentReminder[k] == nil then RRT.TalentReminder[k] = v end
                end
            end
            if not RRT.EquipmentReminder then RRT.EquipmentReminder = {} end
            if RRT_NS.EquipmentReminder and RRT_NS.EquipmentReminder.DEFAULTS then
                for k, v in pairs(RRT_NS.EquipmentReminder.DEFAULTS) do
                    if RRT.EquipmentReminder[k] == nil then RRT.EquipmentReminder[k] = v end
                end
            end
            if not RRT.AutoKeystone then RRT.AutoKeystone = {} end
            if RRT_NS.AutoKeystone and RRT_NS.AutoKeystone.DEFAULTS then
                for k, v in pairs(RRT_NS.AutoKeystone.DEFAULTS) do
                    if RRT.AutoKeystone[k] == nil then RRT.AutoKeystone[k] = v end
                end
            end
            if not RRT.AutoQueue then RRT.AutoQueue = {} end
            if RRT_NS.AutoQueue and RRT_NS.AutoQueue.DEFAULTS then
                for k, v in pairs(RRT_NS.AutoQueue.DEFAULTS) do
                    if RRT.AutoQueue[k] == nil then RRT.AutoQueue[k] = v end
                end
            end
            if not RRT.CDNote then RRT.CDNote = {} end
            if RRT_NS.CDNote and RRT_NS.CDNote.DEFAULTS then
                for k, v in pairs(RRT_NS.CDNote.DEFAULTS) do
                    if RRT.CDNote[k] == nil then RRT.CDNote[k] = v end
                end
            end
            if not RRT.AutoPlaystyle then RRT.AutoPlaystyle = {} end
            if RRT_NS.AutoPlaystyle and RRT_NS.AutoPlaystyle.DEFAULTS then
                for k, v in pairs(RRT_NS.AutoPlaystyle.DEFAULTS) do
                    if RRT.AutoPlaystyle[k] == nil then RRT.AutoPlaystyle[k] = v end
                end
            end

            if RRT.EncounterAlerts[3179] then -- automatically enable CC Add display if user had previously enabled alerts for the first time loging in after adding the option.
                if RRT.EncounterAlerts[3179].CCAddsDisplay == nil then
                    if RRT.EncounterAlerts[3179] and RRT.EncounterAlerts[3179].enabled then
                        RRT.EncounterAlerts[3179].CCAddsDisplay = true
                    else
                        RRT.EncounterAlerts[3179].CCAddsDisplay = false
                    end
                end
            else
                RRT.EncounterAlerts[3179] = {enabled = false, CCAddsDisplay = false}
            end

            if not RRT.Settings["GlobalFontSize"] then RRT.Settings["GlobalFontSize"] = 20 end
            if not RRT.Settings["GlobalEncounterFontSize"] then RRT.Settings["GlobalEncounterFontSize"] = 20 end

            self.ReminderTimer = {}
            self.PlayedSound = {}
            self.StartedCountdown = {}
            self.GlowStarted = {}
            self.BlizzardNickNamesHook = false
            self.VuhDoNickNamesHook    = false
            self:CreateMoveFrames()
            self:InitNickNames()
        end
    elseif e == "PLAYER_LOGIN" and wowevent then
        self.RRTUI:Init()
        self:InitLDB()
        self:InitQoL()
        if self.MouseRing    then self.MouseRing:Enable()    end
        if self.Crosshair    then self.Crosshair:Enable()    end
        if self.Dragonriding then self.Dragonriding:Enable() end
        if self.Durability   then self.Durability:Enable()   end
        if self.CombatTimer  then self.CombatTimer:Enable()  end
        if self.CombatAlert  then self.CombatAlert:Enable()  end
        if self.CombatLogger then self.CombatLogger:Enable() end
        if self.BattleRez    then self.BattleRez:Enable()    end
        if self.PetTracker        then self.PetTracker:Enable()        end
        if self.TalentReminder    then self.TalentReminder:Enable()    end
        if self.EquipmentReminder then self.EquipmentReminder:Enable() end
        if self.Tooltip           then self.Tooltip:Enable()           end
        if self.Questing          then self.Questing:Enable()          end
        if self.AutoKeystone      then self.AutoKeystone:Enable()      end
        if self.AutoQueue         then self.AutoQueue:Enable()         end
        if self.AutoPlaystyle     then self.AutoPlaystyle:Enable()     end
        if self.CDNote            then self.CDNote:Enable()            end
        self.RRTFrame:SetAllPoints(UIParent)
        local MyFrame = self.LGF.GetUnitFrame("player") -- need to call this once to init the library properly I think
        if RRT.PASettings.enabled then self:InitPA() end
        self:InitTextPA()
        if RRT.PARaidSettings.enabled then
            self.InitRaidPATimer = C_Timer.After(5, function() self.InitRaidPATimer = nil; self:InitRaidPA(not UnitInRaid("player"), true) end)
        end
        if RRT.PASounds.UseDefaultPASounds then self:ApplyDefaultPASounds() end
        self:EnableBuffSounds()
        self:EnableDebuffSounds()
        if RRT.PASounds.UseDefaultMPlusPASounds then self:ApplyDefaultPASounds(false, true) end
        for spellID, info in pairs(RRT.PASounds) do
            if type(info) == "table" and info.sound then -- prevents user settings
                self:AddPASound(spellID, info.sound)
            end
        end
        -- only running this on login if enabled. It will only run with false when actively disabling the setting. Doing it this way should prevent conflicts with other addons.
        if RRT.PASettings.DebuffTypeBorder then C_UnitAuras.TriggerPrivateAuraShowDispelType(true) end
        self:SetReminder(RRT.ActiveReminder, false, true) -- loading active reminder from last session
        self:SetReminder(RRT.ActivePersonalReminder, true, true) -- loading active personal reminder from last session
        self:ProcessReminder()
        if self.Reminder == "" then -- if user doesn't have their own active Reminder, load shared one from last session. This should cover disconnects/relogs
            self.Reminder = RRT.StoredSharedReminder or ""
        end
        self:UpdateReminderFrame(true)
        if RRT.Settings["Debug"] then
            print("|cFFBB66FFRRT|r Debug mode is currently enabled. Please disable it with '/rvr debug' unless you are specifically testing something.")
        end
        if self:Restricted() then return end
        if RRT.Settings["MyNickName"] then self:SendNickName("Any") end -- only send nickname if it exists
        if RRT.Settings["GlobalNickNames"] then -- add own nickname if not already in database (for new characters)
            local name, realm = UnitName("player")
            if not realm then realm = GetNormalizedRealmName() end
            if (not RRT.NickNames[name.."-"..realm]) or (RRT.Settings["MyNickName"] ~= RRT.NickNames[name.."-"..realm]) then
                self:NewNickName("player", RRT.Settings["MyNickName"], name, realm)
            end
        end
    elseif e == "PLAYER_ENTERING_WORLD" then
        local IsLogin, IsReload = ...
        C_Timer.After(0.01, function()
            local diff = select(3, GetInstanceInfo()) or 0
            local ForceHide = diff > 17 or diff < 14
            if ForceHide then self:HideAllReminders(true) end
            self:UpdateNoteFrame("ReminderFrame", RRT.ReminderSettings.ReminderFrame, "skip")
            self:UpdateNoteFrame("PersonalReminderFrame", RRT.ReminderSettings.PersonalReminderFrame, "skip")
            self:UpdateNoteFrame("ExtraReminderFrame", RRT.ReminderSettings.ExtraReminderFrame, "skip")
            if RRT.PARaidSettings.enabled and not (IsLogin or IsReload) then
                if self.InitRaidPATimer then self.InitRaidPATimer:Cancel() end
                self.InitRaidPATimer = C_Timer.After(5, function() self.InitRaidPATimer = nil; self:InitRaidPA(not UnitInRaid("player"), true) end)
            end
        end)
        -- Auto-detect zone and load the matching raid profile
        local s = RRT.Settings and RRT.Settings.RaidFrame
        if s and s.raidZoneIDs then
            local instanceMapID = select(8, GetInstanceInfo())
            if instanceMapID and instanceMapID ~= 0 then
                local matchKey = s.raidZoneIDs[instanceMapID]
                if matchKey and s.debuffProfiles and s.debuffProfiles[matchKey] then
                    s.activeRaid = matchKey
                    s.activeBoss = ""
                    if RRT_NS.RaidFrame and RRT_NS.RaidFrame.frame then
                        RRT_NS.RaidFrame._needsPARebuild = true
                        if RRT_NS.RaidFrame.frame:IsShown() then
                            RRT_NS.RaidFrame:RequestRefresh()
                        end
                    end
                end
            end
        end
    elseif e == "ENCOUNTER_START" and wowevent then -- allow sending fake encounter_start if in debug mode, only send spec info in mythic, heroic and normal raids
        local diff = select(3, GetInstanceInfo()) or 0
        if RRT.PATankSettings.enabled and diff <= 17 and diff >= 14 and UnitGroupRolesAssigned("player") == "TANK" then -- enabled in lfr, normal, heroic, mythic
            self:InitTankPA()
        end
        if (diff < 14 or diff > 17) and diff ~= 220 and not RRT.Settings["Debug"] then return end -- everything else is enabled in lfr, normal, heroic, mythic and story mode because people like to test in there.
        self.RRTFrame.generic_display:Hide()
        if RRT.PARaidSettings.enabled then self:InitRaidPA(false) end
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
        self.TLAlerts = {}
        if self.AddAssignments[self.EncounterID] then self.AddAssignments[self.EncounterID](self) end
        if self.EncounterAlertStart[self.EncounterID] then self.EncounterAlertStart[self.EncounterID](self) end
        self:ProcessCustomEncounterAlerts(self.EncounterID)
        self:StartReminders(self.Phase)
        self:FireCallback("RRT_ALERT_ADDED", self.TLAlerts)
    elseif e == "ENCOUNTER_END" and wowevent and self:DifficultyCheck(14) then
        local encID, encounterName = ...
        if self.EncounterAlertStop[encID] then self.EncounterAlertStop[encID](self) end
        if RRT.PATankSettings.enabled and UnitGroupRolesAssigned("player") == "TANK" then
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
            if RRT.ReminderSettings.AutoShare then
                tosend = self.Reminder
            end
            self:Broadcast("RRT_REM_SHARE", "RAID", tosend, RRT.AssignmentSettings, false)
            self.Assignments = RRT.AssignmentSettings
        end
    elseif e == "READY_CHECK" and wowevent then
        self.ProcessDone = false
        local diff= select(3, GetInstanceInfo()) or 0
        if self:DifficultyCheck(14) or diff == 23 then
            C_Timer.After(1, function()
                self:EventHandler("RRT_READY_CHECK", false, true)
            end)
        end
        if UnitIsGroupLeader("player") and UnitInRaid("player") then
            -- always doing this, even outside of raid to allow outside raidleading to work. The difficulty check will instead happen client-side
            local tosend = false
            if RRT.ReminderSettings.AutoShare then
                tosend = self.Reminder
            end
            self:Broadcast("RRT_REM_SHARE", "RAID", tosend, RRT.AssignmentSettings, false)
            self.Assignments = RRT.AssignmentSettings
        end
        -- broadcast spec info
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        self:Broadcast("RRT_SPEC", "RAID", specid)
        if C_ChatInfo.InChatMessagingLockdown() then return end
        self.LastBroadcast = GetTime()
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
        if RRT.Settings["CheckCooldowns"] and self:DifficultyCheck(15) and UnitInRaid("player") then -- only heroic& mythic because in normal you just wanna go fast and don't care about someone having a cd
            self:CheckCooldowns()
        end
    elseif e == "RRT_REM_SHARE"  and internal then
        local unit, reminderstring, assigntable, skipcheck = ...
        if (UnitIsGroupLeader(unit) or (UnitIsGroupAssistant(unit) and skipcheck)) and (self:DifficultyCheck(14) or skipcheck) then -- skipcheck allows manually sent reminders to bypass difficulty checks
            if (RRT.ReminderSettings.enabled or self:IsUsingTLReminders()) and reminderstring and type(reminderstring) == "string" and reminderstring ~= "" then
                RRT.StoredSharedReminder = self.Reminder -- store in SV to reload on next login
                self.Reminder = reminderstring
                self:FireCallback("RRT_REMINDER_CHANGED", self.PersonalReminder, self.Reminder)
            end
            self:ProcessReminder()
            self:UpdateReminderFrame(true)
            self.ProcessDone = true
            if skipcheck then self:FlashNoteBackgrounds() end -- only show animation if reminder was manually shared
            if assigntable then self.Assignments = assigntable end
        end
    elseif e == "RRT_READY_CHECK" and internal then
        if not self.ProcessDone then -- fallback do this here if no addon comms were received because the setting is disabled
            self:ProcessReminder()
            self:UpdateReminderFrame(true)
        end
        local text = ""
        if UnitLevel("player") < 90 then return end
        if RRT.ReadyCheckSettings.RaidBuffCheck and not self:Restricted() then
            local buff = self:BuffCheck()
            if buff and buff ~= "" then text = buff end
        end
        if RRT.ReadyCheckSettings.SoulstoneCheck and not self:Restricted() then
            local Soulstone = self:SoulstoneCheck()
            if Soulstone and Soulstone ~= "" then
                if text == "" then
                    text = Soulstone
                else
                    text = text.."\n"..Soulstone
                end
            end
        end
        local Gear = self:GearCheck()
        if Gear and Gear ~= "" then
            if text == "" then
                text = Gear
            else
                text = text.."\n"..Gear
            end
        end
        if text ~= "" then
            self:DisplayText(text)
        end
    elseif e == "RRIN_REQUEST" and internal then
        -- Another RRT client is requesting inspect data — broadcast own data
        if RRT_NS.BroadcastRaidInspectData then
            RRT_NS:BroadcastRaidInspectData()
        end
    elseif e == "RRIN_DATA" and internal then
        -- Incoming inspect data from a raid member
        if RRT_NS.HandleRaidInspectData then
            local data = ...
            RRT_NS:HandleRaidInspectData(data)
        end
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
    elseif e == "GROUP_FORMED" and wowevent then
        if self:Restricted() then return end
        if RRT.Settings["MyNickName"] then self:SendNickName("Any", true) end -- only send nickname if it exists
    elseif e == "GROUP_ROSTER_UPDATE" and wowevent then
        self:ArrangeGroups()
        if RRT.PARaidSettings.enabled then
            if self.InitRaidPATimer then self.InitRaidPATimer:Cancel() end
            self.InitRaidPATimer = C_Timer.After(5, function() self.InitRaidPATimer = nil; self:InitRaidPA(not UnitInRaid("player"), true) end)
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

        if RRT.Settings.RaidFrame and RRT.Settings.RaidFrame.enabled and RRT_NS.RaidFrame then
            RRT_NS.RaidFrame:RequestRefresh()
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
    elseif e == "QoL_Comms" and internal then
        self:QoLEvents(e, ...)
    elseif e == "UNIT_AURA" and wowevent then
        local unit = ...
        if RRT.Settings.RaidFrame and RRT.Settings.RaidFrame.enabled and RRT_NS.RaidFrame then
            local u = unit or ""
            if u == "player" or u:sub(1,4) == "raid" or u:sub(1,5) == "party" then
                RRT_NS.RaidFrame:RequestRefresh()
            end
        end
    elseif e == "PLAYER_REGEN_ENABLED" and wowevent then
        -- Rebuild PA anchors deferred from combat (RemovePrivateAuraAnchor is blocked in combat)
        local RF = RRT_NS.RaidFrame
        if RF and RF._pendingPARebuild then
            RF._pendingPARebuild = nil
            RF._needsPARebuild   = true
            if RF.frame and RF.frame:IsShown() then
                RF:RequestRefresh()
            end
        end
        C_Timer.After(1, function()
            if self:Restricted() then return end
            if self.SyncNickNamesStore then
                self:EventHandler("RRT_NICKNAMES_SYNC", false, true, self.SyncNickNamesStore.unit, self.SyncNickNamesStore.nicknametable, self.SyncNickNamesStore.channel)
                self.SyncNickNamesStore = nil
            end
        end)
    elseif e == "RRT_NICKNAMES_COMMS" and internal then
        if self:Restricted() then return end
        local unit, nickname, name, realm, requestback, channel = ...
        if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't add yourself
        if requestback and (UnitInRaid(unit) or UnitInParty(unit)) then self:SendNickName(channel, false) end -- send back if requested
        self:NewNickName(unit, nickname, name, realm, channel)
    elseif e == "RRT_NICKNAMES_SYNC" and internal then
        local unit, nicknametable, channel = ...
        local setting = RRT.Settings["NickNamesSyncAccept"]
        if (setting == 3 or (setting == 2 and channel == "GUILD") or (setting == 1 and channel == "RAID")) and (not C_ChallengeMode.IsChallengeModeActive()) then
            if UnitExists(unit) and UnitIsUnit("player", unit) then return end -- don't accept from yourself
            if self:Restricted() or UnitAffectingCombat("player") then
                self.SyncNickNamesStore = {unit = unit, nicknametable = nicknametable, channel = channel}
            else
                self:NickNamesSyncPopup(unit, nicknametable)
            end
        end
    end
end