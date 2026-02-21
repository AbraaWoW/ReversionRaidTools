local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

local MAX_CUSTOM_FRAMES = 20;
local CREATE_DEBOUNCE_SECONDS = 0.20;

-------------------------------------------------------------------------------
-- Custom Frame Management
--
-- Manages the creation, deletion, and configuration of user-defined frames.
-- Each frame has its own spell selection, layout settings, and position.
-------------------------------------------------------------------------------

local function NextAutoFrameName(db)
    local used = {};
    for i = 1, #(db.frames or {}) do
        local cfg = db.frames[i];
        if (cfg and type(cfg.name) == "string") then
            local n = tonumber(cfg.name:match("^Frame%s+(%d+)$"));
            if (n and n > 0) then
                used[n] = true;
            end
        end
    end

    local idx = 1;
    while (used[idx]) do
        idx = idx + 1;
    end
    return "Frame " .. idx;
end

function ST:CreateCustomFrame(name)
    local db = self.db;
    if (not db) then return nil; end
    if (#db.frames >= MAX_CUSTOM_FRAMES) then
        if (self.Print) then
            self:Print("Maximum " .. MAX_CUSTOM_FRAMES .. " frames allowed.");
        end
        return nil;
    end

    -- Guard against duplicate creations from accidental double-clicks.
    local now = (GetTimePreciseSec and GetTimePreciseSec()) or GetTime();
    if (self._lastCustomFrameCreate and (now - self._lastCustomFrameCreate) < CREATE_DEBOUNCE_SECONDS) then
        return nil;
    end
    self._lastCustomFrameCreate = now;

    local frameName = name;
    if (type(frameName) ~= "string" or frameName == "") then
        frameName = NextAutoFrameName(db);
    end

    -- Deep copy defaults
    local newFrame = {};
    for k, v in pairs(self.FRAME_DEFAULTS) do
        if (type(v) == "table") then
            local copy = {};
            for dk, dv in pairs(v) do copy[dk] = dv; end
            newFrame[k] = copy;
        else
            newFrame[k] = v;
        end
    end
    newFrame.name = frameName;

    -- Preselect player class spells so a new frame is directly usable.
    local playerClass = self.playerClass or select(2, UnitClass("player"));
    local playerSpec = GetSpecializationInfo(GetSpecialization() or 0) or nil;
    if (playerClass and self.GetSpellsForClass) then
        local classSpells = self:GetSpellsForClass(playerClass, playerSpec);
        if (classSpells) then
            for spellID in pairs(classSpells) do
                newFrame.spells[spellID] = true;
            end
        end
    end

    table.insert(db.frames, newFrame);
    return #db.frames;
end

function ST:DeleteCustomFrame(frameIndex)
    local db = self.db;
    if (not db or not db.frames[frameIndex]) then return false; end

    -- Hide and clean up display frame
    if (self.displayFrames and self.displayFrames[frameIndex]) then
        local display = self.displayFrames[frameIndex];
        if (display.frame) then
            display.frame:Hide();
            display.frame:SetParent(nil);
        end
        self.displayFrames[frameIndex] = nil;
    end

    table.remove(db.frames, frameIndex);

    -- Re-index display frames after removal
    if (self.displayFrames) then
        local newDisplayFrames = {};
        for idx, display in pairs(self.displayFrames) do
            if (type(idx) == "number") then
                if (idx > frameIndex) then
                    newDisplayFrames[idx - 1] = display;
                else
                    newDisplayFrames[idx] = display;
                end
            end
        end
        self.displayFrames = newDisplayFrames;
    end

    if (self.RefreshDisplay) then
        self:RefreshDisplay();
    end

    return true;
end

function ST:GetCustomFrameCount()
    if (not self.db or not self.db.frames) then return 0; end
    return #self.db.frames;
end
