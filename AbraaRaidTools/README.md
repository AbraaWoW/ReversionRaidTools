# AbraaRaidTools

Fully customizable raid and party cooldown tracking addon for World of Warcraft.

Create multiple independent frames to monitor defensives, offensives and interrupts from your group in real time.

![Interface](https://img.shields.io/badge/Interface-12.0.0%20%2F%2012.0.1-blue)
![Expansion](https://img.shields.io/badge/Midnight-Season%201-orange)

---

## Installation

1. Download or clone this repository
2. Place the `AbraaRaidTools` folder into:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
3. Restart WoW or type `/reload`
4. Type `/art` to open the options panel

> The addon will display a warning on login if the game client version is newer than the supported interface version.

---

## Getting Started

### Quick Setup

1. `/art` to open the options panel
2. Click **+ New Frame** in the sidebar to create your first frame
3. Go to the **Spells** tab and select the spells you want to track
4. Use **Preview** to see how it looks with simulated players
5. Drag the frame to your desired position, then **Lock** it
6. Save your setup in the **Profiles** tab

### Slash Commands

| Command | Description |
|---|---|
| `/art` | Toggle the options panel |

---

## Features

### Custom Frames

- Up to **20 custom frames** per user
- Each frame tracks a different set of spells independently
- Frames auto-show when you join a group or raid and auto-hide when solo

### Dedicated Interrupts Frame

- Separate interrupt tracking with its own top-level **Interrupts** tab
- Independent from custom frames — configure it once, works everywhere
- Tracks all 16+ interrupt spells across every class

### Two Display Layouts

**Bar Layout**
- Spell icon + player name (class-colored) + cooldown progress bar + remaining time
- Configurable grow direction (up or down), width (120-400px), height (16-40px)

**Icon Layout**
- Compact spell icon grid with cooldown overlays
- Optional player names below icons
- Adjustable icon size (16-48px)

### Spell Categories

| Category | Count | Examples |
|---|---|---|
| **Interrupt** | 16+ | Pummel, Counterspell, Kick, Wind Shear |
| **Defensive** | 40+ | Shield Wall, Ironbark, Pain Suppression, Blessing of Protection |
| **Cooldown** | 100+ | Recklessness, Combustion, Avenging Wrath, Innervate |

All 13 classes are supported: Death Knight, Demon Hunter, Druid, Evoker, Hunter, Mage, Monk, Paladin, Priest, Rogue, Shaman, Warlock, Warrior.

### Preview Mode

Test your frame layouts without being in a group. Simulates players with random classes, specs and cooldown timers.

| Mode | Players |
|---|---|
| Group (5) | 5 simulated players |
| Raid (20) | 20 simulated players |
| Raid (40) | 40 simulated players |

### Profile System

Save, load and share your complete setup (all frames + interrupt config).

| Action | Description |
|---|---|
| **Save** | Saves current state under a name (auto-increments for quick multi-save) |
| **Load** | Restores a saved profile (blocked during combat for safety) |
| **Save (Overwrite)** | Updates an existing profile with current settings |
| **Rename** | Inline rename — Enter to confirm, Escape to cancel |
| **Delete** | Removes a saved profile |
| **Reset to Defaults** | Wipes everything — creates 1 empty frame, resets interrupts (double-click to confirm) |
| **Export** | Serializes a profile to a copyable text string |
| **Import** | Imports a profile from a pasted string — auto-generates a unique name |

**Export format:** `ARC1:{frames={...},interruptFrame={...}}`

Share profiles with friends by copying and pasting the export string.

---

## Configuration Reference

### General Settings (per frame)

| Option | Values | Description |
|---|---|---|
| Name | text | Display name of the frame |
| Enable | on/off | Enable or disable the frame |
| Lock Position | on/off | Lock the frame in place (hides title bar) |
| Layout | Bar / Icon | Display mode |
| Group Mode | Any / Party / Raid | When to show the frame |
| Sort Mode | Remaining / Base CD | How to order cooldown entries |
| Show Self | on/off | Include your own cooldowns |
| Self On Top | on/off | Always pin yourself at the top |
| Hide Out of Combat | on/off | Auto-hide when out of combat |

### Display Settings (per frame)

| Option | Range | Description |
|---|---|---|
| Scale | 70% – 180% | Overall frame scale |
| Opacity | 0% – 100% | Frame transparency |
| Spacing | 0 – 12 px | Gap between rows or columns |
| Font Outline | None / Outline / Thick | Font outline style |
| Grow Direction | Up / Down | Direction bars grow from the anchor |
| Bar Width | 120 – 400 px | Width of cooldown bars |
| Bar Height | 16 – 40 px | Height of cooldown bars |
| Icon Size | 16 – 48 px | Size of icons (icon layout) |
| Show Names | on/off | Show player names (icon layout) |

---

## User Interface

The options panel is a 1000x700 window with three top-level tabs:

### Frames Tab

```
┌─ Sidebar ──────────┐  ┌─ Main Content ─────────────────────┐
│ Frames              │  │                                     │
│ [+ New Frame]       │  │  ▎ Selected Frame Name              │
│                     │  │                                     │
│  ● Defensives       │  │  [Settings]  [Spells]  [Display]   │
│  ○ Raid CDs         │  │                                     │
│  ○ Healer CDs       │  │  Frame configuration based on       │
│                     │  │  the active sub-tab                  │
│ Preview Mode        │  │                                     │
│ [G5] [R20] [R40]   │  │                                     │
│ [Toggle Preview]    │  │                                     │
└─────────────────────┘  └─────────────────────────────────────┘
```

### Interrupts Tab

Full-width dedicated panel:
- Layout, grow direction, group mode dropdowns
- Enable / Lock / Hide Out of Combat toggles
- Scale slider and reset position button
- Class-organized interrupt spell selection in 2 columns

### Profiles Tab

```
┌─ Sidebar ──────────┐  ┌─ Main Content ─────────────────────┐
│ Profiles            │  │                                     │
│ [_______________]   │  │  ▎ Raid Setup  (active)             │
│ [+ Save New Profile]│  │    Saved 2h ago                     │
│                     │  │    Contains 3 frame(s)              │
│  ● Raid Setup *     │  │                                     │
│  ○ M+ Setup         │  │  [Load] [Save] [Rename] [Delete]   │
│  ○ PvP Setup        │  │                                     │
│                     │  │  ── Import / Export ──────────────  │
│                     │  │  ┌─────────────────────────────┐   │
│ [Reset to Defaults] │  │  │ (text area)                  │   │
│                     │  │  └─────────────────────────────┘   │
└─────────────────────┘  │  [Export]  [Import]                 │
                          └─────────────────────────────────────┘
```

---

## Technical Details

### Saved Variables

All data is stored in `AbraaRaidToolsDB`:

```lua
AbraaRaidToolsDB = {
    frames = {                       -- Custom frames (array)
        [1] = {
            name = "Defensives",
            spells = { [spellID] = true, ... },
            enabled = true,
            layout = "bar",
            locked = false,
            position = { point, relativePoint, x, y },
            barWidth = 220,
            barHeight = 28,
            barAlpha = 0.9,
            displayScale = 1.0,
            iconSize = 28,
            iconSpacing = 2,
            hideOutOfCombat = false,
            groupMode = "any",
            showNames = true,
            growUp = false,
            showSelf = true,
            sortMode = "remaining",
            selfOnTop = false,
            font = "Friz Quadrata TT",
            fontOutline = "OUTLINE",
        },
    },
    interruptFrame = { ... },        -- Dedicated interrupts frame
    profiles = {                     -- Saved profiles
        ["Raid Setup"] = {
            frames = { ... },
            interruptFrame = { ... },
            savedAt = 1739800000,    -- Unix timestamp
        },
    },
    activeProfile = "Raid Setup",    -- Currently active profile (or nil)
}
```

### Compatibility

- **World of Warcraft 12.0+** (Midnight) — handles Blizzard API secret values
- **LibSharedMedia-3.0** — optional, for custom fonts
- **Addon Channel "ARC"** — cross-player communication for shared interrupt data
- **Outdated version warning** — automatic detection on login if game client is newer than addon's declared interface

### Performance

- Pre-allocated frame pools (80 bar rows, 120 icons)
- Spell icon texture caching
- Greedy balanced column layout algorithm
- 0.1s update tick (no aggressive polling)
- Optimized deep copy for profile operations
- Talent and spec detection with retry logic

### File Structure

```
AbraaRaidTools/
├── AbraaRaidTools.toc        Addon manifest
├── Core.lua                      Initialization, database, defaults, version check
├── Engine.lua                    Event handling, group management, spell detection
├── Frames.lua                    Custom frame creation and deletion
├── Display.lua                   Display coordinator, preview mode, positions
├── Display/
│   ├── Bar.lua                   Bar layout renderer
│   └── Icon.lua                  Icon layout renderer
├── Options.lua                   Full options panel UI
├── Profiles.lua                  Profile save/load/rename/delete/import/export
├── SpellData.lua                 Spell database and helper functions
├── Trackers/
│   ├── Cooldowns.lua             Major offensive cooldowns (100+)
│   ├── Defensives.lua            Defensive cooldowns (40+)
│   └── Interrupts.lua            Interrupt spells (16+)
└── Utils/
    └── ClassColors.lua           Class color utilities
```

---

## Visual Theme

Dark theme with blue accents, designed for minimal visual distraction during gameplay.

| Element | Color |
|---|---|
| Background | `#141414` |
| Sections | `#1F1F1F` |
| Accent | `#4DB8FF` |
| Labels | `#D9D9D9` |
| Muted text | `#8C8C8C` |
| Buttons | `#2E2E2E` → `#404040` (hover) |
| Danger | `#CC3333` |
| Borders | `#333333` |

---

## License

This addon is provided as-is for personal use.

## Author

**Abraa**
