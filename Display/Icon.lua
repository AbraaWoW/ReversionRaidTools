local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Icon frame creation per custom frame
-------------------------------------------------------------------------------

function ST._BuildIconFrame(frameIndex)
    if (ST.displayFrames[frameIndex]) then return; end
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return; end

    local frame = CreateFrame("Frame", "ReversionRaidTools_Frame" .. frameIndex, UIParent);
    frame:SetSize(200, 200);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150);
    frame:SetFrameStrata("MEDIUM");
    frame:SetClampedToScreen(true);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    frame:SetAlpha(frameConfig.barAlpha or 1);
    frame:SetScale(frameConfig.displayScale or 1);
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

    local title = ST._CreateTitleBar(frame, frameIndex, frameConfig);

    local iconPool = {};
    for i = 1, ST._ICON_POOL_SIZE do
        iconPool[i] = ST._CreateSpellIcon(frame, frameConfig.iconSize);
    end

    local namePool = {};
    for i = 1, 40 do
        local nameLabel = frame:CreateFontString(nil, "OVERLAY");
        nameLabel:SetFont(ST._GetFontPath(frameConfig.font), 12, frameConfig.fontOutline or "OUTLINE");
        nameLabel:SetJustifyH("LEFT");
        nameLabel:SetShadowOffset(1, -1);
        nameLabel:SetShadowColor(0, 0, 0, 1);
        nameLabel:Hide();
        namePool[i] = nameLabel;
    end

    local display = {
        frame    = frame,
        title    = title,
        iconPool = iconPool,
        namePool = namePool,
    };
    ST.displayFrames[frameIndex] = display;

    ST._RestorePosition(frameIndex);
    frame:Hide();
end

-------------------------------------------------------------------------------
-- Render icon mode for a custom frame
-------------------------------------------------------------------------------

function ST._RenderIconFrame(frameIndex)
    local display = ST.displayFrames[frameIndex];
    if (not display or not display.frame) then return; end
    if (not display.iconPool) then return; end
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return; end
    local iconSize = frameConfig.iconSize;
    local spacing = frameConfig.iconSpacing;
    local showNames = frameConfig.showNames;
    local fontPath = ST._GetFontPath(frameConfig.font);
    local outline = frameConfig.fontOutline or "OUTLINE";

    -- Hide everything first
    for _, ico in ipairs(display.iconPool) do ico:Hide(); end
    for _, lbl in ipairs(display.namePool) do lbl:Hide(); end

    -- Group entries by player
    local playerOrder = {};
    local playerSpells = {};
    local now = GetTime();

    for playerName, player in pairs(ST.trackedPlayers) do
        local isSelf = (playerName == ST.playerName);
        if (not isSelf or frameConfig.showSelf) then
            local spells = ST._CollectPlayerFrameSpells(player, frameConfig);
            if (#spells > 0) then
                table.insert(playerOrder, { name = playerName, class = player.class, isSelf = isSelf });
                playerSpells[playerName] = spells;
            end
        end
    end

    -- Sort players: self on top, then alphabetical
    table.sort(playerOrder, function(a, b)
        if (frameConfig.selfOnTop and a.isSelf ~= b.isSelf) then return a.isSelf; end
        return a.name < b.name;
    end);

    -- Layout
    local y = 0;
    local iconIdx = 1;
    local nameIdx = 1;
    local maxWidth = 0;
    local growUp = frameConfig.growUp;

    for _, playerInfo in ipairs(playerOrder) do
        local spells = playerSpells[playerInfo.name];
        if (not spells) then break; end

        if (showNames and nameIdx <= #display.namePool) then
            local lbl = display.namePool[nameIdx];
            lbl:SetFont(fontPath, 11, outline);
            local cr, cg, cb = ST:GetClassColor(playerInfo.class);
            lbl:SetTextColor(cr, cg, cb);
            lbl:SetText(playerInfo.name);
            lbl:ClearAllPoints();
            if (growUp) then
                lbl:SetPoint("BOTTOMLEFT", display.frame, "BOTTOMLEFT", 0, y);
            else
                lbl:SetPoint("TOPLEFT", display.frame, "TOPLEFT", 0, -y);
            end
            lbl:Show();
            nameIdx = nameIdx + 1;
            y = y + 14;
        end

        local x = 0;
        for _, spell in ipairs(spells) do
            if (iconIdx > ST._ICON_POOL_SIZE) then break; end
            local ico = display.iconPool[iconIdx];
            ico:SetSize(iconSize, iconSize);

            ico:ClearAllPoints();
            if (growUp) then
                ico:SetPoint("BOTTOMLEFT", display.frame, "BOTTOMLEFT", x, y);
            else
                ico:SetPoint("TOPLEFT", display.frame, "TOPLEFT", x, -y);
            end

            ST._ApplyIconState(ico, spell.state, spell.spellID, spell.cdEnd, spell.activeEnd, spell.baseCd, now);

            ico:Show();
            iconIdx = iconIdx + 1;
            x = x + iconSize + spacing;
        end

        if (x > maxWidth) then maxWidth = x; end
        y = y + iconSize + spacing + 2;
    end

    if (maxWidth > 0 and y > 0) then
        display.frame:SetSize(math.max(maxWidth, 100), y);
    end
    if (ST._ApplyInterruptAnchor) then
        ST._ApplyInterruptAnchor(frameIndex);
    end
end

-------------------------------------------------------------------------------
-- Layout refresh (for settings changes)
-------------------------------------------------------------------------------

function ST:RefreshIconLayout(frameIndex)
    local display = self.displayFrames[frameIndex];
    if (not display or not display.frame) then return; end
    if (not display.iconPool) then return; end
    local frameConfig = self:GetFrameConfig(frameIndex);
    if (not frameConfig) then return; end

    local fontPath = ST._GetFontPath(frameConfig.font);
    local outline = frameConfig.fontOutline or "OUTLINE";
    local iconSize = frameConfig.iconSize;
    local alpha = frameConfig.barAlpha or 1;
    local scale = frameConfig.displayScale or 1;
    display.frame:SetAlpha(alpha);
    display.frame:SetScale(scale);

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

    for _, ico in ipairs(display.iconPool) do
        ico:SetSize(iconSize, iconSize);
        if (ico.text) then
            local timerFontSize = math.max(10, math.floor(iconSize * 0.45));
            ico.text:SetFont(fontPath, timerFontSize, outline);
        end
    end

    for _, lbl in ipairs(display.namePool) do
        lbl:SetFont(fontPath, 11, outline);
    end

    ST._RenderIconFrame(frameIndex);
end
