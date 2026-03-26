local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Auto Queue
-- Automates LFG queue actions:
--   • Auto-accept role check (CompleteLFGRoleCheck)
--   • One-click sign-up (skip the Sign Up button + role dialog)
-- Hold Shift to suppress any action.
--
-- NOTE: Auto-accept group invite (C_LFGList.AcceptInvite) is a protected
-- function in Midnight 12.x and cannot be called from addon code.
-- ─────────────────────────────────────────────────────────────────────────────

local module = {}

module.DEFAULTS = {
    enabled             = false,
    autoAcceptRoleCheck = true,
    oneClickSignUp      = false,
    announce            = true,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function db()
    return RRT and RRT.AutoQueue or {}
end

local function IsEnabled()
    return db().enabled
end

local function ShouldPause()
    return IsShiftKeyDown()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Role Check Auto-Accept
-- ─────────────────────────────────────────────────────────────────────────────

local _roleCheckFrame = nil

local function OnRoleCheckShow()
    if not IsEnabled() then return end
    if not db().autoAcceptRoleCheck then return end
    if ShouldPause() then return end

    CompleteLFGRoleCheck(true)
    if db().announce then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Auto Queue — role check accepted.")
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- One-Click Sign-Up
-- Step 1: clicking a search entry immediately triggers SignUp
-- ─────────────────────────────────────────────────────────────────────────────

local _entryClickHooked = false

local function OnSearchEntryClick(entry, button)
    if not IsEnabled() then return end
    if not db().oneClickSignUp then return end
    if ShouldPause() then return end
    if button == "RightButton" then return end

    local panel = LFGListFrame and LFGListFrame.SearchPanel
    if not panel or not panel.SignUpButton or not panel.SignUpButton:IsEnabled() then return end
    if LFGListSearchPanelUtil_CanSelectResult and not LFGListSearchPanelUtil_CanSelectResult(entry.resultID) then return end

    if panel.selectedResult ~= entry.resultID then
        LFGListSearchPanel_SelectResult(panel, entry.resultID)
    end
    LFGListSearchPanel_SignUp(panel)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- One-Click Sign-Up
-- Step 2: auto-confirm the role/note dialog
-- ─────────────────────────────────────────────────────────────────────────────

local _signUpHooked = false

local function OnApplicationDialogShow(dialog, resultID)
    if not IsEnabled() then return end
    if not db().oneClickSignUp then return end
    if ShouldPause() then return end

    -- Ensure at least one role is checked; fall back to first available
    local tankChecked   = dialog.TankButton:IsShown()    and dialog.TankButton.CheckButton:GetChecked()
    local healerChecked = dialog.HealerButton:IsShown()  and dialog.HealerButton.CheckButton:GetChecked()
    local dpsChecked    = dialog.DamagerButton:IsShown() and dialog.DamagerButton.CheckButton:GetChecked()

    if not tankChecked and not healerChecked and not dpsChecked then
        if     dialog.TankButton:IsShown()    then dialog.TankButton.CheckButton:SetChecked(true)
        elseif dialog.HealerButton:IsShown()  then dialog.HealerButton.CheckButton:SetChecked(true)
        elseif dialog.DamagerButton:IsShown() then dialog.DamagerButton.CheckButton:SetChecked(true)
        end
    end

    LFGListApplicationDialogSignUpButton_OnClick(dialog.SignUpButton)

    if db().announce then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Auto Queue — sign-up submitted.")
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Lifecycle
-- ─────────────────────────────────────────────────────────────────────────────

function module:Enable()
    -- Role check frame (registered unconditionally; handler guards enabled)
    if not _roleCheckFrame then
        _roleCheckFrame = CreateFrame("Frame", "RRTAutoQueueFrame")
        _roleCheckFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
        _roleCheckFrame:SetScript("OnEvent", function(_, event)
            if event == "LFG_ROLE_CHECK_SHOW" then
                OnRoleCheckShow()
            end
        end)
    end

    if not _entryClickHooked and LFGListSearchEntry_OnClick then
        hooksecurefunc("LFGListSearchEntry_OnClick", OnSearchEntryClick)
        _entryClickHooked = true
    end

    if not _signUpHooked and LFGListApplicationDialog_Show then
        hooksecurefunc("LFGListApplicationDialog_Show", OnApplicationDialogShow)
        _signUpHooked = true
    end
end

-- Export
RRT_NS.AutoQueue = module
