local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Major Cooldown Database (Midnight / 12.0)
--
-- Tracks major DPS and healer cooldowns across all classes for M+ groups.
-- Each entry follows the same spell record format as interrupts/defensives.
-------------------------------------------------------------------------------

local spells = {

    ---------------------------------------------------------------------------
    -- WARRIOR
    ---------------------------------------------------------------------------

    -- Recklessness (Fury)
    {
        id       = 1719,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [72] = true },
        category = "cooldown",
    },
    -- Avatar
    {
        id       = 107574,
        cd       = 90,
        duration = 20,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "cooldown",
    },
    -- Thunderous Roar
    {
        id       = 384318,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "cooldown",
    },
    -- Ravager (Arms / Protection)
    {
        id       = 228920,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "WARRIOR",
        specs    = { [71] = true, [73] = true },
        category = "cooldown",
    },
    -- Champion's Spear
    {
        id       = 376079,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "cooldown",
    },

    ---------------------------------------------------------------------------
    -- PALADIN
    ---------------------------------------------------------------------------

    -- Avenging Wrath (Ret 60s, Holy/Prot 120s)
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
    -- Aura Mastery (Holy)
    {
        id       = 31821,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "PALADIN",
        specs    = { [65] = true },
        category = "healer",
    },
    -- Lay on Hands
    {
        id       = 633,
        cd       = 420,
        duration = nil,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "cooldown",
    },
    -- Blessing of Sacrifice
    {
        id       = 6940,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "PALADIN",
        specs    = nil,
        category = "cooldown",
    },

    ---------------------------------------------------------------------------
    -- DEATHKNIGHT
    ---------------------------------------------------------------------------

    -- Pillar of Frost (Frost — 45s in Midnight)
    {
        id       = 51271,
        cd       = 45,
        duration = 12,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [251] = true },
        category = "cooldown",
    },
    -- Dark Transformation (Unholy)
    {
        id       = 63560,
        cd       = 45,
        duration = 15,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [252] = true },
        category = "cooldown",
    },
    -- Army of the Dead (Unholy)
    {
        id       = 42650,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [252] = true },
        category = "cooldown",
    },
    -- Empower Rune Weapon (Frost)
    {
        id       = 47568,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [251] = true },
        category = "cooldown",
    },
    -- Abomination Limb
    {
        id       = 383269,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "cooldown",
    },
    -- Gorefiend's Grasp (Blood)
    {
        id       = 108199,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = { [250] = true },
        category = "cooldown",
    },

    ---------------------------------------------------------------------------
    -- ROGUE
    ---------------------------------------------------------------------------

    -- Adrenaline Rush (Outlaw)
    {
        id       = 13750,
        cd       = 180,
        duration = 19,
        charges  = nil,
        class    = "ROGUE",
        specs    = { [260] = true },
        category = "cooldown",
    },
    -- Shadow Blades (Subtlety)
    {
        id       = 121471,
        cd       = 90,
        duration = 16,
        charges  = nil,
        class    = "ROGUE",
        specs    = { [261] = true },
        category = "cooldown",
    },
    -- Deathmark (Assassination)
    {
        id       = 360194,
        cd       = 120,
        duration = 16,
        charges  = nil,
        class    = "ROGUE",
        specs    = { [259] = true },
        category = "cooldown",
    },

    ---------------------------------------------------------------------------
    -- HUNTER
    ---------------------------------------------------------------------------

    -- Trueshot (Marksmanship)
    {
        id       = 288613,
        cd       = 120,
        duration = 15,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [254] = true },
        category = "cooldown",
    },
    -- Bestial Wrath (Beast Mastery — 30s in Midnight)
    {
        id       = 19574,
        cd       = 30,
        duration = 15,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [253] = true },
        category = "cooldown",
    },
    -- Takedown (Survival — replaces Coordinated Assault in Midnight)
    {
        id       = 1250646,
        cd       = 90,
        duration = 10,
        charges  = nil,
        class    = "HUNTER",
        specs    = { [255] = true },
        category = "cooldown",
    },

    ---------------------------------------------------------------------------
    -- MAGE
    ---------------------------------------------------------------------------

    -- Combustion (Fire — 60s/10s in Midnight)
    {
        id       = 190319,
        cd       = 60,
        duration = 10,
        charges  = nil,
        class    = "MAGE",
        specs    = { [63] = true },
        category = "cooldown",
    },
    -- Ray of Frost (Frost — replaces Icy Veins in Midnight)
    {
        id       = 205021,
        cd       = 60,
        duration = 4,
        charges  = nil,
        class    = "MAGE",
        specs    = { [64] = true },
        category = "cooldown",
    },
    -- Arcane Surge (Arcane)
    {
        id       = 365350,
        cd       = 90,
        duration = 15,
        charges  = nil,
        class    = "MAGE",
        specs    = { [62] = true },
        category = "cooldown",
    },

    ---------------------------------------------------------------------------
    -- WARLOCK
    ---------------------------------------------------------------------------

    -- Summon Infernal (Destruction — 120s in Midnight)
    {
        id       = 1122,
        cd       = 120,
        duration = 30,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [267] = true },
        category = "cooldown",
    },
    -- Summon Darkglare (Affliction)
    {
        id       = 205180,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [265] = true },
        category = "cooldown",
    },
    -- Summon Demonic Tyrant (Demonology)
    {
        id       = 265187,
        cd       = 60,
        duration = 15,
        charges  = nil,
        class    = "WARLOCK",
        specs    = { [266] = true },
        category = "cooldown",
    },

    ---------------------------------------------------------------------------
    -- DRUID
    ---------------------------------------------------------------------------

    -- Celestial Alignment (Balance)
    {
        id       = 194223,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DRUID",
        specs    = { [102] = true },
        category = "cooldown",
    },
    -- Incarnation: Chosen of Elune (Balance — replaces Celestial Alignment, choice node with Convoke)
    {
        id       = 102560,
        cd       = 180,
        duration = 20,
        charges  = nil,
        class    = "DRUID",
        specs    = { [102] = true },
        category = "cooldown",
    },
    -- Berserk (Feral)
    {
        id       = 106951,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DRUID",
        specs    = { [103] = true },
        category = "cooldown",
    },
    -- Incarnation: Avatar of Ashamane (Feral — replaces Berserk, choice node with Convoke)
    {
        id       = 102543,
        cd       = 180,
        duration = 20,
        charges  = nil,
        class    = "DRUID",
        specs    = { [103] = true },
        category = "cooldown",
    },
    -- Berserk (Guardian)
    {
        id       = 50334,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "DRUID",
        specs    = { [104] = true },
        category = "cooldown",
    },
    -- Incarnation: Guardian of Ursoc (Guardian — replaces Berserk, choice node with Convoke)
    {
        id       = 102558,
        cd       = 180,
        duration = 30,
        charges  = nil,
        class    = "DRUID",
        specs    = { [104] = true },
        category = "cooldown",
    },
    -- Ironbark (Restoration — external)
    {
        id       = 102342,
        cd       = 90,
        duration = 12,
        charges  = nil,
        class    = "DRUID",
        specs    = { [105] = true },
        category = "cooldown",
    },
    -- Tranquility (Restoration)
    {
        id       = 740,
        cd       = 120,
        duration = 6,
        charges  = nil,
        class    = "DRUID",
        specs    = { [105] = true },
        category = "healer",
    },
    -- Incarnation: Tree of Life (Restoration)
    {
        id       = 33891,
        cd       = 120,
        duration = 30,
        charges  = nil,
        class    = "DRUID",
        specs    = { [105] = true },
        category = "healer",
    },
    -- Convoke the Spirits (all specs — choice node with Incarnation)
    {
        id       = 391528,
        cd       = 60,
        duration = 4,
        charges  = nil,
        class    = "DRUID",
        specs    = nil,
        category = "cooldown",
    },


    ---------------------------------------------------------------------------
    -- MONK
    ---------------------------------------------------------------------------

    -- Touch of Death (all specs)
    {
        id       = 322109,
        cd       = 180,
        duration = nil,
        charges  = nil,
        class    = "MONK",
        specs    = nil,
        category = "cooldown",
    },
    -- Invoke Niuzao, the Black Ox (Brewmaster)
    {
        id       = 132578,
        cd       = 120,
        duration = 25,
        charges  = nil,
        class    = "MONK",
        specs    = { [268] = true },
        category = "cooldown",
    },
    -- Zenith (Windwalker — replaces Storm, Earth, and Fire in Midnight)
    {
        id       = 1249625,
        cd       = 90,
        duration = 15,
        charges  = 2,
        class    = "MONK",
        specs    = { [269] = true },
        category = "cooldown",
    },
    -- Invoke Xuen, the White Tiger (Windwalker — Conduit of the Celestials hero talent)
    {
        id       = 123904,
        cd       = 96,
        duration = 20,
        charges  = nil,
        class    = "MONK",
        specs    = { [269] = true },
        category = "cooldown",
    },
    -- Revival (Mistweaver)
    {
        id       = 115310,
        cd       = 180,
        duration = nil,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "healer",
    },
    -- Restoral (Mistweaver — choice node with Revival)
    {
        id       = 388615,
        cd       = 180,
        duration = nil,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "healer",
    },
    -- Invoke Yu'lon, the Jade Serpent (Mistweaver)
    {
        id       = 322118,
        cd       = 120,
        duration = 25,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "healer",
    },
    -- Invoke Chi-Ji, the Red Crane (Mistweaver — choice node with Yu'lon)
    {
        id       = 325197,
        cd       = 120,
        duration = 25,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "healer",
    },
    -- Life Cocoon (Mistweaver — external)
    {
        id       = 116849,
        cd       = 120,
        duration = 12,
        charges  = nil,
        class    = "MONK",
        specs    = { [270] = true },
        category = "healer",
    },

    ---------------------------------------------------------------------------
    -- DEMONHUNTER
    ---------------------------------------------------------------------------

    -- Metamorphosis (Havoc — 120s/20s in Midnight)
    {
        id       = 191427,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [577] = true },
        category = "cooldown",
    },
    -- Void Metamorphosis (Devourer — no fixed CD, triggered by 50 soul fragments)
    {
        id       = 1217605,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [1480] = true },
        category = "cooldown",
    },
    -- The Hunt (Havoc)
    {
        id       = 370965,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [577] = true },
        category = "cooldown",
    },
    -- The Hunt (Devourer)
    {
        id       = 1246167,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [1480] = true },
        category = "cooldown",
    },

    ---------------------------------------------------------------------------
    -- PRIEST
    ---------------------------------------------------------------------------

    -- Voidform (Shadow)
    {
        id       = 194249,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [258] = true },
        category = "cooldown",
    },
    -- Power Infusion (all specs — external buff)
    {
        id       = 10060,
        cd       = 120,
        duration = 15,
        charges  = nil,
        class    = "PRIEST",
        specs    = nil,
        category = "cooldown",
    },
    -- Divine Hymn (Holy)
    {
        id       = 64843,
        cd       = 180,
        duration = 5,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [257] = true },
        category = "healer",
    },
    -- Apotheosis (Holy)
    {
        id       = 200183,
        cd       = 120,
        duration = 20,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [257] = true },
        category = "healer",
    },
    -- Guardian Spirit (Holy — external)
    {
        id       = 47788,
        cd       = 180,
        duration = 10,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [257] = true },
        category = "cooldown",
    },
    -- Symbol of Hope (Holy — party CD recovery + mana)
    {
        id       = 64901,
        cd       = 180,
        duration = 4,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [257] = true },
        category = "cooldown",
    },
    -- Rapture (Discipline)
    {
        id       = 47536,
        cd       = 90,
        duration = 30,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [256] = true },
        category = "cooldown",
    },
    -- Pain Suppression (Discipline — external)
    {
        id       = 33206,
        cd       = 180,
        duration = 8,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [256] = true },
        category = "cooldown",
    },
    -- Power Word: Barrier (Discipline — choice node with Ultimate Penitence)
    {
        id       = 62618,
        cd       = 180,
        duration = 10,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [256] = true },
        category = "healer",
    },
    -- Ultimate Penitence (Discipline — choice node with PW:Barrier)
    {
        id       = 421453,
        cd       = 240,
        duration = 4.3,
        charges  = nil,
        class    = "PRIEST",
        specs    = { [256] = true },
        category = "healer",
    },

    ---------------------------------------------------------------------------
    -- SHAMAN
    ---------------------------------------------------------------------------

    -- Ascendance (Elemental)
    {
        id       = 114049,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [262] = true },
        category = "cooldown",
    },
    -- Doom Winds (Enhancement — choice node with Ascendance)
    {
        id       = 384352,
        cd       = 60,
        duration = 8,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [263] = true },
        category = "cooldown",
    },
    -- Ascendance (Enhancement — choice node with Doom Winds)
    {
        id       = 114051,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [263] = true },
        category = "cooldown",
    },
    -- Healing Tide Totem (Restoration — choice node with Ascendance)
    {
        id       = 108280,
        cd       = 180,
        duration = 10,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [264] = true },
        category = "healer",
    },
    -- Ascendance (Restoration — choice node with Healing Tide Totem)
    {
        id       = 114052,
        cd       = 180,
        duration = 15,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [264] = true },
        category = "healer",
    },
    -- Spirit Link Totem (Restoration)
    {
        id       = 98008,
        cd       = 180,
        duration = 6,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [264] = true },
        category = "healer",
    },

    ---------------------------------------------------------------------------
    -- EVOKER
    ---------------------------------------------------------------------------

    -- Dragonrage (Devastation)
    {
        id       = 375087,
        cd       = 120,
        duration = 18,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1467] = true },
        category = "cooldown",
    },

    -- Tip the Scales
    {
        id       = 370553,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "EVOKER",
        specs    = nil,
        category = "cooldown",
    },
    -- Breath of Eons (Augmentation)
    {
        id       = 403631,
        cd       = 120,
        duration = 10,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1473] = true },
        category = "cooldown",
    },
    -- Rewind (Preservation — 240s base, 120s with Temporal Artificer)
    {
        id       = 363534,
        cd       = 240,
        duration = 4,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1468] = true },
        category = "cooldown",
    },
    -- Dream Flight (Preservation — choice node with Stasis)
    {
        id       = 359816,
        cd       = 120,
        duration = nil,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1468] = true },
        category = "healer",
    },
    -- Stasis (Preservation — choice node with Dream Flight)
    {
        id       = 370537,
        cd       = 90,
        duration = nil,
        charges  = nil,
        class    = "EVOKER",
        specs    = { [1468] = true },
        category = "healer",
    },
    ---------------------------------------------------------------------------
    -- MOBILITY
    ---------------------------------------------------------------------------

    -- Heroic Leap (Warrior)
    {
        id       = 6544,
        cd       = 20,
        duration = nil,
        charges  = nil,
        class    = "WARRIOR",
        specs    = nil,
        category = "mobility",
    },
    -- Sprint (Rogue)
    {
        id       = 2983,
        cd       = 60,
        duration = 8,
        charges  = nil,
        class    = "ROGUE",
        specs    = nil,
        category = "mobility",
    },
    -- Blink (Mage — Frost/Fire)
    {
        id       = 1953,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "MAGE",
        specs    = { [63] = true, [64] = true },
        category = "mobility",
    },
    -- Shimmer (Mage — Arcane)
    {
        id       = 212653,
        cd       = 15,
        duration = nil,
        charges  = 2,
        class    = "MAGE",
        specs    = { [62] = true },
        category = "mobility",
    },
    -- Disengage (Hunter)
    {
        id       = 781,
        cd       = 20,
        duration = nil,
        charges  = nil,
        class    = "HUNTER",
        specs    = nil,
        category = "mobility",
    },
    -- Wild Charge (Druid)
    {
        id       = 102401,
        cd       = 15,
        duration = nil,
        charges  = nil,
        class    = "DRUID",
        specs    = nil,
        category = "mobility",
    },
    -- Stampeding Roar (Druid — all specs)
    {
        id       = 106898,
        cd       = 120,
        duration = 8,
        charges  = nil,
        class    = "DRUID",
        specs    = nil,
        category = "mobility",
    },
    -- Divine Steed (Paladin)
    {
        id       = 190784,
        cd       = 45,
        duration = 3,
        charges  = 2,
        class    = "PALADIN",
        specs    = nil,
        category = "mobility",
    },
    -- Fel Rush (Demon Hunter — Havoc)
    {
        id       = 195072,
        cd       = 9,
        duration = nil,
        charges  = 2,
        class    = "DEMONHUNTER",
        specs    = { [577] = true },
        category = "mobility",
    },
    -- Vengeful Retreat (Demon Hunter — Havoc)
    {
        id       = 198793,
        cd       = 25,
        duration = nil,
        charges  = nil,
        class    = "DEMONHUNTER",
        specs    = { [577] = true },
        category = "mobility",
    },
    -- Roll (Monk)
    {
        id       = 109132,
        cd       = 10,
        duration = nil,
        charges  = 2,
        class    = "MONK",
        specs    = nil,
        category = "mobility",
    },
    -- Death's Advance (Death Knight)
    {
        id       = 48265,
        cd       = 45,
        duration = 8,
        charges  = nil,
        class    = "DEATHKNIGHT",
        specs    = nil,
        category = "mobility",
    },
    -- Gust of Wind (Shaman — Elemental / Enhancement)
    {
        id       = 192063,
        cd       = 30,
        duration = nil,
        charges  = nil,
        class    = "SHAMAN",
        specs    = { [262] = true, [263] = true },
        category = "mobility",
    },
    -- Hover (Evoker)
    {
        id       = 358267,
        cd       = 35,
        duration = 6,
        charges  = 2,
        class    = "EVOKER",
        specs    = nil,
        category = "mobility",
    },
};

ST:RegisterSpells(spells);

-------------------------------------------------------------------------------
-- Category Registration
-------------------------------------------------------------------------------

ST:RegisterCategory("cooldowns", {
    label             = "Cooldowns",
    trackBuffDuration = true,
    defaultLayout     = "icon",
    defaultFilter     = "all",
});
