local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled          = false,
    showOnInstance   = true,
    showOnReadyCheck = true,
    autoHideDelay    = 10,
    iconSize         = 40,
    ecEnabled        = false,
    ecUseAllSpecs    = false,
    ecSpecRules      = {},
    point            = "CENTER",
    x                = 0,
    y                = 100,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Constants
-- ─────────────────────────────────────────────────────────────────────────────
local EQUIPMENT_SLOTS = {
    { id = 13, name = "Trinket 1" },
    { id = 14, name = "Trinket 2" },
    { id = 16, name = "Main Hand" },
    { id = 17, name = "Off Hand"  },
}

local ENCHANTABLE_SLOTS = {
    { id = 1,  name = "Head"      },
    { id = 2,  name = "Neck"      },
    { id = 3,  name = "Shoulder"  },
    { id = 5,  name = "Chest"     },
    { id = 6,  name = "Waist"     },
    { id = 7,  name = "Legs"      },
    { id = 8,  name = "Feet"      },
    { id = 9,  name = "Wrist"     },
    { id = 10, name = "Hands"     },
    { id = 11, name = "Ring 1"    },
    { id = 12, name = "Ring 2"    },
    { id = 15, name = "Back"      },
    { id = 16, name = "Main Hand" },
    { id = 17, name = "Off Hand"  },
}

local SLOT_NAMES = {}
for _, slot in ipairs(ENCHANTABLE_SLOTS) do
    SLOT_NAMES[slot.id] = slot.name
end

-- ─────────────────────────────────────────────────────────────────────────────
-- DB helper
-- ─────────────────────────────────────────────────────────────────────────────
local function GetDB()
    if not RRT or not RRT.EquipmentReminder then return nil end
    return RRT.EquipmentReminder
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Enchant check
-- ─────────────────────────────────────────────────────────────────────────────
local function GetPermanentEnchantFromTooltip(slotID)
    if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then return nil, nil end
    local tooltipData = C_TooltipInfo.GetInventoryItem("player", slotID)
    if not tooltipData or not tooltipData.lines then return nil, nil end
    for _, line in ipairs(tooltipData.lines) do
        if line.type == 15 then return line.leftText, line.enchantID end
    end
    return nil, nil
end

local function GetEnchantName(enchantID)
    if not enchantID or enchantID == 0 then return nil end
    local info = C_Spell.GetSpellInfo(enchantID)
    return info and info.name or nil
end

local function DebugSlotInfo(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Slot " .. slotID .. ": No item equipped")
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r === Slot " .. slotID .. " Debug ===")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Link: " .. link)
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local tooltipData = C_TooltipInfo.GetInventoryItem("player", slotID)
        if tooltipData and tooltipData.lines then
            for i, line in ipairs(tooltipData.lines) do
                local typeStr = line.type and (" [type=" .. line.type .. "]") or ""
                local text = line.leftText or line.rightText or ""
                if text ~= "" then
                    DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. typeStr .. ": " .. text)
                end
                if line.type == 15 then
                    DEFAULT_CHAT_FRAME:AddMessage("    enchantID=" .. tostring(line.enchantID))
                end
            end
        end
    end
end

local function ParseEnchantName(enchantText)
    if not enchantText then return nil end
    local name = enchantText:match("Enchanted: (.+)") or enchantText
    name = name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|A.-|a", "")
    return name
end

local function CheckEnchantMismatches()
    local db = GetDB()
    if not db or not db.ecEnabled then return {} end

    local specRules
    if db.ecUseAllSpecs then
        specRules = db.ecSpecRules and db.ecSpecRules[0]
    else
        local specIndex = GetSpecialization()
        local specID    = specIndex and GetSpecializationInfo(specIndex)
        if not specID then return {} end
        specRules = db.ecSpecRules and db.ecSpecRules[specID]
    end
    if not specRules then return {} end

    local mismatches = {}
    for slotID, expectedData in pairs(specRules) do
        slotID = tonumber(slotID)
        local expectedName = expectedData and expectedData.name
        if slotID and expectedName and expectedName ~= "" then
            if GetInventoryItemID("player", slotID) then
                local enchantText  = GetPermanentEnchantFromTooltip(slotID)
                local equippedName = ParseEnchantName(enchantText)
                local slotName     = SLOT_NAMES[slotID] or ("Slot " .. slotID)

                if not equippedName or equippedName == "" then
                    table.insert(mismatches, { slotID = slotID, slotName = slotName, issue = "missing",
                        equippedName = nil, expectedName = expectedName })
                elseif equippedName ~= expectedName then
                    table.insert(mismatches, { slotID = slotID, slotName = slotName, issue = "wrong",
                        equippedName = equippedName, expectedName = expectedName })
                end
            end
        end
    end
    return mismatches
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Frame construction
-- ─────────────────────────────────────────────────────────────────────────────
local equipmentFrame  = nil
local itemButtons     = {}
local enchantStatusRow = nil
local autoHideTimer   = nil

local function CreateItemButton(parent, slotID, slotName, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button.slotID   = slotID
    button.slotName = slotName

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    button.icon = icon

    -- Custom border (4 textures)
    local borderSize = 2
    button.borderTextures = {}
    local sides = {
        { "TOPLEFT",  "TOPRIGHT",    -borderSize, borderSize,  borderSize, 0          },
        { "BOTTOMLEFT","BOTTOMRIGHT", -borderSize, 0,           borderSize, -borderSize },
        { "TOPLEFT",  "BOTTOMLEFT",  -borderSize, borderSize,  0,          -borderSize },
        { "TOPRIGHT", "BOTTOMRIGHT",  0,           borderSize,  borderSize, -borderSize },
    }
    for i, s in ipairs(sides) do
        local tex = button:CreateTexture(nil, "OVERLAY")
        tex:SetPoint(s[1], button, s[1], s[3], s[4])
        tex:SetPoint(s[2], button, s[2], s[5], s[6])
        tex:SetColorTexture(1, 1, 1, 1)
        button.borderTextures[i] = tex
    end
    button.border = {
        SetVertexColor = function(_, r, g, b, a)
            for _, t in ipairs(button.borderTextures) do t:SetVertexColor(r, g, b, a or 1) end
        end,
        Show = function() for _, t in ipairs(button.borderTextures) do t:Show() end end,
        Hide = function() for _, t in ipairs(button.borderTextures) do t:Hide() end end,
    }

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        if GetInventoryItemID("player", self.slotID) then
            GameTooltip:SetInventoryItem("player", self.slotID)
        else
            GameTooltip:SetText(self.slotName .. " — Empty")
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return button
end

local function UpdateSlot(button)
    local texture = GetInventoryItemTexture("player", button.slotID)
    local quality = GetInventoryItemQuality("player", button.slotID)
    if texture then
        button.icon:SetTexture(texture)
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon:Show()
        if quality and quality >= 0 then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            button.border:SetVertexColor(r, g, b, 1)
            button.border:Show()
        else
            button.border:Hide()
        end
    else
        button.icon:SetTexture(0)
        button.icon:Hide()
        button.border:Hide()
    end
end

local function UpdateEnchantStatus()
    if not enchantStatusRow then return end
    local db = GetDB()
    if not db or not db.ecEnabled then enchantStatusRow:Hide(); return end

    local mismatches = CheckEnchantMismatches()
    if #mismatches == 0 then
        enchantStatusRow.text:SetText("|cFF00FF00Enchants OK|r")
        enchantStatusRow.mismatches = nil
    else
        local n = #mismatches
        enchantStatusRow.text:SetText("|cFFFF6666" .. n .. " Enchant Issue" .. (n > 1 and "s" or "") .. "|r")
        enchantStatusRow.mismatches = mismatches
    end
    enchantStatusRow:Show()
end

local function CreateEquipmentFrame()
    if equipmentFrame then return equipmentFrame end
    local db = GetDB()

    local frame = CreateFrame("Frame", "RRTEquipmentReminder", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    local _tc = RRT and RRT.Settings and RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
    frame:SetBackdropBorderColor(_tc[1], _tc[2], _tc[3], 0.8)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    local function UpdateEquipTitle(r, g, b)
        local hex = string.format("%02X%02X%02X", r*255, g*255, b*255)
        title:SetText("|cFF" .. hex .. "Equipment|r Check")
    end
    UpdateEquipTitle(_tc[1], _tc[2], _tc[3])
    frame.title = title

    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
        frame:SetBackdropBorderColor(r, g, b, 0.8)
        UpdateEquipTitle(r, g, b)
    end)

    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(14, 14)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
    closeBtn:GetHighlightTexture():SetVertexColor(1, 0.4, 0.4, 1)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        if autoHideTimer then autoHideTimer:Cancel(); autoHideTimer = nil end
    end)

    local iconSize = (db and db.iconSize) or 40
    local spacing  = 6
    local totalW   = (#EQUIPMENT_SLOTS * iconSize) + ((#EQUIPMENT_SLOTS - 1) * spacing)
    local frameW   = totalW + 20

    local buttonContainer = CreateFrame("Frame", nil, frame)
    buttonContainer:SetSize(totalW, iconSize)
    buttonContainer:SetPoint("TOP", title, "BOTTOM", 0, -8)

    local startX = -totalW / 2 + iconSize / 2
    for i, slot in ipairs(EQUIPMENT_SLOTS) do
        local btn = CreateItemButton(buttonContainer, slot.id, slot.name, iconSize)
        btn:SetPoint("CENTER", buttonContainer, "CENTER", startX + (i - 1) * (iconSize + spacing), 0)
        itemButtons[i] = btn
    end

    local statusRow = CreateFrame("Frame", nil, frame)
    statusRow:SetSize(frameW - 20, 20)
    statusRow:SetPoint("TOP", buttonContainer, "BOTTOM", 0, -4)
    statusRow:EnableMouse(true)
    local statusText = statusRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("CENTER")
    statusRow.text = statusText
    statusRow:SetScript("OnEnter", function(self)
        if not self.mismatches or #self.mismatches == 0 then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Enchant Issues", 1, 0.4, 0.4)
        GameTooltip:AddLine(" ")
        for _, m in ipairs(self.mismatches) do
            if m.issue == "missing" then
                GameTooltip:AddDoubleLine(m.slotName .. ":", "Missing", 1, 1, 1, 1, 0.4, 0.4)
                GameTooltip:AddDoubleLine("  Expected:", m.expectedName or "?", 0.6, 0.6, 0.6, 0.5, 0.8, 0.5)
            else
                GameTooltip:AddDoubleLine(m.slotName .. ":", "Wrong Enchant", 1, 1, 1, 1, 0.6, 0.2)
                GameTooltip:AddDoubleLine("  Have:", m.equippedName or "?", 0.6, 0.6, 0.6, 1, 0.5, 0.5)
                GameTooltip:AddDoubleLine("  Expected:", m.expectedName or "?", 0.6, 0.6, 0.6, 0.5, 0.8, 0.5)
            end
        end
        GameTooltip:Show()
    end)
    statusRow:SetScript("OnLeave", function() GameTooltip:Hide() end)
    statusRow:Hide()
    enchantStatusRow = statusRow

    frame:SetSize(math.max(frameW, 160), iconSize + 60)

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, _, x, y = self:GetPoint()
        if RRT and RRT.EquipmentReminder then
            RRT.EquipmentReminder.point = p
            RRT.EquipmentReminder.x    = x
            RRT.EquipmentReminder.y    = y
        end
    end)

    frame:Hide()
    equipmentFrame = frame
    return frame
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Show / Hide
-- ─────────────────────────────────────────────────────────────────────────────
local function ShowFrame()
    local db = GetDB()
    if not db or not db.enabled then return end
    if InCombatLockdown() then return end

    local frame = CreateEquipmentFrame()
    frame:ClearAllPoints()
    frame:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 100)

    for _, btn in ipairs(itemButtons) do UpdateSlot(btn) end
    UpdateEnchantStatus()
    frame:Show()

    if autoHideTimer then autoHideTimer:Cancel(); autoHideTimer = nil end
    local delay = db.autoHideDelay or 10
    if delay > 0 then
        autoHideTimer = C_Timer.NewTimer(delay, function()
            if equipmentFrame and equipmentFrame:IsShown() then equipmentFrame:Hide() end
            autoHideTimer = nil
        end)
    end
end

local function HideFrame()
    if equipmentFrame then equipmentFrame:Hide() end
    if autoHideTimer then autoHideTimer:Cancel(); autoHideTimer = nil end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", "RRTEquipmentReminderEvents")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        SLASH_RRTECDEBUG1 = "/ecdebug"
        SlashCmdList["RRTECDEBUG"] = function()
            for _, slot in ipairs(ENCHANTABLE_SLOTS) do DebugSlotInfo(slot.id) end
        end
        SLASH_RRTECCHECK1 = "/eccheck"
        SlashCmdList["RRTECCHECK"] = function()
            local d = GetDB()
            if not d then DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r No DB"); return end
            DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r ecEnabled: " .. tostring(d.ecEnabled))
            DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r ecUseAllSpecs: " .. tostring(d.ecUseAllSpecs))
            local specRules
            if d.ecUseAllSpecs then
                specRules = d.ecSpecRules and d.ecSpecRules[0]
                DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Using shared rules (key 0)")
            else
                local specIndex = GetSpecialization()
                local specID = specIndex and GetSpecializationInfo(specIndex)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Current specID: " .. tostring(specID))
                specRules = d.ecSpecRules and d.ecSpecRules[specID]
            end
            if not specRules then DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r No specRules found!"); return end
            local function ParseName(text)
                if not text then return nil end
                local name = text:match("Enchanted: (.+)") or text
                return name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|A.-|a", "")
            end
            for slotID, expectedData in pairs(specRules) do
                local numSlotID = tonumber(slotID)
                local expectedName = expectedData and expectedData.name
                local enchantText = GetPermanentEnchantFromTooltip(numSlotID)
                local equippedName = ParseName(enchantText)
                local slotName = SLOT_NAMES[numSlotID] or ("Slot " .. tostring(slotID))
                DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r " .. slotName .. " — Expected: [" .. tostring(expectedName) .. "] Equipped: [" .. tostring(equippedName) .. "] Match: " .. tostring(expectedName == equippedName))
            end
        end
        self:UnregisterEvent("PLAYER_LOGIN")
        return
    end

    local db = GetDB()
    if not db or not db.enabled then return end

    if event == "PLAYER_ENTERING_WORLD" then
        if not db.showOnInstance then return end
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
            C_Timer.After(1, function()
                if not InCombatLockdown() then ShowFrame() end
            end)
        end

    elseif event == "READY_CHECK" then
        if not db.showOnReadyCheck then return end
        C_Timer.After(0.2, function()
            if not InCombatLockdown() then ShowFrame() end
        end)

    elseif event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" and equipmentFrame and equipmentFrame:IsShown() then
            for _, btn in ipairs(itemButtons) do UpdateSlot(btn) end
            UpdateEnchantStatus()
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if arg1 == "player" and equipmentFrame and equipmentFrame:IsShown() then
            UpdateEnchantStatus()
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Enchant Rules Panel
-- ─────────────────────────────────────────────────────────────────────────────
local enchantPanel = nil
local enchantChild = nil

local SLOT_NAMES_PANEL = {
    [1]="Head",[2]="Neck",[3]="Shoulder",[5]="Chest",[6]="Waist",
    [7]="Legs",[8]="Feet",[9]="Wrist",[10]="Hands",[11]="Ring 1",
    [12]="Ring 2",[15]="Back",[16]="Main Hand",[17]="Off Hand",
}

local function RebuildEnchantGrid()
    if not enchantChild then return end

    for _, child in ipairs({ enchantChild:GetChildren() }) do child:Hide() end
    for i = 1, enchantChild:GetNumRegions() do
        local r = select(i, enchantChild:GetRegions())
        if r then r:Hide() end
    end

    local db = GetDB()
    local rules = (db and db.ecSpecRules) or {}

    if not next(rules) then
        local t = enchantChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("TOPLEFT", 8, -8)
        t:SetWidth(390)
        t:SetWordWrap(true)
        t:SetJustifyH("LEFT")
        t:SetText("|cFF888888No enchant rules saved yet.\nEquip your gear, then click 'Capture Current Enchants'.|r")
        enchantChild:SetHeight(44)
        return
    end

    local specKeys = {}
    for sid in pairs(rules) do specKeys[#specKeys+1] = tonumber(sid) end
    table.sort(specKeys, function(a, b)
        if a == 0 then return true end
        if b == 0 then return false end
        return a < b
    end)

    local yOff = 0
    local W    = 400

    for _, sid in ipairs(specKeys) do
        local specRules = rules[sid]
        if specRules and next(specRules) then
            local specName
            if sid == 0 then
                specName = "All Specs"
            else
                local _, sname = GetSpecializationInfoByID(sid)
                specName = sname or ("Spec " .. sid)
            end

            local hdr = CreateFrame("Frame", nil, enchantChild, "BackdropTemplate")
            hdr:SetSize(W, 22)
            hdr:SetPoint("TOPLEFT", 0, yOff)
            hdr:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            local _htc = RRT and RRT.Settings and RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
            hdr:SetBackdropColor(_htc[1]*0.3, _htc[2]*0.15, _htc[3]*0.55, 0.8)
            hdr:Show()
            local hLabel = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            hLabel:SetPoint("LEFT", 8, 0)
            local _hhex = string.format("%02X%02X%02X", _htc[1]*255, _htc[2]*255, _htc[3]*255)
            hLabel:SetText("|cFF" .. _hhex .. specName .. "|r")
            yOff = yOff - 24

            local slotIDs = {}
            for slotID in pairs(specRules) do slotIDs[#slotIDs+1] = tonumber(slotID) end
            table.sort(slotIDs)

            for _, slotID in ipairs(slotIDs) do
                local ruleData = specRules[slotID]
                if ruleData then
                    local row = CreateFrame("Frame", nil, enchantChild, "BackdropTemplate")
                    row:SetSize(W, 22)
                    row:SetPoint("TOPLEFT", 0, yOff)
                    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
                    row:SetBackdropColor(0.08, 0.08, 0.12, 0.6)
                    row:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
                    row:Show()

                    local slotLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    slotLbl:SetPoint("LEFT", 8, 0)
                    slotLbl:SetWidth(80)
                    slotLbl:SetJustifyH("LEFT")
                    slotLbl:SetText("|cFFAAAAAA" .. (SLOT_NAMES_PANEL[slotID] or ("Slot " .. slotID)) .. ":|r")

                    local enchLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    enchLbl:SetPoint("LEFT", slotLbl, "RIGHT", 4, 0)
                    enchLbl:SetPoint("RIGHT", row, "RIGHT", -30, 0)
                    enchLbl:SetJustifyH("LEFT")
                    enchLbl:SetText("|cFF00CC44" .. (ruleData.name or "?") .. "|r")

                    local delBtn = CreateFrame("Button", nil, row)
                    delBtn:SetSize(22, 18)
                    delBtn:SetPoint("RIGHT", -4, 0)
                    delBtn:SetNormalFontObject("GameFontNormalSmall")
                    delBtn:SetText("|cFFFF4444X|r")
                    local cSid, cSlotID = sid, slotID
                    delBtn:SetScript("OnClick", function()
                        local db2 = GetDB()
                        if db2 and db2.ecSpecRules and db2.ecSpecRules[cSid] then
                            db2.ecSpecRules[cSid][cSlotID] = nil
                            if not next(db2.ecSpecRules[cSid]) then
                                db2.ecSpecRules[cSid] = nil
                            end
                            RebuildEnchantGrid()
                        end
                    end)

                    yOff = yOff - 24
                end
            end
        end
    end

    enchantChild:SetHeight(math.max(1, math.abs(yOff)))
end

local function CreateEnchantPanel()
    if enchantPanel then return enchantPanel end

    local frame = CreateFrame("Frame", "RRTEnchantRulesPanel", UIParent, "BackdropTemplate")
    frame:SetSize(440, 420)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetPoint("CENTER", UIParent, "CENTER", 100, 0)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    local _tc2 = RRT and RRT.Settings and RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
    frame:SetBackdropBorderColor(_tc2[1], _tc2[2], _tc2[3], 0.8)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    local function UpdateEnchantTitle(r, g, b)
        local hex = string.format("%02X%02X%02X", r*255, g*255, b*255)
        title:SetText("|cFF" .. hex .. "Enchant Rules|r")
    end
    UpdateEnchantTitle(_tc2[1], _tc2[2], _tc2[3])

    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
        frame:SetBackdropBorderColor(r, g, b, 0.8)
        UpdateEnchantTitle(r, g, b)
    end)

    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(14, 14)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    closeBtn:GetNormalTexture():SetVertexColor(1, 0.15, 0.15, 1)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Capture button
    local captureBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    captureBtn:SetSize(180, 24)
    captureBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    captureBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    captureBtn:SetBackdropColor(0.08, 0.22, 0.08, 0.9)
    captureBtn:SetBackdropBorderColor(0.3, 0.6, 0.3, 0.9)
    local capLbl = captureBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    capLbl:SetPoint("CENTER")
    capLbl:SetText("Capture Current Enchants")
    captureBtn:SetScript("OnClick", function()
        local m = RRT_NS.EquipmentReminder
        if not m then return end
        local count = m:CaptureEnchants()
        RebuildEnchantGrid()
        local msg = count > 0
            and ("|cFFBB66FFRRT:|r Captured " .. count .. " enchant rule(s).")
            or  "|cFFBB66FFRRT:|r No permanent enchants found on enchantable slots."
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end)
    captureBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Capture Current Enchants", 1, 1, 1)
        GameTooltip:AddLine("Scans all enchantable slots and saves the current\nenchant names as expected rules for your spec.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    captureBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local modeLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLbl:SetPoint("LEFT", captureBtn, "RIGHT", 8, 0)
    modeLbl:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    modeLbl:SetJustifyH("LEFT")
    frame.modeLbl = modeLbl

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", "RRTEnchantRulesScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     4,   -62)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22,  10)

    local child = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(child)
    child:SetWidth(406)
    enchantChild = child

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    frame:SetScript("OnShow", function(self)
        local db = GetDB()
        if db then
            if db.ecUseAllSpecs then
                self.modeLbl:SetText("|cFFAAAAAA(Mode: All Specs)|r")
            else
                local specIndex = GetSpecialization()
                local specID    = specIndex and GetSpecializationInfo(specIndex)
                local _, sname  = specID and GetSpecializationInfoByID(specID) or nil, nil
                self.modeLbl:SetText("|cFFAAAAAA(Mode: " .. (sname or "Current Spec") .. ")|r")
            end
        end
        RebuildEnchantGrid()
    end)

    frame:Hide()
    enchantPanel = frame
    return frame
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS    = DEFAULTS
module.ShowFrame   = ShowFrame
module.HideFrame   = HideFrame

function module:Enable()
    -- nothing on startup
end

function module:UpdateDisplay()
    local db = GetDB()
    if not db or not db.enabled then HideFrame() end
end

function module:CaptureEnchants()
    local db = GetDB()
    if not db then return 0 end

    local specID
    if db.ecUseAllSpecs then
        specID = 0
    else
        local specIndex = GetSpecialization()
        specID = specIndex and GetSpecializationInfo(specIndex)
        if not specID then return 0 end
    end

    db.ecSpecRules = db.ecSpecRules or {}
    db.ecSpecRules[specID] = db.ecSpecRules[specID] or {}

    local count = 0
    for _, slot in ipairs(ENCHANTABLE_SLOTS) do
        if GetInventoryItemID("player", slot.id) then
            local enchantText = GetPermanentEnchantFromTooltip(slot.id)
            if enchantText then
                local name = ParseEnchantName(enchantText)
                if name and name ~= "" then
                    db.ecSpecRules[specID][slot.id] = { name = name }
                    count = count + 1
                end
            end
        end
    end
    return count
end

function module:ToggleEnchantPanel()
    local panel = CreateEnchantPanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

-- Export
RRT_NS.EquipmentReminder = module
