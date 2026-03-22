# Audio Mapping

## Design Status: STRUCTURE COMPLETE — Audio files not yet assigned

## Overview
All audio is hook-based. Each game entity has named audio hooks that map to .wav files.
Format: `category.entity_id.event`

---

## Global / UI Audio Hooks
| Hook ID | Description | .wav File |
|---------|-------------|-----------|
| ui.button_click | Button click in menus | |
| ui.button_hover | Button hover | |
| ui.build_menu_open | Q menu opens | |
| ui.build_menu_close | Q menu closes | |
| ui.build_confirm | Placement confirmed | |
| ui.build_denied | Cannot place / insufficient resources | |
| ui.unit_selected | Unit selected | |
| ui.unit_deselected | Unit deselected | |
| ui.group_selected | Multiple units selected | |
| ui.upgrade_complete | Upgrade finishes | |
| ui.resource_warning | Low resources warning | |
| ui.surge_incoming | Surge alert banner | |
| ui.boss_incoming | Boss spawn warning | |
| ui.sell_confirm | Building/unit sold | |

## Music / Ambience Hooks
| Hook ID | Description | .wav File |
|---------|-------------|-----------|
| music.menu_theme | Main menu music | |
| music.gameplay_ambient | In-game ambient/music | |
| music.intense_combat | High-threat combat music | |
| music.boss_active | Boss on the field | |
| music.defeat | Game over music | |
| ambience.wind | Background wind | |
| ambience.base_hum | Base ambient hum | |

## Cinematic Hooks
| Hook ID | Description | .wav File |
|---------|-------------|-----------|
| cinematic.dropship_engine | Dropship liftoff engine sound | |
| cinematic.dropship_departure | Dropship flying away | |
| cinematic.narrator_line | "You are all that is left..." | |
| cinematic.dramatic_sting | Musical sting at message reveal | |

---

## Tower Audio Hooks
Pattern: `tower.<tower_id>.<event>`

| Event | Description |
|-------|-------------|
| .fire | Tower fires a shot |
| .impact | Projectile hits target |
| .build_start | Construction begins |
| .build_complete | Construction finishes |
| .destroy | Tower destroyed |
| .idle_hum | Ambient loop while idle |
| .upgrade | Upgrade applied |

### Per-Tower Hooks
| Tower ID | Name | Unique Sounds Needed |
|----------|------|---------------------|
| tw_off_001 | Autocannon Turret | Rapid bullet fire, barrel spin-up, brass casing tinks |
| tw_off_002 | Missile Battery | Missile launch whoosh, explosion impact, reload click |
| tw_off_003 | Rail Gun | Energy charge whine, electromagnetic crack, piercing impact |
| tw_off_004 | Plasma Mortar | Plasma charge hum, heavy thump launch, sizzling pool impact |
| tw_off_005 | Tesla Coil | Electrical crackling, arc zap, capacitor charge hum |
| tw_off_006 | Inferno Tower | Sustained beam roar, heat intensifying drone, metal stress |
| tw_res_001 | Leach Tower | Extraction beam hum, material collection chime, corpse dissolve |
| tw_res_002 | Thermal Siphon | Energy drain whoosh, pulsing collector hum, wisp sounds |
| tw_sup_001 | Repair Tower | Healing pulse wave, soft green chime, repair emitter hum |
| tw_sup_002 | War Beacon | Deep beacon pulse, power-up drone, red energy hum |
| tw_sup_003 | Targeting Array | Radar sweep beep, holographic data chitter, sensor ping |
| tw_sup_004 | Shield Pylon | Shield charge hum, hexagonal shimmer, crystal resonance |
| tw_spc_001 | Central Tower | Command center ambient, tier upgrade fanfare, damage alarms |

---

## Barrier Audio Hooks
Pattern: `barrier.<type>.<event>`

| Event | Description |
|-------|-------------|
| .place | Barrier placed |
| .hit | Barrier takes damage |
| .destroy | Barrier destroyed |
| .effect_loop | Ongoing effect sound |

| Barrier | Unique Sounds |
|---------|--------------|
| basic_structure | Concrete placement thud, impact cracks, rubble collapse |
| reinforced | Heavy metal clang placement, metallic stress groans, shearing metal break |
| energy_barrier | Energy field activation hum, projectile absorption zap, shield flicker, recharge pulse |

---

## Player Unit Audio Hooks
Pattern: `unit.<unit_id>.<event>`

| Event | Description |
|-------|-------------|
| .spawn | Unit finishes building and appears |
| .move | Movement loop / footsteps |
| .attack | Unit attacks |
| .impact | Unit's attack hits |
| .hit | Unit takes damage |
| .death | Unit dies |
| .select | Unit selected |
| .command | Unit given an order |
| .ability | Unit uses special ability |

| Unit ID | Name | Unique Sounds |
|---------|------|--------------|
| unit_drone_001 | Repair Drone | Hover hum, repair beam activation, green beam loop |
| unit_drone_002 | Shield Drone | Hover hum (lower pitch), shield bubble deploy, orbit loop |
| unit_drone_003 | Disruptor Drone | Aggressive hover buzz, disruption field crackle, red energy pulse |
| unit_mech_001 | Sentinel | Heavy footsteps, pulse rifle burst, mechanical servo whine |
| unit_mech_002 | Juggernaut | Earthquake stomps, power fist impact, fortify lock-down clank |
| unit_war_001 | Striker | Engine roar, twin cannon fire, overdrive boost |
| unit_war_002 | Siege Walker | Quad-leg march, plasma cannon charge+fire, deploy/undeploy hydraulics |

---

## Enemy Audio Hooks
Pattern: `enemy.<enemy_id>.<event>`

| Event | Description |
|-------|-------------|
| .spawn | Enemy appears on map edge |
| .move | Movement loop / footsteps |
| .attack | Enemy attacks |
| .impact | Enemy's attack hits |
| .hit | Enemy takes damage |
| .death | Enemy dies |
| .ability | Enemy uses special ability |
| .aggro | Enemy engages target |

| Enemy ID | Name | Unique Sounds |
|----------|------|--------------|
| 0 | Thrasher | Skittering claws, frantic chittering, claw swipe |
| 1 | Brute | Heavy thuds, guttural roar, hammer fist slam |
| 2 | Clugg | Ponderous earth-shaking footsteps, carapace groaning, threat aura rumble |
| 3 | Scrit | Bat-like wing flapping, high-pitched shriek, acid spit |
| 4 | Slinker | Stalking footsteps, energy pellet charge, head-crack firing |
| 5 | Polus | Rapid leg clicks, spine launch, leap wind-up + landing thud |
| 6 | Terror Bringer | Sprint shockwave, body slam impact, death blast wind-up + explosion |
| 7 | Blight Mite | Insect skitter swarm, volatile sac pulsing, detonation |
| 8 | Gorger | Predatory growl, jaw snap, frenzy screech |
| 9 | Gloom Wing | Deep wing beats, bomb drop whistle, explosion |
| 10 | Bile Spitter | Wet gurgling, acid lob arc, sizzling acid splash |
| 11 | Howler | Low moan, war cry pulse wave, screeching buff |

---

## Production Building Audio Hooks
Pattern: `production.<building_id>.<event>`

| Event | Description |
|-------|-------------|
| .build_start | Building construction begins |
| .build_complete | Building finishes construction |
| .train_start | Unit training begins |
| .train_complete | Unit finishes training |
| .upgrade_start | Upgrade begins |
| .upgrade_complete | Upgrade finishes |
| .destroy | Building destroyed |
| .ambient | Idle ambient loop |

| Building ID | Name | Unique Sounds |
|-------------|------|--------------|
| prod_001 | Drone Printer | Light fabrication whir, robotic assembly clicks, drone launch |
| prod_002 | Mech Bay | Heavy welding, gantry movement, bay door opening, mech stomp deploy |
| prod_003 | War Factory | Industrial machinery, crane hydraulics, engine start-up, ramp deployment |

---

## Mapping Status
- [x] Global/UI hooks defined
- [x] Music/Ambience hooks defined
- [x] Cinematic hooks defined
- [x] Tower hooks defined with per-tower sound descriptions
- [x] Barrier hooks defined with per-type sound descriptions
- [x] Player unit hooks defined with per-unit sound descriptions
- [x] Enemy hooks defined with per-enemy sound descriptions
- [x] Production building hooks defined with per-building sound descriptions
- [ ] Actual .wav files assigned to all hooks
