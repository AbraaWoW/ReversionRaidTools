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

-- C_LFGList.UpdateListing() is protected in Midnight 12.x and cannot be called
-- from addon code. Instead we trigger the dropdown's own selection callback so
-- Blizzard's code sets generalPlaystyle and handles the rest.
local function ApplyPlaystyle(entryCreation)
    if not entryCreation then return end
    local ps = db().playstyle
    if not ps or ps < 1 or ps > 4 then return end

    local dropdown = entryCreation.PlayStyleDropdown
    if not dropdown then return end

    -- Try to select via the dropdown's own API so Blizzard's callback fires
    -- and sets generalPlaystyle through protected code (no addon taint).
    if dropdown.SetValue then
        dropdown:SetValue(ps)
    elseif dropdown.SetSelectedValue then
        dropdown:SetSelectedValue(ps)
    elseif dropdown.SetText then
        -- Last resort: visual only (user must re-pick to get it saved)
        local text = (_G[PLAYSTYLE_GLOBALS[ps]]) or PLAYSTYLE_NAMES[ps]
        if text then dropdown:SetText(text) end
    end
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
