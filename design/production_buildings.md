# Production Buildings (3 Types)

## Design Status: COMPLETE

## Overview
Production buildings train player units. Player starts with 1 of each type pre-built. Additional copies can be built to speed up production (orders distribute round-robin across buildings of the same type).

**Full data in:** `htl_production_buildings.json`

---

## Core Rules
- **Queue:** Max 5 units per building, or Continuous mode (rotates through queued types).
- **Multiple buildings:** Building more of a type distributes production orders round-robin.
- **Full payment required:** Must have full price available to start producing a unit.
- **Population cap:** Production pauses when 100 pop cap is reached.
- **Sell-back:** 75%.
- **Passive regen:** 1% max HP / 5 sec.

---

## Buildings

| Name | Grid | HP | Armor | Cost (E/M) | Build | Hotkey | Produces |
|------|------|----|-------|-------------|-------|--------|----------|
| Drone Printer | 2x2 | 600 | 2 | 75/60 | 15s | 1 | Repair Drone, Shield Drone, Disruptor Drone |
| Mech Bay | 3x2 | 900 | 4 | 120/100 | 22s | 2 | Sentinel, Juggernaut |
| War Factory | 3x3 | 1200 | 5 | 160/130 | 28s | 3 | Striker, Siege Walker |

---

## Upgrades (per building type, apply globally to all buildings of that type)

### Drone Printer
1. **Quick Fabrication** (40E/30M) — -20% drone build time
2. **Reinforced Chassis** (60E/50M, Tier 1) — +15 HP, +1 armor to all drones
3. **Advanced Optics** (100E/80M, Tier 2) — Repair 7 HP/s, Shield +5 armor, Disruptor 35% slow

### Mech Bay
1. **Streamlined Assembly** (50E/40M) — -20% mech build time
2. **Hardened Plating** (80E/65M, Tier 1) — +50 HP, +1 armor to all mechs
3. **Overclocked Servos** (120E/100M, Tier 2) — +10% atk speed, +10% move speed, Juggernaut Fortify +4 armor

### War Factory
1. **Rapid Deployment** (60E/50M) — -20% vehicle build time
2. **Composite Armor** (100E/80M, Tier 1) — +75 HP, +1 armor to all vehicles
3. **Weapons Research** (150E/120M, Tier 2) — Overdrive 12s duration, Shatter Shell every 3rd shot, +15% damage
