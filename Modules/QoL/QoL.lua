local _, RRT_NS = ... -- Internal namespace

-- ─────────────────────────────────────────────────────────────────────────────
-- Chat Filter
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULT_CHAT_FILTER_KEYWORDS = {
    "wts gold", "buy gold", "cheap gold",
    "wts boost", "wts carry", "wts run", "boost cheap", "carry cheap",
    "piloted", "selfplay", "powerleveling",
}

local _chatFilterFunc = nil

local function ChatFilterMsg(msg)
    if not RRT or not RRT.QoL or not RRT.QoL.ChatFilter then return false end
    if not msg then return false end
    local lowerMsg = msg:lower()
    local keywords = RRT.QoL.ChatFilterKeywords
    if not keywords then return false end
    for keyword, active in pairs(keywords) do
        if active and lowerMsg:find(keyword:lower(), 1, true) then return true end
    end
    return false
end

function RRT_NS:EnableChatFilter()
    if _chatFilterFunc then return end
    _chatFilterFunc = function(_, _, msg, ...)
        if ChatFilterMsg(msg) then return true end
        return false, msg, ...
    end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", _chatFilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", _chatFilterFunc)
    if RRT.QoL.ChatFilterLoginMessage then
        local count = 0
        for _, v in pairs(RRT.QoL.ChatFilterKeywords or {}) do if v then count = count + 1 end end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Chat Filter active — " .. count .. " keyword(s).")
    end
end

function RRT_NS:DisableChatFilter()
    if not _chatFilterFunc then return end
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", _chatFilterFunc)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", _chatFilterFunc)
    _chatFilterFunc = nil
end

function RRT_NS:RestoreChatFilterDefaults()
    if not RRT or not RRT.QoL then return end
    RRT.QoL.ChatFilterKeywords = {}
    for _, kw in ipairs(DEFAULT_CHAT_FILTER_KEYWORDS) do
        RRT.QoL.ChatFilterKeywords[kw] = true
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Delete Confirm
-- ─────────────────────────────────────────────────────────────────────────────
local _deleteConfirmHooked = false
local _deleteConfirmFrame  = nil

local function ApplyDeleteConfirm()
    for i = 1, _G.STATICPOPUP_NUMDIALOGS or 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() then
            local edit = _G["StaticPopup" .. i .. "EditBox"]
            local btn  = _G["StaticPopup" .. i .. "Button1"]
            if edit and edit:IsShown() then edit:SetText(""); edit:Hide() end
            if btn then btn:Enable() end
        end
    end
end

function RRT_NS:EnableDeleteConfirm()
    if _deleteConfirmHooked then return end
    _deleteConfirmHooked = true
    if not _deleteConfirmFrame then
        _deleteConfirmFrame = CreateFrame("Frame")
    end
    _deleteConfirmFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
    _deleteConfirmFrame:SetScript("OnEvent", function()
        C_Timer.After(0, ApplyDeleteConfirm)
    end)
end

function RRT_NS:DisableDeleteConfirm()
    if not _deleteConfirmHooked then return end
    _deleteConfirmHooked = false
    if _deleteConfirmFrame then
        _deleteConfirmFrame:UnregisterEvent("DELETE_ITEM_CONFIRM")
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Disable Auto Add Spells
-- ─────────────────────────────────────────────────────────────────────────────
local _autoAddFrame = nil
local _origIconIntroRegisterEvent = nil

function RRT_NS:EnableDisableAutoAddSpells()
    if _autoAddFrame then return end
    if IconIntroTracker then
        if not _origIconIntroRegisterEvent then
            _origIconIntroRegisterEvent = IconIntroTracker.RegisterEvent
        end
        IconIntroTracker.RegisterEvent = function() end
        IconIntroTracker:UnregisterEvent("SPELL_PUSHED_TO_ACTIONBAR")
    end
    _autoAddFrame = CreateFrame("Frame")
    _autoAddFrame:RegisterEvent("SPELL_PUSHED_TO_ACTIONBAR")
    _autoAddFrame:SetScript("OnEvent", function(_, _, _, _, slotIndex)
        if InCombatLockdown() then return end
        ClearCursor()
        if slotIndex then PickupAction(slotIndex) end
        ClearCursor()
    end)
end

function RRT_NS:DisableDisableAutoAddSpells()
    if not _autoAddFrame then return end
    _autoAddFrame:UnregisterEvent("SPELL_PUSHED_TO_ACTIONBAR")
    _autoAddFrame = nil
    if IconIntroTracker and _origIconIntroRegisterEvent then
        IconIntroTracker.RegisterEvent = _origIconIntroRegisterEvent
        IconIntroTracker:RegisterEvent("SPELL_PUSHED_TO_ACTIONBAR")
        _origIconIntroRegisterEvent = nil
    end
end

-- ─────────────────────────────────────────────────────────────────────────────

local f = CreateFrame("Frame")

f:SetScript("OnEvent", function(self, e, ...)
    RRT_NS:QoLEvents(e, ...)
end)

local GatewayIcon = "\124T"..C_Spell.GetSpellTexture(111771)..":12:12:0:0:64:64:4:60:4:60\124t"
local ResetBossIcon = "\124T"..C_Spell.GetSpellTexture(57724)..":12:12:0:0:64:64:4:60:4:60\124t"
local CrestIcon = "\124T"..C_CurrencyInfo.GetCurrencyInfo(3347).iconFileID..":12:12:0:0:64:64:4:60:4:60\124t"
local FeastIcon = "\124T"..C_Spell.GetSpellTexture(19705)..":12:12:0:0:64:64:4:60:4:60\124t"
local CauldronIcon = "\124T"..C_Spell.GetSpellTexture(448001)..":12:12:0:0:64:64:4:60:4:60\124t"
local SoulwellIcon = "\124T"..C_Spell.GetSpellTexture(6262)..":12:12:0:0:64:64:4:60:4:60\124t"
local RepairIcon = "\124T"..C_Spell.GetSpellTexture(126462)..":12:12:0:0:64:64:4:60:4:60\124t"
local TextDisplays = {
    Gateway = GatewayIcon.."Gateway Useable"..GatewayIcon,
    ResetBoss = ResetBossIcon.."Reset Boss"..ResetBossIcon,
    LootBoss = CrestIcon.."Loot Boss"..CrestIcon,
    SoulwellDropped = SoulwellIcon.."%s Dropped a Soulwell"..SoulwellIcon,
    FeastDropped = FeastIcon.."%s Dropped a Feast"..FeastIcon,
    RepairDropped = RepairIcon.."%s Dropped a Repair"..RepairIcon,
    CauldronDropped = CauldronIcon.."%s Dropped a Cauldron"..CauldronIcon,
}

local ConsumableSpells = {
    [1259657] = "FEAST", -- Quel'dorei Medley
    [1278915] = "FEAST", -- Hearty Quel'dorei Medley

    [1259658] = "FEAST", -- Harandar Celebration
    [1278929] = "FEAST", -- Hearty Rootland Celebration

    [1237104] = "FEAST", -- Blooming Feast
    [1278909] = "FEAST", -- Hearty Blooming Feast

    [1259659] = "FEAST", -- Silvermoon Parade
    [1278895] = "FEAST", -- Hearty Silvermoon Parade

    [1240267] = "CAULDRON", -- Voidlight Potion Cauldron
    [1240195] = "CAULDRON", -- Voidlight of Sin'dorei Flasks

    [29893] = "SOULWELL",

    [199109] = "REPAIR", -- Auto-Hammer
    [67826] = "REPAIR", -- Jeeves
}

local LustDebuffs = {
    57723, -- Exhaustion
    57724, -- Sated
    80354, -- Time Warp
    264689, -- Fatigued
    390435, -- Exhaustion
}
function RRT_NS:QoLEvents(e, ...)
    if self.IsBuilding then return end
    if e == "ACTIONBAR_UPDATE_USABLE" then -- only thing needed for Gateway
        if RRT.QoL.GatewayUseableDisplay and C_Item.IsUsableItem(188152) then
            self.QoLTextDisplays.Gateway = {SettingsName = "GatewayUseableDisplay", text = TextDisplays.Gateway}
        else
            self.QoLTextDisplays.Gateway = nil
        end
        self:UpdateQoLTextDisplay()
    elseif e == "ADDON_RESTRICTION_STATE_CHANGED" then
        if C_ChatInfo.InChatMessagingLockdown() then
            self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", false)
        else
            self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", true, "player")
        end
        if not RRT.QoL.ResetBossDisplay then -- shouldn't be possible but another safety check
            self.QoLTextDisplays.ResetBoss = nil
            self:UpdateQoLTextDisplay()
            self:ToggleQoLEvent("UNIT_AURA", false)
            return
        elseif self:Restricted() then
            self.QoLTextDisplays.ResetBoss = nil
            self:ToggleQoLEvent("UNIT_AURA", false)
        else
            local inRaid = self:DifficultyCheck(14)
            if not inRaid then return end
            self:ToggleQoLEvent("UNIT_AURA", inRaid, "player")
            local debuffed = self:HasLustDebuff()
            if debuffed then
                self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
            else
                self.QoLTextDisplays.ResetBoss = nil
            end
        end
        self:UpdateQoLTextDisplay()
    elseif e == "PLAYER_REGEN_DISABLED" and RRT.QoL.ResetBossDisplay then
        self.QoLTextDisplays.ResetBoss = nil
        self:UpdateQoLTextDisplay()
    elseif e == "PLAYER_REGEN_ENABLED" and RRT.QoL.ResetBossDisplay then
        if self:HasLustDebuff() then
            self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
        else
            self.QoLTextDisplays.ResetBoss = nil
        end
        self:UpdateQoLTextDisplay()
    elseif e == "UNIT_AURA" then
        if self:Restricted() then return end -- shouldn't happen because we unregister but just a safety check
        local unit, updateInfo = ...
        if RRT.QoL.ResetBossDisplay and unit == "player" then
            if updateInfo.isFullUpdate then
                local debuff = self:HasLustDebuff()
                if debuff then
                    self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                else
                    self.QoLTextDisplays.ResetBoss = nil
                end
                self:UpdateQoLTextDisplay()
            elseif updateInfo.addedAuras then
                for _, auraData in ipairs(updateInfo.addedAuras) do
                    for _, spellID in ipairs(LustDebuffs) do
                        -- idk how this can ever be secret because I'm checking that at the very start but it can
                        if (not issecretvalue(auraData.spellId)) and auraData.spellId == spellID then
                            self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                            self:UpdateQoLTextDisplay()
                            return
                        end
                    end
                end
            elseif updateInfo.removedAuraInstanceIDs and self.QoLTextDisplays.ResetBoss then
                if self:HasLustDebuff() then
                    self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                else
                    self.QoLTextDisplays.ResetBoss = nil
                end
                self:UpdateQoLTextDisplay()
            end
        end
    elseif e == "ZONE_CHANGED_NEW_AREA" or e == "PLAYER_ENTERING_WORLD" then
        if self:DifficultyCheck(14) and RRT.QoL.ResetBossDisplay and not self:Restricted() then
            if self:HasLustDebuff() then
                self.QoLTextDisplays.ResetBoss = {SettingsName = "ResetBossDisplay", text = TextDisplays.ResetBoss}
                self:UpdateQoLTextDisplay()
            end
        end
        self:QoLOnZoneSwap()
    elseif e == "ENCOUNTER_END" and self:DifficultyCheck(14) then
        if RRT.QoL.LootBossReminder then
            local success = select(5, ...)
            if success == 1 then
                self.QoLTextDisplays.LootBoss = {SettingsName = "LootBossReminder", text = TextDisplays.LootBoss}
                self:UpdateQoLTextDisplay()
                self.LootReminderTimer = C_Timer.NewTimer(40, function() -- backup hide in case something goes wrong
                    if self.QoLTextDisplays.LootBoss then
                        self.QoLTextDisplays.LootBoss = nil
                        self:UpdateQoLTextDisplay()
                    end
                end)
            end
        end
    elseif e == "ENCOUNTER_START" and self:DifficultyCheck(14) then
        self.QoLTextDisplays = {}
        self:UpdateQoLTextDisplay()
    elseif self:DifficultyCheck(14) and (e == "LOOT_OPENED" or e == "CHAT_MSG_MONEY" or e == "ENCOUNTER_START") then
        if RRT.QoL.LootBossReminder and self.QoLTextDisplays.LootBoss then
            self.QoLTextDisplays.LootBoss = nil
            self:UpdateQoLTextDisplay()
        end
    elseif e == "MERCHANT_SHOW" and RRT.QoL.AutoRepair then
        RepairAllItems(CanGuildBankRepair())
    elseif (e == "CHAT_MSG_WHISPER" or e == "CHAT_MSG_BN_WHISPER") and RRT.QoL.AutoInvite then
        local msg, playerName = ...
        if issecretvalue(msg) or issecretvalue(playerName) then return end
        if msg == "inv" or msg == "invite" then
            if e == "CHAT_MSG_BN_WHISPER" then
                local bnSenderID = select(13, ...)
                for i = 1, BNGetNumFriends() do
                    local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                    if bnSenderID == accountInfo.bnetAccountID then
                        for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) do
                            local gameInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
                            if gameInfo then
                                local char = gameInfo.characterName
                                local realm = gameInfo.realmName
                                if char and realm then
                                    playerName = char.."-"..realm
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
            -- unfortunately have to check guild roster because C_GuildInfo.MemberExistsByName is a security risk as it can't check the realm
            for i=1, GetNumGuildMembers() do
                local name = GetGuildRosterInfo(i)
                if name == playerName then
                    C_PartyInfo.InviteUnit(playerName)
                    return
                end
            end
        end
    elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
        -- registered only for 'player' so we don't need a unitTarget check or a secret check
        local spellId = select(3, ...)
        if IsInGroup() and ConsumableSpells[spellId] then
            self:Broadcast("QoL_Comms", "RAID", ConsumableSpells[spellId])
        end
    elseif e == "QoL_Comms" then
        self:HandleQoLComm(...)
    end
end

local _spellIDTooltipHooked = false
function RRT_NS:InitSpellIDTooltip()
    if _spellIDTooltipHooked then return end
    _spellIDTooltipHooked = true

    if not (TooltipDataProcessor and Enum and Enum.TooltipDataType) then return end

    local function addSpellIDLine(tooltip, data)
        if not RRT.QoL.ShowSpellIDTooltip then return end
        if not data or not data.id then return end
        if issecretvalue(data.id) then return end
        if data.id ~= 0 then
            tooltip:AddLine("Spell ID: " .. data.id, 1, 0.85, 0)
            tooltip:Show()
        end
    end

    -- Spell tooltips: spellbook, action bars, spells in chat, etc.
    pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Spell, addSpellIDLine)
    -- Aura tooltips: buff/debuff icons on unit frames
    pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.UnitAura, addSpellIDLine)
end

function RRT_NS:InitQoL()
    self.QoLTextDisplays = {}
    self:InitSpellIDTooltip()
    -- stuff in here is ALWAYS enabled.
    self:ToggleQoLEvent("ZONE_CHANGED_NEW_AREA", true)
    self:ToggleQoLEvent("PLAYER_ENTERING_WORLD", true)
    self:ToggleQoLEvent("ENCOUNTER_START", true)
    if RRT.QoL.AutoRepair then self:ToggleQoLEvent("MERCHANT_SHOW", true) end
    if RRT.QoL.AutoInvite then
        self:ToggleQoLEvent("CHAT_MSG_WHISPER", true)
        self:ToggleQoLEvent("CHAT_MSG_BN_WHISPER", true)
    end
    if RRT.QoL.ChatFilter          then self:EnableChatFilter()              end
    if RRT.QoL.DeleteConfirm       then self:EnableDeleteConfirm()           end
    if RRT.QoL.DisableAutoAddSpells then self:EnableDisableAutoAddSpells()   end
end

function RRT_NS:ToggleQoLEvent(event, enable, unit)
    if self.IsBuilding then return end
    if enable then
        f:RegisterUnitEvent(event, unit)
    else
        f:UnregisterEvent(event)
    end
end

function RRT_NS:QoLOnZoneSwap() -- only register events while player is in raid
    local InRaid = self:DifficultyCheck(14)
    local InInstance = select(2, GetInstanceInfo()) == "party"
    if RRT.QoL.ResetBossDisplay then
        if InRaid and not self:Restricted() then
            self:ToggleQoLEvent("UNIT_AURA", true, "player")
            self:ToggleQoLEvent("PLAYER_REGEN_ENABLED", true)
            self:ToggleQoLEvent("PLAYER_REGEN_DISABLED", true)
        else
            self:ToggleQoLEvent("UNIT_AURA", false)
            self:ToggleQoLEvent("PLAYER_REGEN_ENABLED", false)
            self:ToggleQoLEvent("PLAYER_REGEN_DISABLED", false)
        end
    end

    if RRT.QoL.LootBossReminder then -- Loot Reminder is active in raid and any non-m+ dungeon
        self:ToggleQoLEvent("ENCOUNTER_END", InRaid)
        self:ToggleQoLEvent("LOOT_OPENED", InRaid)
        self:ToggleQoLEvent("CHAT_MSG_MONEY", InRaid)
        self:ToggleQoLEvent("ENCOUNTER_START", InRaid)
    end

    if RRT.QoL.GatewayUseableDisplay then self:ToggleQoLEvent("ACTIONBAR_UPDATE_USABLE", InRaid or InInstance) end

    -- always keeping these enabled when in a raid or instance as they are required for addon comms to work and addon restriction is used for multiple checks.
    self:ToggleQoLEvent("UNIT_SPELLCAST_SUCCEEDED", InRaid or InInstance, "player")
    self:ToggleQoLEvent("ADDON_RESTRICTION_STATE_CHANGED", InRaid or InInstance)

    if (not InRaid) and (not InInstance) then -- if zoning outside of raid&dungeon -> remove all displays
        self.QoLTextDisplays = {}
        self:UpdateQoLTextDisplay()
    end
end

function RRT_NS:HasLustDebuff()
    for _, spellID in ipairs(LustDebuffs) do
        local debuff = self:UnitAura("player", spellID)
        if (not issecretvalue(debuff)) and debuff then
            return true
        end
    end
    return false
end

local VantusIds = {

}
function RRT_NS:VantusRuneCheck()
    if self:Restricted() then print("Auras are currently secret so this is unvailable.") return end
    if not UnitInRaid("player") then return end
    local name = C_Spell.GetSpellInfo(1276691).name
    local prefix = name:match("^([^:]+)") -- get localized name of vantus runes
    local maxgroup = self:DifficultyCheck(16) and 4 or 6 -- if outside raidlead checks this always goes to 6 but guess that'S fine
    local text = ""
    for i=1, 40 do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name and subgroup and subgroup <= maxgroup then
            local unitid = UnitTokenFromGUID(UnitGUID(name))
            local found = false
            for j=1, 100 do
                local buff = C_UnitAuras.GetAuraDataByIndex(unitid, j, "HELPFUL")
                if not buff then break end
                if buff.name:find(prefix) then
                    found = true
                    break
                end
            end
            if not found then
                if text == "" then text = name else text = text..", "..name end
            end
        end
    end
    if text ~= "" then
        text = "Missing Vantus Runes: "..text
        print(text)
    else
        print("Everyone has a Vantus Rune!")
    end
end

function RRT_NS:HandleQoLComm(unitName, type)
    -- We can get addon comms from anywhere, but only show notifs from players we can actually see.
    if C_InstanceEncounter.IsEncounterInProgress() then return end -- don't popup anything while in boss combat
    if not UnitIsVisible(unitName) then
        return
    end

    if UnitIsUnit(unitName, "player") then
        return
    end

    local displayTimerSeconds = RRT.QoL.ConsumableNotificationDurationSeconds or 5
    local displayName = RRTAPI:Shorten(unitName, 8, false, "GlobalNickNames")
    if type == "FEAST" then
        -- can't check buff duration/presence in combat
        if self:Restricted() then
            return
        end

        local wellFedBuff = self:UnitAura("player", "Well Fed")
        local okayBuffDurationSeconds = 10 * 60
        if wellFedBuff and wellFedBuff.expirationTime and (wellFedBuff.expirationTime - GetTime() > okayBuffDurationSeconds) then
            return
        end

        self.QoLTextDisplays.FeastDropped = {SettingsName = "FeastDropped", text = string.format(TextDisplays.FeastDropped, displayName)}
        self:UpdateQoLTextDisplay()
        C_Timer.After(displayTimerSeconds, function()
            self.QoLTextDisplays.FeastDropped = nil
            self:UpdateQoLTextDisplay()
        end)
    elseif type == "CAULDRON" then
        -- TODO: check flask buff duration and number of potions in inventory?
        self.QoLTextDisplays.CauldronDropped = {SettingsName = "CauldronDropped", text = string.format(TextDisplays.CauldronDropped, displayName)}
        self:UpdateQoLTextDisplay()
        C_Timer.After(displayTimerSeconds, function()
            self.QoLTextDisplays.CauldronDropped = nil
            self:UpdateQoLTextDisplay()
        end)
    elseif type == "SOULWELL" then
        local healthstoneCharges = C_Item.GetItemCount(5512, false, true)
        if healthstoneCharges == 3 then
            return
        end
        self.QoLTextDisplays.SoulwellDropped = {SettingsName = "SoulwellDropped", text = string.format(TextDisplays.SoulwellDropped, displayName)}
        self:UpdateQoLTextDisplay()
        C_Timer.After(displayTimerSeconds, function()
            self.QoLTextDisplays.SoulwellDropped = nil
            self:UpdateQoLTextDisplay()
        end)
    elseif type == "REPAIR" then
        -- no repair notifications above this threshold
        local durabilityCutoff = 0.9

        local minDurability = 1
        for i=1, 18 do
            local currentDurability, maxDurability = GetInventoryItemDurability(i)
            if currentDurability ~= nil then
                minDurability = min(minDurability, currentDurability / maxDurability)
            end
        end
        if minDurability >= durabilityCutoff then
            return
        end

        self.QoLTextDisplays.RepairDropped = {SettingsName = "RepairDropped", text = string.format(TextDisplays.RepairDropped, displayName)}
        self:UpdateQoLTextDisplay()
        C_Timer.After(displayTimerSeconds, function()
            self.QoLTextDisplays.RepairDropped = nil
            self:UpdateQoLTextDisplay()
        end)
    end
end