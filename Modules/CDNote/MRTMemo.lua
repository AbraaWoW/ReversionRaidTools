local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

-- ─────────────────────────────────────────────────────────────────────────────
-- Readme — MRT note guide + quick reference
-- ─────────────────────────────────────────────────────────────────────────────

local ROW_H  = 18
local SBAR_W = 16   -- space reserved for the DF scrollbar (keeps it inside the panel)

-- Entry types:
--   { type="section", key }          yellow bold header (L[key])
--   { type="subsec",  key }          orange sub-header (L[key])
--   { type="row", syntax, key }      syntax (white) + arrow + desc (L[key])
--   { type="code", text }            full-width white code line (raw, not translated)
--   { type="note", key }             full-width gray description (L[key])
--   { type="gap" }                   small vertical space
local MEMO_SCHEMA = {

    -- ── Note Examples ─────────────────────────────────────────────────────────
    { type="section", key="readme_sec_phase_examples" },
    { type="note",    key="readme_note_phase_intro" },
    { type="gap" },

    { type="code",    text="Phase 1:" },
    { type="code",    text="  {time:15} {spell:316958} {spell:196718} Tank1 Healer1" },
    { type="code",    text="  {time:40} {spell:97462} Tank2" },
    { type="code",    text="  {time:1:17} {spell:31821} Tank1" },
    { type="gap" },

    { type="code",    text="Phase 2:  (starts after SAR of spell 367573 - 1st time)" },
    { type="code",    text="  {time:40,SAR:367573:1} {spell:51052} Player1 Player2" },
    { type="code",    text="  {time:15,SAR:367573:1} {spell:196718} Healer1 {spell:740} Healer2" },
    { type="code",    text="  {time:1:22,SAR:367573:1} {spell:97462} Tank2" },
    { type="gap" },

    { type="code",    text="Phase 3:  (starts after SAR of spell 367573 - 2nd time)" },
    { type="code",    text="  {time:15,SAR:367573:2} {spell:196718} Healer1 {spell:108280} Tank3" },
    { type="code",    text="  {time:40,SAR:367573:2} {spell:31821} Tank1 + Defensive" },
    { type="code",    text="  {time:1:20,SAR:367573:2} {spell:97462} Tank2" },
    { type="gap" },

    { type="code",    text="Phase 4:  (starts on 4th SCC of spell 362721)" },
    { type="code",    text="  {time:22,SCC:362721:4} {spell:97462} Tank2" },
    { type="gap" },

    -- ── Other Notes ───────────────────────────────────────────────────────────
    { type="section", key="readme_sec_other" },

    { type="code",    text="Remnants:" },
    { type="code",    text="  <1> {spell:352368} {diamond} TANK {circle} RANGED" },
    { type="code",    text="  <2> {spell:352368} {diamond} TANK {moon} RANGED" },
    { type="code",    text="  <3> {spell:352368} {moon} RANGED {circle} RANGED" },
    { type="gap" },

    { type="code",    text="Resentment (phase 2):" },
    { type="code",    text="  1 - {time:30,p2} {spell:316958} Healer ~2:15" },
    { type="code",    text="  5 - {time:2:02,p2} {spell:740} Healer2" },
    { type="code",    text="  8 - {time:3:08,p2} {spell:265202} Player5" },
    { type="gap" },

    { type="code",    text="Ability per occurrence (SAA counter):" },
    { type="code",    text="  1 - {time:6,SAA:350039:1} {spell:62618} P1 {spell:51052} P2 P3" },
    { type="code",    text="  2 - {time:6,SAA:350039:2} {spell:51052} P2" },
    { type="code",    text="  3 - {time:6,SAA:350039:3} {spell:62618} P1" },
    { type="gap" },

    -- ── Guide: Beginner ───────────────────────────────────────────────────────
    { type="section", key="readme_sec_beginner" },

    { type="subsec",  key="readme_sub_timer_fmt" },
    { type="row",     syntax="{time:75}",                   key="readme_timer_1" },
    { type="row",     syntax="{time:1:10}",                 key="readme_timer_2" },
    { type="row",     syntax="{time:02:30,p2}",             key="readme_timer_5" },
    { type="row",     syntax="{time:00:30,SCC:347704:2}",   key="readme_timer_6" },
    { type="note",    key="readme_note_events" },
    { type="gap" },

    { type="subsec",  key="readme_sub_display_fmt" },
    { type="note",    key="readme_note_double_space" },
    { type="row",     syntax="{time:20} Text",                           key="readme_disp_1" },
    { type="row",     syntax="{time:20} Text {spell:77761}",             key="readme_disp_2" },
    { type="row",     syntax="{time:20} A {spell:1}  B {spell:2}",      key="readme_disp_3" },
    { type="note",    key="readme_note_hyphen" },
    { type="note",    key="readme_note_icon_rule" },
    { type="gap" },

    { type="subsec",  key="readme_sub_examples" },
    { type="code",    text="  {spell:358760} {time:00:16} Chains - Player {spell:77764}" },
    { type="note",    key="readme_ex_1_desc" },
    { type="code",    text="  {spell:351413} {time:00:29,SAR:348805:1} Glare - Player {spell:77764}" },
    { type="note",    key="readme_ex_2_desc" },
    { type="code",    text="  {time:00:22,p3} Chains - P1 {spell:77764}  P2 {spell:77764}" },
    { type="note",    key="readme_ex_3_desc" },
    { type="gap" },

    -- ── Guide: Advanced ───────────────────────────────────────────────────────
    { type="section", key="readme_sec_advanced" },

    { type="subsec",  key="readme_sub_trigger" },
    { type="row",     syntax="{time:ss}",             key="readme_trig_1" },
    { type="row",     syntax="{time:mm:ss}",          key="readme_trig_2" },
    { type="row",     syntax="{time:mm.ss}",          key="readme_trig_3" },
    { type="row",     syntax="{time:mm:ss,condition}", key="readme_trig_4" },
    { type="gap" },

    { type="subsec",  key="readme_sub_conditions" },
    { type="row",     syntax="event:spellID:counter", key="readme_cond_format" },
    { type="row",     syntax="SCC / SCS / SAA / SAR", key="readme_cond_event" },
    { type="row",     syntax="counter: 0 = every",   key="readme_cond_counter" },
    { type="row",     syntax="p2 / p3 ...",           key="readme_cond_phase" },
    { type="gap" },

    { type="subsec",  key="readme_sub_events" },
    { type="row",     syntax="SCC", key="readme_ev_scc" },
    { type="row",     syntax="SCS", key="readme_ev_scs" },
    { type="row",     syntax="SAA", key="readme_ev_saa" },
    { type="row",     syntax="SAR", key="readme_ev_sar" },
    { type="gap" },

    { type="note",    key="readme_note_compat" },
    { type="gap" },

    -- ── Quick Ref: Timing ─────────────────────────────────────────────────────
    { type="section", key="memo_sec_timing" },
    { type="row", syntax="{time:ss}",        key="memo_time_1" },
    { type="row", syntax="{time:mm:ss}",     key="memo_time_2" },
    { type="row", syntax="{time:ss,cond}",   key="memo_time_3" },
    { type="gap" },

    -- ── Quick Ref: Role filters ───────────────────────────────────────────────
    { type="section", key="memo_sec_role" },
    { type="row", syntax="{T}text{/T}",      key="memo_role_t" },
    { type="row", syntax="{H}text{/H}",      key="memo_role_h" },
    { type="row", syntax="{D}text{/D}",      key="memo_role_d" },
    { type="gap" },

    -- ── Quick Ref: Player / Class / Group filters ─────────────────────────────
    { type="section", key="memo_sec_player" },
    { type="row", syntax="{p:Name}text{/p}",          key="memo_player_1" },
    { type="row", syntax="{!p:Name}text{/p}",         key="memo_player_2" },
    { type="row", syntax="{c:CLASS}text{/c}",         key="memo_player_3" },
    { type="row", syntax="{!c:CLASS}text{/c}",        key="memo_player_4" },
    { type="row", syntax="{g1}text{/g}",              key="memo_player_5" },
    { type="row", syntax="{!g2}text{/g}",             key="memo_player_6" },
    { type="row", syntax="{race:Human}text{/race}",   key="memo_player_7" },
    { type="row", syntax="{classunique:MAGE}t{/classunique}", key="memo_player_8" },
    { type="gap" },

    -- ── Quick Ref: Phase / Encounter / Zone filters ───────────────────────────
    { type="section", key="memo_sec_phase" },
    { type="row", syntax="{p2}text{/p}",              key="memo_phase_1" },
    { type="row", syntax="{e:encounterID}t{/e}",      key="memo_phase_2" },
    { type="row", syntax="{z:zoneID}text{/z}",        key="memo_phase_3" },
    { type="gap" },

    -- ── Quick Ref: Special blocks ─────────────────────────────────────────────
    { type="section", key="memo_sec_special" },
    { type="row", syntax="{0}text{/0}",               key="memo_spec_1" },
    { type="row", syntax="{self}",                    key="memo_spec_2" },
    { type="row", syntax="{everyone}",                key="memo_spec_3" },
    { type="gap" },

    -- ── Quick Ref: Spell icons ────────────────────────────────────────────────
    { type="section", key="memo_sec_spell" },
    { type="row", syntax="{spell:ID}",                key="memo_spell_1" },
    { type="row", syntax="{spell:ID:32}",             key="memo_spell_2" },
    { type="row", syntax="{icon:path}",               key="memo_spell_3" },
    { type="gap" },

    -- ── Quick Ref: Raid markers ───────────────────────────────────────────────
    { type="section", key="memo_sec_raid_icons" },
    { type="row", syntax="{star}   / {rt1}", key="memo_rt_star",     icon="|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14|t" },
    { type="row", syntax="{circle} / {rt2}", key="memo_rt_circle",   icon="|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:14|t" },
    { type="row", syntax="{diamond}/ {rt3}", key="memo_rt_diamond",  icon="|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:14|t" },
    { type="row", syntax="{triangle}/{rt4}", key="memo_rt_triangle", icon="|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:14|t" },
    { type="row", syntax="{moon}   / {rt5}", key="memo_rt_moon",     icon="|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:14|t" },
    { type="row", syntax="{square} / {rt6}", key="memo_rt_square",   icon="|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:14|t" },
    { type="row", syntax="{cross}  / {rt7}", key="memo_rt_cross",    icon="|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:14|t" },
    { type="row", syntax="{skull}  / {rt8}", key="memo_rt_skull",    icon="|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14|t" },
    { type="gap" },

    -- ── Quick Ref: Role icons ─────────────────────────────────────────────────
    { type="section", key="memo_sec_role_icons" },
    { type="row", syntax="{tank}",   key="memo_ri_tank",   icon="|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:0:19:22:41|t" },
    { type="row", syntax="{healer}", key="memo_ri_healer", icon="|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:1:20|t" },
    { type="row", syntax="{dps}",    key="memo_ri_dps",    icon="|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:22:41|t" },
    { type="gap" },

    -- ── Quick Ref: Class icons ────────────────────────────────────────────────
    { type="section", key="memo_sec_class" },
    { type="row", syntax="{warrior}     / {war}",   key="memo_cl_warrior" },
    { type="row", syntax="{paladin}     / {pal}",   key="memo_cl_paladin" },
    { type="row", syntax="{hunter}      / {hun}",   key="memo_cl_hunter"  },
    { type="row", syntax="{rogue}       / {rog}",   key="memo_cl_rogue"   },
    { type="row", syntax="{priest}      / {pri}",   key="memo_cl_priest"  },
    { type="row", syntax="{deathknight} / {dk}",    key="memo_cl_dk"      },
    { type="row", syntax="{shaman}      / {sham}",  key="memo_cl_shaman"  },
    { type="row", syntax="{mage}",                  key="memo_cl_mage"    },
    { type="row", syntax="{warlock}     / {lock}",  key="memo_cl_warlock" },
    { type="row", syntax="{monk}",                  key="memo_cl_monk"    },
    { type="row", syntax="{druid}       / {dru}",   key="memo_cl_druid"   },
    { type="row", syntax="{demonhunter} / {dh}",    key="memo_cl_dh"      },
    { type="row", syntax="{evoker}      / {dragon}", key="memo_cl_evoker"  },
    { type="gap" },

    -- ── Quick Ref: Colors ─────────────────────────────────────────────────────
    { type="section", key="memo_sec_colors" },
    { type="row", syntax="|cFFRRGGBBtext|r",        key="memo_color_1" },
    { type="row", syntax="||cFFRRGGBBtext||r",       key="memo_color_2" },
    { type="gap" },

    -- ── Quick Ref: Auto-color ─────────────────────────────────────────────────
    { type="section", key="memo_sec_autocolor" },
    { type="row", syntax="PlayerName",              key="memo_autocolor_1" },
    { type="gap" },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Build the memo panel
-- ─────────────────────────────────────────────────────────────────────────────

local function BuildMRTMemoPanel(panel)
    local Core = RRT_NS.UI.Core

    local W = Core.window_width  - 130 - 12
    local H = Core.window_height - 100 - 22

    local SCROLL_W = W - SBAR_W   -- leave room for the scrollbar so it stays inside the panel
    local NUM_LINES = math.floor(H / ROW_H)

    -- ── Two-column layout widths ─────────────────────────────────────────────
    local COL1_W = 230                          -- syntax column
    local COL2_W = SCROLL_W - COL1_W - 20      -- description column (20 = arrow + margin)

    -- Build flat display rows from MEMO_SCHEMA, resolving L keys at call time
    local function BuildRows()
        local rows = {}
        for _, entry in ipairs(MEMO_SCHEMA) do
            if entry.type == "section" then
                table.insert(rows, { kind="gap" })
                table.insert(rows, { kind="section", text=L[entry.key] })
            elseif entry.type == "subsec" then
                table.insert(rows, { kind="subsec", text=L[entry.key] })
            elseif entry.type == "gap" then
                table.insert(rows, { kind="gap" })
            elseif entry.type == "note" then
                table.insert(rows, { kind="note", text=L[entry.key] })
            elseif entry.type == "code" then
                table.insert(rows, { kind="code", text=entry.text })
            elseif entry.type == "row" then
                local desc = entry.icon and (entry.icon .. "  " .. L[entry.key]) or L[entry.key]
                table.insert(rows, {
                    kind   = "row",
                    syntax = entry.syntax,
                    desc   = desc,
                })
            end
        end
        return rows
    end

    local rows = BuildRows()

    -- ── DF ScrollBox refresh / createLine ───────────────────────────────────
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local line = self:GetLine(i)
            if line then
                local entry = data[i + offset]
                if entry then
                    if entry.kind == "section" then
                        line.col1:SetText("|cFFFFCC00" .. entry.text .. "|r")
                        line.col1:SetWidth(SCROLL_W - 10)
                        line.sep:Show()
                        line.col2:SetText("")
                        line.arrow:SetText("")
                    elseif entry.kind == "subsec" then
                        line.col1:SetText("|cFFFFAA33" .. entry.text .. "|r")
                        line.col1:SetWidth(SCROLL_W - 10)
                        line.sep:Hide()
                        line.col2:SetText("")
                        line.arrow:SetText("")
                    elseif entry.kind == "gap" then
                        line.col1:SetText("")
                        line.col2:SetText("")
                        line.arrow:SetText("")
                        line.sep:Hide()
                    elseif entry.kind == "note" then
                        line.col1:SetText("|cFF888888" .. (entry.text or "") .. "|r")
                        line.col1:SetWidth(SCROLL_W - 10)
                        line.col2:SetText("")
                        line.arrow:SetText("")
                        line.sep:Hide()
                    elseif entry.kind == "code" then
                        line.col1:SetText("|cFFCCCCCC" .. (entry.text or "") .. "|r")
                        line.col1:SetWidth(SCROLL_W - 10)
                        line.col2:SetText("")
                        line.arrow:SetText("")
                        line.sep:Hide()
                    else
                        line.col1:SetText("|cFFFFFFFF" .. (entry.syntax or "") .. "|r")
                        line.col1:SetWidth(COL1_W)
                        line.col2:SetText("|cFFBBBBBB" .. (entry.desc or "") .. "|r")
                        line.arrow:SetText("|cFF666666->|r")
                        line.sep:Hide()
                    end
                else
                    line.col1:SetText("")
                    line.col2:SetText("")
                    line.arrow:SetText("")
                    line.sep:Hide()
                end
            end
        end
    end

    local function createLine(self, index)
        local line = CreateFrame("Frame", "$parentMRTLine"..index, self)
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -((index - 1) * ROW_H) - 1)
        line:SetSize(self:GetWidth(), ROW_H)

        -- Separator for section headers
        local sep = line:CreateTexture(nil, "BACKGROUND")
        sep:SetColorTexture(1, 0.82, 0, 0.18)
        sep:SetPoint("BOTTOMLEFT",  line, "BOTTOMLEFT",  0, 0)
        sep:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", 0, 0)
        sep:SetHeight(1)
        sep:Hide()
        line.sep = sep

        -- Syntax column
        local fs1 = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs1:SetPoint("LEFT", line, "LEFT", 6, 0)
        fs1:SetWidth(COL1_W)
        fs1:SetJustifyH("LEFT")
        line.col1 = fs1

        -- Arrow separator
        local arrow = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        arrow:SetPoint("LEFT", fs1, "RIGHT", 4, 0)
        arrow:SetWidth(14)
        line.arrow = arrow

        -- Description column
        local fs2 = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs2:SetPoint("LEFT", arrow, "RIGHT", 4, 0)
        fs2:SetWidth(COL2_W)
        fs2:SetJustifyH("LEFT")
        line.col2 = fs2

        return line
    end

    -- DF ScrollBox — width = SCROLL_W to leave SBAR_W px for the slider
    local scrollBox = DF:CreateScrollBox(panel, "RRTMRTMemoScrollBox",
        refresh, rows, SCROLL_W, H, NUM_LINES, ROW_H, createLine)
    DF:ReskinSlider(scrollBox)
    scrollBox.ReajustNumFrames = true
    scrollBox:SetPoint("TOPLEFT",    panel, "TOPLEFT",    0, 0)
    scrollBox:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    for i = 1, NUM_LINES do
        scrollBox:CreateLine(createLine)
    end
    scrollBox:Refresh()
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.BuildMRTMemoPanel = BuildMRTMemoPanel
