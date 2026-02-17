# Abraa Raid Cooldown

**Version:** 1.0.0
**Author:** Abraa
**Interface:** 12.0.0 / 12.0.1 (The War Within)
**SavedVariables:** AbraaRaidCooldownDB
**Optional Dependency:** LibSharedMedia-3.0

---

## Description

Fully customizable raid cooldown tracking addon. Create multiple independent frames to monitor defensives, offensives and interrupts from your group in real time.

---

## Slash Commands

| Command | Description |
|---|---|
| `/arc` | Toggle the options panel |

---

## File Structure

```
AbraaRaidCooldown/
├── AbraaRaidCooldown.toc     -- Addon manifest
├── Core.lua                   -- Initialization, database, defaults
├── Engine.lua                 -- Event handling, group detection
├── Frames.lua                 -- Custom frame creation/deletion
├── Display.lua                -- Display coordinator, preview system
├── Display/
│   ├── Bar.lua                -- Horizontal bar layout renderer
│   └── Icon.lua               -- Icon grid layout renderer
├── Options.lua                -- Options panel (full UI)
├── Profiles.lua               -- Profile system (save/load/import/export)
├── SpellData.lua              -- Spell database + helpers
├── Trackers/
│   ├── Cooldowns.lua          -- Major offensive spells (100+)
│   ├── Defensives.lua         -- Defensive spells (40+)
│   └── Interrupts.lua         -- Interrupt spells (16+)
└── Utils/
    └── ClassColors.lua        -- Class color utilities
```

---

## Core Features

### Frame System

- Up to **20 custom frames** per user
- Each frame tracks different spells independently
- **Dedicated Interrupts frame** with its own top-level tab
- Frames auto-show when in a group/raid

### Two Display Modes

**Bar Layout**
- Spell icon + player name (class-colored)
- Cooldown progress bar
- Remaining time displayed on the right
- Configurable grow direction (up or down)
- Adjustable width and height (120-400px / 16-40px)

**Icon Layout**
- Spell icon grid with cooldown overlays
- Optional player names below each column
- Adjustable icon size (16-48px)

### Supported Spell Categories

| Category | Description | Examples |
|---|---|---|
| **Interrupt** | Interrupt abilities | Pummel, Counterspell, Kick, Wind Shear |
| **Defensive** | Defensive cooldowns | Shield Wall, Ironbark, Pain Suppression |
| **Cooldown** | Major offensive CDs | Recklessness, Combustion, Avenging Wrath |

### Preview Mode

Simulates a group or raid with dummy players and random cooldowns to test frame layouts without being in a group.

| Mode | Simulated Players |
|---|---|
| Group (5) | 5 players |
| Raid (20) | 20 players |
| Raid (40) | 40 players |

---

## Per-Frame Configuration

### General Settings

| Option | Values | Description |
|---|---|---|
| Name | text | Display name of the frame |
| Enable | on/off | Enable or disable the frame |
| Lock Position | on/off | Lock the frame (hides title bar) |
| Layout | Bar / Icon | Display mode |
| Group Mode | Any / Party / Raid | Group filter |
| Sort Mode | Remaining / Base CD | Bar sorting order |
| Show Self | on/off | Show your own cooldowns |
| Self On Top | on/off | Pin yourself at the top |
| Hide Out of Combat | on/off | Hide when out of combat |

### Display Settings

| Option | Range | Description |
|---|---|---|
| Scale | 70% - 180% | Overall frame scale |
| Opacity | 0% - 100% | Frame transparency |
| Spacing | 0 - 12 px | Gap between rows/columns |
| Font Outline | None / Outline / Thick | Font outline style |
| Grow Direction | Up / Down | Bar growth direction |
| Bar Width | 120 - 400 px | Width of bars |
| Bar Height | 16 - 40 px | Height of bars |
| Icon Size | 16 - 48 px | Size of icons |
| Show Names | on/off | Player names (icon mode) |

---

## User Interface

### Options Panel (1000x700)

```
┌─ Abraa Raid Cooldown ─────────────────────────── [X] ┐
│                                                        │
│  [Frames]  [Interrupts]  [Profiles]  ← Top-level tabs │
│                                                        │
│  ┌─ Sidebar ─┐  ┌─ Main Content ──────────────────┐  │
│  │ Frames    │  │                                   │  │
│  │ + New     │  │  Selected frame                   │  │
│  │ ○ Frame 1 │  │  [Settings] [Spells] [Display]    │  │
│  │ ○ Frame 2 │  │                                   │  │
│  │           │  │  Dynamic content based             │  │
│  │ Preview   │  │  on the active tab                 │  │
│  │ [G5][R20] │  │                                   │  │
│  │ [R40]     │  │                                   │  │
│  │ [Toggle]  │  │                                   │  │
│  └───────────┘  └───────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

### Spells Tab

Spell selection organized in **2 columns** by class, with:
- Spell icon + checkbox
- Name + category tag in brackets
- Quick buttons: Select All / Deselect All / All Def / All Cooldown

### Interrupts Tab (top-level)

Full-width dedicated panel for the interrupt frame:
- Layout, grow direction, group mode settings
- Enable / Lock / Hide Out of Combat toggles
- Scale slider, reset position
- Class-organized spell selection in 2 columns

### Profiles Tab

```
┌─ Active profile: "My Profile" ───────────────────────┐
│                                                        │
│  [Name: ___________]  [Save]  [Reset to Defaults]     │
│                                                        │
│  ── Saved Profiles ──────────────────────────────────  │
│  │ "Raid Setup"    2h ago    [Load] [Rename] [Delete] ││
│  │ "M+ Setup"      1d ago    [Load] [Rename] [Delete] ││
│                                                        │
│  ── Import / Export ─────────────────────────────────  │
│  [Profile v]  [Export]                                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │ (Multi-line text area for copy/paste)             │  │
│  └──────────────────────────────────────────────────┘  │
│  [Import]                                              │
└────────────────────────────────────────────────────────┘
```

---

## Profile System

| Action | Description |
|---|---|
| **Save** | Saves the current state (frames + interrupts) under a name |
| **Load** | Loads a saved profile (blocked during combat) |
| **Rename** | Renames an existing profile (inline edit, Enter confirms, Escape cancels) |
| **Delete** | Deletes a profile |
| **Reset to Defaults** | Wipes everything (1 empty frame, interrupts reset) — double-click required |
| **Export** | Serializes a profile to a shareable `ARC1:{...}` string |
| **Import** | Imports a profile from a pasted string — auto-generates a unique name |

### Export Format

```
ARC1:{frames={...},interruptFrame={...}}
```

- Custom recursive serialization (no external dependencies)
- Max depth protection (20 levels)
- Import validation: `frames` table required, max 20 frames

---

## Database Structure

```lua
AbraaRaidCooldownDB = {
    frames = {                    -- Custom frames (array)
        [1] = {
            name = "Defensives",
            spells = { [spellID] = true, ... },
            enabled = true,
            layout = "bar",
            locked = false,
            position = { point, relativePoint, x, y },
            barWidth = 220,
            barHeight = 28,
            -- ... other settings
        },
    },
    interruptFrame = { ... },     -- Dedicated interrupts frame
    profiles = {                  -- Saved profiles
        ["Raid Setup"] = {
            frames = { ... },
            interruptFrame = { ... },
            savedAt = 1739800000,
        },
    },
    activeProfile = "Raid Setup", -- Active profile (or nil)
}
```

---

## Technical Details

### Supported Classes (13)

Death Knight, Demon Hunter, Druid, Evoker, Hunter, Mage, Monk, Paladin, Priest, Rogue, Shaman, Warlock, Warrior

### Compatibility

- **Patch 12.0+** — Handles Blizzard API "secret values"
- **LibSharedMedia** — Optional support for custom fonts
- **Addon Channel "ARC"** — Cross-addon communication to share interrupt data between players running the addon

### Performance

- Pre-created frame pools (80 bars, 120 icons max)
- Texture caching for spell icons
- Balanced column layout algorithm (greedy balance)
- State updates via 0.1s tick (no aggressive polling)
- Optimized deep copy for profiles

---

## Visual Theme

| Element | Color |
|---|---|
| Main background | `#141414` (very dark grey) |
| Sections | `#1F1F1F` |
| Accent | `#4DB8FF` (light blue) |
| Labels | `#D9D9D9` |
| Muted text | `#8C8C8C` |
| Buttons | `#2E2E2E` → `#404040` (hover) |
| Danger | `#CC3333` |
| Borders | `#333333` |
