local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-- Spell database populated by RegisterSpells calls below
ST.spellDB = {};          -- spellID -> spell entry
ST.talentModifiers = {};  -- array of talent modifier entries
ST.spellAliases = {};     -- altSpellID -> canonicalSpellID

function ST:RegisterSpells(spells)
    for _, spell in ipairs(spells) do
        self.spellDB[spell.id] = spell;
    end
end

function ST:RegisterTalentModifiers(modifiers)
    for _, mod in ipairs(modifiers) do
        table.insert(self.talentModifiers, mod);
    end
end

function ST:RegisterSpellAliases(aliases)
    for alt, canonical in pairs(aliases) do
        self.spellAliases[alt] = canonical;
    end
end

function ST:GetSpellsForClass(class, spec)
    local result = {};
    for id, spell in pairs(self.spellDB) do
        if (spell.class == class) then
            if (not spell.specs or (spec and spell.specs[spec])) then
                result[id] = spell;
            end
        end
    end
    return result;
end

function ST:RegisterCategory(name, config)
    -- no-op: category metadata defined but not used at runtime
end

function ST:GetSpellsByCategory(category)
    local result = {};
    for id, spell in pairs(self.spellDB) do
        if (spell.category == category) then
            result[id] = spell;
        end
    end
    return result;
end

-------------------------------------------------------------------------------
-- Interrupt Spell Database
-------------------------------------------------------------------------------

ST:RegisterSpells({
    -- Death Knight: Mind Freeze
    {
        id       = 47528,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "interrupt",
    },
    -- Demon Hunter: Disrupt
    {
        id       = 183752,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = nil,
        category = "interrupt",
    },
    -- Druid: Skull Bash (Feral / Guardian)
    {
        id       = 106839,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "DRUID",
        specs    = { [103] = true, [104] = true },
        category = "interrupt",
    },
    -- Druid: Solar Beam (Balance)
    {
        id       = 78675,
        cd       = 60,
        duration = nil,
        charges  = nil,
        class    = "DRUID",
        specs    = { [102] = true },
        category = "interrupt",
    },
    -- Evoker: Quell (Devastation / Augmentation only)
    {
        id       = 351338,
        cd       = 20,
        cdBySpec = { [1473] = 18 },
        duration = nil,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1467] = true, [1473] = true },
        category = "interrupt",
    },
    -- Hunter: Counter Shot (BM / MM)
    {
        id       = 147362,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [253] = true, [254] = true },
        category = "interrupt",
    },
    -- Hunter: Muzzle (Survival)
    {
        id       = 187707,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [255] = true },
        category = "interrupt",
    },
    -- Mage: Counterspell
    {
        id       = 2139,
        cd       = 25,
        duration = nil,
        charges  = nil,
        class    = "MAGE",
        specs    = nil,
        category = "interrupt",
    },
    -- Monk: Spear Hand Strike (Windwalker / Brewmaster)
    {
        id       = 116705,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "MONK",
        specs    = { [269] = true, [268] = true },
        category = "interrupt",
    },
    -- Paladin: Rebuke (Protection / Retribution)
    {
        id       = 96231,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [66] = true, [70] = true },
        category = "interrupt",
    },
    -- Priest: Silence (Shadow only)
    {
        id       = 15487,
        cd       = 30,
        duration = nil,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "interrupt",
    },
    -- Rogue: Kick
    {
        id       = 1766,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "interrupt",
    },
    -- Shaman: Wind Shear (12s base, 30s for Resto)
    {
        id       = 57994,
        cd       = 12,
        cdBySpec = { [264] = 30 },
        duration = nil,
        charges  = nil,
        class    = "SHAMAN",
        specs    = nil,
        category = "interrupt",
    },
    -- Warlock: Spell Lock (Felhunter — Affliction / Destruction)
    {
        id       = 19647,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [265] = true, [267] = true },
        category = "interrupt",
    },
    -- Warlock: Spell Lock (Felhunter alt ID — Affliction / Destruction)
    {
        id       = 132409,
        cd       = 24,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [265] = true, [267] = true },
        category = "interrupt",
    },
    -- Warlock: Axe Toss (Felguard — Demonology)
    {
        id       = 89766,
        cd       = 30,
        duration = nil,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [266] = true },
        category = "interrupt",
    },
    -- Warrior: Pummel
    {
        id       = 6552,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "interrupt",
    },
});

-------------------------------------------------------------------------------
-- Defensive Spell Database
-------------------------------------------------------------------------------

ST:RegisterSpells({
    -- WARRIOR: Shield Wall (Protection)
    {
        id       = 871,
        cd       = 210,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [73] = true },
        category = "defensive",
    },
    -- WARRIOR: Die by the Sword (Arms)
    {
        id       = 118038,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [71] = true },
        category = "defensive",
    },
    -- WARRIOR: Enraged Regeneration (Fury)
    {
        id       = 184364,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [72] = true },
        category = "defensive",
    },
    -- WARRIOR: Rallying Cry
    {
        id       = 97462,
        cd       = 180,
        duration = 10,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "defensive",
    },
    -- WARRIOR: Last Stand
    {
        id       = 12975,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "defensive",
    },

    -- PALADIN: Divine Shield
    {
        id       = 642,
        cd       = 300,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "defensive",
    },
    -- PALADIN: Ardent Defender (Protection)
    {
        id       = 31850,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [66] = true },
        category = "defensive",
    },
    -- PALADIN: Guardian of Ancient Kings (Protection)
    {
        id       = 86659,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [66] = true },
        category = "defensive",
    },
    -- PALADIN: Blessing of Protection
    {
        id       = 1022,
        cd       = 300,
        duration = 10,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "defensive",
    },

    -- DEATHKNIGHT: Anti-Magic Shell
    {
        id       = 48707,
        cd       = 60,
        duration = 5,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Icebound Fortitude
    {
        id       = 48792,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Anti-Magic Zone
    {
        id       = 51052,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Lichborne
    {
        id       = 49039,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Death Pact
    {
        id       = 48743,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "defensive",
    },
    -- DEATHKNIGHT: Vampiric Blood (Blood)
    {
        id       = 55233,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "defensive",
    },
    -- DEATHKNIGHT: Dancing Rune Weapon (Blood)
    {
        id       = 49028,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "defensive",
    },
    -- DEATHKNIGHT: Tombstone (Blood)
    {
        id       = 219809,
        cd       = 60,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "defensive",
    },
    -- DEATHKNIGHT: Purgatory (Blood — passive cheat death)
    {
        id       = 114556,
        cd       = 600,
        duration = 4,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "defensive",
    },

    -- ROGUE: Cloak of Shadows
    {
        id       = 31224,
        cd       = 120,
        duration = 5,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "defensive",
    },
    -- ROGUE: Evasion
    {
        id       = 5277,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "defensive",
    },

    -- MAGE: Ice Block
    {
        id       = 45438,
        cd       = 240,
        duration = 10,
        charges  = nil,
        class    = "MAGE",
        specs    = nil,
        category = "defensive",
    },
    -- MAGE: Greater Invisibility
    {
        id       = 110959,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "MAGE",
        specs    = nil,
        category = "defensive",
    },

    -- HUNTER: Survival of the Fittest
    {
        id       = 281195,
        cd       = 180,
        duration = 6,
        charges  = nil,
        class    = "HUNTER",
        specs    = nil,
        category = "defensive",
    },
    -- HUNTER: Aspect of the Turtle
    {
        id       = 186265,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "HUNTER",
        specs    = nil,
        category = "defensive",
    },

    -- DRUID: Barkskin
    {
        id       = 22812,
        cd       = 60,
        duration = 8,
        charges  = nil,
        class    = "DRUID",
        specs    = nil,
        category = "defensive",
    },
    -- DRUID: Survival Instincts (Feral / Guardian)
    {
        id       = 61336,
        cd       = 180,
        duration = 6,
        charges  = 2,
        class    = "DRUID",
        specs    = { [103] = true, [104] = true },
        category = "defensive",
    },

    -- MONK: Fortifying Brew
    {
        id       = 115203,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "MONK",
        specs    = nil,
        category = "defensive",
    },
    -- MONK: Dampen Harm
    {
        id       = 122278,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "MONK",
        specs    = nil,
        category = "defensive",
    },

    -- DEMONHUNTER: Blur (Havoc / Devourer)
    {
        id       = 198589,
        cd       = 60,
        duration = 10,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [577] = true, [1480] = true },
        category = "defensive",
    },
    -- DEMONHUNTER: Metamorphosis (Vengeance)
    {
        id       = 187827,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [581] = true },
        category = "defensive",
    },
    -- DEMONHUNTER: Darkness
    {
        id       = 196718,
        cd       = 300,
        duration = 8,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = nil,
        category = "defensive",
    },

    -- PRIEST: Dispersion (Shadow)
    {
        id       = 47585,
        cd       = 90,
        duration = 6,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "defensive",
    },
    -- PRIEST: Desperate Prayer
    {
        id       = 19236,
        cd       = 90,
        duration = 10,
        charges  = nil,
        class    = "PRIEST",
        specs    = nil,
        category = "defensive",
    },
    -- PRIEST: Vampiric Embrace (Shadow)
    {
        id       = 15286,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "defensive",
    },

    -- SHAMAN: Astral Shift
    {
        id       = 108271,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "SHAMAN",
        specs    = nil,
        category = "defensive",
    },
    -- SHAMAN: Earth Elemental
    {
        id       = 198103,
        cd       = 180,
        duration = 30,
        charges  = nil,
        class    = "SHAMAN",
        specs    = nil,
        category = "defensive",
    },

    -- WARLOCK: Unending Resolve
    {
        id       = 104773,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "WARLOCK",
        specs    = nil,
        category = "defensive",
    },

    -- EVOKER: Obsidian Scales
    {
        id       = 363916,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "EVOKER",
        specs    = nil,
        category = "defensive",
    },
    -- EVOKER: Zephyr
    {
        id       = 374227,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "EVOKER",
        specs    = nil,
        category = "defensive",
    },
});

-------------------------------------------------------------------------------
-- Cooldown Spell Database
-------------------------------------------------------------------------------

ST:RegisterSpells({
    -- WARRIOR: Recklessness (Fury)
    {
        id       = 1719,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [72] = true },
        category = "cooldown",
    },
    -- WARRIOR: Avatar
    {
        id       = 107574,
        cd       = 90,
        duration = 20,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "cooldown",
    },
    -- WARRIOR: Thunderous Roar
    {
        id       = 384318,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "cooldown",
    },
    -- WARRIOR: Ravager (Arms / Protection)
    {
        id       = 228920,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [71] = true, [73] = true },
        category = "cooldown",
    },
    -- WARRIOR: Champion's Spear
    {
        id       = 376079,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "cooldown",
    },

    -- PALADIN: Avenging Wrath
    {
        id       = 31884,
        cd       = 120,
        duration = 20,
        cdBySpec = { [70] = 60 },
        charges  = nil,
        class    = "PALADIN",
        specs    = { [65] = true, [66] = true, [70] = true },
        category = "cooldown",
    },
    -- PALADIN: Aura Mastery (Holy)
    {
        id       = 31821,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [65] = true },
        category = "cooldown",
    },
    -- PALADIN: Lay on Hands
    {
        id       = 633,
        cd       = 420,
        duration = nil,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "cooldown",
    },
    -- PALADIN: Blessing of Sacrifice
    {
        id       = 6940,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "cooldown",
    },

    -- DEATHKNIGHT: Pillar of Frost (Frost)
    {
        id       = 51271,
        cd       = 45,
        duration = 12,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [251] = true },
        category = "cooldown",
    },
    -- DEATHKNIGHT: Dark Transformation (Unholy)
    {
        id       = 63560,
        cd       = 45,
        duration = 15,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [252] = true },
        category = "cooldown",
    },
    -- DEATHKNIGHT: Army of the Dead (Unholy)
    {
        id       = 42650,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [252] = true },
        category = "cooldown",
    },
    -- DEATHKNIGHT: Empower Rune Weapon (Frost)
    {
        id       = 47568,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [251] = true },
        category = "cooldown",
    },
    -- DEATHKNIGHT: Abomination Limb
    {
        id       = 383269,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "cooldown",
    },
    -- DEATHKNIGHT: Gorefiend's Grasp (Blood)
    {
        id       = 108199,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "cooldown",
    },

    -- ROGUE: Adrenaline Rush (Outlaw)
    {
        id       = 13750,
        cd       = 180,
        duration = 19,
        charges  = nil,
        class    = "ROGUE",
        specs    = { [260] = true },
        category = "cooldown",
    },
    -- ROGUE: Shadow Blades (Subtlety)
    {
        id       = 121471,
        cd       = 90,
        duration = 16,
        charges  = nil,
        class    = "ROGUE",
        specs    = { [261] = true },
        category = "cooldown",
    },
    -- ROGUE: Deathmark (Assassination)
    {
        id       = 360194,
        cd       = 120,
        duration = 16,
        charges  = nil,
        class    = "ROGUE",
        specs    = { [259] = true },
        category = "cooldown",
    },

    -- HUNTER: Trueshot (Marksmanship)
    {
        id       = 288613,
        cd       = 120,
        duration = 15,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [254] = true },
        category = "cooldown",
    },
    -- HUNTER: Bestial Wrath (Beast Mastery)
    {
        id       = 19574,
        cd       = 30,
        duration = 15,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [253] = true },
        category = "cooldown",
    },
    -- HUNTER: Takedown (Survival)
    {
        id       = 1250646,
        cd       = 90,
        duration = 10,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [255] = true },
        category = "cooldown",
    },

    -- MAGE: Combustion (Fire)
    {
        id       = 190319,
        cd       = 60,
        duration = 10,
        charges  = nil,
        class    = "MAGE",
        specs    = { [63] = true },
        category = "cooldown",
    },
    -- MAGE: Ray of Frost (Frost)
    {
        id       = 205021,
        cd       = 60,
        duration = 4,
        charges  = nil,
        class    = "MAGE",
        specs    = { [64] = true },
        category = "cooldown",
    },
    -- MAGE: Arcane Surge (Arcane)
    {
        id       = 365350,
        cd       = 90,
        duration = 15,
        charges  = nil,
        class    = "MAGE",
        specs    = { [62] = true },
        category = "cooldown",
    },

    -- WARLOCK: Summon Infernal (Destruction)
    {
        id       = 1122,
        cd       = 120,
        duration = 30,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [267] = true },
        category = "cooldown",
    },
    -- WARLOCK: Summon Darkglare (Affliction)
    {
        id       = 205180,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [265] = true },
        category = "cooldown",
    },
    -- WARLOCK: Summon Demonic Tyrant (Demonology)
    {
        id       = 265187,
        cd       = 60,
        duration = 15,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [266] = true },
        category = "cooldown",
    },

    -- DRUID: Celestial Alignment (Balance)
    {
        id       = 194223,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DRUID",
        specs    = { [102] = true },
        category = "cooldown",
    },
    -- DRUID: Incarnation: Chosen of Elune (Balance)
    {
        id       = 102560,
        cd       = 180,
        duration = 20,
        charges  = nil,
        class    = "DRUID",
        specs    = { [102] = true },
        category = "cooldown",
    },
    -- DRUID: Berserk (Feral)
    {
        id       = 106951,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DRUID",
        specs    = { [103] = true },
        category = "cooldown",
    },
    -- DRUID: Incarnation: Avatar of Ashamane (Feral)
    {
        id       = 102543,
        cd       = 180,
        duration = 20,
        charges  = nil,
        class    = "DRUID",
        specs    = { [103] = true },
        category = "cooldown",
    },
    -- DRUID: Berserk (Guardian)
    {
        id       = 50334,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DRUID",
        specs    = { [104] = true },
        category = "cooldown",
    },
    -- DRUID: Incarnation: Guardian of Ursoc (Guardian)
    {
        id       = 102558,
        cd       = 180,
        duration = 30,
        charges  = nil,
        class    = "DRUID",
        specs    = { [104] = true },
        category = "cooldown",
    },
    -- DRUID: Tranquility (Restoration)
    {
        id       = 740,
        cd       = 120,
        duration = 6,
        charges  = nil,
        class    = "DRUID",
        specs    = { [105] = true },
        category = "cooldown",
    },
    -- DRUID: Incarnation: Tree of Life (Restoration)
    {
        id       = 33891,
        cd       = 120,
        duration = 30,
        charges  = nil,
        class    = "DRUID",
        specs    = { [105] = true },
        category = "cooldown",
    },
    -- DRUID: Convoke the Spirits
    {
        id       = 391528,
        cd       = 60,
        duration = 4,
        charges  = nil,
        class    = "DRUID",
        specs    = nil,
        category = "cooldown",
    },
    -- DRUID: Ironbark (Restoration)
    {
        id       = 102342,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "DRUID",
        specs    = { [105] = true },
        category = "cooldown",
    },

    -- MONK: Touch of Death
    {
        id       = 322109,
        cd       = 180,
        duration = nil,
        charges  = nil,
        class    = "MONK",
        specs    = nil,
        category = "cooldown",
    },
    -- MONK: Invoke Niuzao (Brewmaster)
    {
        id       = 132578,
        cd       = 120,
        duration = 25,
        charges  = nil,
        class    = "MONK",
        specs    = { [268] = true },
        category = "cooldown",
    },
    -- MONK: Zenith (Windwalker)
    {
        id       = 1249625,
        cd       = 90,
        duration = 15,
        charges  = 2,
        class    = "MONK",
        specs    = { [269] = true },
        category = "cooldown",
    },
    -- MONK: Invoke Xuen (Windwalker)
    {
        id       = 123904,
        cd       = 96,
        duration = 20,
        charges  = nil,
        class    = "MONK",
        specs    = { [269] = true },
        category = "cooldown",
    },
    -- MONK: Revival (Mistweaver)
    {
        id       = 115310,
        cd       = 180,
        duration = nil,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "cooldown",
    },
    -- MONK: Restoral (Mistweaver)
    {
        id       = 388615,
        cd       = 180,
        duration = nil,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "cooldown",
    },
    -- MONK: Invoke Yu'lon (Mistweaver)
    {
        id       = 322118,
        cd       = 120,
        duration = 25,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "cooldown",
    },
    -- MONK: Invoke Chi-Ji (Mistweaver)
    {
        id       = 325197,
        cd       = 120,
        duration = 25,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "cooldown",
    },
    -- MONK: Life Cocoon (Mistweaver)
    {
        id       = 116849,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "cooldown",
    },

    -- DEMONHUNTER: Metamorphosis (Havoc)
    {
        id       = 191427,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [577] = true },
        category = "cooldown",
    },
    -- DEMONHUNTER: Void Metamorphosis (Devourer)
    {
        id       = 1217605,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [1480] = true },
        category = "cooldown",
    },
    -- DEMONHUNTER: The Hunt (Havoc)
    {
        id       = 370965,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [577] = true },
        category = "cooldown",
    },
    -- DEMONHUNTER: The Hunt (Devourer)
    {
        id       = 1246167,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [1480] = true },
        category = "cooldown",
    },

    -- PRIEST: Voidform (Shadow)
    {
        id       = 194249,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "cooldown",
    },
    -- PRIEST: Power Infusion
    {
        id       = 10060,
        cd       = 120,
        duration = 15,
        charges  = nil,
        class    = "PRIEST",
        specs    = nil,
        category = "cooldown",
    },
    -- PRIEST: Divine Hymn (Holy)
    {
        id       = 64843,
        cd       = 180,
        duration = 5,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [257] = true },
        category = "cooldown",
    },
    -- PRIEST: Apotheosis (Holy)
    {
        id       = 200183,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [257] = true },
        category = "cooldown",
    },
    -- PRIEST: Guardian Spirit (Holy)
    {
        id       = 47788,
        cd       = 180,
        duration = 10,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [257] = true },
        category = "cooldown",
    },
    -- PRIEST: Symbol of Hope (Holy)
    {
        id       = 64901,
        cd       = 180,
        duration = 4,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [257] = true },
        category = "cooldown",
    },
    -- PRIEST: Rapture (Discipline)
    {
        id       = 47536,
        cd       = 90,
        duration = 30,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [256] = true },
        category = "cooldown",
    },
    -- PRIEST: Pain Suppression (Discipline)
    {
        id       = 33206,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [256] = true },
        category = "cooldown",
    },
    -- PRIEST: Power Word: Barrier (Discipline)
    {
        id       = 62618,
        cd       = 180,
        duration = 10,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [256] = true },
        category = "cooldown",
    },
    -- PRIEST: Ultimate Penitence (Discipline)
    {
        id       = 421453,
        cd       = 240,
        duration = 4.3,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [256] = true },
        category = "cooldown",
    },

    -- SHAMAN: Ascendance (Elemental)
    {
        id       = 114049,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [262] = true },
        category = "cooldown",
    },
    -- SHAMAN: Doom Winds (Enhancement)
    {
        id       = 384352,
        cd       = 60,
        duration = 8,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [263] = true },
        category = "cooldown",
    },
    -- SHAMAN: Ascendance (Enhancement)
    {
        id       = 114051,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [263] = true },
        category = "cooldown",
    },
    -- SHAMAN: Healing Tide Totem (Restoration)
    {
        id       = 108280,
        cd       = 180,
        duration = 10,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [264] = true },
        category = "cooldown",
    },
    -- SHAMAN: Ascendance (Restoration)
    {
        id       = 114052,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [264] = true },
        category = "cooldown",
    },
    -- SHAMAN: Spirit Link Totem (Restoration)
    {
        id       = 98008,
        cd       = 180,
        duration = 6,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [264] = true },
        category = "cooldown",
    },

    -- EVOKER: Dragonrage (Devastation)
    {
        id       = 375087,
        cd       = 120,
        duration = 18,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1467] = true },
        category = "cooldown",
    },
    -- EVOKER: Rewind (Preservation)
    {
        id       = 363534,
        cd       = 240,
        duration = 4,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1468] = true },
        category = "cooldown",
    },
    -- EVOKER: Tip the Scales
    {
        id       = 370553,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "EVOKER",
        specs    = nil,
        category = "cooldown",
    },
    -- EVOKER: Breath of Eons (Augmentation)
    {
        id       = 403631,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1473] = true },
        category = "cooldown",
    },
    -- EVOKER: Dream Flight (Preservation)
    {
        id       = 359816,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1468] = true },
        category = "cooldown",
    },
    -- EVOKER: Stasis (Preservation)
    {
        id       = 370537,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1468] = true },
        category = "cooldown",
    },
});

-------------------------------------------------------------------------------
-- Talent CD Modifiers
-------------------------------------------------------------------------------

ST:RegisterTalentModifiers({
    -- Quick Witted (Mage): reduces Counterspell CD by 5s
    { spellID = 382297, affectsSpell = 2139, cdReduction = 5 },
    -- Honed Reflexes (Warrior): reduces Pummel CD by 10%
    { spellID = 391271, affectsSpell = 6552, cdReductionPct = 0.10 },
});

-------------------------------------------------------------------------------
-- Spell Aliases
-------------------------------------------------------------------------------

ST:RegisterSpellAliases({
    [119914]  = 89766,   -- Axe Toss (Command Demon) -> Axe Toss (pet)
});

-------------------------------------------------------------------------------
-- Interrupt-Specific Config
-------------------------------------------------------------------------------

ST.interruptConfig = {
    specsWithoutInterrupt = {
        [256]  = true,  -- Discipline Priest
        [257]  = true,  -- Holy Priest
        [105]  = true,  -- Restoration Druid
        [65]   = true,  -- Holy Paladin
        [270]  = true,  -- Mistweaver Monk
        [1468] = true,  -- Preservation Evoker
    },

    healerHasKick = {
        SHAMAN = true,
    },

    kickBonuses = {
        [378848] = { reduction = 3 },   -- Coldthirst (DK): Mind Freeze -3s
        [469886] = { reduction = 1 },   -- Authoritative Rebuke (Prot Paladin): Rebuke -1s
        [202918] = { reduction = 15 },  -- Light of the Sun (Balance Druid): Solar Beam -15s
    },
};
