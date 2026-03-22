# Barriers / Defensive Structures (3 Types)

## Design Status: COMPLETE

## Overview
Defensive structures that block enemy movement. Enemies attack barriers to break through (they do not pathfind around). Some special enemies ignore barriers (flying, Clugg, Gorger) or leap over them (Polus).

**Full data in:** `htl_barriers.json`

---

## Core Rules
- **Starting walls:** Base begins with Basic Structure walls 2-deep in a hexagon shape ~100 units across.
- **Build area:** Can build up to 10 units beyond the starting walls (total ~120x120).
- **Passive regen:** 1% max HP / 5 sec.
- **Repair:** Repair Drones and Repair Towers can heal barriers.
- **Sell-back:** 75%.
- **Visual connection:** Adjacent barriers connect visually (like Age of Empires walls).

---

## Barrier Types

| Name | Grid | HP | Armor | Cost (E/M) | Build | Tech | Effect |
|------|------|----|-------|-------------|-------|------|--------|
| Basic Structure | 1x1 | 400 | 3 | 1/5 | 0.2s | None | Standard wall, blocks movement |
| Reinforced Barrier | 1x2 | 800 | 6 | 2/20 | 0.5s | None | Heavy wall, double HP/armor |
| Energy Barrier | 1x2 | 500 | 4 | 20/10 | 3s | Tier 1 | Shield: absorbs projectiles, slows enemies 15%, 10 contact damage. Recharges 50 HP/s after 5s no damage. |

---

## Key Interactions
- **Blight Mite:** 5 per spawn group, each detonates for 80 damage. One group nearly destroys a Basic Wall (385/400 damage).
- **Brute:** Breaks through a Basic Wall in ~14 seconds.
- **Thrasher swarm (3):** Takes ~23 seconds to break a Basic Wall (armor reduces their 5 damage to 2 per hit).
- **Energy Barrier:** Does not block enemy movement. Absorbs ranged projectiles passing through. Best placed behind physical walls.
