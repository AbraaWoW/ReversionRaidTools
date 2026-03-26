local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Auto Playstyle
-- Automatically applies the saved playstyle when creating a Mythic+ group
-- listing in the LFG Group Finder.
-- ─────────────────────────────────────────────────────────────────────────────

local module = {}

module.DEFAULTS = {
    enabled   = true,
    playstyle = 3, -- Competitive (Fun/Serious)
}

-- Fallback names when global strings are not yet loaded
local PLAYSTYLE_NAMES = {
    [1] = "Learning",
    [2] = "Relaxed",
    [3] = "Competitive",
    [4] = "Carry Offered",
}

local PLAYSTYLE_GLOBALS = {
    "GROUP_FINDER_GENERAL_PLAYSTYLE1",
    "GROUP_FINDER_GENERAL_PLAYSTYLE2",
    "GROUP_FINDER_GENERAL_PLAYSTYLE3",
    "GROUP_FINDER_GENERAL_PLAYSTYLE4",
}

local function db()
    return RRT and RRT.AutoPlaystyle or {}
end

local function IsEnabled()
    return db().enabled
end

function module:GetPlaystyleName(idx)
    if idx and PLAYSTYLE_GLOBALS[idx] and _G[PLAYSTYLE_GLOBALS[idx]] then
        return _G[PLAYSTYLE_GLOBALS[idx]]
    end
    return PLAYSTYLE_NAMES[idx] or ("Style " .. tostring(idx))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Core logic
-- ─────────────────────────────────────────────────────────────────────────────

-- Pending playstyle to apply once an active listing exists.
local _pendingPlaystyle = nil

-- Called by LFG_LIST_ACTIVE_ENTRY_UPDATE: once a listing is live, push the
-- saved playstyle via C_LFGList.UpdateListing (C-level, no taint).
local function OnActiveEntryUpdate()
    if not _pendingPlaystyle then return end
    local pending = _pendingPlaystyle
    _pendingPlaystyle = nil
    local entryInfo = C_LFGList.GetActiveEntryInfo and C_LFGList.GetActiveEntryInfo()
    if not entryInfo then return end
    entryInfo.playstyleID = pending
    C_LFGList.UpdateListing(entryInfo)
end

local function ApplyPlaystyle(entryCreation)
    if not entryCreation then return end
    local ps = db().playstyle
    if not ps or ps < 1 or ps > 4 then return end

    -- Visual: pre-fill the dropdown text so the user sees the correct value.
    -- We must NOT write entryCreation.generalPlaystyle directly — that taints the
    -- field, and Blizzard's code reading it to call SetEntryTitle() (now protected
    -- in Midnight 12.x) causes ADDON_ACTION_BLOCKED.
    local dropdown = entryCreation.PlayStyleDropdown
    if dropdown and dropdown.SetText then
        local text = (_G[PLAYSTYLE_GLOBALS[ps]]) or PLAYSTYLE_NAMES[ps]
        if text then dropdown:SetText(text) end
    end

    -- Queue a listing update: applied once the listing is actually created
    -- (LFG_LIST_ACTIVE_ENTRY_UPDATE fires), via C_LFGList.UpdateListing which
    -- is a C-level API and does not propagate addon taint.
    _pendingPlaystyle = ps
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Hooks (installed once; guard with IsEnabled() inside)
-- ─────────────────────────────────────────────────────────────────────────────

local _hooked = false

local function InstallHooks()
    if _hooked then return end
    _hooked = true

    hooksecurefunc("LFGListEntryCreation_Show", function(entryCreation)
        if not IsEnabled() then return end
        ApplyPlaystyle(entryCreation)
    end)

    hooksecurefunc("LFGListEntryCreation_Select", function(entryCreation, filters, categoryID, groupID, activityID)
        if not IsEnabled() then return end
        if not activityID then return end
        local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
        if not activityInfo or not activityInfo.isMythicPlusActivity then return end
        ApplyPlaystyle(entryCreation)
    end)

    -- Apply queued playstyle once the listing is live (creation submitted).
    local entryUpdateFrame = CreateFrame("Frame", "RRTAutoPlaystyleEntryFrame")
    entryUpdateFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
    entryUpdateFrame:SetScript("OnEvent", function()
        if IsEnabled() then OnActiveEntryUpdate() end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Lifecycle
-- ─────────────────────────────────────────────────────────────────────────────

local _addonLoadedFrame = nil

function module:Enable()
    -- Blizzard_GroupFinder is demand-loaded; install hooks when it's ready
    if type(LFGListEntryCreation_Show) == "function" then
        InstallHooks()
    else
        if not _addonLoadedFrame then
            _addonLoadedFrame = CreateFrame("Frame", "RRTAutoPlaystyleFrame")
            _addonLoadedFrame:RegisterEvent("ADDON_LOADED")
            _addonLoadedFrame:SetScript("OnEvent", function(self, event, name)
                if name == "Blizzard_GroupFinder" then
                    InstallHooks()
                    self:UnregisterEvent("ADDON_LOADED")
                end
            end)
        end
    end
end

-- Export
RRT_NS.AutoPlaystyle = module
