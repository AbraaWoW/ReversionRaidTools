local _, RRT_NS = ... -- Internal namespace

local encID = 3178
-- /run RRTAPI:DebugEncounter(3178)
RRT_NS.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if (not self:DifficultyCheck(16)) then
        if not self.VaelgorPhaseFrame then
            self.VaelgorPhaseFrame = CreateFrame("Frame", nil, RRT_NS.RRTFrame, "BackdropTemplate")
            self.VaelgorPhaseFrame:SetScript("OnEvent", function(_, e, u)
                if e == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" and self.Phase and self.Phase == 1 and UnitExists("boss3") then
                    self.Phase = 2
                    self:StartReminders(self.Phase)
                end
            end)
        end
        self.VaelgorPhaseFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        if not RRT.EncounterAlerts[encID] then
            RRT.EncounterAlerts[encID] = {enabled = false}
        end
    end
    if RRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Breath", "Bar", 1244221, 4, 1, encID)
        -- same timer on all difficultes for now, timers behaved a bit weirdly on beta
        id = id or self:DifficultyCheck(14) or 0
        local timers = {
            [0] = {},
            [14] = {17.3, 51.3, 86.3, 174.3, 220.2},
            [15] = {17.3, 51.3, 86.3, 174.3, 220.2},
            [16] = {17.3, 51.3, 86.3, 174.3, 220.2},
        }
        for _, time in ipairs(timers[id] or {}) do
            Alert.time = time
            self:AddToReminder(Alert)
        end
    end
    if RRT.EncounterAlerts[encID].HealthDisplay then
        -- Dedicated background frame anchored behind the text.
        -- Medium-dark grey (0.38) is the optimal choice: dark enough to feel "foncé",
        -- yet light enough for both black (Vaelgor) and white (Ezzorak) text to be readable.
        if not self.VaelgorHealthBG then
            self.VaelgorHealthBG = CreateFrame("Frame", nil, RRT_NS.RRTFrame, "BackdropTemplate")
            self.VaelgorHealthBG:SetFrameStrata("BACKGROUND")
            self.VaelgorHealthBG:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
                insets   = {left = 5, right = 5, top = 3, bottom = 3},
            })
            self.VaelgorHealthBG:SetBackdropColor(0.50, 0.50, 0.50, 0.95)
            self.VaelgorHealthBG:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)
        end
        local fs = RRT.Settings.GlobalEncounterFontSize or 16
        self.VaelgorHealthBG:SetSize(fs * 12, fs * 2 + 14)
        self.VaelgorHealthBG:ClearAllPoints()
        self.VaelgorHealthBG:SetPoint("TOPLEFT", RRT_NS.RRTFrame.generic_display, "TOPLEFT", -6, 6)
        self.VaelgorHealthBG:Show()

        if not self.VaelgorEzzorakFrame then
            self.VaelgorEzzorakFrame = CreateFrame("Frame", nil, RRT_NS.RRTFrame, "BackdropTemplate")
            self.VaelgorEzzorakFrame:SetScript("OnEvent", function(_, e, u)
                if e == "UNIT_HEALTH" then
                    local health1 = C_StringUtil.RoundToNearestString(UnitHealthPercent("boss1", true, CurveConstants.ScaleTo100)) or "0"
                    local health2 = C_StringUtil.RoundToNearestString(UnitHealthPercent("boss2", true, CurveConstants.ScaleTo100)) or "0"
                    self:DisplaySecretText(
                        "|cFF000000Drake Noir %s%%|r\n|cFFFFFFFFDrake Blanc %s%%|r",
                        false, {health1, health2})
                end
            end)
        end
        self:DisplaySecretText(
            "|cFF000000Drake Noir %s%%|r\n|cFFFFFFFFDrake Blanc %s%%|r",
            false, {"100", "100"})
        self.VaelgorEzzorakFrame:RegisterUnitEvent("UNIT_HEALTH", "boss1", "boss2")
        self.VaelgorEzzorakFrame:Show()
    end
end

RRT_NS.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if RRT.EncounterAlerts[encID].HealthDisplay then
        if self.VaelgorEzzorakFrame then self.VaelgorEzzorakFrame:UnregisterEvent("UNIT_HEALTH") end
        self.VaelgorEzzorakFrame:Hide()
        if self.VaelgorHealthBG then self.VaelgorHealthBG:Hide() end
        self:DisplaySecretText(false, true)
    end
    if self.VaelgorPhaseFrame then
        self.VaelgorPhaseFrame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end
end

RRT_NS.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if (not (id and id == 16)) and not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player") or 0
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID, true) -- text, Type, spellID, dur, phase, encID
    -- Assigning Group 1&2 on first soak, Group 3&4 on second soak. This is overkill as only 7 people are required but not sure how the strat is gonna be yet
    local Soak = self:CreateDefaultAlert(subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK", nil, nil, 10, 1, encID)
    Alert.time, Alert.text, Alert.TTSTimer = 54.4, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK", 4
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 156.1, subgroup >= 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 201.2, subgroup <= 2 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)
    Alert.time, Alert.text = 246.1, subgroup >= 3 and "|cFF00FF00SOAK" or "|cFFFF0000DON'T SOAK"
    self:AddToReminder(Alert)


    if RRT.AssignmentSettings.OnPull then
        local group = subgroup <= 2 and "First" or "Second"
        self:DisplayText("You are assigned to soak |cFF00FF00Gloom|r in the |cFF00FF00"..group.."|r Group", 5)
    end
end