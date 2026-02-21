local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Raid Groups
-------------------------------------------------------------------------------

-- Build the Raid Groups tab content (called from Options.lua)
function ST:BuildRaidGroupsSection(parent, yOff, FONT, PADDING, ROW_HEIGHT,
    COLOR_MUTED, COLOR_LABEL, COLOR_ACCENT, COLOR_BTN, COLOR_BTN_HOVER,
    SkinButton, CreateCheckbox, CreateActionButton, Track)

    -- Section title
    local title = parent:CreateFontString(nil, "OVERLAY");
    title:SetFont(FONT, 13, "OUTLINE");
    title:SetPoint("TOPLEFT", PADDING, yOff);
    title:SetTextColor(unpack(COLOR_ACCENT));
    title:SetText("Raid Groups");
    Track(title);
    yOff = yOff - 28;

    return yOff - 8;
end
