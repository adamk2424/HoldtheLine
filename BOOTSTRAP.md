# Hold The Line - Visual Enhancement Bootstrap

This bootstrap defines tasks to enhance the visual presentation of towers and buildings in Hold The Line.

## Task 1A: Enhanced Building Visuals

Improve the visual generation functions in `core/visual_generator.gd` for production buildings based on their design descriptions:

1. **Drone Printer** (2x2) - Update `_create_drone_printer()` to better match: "Compact industrial fabrication unit with flat top landing pad, robotic arms visible through transparent panels, green status lights, antenna array, military grey with green accent lighting."

2. **Mech Bay** (3x2) - Update `_create_mech_bay()` to better match: "Large industrial hangar with wide bay door, assembly gantries, welding sparks, heavy reinforced walls with external armor plating, blue operational status lights, smoke/steam vents, dark steel with blue accent lighting."

3. **War Factory** (3x3) - Update `_create_war_factory()` to better match: "Massive industrial complex with reinforced vehicle ramp exit, tank treads and heavy machinery visible inside, thick armored walls, orange warning lights, heavy crane arm, exhaust stacks, dark industrial metal with orange accent lighting."

## Task 1B: Tower Turret Animations

Add visual animation hooks and enhanced turret details to support future animation systems:

1. **Autocannon Turret** - Add rotating turret elements, barrel spin mechanics, muzzle flash attachment points
2. **Missile Battery** - Add tube reload animations, missile visibility, launch sequence markers
3. **Rail Gun** - Add energy conduit systems, charging effects, recoil mechanics

## Deliverables

- Updated building visuals in `visual_generator.gd` 
- Enhanced tower turret systems with animation hooks
- Commit after each sub-task is completed
- All changes maintain compatibility with existing entity classes