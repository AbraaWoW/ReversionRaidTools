local _, RRT = ... -- Internal namespace
_G["RRTAPI"] = _G["RRTAPI"] or {}

-- Namespace bridge: BuffReminders runtime modules attach to addon namespace (RRT).
-- Keep RRT.BuffReminders as an alias so integrated UI modules can use either path.
RRT.BuffReminders = RRT
RRT.specs = {}
RRT.LCG = LibStub("LibCustomGlow-1.0")
RRT.LGF = LibStub("LibGetFrame-1.0")
RRT.RRTFrame = CreateFrame("Frame", nil, UIParent)
RRT.RRTFrame:SetAllPoints(UIParent)
RRT.RRTFrame:SetFrameStrata("BACKGROUND")

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

function RRT:InitLDB()
    if LDB then
        local databroker = LDB:NewDataObject("RRT", {
            type = "launcher",
            label = "Reversion Raid Tools",
            icon = [[Interface\Icons\Ability_Evoker_Reversion2]],
            showInCompartment = true,
            OnClick = function(self, button)
                if button == "LeftButton" then
                    RRT.RRTUI:ToggleOptions()
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Reversion Raid Tools", 0, 1, 1)
                tooltip:AddLine("|cFFCFCFCFLeft click|r: Show/Hide Options Window")
            end
        })

        if (databroker and not LDBIcon:IsRegistered("RRT")) then
            LDBIcon:Register("RRT", databroker, RRTDB.Settings["Minimap"])
            LDBIcon:AddButtonToCompartment("RRT")
        end

        self.databroker = databroker
    end
end


RRT.EncounterAlertStart = {}
RRT.EncounterAlertStop = {}
RRT.ShowWarningAlert = {}
RRT.ShowBossWhisperAlert = {}
RRT.AddAssignments = {}
RRT.DetectPhaseChange = {}









