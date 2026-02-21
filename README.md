# Reversion Raid Tools

English and French quick guide for the addon.  
Full documentation: `DOCUMENTATION_ADDON_EN_FR.md`

## EN - Overview
Reversion Raid Tools is a modular World of Warcraft raid utility addon with:
- cooldown and interrupt tracking (SpellTracker)
- reminders and text displays
- private aura tools
- setup manager utilities
- profiles with import/export
- encounter alerts and buff reminders

Main command:
- `/rrt` open/close options

Performance profiling (SpellTracker):
- `/rrt perf on`
- `/rrt perf off`
- `/rrt perf reset`
- `/rrt perf`

Current addon version:
- `1.0` (from `ReversionRaidTools.toc`)

## FR - Resume
Reversion Raid Tools est un addon utilitaire raid modulaire avec:
- suivi cooldowns et interrupts (SpellTracker)
- reminders et affichage texte
- outils private aura
- outils setup manager
- profils avec import/export
- encounter alerts et buff reminders

Commande principale:
- `/rrt` ouvrir/fermer les options

Profiling performance (SpellTracker):
- `/rrt perf on`
- `/rrt perf off`
- `/rrt perf reset`
- `/rrt perf`

Version addon actuelle:
- `1.0` (definie dans `ReversionRaidTools.toc`)

## Project Structure
- `UI/` interface and options modules
- `Display/` SpellTracker rendering (bar/icon)
- `Trackers/` spell category logic
- `Tools/` setup manager utility windows
- `BuffReminders/` integrated buff reminder subsystem
- `EncounterAlerts/` boss alert modules

## Notes
- This repository currently has many unrelated deletions/changes in git status.
- Avoid broad git cleanup until you confirm what should be kept.
