# Reversion Raid Tools

Raid utility addon for World of Warcraft.

Version: `1.0`

Full technical documentation (EN + FR): `DOCUMENTATION_ADDON_EN_FR.md`

## English

### Highlights
- Multi-frame cooldown and interrupt tracking (SpellTracker)
- Reminders (shared, personal, text)
- Private Aura tools
- Setup Manager utility modules
- Profile save/load/import/export
- Encounter alerts and Buff Reminders

### Installation
1. Download or clone this repository.
2. Place `ReversionRaidTools` in:
`World of Warcraft/_retail_/Interface/AddOns/`
3. Start the game (or `/reload`).

### Quick Start
1. Type `/rrt` to open options.
2. Go to Setup Manager / Frames.
3. Create a frame, select spells, choose display style.
4. Lock position and save your profile.

### Slash Commands
- `/rrt` toggle options
- `/rrt help` command list
- `/rrt perf on` enable lightweight SpellTracker profiling
- `/rrt perf off` disable profiling
- `/rrt perf reset` reset profiling stats
- `/rrt perf` show profiling report

### Main Modules
- `SpellTracker` cooldown and interrupt runtime + display
- `Reminders` reminder and note systems
- `PrivateAura` aura display tools
- `Setup Manager` utility windows (`Tools/`)
- `BuffReminders` integrated buff reminder subsystem
- `EncounterAlerts` boss-specific alerts

## Francais

### Points forts
- Suivi multi-fenetres des cooldowns et interrupts (SpellTracker)
- Reminders (partages, personnels, texte)
- Outils Private Aura
- Outils Setup Manager
- Profils avec sauvegarde/chargement/import/export
- Encounter alerts et Buff Reminders

### Installation
1. Telecharge ou clone ce repository.
2. Place `ReversionRaidTools` dans:
`World of Warcraft/_retail_/Interface/AddOns/`
3. Lance le jeu (ou `/reload`).

### Demarrage rapide
1. Tape `/rrt` pour ouvrir les options.
2. Va dans Setup Manager / Frames.
3. Cree une fenetre, choisis les sorts et le style d affichage.
4. Verrouille la position puis sauvegarde un profil.

### Commandes
- `/rrt` ouvrir/fermer les options
- `/rrt help` liste des commandes
- `/rrt perf on` activer le profiling leger SpellTracker
- `/rrt perf off` desactiver le profiling
- `/rrt perf reset` reset des stats profiling
- `/rrt perf` afficher le rapport

### Modules principaux
- `SpellTracker` runtime cooldown/interrupt + affichage
- `Reminders` systemes de reminders et notes
- `PrivateAura` outils d affichage d auras
- `Setup Manager` fenetres utilitaires (`Tools/`)
- `BuffReminders` sous-systeme buffs
- `EncounterAlerts` alertes de boss
