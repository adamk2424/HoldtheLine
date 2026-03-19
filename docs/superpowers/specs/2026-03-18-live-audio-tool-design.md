# Live Audio Tool — Design Spec

A standalone middleware-light audio development tool for Hold The Line. Connects to the running game via WebSocket for real-time audio parameter editing, monitoring, and configuration.

## Architecture

Three components:

1. **WebSocket Server** — Embedded in `audio_manager.gd` behind a debug flag. Listens on port 8090, handles bidirectional JSON messages. Exposes full audio state and accepts live parameter changes.

2. **Web UI** — Self-contained HTML/CSS/JS file (`tools/live_audio_tool.html`). No build step, no dependencies. Three-panel workstation layout (entity tree, cue editor, live monitor). Connects to game via WebSocket.

3. **Debug Overlay** — Separate autoload (`AudioDebugOverlay`). Draws floating 3D text labels at active emitter positions. Toggled with F3 hotkey.

```
Web UI  ←—WebSocket—→  AudioManager (game)
                            ↑
                       Debug Overlay reads
                       active player state
```

## Component 1: WebSocket Server (in-game)

### Activation

- Constant `LIVE_TOOL_ENABLED: bool = true` at top of `audio_manager.gd` (set `false` for release)
- When enabled, `_ready()` creates a `TCPServer` on port 8090
- `_process()` accepts new TCP connections via `TCPServer.take_connection()`, wraps each in a `WebSocketPeer` via `WebSocketPeer.accept_stream()`, then polls all connected peers every frame with `WebSocketPeer.poll()` / `get_packet()` / `send_text()`
- Voice count broadcast throttled to ~4Hz via a delta accumulator (WebSocket polling itself runs every frame)
- **Dev-only tool**: This entire system only operates when running from the Godot editor (F5/F6). `res://` filesystem scanning and writing require editor mode. Set `LIVE_TOOL_ENABLED = false` before exporting.

### Connection

- Auto-listens on `0.0.0.0:8090` when enabled
- Supports multiple simultaneous tool connections (broadcast state to all)
- Sends full state snapshot on connect

### Inbound Commands (Tool → Game)

| Command | Parameters | Effect |
|---|---|---|
| `get_state` | — | Returns full snapshot: entities, cues, bus volumes, attenuation presets, WAV file list (scanned via DirAccess, editor-mode only), active voices |
| `set_cue_volume` | entity, cue, value (dB) | Adjust volume_db for a specific entity.cue |
| `set_cue_pitch` | entity, cue, enabled, cents | Toggle pitch_randomize and/or set pitch_cents |
| `set_cue_files` | entity, cue, slot, path | Set WAV file for a specific slot (also supports files_start, files_end for looping cues) |
| `set_cue_looping` | entity, cue, is_looping | Toggle looping mode on a cue |
| `set_cue_voices` | entity, cue, max_voices | Override max voices for a cue |
| `set_bus_volume` | bus, value (linear 0-1) | Adjust Master/Music/SFX bus volume (converted to dB internally) |
| `set_attenuation_preset` | preset_name, settings | Create or update an attenuation preset |
| `assign_attenuation_preset` | entity, preset_name | Assign an entity to use a specific preset |
| `delete_attenuation_preset` | preset_name | Delete a preset (entities using it fall back to "default") |
| `solo` | entity (or entity.cue) | Toggle solo on an entity or cue |
| `mute` | entity (or entity.cue) | Toggle mute on an entity or cue |
| `test_play` | entity, cue | Fire a specific cue immediately (2D, non-positional). Plays through SFX bus at full volume regardless of in-game volume settings, ensuring audibility during audition. |
| `save` | — | Write current sfx_assignments.json + attenuation_presets.json to disk |

### Outbound Events (Game → Tool)

| Event | Data |
|---|---|
| `state` | Full state snapshot (response to get_state, also sent on connect) |
| `cue_fired` | entity, cue, file chosen, position (if 3D), pitch_scale applied |
| `cue_stopped` | entity, cue |
| `voice_count` | Periodic update (~4Hz) of active voice counts per cue |

### Looping Cue Playback

Looping cues require special handling in the player pool:

1. **Reserved players**: When a looping cue starts, the assigned AudioStreamPlayer3D is marked as "reserved" in a `_reserved_players: Dictionary` (keyed by player instance). Reserved players are excluded from the general pool and cannot be reclaimed by voice limiting or other cues.

2. **Playback chain**:
   - On trigger: acquire a 3D player from pool, mark as reserved, play a random START file (one-shot)
   - Connect to the player's `finished` signal. When START finishes, load a random LOOP file, set `stream.loop = true` (for AudioStreamWAV) or wrap in an `AudioStreamPlaybackResampled` loop, and play on the same player
   - When a stop command is received for this entity.cue: stop the loop, load a random END file, play it (one-shot) on the same player. On END's `finished` signal, un-reserve the player and return it to the pool
   - If no START files assigned, jump straight to LOOP
   - If no END files assigned, stop immediately and un-reserve

3. **Tracking**: A `_looping_cues: Dictionary` maps `entity_id.cue_id` → `{ player: AudioStreamPlayer3D, state: "start"|"loop"|"end" }` so stop commands can find the right player.

4. **Voice limiting**: Looping cues count toward voice limits but their reserved player cannot be stolen. If voice limit is reached, the new trigger is rejected rather than stopping the loop.

### Solo/Mute

- Two runtime-only dictionaries: `_soloed: Dictionary` and `_muted: Dictionary`
- Keyed by entity_id or entity_id.cue_id for granular control
- Before playing any cue: if anything is soloed, only play soloed entries; if muted, skip
- Never saved to disk — purely for live audition workflow

## Component 2: Web UI (External Tool)

### File

Single self-contained file: `tools/live_audio_tool.html`
- No build tools, no npm, no external dependencies
- All CSS and JS inline
- Dark theme matching existing tool aesthetic (greens, dark backgrounds)

### Connection

- On load, auto-attempts WebSocket connection to `ws://localhost:8090`
- If connection fails, shows "Waiting for game..." with retry
- Manual connect input field for remote connections (host:port)
- Connection status indicator in toolbar

### Layout: Three-Panel Workstation

**Top Bar:**
- Tool name + connection status badge
- Manual connect dropdown
- Save button with unsaved change counter (orange badge)

**Bus Mixer Strip (below top bar, always visible):**
- Master / Music / SFX volume sliders with draggable knob handles
- dB readout next to each slider

**Left Panel — Entity Tree:**
- Collapsible categories (Towers-Offensive, Towers-Support, Towers-Resource, Enemies, Units-Drone, Units-Mech, Units-Vehicle, Production, Barriers)
- Filter/search input at top
- Click to select entity, highlight with green accent

**Center Panel — Cue Editor:**
- Entity name + type header
- Entity-level Solo/Mute buttons
- Attenuation preset dropdown (assign entity to preset, shows preset summary inline)
- Expandable/collapsible cue cards for each cue:
  - Cue name + type badge (Standard or Looping)
  - Per-cue Solo (S) / Mute (M) / Test Play buttons
  - **Standard cue:** 3 WAV file slots (clickable → opens WAV picker modal), volume slider with knob, pitch randomize checkbox + cents input, max voices input
  - **Looping cue:** 3 sections (Start one-shot, Loop continuous, End one-shot) each with 3 WAV slots, plus same volume/pitch/voices controls. Orange left-border accent to distinguish.
  - Collapsed view shows cue name + first assigned file + count

**Right Panel — Live Monitor + Presets:**
- **Live Activity section:** Real-time feed of cue_fired events. Shows entity.cue name, fire count, looping indicator. Green dot for active, fades when idle.
- **Attenuation Presets section:** List of all presets. Click to expand/edit. Shows settings and "Used by" entity list. "+ New" button to create. Each preset editable: model dropdown, unit_size, max_distance, filter_cutoff_hz, filter_db, panning_strength.

### WAV Picker Modal

- Triggered by clicking any WAV file slot
- Floating modal overlay with search box at top
- Filterable list of all WAV files (sent by game on connect)
- Shows relative path (e.g., `Building_Explode_01.wav`)
- Click to select, or Clear/Cancel buttons
- Keyboard: Enter to select, Escape to close

### Dirty State / Save Flow

- All parameter changes are applied to the running game immediately via WebSocket
- Changes are tracked locally as "dirty" (unsaved count shown in toolbar)
- Clicking Save sends `save` command to game, which writes `sfx_assignments.json` and `attenuation_presets.json`
- On save success, dirty count resets

## Component 3: Debug Overlay (in-game)

### File

New autoload: `autoloads/audio_debug_overlay.gd`

### Activation

- Registered as autoload in project.godot
- Toggled on/off with F3 hotkey
- Only active when `LIVE_TOOL_ENABLED` is true (shares the debug flag)

### Behavior

- Reads active player state from AudioManager (needs accessor methods)
- For each currently-playing AudioStreamPlayer3D:
  - Draws a floating Label3D at the player's global_position
  - Text shows the WAV filename (e.g., "heavy_thunk_02.wav")
  - Label faces camera (billboard mode)
- Labels appear when a sound starts playing
- Labels linger for 1 second after playback ends, then disappear
- Uses a simple dictionary to track active labels and their linger timers
- **Label3D parenting**: Labels are added as children of `get_tree().current_scene` (a Node3D in gameplay). On scene transitions, all labels are cleaned up via `tree_exiting` signal on the current scene.

### Attenuation Radius (toggleable)

- Sub-toggle (e.g., Shift+F3) to show/hide attenuation radius
- When enabled, draws a wireframe sphere at each active emitter showing max_distance from the entity's attenuation preset
- Uses MeshInstance3D with SphereMesh + StandardMaterial3D with `transparency = ALPHA`, no texture, low alpha — creating a translucent sphere shell rather than a true wireframe (simpler, works on all platforms)

## Data Files

### sfx_assignments.json (existing, extended)

Adds two new fields per cue:

```json
{
  "autocannon": {
    "attack": {
      "files": ["res://audio/sfx/heavy_thunk_01.wav", "res://audio/sfx/heavy_thunk_02.wav", "res://audio/sfx/heavy_thunk_03.wav"],
      "pitch_randomize": true,
      "pitch_cents": 50,
      "volume_db": -3.0,
      "max_voices": 3,
      "is_looping": false
    }
  },
  "inferno_tower": {
    "attack": {
      "is_looping": true,
      "files_start": ["res://audio/sfx/flame_start_01.wav", "", ""],
      "files": ["res://audio/sfx/Flame_longshot.wav", "", ""],
      "files_end": ["res://audio/sfx/Flame_end.wav", "", ""],
      "pitch_randomize": true,
      "pitch_cents": 30,
      "volume_db": 0.0,
      "max_voices": 3
    }
  }
}
```

- Cue data remains Dictionary-only at entity root level (no mixed types)
- `is_looping` flag determines cue structure
- Looping cues use `files_start`, `files` (loop body), `files_end`
- Non-looping cues use `files` only (backward compatible)
- `max_voices` added as per-cue override (existing MAX_VOICES_PER_CUE becomes the default)

### attenuation_presets.json (new)

```json
{
  "default": {
    "model": "inverse_square",
    "unit_size": 15.0,
    "max_distance": 120.0,
    "filter_cutoff_hz": 10000.0,
    "filter_db": -18.0,
    "panning_strength": 0.8
  },
  "heavy_weapon": {
    "model": "inverse_square",
    "unit_size": 25.0,
    "max_distance": 200.0,
    "filter_cutoff_hz": 8000.0,
    "filter_db": -24.0,
    "panning_strength": 0.9
  },
  "small_effect": {
    "model": "inverse_square",
    "unit_size": 8.0,
    "max_distance": 60.0,
    "filter_cutoff_hz": 12000.0,
    "filter_db": -12.0,
    "panning_strength": 0.7
  }
}
```

- Saved by the live tool via the `save` command
- Loaded by AudioManager on startup
- `"default"` preset cannot be deleted

### entity_attenuation.json (new)

Maps entity IDs to attenuation preset names. Kept separate from `sfx_assignments.json` to avoid mixing string values with cue dictionaries at the entity root level.

```json
{
  "autocannon": "heavy_weapon",
  "rail_gun": "heavy_weapon",
  "missile_battery": "heavy_weapon",
  "scrit": "small_effect",
  "blight_mite": "small_effect"
}
```

- Entities not listed fall back to `"default"` preset
- Saved alongside `sfx_assignments.json` and `attenuation_presets.json` on `save` command

## Changes to Existing Files

### audio_manager.gd

- Add WebSocket server code (TCPServer + WebSocketPeer.accept_stream() pattern)
- Add `_soloed` and `_muted` dictionaries
- Add solo/mute check in play path
- Load attenuation presets from `attenuation_presets.json`
- Apply per-entity attenuation preset when configuring 3D players
- Add looping cue playback logic (start → loop → end chain)
- Add `max_voices` per-cue override support
- Expose accessor methods for debug overlay (active players, their positions, streams)
- Add `_process()` for WebSocket polling and voice_count broadcast

### project.godot

- Register `AudioDebugOverlay` as autoload

### tools/audio_setup.gd and tools/audio_setup_tool.py

- No changes needed. The live tool supersedes these for runtime use, but they remain functional for offline editing.

## Feature Summary

### Tier 1 (Essential)
- [x] Per-cue volume (dB slider with knob)
- [x] Per-cue pitch randomization (on/off, cent range)
- [x] Random container WAV assignments (swap/add/remove via picker modal)
- [x] Bus volumes (Master, Music, SFX)
- [x] Test playback from tool

### Tier 2 (Powerful additions)
- [x] 3D attenuation presets (create, edit, assign to entities)
- [x] Per-cue voice limiting override
- [x] Solo/Mute per entity or per cue (runtime only, never saved)
- [x] Live activity monitor (real-time cue firing feed)

### Additional features (from brainstorming)
- [x] Looping cue support (Start → Loop → End)
- [x] Attenuation preset system (named presets, entity assignment)
- [x] Debug overlay with floating WAV filename labels
- [x] Toggleable attenuation radius visualization
- [x] Explicit save workflow (experiment freely, save when ready)
- [x] Auto-discover + manual connect
- [x] WAV file picker modal with search

### Deferred (Tier 3)
- Audio bus effects (reverb, EQ, compressor)
- Distance attenuation curve visualization
- Waveform preview
- Music playlist management
