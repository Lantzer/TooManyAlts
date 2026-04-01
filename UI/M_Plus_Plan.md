# Mythic+ Tab Plan (UI_MythicPlus.lua)

## Visual Design

Each character gets its own card (bordered box). Cards are stacked vertically in a scroll frame.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Altname     [Dungeon img +12]  3/8                                           │
│ 2450        [D1:15] [D2:13] [D3:11] [D4:--] [D5:--] [D6:--] [D7:--] [D8:--]│
└──────────────────────────────────────────────────────────────────────────────┘
```

- **Top-left**: Class-colored character name; M+ rating number directly below (no label)
- **Top-center**: Current keystone box (dungeon artwork + "+N" level overlay)
- **Top-right**: Great Vault fraction (e.g. "3/8", no label)
- **Bottom row**: 8 season-best dungeon boxes (dungeon artwork + level overlay)

No clarifying labels anywhere — data speaks for itself.

---

## Dungeon Box Widget

Each dungeon/keystone slot is a small frame containing:
1. **bg** — Texture: dungeon background artwork (`C_ChallengeMode.GetMapInfo()` → `backgroundTexture`)
2. **overlay** — Semi-transparent black texture for text readability
3. **levelText** — FontString centered on the frame: `"+12"` or `"--"`

Hovering shows a `GameTooltip` with the dungeon name.

---

## Layout Constants

| Constant | Value | Notes |
|---|---|---|
| `CARD_WIDTH` | 550 | Fits inside ~560px content area |
| `CARD_HEIGHT` | 80 | Two visual rows per card |
| `CARD_PADDING` | 6 | Vertical gap between cards |
| `DUNGEON_W` | 48 | Season-best dungeon box width |
| `DUNGEON_H` | 36 | Season-best dungeon box height |
| `KEY_W` | 60 | Current keystone box (slightly wider) |
| `KEY_H` | 36 | Current keystone box height |
| `NUM_DUNGEONS` | 8 | Season dungeon count |

---

## Functions

### `CreateDungeonBox(parent, w, h)`
Reusable widget for any dungeon image slot.
Returns `{ frame, bg, overlay, levelText }`.

### `CreateCharCard(parent)`
Creates one character card frame.
Returns `{ frame, nameTxt, ratingTxt, gvTxt, keyBox, dungeonBoxes[1..8] }`.

### `UpdateCharCard(card, charKey, data)`
Fills a card with live data from `TooManyAltsDB.characters[charKey]`.
Falls back to `"--"` / no texture when `data.mythicplus` is nil.

### `PopulateCards(scrollChild, cards)`
Iterates `TooManyAltsDB.characters`, sorts by name, creates/updates cards,
and sets `scrollChild:SetHeight(...)` dynamically.

---

## Data Shape (future collection)

```lua
TooManyAltsDB.characters[charKey].mythicplus = {
    currentKey  = { level = 12, mapID = 1234, mapName = "Ara-Kara" },
    greatVault  = { completed = 3 },   -- displayed as "3/8"
    rating      = 2450,
    seasonBests = {
        [mapID] = { level = 15, timed = true },
        ...
    },
}
```

### WoW APIs for future data collection
| Data | API |
|---|---|
| Current key | `C_KeystoneInfo.GetOwnedKeystone()` |
| Season dungeon IDs | `C_ChallengeMode.GetMapTable()` |
| Season best per dungeon | `C_MythicPlus.GetSeasonBestForMap(challengeModeID)` |
| Overall rating | `GetPlayerMythicPlusRatingSummary("player")` |
| Great Vault progress | `C_WeeklyRewards.GetActivities()` filtered by M+ type |

---

## Files

| File | Action |
|---|---|
| `UI/M_Plus_Plan.md` | This document |
| `UI/UI_MythicPlus.lua` | Full implementation |
| `TooManyAlts.toc` | Add `UI/UI_MythicPlus.lua` after `UI/UI_Characters.lua` |
