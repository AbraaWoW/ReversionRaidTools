local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core = RRT_NS.UI.Core
local RRTUI = Core.RRTUI

function RRT_NS:UpdateQoLTextDisplay()
    if self.IsBuilding then return end
    if self.IsQoLTextPreview then
        self:ToggleQoLTextPreview()
        return
    end
    self:CreateQoLTextDisplay()
    local F = self.RRTFrame.QoLText
    F:ClearAllPoints()
    F:SetPoint(RRT.QoL.TextDisplay.Anchor, self.RRTFrame, RRT.QoL.TextDisplay.relativeTo, RRT.QoL.TextDisplay.xOffset, RRT.QoL.TextDisplay.yOffset)
    F.text:SetFont(self.LSM:Fetch("font", RRT.Settings.GlobalFont), RRT.QoL.TextDisplay.FontSize, "OUTLINE")
    local text = ""
    local now = GetTime()
    for _, v in pairs(self.QoLTextDisplays or {}) do -- table structure: {SettingsName = string, text = string}
        if RRT.QoL[v.SettingsName] then
            text = text..v.text.."\n"
        end
    end
    F.text:SetText(text)
    if text == "" then
        F:Hide()
    else
        F:Show()
        F:SetSize(F.text:GetStringWidth(), F.text:GetStringHeight())
    end
end

function RRT_NS:CreateQoLTextDisplay()
    if self.RRTFrame.QoLText then return end
    self.RRTFrame.QoLText = CreateFrame("Frame", nil, self.RRTFrame, "BackdropTemplate")
    self.RRTFrame.QoLText.text = self.RRTFrame.QoLText:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local F = self.RRTFrame.QoLText
    F:SetPoint(RRT.QoL.TextDisplay.Anchor, self.RRTFrame, RRT.QoL.TextDisplay.relativeTo, RRT.QoL.TextDisplay.xOffset, RRT.QoL.TextDisplay.yOffset)
    F:SetFrameStrata("DIALOG")
    F.text:SetFont(self.LSM:Fetch("font", RRT.Settings.GlobalFont), RRT.QoL.TextDisplay.FontSize, "OUTLINE")
    F.text:SetPoint("TOP", F, "TOP", 0, 0)
    F.text:SetTextColor(1, 1, 1, 1)
    F.Border = CreateFrame("Frame", nil, F, "BackdropTemplate")
    F.Border:SetPoint("TOPLEFT", F, "TOPLEFT", -6, 6)
    F.Border:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", 6, -6)
    F.Border:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            tileSize = 0,
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
    F.Border:SetBackdropBorderColor(1, 1, 1, 1)
    F.Border:SetBackdropColor(0, 0, 0, 0)
    F.Border:Hide()
    F.Border:SetFrameStrata("DIALOG")
    F:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    F:SetScript("OnDragStop", function(Frame)
        self:StopFrameMove(Frame, RRT.QoL.TextDisplay)
    end)
end

function RRT_NS:ToggleQoLTextPreview()
    if self.IsQoLTextPreview then
        self:CreateQoLTextDisplay()
        local GatewayIcon = "\124T"..C_Spell.GetSpellTexture(111771)..":12:12:0:0:64:64:4:60:4:60\124t"
        local ResetBossIcon = "\124T"..C_Spell.GetSpellTexture(57724)..":12:12:0:0:64:64:4:60:4:60\124t"
        local CrestIcon = "\124T"..C_CurrencyInfo.GetCurrencyInfo(3347).iconFileID..":12:12:0:0:64:64:4:60:4:60\124t"
        local PrevieWTexts = {
            "This is a preview of the QoL Text Display.",
            RRT.QoL.GatewayUseableDisplay and GatewayIcon.."Gateway Useable"..GatewayIcon or "",
            RRT.QoL.ResetBossDisplay and ResetBossIcon.."Reset Boss"..ResetBossIcon or "",
            RRT.QoL.LootBossReminder and CrestIcon.."Loot Boss"..CrestIcon or "",
            "All enabled Text Displays will show here.",
        }
        local text = ""
        for _, v in ipairs(PrevieWTexts) do -- table structure: {enabled = bool, text = string}
            if v ~= "" then
                text = text..v.."\n"
            end
        end
        local F = self.RRTFrame.QoLText
        F.text:SetText(text)
        F.text:SetFont(self.LSM:Fetch("font", RRT.Settings.GlobalFont), RRT.QoL.TextDisplay.FontSize, "OUTLINE")
        F:SetSize(F.text:GetStringWidth(), F.text:GetStringHeight())
        F:Show()
        self:ToggleMoveFrames(F, true)
    else
        self:ToggleMoveFrames(self.RRTFrame.QoLText)
        self:UpdateQoLTextDisplay()
    end
end




local SUB_BTN_HEIGHT = 20
local SUB_BTN_WIDTH  = 110
local SUB_BTN_PAD    = 4

local function BuildSubNav(parent, subDefs)
    local subPanels = {}
    local subActive = nil

    local function SelectSub(key, btn)
        for k, p in pairs(subPanels) do p:SetShown(k == key) end
        if subActive then
            subActive:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            subActive:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
        end
        local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        btn:SetBackdropColor(c[1]*0.4, c[2]*0.4, c[3]*0.4, 0.8)
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        subActive = btn
    end

    for i, def in ipairs(subDefs) do
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(SUB_BTN_WIDTH, SUB_BTN_HEIGHT)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", SUB_BTN_PAD + (i - 1) * (SUB_BTN_WIDTH + 4), -SUB_BTN_PAD)
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then label:SetFont(f, 9, fl or "") end end
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        label:SetText(def.name)
        label:SetTextColor(0.9, 0.9, 0.9, 1)

        local subPanel = CreateFrame("Frame", "RRTQoLHUDSub_" .. def.key, parent)
        subPanel:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0, -(SUB_BTN_HEIGHT + SUB_BTN_PAD * 2 + 4))
        subPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
        subPanel:Hide()
        subPanels[def.key] = subPanel

        local key = def.key
        btn:SetScript("OnClick", function(self) SelectSub(key, self) end)
        btn:SetScript("OnEnter", function(self)
            if subActive ~= self then self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end
        end)
        btn:SetScript("OnLeave", function(self)
            if subActive ~= self then self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end
        end)

        if i == 1 then SelectSub(key, btn) end
    end

    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
        if subActive then
            subActive:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
            subActive:SetBackdropBorderColor(r, g, b, 1)
        end
    end)

    return subPanels
end

local function BuildQoLUI(parent)
    local DF           = _G["DetailsFramework"]
    local Core         = RRT_NS.UI.Core
    local window_height        = Core.window_height
    local options_text_template     = Core.options_text_template
    local options_dropdown_template = Core.options_dropdown_template
    local options_switch_template   = Core.options_switch_template
    local options_slider_template   = Core.options_slider_template
    local options_button_template   = Core.options_button_template
    local L = RRT_NS.L

    local SIDEBAR_WIDTH    = 130
    local SIDEBAR_PADDING  = 4
    local SIDEBAR_ITEM_H   = 20

    -- Breadcrumb
    local breadcrumb = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    breadcrumb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -76)
    breadcrumb:SetText("|cFFBB66FF" .. L["qol_general"] .. "|r")

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",    parent, "TOPLEFT",    4, -100)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4,   22)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    -- Content area
    local contentArea = CreateFrame("Frame", nil, parent)
    contentArea:SetPoint("TOPLEFT",     parent, "TOPLEFT",     SIDEBAR_WIDTH + 8, -100)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4,                  22)

    local SECTIONS = {
        { name = L["qol_general"],    key = "general"    },
        { name = L["qol_hud"],        key = "hud"        },
        { name = L["qol_combat"],     key = "combat"     },
        { name = L["qol_reminders"],  key = "reminders"  },
        { name = L["qol_mplus"],      key = "mplus"      },
    }

    -- Content panels
    local panels = {}
    for _, section in ipairs(SECTIONS) do
        local panel = CreateFrame("Frame", "RRTQoLSection_" .. section.key, contentArea)
        panel:SetAllPoints(contentArea)
        panel:Hide()
        panels[section.key] = panel
    end

    -- Build General panel
    local Opt = RRT_NS.UI.Options.QoL
    DF:BuildMenu(panels["general"], Opt.BuildOptions(), 10, -10,
        window_height - 10, false,
        options_text_template, options_dropdown_template, options_switch_template,
        true, options_slider_template, options_button_template, Opt.BuildCallback())

    -- Build HUD panel with sub-tabs
    -- Available height: window_height(640) - sidebar top(100) - sidebar bottom(22) - subnav(32) - padding(10) ≈ 476
    local subMenuHeight = window_height - 164
    local hudSubDefs = {
        { name = L["qol_hud_mousering"],  key = "mousering"  },
        { name = L["qol_hud_trail"],      key = "trail"      },
        { name = L["qol_hud_crosshair"],  key = "crosshair"  },
        { name = L["qol_hud_dragonride"], key = "dragonride" },
        { name = L["qol_hud_durability"], key = "durability" },
        { name = L["qol_hud_tooltip"],    key = "tooltip"    },
        { name = L["qol_hud_questing"],   key = "questing"   },
    }
    local hudSubPanels = BuildSubNav(panels["hud"], hudSubDefs)

    local OptCH = RRT_NS.UI.Options.Crosshair
    if OptCH then
        DF:BuildMenu(hudSubPanels["crosshair"], OptCH.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptCH.BuildCallback())
    end

    local OptDU = RRT_NS.UI.Options.Durability
    if OptDU then
        DF:BuildMenu(hudSubPanels["durability"], OptDU.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptDU.BuildCallback())
    end

    local OptDR = RRT_NS.UI.Options.Dragonriding
    if OptDR then
        DF:BuildMenu(hudSubPanels["dragonride"], OptDR.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptDR.BuildCallback())
    end

    local OptTT = RRT_NS.UI.Options.Tooltip
    if OptTT then
        DF:BuildMenu(hudSubPanels["tooltip"], OptTT.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptTT.BuildCallback())
    end

    local OptQT = RRT_NS.UI.Options.Questing
    if OptQT then
        DF:BuildMenu(hudSubPanels["questing"], OptQT.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptQT.BuildCallback())
    end

    local OptMR = RRT_NS.UI.Options.MouseRing
    if OptMR then
        DF:BuildMenu(hudSubPanels["mousering"], OptMR.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptMR.BuildCallback())
        DF:BuildMenu(hudSubPanels["trail"], OptMR.BuildTrailOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptMR.BuildCallback())
    end

    -- Build Combat panel with sub-tabs
    local combatSubDefs = {
        { name = L["qol_combat_combattime"],   key = "combattime"   },
        { name = L["qol_combat_combatalert"],  key = "combatalert"  },
        { name = L["qol_combat_combatlogger"], key = "combatlogger" },
        { name = L["qol_combat_battlerez"],    key = "battlerez"    },
        { name = L["qol_combat_pettracker"],   key = "pettracker"   },
        { name = L["qol_combat_dontrelease"],  key = "dontrelease"  },
    }
    local combatSubPanels = BuildSubNav(panels["combat"], combatSubDefs)

    local OptCT = RRT_NS.UI.Options.CombatTime
    if OptCT then
        DF:BuildMenu(combatSubPanels["combattime"], OptCT.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptCT.BuildCallback())
    end

    local OptCA = RRT_NS.UI.Options.CombatAlert
    if OptCA then
        DF:BuildMenu(combatSubPanels["combatalert"], OptCA.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptCA.BuildCallback())
    end

    local OptCL = RRT_NS.UI.Options.CombatLogger
    if OptCL then
        DF:BuildMenu(combatSubPanels["combatlogger"], OptCL.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptCL.BuildCallback())
    end

    local OptBR = RRT_NS.UI.Options.BattleRez
    if OptBR then
        DF:BuildMenu(combatSubPanels["battlerez"], OptBR.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptBR.BuildCallback())
    end

    local OptPT = RRT_NS.UI.Options.PetTracker
    if OptPT then
        DF:BuildMenu(combatSubPanels["pettracker"], OptPT.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptPT.BuildCallback())
    end

    local OptDR2 = RRT_NS.UI.Options.DontRelease
    if OptDR2 then
        DF:BuildMenu(combatSubPanels["dontrelease"], OptDR2.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptDR2.BuildCallback())
    end

    -- Build Reminders panel with sub-tabs
    local remindersSubDefs = {
        { name = L["qol_reminders_talent"],    key = "talent"    },
        { name = L["qol_reminders_equipment"], key = "equipment" },
    }
    local remindersSubPanels = BuildSubNav(panels["reminders"], remindersSubDefs)

    local OptTR = RRT_NS.UI.Options.TalentReminder
    if OptTR then
        -- Enable toggle only via DF:BuildMenu
        DF:BuildMenu(remindersSubPanels["talent"], OptTR.BuildOptions(), 10, -10,
            40, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptTR.BuildCallback())

        local talentPanel = remindersSubPanels["talent"]

        -- Description (single line, below toggle)
        local trDesc = talentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        trDesc:SetPoint("TOPLEFT",  talentPanel, "TOPLEFT",  34,  -38)
        trDesc:SetPoint("TOPRIGHT", talentPanel, "TOPRIGHT", -10, -38)
        trDesc:SetText("|cFFAAAAAA On each Mythic+ entry, your talents are compared to the saved build. A popup lets you swap, overwrite or ignore.|r")
        trDesc:SetJustifyH("LEFT")

        -- ── Saved Loadouts ────────────────────────────────────────────────────
        local loHeader = talentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        loHeader:SetPoint("TOPLEFT", talentPanel, "TOPLEFT", 10, -62)
        loHeader:SetText("|cFFFF9900Saved Loadouts|r")

        local loBox = CreateFrame("Frame", nil, talentPanel, "BackdropTemplate")
        loBox:SetPoint("TOPLEFT",     talentPanel, "TOPLEFT",     10,  -80)
        loBox:SetPoint("BOTTOMRIGHT", talentPanel, "BOTTOMRIGHT", -10,  52)
        loBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        loBox:SetBackdropColor(0.05, 0.05, 0.08, 0.6)
        loBox:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.6)

        -- Native ScrollFrame — no dependency on loBox dimensions at creation time
        local loScroll = CreateFrame("ScrollFrame", "RRTTalentLoadoutScroll", loBox, "UIPanelScrollFrameTemplate")
        loScroll:SetPoint("TOPLEFT",     loBox, "TOPLEFT",     4,  -4)
        loScroll:SetPoint("BOTTOMRIGHT", loBox, "BOTTOMRIGHT", -22, 4)

        local loChild = CreateFrame("Frame", nil, loScroll)
        loScroll:SetScrollChild(loChild)
        loChild:SetWidth(loScroll:GetWidth() > 0 and loScroll:GetWidth() or 300)

        local function RebuildTalentLoadouts()
            -- hide all previous children
            for _, child in ipairs({ loChild:GetChildren() }) do child:Hide() end
            for i = 1, loChild:GetNumRegions() do
                local r = select(i, loChild:GetRegions())
                if r then r:Hide() end
            end

            local d = RRT and RRT.TalentReminder
            local loadouts = d and d.loadouts or {}

            -- empty state
            if not next(loadouts) then
                local t = loChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                t:SetPoint("TOPLEFT", 8, -8)
                t:SetText("|cFF888888No saved builds yet.|r")
                loChild:SetHeight(30)
                return
            end

            -- group by spec
            local specGroups = {}
            for key, entry in pairs(loadouts) do
                local sid = tonumber(key:match("^(%d+):")) or 0
                specGroups[sid] = specGroups[sid] or {}
                specGroups[sid][key] = entry
            end
            local specIDs = {}
            for sid in pairs(specGroups) do specIDs[#specIDs+1] = sid end
            table.sort(specIDs)

            local yOff = 0
            local W = loScroll:GetWidth() - 6
            if W < 10 then W = 300 end

            for _, sid in ipairs(specIDs) do
                local _, sname = GetSpecializationInfoByID(sid)

                -- spec header
                local hdr = CreateFrame("Frame", nil, loChild, "BackdropTemplate")
                hdr:SetSize(W, 22)
                hdr:SetPoint("TOPLEFT", 0, yOff)
                hdr:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
                hdr:SetBackdropColor(0.2, 0.1, 0.35, 0.8)
                hdr:Show()
                local hLabel = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                hLabel:SetPoint("LEFT", 8, 0)
                hLabel:SetText("|cFFBB66FF" .. (sname or ("Spec " .. sid)) .. "|r")
                yOff = yOff - 24

                -- entries
                local keys = {}
                for k in pairs(specGroups[sid]) do keys[#keys+1] = k end
                table.sort(keys)

                for _, key in ipairs(keys) do
                    local entry = specGroups[sid][key]
                    local row = CreateFrame("Frame", nil, loChild, "BackdropTemplate")
                    row:SetSize(W, 26)
                    row:SetPoint("TOPLEFT", 0, yOff)
                    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
                    row:SetBackdropColor(0.08, 0.08, 0.12, 0.6)
                    row:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
                    row:Show()

                    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    lbl:SetPoint("LEFT",  row, "LEFT",   8,   0)
                    lbl:SetPoint("RIGHT", row, "RIGHT", -30,  0)
                    lbl:SetJustifyH("LEFT")
                    local diffPart   = entry.diffName and ("|cFF888888 (" .. entry.diffName .. ")|r") or ""
                    local configPart = entry.tlxMode
                        and (" |cFF00CC44[TLX] " .. (entry.tlxName or "?") .. "|r")
                        or  (entry.configName and (" |cFF00CC44" .. entry.configName .. "|r") or "")
                    lbl:SetText((entry.name or "?") .. diffPart .. configPart)

                    local delBtn = CreateFrame("Button", nil, row)
                    delBtn:SetSize(22, 20)
                    delBtn:SetPoint("RIGHT", -4, 0)
                    delBtn:SetNormalFontObject("GameFontNormalSmall")
                    delBtn:SetText("|cFFFF4444X|r")
                    local capturedKey = key
                    delBtn:SetScript("OnClick", function()
                        local d2 = RRT and RRT.TalentReminder
                        if d2 and d2.loadouts then
                            d2.loadouts[capturedKey] = nil
                            RebuildTalentLoadouts()
                        end
                    end)

                    yOff = yOff - 28
                end
            end

            loChild:SetHeight(math.max(1, math.abs(yOff)))
        end

        talentPanel:HookScript("OnShow", RebuildTalentLoadouts)
        RRT_NS.UI.RebuildTalentLoadouts = RebuildTalentLoadouts

        -- ── Buttons below the loadout box ─────────────────────────────────────
        local btn_template  = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")
        local font_template = DF:GetTemplate("font",   "OPTIONS_FONT_TEMPLATE")

        if not StaticPopupDialogs["RRT_TALENT_CLEAR_CONFIRM"] then
            StaticPopupDialogs["RRT_TALENT_CLEAR_CONFIRM"] = {
                text    = "|cFFBB66FFReversion Raid Tools|r\n\n"
                    .. "|cFFFF4444This will delete ALL saved talent builds.|r\n"
                    .. "You will be prompted again the next time you enter a Mythic+ dungeon.\n\n"
                    .. "Are you sure?",
                button1 = "Clear All",
                button2 = "Cancel",
                OnAccept = function()
                    local m = RRT_NS.TalentReminder; if m then m:ClearSaved() end
                end,
                timeout = 0, whileDead = true, hideOnEscape = true,
            }
        end

        local forceBtn = DF:CreateButton(talentPanel,
            function() local m = RRT_NS.TalentReminder; if m then m:ForceCheck() end end,
            120, 22, "Force Check", nil, nil, nil, nil, nil, false, btn_template, font_template)
        forceBtn:SetPoint("BOTTOMLEFT", talentPanel, "BOTTOMLEFT", 10, 24)

        local clearBtn = DF:CreateButton(talentPanel,
            function() StaticPopup_Show("RRT_TALENT_CLEAR_CONFIRM") end,
            140, 22, "Clear Saved Builds", nil, nil, nil, nil, nil, false, btn_template, font_template)
        clearBtn:SetPoint("BOTTOMLEFT", talentPanel, "BOTTOMLEFT", 138, 24)
    end

    local OptER = RRT_NS.UI.Options.EquipmentReminder
    if OptER then
        DF:BuildMenu(remindersSubPanels["equipment"], OptER.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptER.BuildCallback())

    end

    -- Build Mythic+ panel with sub-tabs
    local mplusSubDefs = {
        { name = L["qol_mplus_autokeystone"],  key = "autokeystone"  },
        { name = L["qol_mplus_autoqueue"],     key = "autoqueue"     },
        { name = L["qol_mplus_autoplaystyle"], key = "autoplaystyle" },
    }
    local mplusSubPanels = BuildSubNav(panels["mplus"], mplusSubDefs)

    local OptAK = RRT_NS.UI.Options.AutoKeystone
    if OptAK then
        DF:BuildMenu(mplusSubPanels["autokeystone"], OptAK.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptAK.BuildCallback())
    end

    local OptAQ = RRT_NS.UI.Options.AutoQueue
    if OptAQ then
        DF:BuildMenu(mplusSubPanels["autoqueue"], OptAQ.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptAQ.BuildCallback())
    end

    local OptAP = RRT_NS.UI.Options.AutoPlaystyle
    if OptAP then
        DF:BuildMenu(mplusSubPanels["autoplaystyle"], OptAP.BuildOptions(), 10, -10,
            subMenuHeight, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, OptAP.BuildCallback())
    end

    -- Sidebar buttons
    local activeButton = nil
    local activeSectionName = ""
    local function SelectSection(key, btn, sectionName)
        for k, p in pairs(panels) do p:SetShown(k == key) end
        if activeButton then
            activeButton:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            activeButton:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
        end
        local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        btn:SetBackdropColor(c[1]*0.4, c[2]*0.4, c[3]*0.4, 0.8)
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        activeButton = btn
        activeSectionName = sectionName
        local hex = string.format("%02X%02X%02X", math.floor(c[1]*255+0.5), math.floor(c[2]*255+0.5), math.floor(c[3]*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. sectionName .. "|r")
    end

    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
        if activeButton then
            activeButton:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
            activeButton:SetBackdropBorderColor(r, g, b, 1)
        end
        local hex = string.format("%02X%02X%02X", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. activeSectionName .. "|r")
    end)

    for i, section in ipairs(SECTIONS) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(SIDEBAR_WIDTH - SIDEBAR_PADDING * 2, SIDEBAR_ITEM_H)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT",
            SIDEBAR_PADDING, -(SIDEBAR_PADDING + (i - 1) * (SIDEBAR_ITEM_H + 4)))
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then btnText:SetFont(f, 9, fl or "") end end
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(section.name)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)

        local key         = section.key
        local sectionName = section.name
        btn:SetScript("OnClick", function(self) SelectSection(key, self, sectionName) end)
        btn:SetScript("OnEnter", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end
        end)

        if i == 1 then SelectSection(key, btn, sectionName) end
    end
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.QoL = {
    BuildQoLUI = BuildQoLUI,
}
