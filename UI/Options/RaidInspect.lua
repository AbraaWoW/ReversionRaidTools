local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local window_width  = Core.window_width
local window_height = Core.window_height
local options_button_template = Core.options_button_template
local apply_scrollbar_style = Core.apply_scrollbar_style

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local COMM_PREFIX = "RRIN"
local FONT        = "Fonts\\FRIZQT__.TTF"

-- Equipment slots in display order:
-- Head(1), Neck(2), Shoulder(3), Back(15), Chest(5), Wrist(9), Hands(10),
-- Waist(6), Legs(7), Feet(8), Ring1(11), Ring2(12), Trinket1(13), Trinket2(14),
-- MainHand(16), OffHand(17)
local EQUIP_SLOTS = {1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17}
local SLOT_SHORT  = {"Hd","Nc","Sh","Bk","Ch","Wr","Gv","Wa","Lg","Bt","R1","R2","T1","T2","MH","OH"}
local SLOT_FULL   = {
    "Head","Neck","Shoulders","Back","Chest","Wrist","Gloves",
    "Waist","Legs","Boots","Ring 1","Ring 2","Trinket 1","Trinket 2",
    "Main Hand","Off Hand",
}
local NUM_SLOTS = #EQUIP_SLOTS

-- Layout
local CONTAINER_W   = window_width - 20    -- 1030
local CONTAINER_H   = window_height - 110  -- 530
local TOPBAR_H      = 32
local HEADER_H      = 24
local SCROLL_Y      = TOPBAR_H + HEADER_H  -- 56
local ROW_H         = 46
local SCROLL_PAD    = 8
local ICON_SZ       = 22   -- class / spec icon size
local SLOT_ICON_SZ  = 30   -- item slot icon size

-- Column widths
local COL_NAME      = 180
local COL_CLASSSPEC = 52   -- two 22-px icons + 4-px gap + 4-px padding
local COL_AVG       = 70
local COL_SLOT      = 40
-- Total: 180 + 52 + 70 + (16 × 40) = 942 px
local CONTENT_W     = COL_NAME + COL_CLASSSPEC + COL_AVG + NUM_SLOTS * COL_SLOT

-- Button colours (match SetupManager style)
local COLOR_BTN       = {0.10, 0.13, 0.18, 0.90}
local COLOR_BTN_HOVER = {0.18, 0.25, 0.35, 0.95}
local COLOR_LABEL     = {0.85, 0.85, 0.85, 1.0}
local COLOR_SECTION   = {0.12, 0.12, 0.12, 1.0}
local COLOR_BORDER    = {0.2, 0.2, 0.2, 1.0}

-- Class colours / display names
local CLASS_HEX = {
    WARRIOR="C69B3A",  PALADIN="F48CBA",  HUNTER="AAD372",    ROGUE="FFF468",
    PRIEST="FFFFFF",   DEATHKNIGHT="C41E3A", SHAMAN="0070DD", MAGE="3FC7EB",
    WARLOCK="8788EE",  MONK="00FF98",     DRUID="FF7C0A",     DEMONHUNTER="A330C9",
    EVOKER="33937F",
}
local CLASS_DISPLAY = {
    WARRIOR="Warrior",     PALADIN="Paladin",   HUNTER="Hunter",
    ROGUE="Rogue",         PRIEST="Priest",     DEATHKNIGHT="Death Knight",
    SHAMAN="Shaman",       MAGE="Mage",         WARLOCK="Warlock",
    MONK="Monk",           DRUID="Druid",       DEMONHUNTER="Dem. Hunter",
    EVOKER="Evoker",
}

-------------------------------------------------------------------------------
-- Module state
-------------------------------------------------------------------------------

local _statusLabel  = nil   -- FontString in the top bar
local _rowFrames    = {}    -- row pool; grown as needed
local _scrollChild  = nil   -- scroll child frame (nil until UI is built)
local _commReady    = false
local _reqCounter   = 0
local _pendingIcons = {}    -- icons buffered when ICN arrives before DAT

-------------------------------------------------------------------------------
-- DB
-------------------------------------------------------------------------------

local function EnsureDB()
    if not RRTDB then return nil end
    RRTDB.RaidInspect = RRTDB.RaidInspect or {}
    local db = RRTDB.RaidInspect
    if type(db.players)  ~= "table" then db.players  = {} end
    if type(db.lastSync) ~= "number" then db.lastSync = 0  end
    return db
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function RRT_Print(msg)
    print("|cFF33FF99[RRT Inspect]|r " .. tostring(msg))
end

local function ResolveChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid()  then return "RAID"  end
    if IsInGroup() then return "PARTY" end
    return nil
end

local function CanSync()
    if not IsInGroup() then return true end   -- solo: always OK for testing
    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

-- Styled button (matches SetupManager SkinButton pattern)
local function SkinPanel(frame, bgColor, borderColor)
    if not frame then return end
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bgColor or COLOR_SECTION))
    frame:SetBackdropBorderColor(unpack(borderColor or COLOR_BORDER))
end

local function SkinButton(btn, color, hoverColor)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(unpack(color or COLOR_BTN))
    btn._bg = bg
    btn:SetScript("OnEnter", function(self)
        self._bg:SetVertexColor(unpack(hoverColor or COLOR_BTN_HOVER))
    end)
    btn:SetScript("OnLeave", function(self)
        self._bg:SetVertexColor(unpack(color or COLOR_BTN))
    end)
end

local function CreateRRTButton(parent, text, width, height, onClick)
    if DF and DF.CreateButton then
        local btnObj = DF:CreateButton(parent, onClick, width, height, text)
        local btn = (btnObj and (btnObj.widget or btnObj.button)) or btnObj
        if options_button_template and btnObj and btnObj.SetTemplate then
            btnObj:SetTemplate(options_button_template)
        else
            if btn then SkinButton(btn) end
        end
        if btnObj and btnObj.SetTextColor then
            btnObj:SetTextColor(unpack(COLOR_LABEL))
        end
        if btn and btn.SetScript then
            btn:SetScript("OnClick", onClick)
        end
        return btn
    end

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)
    SkinButton(btn)
    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("CENTER", 0, 0)
    label:SetTextColor(unpack(COLOR_LABEL))
    label:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Apply class icon to a texture widget
local function SetClassIconTex(tex, class)
    if not class or not tex then return end
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if coords then
        tex:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        tex:SetTexCoord(unpack(coords))
    else
        -- Fallback: individual class icon (covers Evoker and unknowns)
        tex:SetTexture("Interface\\Icons\\classicon_" .. class:lower())
        tex:SetTexCoord(0, 1, 0, 1)
    end
    tex:Show()
end

-- Spec icon FileDataID from a specID
local function GetSpecIconFileID(specID)
    if not specID or specID == 0 then return nil end
    if not GetSpecializationInfoByID then return nil end
    local _, _, _, icon = GetSpecializationInfoByID(specID)
    return icon
end

-- Current player's active spec ID
local function GetSelfSpecID()
    if not GetSpecialization then return 0 end
    local idx = GetSpecialization()
    if not idx or idx == 0 then return 0 end
    local specID = select(1, GetSpecializationInfo(idx))
    return specID or 0
end

-- Item icon FileDataID for a specific equipment slot
local function GetSlotIconFileID(slotID)
    local tex = GetInventoryItemTexture("player", slotID)
    if type(tex) == "number" and tex > 0 then return tex end
    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then return 0 end
    return tonumber(select(10, GetItemInfoInstant(itemID))) or 0
end

-------------------------------------------------------------------------------
-- Gear collection
-------------------------------------------------------------------------------

local function CollectOwnGear()
    local slots = {}
    local total, count = 0, 0
    for _, slotID in ipairs(EQUIP_SLOTS) do
        local loc = ItemLocation:CreateFromEquipmentSlot(slotID)
        if C_Item.DoesItemExist(loc) then
            local ilvl = C_Item.GetCurrentItemLevel(loc)
            if ilvl and ilvl > 0 then
                slots[slotID] = ilvl
                total = total + ilvl
                count = count + 1
            end
        end
    end
    local avg = count > 0 and math.floor(total / count + 0.5) or 0
    return avg, slots
end

local function CollectOwnIcons()
    local icons = {}
    for _, slotID in ipairs(EQUIP_SLOTS) do
        local id = GetSlotIconFileID(slotID)
        if id and id > 0 then icons[slotID] = id end
    end
    return icons
end

local function SlotsToStr(slots)
    local parts = {}
    for _, slotID in ipairs(EQUIP_SLOTS) do
        if slots[slotID] then
            parts[#parts + 1] = slotID .. ":" .. slots[slotID]
        end
    end
    return table.concat(parts, "|")
end

local function StrToSlots(str)
    local slots = {}
    if str and str ~= "" then
        for pair in str:gmatch("[^|]+") do
            local id, ilvl = pair:match("^(%d+):(%d+)$")
            if id and ilvl then
                slots[tonumber(id)] = tonumber(ilvl)
            end
        end
    end
    return slots
end

-- ICN message: 16 FileDataIDs separated by "|", one per EQUIP_SLOTS entry (0 = empty)
local function IconsToStr(icons)
    local parts = {}
    for _, slotID in ipairs(EQUIP_SLOTS) do
        parts[#parts + 1] = tostring(icons[slotID] or 0)
    end
    return table.concat(parts, "|")
end

local function StrToIcons(str)
    local icons = {}
    if str and str ~= "" then
        local i = 1
        for val in str:gmatch("[^|]+") do
            local slotID = EQUIP_SLOTS[i]
            if slotID then
                local v = tonumber(val)
                if v and v > 0 then icons[slotID] = v end
            end
            i = i + 1
        end
    end
    return icons
end

-------------------------------------------------------------------------------
-- UI refresh
-------------------------------------------------------------------------------

local function RefreshStatus()
    if not _statusLabel then return end
    local db = EnsureDB(); if not db then return end
    local count = 0
    for _ in pairs(db.players) do count = count + 1 end
    local groupSize = GetNumGroupMembers()
    if groupSize == 0 then groupSize = 1 end
    local sinceSync = db.lastSync > 0 and math.floor(GetTime() - db.lastSync) or nil
    local timeStr   = sinceSync and (" | last sync " .. sinceSync .. "s ago") or ""
    _statusLabel:SetText(count .. "/" .. groupSize .. " responded" .. timeStr)
end

local function RefreshPlayerList()
    local db = EnsureDB()
    if not db or not _scrollChild then return end

    -- Sort descending by avg ilvl
    local sorted = {}
    for _, pdata in pairs(db.players) do
        sorted[#sorted + 1] = pdata
    end
    table.sort(sorted, function(a, b) return (a.avg or 0) > (b.avg or 0) end)

    local maxAvg = sorted[1] and sorted[1].avg or 0

    -- Vertical center offset for class/spec icons (TOPLEFT anchor)
    local iconTopY = -math.floor((ROW_H - ICON_SZ) / 2)  -- -12

    for i, pdata in ipairs(sorted) do
        -- Grow pool if needed
        local row = _rowFrames[i]
        if not row then
            row = CreateFrame("Frame", nil, _scrollChild)
            row:SetHeight(ROW_H)

            -- Alternating background stripe
            row.altBg = row:CreateTexture(nil, "BACKGROUND")
            row.altBg:SetAllPoints()
            row.altBg:SetTexture("Interface\\Buttons\\WHITE8X8")

            -- Hover highlight
            local hover = row:CreateTexture(nil, "HIGHLIGHT")
            hover:SetAllPoints()
            hover:SetTexture("Interface\\Buttons\\WHITE8X8")
            hover:SetVertexColor(1, 1, 1, 0.08)

            -- Player name (vertically centered via LEFT anchor)
            row.nameFS = row:CreateFontString(nil, "OVERLAY")
            row.nameFS:SetFont(FONT, 11, "")
            row.nameFS:SetPoint("LEFT", row, "LEFT", 2, 0)
            row.nameFS:SetWidth(COL_NAME - 4)
            row.nameFS:SetJustifyH("LEFT")
            row.nameFS:SetWordWrap(false)

            -- Class icon (22×22, vertically centered)
            local classX = COL_NAME + 2
            row.classTex = row:CreateTexture(nil, "ARTWORK")
            row.classTex:SetSize(ICON_SZ, ICON_SZ)
            row.classTex:SetPoint("TOPLEFT", row, "TOPLEFT", classX, iconTopY)

            -- Spec icon (22×22, vertically centered, right of class icon)
            row.specTex = row:CreateTexture(nil, "ARTWORK")
            row.specTex:SetSize(ICON_SZ, ICON_SZ)
            row.specTex:SetPoint("TOPLEFT", row, "TOPLEFT", classX + ICON_SZ + 4, iconTopY)

            -- Average ilvl (vertically centered via LEFT anchor)
            local avgX = COL_NAME + COL_CLASSSPEC + 2
            row.avgFS = row:CreateFontString(nil, "OVERLAY")
            row.avgFS:SetFont(FONT, 11, "")
            row.avgFS:SetPoint("LEFT", row, "LEFT", avgX, 0)
            row.avgFS:SetWidth(COL_AVG - 4)
            row.avgFS:SetJustifyH("CENTER")

            -- Per-slot: item icon (30×30) + ilvl text below
            row.slotTex = {}
            row.slotFS  = {}
            local iconPad = math.floor((COL_SLOT - SLOT_ICON_SZ) / 2)  -- 5
            for j = 1, NUM_SLOTS do
                local slotX = COL_NAME + COL_CLASSSPEC + COL_AVG + (j - 1) * COL_SLOT

                local tex = row:CreateTexture(nil, "ARTWORK")
                tex:SetSize(SLOT_ICON_SZ, SLOT_ICON_SZ)
                tex:SetPoint("TOPLEFT", row, "TOPLEFT", slotX + iconPad, -2)
                row.slotTex[j] = tex

                local fs = row:CreateFontString(nil, "OVERLAY")
                fs:SetFont(FONT, 9, "OUTLINE")
                fs:SetPoint("TOPLEFT", row, "TOPLEFT", slotX, -(2 + SLOT_ICON_SZ + 1))
                fs:SetWidth(COL_SLOT)
                fs:SetJustifyH("CENTER")
                fs:SetWordWrap(false)
                row.slotFS[j] = fs
            end

            -- Tooltip on hover
            row:EnableMouse(true)
            row:SetScript("OnEnter", function(self)
                local d = self._playerData; if not d then return end
                local hex = CLASS_HEX[d.class] or "FFFFFF"
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:ClearLines()
                GameTooltip:AddLine("|cFF" .. hex .. d.name .. "|r  " .. (CLASS_DISPLAY[d.class] or d.class))
                GameTooltip:AddLine("Average ilvl: |cFFFFD700" .. tostring(d.avg or 0) .. "|r")
                GameTooltip:AddLine(" ")
                for k, slotID in ipairs(EQUIP_SLOTS) do
                    local ilvl     = d.slots and d.slots[slotID]
                    local fullName = SLOT_FULL[k] or ("Slot " .. slotID)
                    if ilvl and ilvl > 0 then
                        GameTooltip:AddDoubleLine(fullName, tostring(ilvl), 0.80,0.80,0.80, 1.0,1.0,0.5)
                    else
                        GameTooltip:AddDoubleLine(fullName, "\226\128\148", 0.80,0.80,0.80, 0.40,0.40,0.40)
                    end
                end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)

            _rowFrames[i] = row
        end

        -- Position and populate
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", _scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_H)
        row:SetWidth(CONTENT_W)
        row._playerData = pdata

        row.altBg:SetVertexColor(1, 1, 1, i % 2 == 0 and 0.05 or 0)

        -- Name
        local hex = CLASS_HEX[pdata.class] or "FFFFFF"
        row.nameFS:SetText("|cFF" .. hex .. pdata.name .. "|r")

        -- Class icon
        SetClassIconTex(row.classTex, pdata.class)

        -- Spec icon
        local specIcon = pdata.specID and GetSpecIconFileID(pdata.specID)
        if specIcon then
            row.specTex:SetTexture(specIcon)
            row.specTex:SetTexCoord(0, 1, 0, 1)
            row.specTex:Show()
        else
            row.specTex:Hide()
        end

        -- Average ilvl colour: green ≤5 below max, yellow ≤15, red >15
        local avg  = pdata.avg or 0
        local diff = maxAvg - avg
        if diff <= 5 then
            row.avgFS:SetTextColor(0.27, 1.00, 0.27)
        elseif diff <= 15 then
            row.avgFS:SetTextColor(1.00, 1.00, 0.27)
        else
            row.avgFS:SetTextColor(1.00, 0.27, 0.27)
        end
        row.avgFS:SetText(tostring(avg))

        -- Slots: icon + ilvl text
        for j, slotID in ipairs(EQUIP_SLOTS) do
            local ilvl = pdata.slots and pdata.slots[slotID]
            local icon = pdata.icons and pdata.icons[slotID]
            if ilvl and ilvl > 0 then
                if icon and icon > 0 then
                    row.slotTex[j]:SetTexture(icon)
                    row.slotTex[j]:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- trim icon border
                    row.slotTex[j]:Show()
                else
                    row.slotTex[j]:Hide()
                end
                row.slotFS[j]:SetText(tostring(ilvl))
                row.slotFS[j]:SetTextColor(0.95, 0.95, 0.95)
            else
                row.slotTex[j]:Hide()
                row.slotFS[j]:SetText("\226\128\148")  -- em dash
                row.slotFS[j]:SetTextColor(0.30, 0.30, 0.30)
            end
        end

        row:Show()
    end

    -- Hide rows beyond current player count
    for i = #sorted + 1, #_rowFrames do
        if _rowFrames[i] then _rowFrames[i]:Hide() end
    end

    local totalH = math.max(CONTAINER_H - SCROLL_Y, #sorted * ROW_H + 4)
    _scrollChild:SetHeight(totalH)

    RefreshStatus()
end

-------------------------------------------------------------------------------
-- Comm
-------------------------------------------------------------------------------

local function EnsureComm()
    if _commReady then return end
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        local ok = pcall(C_ChatInfo.RegisterAddonMessagePrefix, COMM_PREFIX)
        if ok then _commReady = true end
    end
end

local function SendAddon(msg, dist)
    if not dist or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return end
    pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, msg, dist)
end

local function CollectAndSendGear(reqID, dist)
    local avg, slots = CollectOwnGear()
    local name = UnitName("player") or "Unknown"
    local _, classTok = UnitClass("player")
    classTok = classTok or "WARRIOR"
    local specID = GetSelfSpecID()

    -- DAT: DAT\treqID\tname\tclass\tspecID\tavg\tslotsStr
    local msg = "DAT\t" .. reqID .. "\t" .. name .. "\t" .. classTok
                        .. "\t" .. specID .. "\t" .. avg .. "\t" .. SlotsToStr(slots)
    SendAddon(msg, dist)

    -- ICN: ICN\treqID\tname\ticon1|icon2|...|icon16  (FileDataIDs, 0 = empty slot)
    local icons = CollectOwnIcons()
    local icnMsg = "ICN\t" .. reqID .. "\t" .. name .. "\t" .. IconsToStr(icons)
    SendAddon(icnMsg, dist)
end

local function SyncGear()
    local db = EnsureDB(); if not db then return end
    if not CanSync() then
        RRT_Print("Only the raid leader or an assistant can sync gear.")
        return
    end
    EnsureComm()
    wipe(db.players)
    wipe(_pendingIcons)
    db.lastSync = GetTime()
    _reqCounter = (_reqCounter % 9999) + 1
    local reqID = string.format("%d-%04d", math.floor(GetTime() * 1000), _reqCounter)

    local dist = ResolveChannel()
    if dist then
        SendAddon("REQ\t" .. reqID, dist)
    end

    -- Self-report immediately; we won't rely on receiving our own broadcast
    local avg, slots = CollectOwnGear()
    local name = UnitName("player") or "Unknown"
    local _, classTok = UnitClass("player")
    classTok = classTok or "WARRIOR"
    local specID = GetSelfSpecID()
    local icons  = CollectOwnIcons()

    db.players[name] = {
        name=name, class=classTok, specID=specID,
        avg=avg, slots=slots, icons=icons, ts=GetTime()
    }
    RefreshPlayerList()
end

local function HandleComm(_, _, prefix, message, _, sender)
    if prefix ~= COMM_PREFIX then return end
    local db = EnsureDB(); if not db then return end

    local meName      = Ambiguate(UnitName("player") or "", "short")
    local senderShort = Ambiguate(sender or "", "short")

    local cmd = message:match("^(%u%u%u)\t")
    if not cmd then return end

    if cmd == "REQ" then
        -- Skip our own request (self-reported in SyncGear already)
        if senderShort == meName then return end
        local reqID = message:match("^REQ\t(.+)$")
        if not reqID then return end
        local dist = ResolveChannel()
        if dist then CollectAndSendGear(reqID, dist) end

    elseif cmd == "DAT" then
        local parts = {}
        for part in message:gmatch("[^\t]+") do parts[#parts+1] = part end
        -- New format (7 parts): DAT\treqID\tname\tclass\tspecID\tavg\tslotsStr
        -- Old format (6 parts): DAT\treqID\tname\tclass\tavg\tslotsStr
        if #parts < 5 then return end
        local name, classTok, specID, avg, slotsStr
        if #parts >= 7 then
            name     = parts[3]
            classTok = parts[4]
            specID   = tonumber(parts[5]) or 0
            avg      = tonumber(parts[6]) or 0
            slotsStr = parts[7] or ""
        else
            name     = parts[3]
            classTok = parts[4]
            specID   = 0
            avg      = tonumber(parts[5]) or 0
            slotsStr = parts[6] or ""
        end
        local slots    = StrToSlots(slotsStr)
        local existing = db.players[name] or {}
        db.players[name] = {
            name=name, class=classTok, specID=specID,
            avg=avg, slots=slots, icons=(existing.icons or {}), ts=GetTime()
        }
        -- Apply icons that arrived ahead of DAT
        if _pendingIcons[name] then
            db.players[name].icons = _pendingIcons[name]
            _pendingIcons[name] = nil
        end
        RefreshPlayerList()

    elseif cmd == "ICN" then
        local parts = {}
        for part in message:gmatch("[^\t]+") do parts[#parts+1] = part end
        -- ICN\treqID\tname\ticonsStr
        if #parts < 4 then return end
        local name     = parts[3]
        local icons    = StrToIcons(parts[4])
        if db.players[name] then
            db.players[name].icons = icons
            RefreshPlayerList()
        else
            -- Buffer until DAT arrives
            _pendingIcons[name] = icons
        end
    end
end

-------------------------------------------------------------------------------
-- Scrollbar skin (mirrors Note.lua style)
-------------------------------------------------------------------------------

local function SkinScrollBar(sf)
    if not sf then return end
    local sb = sf.ScrollBar
    if not sb then
        for _, ch in ipairs({sf:GetChildren()}) do
            if ch and ch.GetObjectType and ch:GetObjectType() == "Slider" then
                sb = ch; break
            end
        end
    end
    if not sb or sb._rrtSkinned then return end
    sb._rrtSkinned = true
    sb:SetWidth(13)
    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.07, 0.07, 0.08, 0.95)
    local thumb = sb:GetThumbTexture()
    if not thumb then
        thumb = sb:CreateTexture(nil, "ARTWORK")
        sb:SetThumbTexture(thumb)
    end
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetSize(10, 26)
    thumb:SetVertexColor(0.30, 0.72, 1.00, 0.9)
    local function SkinArrow(btn, ch)
        if not btn or btn._rrtArr then return end
        btn._rrtArr = true
        for _, getter in ipairs({"GetNormalTexture","GetHighlightTexture","GetPushedTexture","GetDisabledTexture"}) do
            local tx = btn[getter] and btn[getter](btn); if tx then tx:SetAlpha(0) end
        end
        local abg = btn:CreateTexture(nil, "BACKGROUND")
        abg:SetAllPoints()
        abg:SetTexture("Interface\\Buttons\\WHITE8X8")
        abg:SetVertexColor(0.14, 0.14, 0.15, 0.95)
        local afs = btn:CreateFontString(nil, "OVERLAY")
        afs:SetFont(FONT, 10, "OUTLINE")
        afs:SetPoint("CENTER")
        afs:SetText(ch)
        afs:SetTextColor(0.55, 0.55, 0.55)
        btn:HookScript("OnEnter", function() abg:SetVertexColor(0.22,0.22,0.24,1); afs:SetTextColor(0.30,0.72,1.00) end)
        btn:HookScript("OnLeave", function() abg:SetVertexColor(0.14,0.14,0.15,0.95); afs:SetTextColor(0.55,0.55,0.55) end)
    end
    local sbn = sb.GetName and sb:GetName()
    SkinArrow(sb.ScrollUpButton   or (sbn and _G[sbn .. "ScrollUpButton"]),   "^")
    SkinArrow(sb.ScrollDownButton or (sbn and _G[sbn .. "ScrollDownButton"]), "v")
end

-------------------------------------------------------------------------------
-- BuildRaidInspectUI
-------------------------------------------------------------------------------

local function BuildRaidInspectUI(parent)
    if parent.RaidInspectPanel then
        return parent.RaidInspectPanel
    end

    EnsureComm()

    -- Container (matches BuffReminders dimensions / positioning)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(CONTAINER_W, CONTAINER_H)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -90)
    SkinPanel(container, { 0, 0, 0, 0.2 }, COLOR_BORDER)

    ---------------------------------------------------------------------------
    -- Top bar
    ---------------------------------------------------------------------------
    local topBar = CreateFrame("Frame", nil, container, "BackdropTemplate")
    topBar:SetPoint("TOPLEFT",  container, "TOPLEFT",  0, 0)
    topBar:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    topBar:SetHeight(TOPBAR_H)
    SkinPanel(topBar, COLOR_SECTION, COLOR_BORDER)

    local syncBtn = CreateRRTButton(topBar, "Sync Gear", 120, 26, SyncGear)
    syncBtn:SetPoint("LEFT", topBar, "LEFT", 8, 0)

    local clearBtn = CreateRRTButton(topBar, "Clear", 70, 26, function()
        local db = EnsureDB(); if not db then return end
        wipe(db.players)
        wipe(_pendingIcons)
        RefreshPlayerList()
    end)
    clearBtn:SetPoint("LEFT", syncBtn, "RIGHT", 6, 0)

    _statusLabel = topBar:CreateFontString(nil, "OVERLAY")
    _statusLabel:SetFont(FONT, 10, "")
    _statusLabel:SetPoint("LEFT",  clearBtn, "RIGHT", 10, 0)
    _statusLabel:SetPoint("RIGHT", topBar,   "RIGHT", -8, 0)
    _statusLabel:SetJustifyH("LEFT")
    _statusLabel:SetTextColor(0.65, 0.65, 0.65)
    _statusLabel:SetText("0/0 responded")

    ---------------------------------------------------------------------------
    -- Column header row
    ---------------------------------------------------------------------------
    local headerRow = CreateFrame("Frame", nil, container, "BackdropTemplate")
    headerRow:SetPoint("TOPLEFT", container, "TOPLEFT", SCROLL_PAD, -TOPBAR_H)
    headerRow:SetWidth(CONTENT_W)
    headerRow:SetHeight(HEADER_H)
    SkinPanel(headerRow, COLOR_SECTION, COLOR_BORDER)

    local function AddHeaderLabel(x, w, text, justify)
        local fs = headerRow:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT, 9, "")
        fs:SetPoint("LEFT", headerRow, "LEFT", x, 0)
        fs:SetWidth(w)
        fs:SetJustifyH(justify or "CENTER")
        fs:SetTextColor(0.58, 0.58, 0.58)
        fs:SetText(text)
    end

    AddHeaderLabel(2,                            COL_NAME - 4,      "Player",   "LEFT")
    AddHeaderLabel(COL_NAME + 2,                 COL_CLASSSPEC - 4, "Cls/Spec", "LEFT")
    AddHeaderLabel(COL_NAME + COL_CLASSSPEC + 2, COL_AVG - 4,       "Avg",      "CENTER")
    for k, short in ipairs(SLOT_SHORT) do
        local xOff = COL_NAME + COL_CLASSSPEC + COL_AVG + (k - 1) * COL_SLOT + 2
        AddHeaderLabel(xOff, COL_SLOT - 4, short, "CENTER")
    end

    ---------------------------------------------------------------------------
    -- Scroll frame + child
    ---------------------------------------------------------------------------
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     container, "TOPLEFT",     SCROLL_PAD, -(TOPBAR_H + HEADER_H))
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -26,         4)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur  = self:GetVerticalScroll()
        local ch   = self:GetScrollChild(); if not ch then return end
        local maxS = math.max(0, ch:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, maxS)))
    end)
    if apply_scrollbar_style then
        apply_scrollbar_style(scrollFrame)
    else
        SkinScrollBar(scrollFrame)
    end

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(CONTENT_W)
    scrollChild:SetHeight(CONTAINER_H - SCROLL_Y)
    scrollFrame:SetScrollChild(scrollChild)
    _scrollChild = scrollChild

    -- Reset row pool for this UI instance
    wipe(_rowFrames)

    -- Initial draw
    RefreshPlayerList()

    parent.RaidInspectPanel = container
    return container
end

-------------------------------------------------------------------------------
-- Module-level event handlers (always active, regardless of UI being open)
-------------------------------------------------------------------------------

local _commEvtFrame = CreateFrame("Frame")
_commEvtFrame:RegisterEvent("CHAT_MSG_ADDON")
_commEvtFrame:SetScript("OnEvent", HandleComm)

local _rosterFrame = CreateFrame("Frame")
_rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
_rosterFrame:SetScript("OnEvent", function()
    RefreshStatus()
end)

local _initFrame = CreateFrame("Frame")
_initFrame:RegisterEvent("PLAYER_LOGIN")
_initFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    EnsureDB()
    EnsureComm()
end)

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.RaidInspect = {
    BuildUI = BuildRaidInspectUI,
}
