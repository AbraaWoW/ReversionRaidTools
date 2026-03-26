local _, RRT_NS = ...

local MAX_ROWS     = 40
local ROW_HEIGHT   = 22
local FRAME_WIDTH  = 160
local ICON_SIZE    = 20
local PADDING      = 3
local HEADER_H     = 22

local MAX_DBF_SLOTS  = 8   -- must match RaidFrame.MAX_DBF_SLOTS
local DBF_ICON_SZ    = 14  -- default icon size (overridden by setting at runtime)
local DBF_GAP        = 2   -- gap between slots

local ROLE_ICON_TEX = "Interface\\LFGFRAME\\UI-LFG-ICON-ROLES"
local ROLE_TEXCOORD = {
    TANK    = {0/256,  66/256, 67/256, 132/256},
    HEALER  = {67/256, 132/256, 0/256,  66/256},
    DAMAGER = {67/256, 132/256, 67/256, 132/256},
}

local function BuildRaidFrameUI()
    local RF = RRT_NS.RaidFrame
    local s  = RRT.Settings.RaidFrame

    -- ── Main frame ──────────────────────────────────────────────────────────
    local frame = CreateFrame("Frame", "RRTRaidFrameDisplay", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    frame:SetBackdropColor(0.05, 0.05, 0.08, s.bgAlpha or 0.85)

    -- Restore saved position
    local pos = s.position
    frame:SetPoint(pos.point or "TOPLEFT", UIParent, pos.point or "TOPLEFT", pos.x or 200, pos.y or -200)

    -- Drag
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not RRT.Settings.RaidFrame.locked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        RRT.Settings.RaidFrame.position = { point = point, x = x, y = y }
    end)

    -- ── Header ──────────────────────────────────────────────────────────────
    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_H)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    header:SetBackdropColor(0.15, 0.05, 0.25, 0.95)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("LEFT", header, "LEFT", 6, 0)
    title:SetText("|cFFBB66FFRaid Frame|r")

    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -3, 0)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- ── Row container ────────────────────────────────────────────────────────
    local rowCont = CreateFrame("Frame", nil, frame)
    rowCont:SetPoint("TOPLEFT",     header, "BOTTOMLEFT",  0, -1)
    rowCont:SetPoint("BOTTOMRIGHT", frame,  "BOTTOMRIGHT", 0,  0)

    -- ── Pre-create rows ──────────────────────────────────────────────────────
    -- Name width uses full bar interior (debuffs are now OUTSIDE the bar to the right)
    local NAME_W = FRAME_WIDTH - ICON_SIZE - PADDING * 2 - 4

    local rows = {}
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Frame", nil, rowCont)
        row:SetSize(FRAME_WIDTH, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", rowCont, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        row:Hide()

        -- Class icon
        local classIcon = row:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(ICON_SIZE, ICON_SIZE)
        classIcon:SetPoint("LEFT", row, "LEFT", PADDING, 0)
        row.classIcon = classIcon

        -- Role icon (same size/position as class icon, shown instead of it)
        local roleIco = row:CreateTexture(nil, "ARTWORK")
        roleIco:SetSize(ICON_SIZE, ICON_SIZE)
        roleIco:SetPoint("LEFT", row, "LEFT", PADDING, 0)
        roleIco:Hide()
        row.roleIco = roleIco

        -- Player name (full width, debuffs are outside the bar)
        local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameFS:SetPoint("LEFT", classIcon, "RIGHT", 4, 0)
        nameFS:SetWidth(NAME_W)
        nameFS:SetJustifyH("LEFT")
        row.nameFS = nameFS

        -- Debuff slots: parented to rowCont so they render OUTSIDE the row bar
        -- Slot 1 is closest to the bar, subsequent slots stack further right.
        -- Positions and sizes are updated dynamically in Refresh() from settings.
        row.dbfSlots = {}
        for sl = 1, MAX_DBF_SLOTS do
            -- Container frame (parented to rowCont, not row, to avoid clipping)
            local sf = CreateFrame("Frame", nil, rowCont)
            sf:SetSize(DBF_ICON_SZ, DBF_ICON_SZ)
            sf:SetPoint("LEFT", row, "RIGHT", PADDING + (sl - 1) * (DBF_ICON_SZ + DBF_GAP), 0)
            sf:Hide()

            local ico = sf:CreateTexture(nil, "ARTWORK")
            ico:SetAllPoints(sf)
            ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Count text appears to the RIGHT of the icon
            local cnt = sf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cnt:SetPoint("LEFT", sf, "RIGHT", 2, 0)
            cnt:SetTextColor(1, 0.9, 0, 1)
            cnt:Hide()

            row.dbfSlots[sl] = { ico = ico, cnt = cnt, sf = sf }
        end

        rows[i] = row
    end

    -- ── Pulse effect on debuff icons ─────────────────────────────────────────
    -- Placed AFTER rows is created so the closure captures it as an upvalue.
    local _pulseTime  = 0
    local _pulseDelta = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        if not RRT.Settings.RaidFrame.debuffPulse then return end
        _pulseDelta = _pulseDelta + elapsed
        if _pulseDelta < 0.033 then return end  -- cap at ~30 fps
        _pulseTime  = _pulseTime + _pulseDelta
        _pulseDelta = 0
        -- Oscillate green+blue channels: 0.15 (red) → 1.0 (normal), ~1.3s cycle
        local t  = (math.sin(_pulseTime * math.pi * 1.5) + 1) * 0.5
        local gb = 0.15 + t * 0.85
        for i = 1, MAX_ROWS do
            local row = rows[i]
            if row:IsShown() then
                for sl = 1, MAX_DBF_SLOTS do
                    local slot = row.dbfSlots[sl]
                    if slot.sf:IsShown() then
                        slot.ico:SetVertexColor(1, gb, gb)
                    end
                end
            end
        end
    end)

    -- Pre-allocated scratch tables reused every Refresh() to avoid GC pressure
    local _visibleBuf = {}
    local _revBuf     = {}
    local _unitBuf    = {}

    -- ── Refresh ──────────────────────────────────────────────────────────────
    function frame:Refresh()
        local cfg     = RRT.Settings.RaidFrame
        local showAll = cfg.showAll
        local data    = RRT_NS.RaidFrame:GetData()

        -- Header show/hide
        header:SetShown(not cfg.hideHeader)
        rowCont:ClearAllPoints()
        if cfg.hideHeader then
            rowCont:SetPoint("TOPLEFT",     frame, "TOPLEFT",     0,  0)
            rowCont:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0,  0)
        else
            rowCont:SetPoint("TOPLEFT",     header, "BOTTOMLEFT",  0, -1)
            rowCont:SetPoint("BOTTOMRIGHT", frame,  "BOTTOMRIGHT", 0,  0)
        end

        -- Filter (reuse buffer)
        local visCount = 0
        for _, e in ipairs(data) do
            if showAll or #e.debuffs > 0 then
                visCount = visCount + 1
                _visibleBuf[visCount] = e
            end
        end
        -- Clear stale tail entries from previous longer refresh
        for i = visCount + 1, #_visibleBuf do _visibleBuf[i] = nil end
        local visible = _visibleBuf

        -- Sort by role: TANK > HEALER > DAMAGER > NONE
        if cfg.sortByRole then
            table.sort(visible, function(a, b)
                return (a.roleOrder or 4) < (b.roleOrder or 4)
            end)
        end

        -- Move the player's own row to position 1 only when not sorting by role
        if not cfg.sortByRole then
            for i = 2, visCount do
                if UnitIsUnit(visible[i].unit, "player") then
                    local me = table.remove(visible, i)
                    table.insert(visible, 1, me)
                    break
                end
            end
        end

        -- growUp: reverse list so player row ends up at the bottom (frame anchor = BOTTOMLEFT)
        if cfg.growUp then
            for i = 1, visCount do _revBuf[i] = visible[visCount - i + 1] end
            for i = visCount + 1, #_revBuf do _revBuf[i] = nil end
            visible = _revBuf
        end

        -- Debuff icon size (dynamic from setting)
        local iconSz   = cfg.dbfIconSize or DBF_ICON_SZ
        local slotStep = iconSz + DBF_GAP

        local count = visCount
        for i = 1, MAX_ROWS do
            local row   = rows[i]
            local entry = visible[i]
            if entry then
                -- Class icon vs Role icon (mutually exclusive)
                if cfg.showRoleIcons then
                    local coords = ROLE_TEXCOORD[entry.role]
                    if coords then
                        row.roleIco:SetTexture(ROLE_ICON_TEX)
                        row.roleIco:SetTexCoord(unpack(coords))
                        row.roleIco:Show()
                        row.classIcon:Hide()
                    else
                        -- No role assigned: fallback to class icon
                        row.classIcon:SetAtlas("classicon-" .. strlower(entry.class), false)
                        row.classIcon:Show()
                        row.roleIco:Hide()
                    end
                else
                    row.classIcon:SetAtlas("classicon-" .. strlower(entry.class), false)
                    row.classIcon:Show()
                    row.roleIco:Hide()
                end

                -- Name with class color
                local col = RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
                row.nameFS:SetTextColor(col and col.r or 1, col and col.g or 1, col and col.b or 1, 1)
                row.nameFS:SetText(entry.name)

                -- Debuff slots (icons outside the bar, left or right depending on setting)
                for sl = 1, MAX_DBF_SLOTS do
                    local slot = row.dbfSlots[sl]
                    -- Update size and position from current setting
                    slot.sf:SetSize(iconSz, iconSz)
                    slot.sf:ClearAllPoints()
                    if cfg.aurasOnLeft then
                        slot.sf:SetPoint("RIGHT", row, "LEFT", -(PADDING + (sl - 1) * slotStep), 0)
                    else
                        slot.sf:SetPoint("LEFT", row, "RIGHT", PADDING + (sl - 1) * slotStep, 0)
                    end

                    local aura = cfg.showDebuffs and entry.debuffs[sl]
                    if aura then
                        local iconOk = pcall(function()
                            slot.ico:SetTexture(aura.icon)
                            slot.sf:Show()
                            local apps = aura.applications or 0
                            if apps > 1 then
                                slot.cnt:SetText(apps)
                                slot.cnt:Show()
                            else
                                slot.cnt:Hide()
                            end
                        end)
                        if not iconOk then
                            slot.sf:Hide()
                            slot.cnt:Hide()
                        end
                    else
                        slot.ico:SetTexture(nil)
                        slot.ico:SetVertexColor(1, 1, 1)
                        slot.sf:Show()
                        slot.cnt:Hide()
                    end
                end

                row:Show()
            else
                row:Hide()
                -- Also hide all debuff slots for this row (parented to rowCont)
                for sl = 1, MAX_DBF_SLOTS do
                    row.dbfSlots[sl].sf:Hide()
                    row.dbfSlots[sl].cnt:Hide()
                end
            end
        end

        -- Rebuild PA anchors when unit-to-row mapping changes or explicitly requested
        local RF = RRT_NS.RaidFrame
        for i = 1, count do _unitBuf[i] = visible[i].unit end
        for i = count + 1, #_unitBuf do _unitBuf[i] = nil end
        local unitKey = table.concat(_unitBuf)
        if unitKey ~= (RF._lastUnitKey or "") or RF._needsPARebuild then
            RF._lastUnitKey    = unitKey
            RF._needsPARebuild = false
            RF:RebuildPAAnchors(visible, rows)
        end

        -- Scale
        frame:SetScale(cfg.barScale or 1.0)

        -- Update background alpha
        frame:SetBackdropColor(0.05, 0.05, 0.08, cfg.bgAlpha or 0.85)

        -- Dynamic height (bar width only; debuffs extend right outside frame)
        local headerH = cfg.hideHeader and 0 or HEADER_H
        local totalH = math.max(1, count) * ROW_HEIGHT + headerH + 2
        frame:SetSize(FRAME_WIDTH + PADDING * 2, totalH)
        rowCont:SetHeight(count * ROW_HEIGHT)
    end

    if s.enabled then
        frame:Refresh()
    else
        frame:Hide()
    end

    RF.frame = frame
    return frame
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.RaidFrame = {
    BuildRaidFrameUI = BuildRaidFrameUI,
}
