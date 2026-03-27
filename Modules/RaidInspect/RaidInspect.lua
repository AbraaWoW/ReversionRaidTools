-- ─────────────────────────────────────────────────────────────────────────────
-- Modules/RaidInspect/RaidInspect.lua
-- Self-reporting Raid Inspect: each player broadcasts their own spec + ilvl.
-- No NotifyInspect() needed — fully compatible with WoW Midnight 12.x.
-- ─────────────────────────────────────────────────────────────────────────────
local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core          = RRT_NS.UI.Core
local window_width  = Core.window_width   -- 1050
local window_height = Core.window_height  -- 640

-- Gear slot IDs (skip Shirt=4, Tabard=19, deprecated Ranged=18)
local SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
local SLOT_NAMES = {
    [1]="Head",      [2]="Neck",       [3]="Shoulder",  [5]="Chest",
    [6]="Belt",      [7]="Legs",       [8]="Feet",      [9]="Wrist",
    [10]="Hands",    [11]="Ring 1",    [12]="Ring 2",   [13]="Trinket 1",
    [14]="Trinket 2",[15]="Cloak",     [16]="Main Hand",[17]="Off Hand",
}

-- Class icon atlas (Midnight 12.x supports SetAtlas)
local CLASS_ATLAS = {
    WARRIOR     = "classicon-warrior",    PALADIN    = "classicon-paladin",
    HUNTER      = "classicon-hunter",     ROGUE      = "classicon-rogue",
    PRIEST      = "classicon-priest",     DEATHKNIGHT= "classicon-deathknight",
    SHAMAN      = "classicon-shaman",     MAGE       = "classicon-mage",
    WARLOCK     = "classicon-warlock",    MONK       = "classicon-monk",
    DRUID       = "classicon-druid",      DEMONHUNTER= "classicon-demonhunter",
    EVOKER      = "classicon-evoker",
}

-- ilvl → color (rough Midnight Season 1 thresholds)
local function IlvlColor(ilvl)
    if not ilvl or ilvl == 0 then return 0.15, 0.15, 0.15 end
    if ilvl >= 658 then return 1.00, 0.82, 0.00 end  -- Mythic+ (gold)
    if ilvl >= 641 then return 0.64, 0.21, 0.93 end  -- Heroic   (purple)
    if ilvl >= 625 then return 0.20, 0.60, 1.00 end  -- Normal   (blue)
    if ilvl >= 606 then return 0.30, 0.80, 0.30 end  -- LFR/Crafted (green)
    return 0.55, 0.55, 0.55                           -- low gear  (gray)
end

-- ── Data collection (own player only) ────────────────────────────────────────
local function GetSlotIlvl(slotID)
    -- ItemLocation API: most reliable for equipped slots in Midnight 12.x
    if ItemLocation and C_Item.GetCurrentItemLevel then
        local loc = ItemLocation:CreateFromEquipmentSlot(slotID)
        if C_Item.DoesItemExist(loc) then
            return C_Item.GetCurrentItemLevel(loc) or 0
        end
        return 0
    end
    -- Fallback: link + GetDetailedItemLevelInfo / GetItemInfo
    local link = GetInventoryItemLink("player", slotID)
    if not link then return 0 end
    if C_Item.GetDetailedItemLevelInfo then
        local ilvl = C_Item.GetDetailedItemLevelInfo(link) or 0
        if ilvl > 0 then return ilvl end
    end
    return select(4, GetItemInfo(link)) or 0
end

-- Slots that must have a permanent enchant
local ENCHANT_SLOTS = {
    [1]=true,  -- Head
    [3]=true,  -- Shoulder
    [5]=true,  -- Chest
    [7]=true,  -- Legs
    [8]=true,  -- Feet
    [11]=true, -- Ring 1
    [12]=true, -- Ring 2
    [16]=true, -- Main Hand (not Off Hand)
}

-- Slots that can have gems
local GEM_SLOTS = {
    [2]=true,  -- Neck
    [11]=true, -- Ring 1
    [12]=true, -- Ring 2
}

local function IsMissingEnchant(slotID, link)
    if not ENCHANT_SLOTS[slotID] or not link then return false end
    -- Enchant is the 2nd field after "item:" in the hyperlink
    local enchantID = tonumber(link:match("|Hitem:%d+:(%d+):")) or 0
    return enchantID == 0
end

-- Bonus IDs that indicate a socket on an item.
-- To find new ones: /dump GetInventoryItemLink("player", slotID) then check field 14+
local SOCKET_BONUS_IDS = {
    [8902]=1, [9114]=1, [9553]=1, [9554]=1, [9555]=1,
    [9115]=1, [9116]=1, [9117]=1, [9118]=1,
    [6935]=1, [7978]=1,
    -- Midnight 12.x — common to neck + both rings (confirmed from item links 2026-03)
    [6652]=1, [13668]=1,
}

-- Split item link into all fields preserving empty ones.
-- |Hitem:id:enc:g1:g2:g3:g4:suf:uid:lvl:spec:mod:ctx:numBonus:b1:...|
-- Returns fields[1]=itemID [2]=enc [3-6]=gems [7]=suf [8]=uid [9]=lvl
--         [10]=spec [11]=mod [12]=ctx [13]=numBonus [14+]=bonusIDs
local function ParseLinkFields(link)
    local inner = link:match("|Hitem:([^|]+)|")
    if not inner then return nil end
    local f = {}
    for field in (inner .. ":"):gmatch("([^:]*):") do
        tinsert(f, tonumber(field) or 0)
    end
    return f
end

local function CountMissingGems(slotID)
    if not GEM_SLOTS[slotID] then return 0 end

    local link = GetInventoryItemLink("player", slotID)
    if not link then return 0 end

    local numSockets = 0

    -- Method 1: C_ItemSocketInfo (Midnight 12.x preferred API)
    if ItemLocation and C_Item.DoesItemExist and C_ItemSocketInfo then
        local loc = ItemLocation:CreateFromEquipmentSlot(slotID)
        if C_Item.DoesItemExist(loc) then
            if C_ItemSocketInfo.GetSocketTypes then
                local ok, sockets = pcall(C_ItemSocketInfo.GetSocketTypes, loc)
                if ok and sockets then numSockets = #sockets end
            end
            if numSockets == 0 and C_ItemSocketInfo.GetSocketCount then
                local ok, n = pcall(C_ItemSocketInfo.GetSocketCount, loc)
                if ok and type(n) == "number" then numSockets = n end
            end
        end
    end

    -- Method 2: bonus ID scan — boolean detection (one socket per item in GEM_SLOTS)
    if numSockets == 0 then
        local f = ParseLinkFields(link)
        if f then
            local numBonus = f[13] or 0
            for i = 1, numBonus do
                local bid = f[13 + i]
                if bid and bid > 0 and SOCKET_BONUS_IDS[bid] then
                    numSockets = 1
                    break
                end
            end
        end
    end

    -- Method 3: C_TooltipInfo text scan (EN: "Socket" / FR: "Emplacement")
    if numSockets == 0 and C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                local txt = line.leftText or ""
                if txt:find("Socket") or txt:find("Emplacement") then
                    numSockets = numSockets + 1
                end
            end
        end
    end

    if numSockets == 0 then return 0 end

    -- Count empty gem fields in link (field 3 = gem1, 4 = gem2, etc.)
    local f = ParseLinkFields(link)
    if not f then return 0 end
    local count = 0
    for i = 1, numSockets do
        if (f[2 + i] or 0) == 0 then count = count + 1 end
    end
    return count
end

local function CollectSelfData()
    local spec   = C_SpecializationInfo.GetSpecialization()
    local specID = (spec and spec > 0)
                   and select(1, C_SpecializationInfo.GetSpecializationInfo(spec)) or 0
    local _, _, classFile = UnitClass("player")

    local ilvls    = {}
    local icons    = {}
    local missing  = {}   -- per slot: 0=ok, 1=enchant, 2=gem, 3=both
    local gemcount = {}   -- per slot: number of missing gems
    local total, count = 0, 0
    for _, slotID in ipairs(SLOTS) do
        local link = GetInventoryItemLink("player", slotID)
        local ilvl = GetSlotIlvl(slotID)
        tinsert(ilvls, ilvl)
        tinsert(icons, GetInventoryItemTexture("player", slotID) or 0)
        local m, gc = 0, 0
        if ilvl > 0 then
            if IsMissingEnchant(slotID, link) then m = m + 1 end
            gc = CountMissingGems(slotID)
            if gc > 0 then m = m + 2 end
            total = total + ilvl; count = count + 1
        end
        tinsert(missing, m)
        tinsert(gemcount, gc)
    end
    local avg = (count > 0) and math.floor(total / count) or 0

    return {
        name     = UnitName("player"),
        class    = classFile or "",
        specID   = specID,
        avg      = avg,
        ilvls    = ilvls,
        icons    = icons,
        missing  = missing,
        gemcount = gemcount,
    }
end

-- ── Comm: broadcast own data ──────────────────────────────────────────────────
function RRT_NS:BroadcastRaidInspectData()
    if not IsInGroup() then return end
    RRT_NS:Broadcast("RRIN_DATA", "RAID", CollectSelfData())
end

-- ── Comm: store incoming data + refresh UI ────────────────────────────────────
function RRT_NS:HandleRaidInspectData(data)
    if type(data) ~= "table" or not data.name then return end
    RRT.RaidInspect          = RRT.RaidInspect or { players = {} }
    RRT.RaidInspect.players[data.name] = data
    RRT.RaidInspect.lastSync = time()
    if RRT_NS._RaidInspectRefresh then
        RRT_NS._RaidInspectRefresh()
    end
end

-- ── Scan: ask everyone + store own data immediately ───────────────────────────
function RRT_NS:RequestRaidInspect()
    RRT_NS:HandleRaidInspectData(CollectSelfData())
    if IsInGroup() then
        RRT_NS:Broadcast("RRIN_REQUEST", "RAID")
    end
end

-- ── Auto-broadcast on group events ───────────────────────────────────────────
do
    local af = CreateFrame("Frame")
    af:RegisterEvent("GROUP_ROSTER_UPDATE")
    af:RegisterEvent("PLAYER_ENTERING_WORLD")
    af:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(6, function() RRT_NS:BroadcastRaidInspectData() end)
        elseif event == "GROUP_ROSTER_UPDATE" then
            C_Timer.After(2, function() RRT_NS:BroadcastRaidInspectData() end)
        end
    end)
end

-- ── Panel UI ──────────────────────────────────────────────────────────────────
local SIDEBAR_WIDTH = 130  -- must match Modules/Raid/UI.lua
local SCAN_H        = 30
local HEADER_H      = 18
local ROW_H         = 40   -- taller rows: 2-line name + spec/ilvl, icon slots
-- Content area dimensions (panel = contentArea inside BuildRaidUI)
-- 12px reserved on right for custom scrollbar (2 gap + 8 track + 2 pad)
-- extra 20px bottom margin to prevent overflow
local CONTENT_W     = window_width - SIDEBAR_WIDTH - 32   -- ~888
local CONTENT_H     = window_height - 100 - 22 - SCAN_H - HEADER_H - 20  -- ~450
local MAX_LINES     = math.floor(CONTENT_H / ROW_H)      -- ~11

-- Left section: Name (top row) + [SpecIcon + ilvl] (bottom row) = 200px
local LEFT_W    = 200
local SLOT_STEP = math.floor((CONTENT_W - LEFT_W - 18) / 16)  -- ~42
local SLOT_SZ   = SLOT_STEP - 6                                -- ~36px icon squares

local function GetSortedPlayers()
    local t = {}
    local db = (RRT.RaidInspect and RRT.RaidInspect.players) or {}
    local seen = {}
    -- Raid members first
    local n = GetNumGroupMembers()
    for i = 1, n do
        local unitID = IsInRaid() and ("raid" .. i) or ("party" .. i)
        local name = UnitName(unitID)
        if name and db[name] and not seen[name] then
            tinsert(t, db[name])
            seen[name] = true
        end
    end
    -- Self
    local myName = UnitName("player")
    if myName and db[myName] and not seen[myName] then
        tinsert(t, db[myName])
    end
    -- Sort by avg ilvl descending
    table.sort(t, function(a, b) return (a.avg or 0) > (b.avg or 0) end)
    return t
end

-- Custom dark scrollbar for FauxScrollFrame-based DF scrollboxes
local function MakeFauxScrollBar(scrollBox, name, numLines)
    local scrollBar = _G[name .. "ScrollBar"]
    if scrollBar then
        scrollBar:SetAlpha(0)
        scrollBar:EnableMouse(false)
    end
    local upBtn = _G[name .. "ScrollBarScrollUpButton"]
    local dnBtn = _G[name .. "ScrollBarScrollDownButton"]
    if upBtn then upBtn:Hide() upBtn:EnableMouse(false) end
    if dnBtn then dnBtn:Hide() dnBtn:EnableMouse(false) end

    local track = CreateFrame("Frame", nil, scrollBox:GetParent(), "BackdropTemplate")
    track:SetWidth(8)
    track:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    track:SetBackdropColor(0.08, 0.08, 0.10, 0.85)
    track:SetBackdropBorderColor(0, 0, 0, 1)
    track:EnableMouse(true)

    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    thumb:SetBackdropColor(0.45, 0.45, 0.45, 0.75)
    thumb:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    thumb:EnableMouse(true)

    local function UpdateThumb()
        if not scrollBar then return end
        local _, maxV = scrollBar:GetMinMaxValues()
        local curV = scrollBar:GetValue()
        local trackH = track:GetHeight() or 1
        if maxV <= 0 then
            thumb:Hide()
            return
        end
        local thumbH = math.max(16, trackH * (numLines / (numLines + maxV)))
        thumb:Show()
        thumb:SetWidth(track:GetWidth() - 2)
        thumb:SetHeight(thumbH)
        local travel = trackH - thumbH
        local pct    = math.max(0, math.min(1, curV / maxV))
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -(travel * pct))
    end

    if scrollBar then
        scrollBar:HookScript("OnValueChanged", function() UpdateThumb() end)
    end

    track:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not scrollBar then return end
        local _, maxV = scrollBar:GetMinMaxValues()
        if maxV <= 0 then return end
        local cy  = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local top = track:GetTop()
        local bot = track:GetBottom()
        if not top or not bot or top == bot then return end
        local pct = 1 - ((cy - bot) / (top - bot))
        scrollBar:SetValue(math.max(0, math.min(maxV, pct * maxV)))
    end)

    local isDragging, dragStartY, dragStartVal = false, 0, 0
    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not scrollBar then return end
        isDragging  = true
        dragStartY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartVal = scrollBar:GetValue()
    end)
    thumb:SetScript("OnMouseUp", function() isDragging = false end)
    thumb:SetScript("OnUpdate", function()
        if not isDragging or not scrollBar then return end
        local _, maxV = scrollBar:GetMinMaxValues()
        if maxV <= 0 then return end
        local cy     = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local trackH = track:GetHeight() or 1
        local thumbH = thumb:GetHeight() or 1
        local travel = trackH - thumbH
        if travel <= 0 then return end
        local delta  = dragStartY - cy
        scrollBar:SetValue(math.max(0, math.min(maxV, dragStartVal + (delta / travel) * maxV)))
    end)
    thumb:SetScript("OnEnter", function(self) self:SetBackdropColor(0.65, 0.65, 0.65, 0.95) end)
    thumb:SetScript("OnLeave", function(self) self:SetBackdropColor(0.45, 0.45, 0.45, 0.75) end)

    track:HookScript("OnShow", UpdateThumb)
    scrollBox:HookScript("OnShow", UpdateThumb)

    return track
end

local function BuildRaidInspectPanel(panel)
    RRT.RaidInspect = RRT.RaidInspect or { players = {} }

    local _tc = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
    local tR, tG, tB = _tc[1], _tc[2], _tc[3]

    -- ── Scan button ───────────────────────────────────────────────────────────
    local btnScan = CreateFrame("Button", nil, panel, "BackdropTemplate")
    btnScan:SetSize(100, SCAN_H - 4)
    btnScan:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    btnScan:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btnScan:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    btnScan:SetBackdropBorderColor(tR, tG, tB, 1)
    local btnLbl = btnScan:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then btnLbl:SetFont(f, 9, fl or "") end end
    btnLbl:SetPoint("CENTER")
    btnLbl:SetText("Scan Raid")
    btnLbl:SetTextColor(0.9, 0.9, 0.9, 1)
    btnScan:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 1)
        btnLbl:SetTextColor(1, 1, 1, 1)
    end)
    btnScan:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(tR, tG, tB, 1)
        btnLbl:SetTextColor(0.9, 0.9, 0.9, 1)
    end)

    -- ── Status label ──────────────────────────────────────────────────────────
    local statusLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then statusLbl:SetFont(f, 9, fl or "") end end
    statusLbl:SetPoint("LEFT", btnScan, "RIGHT", 10, 0)
    statusLbl:SetTextColor(0.65, 0.65, 0.65, 1)
    statusLbl:SetText("Click Scan Raid to request data from group members.")

    -- ── Column headers ────────────────────────────────────────────────────────
    local headerY = -(SCAN_H + 2)
    local headers = {
        { label = "Name / Spec / Avg ilvl",       x = 5 },
        { label = "Gear Slots (hover for detail)", x = LEFT_W + 14 },
    }
    for _, h in ipairs(headers) do
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then fs:SetFont(f, 9, fl or "") end end
        fs:SetPoint("TOPLEFT", panel, "TOPLEFT", h.x, headerY)
        fs:SetText(h.label)
        fs:SetTextColor(0.75, 0.75, 0.75, 1)
    end
    -- Separator
    local sep = panel:CreateTexture(nil, "ARTWORK")
    sep:SetTexture("Interface\\Buttons\\WHITE8X8")
    sep:SetVertexColor(0.3, 0.3, 0.3, 0.5)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  panel, "TOPLEFT",  4, headerY - HEADER_H + 3)
    sep:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, headerY - HEADER_H + 3)

    -- ── Scrollbox ─────────────────────────────────────────────────────────────
    local scrollTopOff = SCAN_H + HEADER_H + 10

    local function refreshFunc(self, data, offset, totalLines)
        for i = 1, totalLines do
            local idx  = i + offset
            local d    = data[idx]
            local line = self:GetLine(i)
            if not line then break end
            if d then
                line:Show()
                -- Spec icon (GetSpecializationInfoByID takes a global spec ID)
                if d.specID and d.specID > 0 then
                    local _, _, _, specTex = GetSpecializationInfoByID(d.specID)
                    if specTex then
                        line.specIcon:SetTexture(specTex)
                        line.specIcon:Show()
                    else
                        line.specIcon:Hide()
                    end
                else
                    line.specIcon:Hide()
                end
                -- Name (class-colored)
                local cc = RAID_CLASS_COLORS and d.class and RAID_CLASS_COLORS[d.class]
                if cc then
                    line.nameLbl:SetTextColor(cc.r, cc.g, cc.b, 1)
                else
                    line.nameLbl:SetTextColor(0.9, 0.9, 0.9, 1)
                end
                line.nameLbl:SetText(d.name or "")
                -- Avg ilvl (colored)
                local ir, ig, ib = IlvlColor(d.avg)
                line.ilvlLbl:SetTextColor(ir, ig, ib, 1)
                line.ilvlLbl:SetText((d.avg and d.avg > 0) and tostring(d.avg) or "?")
                -- Gear slot icons + ilvl overlay
                for j = 1, 16 do
                    local sq   = line.slots[j]
                    local ilvl = (d.ilvls and d.ilvls[j]) or 0
                    local icon = (d.icons and d.icons[j]) or 0
                    local sr, sg, sb = IlvlColor(ilvl)
                    -- Icon texture
                    if icon ~= 0 then
                        sq.icon:SetTexture(icon)
                        sq.icon:Show()
                        sq:SetBackdropColor(0, 0, 0, 0)
                    else
                        sq.icon:SetTexture(nil)
                        sq.icon:Hide()
                        sq:SetBackdropColor(0.07, 0.07, 0.07, 0.95)
                    end
                    -- ilvl text (only when > 0)
                    if ilvl > 0 then
                        sq.ilvlText:SetText(tostring(ilvl))
                    else
                        sq.ilvlText:SetText("")
                    end
                    -- Border colored by ilvl tier
                    sq:SetBackdropBorderColor(sr, sg, sb, ilvl > 0 and 0.9 or 0.2)
                    sq._ilvl     = ilvl
                    sq._slotName = SLOT_NAMES[SLOTS[j]] or ("Slot " .. j)
                    -- Warning blink (missing enchant / gem)
                    local miss = (d.missing  and d.missing[j])  or 0
                    local gc   = (d.gemcount and d.gemcount[j]) or 0
                    sq._missing  = miss
                    sq._gemcount = gc
                    if miss > 0 and ilvl > 0 then
                        sq.warn:Show()
                        if not sq.warn._anim:IsPlaying() then sq.warn._anim:Play() end
                    else
                        sq.warn._anim:Stop()
                        sq.warn:Hide()
                    end
                end
            else
                line:Hide()
            end
        end
    end

    local function createLineFunc(sf, idx)
        local line = CreateFrame("Frame", nil, sf, "BackdropTemplate")
        line:SetPoint("TOPLEFT", sf, "TOPLEFT", 1, -((idx - 1) * (sf.LineHeight + 1)) - 1)
        line:SetSize(sf:GetWidth() - 2, sf.LineHeight)
        line:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        local bg = (idx % 2 == 0) and 0.08 or 0.05
        line:SetBackdropColor(bg, bg, bg, 0.6)
        line.index = idx

        -- ── Left section: 2-line layout ──────────────────────────────────────
        -- Line 1 (top): Name, class-colored
        local nameLbl = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then nameLbl:SetFont(f, 9, fl or "") end end
        nameLbl:SetWidth(LEFT_W - 6)
        nameLbl:SetJustifyH("LEFT")
        nameLbl:SetPoint("TOPLEFT", line, "TOPLEFT", 4, -4)
        line.nameLbl = nameLbl

        -- Line 2 (bottom): Spec icon + avg ilvl
        local specIcon = line:CreateTexture(nil, "ARTWORK")
        specIcon:SetSize(16, 16)
        specIcon:SetPoint("BOTTOMLEFT", line, "BOTTOMLEFT", 4, 4)
        line.specIcon = specIcon

        local ilvlLbl = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then ilvlLbl:SetFont(f, 9, fl or "") end end
        ilvlLbl:SetJustifyH("LEFT")
        ilvlLbl:SetPoint("LEFT", specIcon, "RIGHT", 4, 0)
        line.ilvlLbl = ilvlLbl

        -- ── Gear slots: item icons with ilvl overlay ──────────────────────────
        line.slots = {}
        for j = 1, 16 do
            local sq = CreateFrame("Frame", nil, line, "BackdropTemplate")
            sq:SetSize(SLOT_SZ, SLOT_SZ)
            sq:SetPoint("TOP", line, "TOP", 0, -2)
            if j == 1 then
                sq:SetPoint("LEFT", line, "LEFT", LEFT_W + 6, 0)
            else
                sq:SetPoint("LEFT", line.slots[j - 1], "RIGHT", SLOT_STEP - SLOT_SZ, 0)
            end
            sq:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            sq:SetBackdropColor(0.07, 0.07, 0.07, 0.95)
            sq:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.6)

            -- Item icon texture (fills interior, trims Blizzard icon border)
            local sqIcon = sq:CreateTexture(nil, "ARTWORK")
            sqIcon:SetPoint("TOPLEFT",     sq, "TOPLEFT",     1, -1)
            sqIcon:SetPoint("BOTTOMRIGHT", sq, "BOTTOMRIGHT", -1,  1)
            sqIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            sq.icon = sqIcon

            -- ilvl text overlay (bottom of icon, white + outline)
            local sqIlvl = sq:CreateFontString(nil, "OVERLAY")
            sqIlvl:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
            sqIlvl:SetPoint("BOTTOMLEFT",  sq, "BOTTOMLEFT",  1, 1)
            sqIlvl:SetPoint("BOTTOMRIGHT", sq, "BOTTOMRIGHT", -1, 1)
            sqIlvl:SetJustifyH("CENTER")
            sqIlvl:SetTextColor(1, 1, 1, 1)
            sq.ilvlText = sqIlvl

            -- Red blinking warning overlay (missing enchant / gem)
            local warnTex = sq:CreateTexture(nil, "OVERLAY")
            warnTex:SetAllPoints()
            warnTex:SetTexture("Interface\\Buttons\\WHITE8X8")
            warnTex:SetVertexColor(1, 0, 0, 0)
            warnTex:Hide()
            local ag = warnTex:CreateAnimationGroup()
            ag:SetLooping("REPEAT")
            local a1 = ag:CreateAnimation("Alpha")
            a1:SetFromAlpha(0); a1:SetToAlpha(0.65); a1:SetDuration(0.45); a1:SetOrder(1)
            local a2 = ag:CreateAnimation("Alpha")
            a2:SetFromAlpha(0.65); a2:SetToAlpha(0); a2:SetDuration(0.45); a2:SetOrder(2)
            warnTex._anim = ag
            sq.warn = warnTex

            sq._slotName = SLOT_NAMES[SLOTS[j]] or ("Slot " .. j)
            sq._ilvl     = 0
            sq._missing  = 0
            sq._gemcount = 0
            sq:EnableMouse(true)
            sq:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(self._slotName, 1, 1, 1)
                local ilvl = self._ilvl or 0
                if ilvl > 0 then
                    local r, g, b = IlvlColor(ilvl)
                    GameTooltip:AddLine("Item Level: " .. ilvl, r, g, b)
                else
                    GameTooltip:AddLine("Empty", 0.5, 0.5, 0.5)
                end
                local m  = self._missing  or 0
                local gc = self._gemcount or 0
                if m == 1 or m == 3 then
                    GameTooltip:AddLine("Missing enchantment", 1, 0.3, 0.3)
                end
                if m == 2 or m == 3 then
                    local gemLabel = gc > 1
                        and ("Missing gems (" .. gc .. ")")
                        or  "Missing gem"
                    GameTooltip:AddLine(gemLabel, 1, 0.3, 0.3)
                end
                GameTooltip:Show()
            end)
            sq:SetScript("OnLeave", function() GameTooltip:Hide() end)
            line.slots[j] = sq
        end

        return line
    end

    local scrollbox = DF:CreateScrollBox(panel, "RRTRaidInspectScrollBox",
        refreshFunc, {}, CONTENT_W, CONTENT_H, MAX_LINES, ROW_H, createLineFunc)
    scrollbox:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -scrollTopOff)
    local riTrack = MakeFauxScrollBar(scrollbox, "RRTRaidInspectScrollBox", MAX_LINES)
    riTrack:SetPoint("TOPLEFT",    scrollbox, "TOPRIGHT",    2, 0)
    riTrack:SetPoint("BOTTOMLEFT", scrollbox, "BOTTOMRIGHT", 2, 0)
    for i = 1, MAX_LINES do scrollbox:CreateLine(createLineFunc) end
    scrollbox:Refresh()

    -- ── Scan button click ─────────────────────────────────────────────────────
    local function DoRefresh()
        local players = GetSortedPlayers()
        scrollbox:SetData(players)
        scrollbox:Refresh()
        local n = #players
        statusLbl:SetText(n .. " player" .. (n ~= 1 and "s" or "") ..
            " with RRT found.  Last scan: " .. date("%H:%M:%S"))
    end

    btnScan:SetScript("OnClick", function()
        RRT_NS:RequestRaidInspect()
        statusLbl:SetText("Scanning... waiting for responses.")
        C_Timer.After(3, DoRefresh)
    end)

    -- ── Auto-refresh when RRIN_DATA arrives ───────────────────────────────────
    RRT_NS._RaidInspectRefresh = DoRefresh

    -- ── Refresh on panel show ─────────────────────────────────────────────────
    panel:HookScript("OnShow", DoRefresh)

    -- ── Theme color callback ──────────────────────────────────────────────────
    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
        tR, tG, tB = r, g, b
        btnScan:SetBackdropBorderColor(r, g, b, 1)
    end)
end

-- ── Export ────────────────────────────────────────────────────────────────────
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.RaidInspect = {
    BuildRaidInspectPanel = BuildRaidInspectPanel,
}
