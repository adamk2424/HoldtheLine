# Enemy Attackers (12 Types)

## Design Status: COMPLETE

## Overview
Enemies spawn continuously from the edges of the 300x300 map and advance toward the player's 120x120 base. 12 distinct enemy types with unique AI behaviors, visual designs, and roles.

**Full data in:** `htl_enemies.json`

---

## Core Rules
- **Armor formula:** Flat damage reduction per hit. Minimum 1 damage per hit.
- **Stat scaling:** +1% HP/damage per minute. Armor: Small +1/10min, Large +1/5min, Huge +2/5min.
- **Spawning:** Continuous from all 4 edges. Surges every ~30 sec. First boss at ~90 sec.
- **Corpses persist** 10 seconds for Leach Tower harvesting.

---

## Enemy Roster

| # | Name | Role | Size | HP | Armor | Damage | Speed | Attack | Appears | Special |
|---|------|------|------|----|-------|--------|-------|--------|---------|---------|
| 0 | Thrasher | Swarm | Small | 60 | 0 | 5 | 2.0 | Melee 3/s | 0s | Spawns in 3s |
| 1 | Brute | Bruiser | Large | 210 | 1 | 32 | 1.0 | Melee 1/s | 0s | Wall-breaker |
| 2 | Clugg | Tank | Huge | 1200 | 4 | 0 | 0.65 | None | 60s | Threat Aura taunt, ignores barriers |
| 3 | Scrit | Flying | Small | 100 | 0 | 12 | 3.0 | Proj 1/s | 80s | Erratic targeting, flies |
| 4 | Slinker | Ranged | Large | 300 | 1 | 22 | 1.5 | Proj 1/s | 120s | Stays at max range |
| 5 | Polus | Ranged | Small | 85 | 0 | 8 | 2.5 | Proj 2/s | 100s | Leap over barriers |
| 6 | Terror Bringer | Boss | Huge | 2400 | 5 | 100 | 2.0 | Melee 2/s | 90s | Death Blast 500dmg/3r |
| 7 | Blight Mite | Swarm | Small | 35 | 0 | 0 | 2.8 | Suicide | 90s | Spawns in 5s, 80dmg detonate |
| 8 | Gorger | Bruiser | Large | 280 | 2 | 45 | 1.5 | Melee 0.8/s | 150s | Hunts units, Frenzy <30% HP |
| 9 | Gloom Wing | Flying | Large | 250 | 1 | 35 | 1.8 | AoE 0.5/s | 200s | Carpet bombs tower clusters |
| 10 | Bile Spitter | Ranged | Large | 220 | 1 | 40 | 0.8 | Proj 0.4/s | 240s | Range 18, corrodes armor |
| 11 | Howler | Swarm | Small | 45 | 0 | 3 | 1.8 | Melee 1/s | 130s | Spawns in 2s, +20%dmg aura |

---

## Size Distribution
- **Small (5):** Thrasher, Scrit, Polus, Blight Mite, Howler
- **Large (5):** Brute, Slinker, Gorger, Gloom Wing, Bile Spitter
- **Huge (2):** Clugg, Terror Bringer

## Barrier Interaction
- **Attacks barriers:** Thrasher, Brute, Slinker, Blight Mite, Howler
- **Ignores barriers:** Clugg (walks through), Scrit (flies), Gorger (walks through), Gloom Wing (flies)
- **Leaps over barriers:** Polus (via Leap ability, 3s cooldown)
- **Rams through barriers:** Terror Bringer (attacks in straight line path)
- **Fires over barriers:** Bile Spitter (range 18 arcing projectiles)
