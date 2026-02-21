local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

local DeepCopyTable = ST.DeepCopyTable;

-------------------------------------------------------------------------------
-- Auto-load Profile by Role
-------------------------------------------------------------------------------

function ST:AutoLoadProfileForCurrentRole()
    local db = self.db;
    if (not db or not db.autoLoad) then return; end
    if (InCombatLockdown()) then return; end

    local specIndex = GetSpecialization();
    if (not specIndex) then return; end

    local _, _, _, _, _, role = GetSpecializationInfo(specIndex);
    if (not role or role == "NONE") then return; end

    local profileName = db.autoLoad[role];
    if (not profileName) then return; end
    if (not db.profiles or not db.profiles[profileName]) then return; end
    if (db.activeProfile == profileName) then return; end

    self:LoadProfile(profileName);
    self:Print("Auto-loaded profile: " .. profileName .. " (" .. role .. ")");
end

-------------------------------------------------------------------------------
-- Save Profile
-------------------------------------------------------------------------------

function ST:SaveProfile(name)
    local db = self.db;
    if (not db) then return; end
    db.profiles = db.profiles or {};
    db.profiles[name] = {
        frames = DeepCopyTable(db.frames or {}),
        interruptFrame = DeepCopyTable(db.interruptFrame or {}),
        savedAt = time(),
    };
    db.activeProfile = name;
end

-------------------------------------------------------------------------------
-- New Profile (blank slate — no frames, default interrupt frame)
-------------------------------------------------------------------------------

function ST:NewProfile(name)
    local db = self.db;
    if (not db) then return; end

    -- Hide and detach all current displays
    self:HideAllDisplays();
    for k, display in pairs(self.displayFrames) do
        if (display.frame) then
            display.frame:Hide();
            display.frame:SetParent(nil);
        end
    end
    wipe(self.displayFrames);

    -- Reset frames to defaults: one default frame
    wipe(db.frames);
    self:CreateCustomFrame("New Frame");

    -- Reset interrupt frame to defaults
    db.interruptFrame = nil;
    self:GetFrameConfig("interrupts");

    -- Deactivate preview if active
    if (self._previewActive and self.DeactivatePreview) then
        self:DeactivatePreview();
    end

    -- Save default state as the new profile
    db.profiles = db.profiles or {};
    db.profiles[name] = {
        frames         = DeepCopyTable(db.frames or {}),
        interruptFrame = DeepCopyTable(db.interruptFrame or {}),
        savedAt        = time(),
    };
    db.activeProfile = name;

    self:RefreshDisplay();
    self:RebuildOptions();
end

-------------------------------------------------------------------------------
-- Load Profile
-------------------------------------------------------------------------------

function ST:LoadProfile(name)
    local db = self.db;
    if (not db) then return; end
    if (InCombatLockdown()) then
        self:Print("Cannot load profiles during combat.");
        return;
    end

    db.profiles = db.profiles or {};
    local snapshot = db.profiles[name];
    if (not snapshot) then
        self:Print("Profile not found: " .. name);
        return;
    end

    -- 1. Hide all displays
    self:HideAllDisplays();

    -- 2. Detach and clean all displayFrames
    for k, display in pairs(self.displayFrames) do
        if (display.frame) then
            display.frame:Hide();
            display.frame:SetParent(nil);
        end
    end
    wipe(self.displayFrames);

    -- 3. Replace frames data
    wipe(db.frames);
    local newFrames = DeepCopyTable(snapshot.frames);
    for i, v in ipairs(newFrames) do
        db.frames[i] = v;
    end

    -- 4. Replace interruptFrame
    db.interruptFrame = DeepCopyTable(snapshot.interruptFrame);

    -- 5. Update active profile
    db.activeProfile = name;

    -- 6. Deactivate preview if active
    if (self._previewActive and self.DeactivatePreview) then
        self:DeactivatePreview();
    end

    -- 7. Refresh display
    self:RefreshDisplay();

    -- 8. Rebuild options UI
    self:RebuildOptions();
end

-------------------------------------------------------------------------------
-- Delete Profile
-------------------------------------------------------------------------------

function ST:DeleteProfile(name)
    local db = self.db;
    if (not db) then return; end
    db.profiles = db.profiles or {};
    db.profiles[name] = nil;
    if (db.activeProfile == name) then
        db.activeProfile = nil;
    end
end

-------------------------------------------------------------------------------
-- Rename Profile
-------------------------------------------------------------------------------

function ST:RenameProfile(oldName, newName)
    local db = self.db;
    if (not db) then return; end
    db.profiles = db.profiles or {};
    if (not db.profiles[oldName]) then return; end
    if (db.profiles[newName]) then
        self:Print("A profile named '" .. newName .. "' already exists.");
        return;
    end
    db.profiles[newName] = db.profiles[oldName];
    db.profiles[oldName] = nil;
    if (db.activeProfile == oldName) then
        db.activeProfile = newName;
    end
end

-------------------------------------------------------------------------------
-- Reset to Defaults
-------------------------------------------------------------------------------

function ST:ResetToDefaults()
    local db = self.db;
    if (not db) then return; end

    -- Hide and detach all displays
    self:HideAllDisplays();
    for k, display in pairs(self.displayFrames) do
        if (display.frame) then
            display.frame:Hide();
            display.frame:SetParent(nil);
        end
    end
    wipe(self.displayFrames);

    -- Wipe all frames (start from zero)
    wipe(db.frames);

    -- Reset interrupt frame
    db.interruptFrame = nil;
    -- Force re-initialization via GetFrameConfig
    self:GetFrameConfig("interrupts");

    db.activeProfile = nil;

    -- Deactivate preview if active
    if (self._previewActive and self.DeactivatePreview) then
        self:DeactivatePreview();
    end

    self:RefreshDisplay();
    self:RebuildOptions();
end

-------------------------------------------------------------------------------
-- Get Profile Names (sorted)
-------------------------------------------------------------------------------

function ST:GetProfileNames()
    local db = self.db;
    if (not db) then return {}; end
    db.profiles = db.profiles or {};
    local names = {};
    for name in pairs(db.profiles) do
        table.insert(names, name);
    end
    table.sort(names);
    return names;
end

-------------------------------------------------------------------------------
-- Serialization Helpers
-------------------------------------------------------------------------------

local MAX_DEPTH = 20;

local function SerializeValue(v, depth)
    if (depth > MAX_DEPTH) then return "nil"; end
    local t = type(v);
    if (t == "string") then
        -- Escape special characters
        local escaped = v:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r");
        return "\"" .. escaped .. "\"";
    elseif (t == "number") then
        if (v == math.floor(v)) then
            return tostring(math.floor(v));
        end
        return string.format("%.6g", v);
    elseif (t == "boolean") then
        return v and "true" or "false";
    elseif (t == "table") then
        local parts = {};
        -- Check if array-like
        local maxN = 0;
        local count = 0;
        for k in pairs(v) do
            count = count + 1;
            if (type(k) == "number" and k == math.floor(k) and k > 0) then
                if (k > maxN) then maxN = k; end
            end
        end
        local isArray = (maxN == count and maxN > 0);

        if (isArray) then
            for i = 1, maxN do
                table.insert(parts, SerializeValue(v[i], depth + 1));
            end
        else
            local keys = {};
            for k in pairs(v) do table.insert(keys, k); end
            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b);
            end);
            for _, k in ipairs(keys) do
                local kStr;
                if (type(k) == "number") then
                    kStr = "[" .. SerializeValue(k, depth + 1) .. "]";
                else
                    kStr = tostring(k);
                end
                table.insert(parts, kStr .. "=" .. SerializeValue(v[k], depth + 1));
            end
        end
        return "{" .. table.concat(parts, ",") .. "}";
    elseif (t == "nil") then
        return "nil";
    else
        return "nil";
    end
end

-------------------------------------------------------------------------------
-- Deserialization (recursive descent parser)
-------------------------------------------------------------------------------

local function CreateParser(str)
    return { str = str, pos = 1 };
end

local function Peek(p)
    return p.str:sub(p.pos, p.pos);
end

local function Skip(p)
    p.pos = p.pos + 1;
end

local function SkipWhitespace(p)
    while (p.pos <= #p.str) do
        local c = p.str:sub(p.pos, p.pos);
        if (c == " " or c == "\t" or c == "\n" or c == "\r") then
            p.pos = p.pos + 1;
        else
            break;
        end
    end
end

local ParseValue; -- forward declaration

local function ParseString(p)
    -- Assumes current pos is at opening quote
    Skip(p); -- skip opening "
    local result = {};
    while (p.pos <= #p.str) do
        local c = p.str:sub(p.pos, p.pos);
        if (c == "\\") then
            Skip(p);
            local next = p.str:sub(p.pos, p.pos);
            if (next == "n") then table.insert(result, "\n");
            elseif (next == "r") then table.insert(result, "\r");
            elseif (next == "\"") then table.insert(result, "\"");
            elseif (next == "\\") then table.insert(result, "\\");
            else table.insert(result, next);
            end
            Skip(p);
        elseif (c == "\"") then
            Skip(p); -- skip closing "
            return table.concat(result);
        else
            table.insert(result, c);
            Skip(p);
        end
    end
    return nil; -- unterminated string
end

local function ParseNumber(p)
    local start = p.pos;
    -- Match optional minus, digits, optional dot + digits, optional exponent
    if (p.str:sub(p.pos, p.pos) == "-") then Skip(p); end
    while (p.pos <= #p.str and p.str:sub(p.pos, p.pos):match("[0-9]")) do
        Skip(p);
    end
    if (p.pos <= #p.str and p.str:sub(p.pos, p.pos) == ".") then
        Skip(p);
        while (p.pos <= #p.str and p.str:sub(p.pos, p.pos):match("[0-9]")) do
            Skip(p);
        end
    end
    -- Optional exponent
    if (p.pos <= #p.str and p.str:sub(p.pos, p.pos):match("[eE]")) then
        Skip(p);
        if (p.pos <= #p.str and p.str:sub(p.pos, p.pos):match("[%+%-]")) then
            Skip(p);
        end
        while (p.pos <= #p.str and p.str:sub(p.pos, p.pos):match("[0-9]")) do
            Skip(p);
        end
    end
    local numStr = p.str:sub(start, p.pos - 1);
    return tonumber(numStr);
end

local function ParseTable(p)
    Skip(p); -- skip {
    local result = {};
    local arrayIndex = 1;
    local isArray = true;

    SkipWhitespace(p);
    if (Peek(p) == "}") then
        Skip(p);
        return result;
    end

    while (p.pos <= #p.str) do
        SkipWhitespace(p);
        if (Peek(p) == "}") then
            Skip(p);
            return result;
        end

        -- Check for key=value or [key]=value
        local key = nil;
        local savedPos = p.pos;

        if (Peek(p) == "[") then
            -- Bracketed key
            Skip(p);
            SkipWhitespace(p);
            key = ParseValue(p);
            SkipWhitespace(p);
            if (Peek(p) == "]") then Skip(p); end
            SkipWhitespace(p);
            if (Peek(p) == "=") then
                Skip(p);
                isArray = false;
            else
                -- Not a key, restore
                p.pos = savedPos;
                key = nil;
            end
        else
            -- Try identifier=value
            local identStart = p.pos;
            while (p.pos <= #p.str and p.str:sub(p.pos, p.pos):match("[%w_]")) do
                Skip(p);
            end
            local identEnd = p.pos;
            SkipWhitespace(p);

            if (Peek(p) == "=" and identEnd > identStart) then
                key = p.str:sub(identStart, identEnd - 1);
                Skip(p); -- skip =
                isArray = false;
            else
                -- Not a key=value, restore and parse as array element
                p.pos = savedPos;
            end
        end

        SkipWhitespace(p);
        local value = ParseValue(p);

        if (key ~= nil) then
            -- Convert numeric string keys that look like numbers
            local numKey = tonumber(key);
            if (numKey and type(key) == "string" and tostring(numKey) == key) then
                result[numKey] = value;
            else
                result[key] = value;
            end
        else
            result[arrayIndex] = value;
            arrayIndex = arrayIndex + 1;
        end

        SkipWhitespace(p);
        if (Peek(p) == ",") then
            Skip(p);
        end
    end

    return result;
end

ParseValue = function(p)
    SkipWhitespace(p);
    if (p.pos > #p.str) then return nil; end

    local c = Peek(p);

    if (c == "\"") then
        return ParseString(p);
    elseif (c == "{") then
        return ParseTable(p);
    elseif (c == "-" or c:match("[0-9]")) then
        return ParseNumber(p);
    elseif (p.str:sub(p.pos, p.pos + 3) == "true") then
        p.pos = p.pos + 4;
        return true;
    elseif (p.str:sub(p.pos, p.pos + 4) == "false") then
        p.pos = p.pos + 5;
        return false;
    elseif (p.str:sub(p.pos, p.pos + 2) == "nil") then
        p.pos = p.pos + 3;
        return nil;
    end

    return nil;
end

-------------------------------------------------------------------------------
-- Export Profile
-------------------------------------------------------------------------------

function ST:ExportProfile(name)
    local db = self.db;
    if (not db) then return nil; end
    db.profiles = db.profiles or {};
    local snapshot = db.profiles[name];
    if (not snapshot) then return nil; end

    local ok, result = pcall(function()
        local data = {
            frames = snapshot.frames,
            interruptFrame = snapshot.interruptFrame,
        };
        return "ARC1:" .. SerializeValue(data, 0);
    end);

    if (ok) then return result; end
    return nil;
end

-------------------------------------------------------------------------------
-- Import Profile
-------------------------------------------------------------------------------

function ST:ImportProfile(str)
    if (not str or type(str) ~= "string") then
        return false, "Invalid input.";
    end
    str = strtrim(str);

    -- Check prefix
    if (str:sub(1, 5) ~= "ARC1:") then
        return false, "Invalid format (expected ARC1: prefix).";
    end

    local payload = str:sub(6);

    local ok, data = pcall(function()
        local p = CreateParser(payload);
        return ParseValue(p);
    end);

    if (not ok or type(data) ~= "table") then
        return false, "Failed to parse profile data.";
    end

    -- Validate
    if (type(data.frames) ~= "table") then
        return false, "Profile data missing 'frames'.";
    end
    if (#data.frames > 20) then
        return false, "Too many frames (max 20).";
    end

    -- Generate a unique name
    local db = self.db;
    if (not db) then return false, "No database."; end
    db.profiles = db.profiles or {};

    local baseName = "Imported";
    local name = baseName;
    local counter = 1;
    while (db.profiles[name]) do
        counter = counter + 1;
        name = baseName .. " " .. counter;
    end

    db.profiles[name] = {
        frames = DeepCopyTable(data.frames),
        interruptFrame = data.interruptFrame and DeepCopyTable(data.interruptFrame) or nil,
        savedAt = time(),
    };

    return true, name;
end
