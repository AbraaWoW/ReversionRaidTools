local _, RRT = ... -- Internal namespace

local encID = 3176
-- /run RRTAPI:DebugEncounter(3176)
RRT.EncounterAlertStart[encID] = function(self) -- on ENCOUNTER_START
    if not RRTDB.EncounterAlerts[encID] then
        RRTDB.EncounterAlerts[encID] = {enabled = false}
    end
    if RRTDB.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Soak", "Text", nil, 5.5, 1, encID) -- Group Soaks

        local id = self:DifficultyCheck(14) or 0
        local timers = {
            [0] = {},
            [16] = {37.5, 45, 117.5, 125, 223.5, 231, 303.5, 311, 407.5, 415}, -- Mythic only for now
        }
        for i, v in ipairs(timers[id]) do
            Alert.time = v
            self:AddToReminder(Alert)
        end

    end
end

