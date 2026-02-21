local _, RRT = ... -- Internal namespace

local encID = 3463
-- /run RRTAPI:DebugEncounter(3463)
RRT.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    if not RRTDB.EncounterAlerts[encID] then
        RRTDB.EncounterAlerts[encID] = {enabled = false}
    end
    if RRTDB.EncounterAlerts[encID].enabled or encID == 3463 then -- text, Type, spellID, dur, phase, encID
        --[[
        local Soak = self:CreateDefaultAlert("Soak", "Bar", 1241291, 8, 1, encID)
        Soak.time = 10
        self:AddToReminder(Soak)
        ]]
    end
end

RRT.ShowWarningAlert[encID] = function(self, encID, phase, time, info) -- on ENCOUNTER_WARNING
    if RRTDB.EncounterAlerts[encID].enabled then
        local severity, dur = info.severity, info.duration
        if severity == 0 then
        elseif severity == 1 then
        elseif severity == 2 then
        end
        --[[ Example
        local Fixate = self:CreateDefaultAlert("Fixate", "Icon", 210099, 15) -- text, type, spellID; dur
        Fixate.skipdur = true
        self:DisplayReminder(Fixate)
        ]]
    end
end

RRT.ShowBossWhisperAlert[encID] = function(self, encID, phase, time, text, name, dur) -- on RAID_BOSS_WHISPER
    if RRTDB.EncounterAlerts[encID].enabled then

    end
end

RRT.AddAssignments[encID] = function(self) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID) -- text, Type, spellID, dur, phase, encID
end


local detectedDurations = {
    [16] = {
        {time = 31, phase = function(num) return 3 end},
        {time = 33, phase = function(num) return 1 end},
        {time = 34.5, phase = function(num) return 2 end},
    },
}

RRT.DetectPhaseChange[encID] = function(self, e, info)
    local now = GetTime()
    -- not checking REMOVED event by default but may be needed for some encounters
    if e == "ENCOUNTER_TIMELINE_EVENT_REMOVED" or (not info) or (not self.PhaseSwapTime) or (not (now > self.PhaseSwapTime+5)) or (not self.EncounterID) or (not self.Phase) then return end
    local difficultyID = 16 -- bypass for debug
    if not difficultyID or not detectedDurations[difficultyID] then return end
    for _, phaseinfo in ipairs(detectedDurations[difficultyID]) do
        print("Checking duration:", info.duration, "against", phaseinfo.time)
        if info.duration == phaseinfo.time then
            local newphase = phaseinfo.phase(self.Phase)
            print("Changing to phase:", newphase, "from", self.Phase)
            if newphase > self.Phase then
                self.Phase = newphase
                self:StartReminders(self.Phase)
                self.PhaseSwapTime = now
                break
            end
        end
    end
end

RRT.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if RRTDB.EncounterAlerts[encID].enabled then
    end
end

