# Player Units (7 Types)

## Design Status: COMPLETE

## Overview
Mobile units built from production buildings. 3 utility drones (Drone Printer), 2 combat mechs (Mech Bay), 2 heavy vehicles (War Factory). All units auto-engage and auto-position by default.

**Full data in:** `htl_unit_designs.json`

---

## Core Rules
- **Population cap:** 100 units. Each unit has a pop cost (1-5).
- **Passive regen:** 1% max HP / 5 sec. Repair Drones and Repair Towers also heal.
- **Sell-back:** 75% refund.
- **Movement:** Fine sub-grid increments, not locked to the build grid.
- **Confinement:** All units stay inside the 120x120 buildable area.
- **Production queue:** Max 5 per building, or Continuous mode.

---

## Drone Printer Units (Flying Support)

| Name | HP | Armor | Speed | Pop | Cost (E/M) | Build | Tech | Role |
|------|----|-------|-------|-----|-------------|-------|------|------|
| Repair Drone | 40 | 0 | 3.5 | 1 | 15/10 | 6s | None | Heals 5 HP/sec beam |
| Shield Drone | 55 | 0 | 3.0 | 1 | 30/20 | 10s | Tier 1 | +4 armor to target building |
| Disruptor Drone | 70 | 1 | 2.5 | 2 | 50/35 | 14s | Tier 2 | -25% speed, -2 armor aura |

---

## Mech Bay Units (Frontline Combat)

| Name | HP | Armor | Damage | Speed | Atk/s | Range | Pop | Cost (E/M) | Build | Tech | Role |
|------|----|-------|--------|-------|-------|-------|-----|-------------|-------|------|------|
| Sentinel | 450 | 3 | 28 | 1.4 | 1.5 | 8 | 2 | 50/40 | 12s | None | Ranged infantry |
| Juggernaut | 800 | 6 | 65 | 0.9 | 0.8 | 2 | 4 | 90/75 | 22s | Tier 1 | Tank, Fortify (+3 armor) |

---

## War Factory Units (Heavy Specialists)

| Name | HP | Armor | Damage | Speed | Atk/s | Range | Pop | Cost (E/M) | Build | Tech | Role |
|------|----|-------|--------|-------|-------|-------|-----|-------------|-------|------|------|
| Striker | 350 | 2 | 20 | 2.2 | 3 | 7 | 3 | 60/50 | 15s | None | Fast response, Overdrive |
| Siege Walker | 600 | 4 | 120 | 0.7 | 0.3 | 18 | 5 | 130/110 | 28s | Tier 2 | Artillery, must Deploy |

---

## Unit Tier Availability
- **No tech required (Tier 0):** Repair Drone, Sentinel, Striker
- **Tier 1 Central Tower:** Shield Drone, Juggernaut
- **Tier 2 Central Tower:** Disruptor Drone, Siege Walker
