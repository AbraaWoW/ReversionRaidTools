local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Faster Loot
-- ─────────────────────────────────────────────────────────────────────────────

local _fasterLootFrame     = nil
local _inventoryFullWarned = false

local function FasterLoot_Enable()
    if _fasterLootFrame then return end
    _fasterLootFrame = CreateFrame("Frame")
    _fasterLootFrame:RegisterEvent("LOOT_READY")
    _fasterLootFrame:RegisterEvent("UI_ERROR_MESSAGE")
    _fasterLootFrame:SetScript("OnEvent", function(_, event, _, message)
        if event == "LOOT_READY" then
            if not RRT.QoL.FasterLoot then return end
            _inventoryFullWarned = false
            local numItems = GetNumLootItems()
            if numItems == 0 then return end
            for i = numItems, 1, -1 do LootSlot(i) end

        elseif event == "UI_ERROR_MESSAGE" then
            if not RRT.QoL.FasterLoot or _inventoryFullWarned then return end
            if message == ERR_INV_FULL then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Inventory is full — some items were not looted.")
                _inventoryFullWarned = true
            end
        end
    end)
end

local function FasterLoot_Disable()
    if not _fasterLootFrame then return end
    _fasterLootFrame:UnregisterAllEvents()
    _fasterLootFrame = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Skip Cinematics
-- ─────────────────────────────────────────────────────────────────────────────

local _cinematicsFrame = nil

local function SkipCinematics_Enable()
    if _cinematicsFrame then return end
    _cinematicsFrame = CreateFrame("Frame")
    _cinematicsFrame:RegisterEvent("PLAY_MOVIE")
    _cinematicsFrame:RegisterEvent("CINEMATIC_START")
    _cinematicsFrame:SetScript("OnEvent", function(_, event)
        if not RRT.QoL.SkipCinematics then return end

        if event == "PLAY_MOVIE" then
            MovieFrame:StopMovie()
            if RRT.QoL.SkipCinematicsMessage then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Cinematic skipped.")
            end

        elseif event == "CINEMATIC_START" then
            if CinematicFrame_CancelCinematic then
                CinematicFrame_CancelCinematic()
            elseif StopCinematic then
                StopCinematic()
            end
            C_Timer.After(0.1, function()
                if IsInCinematicScene and IsInCinematicScene()
                    and CanCancelScene and CanCancelScene() then
                    CancelScene()
                end
            end)
            if RRT.QoL.SkipCinematicsMessage then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Cinematic skipped.")
            end
        end
    end)
end

local function SkipCinematics_Disable()
    if not _cinematicsFrame then return end
    _cinematicsFrame:UnregisterAllEvents()
    _cinematicsFrame = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Auto Quest
-- ─────────────────────────────────────────────────────────────────────────────

local EXCLUDED_INSTANCE_MAPS = { [2513] = true }
local BLOCKED_NPC_IDS        = { [256203] = true }  -- Lady Liadrin (weekly)

local _pendingActions = {}
local _combatFrame    = nil

local function AQ_SetupCombatFrame()
    if _combatFrame then return end
    _combatFrame = CreateFrame("Frame")
    _combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    _combatFrame:SetScript("OnEvent", function()
        for _, action in ipairs(_pendingActions) do
            pcall(action.func, unpack(action.args or {}))
        end
        wipe(_pendingActions)
    end)
end

local function SafeCall(func, ...)
    if InCombatLockdown() then
        table.insert(_pendingActions, { func = func, args = {...} })
        return false
    end
    return pcall(func, ...)
end

local function IsExcludedMap()
    local instanceID = select(8, GetInstanceInfo())
    return instanceID and EXCLUDED_INSTANCE_MAPS[instanceID] or false
end

local function IsNPCBlocked()
    for _, unit in ipairs({"npc", "target"}) do
        if UnitExists(unit) and not UnitIsPlayer(unit) then
            local guid = UnitGUID(unit)
            if guid then
                local npcID = select(6, strsplit("-", guid))
                if npcID and BLOCKED_NPC_IDS[tonumber(npcID)] then return true end
            end
        end
    end
    return false
end

local function AQ_IsQuestReadyForTurnIn(questID)
    if not questID then return false end
    if C_QuestLog and C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questID) then return true end
    if C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) then return true end
    return false
end

local function AQ_IsQuestTrivial(questID)
    if not questID then return false end
    if C_QuestLog and C_QuestLog.IsQuestTrivial then return C_QuestLog.IsQuestTrivial(questID) end
    return false
end

local function AQ_db()
    if not RRT or not RRT.AutoQuest then return {} end
    return RRT.AutoQuest
end

local function AQ_OnGossipShow()
    local d = AQ_db()
    if not d.enabled then return end

    -- Turn in active quests
    if d.autoTurnIn and not IsNPCBlocked() and not IsExcludedMap() then
        if C_GossipInfo and C_GossipInfo.GetActiveQuests then
            for _, q in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
                if q and q.questID and (q.isComplete or AQ_IsQuestReadyForTurnIn(q.questID)) then
                    SafeCall(C_GossipInfo.SelectActiveQuest, q.questID)
                    return
                end
            end
        end
    end
    -- Accept available quests
    if d.autoAccept and not IsNPCBlocked() and not IsExcludedMap() then
        if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
            for _, q in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
                if q and q.questID then
                    if not (d.skipTrivialQuests and (q.isTrivial or AQ_IsQuestTrivial(q.questID))) then
                        SafeCall(C_GossipInfo.SelectAvailableQuest, q.questID)
                        return
                    end
                end
            end
        end
    end
    -- Auto-select single gossip option
    if d.autoSelectSingleGossip and not IsNPCBlocked() then
        local numAvail  = C_GossipInfo.GetNumAvailableQuests and C_GossipInfo.GetNumAvailableQuests() or 0
        local numActive = C_GossipInfo.GetNumActiveQuests  and C_GossipInfo.GetNumActiveQuests()  or 0
        if numAvail > 0 or numActive > 0 then return end
        local options = C_GossipInfo.GetOptions and C_GossipInfo.GetOptions()
        if options and #options == 1 and options[1].gossipOptionID then
            SafeCall(C_GossipInfo.SelectOption, options[1].gossipOptionID)
        end
    end
end

local function AQ_OnQuestGreeting()
    local d = AQ_db()
    if not d.enabled or IsExcludedMap() or IsNPCBlocked() then return end
    if d.autoTurnIn and GetNumActiveQuests and GetActiveTitle and SelectActiveQuest then
        for i = 1, (GetNumActiveQuests() or 0) do
            local questID = GetActiveQuestID and GetActiveQuestID(i)
            local _, _, _, isComplete = GetActiveTitle(i)
            if isComplete or AQ_IsQuestReadyForTurnIn(questID) then
                SafeCall(SelectActiveQuest, i); return
            end
        end
    end
    if d.autoAccept and GetNumAvailableQuests and SelectAvailableQuest then
        for i = 1, (GetNumAvailableQuests() or 0) do
            SafeCall(SelectAvailableQuest, i); return
        end
    end
end

local function AQ_OnQuestDetail()
    local d = AQ_db()
    if not d.enabled or not d.autoAccept or IsExcludedMap() or IsNPCBlocked() then return end
    local questID = GetQuestID and GetQuestID()
    if d.skipTrivialQuests and AQ_IsQuestTrivial(questID) then return end
    if QuestGetAutoAccept() or QuestIsFromAreaTrigger() then
        SafeCall(AcknowledgeAutoAcceptQuest)
    else
        SafeCall(AcceptQuest)
    end
end

local function AQ_OnQuestProgress()
    local d = AQ_db()
    if not d.enabled or not d.autoTurnIn or IsExcludedMap() or IsNPCBlocked() then return end
    local questID = GetQuestID and GetQuestID()
    if IsQuestCompletable() or AQ_IsQuestReadyForTurnIn(questID) then
        SafeCall(CompleteQuest)
    end
end

local function AQ_OnQuestComplete()
    local d = AQ_db()
    if not d.enabled or not d.autoTurnIn or IsExcludedMap() or IsNPCBlocked() then return end
    local numChoices = GetNumQuestChoices() or 0
    if numChoices == 0 then
        SafeCall(GetQuestReward, 1)
    elseif numChoices == 1 and d.autoSelectSingleReward then
        SafeCall(GetQuestReward, 1)
    end
end

local _questFrame = nil

local function AutoQuest_Enable()
    if _questFrame then return end
    AQ_SetupCombatFrame()
    _questFrame = CreateFrame("Frame")
    _questFrame:RegisterEvent("GOSSIP_SHOW")
    _questFrame:RegisterEvent("QUEST_GREETING")
    _questFrame:RegisterEvent("QUEST_DETAIL")
    _questFrame:RegisterEvent("QUEST_PROGRESS")
    _questFrame:RegisterEvent("QUEST_COMPLETE")
    _questFrame:SetScript("OnEvent", function(_, event)
        if event == "GOSSIP_SHOW"    then AQ_OnGossipShow()    end
        if event == "QUEST_GREETING" then AQ_OnQuestGreeting() end
        if event == "QUEST_DETAIL"   then AQ_OnQuestDetail()   end
        if event == "QUEST_PROGRESS" then AQ_OnQuestProgress() end
        if event == "QUEST_COMPLETE" then AQ_OnQuestComplete()  end
    end)
end

local function AutoQuest_Disable()
    if not _questFrame then return end
    _questFrame:UnregisterAllEvents()
    _questFrame = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────

local module = {}

module.DEFAULTS_AUTOQUEST = {
    enabled                = false,
    autoAccept             = true,
    autoTurnIn             = true,
    autoSelectSingleReward = true,
    autoSelectSingleGossip = true,
    skipTrivialQuests      = false,
}

function module:Enable()
    if RRT.QoL.FasterLoot     then FasterLoot_Enable()     end
    if RRT.QoL.SkipCinematics then SkipCinematics_Enable() end
    if RRT.AutoQuest and RRT.AutoQuest.enabled then AutoQuest_Enable() end
end

function module:EnableFasterLoot(v)
    if v then FasterLoot_Enable() else FasterLoot_Disable() end
end

function module:EnableSkipCinematics(v)
    if v then SkipCinematics_Enable() else SkipCinematics_Disable() end
end

function module:EnableAutoQuest(v)
    if v then AutoQuest_Enable() else AutoQuest_Disable() end
end

RRT_NS.Questing = module
