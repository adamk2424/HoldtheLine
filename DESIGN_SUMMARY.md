# Hold the Line - Project Summary

## Concept
RTS / Tower Defense hybrid. Survive as long as possible in a fixed base location by building units, towers, and defensive structures against endless waves of attackers.

## Engine & Perspective
- **Engine:** Godot (latest)
- **View:** 3D isometric top-down/angled (Starcraft/Warcraft style)
- **Visuals:** Code-generated placeholder geometry initially; swap in 3D assets later

## Map
- **Total visible area:** 300x300 units
- **Buildable area:** 120x120 unit grid (centered)
- **Grid:** Square build-grid; all buildings snap to grid
- **Enemy spawns:** From edges of the 300x300 map

## Controls
| Input | Action |
|-------|--------|
| W/A/S/D | Camera pan |
| Mouse | Select units/buildings |
| Q | Open build menu |

## Resources
| Resource | Base Rate | Notes |
|----------|-----------|-------|
| Energy | 1/sec | Used for all units and buildings |
| Materials | 1/sec | Used for all units and buildings |

- Every unit and building has a unique Energy + Materials cost
- Resources tick continuously (not per-wave)

## Combat Mechanics
- All buildings and units have **HP** and **Armor**
- **Armor:** Each point of armor reduces incoming damage by 1 per hit
- **Regen:** All units/buildings regen 1% of max HP every 5 seconds
- **HP Display:** Whole numbers in UI, 3 decimal places (0.000) in backend

## Content Counts
| Category | Count | Design Doc |
|----------|-------|------------|
| Enemy Types | 12 | [design/enemies.md](design/enemies.md) |
| Player Towers | 6 | [design/towers.md](design/towers.md) |
| Barrier/Defensive Structures | 3 | [design/barriers.md](design/barriers.md) |
| Player Offensive Units | 4 | [design/offensive_units.md](design/offensive_units.md) |
| Production Buildings | 3 | [design/production_buildings.md](design/production_buildings.md) |
| Audio Mapping | - | [design/audio_mapping.md](design/audio_mapping.md) |

## Unit Production
- Units are bought and spawn from **production buildings**
- Each unit has a **build time** before it appears
- Production buildings are placed in the base

## Upgrade System
- 3 production buildings can be **upgraded**
- Upgrades unlock new buildings/units, strengthen existing ones, or grant new abilities

## Intro Cinematic
- Camera shows the base
- Last dropships lift off into space
- Text: *"You are all that is left. You must Survive."*
- Camera settles into gameplay position

## Design Readiness Tracker
| Module | Status |
|--------|--------|
| Enemies (12) | NEEDS DESIGN |
| Towers (6) | NEEDS DESIGN |
| Barriers (3) | NEEDS DESIGN |
| Offensive Units (4) | NEEDS DESIGN |
| Production Buildings (3) | NEEDS DESIGN |
| Audio Mapping | NEEDS DESIGN |
| UI / HUD | NEEDS DESIGN |
| Wave / Spawn System | NEEDS DESIGN |
| Intro Cinematic | OUTLINED |
| Controls / Camera | OUTLINED |
| Resource System | OUTLINED |
| Combat Mechanics | OUTLINED |
