local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Bar frame creation per custom frame
-------------------------------------------------------------------------------

function ST._BuildBarFrame(frameIndex)
    if (ST.displayFrames[frameIndex]) then return; end
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return; end

    local frame = CreateFrame("Frame", "ReversionRaidTools_Frame" .. frameIndex, UIParent);
    frame:SetSize(frameConfig.barWidth, 200);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150);
    frame:SetFrameStrata("MEDIUM");
    frame:SetClampedToScreen(true);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", function(self)
        if (not frameConfig.locked or IsShiftKeyDown()) then
            self:StartMoving();
        end
    end);
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        ST._SavePosition(frameIndex);
    end);
    frame:SetAlpha(frameConfig.barAlpha);
    frame:SetScale(frameConfig.displayScale or 1);

    local title = ST._CreateTitleBar(frame, frameIndex, frameConfig);

    local bh = math.max(12, frameConfig.barHeight);
    local spacing = math.max(0, frameConfig.iconSpacing or 2);
    local iconSize = bh;
    local barW = math.max(60, frameConfig.barWidth - iconSize);
    local nameFontSize = math.max(9, math.floor(bh * 0.45));
    local cdFontSize = math.max(10, math.floor(bh * 0.55));
    local fontPath = ST._GetFontPath(frameConfig.font);
    local outline = frameConfig.fontOutline or "OUTLINE";

    local barPool = {};
    for i = 1, ST._BAR_POOL_SIZE do
        local yOff = frameConfig.growUp
            and ((i - 1) * (bh + spacing))
            or (-((i - 1) * (bh + spacing)));

        local row = CreateFrame("Frame", ST._FrameName("BarRow"), frame);
        row:SetSize(iconSize + barW, bh);
        if (frameConfig.growUp) then
            row:SetPoint("BOTTOMLEFT", 0, yOff);
        else
            row:SetPoint("TOPLEFT", 0, yOff);
        end

        local ico = row:CreateTexture(nil, "ARTWORK");
        ico:SetSize(iconSize, bh);
        ico:SetPoint("LEFT", 0, 0);
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92);
        row.icon = ico;

        local barBg = row:CreateTexture(nil, "BACKGROUND");
        barBg:SetPoint("TOPLEFT", iconSize, 0);
        barBg:SetPoint("BOTTOMRIGHT", 0, 0);
        barBg:SetTexture(ST._SOLID);
        barBg:SetVertexColor(0.15, 0.15, 0.15, 1);
        row.barBg = barBg;

        local sb = CreateFrame("StatusBar", ST._FrameName("BarStatus"), row);
        sb:SetPoint("TOPLEFT", iconSize, 0);
        sb:SetPoint("BOTTOMRIGHT", 0, 0);
        sb:SetStatusBarTexture(ST._SOLID);
        sb:SetStatusBarColor(1, 1, 1, 0.85);
        sb:SetMinMaxValues(0, 1);
        sb:SetValue(0);
        sb:SetFrameLevel(row:GetFrameLevel() + 1);
        row.cdBar = sb;

        local overlay = CreateFrame("Frame", ST._FrameName("BarOverlay"), row);
        overlay:SetPoint("TOPLEFT", iconSize, 0);
        overlay:SetPoint("BOTTOMRIGHT", 0, 0);
        overlay:SetFrameLevel(sb:GetFrameLevel() + 1);
        row.overlay = overlay;

        local nameStr = overlay:CreateFontString(nil, "OVERLAY");
        nameStr:SetFont(fontPath, nameFontSize, outline);
        nameStr:SetPoint("LEFT", 6, 0);
        nameStr:SetJustifyH("LEFT");
        nameStr:SetWidth(barW - 50);
        nameStr:SetWordWrap(false);
        nameStr:SetShadowOffset(1, -1);
        nameStr:SetShadowColor(0, 0, 0, 1);
        row.nameText = nameStr;

        local cdStr = overlay:CreateFontString(nil, "OVERLAY");
        cdStr:SetFont(fontPath, cdFontSize, outline);
        cdStr:SetPoint("RIGHT", -6, 0);
        cdStr:SetShadowOffset(1, -1);
        cdStr:SetShadowColor(0, 0, 0, 1);
        row.cdText = cdStr;

        row:Hide();
        barPool[i] = row;
    end

    local display = {
        frame   = frame,
        title   = title,
        barPool = barPool,
    };
    ST.displayFrames[frameIndex] = display;

    ST._RestorePosition(frameIndex);
    frame:Hide();
end

-------------------------------------------------------------------------------
-- Render bar mode for a custom frame
-------------------------------------------------------------------------------

function ST._RenderBarFrame(frameIndex)
    local display = ST.displayFrames[frameIndex];
    if (not display or not display.frame) then return; end
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return; end
    local bh = math.max(12, frameConfig.barHeight);
    local spacing = math.max(0, frameConfig.iconSpacing or 2);

    local entries = ST._CollectSortedEntries(frameIndex);

    for i = 1, ST._BAR_POOL_SIZE do
        local bar = display.barPool[i];
        local entry = entries[i];

        if (entry) then
            bar:Show();

            local tex = ST._GetSpellTexture(entry.spellID);
            if (tex) then
                bar.icon:SetTexture(tex);
            end

            local cr, cg, cb = ST:GetClassColor(entry.class);

            if (frameConfig.isInterruptFrame and not frameConfig.showNames) then
                bar.nameText:SetText("");
            else
                bar.nameText:SetText("|cFFFFFFFF" .. entry.name .. "|r");
            end

            if (entry.state == "ready") then
                bar.cdBar:SetMinMaxValues(0, 1);
                bar.cdBar:SetValue(0);
                bar.barBg:SetVertexColor(cr * 0.6, cg * 0.6, cb * 0.6, 1);
                bar.cdText:SetText("READY");
                bar.cdText:SetTextColor(0.2, 1.0, 0.2);
            elseif (entry.state == "active") then
                local spellData = ST.spellDB[entry.spellID];
                local totalDur = spellData and spellData.duration or 1;
                bar.cdBar:SetMinMaxValues(0, totalDur);
                bar.cdBar:SetValue(entry.remaining);
                bar.cdBar:SetStatusBarColor(0.9, 0.77, 0.1);
                bar.barBg:SetVertexColor(cr * 0.25, cg * 0.25, cb * 0.25, 1);
                bar.cdText:SetText(ST._FormatTime(entry.remaining));
                bar.cdText:SetTextColor(1, 0.9, 0.3);
            elseif (entry.state == "cooldown") then
                bar.cdBar:SetMinMaxValues(0, entry.baseCd);
                bar.cdBar:SetValue(entry.remaining);
                bar.cdBar:SetStatusBarColor(cr * 0.5, cg * 0.5, cb * 0.5);
                bar.barBg:SetVertexColor(cr * 0.15, cg * 0.15, cb * 0.15, 1);
                bar.cdText:SetText(ST._FormatTime(entry.remaining));
                bar.cdText:SetTextColor(1, 1, 1);
            end
        else
            bar:Hide();
        end
    end

    local numVisible = math.min(#entries, ST._BAR_POOL_SIZE);
    if (numVisible > 0) then
        display.frame:SetHeight(numVisible * (bh + spacing) + 2);
    end
    if (ST._ApplyInterruptAnchor) then
        ST._ApplyInterruptAnchor(frameIndex);
    end
end

-------------------------------------------------------------------------------
-- Layout refresh (for settings changes)
-------------------------------------------------------------------------------

function ST:RefreshBarLayout(frameIndex)
    local display = self.displayFrames[frameIndex];
    if (not display or not display.frame) then return; end
    local frameConfig = self:GetFrameConfig(frameIndex);
    if (not frameConfig) then return; end

    local fontPath = ST._GetFontPath(frameConfig.font);
    local outline = frameConfig.fontOutline or "OUTLINE";
    local bh = math.max(12, frameConfig.barHeight);
    local spacing = math.max(0, frameConfig.iconSpacing or 2);
    local iconSize = bh;
    local barW = math.max(60, frameConfig.barWidth - iconSize);
    local nameFontSize = math.max(9, math.floor(bh * 0.45));
    local cdFontSize = math.max(10, math.floor(bh * 0.55));

    display.frame:SetWidth(frameConfig.barWidth);
    display.frame:SetAlpha(frameConfig.barAlpha);
    display.frame:SetScale(frameConfig.displayScale or 1);

    if (display.title) then
        local label = frameConfig.isInterruptFrame and "Interrupts" or (frameConfig.name or ("Frame " .. frameIndex));
        if (display.title.text) then
            display.title.text:SetFont(fontPath, 12, outline);
        end
        if (frameConfig.locked) then
            display.title:Hide();
        else
            display.title:Show();
            display.title.text:SetText("|cFF4DB7FF" .. label .. " (unlocked)|r");
        end
    end

    for i = 1, ST._BAR_POOL_SIZE do
        local bar = display.barPool[i];
        if (bar) then
            bar:SetSize(iconSize + barW, bh);
            bar.icon:SetSize(iconSize, bh);
            bar:ClearAllPoints();
            local yOff = frameConfig.growUp
                and ((i - 1) * (bh + spacing))
                or (-((i - 1) * (bh + spacing)));
            if (frameConfig.growUp) then
                bar:SetPoint("BOTTOMLEFT", 0, yOff);
            else
                bar:SetPoint("TOPLEFT", 0, yOff);
            end
            bar.barBg:ClearAllPoints();
            bar.barBg:SetPoint("TOPLEFT", iconSize, 0);
            bar.barBg:SetPoint("BOTTOMRIGHT", 0, 0);
            bar.cdBar:ClearAllPoints();
            bar.cdBar:SetPoint("TOPLEFT", iconSize, 0);
            bar.cdBar:SetPoint("BOTTOMRIGHT", 0, 0);
            if (bar.overlay) then
                bar.overlay:ClearAllPoints();
                bar.overlay:SetPoint("TOPLEFT", iconSize, 0);
                bar.overlay:SetPoint("BOTTOMRIGHT", 0, 0);
            end
            bar.nameText:SetWidth(barW - 50);
            bar.nameText:SetFont(fontPath, nameFontSize, outline);
            bar.cdText:SetFont(fontPath, cdFontSize, outline);
        end
    end
end
