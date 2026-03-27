local _, RRT_NS = ... -- Internal namespace

RRT_NS.EncounterOrder = {
    [3176] = 1, -- Imperator
    [3177] = 2, -- Vorasius
    [3179] = 3, -- Fallen-King
    [3178] = 4, -- Dragons
    [3180] = 5, -- Lightblinded Vanguard
    [3181] = 6, -- Crown of the Cosmos
    [3306] = 7, -- Chimaerus
    [3182] = 8, -- Belo'ren
    [3183] = 9, -- Midnight Falls
}

local symbols = {
    star = 1,
    circle = 2,
    diamond = 3,
    triangle = 4,
    moon = 5,
    square = 6,
    cross = 7,
    skull = 8,
}

function RRT_NS:AddToReminder(info)
    self.ProcessedReminder = self.ProcessedReminder or {}
    self.ProcessedReminder[info.encID] = self.ProcessedReminder[info.encID] or {}
    if (info.IsAlert and self:IsUsingTLAlerts()) or (info.IsAssignment and self:IsUsingTLAssignments()) then
        table.insert(self.TLAlerts, CopyTable(info))
        return
    elseif self:IsUsingTLReminders() and (not info.IsAlert) and (not info.IsAssignment) then
        return
    end
    info.spellID = info.spellID and tonumber(info.spellID)
    -- convert to booleans
    if info.TTS == "true" then info.TTS = true end
    if info.TTS == "false" then info.TTS = false end
    -- default to user settings if not overwritten by the reminders
    if info.TTS == nil then
        info.TTS = (info.spellID and RRT.ReminderSettings.SpellTTS) or ((not info.spellID) and RRT.ReminderSettings.TextTTS)
    end
    if info.TTSTimer == nil then
        -- set TTS timer to the specified duration or if no duration was specified, set it to the default value
        info.TTSTimer = info.dur or ((info.spellID and RRT.ReminderSettings.SpellTTSTimer) or RRT.ReminderSettings.TextTTSTimer)
    end
    if info.dur == nil then
        info.dur = info.spellID and RRT.ReminderSettings.SpellDuration or RRT.ReminderSettings.TextDuration
    end
    if info.countdown == nil then
        info.countdown = info.spellID and RRT.ReminderSettings.SpellCountdown or RRT.ReminderSettings.TextCountdown
        if info.countdown == 0 then info.countdown = false end
    end
    info.dur = tonumber(info.dur)
    info.time = tonumber(info.time)
    info.TTSTimer = tonumber(info.TTSTimer)
    info.countdown = tonumber(info.countdown)
    if info.dur > info.time then info.dur = info.time end -- force duration to be equal to time if an alert is set very early into the phase
    if info.TTSTimer > info.time then info.TTSTimer = info.time end -- same for TTSTimer
    if info.countdown and info.countdown > info.time then info.countdown = info.time end -- same for countdown
    info.phase = info.phase and tonumber(info.phase)
    if not info.phase then info.phase = 1 end
    local rawtext = info.text
    if info.text then
        info.text = info.text:gsub("{(%a*%d*)}", function(token) -- convert {star}/{rt1} etc. to raid target icons
            local id = symbols[token] or (token:match("^rt(%d)$") and tonumber(token:match("^rt(%d)$")))
            if id then return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..id..":0|t" end
        end)
    end
    if (RRT.ReminderSettings.SpellName or RRT.ReminderSettings.SpellNameTTS) and info.spellID and not info.text then -- display spellname if text is empty, also make TTS that spellname
        local spell = C_Spell.GetSpellInfo(info.spellID)
        if spell then
            info.text = RRT.ReminderSettings.SpellName and spell.name or "" -- set text to SpellName
            info.TTS = info.TTS and type(info.TTS) ~= "string" and spell.name or info.TTS -- Set TTS to SpellName
        end
    end
    if info.TTS and info.text and type(info.TTS) == "boolean" then -- if tts is "true" convert it to the rawtext, which is the text before converting it to display raid-icons
        info.TTS = rawtext
    end
    if info.TTS and type(info.TTS) == "string" and ((RRT.ReminderSettings.AnnounceSpellDuration and info.spellID) or (RRT.ReminderSettings.AnnounceTextDuration and not info.spellID)) and not (info.IsAlert or info.IsAssignment) then
        info.TTS = info.TTS.." in "..info.TTSTimer
    end
    if info.glowunit then
        local glowtable = {}
        for name in info.glowunit:gmatch("([^%s:]+)") do
            if name ~= "glowunit" then
                table.insert(glowtable, name)
            end
        end
        info.glowunit = glowtable
    end
    if info.colors then
        local colors = {}
        for color in info.colors:gmatch("([^%s:]+)") do
            table.insert(colors, tonumber(color))
        end
        info.colors = colors
    end
    -- play default sound if enabled and no TTS/Sound was specified
    if RRT.ReminderSettings.PlayDefaultSound and (type(info.TTS) == "boolean" or not info.TTS) and (not info.sound) and (not (info.IsAlert or info.IsAssignment)) then
        info.sound = RRT.ReminderSettings.DefaultSound
    end

    self.ProcessedReminder[info.encID][info.phase] = self.ProcessedReminder[info.encID][info.phase] or {}
    table.insert(self.ProcessedReminder[info.encID][info.phase],
    {
        notsticky = info.notsticky,
        BarOverwrite = info.BarOverwrite or info.Type == "Bar",
        IconOverwrite = info.IconOverwrite or info.Type == "Icon",
        TTSTimer = info.TTSTimer,
        rawtext = info.rawtext,
        phase = info.phase,
        colors = info.colors,
        id = #self.ProcessedReminder[info.encID][info.phase]+1,
        countdown = info.countdown and tonumber(info.countdown),
        glowunit = info.glowunit,
        sound = info.sound,
        time = info.time,
        text = info.text,
        TTS = info.TTS,
        spellID = info.spellID and tonumber(info.spellID),
        dur = info.dur or 8,
        skipdur = info.skipdur, -- with this true there will be no cooldown edge shown for icons
        IsAlert = info.IsAlert,
    })
end

function RRT_NS:ProcessReminder()
    local str = ""
    self.ProcessedReminder = {}
    local remindertable = {}
    local addedreminders = {}
    local personalremindertable = {}
    local addedpersonalreminders = {}
    self.DisplayedReminder = ""
    self.DisplayedPersonalReminder = ""
    self.DisplayedExtraReminder = ""
    local pers = RRT.ReminderSettings.PersonalReminderFrame.enabled
    local shared = RRT.ReminderSettings.ReminderFrame.enabled
    -- self:IsUsingTLReminders() makes it process the note but then stops the display at a later point. This allows still displaying the note.
    if (RRT.ReminderSettings.enabled or self:IsUsingTLReminders()) and self.Reminder then str = self.Reminder end
    if RRT.ReminderSettings.MRTNote or (self:IsUsingTLReminders() and LiquidRemindersSaved.settings.timeline.mrtNote) then
        local note = VMRT and VMRT.Note and VMRT.Note.Text1 or ""
        note = strtrim(note)
        str = (note == "" and str) or (str ~= "" and note.."\n"..str) or note
        local persnote = VMRT and VMRT.Note and VMRT.Note.SelfText or ""
        persnote = strtrim(persnote)
        str = (persnote == "" and str) or (str ~= "" and persnote.."\n"..str) or persnote
    end
    if RRT.ReminderSettings.PersNote or self:IsUsingTLReminders() then
        local note = self.PersonalReminder or ""
        str = (note == "" and str) or (str ~= "" and note.."\n"..str) or note
    end
    if str ~= "" then
        local subgroup = self:GetSubGroup("player")
        if not subgroup then subgroup = 1 end
        subgroup = "group"..subgroup
        local specid = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
        local pos = self.spectable[specid]
        local encID = 0
        local mynickname = strlower(RRTAPI:GetName("player", "GlobalNickNames"))
        local myname = strlower(UnitName("player"))
        local myrole = strlower(UnitGroupRolesAssigned("player"))
        local myclass = strlower(select(2, UnitClass("player")))
        pos = (self.meleetable[specid] or myrole == "tank") and "melee" or "ranged"
        local extranote = ""
        if not str:match('\n$') then
            str = str..'\n'
        end
        for line in str:gmatch('([^\n]*)\n') do
            local firstline = false
            if line:find("EncounterID:") then
                encID = line:match("EncounterID:(%d+)")
                if encID then
                    encID = tonumber(encID)
                    firstline = true
                end
            end
            local tag = line:match("tag:([^;]+)")
            local time = line:match("time:(%d*%.?%d+)")
            local text = line:match("text:([^;]+)")
            local spellID = line:match("spellid:(%d+)")
            local phase = line:match("ph:(%d+)")
            local dur = line:match("dur:(%d+)")
            local TTS = line:match("TTS:([^;]+)")
            local TTSTimer = line:match("TTSTimer:(%d+)")
            local countdown = line:match("countdown:(%d+)")
            local sound = line:match("sound:([^;]+)")
            local glowunit = line:match("glowunit:([^;]+)")
            local bossSpellID = line:match("bossSpell:(%d+)")
            local colors = line:match("colors:([^;]+)")
            if time and tag and (text or spellID) and encID and encIDs ~= 0 and not firstline then
                local displayLine = line
                phase = phase and tonumber(phase) or 1
                local key = encID..phase..time..tag..(text or spellID)
                if (pers or shared) and (spellID or not RRT.ReminderSettings.OnlySpellReminders) then -- only insert this if it's a spell or user wants to see text-reminders as well
                    -- remove phase as we add it back later
                    displayLine = displayLine:gsub("ph:"..phase, "")
                    -- convert to MM:SS format
                    local timeNum = tonumber(time)
                    if timeNum then
                        local minutes = math.floor(timeNum / 60)
                        local seconds = math.floor(timeNum % 60)
                        local timeFormatted = string.format("%d:%02d", minutes, seconds)
                        displayLine = displayLine:gsub("time:"..time, timeFormatted.." ")
                    end
                    if text then
                        local displayText = text:gsub("{(%a*%d*)}", function(token) -- convert {star}/{rt1} etc. to raid target icons
                            local id = symbols[token] or (token:match("^rt(%d)$") and tonumber(token:match("^rt(%d)$")))
                            if id then return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..id..":0|t" end
                        end)
                        local s, e = displayLine:find("text:"..text, 1, true)
                        if s then displayLine = displayLine:sub(1, s-1).."- "..displayText.." "..displayLine:sub(e+1) end
                    end
                    -- convert to icon
                    if spellID then
                        local iconID = C_Spell.GetSpellTexture(tonumber(spellID))
                        if iconID then
                            local iconString = "\124T"..iconID..":12:12:0:0:64:64:4:60:4:60\124t"
                            displayLine = displayLine:gsub("spellid:%d+", iconString.. " ")
                        end
                    end
                    if bossSpellID then
                        local iconID = C_Spell.GetSpellTexture(tonumber(bossSpellID))
                        if iconID then
                            local iconString = "\124T"..iconID..":12:12:0:0:64:64:4:60:4:60\124t"
                            displayLine = displayLine:gsub("bossSpell:%d+", iconString.. " ")
                        end
                    end
                    -- cleanup stuff we don't want to have displayed
                    if glowunit then
                        displayLine = displayLine:gsub("glowunit:"..glowunit, "")
                    end
                    if countdown then
                        displayLine = displayLine:gsub("countdown:"..countdown, "")
                    end
                    if TTS then
                        displayLine = displayLine:gsub("TTS:"..TTS, "")
                    end
                    if TTSTimer then
                        displayLine = displayLine:gsub("TTSTimer:"..TTSTimer, "")
                    end
                    if sound then
                        displayLine = displayLine:gsub("sound:"..sound, "")
                    end
                    if dur then
                        displayLine = displayLine:gsub("dur:"..dur, "")
                    end
                    if colors then
                        displayLine = displayLine:gsub("colors:"..colors, "")
                    end
                    -- convert names to nicknames and color code them
                    local tagNames = ""
                    if not RRT.ReminderSettings.HidePlayerNames then
                        for name in tag:gmatch("(%S+)") do
                            tagNames = tagNames..RRTAPI:Shorten(RRTAPI:GetChar(strtrim(name), true), 12, false, "GlobalNickNames").." "
                        end
                    end
                    tagNames = strtrim(tagNames)
                    displayLine = RRT.ReminderSettings.HidePlayerNames and displayLine:gsub("tag:([^;]+)", "") or displayLine:gsub("tag:([^;]+)", tagNames.." ")
                    -- remove remaining semicolons
                    displayLine = displayLine:gsub(";", "")
                    if shared and not addedreminders[key] then
                        table.insert(remindertable, {str = displayLine, time = tonumber(time), phase = phase})
                        addedreminders[key] = true
                    end
                end
                local tags = {}
                tag = strlower(tag)
                for name in tag:gmatch("(%S+)") do
                    tags[strtrim(name)] = true
                end
                specid = specid and tostring(specid)
                if tag == "everyone" or
                tags[myname] or
                tags[mynickname] or
                tags[myrole] or
                tags[specid] or
                tags[myclass] or
                tags[subgroup] or
                (pos and tags[pos])
                then
                    if not addedpersonalreminders[key] then
                        addedpersonalreminders[key] = true
                        if pers then
                            if (spellID or not RRT.ReminderSettings.OnlySpellReminders) then -- only insert this if it's a spell or user wants to see text-reminders as well
                                table.insert(personalremindertable, {str = displayLine, time = tonumber(time), phase = phase})
                            end
                        end
                        self:AddToReminder({text = text, phase = phase, colors = colors, countdown = countdown, glowunit = glowunit, sound = sound, time = time, spellID = spellID, dur = dur, TTS = TTS, TTSTimer = TTSTimer, encID = encID, Type = nil, notsticky = false})
                    end
                end
            else
                if (not firstline) and (not line:find("invitelist:")) then
                    line = line:gsub("{(%a*%d*)}", function(token) -- convert {star}/{rt1} etc. to raid target icons
                        local id = symbols[token] or (token:match("^rt(%d)$") and tonumber(token:match("^rt(%d)$")))
                        if id then return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..id..":0|t" end
                    end)
                    if RRT.Settings["GlobalNickNames"] and false then
                        local words = {}
                        for word in line:gmatch("[^%s]+") do
                            local shortened = RRTAPI:Shorten(RRTAPI:GetChar(word, true), 12, false, "GlobalNickNames")
                            table.insert(words, shortened)
                        end
                        extranote = extranote..table.concat(words, " ").."\n"
                    else
                        extranote = extranote..line.."\n"
                    end
                end
            end
        end

        if shared then
            local phasedisplayed = {}
            table.sort(remindertable, function(a, b)
                if a.phase == b.phase then
                    return a.time < b.time
                else
                    return a.phase < b.phase
                end
            end)
            for _, data in ipairs(remindertable) do
                if not phasedisplayed[data.phase] then
                    data.str = "Phase "..data.phase.."\n"..data.str
                    phasedisplayed[data.phase] = true
                end
                self.DisplayedReminder = self.DisplayedReminder..data.str.."\n"
            end
        end
        if pers then
            local phasedisplayed = {}
            table.sort(personalremindertable, function(a, b)
                if a.phase == b.phase then
                    return a.time < b.time
                else
                    return a.phase < b.phase
                end
            end)
            for _, data in ipairs(personalremindertable) do
                if not phasedisplayed[data.phase] then
                    data.str = "Phase "..data.phase.."\n"..data.str
                    phasedisplayed[data.phase] = true
                end
                self.DisplayedPersonalReminder = self.DisplayedPersonalReminder..data.str.."\n"
            end
        end
        extranote = extranote:gsub("^%s*\n+", "")
        self.DisplayedExtraReminder = extranote
    end
    -- ── CDNote source ──────────────────────────────────────────────────────────
    -- Injects entries from the MRT/Viserio-format CDNote note as reminder source.
    -- Timed pop-ups go through AddToReminder; the full rendered note feeds the
    -- display frames (controlled by the existing ReminderFrame/PersonalReminderFrame
    -- enabled toggles in Rappels-Note options).
    if RRT.CDNote and RRT.CDNote.noteText and RRT.CDNote.noteText ~= "" and RRT_NS.CDNote then
        local cdn      = RRT_NS.CDNote
        local noteText = RRT.CDNote.noteText
        local entries  = cdn.ParseNote(noteText)
        local cdnEncID = self.EncounterID or 0
        local addedCDN = {}
        local persEnabled   = RRT.ReminderSettings.PersonalReminderFrame and RRT.ReminderSettings.PersonalReminderFrame.enabled
        local sharedEnabled = RRT.ReminderSettings.ReminderFrame and RRT.ReminderSettings.ReminderFrame.enabled

        -- Register timed reminder pop-ups via AddToReminder
        for _, entry in ipairs(entries) do
            if entry.type == "timer" and not cdn.HasComplexCondition(entry) then
                local spellID = entry.spells and entry.spells[1] or nil
                for _, secs in ipairs(entry.seconds) do
                    local dkey = tostring(secs) .. (entry.displayText or "")
                    if not addedCDN[dkey] then
                        addedCDN[dkey] = true
                        self:AddToReminder({
                            text    = entry.displayText,
                            phase   = 1,
                            time    = secs,
                            spellID = spellID,
                            encID   = cdnEncID,
                        })
                    end
                end
            end
        end

        -- Append full rendered note to the display frames
        local rendered = cdn.FormatNote(noteText)
        if rendered ~= "" then
            if sharedEnabled then
                self.DisplayedReminder = self.DisplayedReminder .. rendered .. "\n"
            end
            if persEnabled then
                self.DisplayedPersonalReminder = self.DisplayedPersonalReminder .. rendered .. "\n"
            end
        end
    end
    -- ── End CDNote source ──────────────────────────────────────────────────────

    if self.TimelineWindow and self.TimelineWindow:IsShown() then
        self:RefreshTimelineForMode()
    end
end

function RRT_NS:UpdateExistingFrames() -- called when user changes settings to not require a reload
    local parent = self.ReminderText or {}
    for i=1, #parent do
        local F = parent[i]
        if F and F:IsShown() then
            local s = RRT.ReminderSettings.TextSettings
            F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            local anchor = s.CenterAligned and "CENTER" or "LEFT"
            F.Text:ClearAllPoints()
            F.Text:SetPoint(anchor, F, anchor, 0, 0)
        end
    end
    self:ArrangeStates("Texts")
    self:MoveFrameSettings(self.TextMover, RRT.ReminderSettings.TextSettings, true)
    parent = self.ReminderIcon or {}
    for i=1, #parent do
        local F = parent[i]
        if F and F:IsShown() then
            local s = RRT.ReminderSettings.IconSettings
            F:SetSize(s.Width, s.Height)
            F.Icon:SetAllPoints(F)
            F.Border:SetAllPoints(F)
            local anchor = RRT.ReminderSettings.IconSettings.RightAlignedText and "RIGHT" or "LEFT"
            local relativePoint = RRT.ReminderSettings.IconSettings.RightAlignedText and "LEFT" or "RIGHT"
            F.Text:ClearAllPoints()
            F.Text:SetPoint(anchor, F, relativePoint, s.xTextOffset, s.yTextOffset)
            F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            if RRT.ReminderSettings.HideTimerText then
                F.TimerText:Hide()
            else
                F.TimerText:Show()
            end
            F.TimerText:SetPoint("CENTER", F.Swipe, "CENTER", s.xTimer, s.yTimer)
            F.TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
        end
    end
    self:ArrangeStates("Icons")
    self:MoveFrameSettings(self.IconMover, RRT.ReminderSettings.IconSettings)
    parent = self.UnitIcon or {}
    for i=1, #parent do
        local F = parent[i]
        if F and F:IsShown() then
            local s = RRT.ReminderSettings.UnitIconSettings
            F:SetSize(s.Width, s.Height) -- not setting points in this one because this is repeated every time the frame is shown as it needs a new frame to anchor to anyway
        end
    end
    parent = self.ReminderBar or {}
    for i=1, #parent do
        local F = parent[i]
        if F and F:IsShown() then
            local s = RRT.ReminderSettings.BarSettings
            F:SetSize(s.Width, s.Height)
            F:SetStatusBarTexture(self.LSM:Fetch("statusbar", s.Texture))
            F:SetStatusBarColor(unpack(F.info.colors or s.colors))
            F.Icon:SetPoint("RIGHT", F, "LEFT", s.xIcon, s.yIcon)
            F.Icon:SetSize(s.Height, s.Height)
            F.Text:SetPoint("LEFT", F.Icon, "RIGHT", s.xTextOffset, s.yTextOffset)
            F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            if RRT.ReminderSettings.HideTimerText then
                F.TimerText:Hide()
            else
                F.TimerText:Show()
            end
            F.TimerText:SetPoint("RIGHT", F, "RIGHT", s.xTimer, s.yTimer)
            F.TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
        end
    end
    self:ArrangeStates("Bars")
    self:MoveFrameSettings(self.BarMover, RRT.ReminderSettings.BarSettings, false, true)
end

function RRT_NS:ArrangeStates(Type)
    local F = (Type == "Texts" and self.ReminderText) or (Type == "Icons" and self.ReminderIcon) or (Type == "Bars" and self.ReminderBar)
    if not F then return end
    local s = (Type == "Texts" and RRT.ReminderSettings.TextSettings) or (Type == "Icons" and RRT.ReminderSettings.IconSettings) or (Type == "Bars" and RRT.ReminderSettings.BarSettings)
    local pos = {}
    for i=1, #F do
        if F[i] and F[i]:IsShown() then
            table.insert(pos, {Frame = F[i], id = F[i].info.id, expires = F[i].info.expires})
        end
    end
    table.sort(pos, function(a, b)
        if a.expires == b.expires then
            return a.id < b.id
        else
            return a.expires < b.expires
        end
    end)
    for i, v in ipairs(pos) do
        local diff = Type == "Texts" and v.Frame.Text and v.Frame.Text:GetStringHeight() or s.Height or 0
        local Spacing = s.Spacing or 0
        local yoffset = (s.GrowDirection == "Up" and (i-1) * (diff+Spacing) or (s.GrowDirection == "Down" and -(i-1) * (diff+Spacing))) or 0
        local xoffset = Type == "Icons" and ((s.GrowDirection == "Right" and (i-1) * (s.Width+Spacing)) or (s.GrowDirection == "Left" and -(i-1) * (s.Width+Spacing))) or 0
        v.Frame:ClearAllPoints()
        if Type == "Texts" then
            v.Frame:SetPoint("BOTTOMLEFT", "RRTReminderTextMover", "BOTTOMLEFT", 0, 0 + yoffset)
            v.Frame:SetPoint("TOPRIGHT", "RRTReminderTextMover", "TOPRIGHT", 0, 0 + yoffset)
        elseif Type == "Icons" then
            v.Frame:SetPoint("BOTTOMLEFT", "RRTReminderIconMover", "BOTTOMLEFT", 0 + xoffset, 0 + yoffset)
            v.Frame:SetPoint("TOPRIGHT", "RRTReminderIconMover", "TOPRIGHT", 0 + xoffset, 0 + yoffset)
        elseif Type == "Bars" then
            v.Frame:SetPoint("BOTTOMLEFT", "RRTReminderBarMover", "BOTTOMLEFT", 0, 0 + yoffset)
            v.Frame:SetPoint("TOPRIGHT", "RRTReminderBarMover", "TOPRIGHT", 0, 0 + yoffset)
        else
            print("RELOE PLS FIX (Reminder anchoring issue @ RRT_NS:ArrangeStates)")
        end
    end
end

function RRT_NS:SetProperties(F, info, skipsound, s)
    -- Pre-compute the composite key once so OnUpdate never rebuilds it
    info._key = "ph" .. info.phase .. "id" .. info.id
    F._updateAcc = 0
    F:SetScript("OnUpdate", function(_, elapsed)
        F._updateAcc = F._updateAcc + elapsed
        if F._updateAcc < 0.05 then return end  -- cap at 20 fps
        F._updateAcc = 0
        self:UpdateReminderDisplay(info, F, skipsound)
    end)
    F:SetScript("OnHide", function()
        if info.glowunit then
            self:HideGlows(info.glowunit, "p"..info.phase.."id"..info.id)
        end
        if F.Swipe and RRT.ReminderSettings.IconSettings.Glow > 0 then
            self:HideGlows(nil, nil, F)
        end
        RRT_NS:ArrangeStates(F.Type)
        F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end)
    F.info = info
    if not info.spellID then
        F.Text:SetTextColor(unpack(info.colors or s.colors))
        return
    end
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    F.Icon:SetTexture(icon)
    if F.Swipe then
        if info.skipdur then
            F.Swipe:SetCooldown(0, 0)
            F.TimerText:Hide()
        else
            F.Swipe:SetCooldown(GetTime(), info.dur)
            if F.TimerText then
                F.TimerText:SetTextColor(1, 1, 0, 1)
                if RRT.ReminderSettings.HideTimerText then
                    F.TimerText:Hide()
                else
                    F.TimerText:Show()
                end
            end
        end
        F.Text:SetTextColor(unpack(info.colors or s.colors))
    elseif F:GetObjectType() == "StatusBar" then
        F:SetStatusBarColor(unpack(info.colors or s.colors))
        if F.TimerText then
            F.TimerText:SetTextColor(1, 1, 1, 1)
            if RRT.ReminderSettings.HideTimerText then
                F.TimerText:Hide()
            else
                F.TimerText:Show()
            end
        end
    end
    F:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    F:SetScript("OnEvent", function(self, e, ...)
        -- only registered for player so spellID is never secret
        local _, _, spellID = ...
        if (not issecretvalue(info.spellID)) and spellID == info.spellID and self:IsShown() then
            local rem = info.dur - (GetTime() - info.startTime)
            if rem and rem <= 5 then
                F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
                F:Hide()
            end
        end
    end)
end

function RRT_NS:CreateText(info)
    self.ReminderText = self.ReminderText or {}
    local s = RRT.ReminderSettings.TextSettings
    for i=1, #self.ReminderText+1 do
        if self.ReminderText[i] and not self.ReminderText[i]:IsShown() then
            self:SetProperties(self.ReminderText[i], info, false, s)
            return self.ReminderText[i]
        end
        if not self.ReminderText[i] then
            self.ReminderText[i] = CreateFrame("Frame", 'RRTReminderText' .. i, UIParent, "BackdropTemplate")
            local offset = s.GrowDirection == "Up" and (i-1) * s.FontSize or -(i-1) * s.FontSize
            self.ReminderText[i]:SetPoint("BOTTOMLEFT", "RRTReminderTextMover", "BOTTOMLEFT", 0, 0 + offset)
            self.ReminderText[i]:SetPoint("TOPRIGHT", "RRTReminderTextMover", "TOPRIGHT", 0, 0 + offset)
            self.ReminderText[i]:SetFrameStrata("HIGH")
            self.ReminderText[i].Text = self.ReminderText[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            local anchor = s.CenterAligned and "CENTER" or "LEFT"
            self.ReminderText[i].Text:SetPoint(anchor, self.ReminderText[i], anchor, 0, 0)
            self.ReminderText[i].Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            self.ReminderText[i].Text:SetShadowColor(0, 0, 0, 1)
            self.ReminderText[i].Text:SetShadowOffset(0, 0)
            self.ReminderText[i].Text:SetTextColor(unpack(info.colors or s.colors))
            self:SetProperties(self.ReminderText[i], info, false, s)
            return self.ReminderText[i]
        end
    end
end

function RRT_NS:CreateIcon(info)
    self.ReminderIcon = self.ReminderIcon or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    local s = RRT.ReminderSettings.IconSettings
    for i=1, #self.ReminderIcon+1 do
        if self.ReminderIcon[i] and not self.ReminderIcon[i]:IsShown() then
            self:SetProperties(self.ReminderIcon[i], info, false, s)
            return self.ReminderIcon[i]
        end
        if not self.ReminderIcon[i] then
            self.ReminderIcon[i] = CreateFrame("Frame", 'RRTReminderIcon' .. i, UIParent, "BackdropTemplate")
            local yoffset = (s.GrowDirection == "Up" and (i-1) * s.Height) or (s.GrowDirection == "Down" and -(i-1) * s.Height) or 0
            local xoffset = (s.GrowDirection == "Right" and (i-1) * s.Width) or (s.GrowDirection == "Left" and -(i-1) * s.Width) or 0
            self.ReminderIcon[i]:SetPoint("BOTTOMLEFT", "RRTReminderIconMover", "BOTTOMLEFT", 0 + xoffset, 0 + yoffset)
            self.ReminderIcon[i]:SetPoint("TOPRIGHT", "RRTReminderIconMover", "TOPRIGHT", 0 + xoffset, 0 + yoffset)
            self.ReminderIcon[i]:SetFrameStrata("HIGH")
            self.ReminderIcon[i].Icon = self.ReminderIcon[i]:CreateTexture(nil, "ARTWORK")
            self.ReminderIcon[i].Icon:SetAllPoints(self.ReminderIcon[i])
            self.ReminderIcon[i].Border = CreateFrame("Frame", nil, self.ReminderIcon[i], "BackdropTemplate")
            self.ReminderIcon[i].Border:SetAllPoints(self.ReminderIcon[i])
            self.ReminderIcon[i].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            self.ReminderIcon[i].Border:SetBackdropBorderColor(0, 0, 0, 1)
            self.ReminderIcon[i].Text = self.ReminderIcon[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            local anchor = RRT.ReminderSettings.IconSettings.RightAlignedText and "RIGHT" or "LEFT"
            local relativePoint = RRT.ReminderSettings.IconSettings.RightAlignedText and "LEFT" or "RIGHT"
            self.ReminderIcon[i].Text:SetPoint(anchor, self.ReminderIcon[i], relativePoint, s.xTextOffset, s.yTextOffset)
            self.ReminderIcon[i].Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            self.ReminderIcon[i].Text:SetShadowColor(0, 0, 0, 1)
            self.ReminderIcon[i].Text:SetShadowOffset(0, 0)
            self.ReminderIcon[i].Text:SetTextColor(unpack(info.colors or s.colors))
            self.ReminderIcon[i].Swipe = CreateFrame("Cooldown", nil, self.ReminderIcon[i], "CooldownFrameTemplate")
            self.ReminderIcon[i].Swipe:SetAllPoints()
            self.ReminderIcon[i].Swipe:SetDrawBling(false)
            self.ReminderIcon[i].Swipe:SetDrawEdge(false)
            self.ReminderIcon[i].Swipe:SetReverse(true)
            self.ReminderIcon[i].Swipe:SetHideCountdownNumbers(true)
            self.ReminderIcon[i].TimerText = self.ReminderIcon[i].Swipe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderIcon[i].TimerText:SetPoint("CENTER", self.ReminderIcon[i].Swipe, "CENTER", s.xTimer, s.yTimer)
            self.ReminderIcon[i].TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
            self.ReminderIcon[i].TimerText:SetShadowColor(0, 0, 0, 1)
            self.ReminderIcon[i].TimerText:SetShadowOffset(0, 0)
            self.ReminderIcon[i].TimerText:SetDrawLayer("OVERLAY", 7)
            self:SetProperties(self.ReminderIcon[i], info, false, s)
            return self.ReminderIcon[i]
        end
    end
end



function RRT_NS:CreateUnitFrameIcon(info, name)
    self.UnitIcon = self.UnitIcon or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    local unit = RRTAPI:GetChar(name, true)
    local i = UnitInRaid(unit)
    if (not UnitExists(unit)) or (not i) then return end
    local F = self.LGF.GetUnitFrame("raid"..i)
    if not F then return end
    local s = RRT.ReminderSettings.UnitIconSettings
    for i=1, #self.UnitIcon+1 do
        if self.UnitIcon[i] and not self.UnitIcon[i]:IsShown() then
            self.UnitIcon[i]:ClearAllPoints()
            self.UnitIcon[i]:SetPoint(s.Position, F, s.Position, s.xOffset, s.yOffset)
            self:SetProperties(self.UnitIcon[i], info, true, s)
            return self.UnitIcon[i]
        end
        if not self.UnitIcon[i] then
            self.UnitIcon[i] = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            self.UnitIcon[i]:SetSize(s.Width, s.Height)
            self.UnitIcon[i]:SetPoint(s.Position, F, s.Position, s.xOffset, s.yOffset)
            self.UnitIcon[i].Icon = self.UnitIcon[i]:CreateTexture(nil, "ARTWORK")
            self.UnitIcon[i].Icon:SetAllPoints(self.UnitIcon[i])
            self.UnitIcon[i].Icon:SetTexture(icon)
            self.UnitIcon[i].Border = CreateFrame("Frame", nil, self.UnitIcon[i], "BackdropTemplate")
            self.UnitIcon[i].Border:SetAllPoints(self.UnitIcon[i])
            self.UnitIcon[i].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            self.UnitIcon[i].Border:SetBackdropBorderColor(0, 0, 0, 1)
            self:SetProperties(self.UnitIcon[i], info, true, s)
            return self.UnitIcon[i]
        end
    end
end

function RRT_NS:CreateBar(info)
    self.ReminderBar = self.ReminderBar or {}
    local icon = C_Spell.GetSpellInfo(info.spellID).iconID
    local s = RRT.ReminderSettings.BarSettings
    for i=1, #self.ReminderBar+1 do
        if self.ReminderBar[i] and not self.ReminderBar[i]:IsShown() then
            self:SetProperties(self.ReminderBar[i], info, false, s)
            return self.ReminderBar[i]
        end
        if not self.ReminderBar[i] then
            self.ReminderBar[i] = CreateFrame("StatusBar", 'RRTReminderBar' .. i, UIParent, "BackdropTemplate")
            self.ReminderBar[i]:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            tileSize = 0,
            })
            self.ReminderBar[i]:SetStatusBarTexture(self.LSM:Fetch("statusbar", s.Texture))
            self.ReminderBar[i]:SetStatusBarColor(unpack(info.colors or s.colors))
            self.ReminderBar[i]:SetBackdropColor(0, 0, 0, 0.8)
            local offset = s.GrowDirection == "Up" and (i-1) * s.Height or -(i-1) * s.Height
            self.ReminderBar[i]:SetPoint("BOTTOMLEFT", "RRTReminderBarMover", "BOTTOMLEFT", 0, 0 + offset)
            self.ReminderBar[i]:SetPoint("TOPRIGHT", "RRTReminderBarMover", "TOPRIGHT", 0, 0 + offset)
            self.ReminderBar[i]:SetFrameStrata("HIGH")
            self.ReminderBar[i].Border = CreateFrame("Frame", nil, self.ReminderBar[i], "BackdropTemplate")
            self.ReminderBar[i].Border:SetAllPoints(self.ReminderBar[i])
            self.ReminderBar[i].Border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            self.ReminderBar[i].Border:SetBackdropBorderColor(0, 0, 0, 1)
            self.ReminderBar[i].Icon = self.ReminderBar[i]:CreateTexture(nil, "ARTWORK")
            self.ReminderBar[i].Icon:SetPoint("RIGHT", self.ReminderBar[i], "LEFT", s.xIcon, s.yIcon)
            self.ReminderBar[i].Icon:SetSize(s.Height, s.Height)
            self.ReminderBar[i].Text = self.ReminderBar[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderBar[i].Text:SetPoint("LEFT", self.ReminderBar[i].Icon, "RIGHT", s.xTextOffset, s.yTextOffset)
            self.ReminderBar[i].Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
            self.ReminderBar[i].Text:SetShadowColor(0, 0, 0, 1)
            self.ReminderBar[i].Text:SetShadowOffset(0, 0)
            self.ReminderBar[i].Text:SetTextColor(1, 1, 1, 1)
            self.ReminderBar[i].TimerText = self.ReminderBar[i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.ReminderBar[i].TimerText:SetPoint("RIGHT", self.ReminderBar[i], "RIGHT", s.xTimer, s.yTimer)
            self.ReminderBar[i].TimerText:SetFont(self.LSM:Fetch("font", s.Font), s.TimerFontSize, "OUTLINE")
            self.ReminderBar[i].TimerText:SetShadowColor(0, 0, 0, 1)
            self.ReminderBar[i].TimerText:SetShadowOffset(0, 0)
            self:SetProperties(self.ReminderBar[i], info, false, s)
            return self.ReminderBar[i]
        end
    end
end

function RRT_NS:DisplayReminder(info)
    local now = GetTime()
    local dur = info.dur or 8
    info.startTime = now
    info.dur = dur
    info.expires = now + dur
    local rem = info.dur - (now - info.startTime)
    if info.spellID and rem <= (0-RRT.ReminderSettings.Sticky) or ((info.notsticky or not info.spellID) and rem <= 0) then
        return
    end
    local remString
    if rem < 3 then
        if rem < 0 then
            remString = ""
        else
            rem = math.floor(rem * 10 + 0.5) / 10
            remString = string.format("%.1f", rem)
        end
    else
        remString = tostring(math.ceil(rem))
    end
    local remString = (rem % 1 == 0) and string.format("%.1f", rem) or rem
    local text = info.text ~= "" and info.text or ""
    local F
    if info.spellID then -- display icon if we have a spellID
        if (RRT.ReminderSettings.Bars or info.BarOverwrite) and not info.IconOverwrite then
            F = self:CreateBar(info)
            F:SetMinMaxValues(0, info.dur)
            F:SetValue(0)
            F:Show()
            self:ArrangeStates("Bars")
            F.Type = "Bars"
        else
            F = self:CreateIcon(info)
            F:Show()
            self:ArrangeStates("Icons")
            F.Type = "Icons"
        end
        F.Text:SetText(text)
        F.TimerText:SetText(remString)
    else
        F = self:CreateText(info)
        F.Type = "Texts"
        F.Text:SetText(text.." - ("..remString..")" or remString)
        F:Show()
        self:ArrangeStates("Texts")
    end
    if info.glowunit then
        for i, name in ipairs(info.glowunit) do
            self:GlowFrame(name, "p"..info.phase.."id"..info.id)
            if info.spellID then
                local UnitIcon = self:CreateUnitFrameIcon(info, name)
                if UnitIcon then UnitIcon:Show() end
            end
        end
    end
end

function RRT_NS:UpdateReminderDisplay(info, F, skipsound)
    local rem = info.dur - (GetTime() - info.startTime)
    local SoundTimer = info.TTSTimer or (info.spellID and RRT.ReminderSettings.SpellTTSTimer or RRT.ReminderSettings.TextTTSTimer)
    local key = info._key or ("ph"..info.phase.."id"..info.id)
    if rem <= SoundTimer and (not self.PlayedSound[key]) and (not skipsound) then
        self:PlayReminderSound(info)
        self.PlayedSound[key] = true
    end
    if info.countdown and rem <= info.countdown and (not self.StartedCountdown[key]) and (not skipsound) then
        RRTAPI:TTSCountdown(info.countdown)
        self.StartedCountdown[key] = true
    end
    if info.spellID and rem <= (0-RRT.ReminderSettings.Sticky) or ((info.notsticky or not info.spellID) and rem <= 0) then
        F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        F:Hide()
        return
    end
    local remString
    if rem < 3 then
        if rem < 0 then
            remString = ""
        else
            rem = math.floor(rem * 10 + 0.5) / 10
            remString = string.format("%.1f", rem)
        end
    else
        remString = tostring(math.ceil(rem))
    end
    local text = (info.skiptime and info.text) or (info.text and info.text ~= "" and info.text.." - ("..remString..")") or remString
    if info.spellID and type(info.spellID) == "number" then
        if F:GetObjectType() == "StatusBar" then
            F:SetValue((GetTime()-info.startTime))
        else
            if rem <= 3 and F.TimerText then
                F.TimerText:SetTextColor(1, 0, 0, 1)
            end
            if F.Swipe and RRT.ReminderSettings.IconSettings.Glow > 0 and rem <= RRT.ReminderSettings.IconSettings.Glow and not self.GlowStarted[key] then
                self.GlowStarted[key] = true
                self:GlowFrame(nil, nil, F)
            end
        end
        if F.TimerText and remString ~= F._lastRemString then
            F._lastRemString = remString
            F.TimerText:SetText(remString)
        end
    else
        if text ~= F._lastDisplayText then
            F._lastDisplayText = text
            F.Text:SetText(text)
        end
    end
end

function RRT_NS:PlayReminderSound(info, default)
    if info.TTS and issecretvalue(info.TTS) then RRTAPI:TTS(info.TTS) return end
    if default then -- so I can use this function outside of reminders basically
        info = {sound = default, TTS = default, rawtext = default}
    end
    local sound = info.sound and self.LSM:Fetch("sound", info.sound)
    if sound and sound ~= 1 then
        PlaySoundFile(sound, "Master")
        return
    elseif info.TTS then
        local TTS = (type(info.TTS) == "string" and info.TTS) or (info.rawtext and info.rawtext ~= "" and info.rawtext) or ""
        sound = self.LSM:Fetch("sound", TTS)
        if sound and sound ~= 1 then
            PlaySoundFile(sound, "Master")
            return
        else
            RRTAPI:TTS(TTS)
        end
    end
end

function RRT_NS:CountdownNoteFrame(frame)
    if not frame or not frame:IsShown() then return end
    local originalText = frame.OriginalText or frame.Text:GetText()
    if not originalText then return end
    local newtext = ""
    local PassedTime = (GetTime() - self.PhaseSwapTime)
    local curphase = 100
    if not originalText:match('\n$') then originalText = originalText..'\n' end
    for line in originalText:gmatch('([^\n]*)\n') do
        local ShouldDelete = false
        local phase = line:match("Phase (%d+)")
        curphase = phase and tonumber(phase) or curphase
        if curphase < self.Phase then
            ShouldDelete = true
        elseif curphase == self.Phase and not phase then
            local minutes, seconds = line:match("(%d+):(%d%d)")
            local originalTime = minutes and seconds and (minutes*60) + seconds
            if originalTime then
                local newtime = originalTime - PassedTime
                if newtime > 0 then
                    local newminutes = math.floor(newtime/60)
                    local newseconds = math.floor(newtime%60)
                    local timeFormatted = string.format("%d:%02d", newminutes, newseconds)
                    line = line:gsub(minutes..":"..seconds.." ", timeFormatted.." ")
                else
                    ShouldDelete = true
                end
            end
        end
        if not ShouldDelete then
            newtext = newtext..line.."\n"
        end
    end
    frame.Text:SetText(newtext)
end

function RRT_NS:StartReminders(phase, testrun)
    self:HideAllReminders()
    self.AllGlows = {}
    self.ReminderTimer = {}
    if testrun then
        if not self.ProcessedReminder then self:ProcessReminder() end
        if not self.ProcessedReminder then return end
        for encID, encData in pairs(self.ProcessedReminder) do
            for i, info in ipairs(encData[phase] or {}) do
                local time = math.max(info.time-info.dur, 0)
                self.ReminderTimer[i] = C_Timer.NewTimer(time, function()
                    self:DisplayReminder(info)
                end)
            end
        end
        return
    end
    if not self.EncounterID then return end
    if not self.ProcessedReminder[self.EncounterID] then return end
    if not self.ProcessedReminder[self.EncounterID][phase] then return end
    for i, info in ipairs(self.ProcessedReminder[self.EncounterID][phase]) do
        local time = math.max(info.time-info.dur, 0)
        self.ReminderTimer[i] = C_Timer.NewTimer(time, function()
            self:DisplayReminder(info)
        end)
    end
    -- Also run encounter-agnostic entries (encID=0, used by CDNote)
    if self.ProcessedReminder[0] and self.ProcessedReminder[0][phase] then
        local base = #self.ReminderTimer
        for i, info in ipairs(self.ProcessedReminder[0][phase]) do
            local time = math.max(info.time-info.dur, 0)
            self.ReminderTimer[base+i] = C_Timer.NewTimer(time, function()
                self:DisplayReminder(info)
            end)
        end
    end
end

function RRT_NS:DelayAllReminders(delay)
    if not self.ReminderTimer then return end
    for i, v in ipairs(self.ReminderTimer) do
        v:Cancel()
    end
    if not self.EncounterID then return end
    if not self.ProcessedReminder[self.EncounterID] then return end
    local phase = self.Phase or 1
    if not self.ProcessedReminder[self.EncounterID][phase] then return end
    local timediff = GetTime() - self.PhaseSwapTime -- time since phase change

    local parents = {"ReminderText", "ReminderIcon", "ReminderBar", "UnitIcon"}
    for _, parentname in ipairs(parents) do
        if self[parentname] then
            for i=1, #self[parentname] do
                local F = self[parentname][i]
                if F and F:IsShown() then
                    if F.info and F.info.dur then
                        F.info.expires = F.info.expires + delay
                        F.info.startTime = F.info.startTime + delay
                        self:UpdateReminderDisplay(F.info, F)
                    end
                end
            end
        end
    end

    for i, info in ipairs(self.ProcessedReminder[self.EncounterID][phase]) do
        if info.time-info.dur > timediff then -- if time is 0 then this reminder has already started
            local time = math.max(info.time-info.dur-timediff+delay, 0)
            info.time = info.time + delay
            self.ReminderTimer[i] = C_Timer.NewTimer(time, function()
                self:DisplayReminder(info)
            end)
        end
    end
end

function RRT_NS:HideAllReminders(FullReset)
    self.PlayedSound = {}
    self.StartedCountdown = {}
    self.GlowStarted = {}
    if self.ReminderTimer then
        for i, v in ipairs(self.ReminderTimer) do
            v:Cancel()
        end
    end
    if self.AllGlows then
        for k, v in pairs(self.AllGlows) do
            self.LCG.PixelGlow_Stop(k, v)
        end
    end
    local parent = self.ReminderText or {}
    for i=1, #parent do
        local F = parent[i]
        if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
    end
    parent = self.ReminderIcon or {}
    for i=1, #parent do
        local F = parent[i]
        if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
    end
    parent = self.ReminderBar or {}
    for i=1, #parent do
        local F = parent[i]
        if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
    end
    parent = self.UnitIcon or {}
    for i=1, #parent do
        local F = parent[i]
        if F then F:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") F:Hide() end
    end
    if not FullReset then return end
    self.ReminderTimer = nil
    self.AllGlows = nil
    self.Timelines = {}
    if self.EncounterAlertStop[self.EncounterID] then self.EncounterAlertStop[self.EncounterID](self) end
    self.EncounterID = nil
    self.TestingReminder = false
    self.ProcessedReminder = nil
end

function RRT_NS:GetAllReminderNames(personal)
    local list = {}
    local tocheck = personal and RRT.PersonalReminders or RRT.Reminders
    for k, v in pairs(tocheck) do
        local encID = v:match("EncounterID:(%d+)")
        local order = encID and self.EncounterOrder[tonumber(encID)] or 1000
        table.insert(list, {name = k, order = order, hasencID = encID})
    end
    table.sort(list, function(a, b)
        if a.order == b.order then
            return a.name < b.name
        else
            return a.order < b.order
        end
    end)
    return list
end

function RRT_NS:SetReminder(name, personal, skipupdate)
    if personal then
        if name and RRT.PersonalReminders[name] then
            self.PersonalReminder = RRT.PersonalReminders[name]
            RRT.ActivePersonalReminder = name
        else
            self.PersonalReminder = ""
            RRT.ActivePersonalReminder = nil
        end
    elseif name and RRT.Reminders[name] then
        self.Reminder = RRT.Reminders[name]
        RRT.ActiveReminder = name
    else
        self.Reminder = ""
        RRT.ActiveReminder = nil
    end
    if not skipupdate then
        self:ProcessReminder()
        self:UpdateReminderFrame(true)
        self:FireCallback("RRT_REMINDER_CHANGED", self.PersonalReminder, self.Reminder)
    end
end

function RRT_NS:RemoveReminder(name, personal)
    if personal then
        if name and RRT.PersonalReminders[name] then
            RRT.PersonalReminders[name] = nil
            if RRT.ActivePersonalReminder == name then
                self:SetReminder(nil, true)
            end
        end
    elseif name and RRT.Reminders[name] then
        RRT.Reminders[name] = nil
        RRT.InviteList[name] = nil
        if RRT.ActiveReminder == name then
            self:SetReminder(nil, false)
        end
    end
end

function RRT_NS:ImportFullReminderString(str, personal, IsUpdate, name)
    local name = ""
    local values = ""
    local diff = ""
    if not str:match('\n$') then
        str = str..'\n'
    end
    for line in str:gmatch('([^\n]*)\n') do
        if line:find("EncounterID:") then
            if values ~= "" then -- meaning we reached a new boss line as the previous one has values already
                self:ImportReminder(name, values, false, personal, IsUpdate)
                values = ""
                name = ""
                diff = ""
            end
            name = line:match("Name:([^;]+)")
            diff = line:match("Difficulty:([^;]+)")
            values = line.."\n"
        elseif name ~= "" then
            values = values..line.."\n"
        end
    end
    if values ~= "" and name ~= "" then -- importing the last boss
        self:ImportReminder(name, values, false, personal, IsUpdate, diff)
    end
end

function RRT_NS:ImportReminder(name, values, activate, personal, IsUpdate, diff)
    if not name then name = "Default Reminder" end
    local newname = diff and name.." - "..diff or name
    if personal then
        if RRT.PersonalReminders[newname] and not IsUpdate then -- if name already exists we add a 2 at the end
            self:ImportReminder(name.." 2", values, activate, personal, IsUpdate, diff)
            return
        end
        RRT.PersonalReminders[newname] = values
        if activate then
            self:SetReminder(newname, true)
        end
        return
    end
    if RRT.Reminders[newname] and not IsUpdate then -- if name already exists we add a 2 at the end
        self:ImportReminder(name.." 2", values, activate, personal, IsUpdate, diff)
        return
    end
    RRT.Reminders[newname] = values
    RRT.InviteList[newname] = self:InviteListFromReminder(values)
    if activate then
        self:SetReminder(newname)
    end
end

function RRT_NS:InviteListFromReminder(str)
    local list = {}
    local found = false
    for line in str:gmatch('[^\r\n]+') do
        if line:find("invitelist:") then
            found = true
            for name in line:gmatch("([^%s,;:]+)") do
                if name ~= "invitelist" then
                    table.insert(list, name)
                end
            end
        end
    end
    return found and list or false
end

function RRT_NS:GlowFrame(unit, id, F)
    if F then
        local s = RRT.ReminderSettings.GlowSettings
        self.LCG.ButtonGlow_Start(F)
        return
    end
    local color = {0, 1, 0, 1}
    if not unit then return end
    unit = RRTAPI:GetChar(unit, true)
    local i = UnitInRaid(unit)
    if (not UnitExists(unit)) or (not i) then return end
    id = unit..id
    local F = self.LGF.GetUnitFrame(unit)
    if not F then return end
    self.LCG.PixelGlow_Stop(F, id) -- hide any preivous glows first
    self.AllGlows[F] = id
    local s = RRT.ReminderSettings.GlowSettings
    self.LCG.PixelGlow_Start(F, s.colors, s.Lines, s.Frequency, s.Length, s.Thickness, s.xOffset, s.yOffset, true, id)
end

function RRT_NS:HideGlows(units, id, F)
    if F then
        self.LCG.ButtonGlow_Stop(F)
        return
    end
    if not units then return end
    for i, unit in ipairs(units) do
        unit = RRTAPI:GetChar(unit, true)
        local i = UnitInRaid(unit)
        if (not UnitExists(unit)) or (not i) then return end
        local newid = unit..id
        local F = self.LGF.GetUnitFrame(unit)
        if not F then return end
        self.AllGlows[F] = nil
        self.LCG.PixelGlow_Stop(F, newid)
    end
end

function RRT_NS:CreateMoveFrames()
    self:CreateReminderMoverFrame("IconMover", RRT.ReminderSettings.IconSettings, "IconSettings")
    self:CreateReminderMoverFrame("BarMover", RRT.ReminderSettings.BarSettings, "BarSettings")
    self:CreateReminderMoverFrame("TextMover", RRT.ReminderSettings.TextSettings, "TextSettings", true)
    self:CreateNoteMoverFrame("ReminderFrame", RRT.ReminderSettings.ReminderFrame, true, false, false)
    self:CreateNoteMoverFrame("PersonalReminderFrame", RRT.ReminderSettings.PersonalReminderFrame, false, true, false)
    self:CreateNoteMoverFrame("ExtraReminderFrame", RRT.ReminderSettings.ExtraReminderFrame, false, false, true)
end

function RRT_NS:CreateReminderMoverFrame(Name, SettingsTable, SettingsName, IsText)
    if not self[Name] then
        self[Name] = CreateFrame("Frame", 'RRTReminder'..Name, UIParent, "BackdropTemplate")
        if IsText then
            self[Name].Text = self[Name]:CreateFontString(Name..'Text', "OVERLAY", "GameFontNormal")
            self[Name].Text:SetText("Personals - (10)")
            self[Name].Text:SetFont(self.LSM:Fetch("font", SettingsTable.Font), SettingsTable.FontSize, "OUTLINE")
            self[Name].Text:SetPoint("LEFT", self[Name], "LEFT", 0, 0)
            self[Name].Text:SetTextColor(1, 1, 1, 0)
        end
        self:MoveFrameInit(self[Name], SettingsName)
        self:MoveFrameSettings(self[Name], SettingsTable, IsText)
    else
        self:MoveFrameSettings(self[Name], SettingsTable, IsText)
    end
    self[Name]:Show()
end

function RRT_NS:CreateNoteMoverFrame(Name, SettingsTable, Shared, Personal, Extra)
    if not self[Name.."Mover"] then
        self[Name.."Mover"] = CreateFrame("Frame", "RRTUI"..Name.."Mover", UIParent, "BackdropTemplate")
        self:MoveFrameInit(self[Name.."Mover"], Name, SettingsTable.BGcolor)
        self:MoveFrameSettings(self[Name.."Mover"], SettingsTable)
        if SettingsTable.enabled and SettingsTable.Moveable then
            self:UpdateReminderFrame(false, Shared, Personal, Extra)
            self:ToggleMoveFrames(self[Name.."Mover"], true)
            self[Name.."Mover"].Resizer:Show()
            self[Name.."Mover"]:SetResizable(true)
            self[Name.."Mover"]:SetResizeBounds(100, 100, 2000, 2000)
        end
    else
        self:MoveFrameSettings(self[Name.."Mover"], SettingsTable)
    end
    self[Name.."Mover"]:Show()
end

function RRT_NS:MoveFrameSettings(F, s, IsText)
    local Width = (IsText and F.Text:GetStringWidth()) or s.Width
    local Height = (IsText and F.Text:GetStringHeight()) or s.Height
    if IsText then
        F.Text:SetFont(self.LSM:Fetch("font", s.Font), s.FontSize, "OUTLINE")
        F.Text:SetText("Personals - (10)")
    end
    F:SetSize(Width, Height)
    F:ClearAllPoints()
    F:SetPoint(s.Anchor, UIParent, s.relativeTo, s.xOffset, s.yOffset)
end

function RRT_NS:MoveFrameInit(F, s, ReminderColor)
    if F then
        F.Border = CreateFrame("Frame", nil, F, "BackdropTemplate")
        local x = s == "BarSettings" and -6-RRT.ReminderSettings[s].Height or -6 -- extra offset for bars to account for the icon
        F.Border:SetPoint("TOPLEFT", F, "TOPLEFT", x, 6)
        F.Border:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", 6, -6)
        F.Border:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                tileSize = 0,
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
        if ReminderColor then F.Border:SetBackdropBorderColor(1, 1, 1, 0) else F.Border:SetBackdropBorderColor(1, 1, 1, 1) end
        if ReminderColor then F.Border:SetBackdropColor(unpack(ReminderColor)) else F.Border:SetBackdropColor(0, 0, 0, 0) end
        F.Border:Hide()
        F:SetFrameStrata(ReminderColor and "BACKGROUND" or "DIALOG")
        F.Border:SetFrameStrata(ReminderColor and "BACKGROUND" or "DIALOG")
        F:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        F:SetScript("OnDragStop", function(Frame)
            local settingsTable = s == "Generic" and RRT.Settings.GenericDisplay or RRT.ReminderSettings[s]
            self:StopFrameMove(Frame, settingsTable)
            if (not ReminderColor) and not (s == "Generic") then self:UpdateExistingFrames() end
        end)
    end
end

function RRTAPI:DebugNextPhase(num)
    if not RRT.Settings["Debug"] then return end
    for i=1, num do
        RRT_NS:EventHandler("ENCOUNTER_TIMELINE_EVENT_ADDED")
    end
end

function RRTAPI:DebugEncounter(EncounterID, diffID)
    if not RRT.Settings["Debug"] then return end
    RRT_NS.ProcessedReminder = nil
    RRT_NS.Assignments = RRT.AssignmentSettings
    RRT_NS._debugDiffID = diffID
    RRT_NS:EventHandler("ENCOUNTER_START", true, true, EncounterID)
    RRT_NS._debugDiffID = nil
end
-- /run RRTAPI:DebugEncounter(3306)
-- /run RRTAPI:DebugTimeline("ENCOUNTER_TIMELINE_EVENT_ADDED", 120.9)
function RRTAPI:DebugShowAlerts(encID, diffID, phase)
    if not RRT.Settings["Debug"] then return end
    self:DebugEncounter(encID, diffID)
    phase = phase or 1
    local encData = RRT_NS.ProcessedReminder and RRT_NS.ProcessedReminder[encID]
    if not encData or not encData[phase] then
        print("RRT Debug: no reminders for enc="..tostring(encID).." phase="..tostring(phase))
        return
    end
    print("RRT Debug: showing "..#encData[phase].." alerts for enc="..encID.." phase="..phase)
    for i, info in ipairs(encData[phase]) do
        C_Timer.NewTimer(i * 0.1, function()
            RRT_NS:DisplayReminder(info)
        end)
    end
end
function RRTAPI:DebugTimeline(e, dur)
    if not RRT.Settings["Debug"] then return end
    RRT_NS:EventHandler(e, true, true, {duration = dur})
end

function RRT_NS:CreateDefaultAlert(text, Type, spellID, dur, phase, encID, IsAssignment)
    local id = self.DefaultAlertID or 10000
    self.DefaultAlertID = self.DefaultAlertID and self.DefaultAlertID + 1 or 10001
    local info =
    {
        dur = dur,
        spellID = spellID,
        encID = encID,
        TTSTimer = dur, -- tts on show
        text = text,
        TTS = (Type == "Text" and RRT.ReminderSettings.TextTTS and text) or (Type ~= "Text" and RRT.ReminderSettings.SpellTTS and text), -- use the user's settings
        notsticky = true,
        phase = phase or self.Phase,
        id = id,
        startTime = GetTime(),
        IsAssignment = IsAssignment,
        IsAlert = not IsAssignment,
        countdown = false,
    }
    if Type == "Bar" then info.BarOverwrite = true
    elseif Type == "Icon" then info.IconOverwrite = true
    end
    return info
end

function RRT_NS:UpdateReminderFrame(all, shared, personal, extra)
    if all or shared then
        self:MoveFrameSettings(self.ReminderFrameMover, RRT.ReminderSettings.ReminderFrame)
        if not self.ReminderFrame then
            self:CreateNoteFrame("ReminderFrame", RRT.ReminderSettings.ReminderFrame)
        end
        local text = RRT.ReminderSettings.TextInSharedNote and self.DisplayedExtraReminder..self.DisplayedReminder or self.DisplayedReminder
        self:UpdateNoteFrame("ReminderFrame", RRT.ReminderSettings.ReminderFrame, text)
    end
    if all or personal then
        self:MoveFrameSettings(self.PersonalReminderFrameMover, RRT.ReminderSettings.PersonalReminderFrame)
        if not self.PersonalReminderFrame then
            self:CreateNoteFrame("PersonalReminderFrame", RRT.ReminderSettings.PersonalReminderFrame)
        end
        local text = RRT.ReminderSettings.TextInPersonalNote and self.DisplayedExtraReminder..self.DisplayedPersonalReminder or self.DisplayedPersonalReminder
        self:UpdateNoteFrame("PersonalReminderFrame", RRT.ReminderSettings.PersonalReminderFrame, text)
    end
    if all or extra then
        self:MoveFrameSettings(self.ExtraReminderFrameMover, RRT.ReminderSettings.ExtraReminderFrame)
        if not self.ExtraReminderFrame then
            self:CreateNoteFrame("ExtraReminderFrame", RRT.ReminderSettings.ExtraReminderFrame)
        end
        local text = self.DisplayedExtraReminder
        self:UpdateNoteFrame("ExtraReminderFrame", RRT.ReminderSettings.ExtraReminderFrame, text)
    end
end

function RRTAPI:GetReminderString()
    return RRT_NS.PersonalReminder, RRT_NS.Reminder
end

function RRT_NS:CreateNoteFrame(Name, SettingsTable)
    self[Name] = CreateFrame("Frame", 'RRTUI'..Name, self[Name.."Mover"], "BackdropTemplate")
    self[Name]:SetClipsChildren(true)
    self[Name]:SetFrameStrata("MEDIUM")
    self[Name].Text = self[Name]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self[Name].Text:SetPoint("TOPLEFT", self[Name], "TOPLEFT", 0, 0)
    self[Name].Text:SetWidth(SettingsTable.Width)
    self[Name].Text:SetTextColor(1, 1, 1, 1)
    self[Name].Text:SetJustifyH("LEFT")
    self[Name].Text:SetJustifyV("TOP")
    self[Name].Text:SetWordWrap(true)
    self[Name].Text:SetNonSpaceWrap(true)
    self[Name].Text:SetDrawLayer("OVERLAY", 7)
    self[Name.."Mover"].Resizer = CreateFrame("Button", nil, self[Name.."Mover"])
    self[Name.."Mover"].Resizer:SetSize(20, 20)
    self[Name.."Mover"].Resizer:SetPoint("BOTTOMRIGHT", self[Name.."Mover"], "BOTTOMRIGHT", -2, 2)
    self[Name.."Mover"].Resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    self[Name.."Mover"].Resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    self[Name.."Mover"].Resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    self[Name.."Mover"].Resizer:EnableMouse(true)
    self[Name.."Mover"].Resizer:RegisterForDrag("LeftButton")
    self[Name.."Mover"].Resizer:SetScript("OnMouseDown", function()
        self[Name.."Mover"]:StartSizing("BOTTOMRIGHT")
        self[Name.."Mover"]:SetScript("OnSizeChanged", function()
            local newWidth = self[Name.."Mover"]:GetWidth()
            self[Name].Text:SetWidth(newWidth)
        end)
    end)
    self[Name.."Mover"].Resizer:SetScript("OnMouseUp", function()
        self[Name.."Mover"]:SetScript("OnSizeChanged", nil)
        self[Name.."Mover"]:StopMovingOrSizing()
        SettingsTable.Width = self[Name.."Mover"]:GetWidth()
        SettingsTable.Height = self[Name.."Mover"]:GetHeight()
        local anchor, _, relativeTo, xOffset, yOffset = self[Name.."Mover"]:GetPoint(nil, UIParent)
        SettingsTable.Anchor = anchor
        SettingsTable.relativeTo = relativeTos
        SettingsTable.xOffset = Round(xOffset)
        SettingsTable.yOffset = Round(yOffset)
    end)
    if not SettingsTable.Moveable then
        self[Name.."Mover"].Resizer:Hide()
    end
end

function RRT_NS:UpdateNoteFrame(Name, SettingsTable, text)
    if SettingsTable.enabled then
        if not self[Name] then
            self:CreateNoteFrame(Name, SettingsTable)
        end
        self[Name]:SetAllPoints(self[Name.."Mover"])
        self[Name].Text:SetFont(self.LSM:Fetch("font", SettingsTable.Font), SettingsTable.FontSize, "OUTLINE")
        self[Name].Text:SetWidth(SettingsTable.Width)
        if text ~= "skip" then self[Name].Text:SetText(text) self[Name].OriginalText = text end
        if not self[Name.."Mover"].IsActiveFlash then self[Name.."Mover"].Border:SetBackdropColor(unpack(SettingsTable.BGcolor)) end
        local diff = select(3, GetInstanceInfo()) or 0
        if (diff > 17 or diff < 14) and not RRT.ReminderSettings.ShowOutsideOfRaid then
            self[Name]:Hide()
        else
            self[Name]:Show()
        end
    elseif self[Name] then
        self[Name]:Hide()
    end
end

function RRT_NS:FlashFrameBackground(F, SettingsTable)
    if not F or not F.Border then return end
    if not SettingsTable.enabled then return end
    if F.IsActiveFlash then return end
    local wasshown = F.Border:IsShown()
    F.Border:Show()
    local holdDuration = 1
    local fadeDuration = 2

    F.Border:SetBackdropColor(1, 0, 0, 0.4)

    local elapsed = 0
    F.IsActiveFlash = true
    C_Timer.NewTicker(0.1, function(ticker)
        elapsed = elapsed + 0.1

        if elapsed < holdDuration then
            return
        end

        local fadeElapsed = elapsed - holdDuration
        local progress = math.min(fadeElapsed / fadeDuration, 1)

        local r = 1
        local g = 0
        local b = 0
        local a = 0.4 + (0 - 0.4) * progress

        F.Border:SetBackdropColor(r, g, b, a)

        if progress >= 1 then
            if not wasshown then F.Border:Hide() end
            if wasshown then F.Border:SetBackdropColor(unpack(SettingsTable.BGcolor)) end
            ticker:Cancel()
            F.IsActiveFlash = false
        end
    end)
end

function RRT_NS:FlashNoteBackgrounds()
    self:FlashFrameBackground(RRT_NS.ReminderFrameMover, RRT.ReminderSettings.ReminderFrame)
    self:FlashFrameBackground(RRT_NS.PersonalReminderFrameMover, RRT.ReminderSettings.PersonalReminderFrame)
    self:FlashFrameBackground(RRT_NS.ExtraReminderFrameMover, RRT.ReminderSettings.ExtraReminderFrame)
end

function RRTAPI:ToggleTLReminders(enable)
    RRT.ReminderSettings.UseTLReminders = enable
    RRT_NS:ProcessReminder()
    RRT_NS:UpdateReminderFrame(true)
    RRT_NS:FireCallback("RRT_REMINDER_CHANGED", RRT_NS.PersonalReminder, RRT_NS.Reminder)
end

function RRT_NS:IsUsingTLReminders()
    return RRT.ReminderSettings.UseTLReminders and C_AddOns.IsAddOnLoaded("TimelineReminders")
end

function RRT_NS:IsUsingTLAlerts()
    return RRT.ReminderSettings.UseTLAlerts and C_AddOns.IsAddOnLoaded("TimelineReminders")
end

function RRT_NS:IsUsingTLAssignments()
    return RRT.ReminderSettings.UseTLAssignments and C_AddOns.IsAddOnLoaded("TimelineReminders")
end

function RRTAPI:GetAlerts(encounterID, id)
    if C_InstanceEncounter.IsEncounterInProgress() then return end
    RRT_NS.TLAlerts = {}
    if RRT_NS.EncounterAlertStart[encounterID] and RRT_NS:IsUsingTLAlerts() then RRT_NS.EncounterAlertStart[encounterID](RRT_NS, id) end
    if RRT_NS.AddAssignments[encounterID] and RRT_NS:IsUsingTLAssignments() then RRT_NS.AddAssignments[encounterID](RRT_NS, id) end
    if RRT_NS.EncounterAlertStop[encounterID] and (RRT_NS:IsUsingTLAlerts() or RRT_NS:IsUsingTLAssignments()) then RRT_NS.EncounterAlertStop[encounterID](RRT_NS) end
    return RRT_NS.TLAlerts
end