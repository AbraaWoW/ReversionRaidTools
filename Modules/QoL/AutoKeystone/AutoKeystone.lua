local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Auto Keystone
-- Automatically inserts the Mythic+ keystone into the receptacle when opened.
-- Hold Shift to suppress for one receptacle opening.
-- ─────────────────────────────────────────────────────────────────────────────

local module = {}

module.DEFAULTS = {
    enabled = true,
}

local KEYSTONE_ITEM_IDS = {
    [180653] = true, -- Mythic Keystone (Shadowlands+)
    [187786] = true,
    [158923] = true,
    [151086] = true,
}

local _frame = nil

local function IsEnabled()
    return RRT and RRT.AutoKeystone and RRT.AutoKeystone.enabled
end

local function SlotKeystone()
    if not IsEnabled() then return end
    if IsShiftKeyDown() then return end

    -- Already have an active challenge keystone slotted
    if C_ChallengeMode.GetActiveChallengeMapID() then return end

    C_Timer.After(0.1, function()
        for bag = 0, 4 do
            local numSlots = C_Container.GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID and KEYSTONE_ITEM_IDS[info.itemID] then
                    C_Container.PickupContainerItem(bag, slot)
                    if CursorHasItem() then
                        C_ChallengeMode.SlotKeystone()
                    end
                    return
                end
            end
        end
    end)
end

function module:Enable()
    if _frame then return end
    _frame = CreateFrame("Frame", "RRTAutoKeystoneFrame")
    _frame:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN")
    _frame:SetScript("OnEvent", function(_, event)
        if event == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" then
            SlotKeystone()
        end
    end)
end

-- Export
RRT_NS.AutoKeystone = module
