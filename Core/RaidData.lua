local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- RaidData — Single source of truth for all raid boss/spell data.
--
-- Structure:
--   RRT_NS.RaidData = {
--       {
--           extension = "Season Name",
--           instances = {
--               {
--                   instance   = "Instance Name",
--                   instanceID = 0,   -- EJ / GetInstanceInfo() zone ID (0 = unknown/TBD)
--                   bosses = {
--                       {
--                           id     = 1234,        -- EJ encounter ID (> 0)
--                           name   = "Boss Name",
--                           spells = {
--                               { spellID = 000000, name = "Spell Name" },
--                           },
--                       },
--                   },
--               },
--           },
--       },
--   }
--
-- Spell IDs are sourced from Timeline/BossData/ (primary) and supplemented
-- with encounter-specific spells from EncounterAlerts/.
-- To add a new raid tier: append a new block to RRT_NS.RaidData.
-- All modules (CreateNote, RaidFrame profiles, PA Filter) read from here.
-- ─────────────────────────────────────────────────────────────────────────────

RRT_NS.RaidData = {

    -- ── Midnight Season 1 ─────────────────────────────────────────────────
    {
        extension = "Midnight",
        instances = {

            -- ── The Voidspire ──────────────────────────────────────────────
            {
                instance   = "The Voidspire",
                instanceID = 0, -- TODO: fill in zone ID once known
                bosses = {

                    {id=3176, name="Imperator Averzian", spells={
                        -- Timeline primary
                        {spellID=1249251, name="Dark Upheaval"},
                        {spellID=1262776, name="Shadow's Advance"},
                        {spellID=1249266, name="Umbral Collapse"},
                        {spellID=1262036, name="Void Rupture"},
                        {spellID=1261249, name="Cosmic Eruption"},
                        {spellID=1258880, name="Void Fall"},
                        {spellID=1260712, name="Oblivion's Wrath"},
                        {spellID=1280015, name="Void Marked"},
                        -- Supplemental
                        {spellID=1280035, name="Cosmic Shell"},
                        {spellID=1253918, name="Imperator's Glory"},
                        {spellID=1255749, name="Gathering Darkness"},
                        {spellID=1255702, name="Pitch Bulwark"},
                    }},

                    {id=3177, name="Vorasius", spells={
                        -- Timeline primary
                        {spellID=1260052, name="Primordial Roar"},
                        {spellID=1241836, name="Smashing Frenzy"},
                        {spellID=1254199, name="Parasite Expulsion"},
                        {spellID=1254113, name="Fixate"},
                        {spellID=1256855, name="Void Breath"},
                        {spellID=1259186, name="Blisterburst"},
                        -- Supplemental
                        {spellID=1244012, name="Shadowclaw Slam"},
                        {spellID=1273067, name="Aftershock"},
                        {spellID=1272937, name="Primordial Power"},
                        {spellID=1244419, name="Overpowering Pulse"},
                    }},

                    {id=3179, name="Fallen-King Salhadaar", spells={
                        -- Timeline primary
                        {spellID=1243453, name="Desperate Measures"},
                        {spellID=1250686, name="Twisting Obscurity"},
                        {spellID=1254081, name="Fractured Projection"},
                        {spellID=1250991, name="Galactic Miasma"},
                        {spellID=1260823, name="Despotic Command"},
                        {spellID=1253032, name="Shattering Twilight"},
                        {spellID=1251213, name="Twilight Spikes"},
                        {spellID=1246175, name="Cosmic Unraveling"},
                        -- Supplemental
                        {spellID=1245960, name="Void Infusion"},
                        {spellID=1254088, name="Shadow Fracture"},
                        {spellID=1248709, name="Oppressive Darkness"},
                        {spellID=1271577, name="Destabilizing Strikes"},
                        {spellID=1247738, name="Void Convergence"},
                        {spellID=1275056, name="Nexus Shield"},
                    }},

                    {id=3178, name="Vaelgor & Ezzorak", spells={
                        -- Timeline primary
                        {spellID=1265131, name="Vaelwing"},
                        {spellID=1264467, name="Tail Lash"},
                        {spellID=1245645, name="Rakfang"},
                        {spellID=1265152, name="Impale"},
                        {spellID=1262623, name="Nullbeam"},
                        {spellID=1244672, name="Nullzone"},
                        {spellID=1245391, name="Gloom"},
                        {spellID=1245420, name="Gloomfield"},
                        {spellID=1258744, name="Midnight Manifestation"},
                        {spellID=1244221, name="Dread Breath"},
                        {spellID=1244917, name="Void Howl"},
                        {spellID=1249748, name="Midnight Flames"},
                        {spellID=1270497, name="Shadowmark"},
                        -- Supplemental
                        {spellID=1248847, name="Radiant Barrier"},
                        {spellID=1245554, name="Gloomtouched"},
                        {spellID=1244413, name="Nullsnap"},
                        {spellID=1252157, name="Nullzone Implosion"},
                    }},

                    {id=3180, name="Lightblinded Vanguard", spells={
                        -- Timeline primary (War Chaplain Senn abilities)
                        {spellID=1246497, name="Avenger's Shield"},
                        {spellID=1251857, name="Judgment"},
                        {spellID=1251859, name="Shield of the Righteous"},
                        {spellID=1251812, name="Final Verdict"},
                        {spellID=1246765, name="Divine Storm"},
                        {spellID=1258659, name="Light Infused"},
                        {spellID=1258514, name="Blinding Light"},
                        {spellID=1248644, name="Divine Toll"},
                        {spellID=1246162, name="Aura of Devotion"},
                        {spellID=1248449, name="Aura of Wrath"},
                        {spellID=1248451, name="Aura of Peace"},
                        {spellID=1246749, name="Sacred Toll"},
                        {spellID=1255738, name="Searing Radiance"},
                        {spellID=1248710, name="Tyr's Wrath"},
                        {spellID=1250839, name="Execution Sentence"},
                        -- Supplemental
                        {spellID=1248674, name="Sacred Shield"},
                    }},

                    {id=3181, name="Crown of the Cosmos", spells={
                        -- Alleria Windrunner abilities (no Timeline file yet)
                        {spellID=1233819, name="Void Expulsion"},
                        {spellID=1233602, name="Silverstrike Arrow"},
                        {spellID=1237837, name="Call of the Void"},
                        {spellID=1237614, name="Ranger Captain's Mark"},
                        {spellID=1241520, name="Corrupting Essence"},
                        {spellID=1239080, name="Aspect of the End"},
                        {spellID=1233865, name="Null Corona"},
                        {spellID=1233778, name="Echoing Darkness"},
                        {spellID=1237251, name="Empowering Darkness"},
                        {spellID=1239089, name="Gravity Collapse"},
                        {spellID=1232470, name="Grasp of Emptiness"},
                    }},

                },
            },

            -- ── The Dreamrift ──────────────────────────────────────────────
            {
                instance   = "The Dreamrift",
                instanceID = 0, -- TODO: fill in zone ID once known
                bosses = {

                    {id=3306, name="Chimaerus the Undreamt God", spells={
                        -- Timeline primary
                        {spellID=1258610, name="Rift Emergence"},
                        {spellID=1250953, name="Rift Sickness"},
                        {spellID=1262289, name="Alndust Upheaval"},
                        {spellID=1246621, name="Caustic Phlegm"},
                        {spellID=1262020, name="Colossal Strikes"},
                        {spellID=1272726, name="Rending Tear"},
                        {spellID=1245396, name="Consume"},
                        {spellID=1245452, name="Corrupted Devastation"},
                        {spellID=1245404, name="Ravenous Dive"},
                        -- Supplemental
                        {spellID=1245727, name="Alnshroud"},
                        {spellID=1252863, name="Insatiable"},
                    }},

                },
            },

            -- ── March on Quel'Danas ────────────────────────────────────────
            {
                instance   = "March on Quel'Danas",
                instanceID = 0, -- TODO: fill in zone ID once known
                bosses = {

                    {id=3182, name="Belo'ren, Child of Al'ar", spells={
                        -- Timeline primary
                        {spellID=1242515, name="Voidlight Convergence"},
                        {spellID=1244348, name="Holy Burn"},
                        {spellID=1242260, name="Infused Quills"},
                        {spellID=1241291, name="Light Dive"},
                        {spellID=1261217, name="Light Edict"},
                        {spellID=1261218, name="Void Edict"},
                        {spellID=1241640, name="Voidlight Edict"},
                        {spellID=1242792, name="Incubation of Flames"},
                        {spellID=1242981, name="Radiant Echoes"},
                        {spellID=1260826, name="Guardian's Edict"},
                        {spellID=1246709, name="Death Drop"},
                    }},

                    {id=3183, name="Midnight Falls", spells={
                        {spellID=1257087, name="Midnight Barrage"},
                        {spellID=1255612, name="Eclipse"},
                    }},

                },
            },

        },
    },

    -- ── Next Season — add new block here ──────────────────────────────────
    -- {
    --     extension  = "Next Season Name",
    --     instances  = {
    --         {
    --             instance   = "Instance Name",
    --             instanceID = 0,
    --             bosses     = { ... },
    --         },
    --     },
    -- },

}
