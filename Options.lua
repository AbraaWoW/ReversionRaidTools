local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FONT = "Fonts\\FRIZQT__.TTF";
local FRAME_WIDTH = 1000;
local FRAME_HEIGHT = 700;
local FRAME_NAME = "ReversionRaidToolsOptions";

local COLOR_BG          = { 0.08, 0.08, 0.08, 0.95 };
local COLOR_SECTION     = { 0.12, 0.12, 0.12, 1.0 };
local COLOR_ACCENT      = { 0.30, 0.72, 1.00 };
local COLOR_LABEL       = { 0.85, 0.85, 0.85 };
local COLOR_MUTED       = { 0.55, 0.55, 0.55 };
local COLOR_BTN         = { 0.18, 0.18, 0.18, 1.0 };
local COLOR_BTN_HOVER   = { 0.25, 0.25, 0.25, 1.0 };
local COLOR_DANGER      = { 0.8, 0.2, 0.2 };
local COLOR_BORDER      = { 0.2, 0.2, 0.2, 1.0 };
local COLOR_TAB_ACTIVE  = { 0.2, 0.2, 0.2, 1.0 };
local COLOR_TAB_IDLE    = { 0.1, 0.1, 0.1, 1.0 };
local SIDEBAR_WIDTH     = 176;
local COLUMN_GAP        = 10;
local LAYOUT_OPTIONS = { "bar", "icon" };
local LAYOUT_LABELS  = { bar = "Bar", icon = "Icon" };
local GROW_DIR_OPTIONS = { "down", "up" };
local GROW_DIR_LABELS  = { down = "Down", up = "Up" };
local SORT_MODE_OPTIONS = { "remaining", "basecd" };
local SORT_MODE_LABELS  = { remaining = "Remaining", basecd = "Base CD" };
local GROUP_MODE_OPTIONS = { "any", "party", "raid" };
local GROUP_MODE_LABELS  = { any = "Any Group", party = "Party Only (5)", raid = "Raid Only" };
local PREVIEW_MODE_OPTIONS = { "party5", "raid20", "raid40" };
local PREVIEW_MODE_LABELS  = { party5 = "Group (5)", raid20 = "Raid (20)", raid40 = "Raid (40)" };
local OUTLINE_OPTIONS = { "", "OUTLINE", "THICKOUTLINE" };
local OUTLINE_LABELS  = {
    [""] = "None",
    OUTLINE = "Outline",
    THICKOUTLINE = "Thick Outline",
};

local PADDING = 12;
local ROW_HEIGHT = 26;
local SLIDER_HEIGHT = 20;

-- Class display names
local CLASS_DISPLAY_NAMES = {
    WARRIOR     = "Warrior",
    PALADIN     = "Paladin",
    HUNTER      = "Hunter",
    ROGUE       = "Rogue",
    PRIEST      = "Priest",
    DEATHKNIGHT = "Death Knight",
    SHAMAN      = "Shaman",
    MAGE        = "Mage",
    WARLOCK     = "Warlock",
    MONK        = "Monk",
    DRUID       = "Druid",
    DEMONHUNTER = "Demon Hunter",
    EVOKER      = "Evoker",
};

local CLASS_ORDER = {
    "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER",
    "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE",
    "SHAMAN", "WARLOCK", "WARRIOR",
};

local INTERRUPT_EN_NAMES = {
    [47528]  = "Mind Freeze",
    [183752] = "Disrupt",
    [106839] = "Skull Bash",
    [78675]  = "Solar Beam",
    [351338] = "Quell",
    [147362] = "Counter Shot",
    [187707] = "Muzzle",
    [2139]   = "Counterspell",
    [116705] = "Spear Hand Strike",
    [96231]  = "Rebuke",
    [15487]  = "Silence",
    [1766]   = "Kick",
    [57994]  = "Wind Shear",
    [19647]  = "Spell Lock",
    [132409] = "Spell Lock",
    [89766]  = "Axe Toss",
    [6552]   = "Pummel",
};

-- Per-frame expanded tab state: frameIndex -> "settings" or "spells"
local _frameTabs = {};
-- Per-frame expanded state: frameIndex -> bool
local _frameExpanded = {};
local _selectedFrameIndex = 1;

local function GetContentWidth(parent)
    if (not parent or not parent.GetWidth) then return FRAME_WIDTH; end
    local w = parent:GetWidth();
    if (not w or w <= 0) then return FRAME_WIDTH; end
    return w;
end

local function SkinPanel(frame, bgColor, borderColor)
    if (not frame) then return; end
    if (not frame.SetBackdrop) then
        Mixin(frame, BackdropTemplateMixin);
    end
    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    });
    frame:SetBackdropColor(unpack(bgColor or COLOR_SECTION));
    frame:SetBackdropBorderColor(unpack(borderColor or COLOR_BORDER));
end

local function SkinButton(btn, color, hoverColor, textColor)
    local bg = btn:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    bg:SetVertexColor(unpack(color or COLOR_BTN));
    btn._bg = bg;

    btn:SetScript("OnEnter", function(self)
        self._bg:SetVertexColor(unpack(hoverColor or COLOR_BTN_HOVER));
    end);
    btn:SetScript("OnLeave", function(self)
        self._bg:SetVertexColor(unpack(color or COLOR_BTN));
    end);

    if (textColor) then
        btn._textColor = textColor;
    end
end

-------------------------------------------------------------------------------
-- Widget Helpers
-------------------------------------------------------------------------------

local function CreateSectionHeader(parent, text, yOff, width)
    local holder = CreateFrame("Frame", nil, parent);
    holder:SetPoint("TOPLEFT", PADDING, yOff);
    holder:SetPoint("TOPRIGHT", -PADDING, yOff);
    holder:SetHeight(24);
    SkinPanel(holder, COLOR_SECTION, COLOR_BORDER);

    local label = holder:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 13, "OUTLINE");
    label:SetPoint("LEFT", 8, 0);
    label:SetTextColor(unpack(COLOR_ACCENT));
    label:SetText(text);

    return holder, yOff - 28;
end

local function CreateCheckbox(parent, xOff, yOff, text, checked, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
    cb:SetPoint("TOPLEFT", xOff, yOff);
    cb:SetSize(22, 22);
    cb:SetChecked(checked);

    local label = cb:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 12);
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0);
    label:SetTextColor(unpack(COLOR_LABEL));
    label:SetText(text);
    cb.label = label;

    cb:SetScript("OnClick", function(self)
        local val = self:GetChecked();
        if (onChange) then onChange(val); end
    end);

    return cb;
end

local function CreateDropdown(parent, xOff, yOff, labelText, options, labels, currentValue, onChange)
    local parentWidth = GetContentWidth(parent);
    local holder = CreateFrame("Frame", nil, parent);
    holder:SetPoint("TOPLEFT", xOff, yOff);
    holder:SetSize(parentWidth - PADDING * 2 - xOff + PADDING, ROW_HEIGHT);

    local label = holder:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 11);
    label:SetPoint("LEFT", 0, 0);
    label:SetTextColor(unpack(COLOR_MUTED));
    label:SetText(labelText);

    local btn = CreateFrame("Button", nil, holder);
    btn:SetPoint("LEFT", 80, 0);
    btn:SetSize(140, ROW_HEIGHT - 2);
    SkinButton(btn, COLOR_BTN, COLOR_BTN_HOVER);

    local btnText = btn:CreateFontString(nil, "OVERLAY");
    btnText:SetFont(FONT, 11);
    btnText:SetPoint("LEFT", 6, 0);
    btnText:SetTextColor(unpack(COLOR_LABEL));
    btnText:SetText(labels[currentValue] or currentValue);
    btn.text = btnText;

    local arrow = btn:CreateFontString(nil, "OVERLAY");
    arrow:SetFont(FONT, 9);
    arrow:SetPoint("RIGHT", -6, 0);
    arrow:SetTextColor(unpack(COLOR_MUTED));
    arrow:SetText("v");

    btn:SetScript("OnClick", function()
        MenuUtil.CreateContextMenu(btn, function(_, rootDescription)
            for _, opt in ipairs(options) do
                local text = labels[opt] or opt;
                rootDescription:CreateRadio(text,
                    function() return currentValue == opt; end,
                    function()
                        currentValue = opt;
                        btnText:SetText(text);
                        if (onChange) then onChange(opt); end
                    end
                );
            end
        end);
    end);

    return holder;
end

local function CreateSlider(parent, xOff, yOff, labelText, minVal, maxVal, step, currentValue, onChange)
    local parentWidth = GetContentWidth(parent);
    local holder = CreateFrame("Frame", nil, parent);
    holder:SetPoint("TOPLEFT", xOff, yOff);
    holder:SetSize(parentWidth - PADDING * 2 - xOff + PADDING, 40);

    local label = holder:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 11);
    label:SetPoint("TOPLEFT", 0, 0);
    label:SetTextColor(unpack(COLOR_MUTED));
    label:SetText(labelText);

    local slider = CreateFrame("Slider", nil, holder, "OptionsSliderTemplate");
    slider:SetPoint("TOPLEFT", 0, -16);
    slider:SetSize(180, SLIDER_HEIGHT);
    slider:SetMinMaxValues(minVal, maxVal);
    slider:SetValueStep(step or 1);
    slider:SetObeyStepOnDrag(true);
    slider:SetValue(currentValue);

    slider.Text:SetText(""); slider.Text:Hide();
    slider.Low:SetText(""); slider.Low:Hide();
    slider.High:SetText(""); slider.High:Hide();

    local valueText = holder:CreateFontString(nil, "OVERLAY");
    valueText:SetFont(FONT, 11);
    valueText:SetPoint("LEFT", slider, "RIGHT", 8, 0);
    valueText:SetTextColor(unpack(COLOR_LABEL));
    valueText:SetText(math.floor(currentValue));

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5);
        valueText:SetText(value);
        if (onChange) then onChange(value); end
    end);

    return holder;
end

local function CreateActionButton(parent, xOff, yOff, text, width, onClick, color)
    local btn = CreateFrame("Button", nil, parent);
    btn:SetPoint("TOPLEFT", xOff, yOff);
    btn:SetSize(width, ROW_HEIGHT);
    SkinButton(btn, color or COLOR_BTN, COLOR_BTN_HOVER);

    local btnText = btn:CreateFontString(nil, "OVERLAY");
    btnText:SetFont(FONT, 11);
    btnText:SetPoint("CENTER", 0, 0);
    btnText:SetTextColor(unpack(COLOR_LABEL));
    btnText:SetText(text);

    btn:SetScript("OnClick", onClick);

    return btn;
end

local function CreateTextInput(parent, xOff, yOff, labelText, currentValue, onChange)
    local parentWidth = GetContentWidth(parent);
    local holder = CreateFrame("Frame", nil, parent);
    holder:SetPoint("TOPLEFT", xOff, yOff);
    holder:SetSize(parentWidth - PADDING * 2 - xOff + PADDING, ROW_HEIGHT);

    local label = holder:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 11);
    label:SetPoint("LEFT", 0, 0);
    label:SetTextColor(unpack(COLOR_MUTED));
    label:SetText(labelText);

    local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate");
    editBox:SetPoint("LEFT", 80, 0);
    editBox:SetSize(200, ROW_HEIGHT - 4);
    editBox:SetAutoFocus(false);
    if (editBox.SetFontObject and ChatFontNormal) then
        editBox:SetFontObject(ChatFontNormal);
    end
    editBox:SetText(currentValue or "");
    if (editBox.SetBackdrop and editBox.SetBackdropColor and editBox.SetBackdropBorderColor) then
        editBox:SetBackdrop({
            bgFile   = "Interface\\BUTTONS\\WHITE8X8",
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
        });
        editBox:SetBackdropColor(0.06, 0.06, 0.06, 0.95);
        editBox:SetBackdropBorderColor(unpack(COLOR_BORDER));
    end
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus();
        if (onChange) then onChange(self:GetText()); end
    end);
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);

    return holder;
end

local function CreateNameInput(parent, xOff, yOff, currentValue, onChange)
    local parentWidth = GetContentWidth(parent);
    local holder = CreateFrame("Frame", nil, parent);
    holder:SetPoint("TOPLEFT", xOff, yOff);
    holder:SetSize(parentWidth - PADDING * 2 - xOff + PADDING, 46);

    local label = holder:CreateFontString(nil, "OVERLAY");
    label:SetFont(FONT, 10, "OUTLINE");
    label:SetPoint("TOPLEFT", 0, 0);
    label:SetTextColor(unpack(COLOR_MUTED));
    label:SetText("Frame Name");

    local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate");
    editBox:SetPoint("TOPLEFT", 0, -16);
    editBox:SetPoint("TOPRIGHT", -8, -16);
    editBox:SetHeight(24);
    editBox:SetAutoFocus(false);
    if (editBox.SetFontObject and ChatFontNormal) then
        editBox:SetFontObject(ChatFontNormal);
    end
    editBox:SetText(currentValue or "");
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus();
        if (onChange) then onChange(self:GetText()); end
    end);
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);

    return holder;
end

-------------------------------------------------------------------------------
-- Options Frame
-------------------------------------------------------------------------------

local _optionsFrame = nil;
local _contentChildren = {};
local _profileDraftName = "Profile 1";
local _mainTab = "frames";
local _selectedProfileName = nil;

local function DeepCopyTable(src)
    if (type(src) ~= "table") then return src; end
    local out = {};
    for k, v in pairs(src) do
        out[k] = DeepCopyTable(v);
    end
    return out;
end

ST.DeepCopyTable = DeepCopyTable;

local function DestroyContent()
    for _, child in ipairs(_contentChildren) do
        if (child.UnregisterAllEvents) then child:UnregisterAllEvents(); end
        child:Hide();
        child:SetParent(nil);
    end
    wipe(_contentChildren);
end

local function Track(widget)
    table.insert(_contentChildren, widget);
    return widget;
end

local BuildContent;

-------------------------------------------------------------------------------
-- Frame Settings Tab
-------------------------------------------------------------------------------

local function BuildFrameSettings(content, frameIndex, yOff)
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return yOff; end

    local function DestroyAndRefresh()
        local display = ST.displayFrames[frameIndex];
        if (display) then
            if (display.frame) then display.frame:Hide(); display.frame:SetParent(nil); end
            ST.displayFrames[frameIndex] = nil;
        end
        ST:RefreshDisplay();
    end

    -- Name
    Track(CreateNameInput(content, PADDING + 4, yOff, frameConfig.name, function(val)
        frameConfig.name = val;
        DestroyAndRefresh();
    end));
    yOff = yOff - 48;

    -- Enable
    Track(CreateCheckbox(content, PADDING + 4, yOff, "Enable", frameConfig.enabled, function(val)
        frameConfig.enabled = val;
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Order
    Track(CreateDropdown(content, PADDING + 4, yOff, "Order", SORT_MODE_OPTIONS, SORT_MODE_LABELS, frameConfig.sortMode or "remaining", function(val)
        frameConfig.sortMode = val;
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Show Self + Self On Top
    Track(CreateCheckbox(content, PADDING + 4, yOff, "Show Self", frameConfig.showSelf, function(val)
        frameConfig.showSelf = val;
        ST:RefreshDisplay();
    end));
    Track(CreateCheckbox(content, PADDING + 160, yOff, "Self On Top", frameConfig.selfOnTop, function(val)
        frameConfig.selfOnTop = val;
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    local layout = frameConfig.layout or "bar";

    if (layout == "bar") then
        Track(CreateSlider(content, PADDING + 4, yOff, "Bar Width", 120, 400, 1, frameConfig.barWidth, function(val)
            frameConfig.barWidth = val;
            ST:RefreshBarLayout(frameIndex);
            ST:RefreshDisplay();
        end));
        yOff = yOff - 44;

        Track(CreateSlider(content, PADDING + 4, yOff, "Bar Height", 16, 40, 1, frameConfig.barHeight, function(val)
            frameConfig.barHeight = val;
            ST:RefreshBarLayout(frameIndex);
            ST:RefreshDisplay();
        end));
        yOff = yOff - 44;

    elseif (layout == "icon") then
        Track(CreateSlider(content, PADDING + 4, yOff, "Icon Size", 16, 48, 1, frameConfig.iconSize, function(val)
            frameConfig.iconSize = val;
            ST:RefreshIconLayout(frameIndex);
        end));
        yOff = yOff - 44;

        Track(CreateCheckbox(content, PADDING + 4, yOff, "Show Names", frameConfig.showNames, function(val)
            frameConfig.showNames = val;
            ST:RefreshDisplay();
        end));
        yOff = yOff - ROW_HEIGHT;
    end

    -- Grow Direction (relevant for bars layout)
    if ((frameConfig.layout or "bar") == "bar") then
        local growDir = frameConfig.growUp and "up" or "down";
        Track(CreateDropdown(content, PADDING + 4, yOff, "Grow", GROW_DIR_OPTIONS, GROW_DIR_LABELS, growDir, function(val)
            frameConfig.growUp = (val == "up");
            DestroyAndRefresh();
        end));
        yOff = yOff - ROW_HEIGHT;
    end

    -- Lock + Reset Position
    Track(CreateCheckbox(content, PADDING + 4, yOff, "Lock Position", frameConfig.locked, function(val)
        frameConfig.locked = val;
        local display = ST.displayFrames[frameIndex];
        if (display and display.title) then
            if (val) then display.title:Hide(); else display.title:Show(); end
        end
    end));
    yOff = yOff - ROW_HEIGHT;

    Track(CreateActionButton(content, PADDING + 4, yOff, "Reset Frame Position", 180, function()
        ST:ResetPosition(frameIndex);
        ST:Print(frameConfig.name .. " position reset.");
    end));
    yOff = yOff - ROW_HEIGHT - 8;

    return yOff;
end

-------------------------------------------------------------------------------
-- Frame Spells Tab
-------------------------------------------------------------------------------

local function BuildFrameSpells(content, frameIndex, yOff)
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return yOff; end

    local selectedSpells = frameConfig.spells;

    -- Organize spells by class then by category (interrupts excluded)
    local spellsByClass = {};
    for id, spell in pairs(ST.spellDB) do
        if (spell.category ~= "interrupt") then
            local cls = spell.class;
            if (not spellsByClass[cls]) then spellsByClass[cls] = {}; end
            table.insert(spellsByClass[cls], {
                id       = id,
                category = spell.category,
                name     = C_Spell.GetSpellName(id) or ("Spell " .. id),
            });
        end
    end

    -- Sort spells within each class by category then name
    local CATEGORY_ORDER = { interrupt = 1, defensive = 2, cooldown = 3 };
    for _, spells in pairs(spellsByClass) do
        table.sort(spells, function(a, b)
            local ao = CATEGORY_ORDER[a.category] or 99;
            local bo = CATEGORY_ORDER[b.category] or 99;
            if (ao ~= bo) then return ao < bo; end
            return a.name < b.name;
        end);
    end

    -- Select All / Deselect All buttons
    Track(CreateActionButton(content, PADDING + 4, yOff, "Select All", 100, function()
        for id, spell in pairs(ST.spellDB) do
            if (spell.category ~= "interrupt") then
                selectedSpells[id] = true;
            end
        end
        ST:RefreshDisplay();
        if (_optionsFrame and _optionsFrame:IsShown()) then BuildContent(); end
    end));
    Track(CreateActionButton(content, PADDING + 110, yOff, "Deselect All", 100, function()
        wipe(selectedSpells);
        ST:RefreshDisplay();
        if (_optionsFrame and _optionsFrame:IsShown()) then BuildContent(); end
    end));
    Track(CreateActionButton(content, PADDING + 216, yOff, "All Def", 100, function()
        for id, spell in pairs(ST.spellDB) do
            if (spell.category == "defensive") then
                selectedSpells[id] = true;
            end
        end
        ST:RefreshDisplay();
        if (_optionsFrame and _optionsFrame:IsShown()) then BuildContent(); end
    end));
    Track(CreateActionButton(content, PADDING + 322, yOff, "All Cooldown", 120, function()
        for id, spell in pairs(ST.spellDB) do
            if (spell.category == "cooldown") then
                selectedSpells[id] = true;
            end
        end
        ST:RefreshDisplay();
        if (_optionsFrame and _optionsFrame:IsShown()) then BuildContent(); end
    end));
    yOff = yOff - ROW_HEIGHT - 12;

    local function CreateCompactSpellToggle(parent, x, y, width, spellID, text, checked, onToggle)
        local row = CreateFrame("Button", nil, parent);
        row:SetPoint("TOPLEFT", x, y);
        row:SetSize(width, 19);
        Track(row);

        local icon = row:CreateTexture(nil, "ARTWORK");
        icon:SetPoint("LEFT", 0, 0);
        icon:SetSize(14, 14);
        icon:SetTexture(ST._GetSpellTexture(spellID));
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

        local box = row:CreateTexture(nil, "ARTWORK");
        box:SetPoint("LEFT", 20, 0);
        box:SetSize(12, 12);
        box:SetTexture("Interface\\BUTTONS\\WHITE8X8");
        box:SetVertexColor(0.12, 0.12, 0.12, 1);

        local boxBorder = row:CreateTexture(nil, "BORDER");
        boxBorder:SetPoint("TOPLEFT", box, -1, 1);
        boxBorder:SetPoint("BOTTOMRIGHT", box, 1, -1);
        boxBorder:SetTexture("Interface\\BUTTONS\\WHITE8X8");
        boxBorder:SetVertexColor(unpack(COLOR_BORDER));

        local mark = row:CreateFontString(nil, "OVERLAY");
        mark:SetFont(FONT, 10, "OUTLINE");
        mark:SetPoint("CENTER", box, "CENTER", 0, 0);
        mark:SetTextColor(unpack(COLOR_ACCENT));
        mark:SetText(checked and "x" or "");

        local label = row:CreateFontString(nil, "OVERLAY");
        label:SetFont(FONT, 11);
        label:SetPoint("LEFT", 37, 0);
        label:SetTextColor(unpack(COLOR_LABEL));
        label:SetWidth(width - 38);
        label:SetJustifyH("LEFT");
        label:SetWordWrap(false);
        label:SetText(text);

        row:SetScript("OnClick", function()
            checked = not checked;
            mark:SetText(checked and "x" or "");
            if (onToggle) then onToggle(checked); end
        end);
    end

    local classSections = {};
    for _, cls in ipairs(CLASS_ORDER) do
        local classSpells = spellsByClass[cls];
        if (classSpells and #classSpells > 0) then
            table.insert(classSections, {
                cls = cls,
                spells = classSpells,
                height = 18 + (#classSpells * 20) + 10,
            });
        end
    end

    local parentWidth = GetContentWidth(content);
    local availableWidth = parentWidth - ((PADDING + 4) * 2);
    local colCount = 2;
    local colGap = 10;
    local colWidth = math.floor((availableWidth - ((colCount - 1) * colGap)) / colCount);

    local columns = {};
    local colHeights = {};
    for i = 1, colCount do
        columns[i] = {};
        colHeights[i] = 0;
    end
    for _, section in ipairs(classSections) do
        local target = 1;
        for i = 2, colCount do
            if (colHeights[i] < colHeights[target]) then
                target = i;
            end
        end
        table.insert(columns[target], section);
        colHeights[target] = colHeights[target] + section.height;
    end

    local startY = yOff;
    local lowestY = yOff;
    local startX = PADDING + 4;

    for col = 1, colCount do
        local colX = startX + ((col - 1) * (colWidth + colGap));
        local colY = startY;
        for _, section in ipairs(columns[col]) do
            local cls = section.cls;
            local classLabel = content:CreateFontString(nil, "OVERLAY");
            classLabel:SetFont(FONT, 12, "OUTLINE");
            classLabel:SetPoint("TOPLEFT", colX, colY);
            local cr, cg, cb = ST:GetClassColor(cls);
            classLabel:SetTextColor(cr, cg, cb);
            classLabel:SetText(CLASS_DISPLAY_NAMES[cls] or cls);
            Track(classLabel);
            colY = colY - 18;

            for _, spell in ipairs(section.spells) do
                local spellID = spell.id;
                local checked = selectedSpells[spellID] or false;
                local text = spell.name .. " |cFF888888[" .. spell.category .. "]|r";
                CreateCompactSpellToggle(content, colX + 8, colY, colWidth - 12, spellID, text, checked, function(val)
                    if (val) then
                        selectedSpells[spellID] = true;
                    else
                        selectedSpells[spellID] = nil;
                    end
                    ST:RefreshDisplay();
                end);
                colY = colY - 20;
            end

            colY = colY - 10;
        end
        if (colY < lowestY) then
            lowestY = colY;
        end
    end

    return lowestY - 4;
end

-------------------------------------------------------------------------------
-- Frame Display Tab
-------------------------------------------------------------------------------

local function BuildFrameDisplay(content, frameIndex, yOff)
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return yOff; end

    local function DestroyAndRefresh()
        local display = ST.displayFrames[frameIndex];
        if (display) then
            if (display.frame) then display.frame:Hide(); display.frame:SetParent(nil); end
            ST.displayFrames[frameIndex] = nil;
        end
        ST:RefreshDisplay();
    end

    local function RefreshAll()
        ST:RefreshDisplay();
    end

    -- Layout selector (dropdown style, like Outline)
    Track(CreateDropdown(content, PADDING + 4, yOff, "Layout", LAYOUT_OPTIONS, LAYOUT_LABELS, frameConfig.layout or "bar", function(val)
        if (frameConfig.layout == val) then return; end
        frameConfig.layout = val;
        DestroyAndRefresh();
        BuildContent();
    end));
    yOff = yOff - ROW_HEIGHT;

    Track(CreateSlider(content, PADDING + 4, yOff, "Scale", 70, 180, 1, math.floor((frameConfig.displayScale or 1) * 100), function(val)
        frameConfig.displayScale = val / 100;
        if (frameConfig.layout == "bar") then
            ST:RefreshBarLayout(frameIndex);
        else
            ST:RefreshIconLayout(frameIndex);
        end
        RefreshAll();
    end));
    yOff = yOff - 44;

    -- Font outline
    Track(CreateDropdown(content, PADDING + 4, yOff, "Outline", OUTLINE_OPTIONS, OUTLINE_LABELS, frameConfig.fontOutline or "OUTLINE", function(val)
        frameConfig.fontOutline = val;
        if (frameConfig.layout == "bar") then
            ST:RefreshBarLayout(frameIndex);
        else
            ST:RefreshIconLayout(frameIndex);
        end
        RefreshAll();
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Shared opacity applies to icon and bar layouts
    Track(CreateSlider(content, PADDING + 4, yOff, "Opacity", 0, 100, 1, math.floor((frameConfig.barAlpha or 1) * 100), function(val)
        frameConfig.barAlpha = val / 100;
        if (frameConfig.layout == "bar") then
            ST:RefreshBarLayout(frameIndex);
        else
            ST:RefreshIconLayout(frameIndex);
        end
        RefreshAll();
    end));
    yOff = yOff - 44;

    -- Shared spacing applies to icon and bar layouts
    Track(CreateSlider(content, PADDING + 4, yOff, "Spacing", 0, 12, 1, frameConfig.iconSpacing or 2, function(val)
        frameConfig.iconSpacing = val;
        if (frameConfig.layout == "bar") then
            ST:RefreshBarLayout(frameIndex);
        else
            ST:RefreshIconLayout(frameIndex);
        end
        RefreshAll();
    end));
    yOff = yOff - 44;

    local hint = content:CreateFontString(nil, "OVERLAY");
    hint:SetFont(FONT, 10);
    hint:SetPoint("TOPLEFT", PADDING + 4, yOff);
    hint:SetTextColor(unpack(COLOR_MUTED));
    hint:SetText("Display settings affect the selected frame.");
    Track(hint);
    yOff = yOff - 20;

    return yOff;
end

-------------------------------------------------------------------------------
-- Frame Interrupts Tab
-------------------------------------------------------------------------------

local function BuildFrameInterrupts(content, frameIndex, yOff)
    local interruptKey = "interrupts";
    local frameConfig = ST:GetFrameConfig(interruptKey);
    if (not frameConfig) then return yOff; end

    local selectedSpells = frameConfig.spells;

    local function DestroyAndRefresh()
        local display = ST.displayFrames[interruptKey];
        if (display) then
            if (display.frame) then display.frame:Hide(); display.frame:SetParent(nil); end
            ST.displayFrames[interruptKey] = nil;
        end
        ST:RefreshDisplay();
    end

    -- Top controls (2 rows for cleaner alignment)
    Track(CreateDropdown(content, PADDING + 4, yOff, "Layout", LAYOUT_OPTIONS, LAYOUT_LABELS, frameConfig.layout or "bar", function(val)
        if (frameConfig.layout == val) then return; end
        frameConfig.layout = val;
        DestroyAndRefresh();
        BuildContent();
    end));
    Track(CreateDropdown(content, PADDING + 250, yOff, "Show In", GROUP_MODE_OPTIONS, GROUP_MODE_LABELS, frameConfig.groupMode or "any", function(val)
        frameConfig.groupMode = val;
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    local growDir = frameConfig.growUp and "up" or "down";
    Track(CreateDropdown(content, PADDING + 4, yOff, "Grow", GROW_DIR_OPTIONS, GROW_DIR_LABELS, growDir, function(val)
        frameConfig.growUp = (val == "up");
        DestroyAndRefresh();
        BuildContent();
    end));
    yOff = yOff - ROW_HEIGHT;

    Track(CreateCheckbox(content, PADDING + 4, yOff, "Enable", frameConfig.enabled, function(val)
        frameConfig.enabled = val;
        if (val and ST._previewActive) then
            ST:DeactivatePreview();
        end
        ST:RefreshDisplay();
    end));
    Track(CreateCheckbox(content, PADDING + 110, yOff, "Lock", frameConfig.locked, function(val)
        frameConfig.locked = val;
        local display = ST.displayFrames[interruptKey];
        if (display and display.title) then
            if (val) then display.title:Hide(); else display.title:Show(); end
        end
        if (frameConfig.layout == "bar") then
            ST:RefreshBarLayout(interruptKey);
        else
            ST:RefreshIconLayout(interruptKey);
        end
        ST:RefreshDisplay();
    end));
    Track(CreateCheckbox(content, PADDING + 230, yOff, "Hide Out of Combat", frameConfig.hideOutOfCombat, function(val)
        frameConfig.hideOutOfCombat = val;
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    Track(CreateCheckbox(content, PADDING + 4, yOff, "Show Player Names", frameConfig.showNames, function(val)
        frameConfig.showNames = val;
        if (frameConfig.layout == "bar") then
            ST:RefreshBarLayout(interruptKey);
        else
            ST:RefreshIconLayout(interruptKey);
        end
        ST:RefreshDisplay();
    end));
    yOff = yOff - ROW_HEIGHT;

    Track(CreateSlider(content, PADDING + 4, yOff, "Scale", 70, 180, 1, math.floor((frameConfig.displayScale or 1) * 100), function(val)
        frameConfig.displayScale = val / 100;
        if (frameConfig.layout == "bar") then
            ST:RefreshBarLayout(interruptKey);
        else
            ST:RefreshIconLayout(interruptKey);
        end
        ST:RefreshDisplay();
    end));
    yOff = yOff - 44;

    Track(CreateActionButton(content, PADDING + 4, yOff, "Reset", 80, function()
        ST:ResetPosition(interruptKey);
        ST:Print("Interrupts position reset.");
    end));
    local testLabel = ST._intTestActive and "Disable Test" or "Test";
    Track(CreateActionButton(content, PADDING + 4 + 88, yOff, testLabel, 100, function()
        if (ST._intTestActive) then
            ST._intTestActive = nil;
            ST:DeactivatePreview();
            ST:Print("Test disabled.");
        else
            ST._intTestActive = true;
            if (ST.SetPreviewMode) then ST:SetPreviewMode("party5"); end
            ST:ActivatePreview();
            ST:Print("Test enabled (Interrupts only).");
        end
        if (_optionsFrame and _optionsFrame:IsShown()) then BuildContent(); end
    end));
    yOff = yOff - ROW_HEIGHT - 10;

    -- Organize interrupt spells by class (same layout as Spells tab)
    local spellsByClass = {};
    for id, spell in pairs(ST.spellDB) do
        if (spell.category == "interrupt") then
            local cls = spell.class;
            if (not spellsByClass[cls]) then spellsByClass[cls] = {}; end
            table.insert(spellsByClass[cls], {
                id       = id,
                category = spell.category,
                name     = C_Spell.GetSpellName(id) or ("Spell " .. id),
            });
        end
    end

    for _, spells in pairs(spellsByClass) do
        table.sort(spells, function(a, b) return a.name < b.name; end);
    end

    -- Select All / Deselect All buttons
    Track(CreateActionButton(content, PADDING + 4, yOff, "Select All", 100, function()
        for id, spell in pairs(ST.spellDB) do
            if (spell.category == "interrupt") then
                selectedSpells[id] = true;
            end
        end
        ST:RefreshDisplay();
        if (_optionsFrame and _optionsFrame:IsShown()) then BuildContent(); end
    end));
    Track(CreateActionButton(content, PADDING + 110, yOff, "Deselect All", 100, function()
        wipe(selectedSpells);
        ST:RefreshDisplay();
        if (_optionsFrame and _optionsFrame:IsShown()) then BuildContent(); end
    end));
    yOff = yOff - ROW_HEIGHT - 12;

    local function CreateCompactSpellToggle(parent, x, y, width, spellID, text, checked, onToggle)
        local row = CreateFrame("Button", nil, parent);
        row:SetPoint("TOPLEFT", x, y);
        row:SetSize(width, 19);
        Track(row);

        local icon = row:CreateTexture(nil, "ARTWORK");
        icon:SetPoint("LEFT", 0, 0);
        icon:SetSize(14, 14);
        icon:SetTexture(ST._GetSpellTexture(spellID));
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

        local box = row:CreateTexture(nil, "ARTWORK");
        box:SetPoint("LEFT", 20, 0);
        box:SetSize(12, 12);
        box:SetTexture("Interface\\BUTTONS\\WHITE8X8");
        box:SetVertexColor(0.12, 0.12, 0.12, 1);

        local boxBorder = row:CreateTexture(nil, "BORDER");
        boxBorder:SetPoint("TOPLEFT", box, -1, 1);
        boxBorder:SetPoint("BOTTOMRIGHT", box, 1, -1);
        boxBorder:SetTexture("Interface\\BUTTONS\\WHITE8X8");
        boxBorder:SetVertexColor(unpack(COLOR_BORDER));

        local mark = row:CreateFontString(nil, "OVERLAY");
        mark:SetFont(FONT, 10, "OUTLINE");
        mark:SetPoint("CENTER", box, "CENTER", 0, 0);
        mark:SetTextColor(unpack(COLOR_ACCENT));
        mark:SetText(checked and "x" or "");

        local label = row:CreateFontString(nil, "OVERLAY");
        label:SetFont(FONT, 11);
        label:SetPoint("LEFT", 37, 0);
        label:SetTextColor(unpack(COLOR_LABEL));
        label:SetWidth(width - 38);
        label:SetJustifyH("LEFT");
        label:SetWordWrap(false);
        label:SetText(text);

        row:SetScript("OnClick", function()
            checked = not checked;
            mark:SetText(checked and "x" or "");
            if (onToggle) then onToggle(checked); end
        end);
    end

    local classSections = {};
    for _, cls in ipairs(CLASS_ORDER) do
        local classSpells = spellsByClass[cls];
        if (classSpells and #classSpells > 0) then
            table.insert(classSections, {
                cls = cls,
                spells = classSpells,
                height = 18 + (#classSpells * 20) + 10,
            });
        end
    end

    local parentWidth = GetContentWidth(content);
    local availableWidth = parentWidth - ((PADDING + 4) * 2);
    local colCount = 2;
    local colGap = 10;
    local colWidth = math.floor((availableWidth - ((colCount - 1) * colGap)) / colCount);

    local columns = {};
    local colHeights = {};
    for i = 1, colCount do
        columns[i] = {};
        colHeights[i] = 0;
    end
    for _, section in ipairs(classSections) do
        local target = 1;
        for i = 2, colCount do
            if (colHeights[i] < colHeights[target]) then
                target = i;
            end
        end
        table.insert(columns[target], section);
        colHeights[target] = colHeights[target] + section.height;
    end

    local startY = yOff;
    local lowestY = yOff;
    local startX = PADDING + 4;

    for col = 1, colCount do
        local colX = startX + ((col - 1) * (colWidth + colGap));
        local colY = startY;
        for _, section in ipairs(columns[col]) do
            local cls = section.cls;
            local classLabel = content:CreateFontString(nil, "OVERLAY");
            classLabel:SetFont(FONT, 12, "OUTLINE");
            classLabel:SetPoint("TOPLEFT", colX, colY);
            local cr, cg, cb = ST:GetClassColor(cls);
            classLabel:SetTextColor(cr, cg, cb);
            classLabel:SetText(CLASS_DISPLAY_NAMES[cls] or cls);
            Track(classLabel);
            colY = colY - 18;

            for _, spell in ipairs(section.spells) do
                local spellID = spell.id;
                local checked = selectedSpells[spellID] or false;
                local text = spell.name .. " |cFF888888[" .. spell.category .. "]|r";
                CreateCompactSpellToggle(content, colX + 8, colY, colWidth - 12, spellID, text, checked, function(val)
                    if (val) then
                        selectedSpells[spellID] = true;
                    else
                        selectedSpells[spellID] = nil;
                    end
                    ST:RefreshDisplay();
                end);
                colY = colY - 20;
            end

            colY = colY - 10;
        end
        if (colY < lowestY) then
            lowestY = colY;
        end
    end

    return lowestY - 4;
end

-------------------------------------------------------------------------------
-- Build Content
-------------------------------------------------------------------------------

BuildContent = function()
    if (not _optionsFrame) then return; end
    local content = _optionsFrame.content;

    local scrollPos = _optionsFrame.scrollFrame and _optionsFrame.scrollFrame:GetVerticalScroll() or 0;
    DestroyContent();

    local yOff = -8;
    local db = ST.db;
    if (not db) then return; end

    -- Top-level tab band: Frames / Profiles
    local tabBand = CreateFrame("Frame", nil, content);
    tabBand:SetPoint("TOPLEFT", PADDING, yOff);
    tabBand:SetPoint("TOPRIGHT", -PADDING, yOff);
    tabBand:SetHeight(28);
    Track(tabBand);

    local tabBandBg = tabBand:CreateTexture(nil, "BACKGROUND");
    tabBandBg:SetAllPoints();
    tabBandBg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    tabBandBg:SetVertexColor(0.1, 0.1, 0.1, 1);

    local framesTabBtn = CreateFrame("Button", nil, tabBand);
    framesTabBtn:SetSize(100, 28);
    framesTabBtn:SetPoint("LEFT", 0, 0);
    SkinButton(framesTabBtn, _mainTab == "frames" and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
    local framesTabText = framesTabBtn:CreateFontString(nil, "OVERLAY");
    framesTabText:SetFont(FONT, 12, "OUTLINE");
    framesTabText:SetPoint("CENTER", 0, 0);
    framesTabText:SetTextColor(unpack(_mainTab == "frames" and COLOR_ACCENT or COLOR_MUTED));
    framesTabText:SetText("Frames");
    framesTabBtn:SetScript("OnClick", function()
        _mainTab = "frames";
        BuildContent();
    end);

    local interruptsTabBtn = CreateFrame("Button", nil, tabBand);
    interruptsTabBtn:SetSize(100, 28);
    interruptsTabBtn:SetPoint("LEFT", framesTabBtn, "RIGHT", 2, 0);
    SkinButton(interruptsTabBtn, _mainTab == "interrupts" and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
    local interruptsTabText = interruptsTabBtn:CreateFontString(nil, "OVERLAY");
    interruptsTabText:SetFont(FONT, 12, "OUTLINE");
    interruptsTabText:SetPoint("CENTER", 0, 0);
    interruptsTabText:SetTextColor(unpack(_mainTab == "interrupts" and COLOR_ACCENT or COLOR_MUTED));
    interruptsTabText:SetText("Interrupts");
    interruptsTabBtn:SetScript("OnClick", function()
        _mainTab = "interrupts";
        BuildContent();
    end);

    local profilesTabBtn = CreateFrame("Button", nil, tabBand);
    profilesTabBtn:SetSize(100, 28);
    profilesTabBtn:SetPoint("LEFT", interruptsTabBtn, "RIGHT", 2, 0);
    SkinButton(profilesTabBtn, _mainTab == "profiles" and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
    local profilesTabText = profilesTabBtn:CreateFontString(nil, "OVERLAY");
    profilesTabText:SetFont(FONT, 12, "OUTLINE");
    profilesTabText:SetPoint("CENTER", 0, 0);
    profilesTabText:SetTextColor(unpack(_mainTab == "profiles" and COLOR_ACCENT or COLOR_MUTED));
    profilesTabText:SetText("Profiles");
    profilesTabBtn:SetScript("OnClick", function()
        _mainTab = "profiles";
        BuildContent();
    end);

    yOff = yOff - 32;

    -- If on Profiles tab, delegate to BuildProfilesTab and return
    if (_mainTab == "profiles") then
        local profilesY = BuildProfilesTab(content, yOff);
        local contentHeight = math.max(64, math.abs(profilesY) + PADDING);
        content:SetHeight(contentHeight);
        _optionsFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT);
        if (_optionsFrame.scrollFrame) then
            local maxScroll = math.max(0, contentHeight - _optionsFrame.scrollFrame:GetHeight());
            _optionsFrame.scrollFrame:SetVerticalScroll(math.min(scrollPos, maxScroll));
        end
        return;
    end

    -- If on Interrupts tab, render interrupt config full-width and return
    if (_mainTab == "interrupts") then
        local intY = yOff;

        -- Preview button for interrupts
        intY = BuildFrameInterrupts(content, "interrupts", intY);
        local contentHeight = math.max(64, math.abs(intY) + PADDING + 40);
        content:SetHeight(contentHeight);
        _optionsFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT);
        if (_optionsFrame.scrollFrame) then
            local maxScroll = math.max(0, contentHeight - _optionsFrame.scrollFrame:GetHeight());
            _optionsFrame.scrollFrame:SetVerticalScroll(math.min(scrollPos, maxScroll));
        end
        return;
    end

    local mainWidth = FRAME_WIDTH - (PADDING * 2) - SIDEBAR_WIDTH - COLUMN_GAP;

    local sidebar = CreateFrame("Frame", nil, content, "BackdropTemplate");
    sidebar:SetPoint("TOPLEFT", PADDING, yOff);
    sidebar:SetWidth(SIDEBAR_WIDTH);
    sidebar:SetHeight(1);
    SkinPanel(sidebar, { 0.1, 0.1, 0.1, 0.92 }, COLOR_BORDER);
    Track(sidebar);

    local main = CreateFrame("Frame", nil, content);
    main:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", COLUMN_GAP, 0);
    main:SetWidth(mainWidth);
    main:SetHeight(1);
    Track(main);

    local sideY = -12;
    local sideTitle = sidebar:CreateFontString(nil, "OVERLAY");
    sideTitle:SetFont(FONT, 12, "OUTLINE");
    sideTitle:SetPoint("TOPLEFT", 10, sideY);
    sideTitle:SetTextColor(unpack(COLOR_ACCENT));
    sideTitle:SetText("Frames");
    Track(sideTitle);
    sideY = sideY - 24;

    -- Sidebar: "New Frame" button
    Track(CreateActionButton(sidebar, 8, sideY, "+ New Frame", SIDEBAR_WIDTH - 16, function()
        local before = #(db.frames or {});
        local idx = ST:CreateCustomFrame();
        if (not idx) then idx = #(db.frames or {}); end
        if (idx <= before) then
            ST:Print("Unable to create a new frame.");
            return;
        end
        local fc = ST:GetFrameConfig(idx);
        if (fc) then
            fc.locked = false;
            fc.position = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = 0,
                y = -150,
            };
        end
        _selectedFrameIndex = idx;
        _frameTabs[idx] = "settings";
        BuildContent();
        ST:RefreshDisplay();

        -- Outside a group, force preview so the new frame is immediately visible.
        if (not ST._previewActive and not IsInGroup() and not IsInRaid()) then
            ST:ActivatePreview();
            ST:Print("Preview enabled for new frame.");
            BuildContent();
        end
    end));
    sideY = sideY - ROW_HEIGHT - 8;

    local frameCount = #db.frames;
    if (frameCount > 0) then
        _selectedFrameIndex = math.max(1, math.min(_selectedFrameIndex or 1, frameCount));
    else
        _selectedFrameIndex = 1;
    end

    -- Sidebar: frames list
    for frameIndex, frameConfig in ipairs(db.frames) do
        local fIdx = frameIndex;
        local row = CreateFrame("Frame", nil, sidebar);
        row:SetPoint("TOPLEFT", 8, sideY);
        row:SetSize(SIDEBAR_WIDTH - 16, 24);
        Track(row);

        local btn = CreateFrame("Button", nil, row);
        btn:SetPoint("TOPLEFT", 0, 0);
        btn:SetSize(SIDEBAR_WIDTH - 40, 24);
        SkinButton(btn, fIdx == _selectedFrameIndex and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
        Track(btn);

        local btnText = btn:CreateFontString(nil, "OVERLAY");
        btnText:SetFont(FONT, 11);
        btnText:SetPoint("LEFT", 8, 0);
        local btnColor = (fIdx == _selectedFrameIndex) and COLOR_ACCENT or COLOR_LABEL;
        btnText:SetTextColor(unpack(btnColor));
        btnText:SetText(frameConfig.name or ("Frame " .. fIdx));

        btn:SetScript("OnClick", function()
            _selectedFrameIndex = fIdx;
            BuildContent();
        end);

        local delBtn = CreateFrame("Button", nil, row);
        delBtn:SetPoint("TOPRIGHT", 0, 0);
        delBtn:SetSize(20, 24);
        SkinButton(delBtn, { 0.4, 0.1, 0.1, 1 }, { 0.6, 0.15, 0.15, 1 });
        Track(delBtn);

        local delText = delBtn:CreateFontString(nil, "OVERLAY");
        delText:SetFont(FONT, 11, "OUTLINE");
        delText:SetPoint("CENTER", 0, 0);
        delText:SetTextColor(1, 0.6, 0.6);
        delText:SetText("X");

        delBtn:SetScript("OnClick", function()
            ST:DeleteCustomFrame(fIdx);
            local newTabs = {};
            for idx, v in pairs(_frameTabs) do
                if (idx > fIdx) then
                    newTabs[idx - 1] = v;
                elseif (idx < fIdx) then
                    newTabs[idx] = v;
                end
            end
            _frameTabs = newTabs;
            _frameExpanded = {};

            local remaining = #(ST.db and ST.db.frames or {});
            if (remaining > 0) then
                _selectedFrameIndex = math.max(1, math.min(_selectedFrameIndex, remaining));
            else
                _selectedFrameIndex = 1;
            end

            BuildContent();
            ST:RefreshDisplay();
        end);

        sideY = sideY - 26;
    end
    sideY = sideY - 8;

    local currentPreviewMode = ST.GetPreviewMode and ST:GetPreviewMode() or "party5";
    local previewModeLabel = sidebar:CreateFontString(nil, "OVERLAY");
    previewModeLabel:SetFont(FONT, 10);
    previewModeLabel:SetPoint("TOPLEFT", 10, sideY);
    previewModeLabel:SetTextColor(unpack(COLOR_MUTED));
    previewModeLabel:SetText("Preview Mode");
    Track(previewModeLabel);
    sideY = sideY - 16;

    local modeX = 8;
    for _, mode in ipairs(PREVIEW_MODE_OPTIONS) do
        local modeBtn = CreateFrame("Button", nil, sidebar);
        modeBtn:SetPoint("TOPLEFT", modeX, sideY);
        modeBtn:SetSize(52, 20);
        SkinButton(modeBtn, currentPreviewMode == mode and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
        Track(modeBtn);

        local modeText = modeBtn:CreateFontString(nil, "OVERLAY");
        modeText:SetFont(FONT, 9);
        modeText:SetPoint("CENTER", 0, 0);
        modeText:SetText(mode == "party5" and "G5" or (mode == "raid20" and "R20" or "R40"));
        modeText:SetTextColor(unpack(currentPreviewMode == mode and COLOR_ACCENT or COLOR_LABEL));

        modeBtn:SetScript("OnClick", function()
            if (ST.SetPreviewMode) then ST:SetPreviewMode(mode); end
            BuildContent();
        end);
        modeX = modeX + 54;
    end
    sideY = sideY - 24;

    -- Sidebar: Preview button
    local previewLabel = ST._previewActive and "Disable Preview" or "Toggle Preview";
    Track(CreateActionButton(sidebar, 8, sideY, previewLabel, SIDEBAR_WIDTH - 16, function()
        if (ST._previewActive) then
            ST:DeactivatePreview();
            ST:Print("Preview disabled.");
        else
            ST:ActivatePreview();
            local pm = ST.GetPreviewMode and ST:GetPreviewMode() or "party5";
            local label = PREVIEW_MODE_LABELS[pm] or "Group (5)";
            ST:Print("Preview enabled (" .. label .. ").");
        end
        if (_optionsFrame and _optionsFrame:IsShown()) then
            BuildContent();
        end
    end));
    sideY = sideY - ROW_HEIGHT - 8;

    local mainY = yOff;

    if (frameCount > 0) then
        local frameIndex = _selectedFrameIndex;
        local frameConfig = ST:GetFrameConfig(frameIndex);
        local activeTab = _frameTabs[frameIndex] or "settings";
        local fIdx = frameIndex;

        -- Settings/Spells tabs for selected frame
        local tabHolder = CreateFrame("Frame", nil, main);
        tabHolder:SetPoint("TOPLEFT", PADDING + 4, -8);
        tabHolder:SetPoint("TOPRIGHT", -PADDING, -8);
        tabHolder:SetHeight(24);
        Track(tabHolder);

        local settingsTab = CreateFrame("Button", nil, tabHolder);
        settingsTab:SetSize(80, 24);
        settingsTab:SetPoint("LEFT", 0, 0);
        SkinButton(settingsTab, activeTab == "settings" and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
        local settingsText = settingsTab:CreateFontString(nil, "OVERLAY");
        settingsText:SetFont(FONT, 11);
        settingsText:SetPoint("CENTER", 0, 0);
        settingsText:SetText("Settings");
        local settingsColor = (activeTab == "settings") and COLOR_ACCENT or COLOR_MUTED;
        settingsText:SetTextColor(unpack(settingsColor));
        settingsTab:SetScript("OnClick", function()
            _frameTabs[fIdx] = "settings";
            BuildContent();
        end);

        local spellsTab = CreateFrame("Button", nil, tabHolder);
        spellsTab:SetSize(80, 24);
        spellsTab:SetPoint("LEFT", settingsTab, "RIGHT", 4, 0);
        SkinButton(spellsTab, activeTab == "spells" and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
        local spellsText = spellsTab:CreateFontString(nil, "OVERLAY");
        spellsText:SetFont(FONT, 11);
        spellsText:SetPoint("CENTER", 0, 0);
        spellsText:SetText("Spells");
        local spellsColor = (activeTab == "spells") and COLOR_ACCENT or COLOR_MUTED;
        spellsText:SetTextColor(unpack(spellsColor));
        spellsTab:SetScript("OnClick", function()
            _frameTabs[fIdx] = "spells";
            BuildContent();
        end);

        local displayTab = CreateFrame("Button", nil, tabHolder);
        displayTab:SetSize(80, 24);
        displayTab:SetPoint("LEFT", spellsTab, "RIGHT", 4, 0);
        SkinButton(displayTab, activeTab == "display" and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
        local displayText = displayTab:CreateFontString(nil, "OVERLAY");
        displayText:SetFont(FONT, 11);
        displayText:SetPoint("CENTER", 0, 0);
        displayText:SetText("Display");
        local displayColor = (activeTab == "display") and COLOR_ACCENT or COLOR_MUTED;
        displayText:SetTextColor(unpack(displayColor));
        displayTab:SetScript("OnClick", function()
            _frameTabs[fIdx] = "display";
            BuildContent();
        end);

        local spellCount = 0;
        if (frameConfig.spells) then
            for _ in pairs(frameConfig.spells) do spellCount = spellCount + 1; end
        end
        local countLabel = tabHolder:CreateFontString(nil, "OVERLAY");
        countLabel:SetFont(FONT, 10);
        countLabel:SetPoint("RIGHT", -4, 0);
        countLabel:SetTextColor(unpack(COLOR_MUTED));
        countLabel:SetText(spellCount .. " spells selected");

        mainY = -8 - 30;

        if (activeTab == "settings") then
            mainY = BuildFrameSettings(main, frameIndex, mainY);
        elseif (activeTab == "spells") then
            mainY = BuildFrameSpells(main, frameIndex, mainY);
        else
            mainY = BuildFrameDisplay(main, frameIndex, mainY);
        end
    end

    local mainHeight = math.max(64, math.abs(mainY) + PADDING);
    local sideHeight = math.max(100, math.abs(sideY) + PADDING);
    main:SetHeight(mainHeight);
    sidebar:SetHeight(sideHeight);

    -- Resize content
    local contentHeight = math.max(mainHeight, sideHeight);
    content:SetHeight(contentHeight);
    _optionsFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT);

    if (_optionsFrame.scrollFrame) then
        local maxScroll = math.max(0, contentHeight - _optionsFrame.scrollFrame:GetHeight());
        _optionsFrame.scrollFrame:SetVerticalScroll(math.min(scrollPos, maxScroll));
    end
end

local function CreateOptionsFrame()
    if (_optionsFrame) then return _optionsFrame; end

    local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate");
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT);
    frame:SetPoint("CENTER", UIParent, "CENTER", 300, 50);
    frame:SetFrameStrata("DIALOG");
    frame:SetClampedToScreen(true);
    frame:SetMovable(true);
    frame:EnableMouse(true);
    SkinPanel(frame, COLOR_BG, COLOR_BORDER);

    table.insert(UISpecialFrames, FRAME_NAME);

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame);
    titleBar:SetHeight(30);
    titleBar:SetPoint("TOPLEFT", 0, 0);
    titleBar:SetPoint("TOPRIGHT", 0, 0);
    titleBar:EnableMouse(true);
    titleBar:RegisterForDrag("LeftButton");
    titleBar:SetScript("OnDragStart", function() frame:StartMoving(); end);
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); end);

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    titleBg:SetVertexColor(0.12, 0.12, 0.12, 1);

    local titleAccent = titleBar:CreateTexture(nil, "BORDER");
    titleAccent:SetPoint("BOTTOMLEFT", 0, 0);
    titleAccent:SetPoint("BOTTOMRIGHT", 0, 0);
    titleAccent:SetHeight(1);
    titleAccent:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    titleAccent:SetVertexColor(unpack(COLOR_ACCENT));

    local titleLogo = titleBar:CreateTexture(nil, "ARTWORK");
    titleLogo:SetSize(22, 22);
    titleLogo:SetPoint("LEFT", 8, 0);
    titleLogo:SetTexture("Interface\\AddOns\\ReversionRaidTools\\logo");

    local titleText = titleBar:CreateFontString(nil, "OVERLAY");
    titleText:SetFont(FONT, 14, "OUTLINE");
    titleText:SetPoint("LEFT", 36, 0);
    titleText:SetTextColor(unpack(COLOR_ACCENT));
    titleText:SetText("Reversion Raid Tools");

    local closeBtn = CreateFrame("Button", nil, titleBar);
    closeBtn:SetSize(20, 20);
    closeBtn:SetPoint("RIGHT", -6, 0);
    SkinButton(closeBtn, COLOR_BTN, COLOR_BTN_HOVER);

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY");
    closeText:SetFont(FONT, 16);
    closeText:SetPoint("CENTER", 0, 0);
    closeText:SetTextColor(unpack(COLOR_MUTED));
    closeText:SetText("X");

    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(1, 1, 1); end);
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(unpack(COLOR_MUTED)); end);
    closeBtn:SetScript("OnClick", function() frame:Hide(); end);

    -- Scale buttons
    local scalePlusBtn = CreateFrame("Button", nil, titleBar);
    scalePlusBtn:SetSize(20, 20);
    scalePlusBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0);
    SkinButton(scalePlusBtn, COLOR_BTN, COLOR_BTN_HOVER);
    local scalePlusText = scalePlusBtn:CreateFontString(nil, "OVERLAY");
    scalePlusText:SetFont(FONT, 14);
    scalePlusText:SetPoint("CENTER", 0, 0);
    scalePlusText:SetTextColor(unpack(COLOR_MUTED));
    scalePlusText:SetText("+");
    scalePlusBtn:SetScript("OnEnter", function() scalePlusText:SetTextColor(1,1,1); end);
    scalePlusBtn:SetScript("OnLeave", function() scalePlusText:SetTextColor(unpack(COLOR_MUTED)); end);

    local scaleLabel = titleBar:CreateFontString(nil, "OVERLAY");
    scaleLabel:SetFont(FONT, 11);
    scaleLabel:SetWidth(40);
    scaleLabel:SetPoint("RIGHT", scalePlusBtn, "LEFT", -2, 0);
    scaleLabel:SetTextColor(unpack(COLOR_MUTED));
    scaleLabel:SetText("100%");

    local scaleMinusBtn = CreateFrame("Button", nil, titleBar);
    scaleMinusBtn:SetSize(20, 20);
    scaleMinusBtn:SetPoint("RIGHT", scaleLabel, "LEFT", -2, 0);
    SkinButton(scaleMinusBtn, COLOR_BTN, COLOR_BTN_HOVER);
    local scaleMinusText = scaleMinusBtn:CreateFontString(nil, "OVERLAY");
    scaleMinusText:SetFont(FONT, 14);
    scaleMinusText:SetPoint("CENTER", 0, 0);
    scaleMinusText:SetTextColor(unpack(COLOR_MUTED));
    scaleMinusText:SetText("−");
    scaleMinusBtn:SetScript("OnEnter", function() scaleMinusText:SetTextColor(1,1,1); end);
    scaleMinusBtn:SetScript("OnLeave", function() scaleMinusText:SetTextColor(unpack(COLOR_MUTED)); end);

    local function ApplyUIScale(delta)
        local db = ST.db;
        if not db then return; end
        local current = math.floor((db.uiScale or 1.0) * 10 + 0.5);
        current = math.max(7, math.min(15, current + delta));
        db.uiScale = current / 10;
        frame:SetScale(db.uiScale);
        scaleLabel:SetText(math.floor(db.uiScale * 100) .. "%");
    end;

    scalePlusBtn:SetScript("OnClick", function() ApplyUIScale(1); end);
    scaleMinusBtn:SetScript("OnClick", function() ApplyUIScale(-1); end);

    -- Scrollable content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame);
    scrollFrame:SetPoint("TOPLEFT", 0, -30);
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0);
    scrollFrame:EnableMouseWheel(true);
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll();
        local child = self:GetScrollChild();
        if (not child) then return; end
        local maxScroll = math.max(0, child:GetHeight() - self:GetHeight());
        local newScroll = math.max(0, math.min(current - (delta * 30), maxScroll));
        self:SetVerticalScroll(newScroll);
    end);

    local content = CreateFrame("Frame", nil, scrollFrame);
    content:SetSize(FRAME_WIDTH, 1);
    scrollFrame:SetScrollChild(content);
    frame.content = content;
    frame.scrollFrame = scrollFrame;

    frame:SetScript("OnShow", function()
        BuildContent();
    end);

    -- Apply saved UI scale
    local initScale = (ST.db and ST.db.uiScale) or 1.0;
    frame:SetScale(initScale);
    scaleLabel:SetText(math.floor(initScale * 100) .. "%");

    frame:Hide();
    _optionsFrame = frame;
    return frame;
end

-------------------------------------------------------------------------------
-- Profiles Tab (UI only — logic in Profiles.lua)
-------------------------------------------------------------------------------

BuildProfilesTab = function(parent, yOff)
    local db = ST.db;
    if (not db) then return yOff; end
    db.profiles = db.profiles or {};

    local mainWidth = FRAME_WIDTH - (PADDING * 2) - SIDEBAR_WIDTH - COLUMN_GAP;

    -- Sidebar: profile list
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate");
    sidebar:SetPoint("TOPLEFT", PADDING, yOff);
    sidebar:SetWidth(SIDEBAR_WIDTH);
    sidebar:SetHeight(1);
    SkinPanel(sidebar, { 0.1, 0.1, 0.1, 0.92 }, COLOR_BORDER);
    Track(sidebar);

    -- Main panel
    local main = CreateFrame("Frame", nil, parent);
    main:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", COLUMN_GAP, 0);
    main:SetWidth(mainWidth);
    main:SetHeight(1);
    Track(main);

    local sideY = -12;

    -- Sidebar title
    local sideTitle = sidebar:CreateFontString(nil, "OVERLAY");
    sideTitle:SetFont(FONT, 12, "OUTLINE");
    sideTitle:SetPoint("TOPLEFT", 10, sideY);
    sideTitle:SetTextColor(unpack(COLOR_ACCENT));
    sideTitle:SetText("Profiles");
    Track(sideTitle);
    sideY = sideY - 24;

    -- Quick Save to active profile (Option B)
    if (db.activeProfile and db.profiles[db.activeProfile]) then
        local shortName = db.activeProfile;
        if (#shortName > 12) then shortName = shortName:sub(1, 11) .. "…"; end
        Track(CreateActionButton(sidebar, 8, sideY, "Save  [" .. shortName .. "]", SIDEBAR_WIDTH - 16, function()
            ST:SaveProfile(db.activeProfile);
            ST:Print("Saved: " .. db.activeProfile);
            BuildContent();
        end, { 0.1, 0.28, 0.1, 1 }));
        sideY = sideY - ROW_HEIGHT - 8;
    end

    -- "New Profile" button
    -- Auto-suggest a free name
    if (not _profileDraftName or _profileDraftName == "" or db.profiles[_profileDraftName]) then
        local idx = 1;
        while (db.profiles["Profile " .. idx]) do
            idx = idx + 1;
        end
        _profileDraftName = "Profile " .. idx;
    end

    local newProfileInput = CreateFrame("EditBox", nil, sidebar, "InputBoxTemplate");
    newProfileInput:SetPoint("TOPLEFT", 8, sideY);
    newProfileInput:SetSize(SIDEBAR_WIDTH - 16, 20);
    newProfileInput:SetAutoFocus(false);
    if (newProfileInput.SetFontObject and ChatFontNormal) then
        newProfileInput:SetFontObject(ChatFontNormal);
    end
    newProfileInput:SetText(_profileDraftName or "");
    newProfileInput:SetScript("OnTextChanged", function(self, userInput)
        if (userInput) then _profileDraftName = self:GetText(); end
    end);
    newProfileInput:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
    newProfileInput:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
    Track(newProfileInput);
    sideY = sideY - 24;

    Track(CreateActionButton(sidebar, 8, sideY, "Create Profile", SIDEBAR_WIDTH - 16, function()
        local name = strtrim(_profileDraftName or "");
        if (name == "") then
            ST:Print("Profile name is required.");
            return;
        end
        if (db.profiles and db.profiles[name]) then
            ST:Print("A profile named '" .. name .. "' already exists.");
            return;
        end
        -- Create blank profile with defaults, set as active
        ST:NewProfile(name);
        ST:Print("Profile created: " .. name);
        _selectedProfileName = name;
        -- Auto-increment for next creation
        local base = name:match("^(.-)%s*%d*$") or name;
        local idx = 1;
        db.profiles = db.profiles or {};
        while (db.profiles[base .. " " .. idx]) do
            idx = idx + 1;
        end
        _profileDraftName = base .. " " .. idx;
    end));
    sideY = sideY - ROW_HEIGHT - 12;

    -- Profile list
    local profileNames = ST:GetProfileNames();

    -- Validate selection
    if (_selectedProfileName and not db.profiles[_selectedProfileName]) then
        _selectedProfileName = nil;
    end
    if (not _selectedProfileName and #profileNames > 0) then
        _selectedProfileName = profileNames[1];
    end

    for _, pName in ipairs(profileNames) do
        local pNameCopy = pName;
        local isSelected = (_selectedProfileName == pName);
        local isActive = (db.activeProfile == pName);

        -- Name button (narrowed to leave room for Load button)
        local nameWidth = SIDEBAR_WIDTH - 16 - 46;
        local btn = CreateFrame("Button", nil, sidebar);
        btn:SetPoint("TOPLEFT", 8, sideY);
        btn:SetSize(nameWidth, 24);
        SkinButton(btn, isSelected and COLOR_TAB_ACTIVE or COLOR_TAB_IDLE, COLOR_BTN_HOVER);
        Track(btn);

        local btnText = btn:CreateFontString(nil, "OVERLAY");
        btnText:SetFont(FONT, 11);
        btnText:SetPoint("LEFT", 8, 0);
        btnText:SetPoint("RIGHT", -4, 0);
        local btnColor = isSelected and COLOR_ACCENT or COLOR_LABEL;
        btnText:SetTextColor(unpack(btnColor));
        local label = pName;
        if (isActive) then label = label .. " *"; end
        btnText:SetText(label);

        btn:SetScript("OnClick", function()
            _selectedProfileName = pNameCopy;
            BuildContent();
        end);

        -- Quick Load button (Option A)
        local loadBtn = CreateFrame("Button", nil, sidebar);
        loadBtn:SetPoint("TOPLEFT", 8 + nameWidth + 4, sideY);
        loadBtn:SetSize(42, 24);
        local loadBg = isActive and { 0.05, 0.18, 0.05, 1 } or { 0.1, 0.28, 0.1, 1 };
        SkinButton(loadBtn, loadBg, { 0.15, 0.38, 0.15, 1 });
        Track(loadBtn);

        local loadText = loadBtn:CreateFontString(nil, "OVERLAY");
        loadText:SetFont(FONT, 10, "OUTLINE");
        loadText:SetPoint("CENTER", 0, 0);
        if (isActive) then
            loadText:SetTextColor(0.4, 0.7, 0.4);
            loadText:SetText("ON");
        else
            loadText:SetTextColor(0.5, 1, 0.5);
            loadText:SetText("Load");
            loadBtn:SetScript("OnClick", function()
                if (InCombatLockdown()) then
                    ST:Print("Cannot load profiles during combat.");
                    return;
                end
                ST:LoadProfile(pNameCopy);
                ST:Print("Loaded: " .. pNameCopy);
                _selectedProfileName = pNameCopy;
                BuildContent();
            end);
        end

        sideY = sideY - 26;
    end
    sideY = sideY - 8;

    -- Reset to defaults button at bottom of sidebar
    Track(CreateActionButton(sidebar, 8, sideY, "Reset to Defaults", SIDEBAR_WIDTH - 16, function()
        if (InCombatLockdown()) then
            ST:Print("Cannot reset during combat.");
            return;
        end
        if (not sidebar._resetConfirm) then
            sidebar._resetConfirm = true;
            ST:Print("Click again within 3s to confirm reset.");
            C_Timer.After(3, function() sidebar._resetConfirm = false; end);
            return;
        end
        sidebar._resetConfirm = false;
        _selectedProfileName = nil;
        ST:ResetToDefaults();
        ST:Print("Reset to defaults.");
        BuildContent();
    end, COLOR_DANGER));
    sideY = sideY - ROW_HEIGHT - 8;

    ---------------------------------------------------------------------------
    -- Main panel: selected profile details
    ---------------------------------------------------------------------------
    local mainY = -12;

    if (not _selectedProfileName or not db.profiles[_selectedProfileName]) then
        -- No profile selected
        local hint = main:CreateFontString(nil, "OVERLAY");
        hint:SetFont(FONT, 12);
        hint:SetPoint("TOPLEFT", PADDING, mainY);
        hint:SetTextColor(unpack(COLOR_MUTED));
        hint:SetText("Select a profile or create a new one.");
        Track(hint);
        mainY = mainY - 30;
    else
        local selName = _selectedProfileName;
        local profileData = db.profiles[selName];
        local isActive = (db.activeProfile == selName);

        -- Profile header
        local headerHolder = CreateFrame("Frame", nil, main);
        headerHolder:SetPoint("TOPLEFT", PADDING, mainY);
        headerHolder:SetPoint("TOPRIGHT", -PADDING, mainY);
        headerHolder:SetHeight(28);
        Track(headerHolder);

        local headerBg = headerHolder:CreateTexture(nil, "BACKGROUND");
        headerBg:SetAllPoints();
        headerBg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
        headerBg:SetVertexColor(0.14, 0.14, 0.14, 1);

        local headerAccent = headerHolder:CreateTexture(nil, "BORDER");
        headerAccent:SetPoint("TOPLEFT", 0, 0);
        headerAccent:SetPoint("BOTTOMLEFT", 0, 0);
        headerAccent:SetWidth(2);
        headerAccent:SetTexture("Interface\\BUTTONS\\WHITE8X8");
        headerAccent:SetVertexColor(unpack(COLOR_ACCENT));

        local headerText = headerHolder:CreateFontString(nil, "OVERLAY");
        headerText:SetFont(FONT, 12, "OUTLINE");
        headerText:SetPoint("LEFT", 10, 0);
        headerText:SetTextColor(unpack(COLOR_LABEL));
        local headerStr = selName;
        if (isActive) then headerStr = headerStr .. "  |cFF4DB8FF(active)|r"; end
        headerText:SetText(headerStr);

        -- Saved time
        if (profileData and profileData.savedAt) then
            local elapsed = time() - profileData.savedAt;
            local timeStr;
            if (elapsed < 60) then timeStr = elapsed .. "s ago";
            elseif (elapsed < 3600) then timeStr = math.floor(elapsed / 60) .. "m ago";
            elseif (elapsed < 86400) then timeStr = math.floor(elapsed / 3600) .. "h ago";
            else timeStr = math.floor(elapsed / 86400) .. "d ago";
            end
            local timeLabel = headerHolder:CreateFontString(nil, "OVERLAY");
            timeLabel:SetFont(FONT, 10);
            timeLabel:SetPoint("RIGHT", -8, 0);
            timeLabel:SetTextColor(unpack(COLOR_MUTED));
            timeLabel:SetText("Saved " .. timeStr);
        end

        mainY = mainY - 36;

        -- Info: frame count
        local frameCount = 0;
        if (profileData and profileData.frames) then
            frameCount = #profileData.frames;
        end
        local infoLabel = main:CreateFontString(nil, "OVERLAY");
        infoLabel:SetFont(FONT, 11);
        infoLabel:SetPoint("TOPLEFT", PADDING, mainY);
        infoLabel:SetTextColor(unpack(COLOR_MUTED));
        infoLabel:SetText("Contains " .. frameCount .. " frame(s)");
        Track(infoLabel);
        mainY = mainY - 24;

        -- Action buttons row
        -- Load
        Track(CreateActionButton(main, PADDING, mainY, "Load Profile", 110, function()
            if (InCombatLockdown()) then
                ST:Print("Cannot load profiles during combat.");
                return;
            end
            ST:LoadProfile(selName);
            ST:Print("Profile loaded: " .. selName);
            BuildContent();
        end, { 0.1, 0.3, 0.1, 1 }));

        -- Save (overwrite)
        Track(CreateActionButton(main, PADDING + 118, mainY, "Save (Overwrite)", 130, function()
            ST:SaveProfile(selName);
            ST:Print("Profile updated: " .. selName);
            BuildContent();
        end));

        -- Rename
        Track(CreateActionButton(main, PADDING + 256, mainY, "Rename", 80, function()
            -- Inline rename: show an editbox
            if (main._renameBox) then
                main._renameBox:Hide();
                main._renameBox = nil;
            end
            local renameHolder = CreateFrame("Frame", nil, main);
            renameHolder:SetPoint("TOPLEFT", PADDING, mainY - ROW_HEIGHT - 4);
            renameHolder:SetSize(400, ROW_HEIGHT);
            Track(renameHolder);
            main._renameBox = renameHolder;

            local renLabel = renameHolder:CreateFontString(nil, "OVERLAY");
            renLabel:SetFont(FONT, 11);
            renLabel:SetPoint("LEFT", 0, 0);
            renLabel:SetTextColor(unpack(COLOR_MUTED));
            renLabel:SetText("New name:");

            local renInput = CreateFrame("EditBox", nil, renameHolder, "InputBoxTemplate");
            renInput:SetPoint("LEFT", 70, 0);
            renInput:SetSize(180, 22);
            renInput:SetAutoFocus(true);
            if (renInput.SetFontObject and ChatFontNormal) then
                renInput:SetFontObject(ChatFontNormal);
            end
            renInput:SetText(selName);
            renInput:HighlightText();
            renInput:SetScript("OnEnterPressed", function(self)
                local newName = strtrim(self:GetText());
                if (newName ~= "" and newName ~= selName) then
                    ST:RenameProfile(selName, newName);
                    _selectedProfileName = newName;
                    ST:Print("Profile renamed: " .. selName .. " -> " .. newName);
                end
                BuildContent();
            end);
            renInput:SetScript("OnEscapePressed", function()
                renameHolder:Hide();
            end);
        end));

        -- Delete
        Track(CreateActionButton(main, PADDING + 344, mainY, "Delete", 70, function()
            ST:DeleteProfile(selName);
            _selectedProfileName = nil;
            ST:Print("Profile deleted: " .. selName);
            BuildContent();
        end, { 0.4, 0.1, 0.1, 1 }));

        mainY = mainY - ROW_HEIGHT - 12;

        -- Auto-load by Role
        local autoHdr2;
        autoHdr2, mainY = CreateSectionHeader(main, "Auto-load by Role", mainY);
        Track(autoHdr2);

        db.autoLoad = db.autoLoad or {};
        local roleRows = {
            { role = "HEALER",  label = "Healer" },
            { role = "DAMAGER", label = "DPS"    },
            { role = "TANK",    label = "Tank"   },
        };
        local btnW = 80;
        local btnGap = 6;
        for i = 1, #roleRows do
            local rr = roleRows[i];
            local roleCopy = rr.role;
            local isAssigned = (db.autoLoad[rr.role] == selName);
            local roleBtn = CreateFrame("Button", nil, main);
            roleBtn:SetPoint("TOPLEFT", PADDING + (btnW + btnGap) * (i - 1), mainY);
            roleBtn:SetSize(btnW, ROW_HEIGHT);
            SkinButton(roleBtn, isAssigned and { 0.1, 0.32, 0.1, 1 } or COLOR_BTN, COLOR_BTN_HOVER);
            Track(roleBtn);
            local roleTxt = roleBtn:CreateFontString(nil, "OVERLAY");
            roleTxt:SetFont(FONT, 11, "OUTLINE");
            roleTxt:SetPoint("CENTER", 0, 0);
            roleTxt:SetTextColor(unpack(isAssigned and { 0.4, 1, 0.4 } or COLOR_LABEL));
            roleTxt:SetText(isAssigned and (rr.label .. " *") or rr.label);
            roleBtn:SetScript("OnClick", function()
                db.autoLoad = db.autoLoad or {};
                if (isAssigned) then
                    db.autoLoad[roleCopy] = nil;
                else
                    db.autoLoad[roleCopy] = selName;
                end
                BuildContent();
            end);
        end
        mainY = mainY - ROW_HEIGHT - 12;

        -- Import / Export section
        local secHeader;
        secHeader, mainY = CreateSectionHeader(main, "Import / Export", mainY);
        Track(secHeader);

        -- Editbox for import/export
        local editBoxHolder = CreateFrame("Frame", nil, main, "BackdropTemplate");
        editBoxHolder:SetPoint("TOPLEFT", PADDING, mainY);
        editBoxHolder:SetSize(mainWidth - PADDING * 2, 120);
        SkinPanel(editBoxHolder, { 0.06, 0.06, 0.06, 0.95 }, COLOR_BORDER);
        Track(editBoxHolder);

        local ieScrollFrame = CreateFrame("ScrollFrame", nil, editBoxHolder, "UIPanelScrollFrameTemplate");
        ieScrollFrame:SetPoint("TOPLEFT", 6, -6);
        ieScrollFrame:SetPoint("BOTTOMRIGHT", -24, 6);
        Track(ieScrollFrame);

        local importExportBox = CreateFrame("EditBox", nil, ieScrollFrame);
        importExportBox:SetMultiLine(true);
        importExportBox:SetAutoFocus(false);
        importExportBox:SetSize(mainWidth - PADDING * 2 - 40, 200);
        if (importExportBox.SetFontObject and ChatFontNormal) then
            importExportBox:SetFontObject(ChatFontNormal);
        end
        importExportBox:SetText("");
        importExportBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
        ieScrollFrame:SetScrollChild(importExportBox);
        Track(importExportBox);

        mainY = mainY - 128;

        -- Export / Import buttons
        Track(CreateActionButton(main, PADDING, mainY, "Export", 80, function()
            local str = ST:ExportProfile(selName);
            if (str) then
                importExportBox:SetText(str);
                importExportBox:HighlightText();
                importExportBox:SetFocus();
            else
                ST:Print("Export failed.");
            end
        end));

        Track(CreateActionButton(main, PADDING + 88, mainY, "Import", 80, function()
            local str = importExportBox:GetText();
            if (not str or strtrim(str) == "") then
                ST:Print("Paste a profile string first.");
                return;
            end
            local ok, err = ST:ImportProfile(str);
            if (ok) then
                _selectedProfileName = err; -- err contains the generated name on success
                ST:Print("Profile imported: " .. (err or ""));
                BuildContent();
            else
                ST:Print("Import failed: " .. (err or "unknown error"));
            end
        end));

        mainY = mainY - ROW_HEIGHT - 16;
    end

    -- Set heights
    local mainHeight = math.max(64, math.abs(mainY) + PADDING);
    local sideHeight = math.max(100, math.abs(sideY) + PADDING);
    main:SetHeight(mainHeight);
    sidebar:SetHeight(sideHeight);

    return yOff - math.max(mainHeight, sideHeight);
end

-------------------------------------------------------------------------------
-- RebuildOptions (called from Profiles.lua after loading/resetting)
-------------------------------------------------------------------------------

function ST:RebuildOptions()
    _selectedFrameIndex = 1;
    _frameTabs = {};
    if (_optionsFrame and _optionsFrame:IsShown()) then
        BuildContent();
    end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function ST:ToggleOptions()
    local frame = CreateOptionsFrame();
    local s = (ST.db and ST.db.uiScale) or 1.0;
    frame:SetScale(s);
    if (frame:IsShown()) then
        frame:Hide();
    else
        frame:Show();
    end
end

-------------------------------------------------------------------------------
-- Slash Command: /arc
-------------------------------------------------------------------------------

SLASH_REVERSIONRAIDTOOLS1 = "/arc";
SlashCmdList["REVERSIONRAIDTOOLS"] = function(msg)
    msg = strtrim(msg or ""):lower();

    if (msg == "preview" or msg == "preview group" or msg == "preview raid20" or msg == "preview raid40") then
        if (msg == "preview group" and ST.SetPreviewMode) then
            ST:SetPreviewMode("party5");
        elseif (msg == "preview raid20" and ST.SetPreviewMode) then
            ST:SetPreviewMode("raid20");
        elseif (msg == "preview raid40" and ST.SetPreviewMode) then
            ST:SetPreviewMode("raid40");
        end
        if (ST._previewActive) then
            ST:DeactivatePreview();
            ST:Print("Preview disabled.");
        else
            local frame = CreateOptionsFrame();
            if (not frame:IsShown()) then frame:Show(); end
            ST:ActivatePreview();
            local pm = ST.GetPreviewMode and ST:GetPreviewMode() or "party5";
            local label = PREVIEW_MODE_LABELS[pm] or "Group (5)";
            ST:Print("Preview enabled (" .. label .. ").");
        end

    elseif (msg == "reset") then
        local db = ST.db;
        if (db and db.frames) then
            for i = 1, #db.frames do
                ST:ResetPosition(i);
            end
        end
        ST:ResetPosition("interrupts");
        ST:Print("All positions reset.");

    elseif (msg == "lock") then
        local db = ST.db;
        if (not db or not db.frames) then return; end
        local anyUnlocked = false;
        for _, fc in ipairs(db.frames) do
            if (not fc.locked) then anyUnlocked = true; break; end
        end
        local newState = anyUnlocked;
        for i, fc in ipairs(db.frames) do
            fc.locked = newState;
            local display = ST.displayFrames[i];
            if (display and display.title) then
                if (newState) then display.title:Hide(); else display.title:Show(); end
            end
        end
        ST:Print(newState and "All frames locked." or "All frames unlocked.");

    else
        ST:ToggleOptions();
    end
end;
