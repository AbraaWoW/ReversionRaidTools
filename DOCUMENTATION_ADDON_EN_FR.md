# Reversion Raid Tools - Full Documentation (EN + FR)

## English

### 1) What this addon does
Reversion Raid Tools is a raid utility addon for World of Warcraft focused on:
- cooldown and interrupt tracking
- reminder display
- private aura tools
- raid setup utilities
- profile management and sharing

It is modular: each subsystem has its own files and UI tab.

### 2) Core architecture

Main entry flow:
1. `ReversionRaidTools.toc` loads libraries and addon files in order
2. `EventHandler.lua` initializes database defaults and runtime systems
3. `RRTUI.lua` builds the main options window and tab content
4. Runtime modules handle tracking, rendering, reminders, and utilities

Important folders:
- `UI/` options and interface builders
- `Display/` SpellTracker visual rendering (bar/icon)
- `Trackers/` spell category logic (cooldowns, defensives, interrupts)
- `Tools/` setup manager utilities (BattleRez, CombatTimer, MarksBar, RaidCheck)
- `BuffReminders/` full integrated buff reminder subsystem
- `EncounterAlerts/` boss encounter custom alerts

### 3) Main gameplay modules

#### SpellTracker
Core files:
- `Core.lua`
- `SpellData.lua`
- `Engine.lua`
- `Display.lua`
- `Display/Bar.lua`
- `Display/Icon.lua`
- `Profiles.lua`
- `Options.lua`

Responsibilities:
- detect and track player/group spells
- update spell states (ready, active, cooldown)
- render custom frames in bar or icon layout
- provide frame profiles/import/export

#### Reminders
Core files:
- `Reminders.lua`
- `UI/Reminders.lua`
- `UI/Options/Reminders.lua`

Responsibilities:
- display raid/personal/text reminders
- support font/size/layout tuning
- integrate sound/TTS and timing behavior

#### Private Auras
Core files:
- `PrivateAura.lua`
- `UI/PrivateAuras.lua`
- `UI/Options/PrivateAuras.lua`

Responsibilities:
- configure aura displays for raid/tank/general usage
- positioning and growth modes
- optional sound handling

#### Setup Manager tools
Core files:
- `SetupManager.lua`
- `UI/Options/SetupManager.lua`
- `UI/SetupManager/*.lua`
- `Tools/*.lua`

Responsibilities:
- build utility windows and quick raid tools
- module-specific settings and visuals

#### BuffReminders subsystem
Core files:
- `BuffReminders/Core.lua`
- `BuffReminders/Display/*.lua`
- `BuffReminders/UI/*.lua`
- `UI/BuffReminders/*.lua`

Responsibilities:
- buff checks and display widgets
- import/export
- secure buttons and state updates

### 4) UI and options

Main command:
- `/rrt` opens/closes options

Tabs are built in `RRTUI.lua` and options tables are provided by:
- `UI/Options/*.lua`

Shared UI helpers and templates:
- `UI/Core.lua`

### 5) SavedVariables and config

Saved variables in TOC:
- `RRTDB`
- `ReversionRaidToolsDB`
- `AbraaRaidToolsDB`

Database defaults are initialized in `EventHandler.lua`.

### 6) Profiles

Relevant files:
- `Profiles.lua`
- `UI/Options/Profiles.lua`

Profiles allow:
- save/load/overwrite/delete
- import/export
- default reset workflows

### 7) Performance and optimization status

Recent runtime optimizations:
- removed expensive continuous UI font OnUpdate loop
- switched to event-driven global font apply
- reduced SpellTracker tick refresh overhead
- coalesced repeated UI refresh requests via `RequestRefreshDisplay()`

Lightweight profiling commands:
- `/rrt perf on`
- `/rrt perf off`
- `/rrt perf reset`
- `/rrt perf`

Measured metrics include:
- `OnTick`
- `RefreshDisplay`
- `RecordSpellCast`

### 8) Troubleshooting

If UI errors appear:
1. run `/reload`
2. test with `/rrt perf off`
3. collect stack trace + `/rrt perf` output
4. verify addon version in `ReversionRaidTools.toc`

### 9) Versioning

Addon version is defined in:
- `ReversionRaidTools.toc`

Current version line:
- `## Version: 1.0`

---

## Francais

### 1) Role de l addon
Reversion Raid Tools est un addon utilitaire raid pour World of Warcraft centre sur:
- le suivi des cooldowns et interrupts
- les reminders (rappels)
- les outils de private aura
- des outils de setup raid
- la gestion/partage de profils

L addon est modulaire: chaque systeme a ses fichiers et son onglet UI.

### 2) Architecture principale

Flux d initialisation:
1. `ReversionRaidTools.toc` charge les libs et les fichiers
2. `EventHandler.lua` initialise la base de donnees et les systemes runtime
3. `RRTUI.lua` construit la fenetre options et les onglets
4. Les modules runtime gerent le tracking, l affichage, les reminders et outils

Dossiers importants:
- `UI/` interface et options
- `Display/` rendu visuel SpellTracker (bar/icon)
- `Trackers/` logique categories de sorts
- `Tools/` utilitaires setup manager
- `BuffReminders/` sous-systeme buff reminders
- `EncounterAlerts/` alertes de boss

### 3) Modules gameplay principaux

#### SpellTracker
Fichiers:
- `Core.lua`
- `SpellData.lua`
- `Engine.lua`
- `Display.lua`
- `Display/Bar.lua`
- `Display/Icon.lua`
- `Profiles.lua`
- `Options.lua`

Fonctions:
- detection/suivi des sorts joueur + groupe
- mise a jour des etats (ready, active, cooldown)
- rendu des fenetres custom (bar/icon)
- profils + import/export

#### Reminders
Fichiers:
- `Reminders.lua`
- `UI/Reminders.lua`
- `UI/Options/Reminders.lua`

Fonctions:
- affichage reminders raid/personnel/texte
- reglage police/taille/layout
- integration sons/TTS et timing

#### Private Auras
Fichiers:
- `PrivateAura.lua`
- `UI/PrivateAuras.lua`
- `UI/Options/PrivateAuras.lua`

Fonctions:
- config des affichages aura (raid/tank/general)
- positionnement et directions de croissance
- gestion son optionnelle

#### Outils Setup Manager
Fichiers:
- `SetupManager.lua`
- `UI/Options/SetupManager.lua`
- `UI/SetupManager/*.lua`
- `Tools/*.lua`

Fonctions:
- fenetres utilitaires et outils rapides de raid
- reglages visuels et fonctionnels par module

#### BuffReminders
Fichiers:
- `BuffReminders/Core.lua`
- `BuffReminders/Display/*.lua`
- `BuffReminders/UI/*.lua`
- `UI/BuffReminders/*.lua`

Fonctions:
- verification buffs et affichage
- import/export
- secure buttons + updates d etat

### 4) UI et commandes

Commande principale:
- `/rrt` ouvre/ferme les options

Les onglets sont montes dans `RRTUI.lua`.
Les tables d options sont dans:
- `UI/Options/*.lua`

Helpers/templates UI partages:
- `UI/Core.lua`

### 5) Base de donnees

SavedVariables TOC:
- `RRTDB`
- `ReversionRaidToolsDB`
- `AbraaRaidToolsDB`

Les defaults sont initialises dans `EventHandler.lua`.

### 6) Profils

Fichiers:
- `Profiles.lua`
- `UI/Options/Profiles.lua`

Actions:
- save/load/overwrite/delete
- import/export
- reset default

### 7) Performance et optimisations

Optimisations recentes:
- suppression d une boucle `OnUpdate` couteuse pour la police globale
- passage vers une application de police orientee evenement
- reduction du cout du ticker SpellTracker
- regroupement des refresh UI via `RequestRefreshDisplay()`

Commandes de profiling leger:
- `/rrt perf on`
- `/rrt perf off`
- `/rrt perf reset`
- `/rrt perf`

Mesures:
- `OnTick`
- `RefreshDisplay`
- `RecordSpellCast`

### 8) Depannage

Si erreur UI:
1. faire `/reload`
2. tester avec `/rrt perf off`
3. recuperer stack trace + sortie `/rrt perf`
4. verifier la version dans `ReversionRaidTools.toc`

### 9) Version

Version addon definie dans:
- `ReversionRaidTools.toc`

Version actuelle:
- `## Version: 1.0`
