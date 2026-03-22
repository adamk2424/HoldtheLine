# Player Towers (13 Types)

## Design Status: COMPLETE

## Overview
Towers are static structures placed on the build grid. 6 offensive, 2 resource, 4 support, 1 special (Central Tower). All towers can target both ground and flying enemies.

**Full data in:** `htl_tower_designs.json`

---

## Core Rules
- **Range scale:** Short=6, Medium=12, Long=20 grid units
- **Passive regen:** 1% max HP / 5 sec
- **Sell-back:** 75% of total invested cost
- **Repair:** Repair Drones and Repair Towers can heal towers
- **Placement:** Inside 120x120 buildable area only

---

## Offensive Towers

| Name | Grid | HP | Armor | Damage | Speed | Range | Type | Cost (E/M) | Tech | DPS |
|------|------|----|-------|--------|-------|-------|------|-------------|------|-----|
| Autocannon Turret | 1x1 | 400 | 2 | 12 | 4/s | 8 | Projectile | 25/20 | None | 48 |
| Missile Battery | 1x1 | 500 | 3 | 45 | 0.8/s | 12 | Missile | 45/35 | None | 36+splash |
| Rail Gun | 1x1 | 350 | 2 | 90 | 0.5/s | 18 | Projectile | 60/50 | Tier 1 | 45 |
| Plasma Mortar | 2x2 | 600 | 4 | 70 | 0.4/s | 16 | AoE Burst | 75/60 | Tier 2 | 28+splash |
| Tesla Coil | 1x1 | 300 | 2 | 25 | 1.5/s | 10 | Beam | 55/40 | Tier 1 | 37.5+chain |
| Inferno Tower | 1x1 | 500 | 3 | 8 | 5/s | 6 | Beam | 45/35 | None | 40-80 (ramp) |

### Branching Towers
- **Autocannon (Lv3):** Gatling Turret (speed) OR Heavy Autocannon (damage+splash)
- **Missile Battery (Lv3):** Cluster Rockets (splash) OR Siege Missile (range+damage)
- **Tesla Coil (Lv3):** Storm Spire (6 chains) OR Arc Cannon (single-target nuke)

---

## Resource Towers

| Name | Grid | HP | Range | Cost (E/M) | Tech | Effect |
|------|------|----|-------|-------------|------|--------|
| Leach Tower | 1x1 | 200 | 10 | 40/30 | Tier 1 | Harvests Materials from corpses (1 mat/10 HP) |
| Thermal Siphon | 1x1 | 200 | 12 | 45/35 | Tier 1 | Drains 0.5 Energy/sec per enemy in range |

---

## Support Towers

| Name | Grid | HP | Radius | Cost (E/M) | Tech | Effect |
|------|------|----|--------|-------------|------|--------|
| Repair Tower | 1x1 | 300 | 6 | 35/25 | None | 8 HP/sec heal to all in radius |
| War Beacon | 1x1 | 250 | 8 | 50/40 | Tier 1 | +15% damage to towers/units in radius |
| Targeting Array | 1x1 | 250 | 8 | 45/35 | Tier 1 | +20% range to towers in radius |
| Shield Pylon | 1x1 | 350 | 6 | 55/45 | Tier 2 | +3 armor to buildings in radius |

---

## Special: Central Tower (3x3)
- **HP:** 1500 (upgrades to 2000/2500/3000)
- **Armor:** 5 (upgrades to 7/10/15)
- **Tier 1:** 100E/100M + 1 boss kill. Doubles income (2x). Unlocks Tier 1 towers/units.
- **Tier 2:** 250E/250M + 10 boss kills. Doubles again (4x). Unlocks Tier 2.
- **Tier 3:** 500E/500M. Doubles again (8x). Final tier.
- **If destroyed, game over.**
