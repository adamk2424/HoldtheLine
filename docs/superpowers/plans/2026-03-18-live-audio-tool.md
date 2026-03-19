# Live Audio Tool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a middleware-light live audio development tool that connects to the running Godot game via WebSocket for real-time audio parameter editing, monitoring, and debug visualization.

**Architecture:** Three components built sequentially: (1) Extend AudioManager with attenuation presets, looping cues, solo/mute, and a WebSocket server, (2) Build a self-contained HTML/JS web UI that connects as a three-panel workstation, (3) Add an in-game debug overlay autoload for emitter visualization.

**Tech Stack:** GDScript (Godot 4.6.1), HTML/CSS/JS (no build tools), WebSocket (TCPServer + WebSocketPeer), JSON data files.

**Spec:** `docs/superpowers/specs/2026-03-18-live-audio-tool-design.md`

**Existing code:**
- `autoloads/audio_manager.gd` (588 lines) — the audio system we're extending
- `autoloads/game_bus.gd` — signal bus, extends Node, has `audio_play`, `audio_play_3d`, `audio_stop` signals
- `data/sfx_assignments.json` — existing entity→cue mapping (46 entities, 211 cues)
- `tools/audio_setup.gd` / `tools/audio_setup_tool.py` — existing offline editors (not modified)

**File structure:**
```
autoloads/
  audio_manager.gd          — MODIFY: add presets, looping, solo/mute, WebSocket server
  audio_debug_overlay.gd    — CREATE: debug overlay autoload
data/
  sfx_assignments.json      — EXISTING: extended with is_looping, files_start, files_end, max_voices
  attenuation_presets.json   — CREATE: named attenuation preset definitions
  entity_attenuation.json   — CREATE: entity→preset mapping
tools/
  live_audio_tool.html       — CREATE: self-contained web UI
project.godot               — MODIFY: register AudioDebugOverlay autoload
```

**Testing approach:** This is a Godot game with no automated test framework. Testing is manual: run the game (F5), open the web tool in a browser, verify behavior. Each task includes specific manual verification steps.

---

## Task 1: Attenuation Presets System

**Files:**
- Create: `data/attenuation_presets.json`
- Create: `data/entity_attenuation.json`
- Modify: `autoloads/audio_manager.gd:1-17` (constants section), `:59` (state vars), `:68-70` (_ready), `:112-119` (_configure_3d_player), `:297-311` (_play_cue_data_3d)

This task replaces the hardcoded attenuation constants with a preset system. No WebSocket yet — just the data loading and runtime application.

- [ ] **Step 1: Create attenuation_presets.json with default preset matching current constants**

Create `data/attenuation_presets.json`:
```json
{
	"default": {
		"model": "inverse_square",
		"unit_size": 15.0,
		"max_distance": 120.0,
		"filter_cutoff_hz": 10000.0,
		"filter_db": -18.0,
		"panning_strength": 0.8
	}
}
```

- [ ] **Step 2: Create empty entity_attenuation.json**

Create `data/entity_attenuation.json`:
```json
{
}
```

All entities default to the `"default"` preset when not listed.

- [ ] **Step 3: Add preset loading to audio_manager.gd**

Add state variables after line 59 (`var _sfx_assignments`):
```gdscript
var _attenuation_presets: Dictionary = {}
var _entity_attenuation: Dictionary = {}  # entity_id -> preset_name
```

Add two loader functions after `_load_sfx_assignments()`:
```gdscript
func _load_attenuation_presets() -> void:
	var path := "res://data/attenuation_presets.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_attenuation_presets = json.data
		print("[AudioManager] Loaded %d attenuation presets" % _attenuation_presets.size())


func _load_entity_attenuation() -> void:
	var path := "res://data/entity_attenuation.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_entity_attenuation = json.data
		print("[AudioManager] Loaded attenuation assignments for %d entities" % _entity_attenuation.size())
```

Call both in `_ready()` after `_load_sfx_assignments()`:
```gdscript
_load_attenuation_presets()
_load_entity_attenuation()
```

- [ ] **Step 4: Add preset lookup helper and modify _configure_3d_player**

Add a helper to resolve an entity's preset settings:
```gdscript
func _get_attenuation_for_entity(entity_id: String) -> Dictionary:
	var preset_name: String = _entity_attenuation.get(entity_id, "default")
	if _attenuation_presets.has(preset_name):
		return _attenuation_presets[preset_name]
	if _attenuation_presets.has("default"):
		return _attenuation_presets["default"]
	# Hardcoded fallback matching original constants
	return {
		"model": "inverse_square",
		"unit_size": 15.0,
		"max_distance": 120.0,
		"filter_cutoff_hz": 10000.0,
		"filter_db": -18.0,
		"panning_strength": 0.8,
	}


static func _atten_model_from_string(model_name: String) -> AudioStreamPlayer3D.AttenuationModel:
	match model_name:
		"inverse_distance": return AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		"inverse_square": return AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		"logarithmic": return AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
		"disabled": return AudioStreamPlayer3D.ATTENUATION_DISABLED
	return AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
```

Change `_configure_3d_player` to accept a preset Dictionary:
```gdscript
func _configure_3d_player(player: AudioStreamPlayer3D, preset: Dictionary = {}) -> void:
	if preset.is_empty() and _attenuation_presets.has("default"):
		preset = _attenuation_presets["default"]
	player.attenuation_model = _atten_model_from_string(preset.get("model", "inverse_square"))
	player.unit_size = preset.get("unit_size", 15.0)
	player.max_distance = preset.get("max_distance", 120.0)
	player.attenuation_filter_cutoff_hz = preset.get("filter_cutoff_hz", 10000.0)
	player.attenuation_filter_db = preset.get("filter_db", -18.0)
	player.panning_strength = preset.get("panning_strength", 0.8)
	player.max_polyphony = 1
```

- [ ] **Step 5: Apply entity-specific presets before 3D playback**

In `_play_cue_data_3d`, after acquiring the player and before `player.play()`, apply the entity's preset. The function needs the entity_id, so update `_try_sfx_assignment_3d` to pass it through. Modify `_play_cue_data_3d` signature:
```gdscript
func _play_cue_data_3d(cue_data: Dictionary, world_pos: Vector3, cue_key: String, entity_id: String = "") -> bool:
	var stream := _resolve_cue_stream(cue_data)
	if not stream:
		return false
	var player := _acquire_3d_player(cue_key)
	if not player:
		return false
	# Apply entity-specific attenuation preset
	if not entity_id.is_empty():
		_configure_3d_player(player, _get_attenuation_for_entity(entity_id))
	player.stream = stream
	player.global_position = world_pos
	_apply_cue_params_3d(player, cue_data)
	player.play()
	return true
```

Update the two call sites in `_try_sfx_assignment_3d` to pass `entity_id`:
```gdscript
return _play_cue_data_3d(entity_cues[action], world_pos, cue_key, entity_id)
# and
return _play_cue_data_3d(entity_cues[cue], world_pos, cue_key, entity_id)
```

Also update the fallback in `play_at` (line 443) to pass empty entity_id (no change needed, default parameter handles it).

- [ ] **Step 6: Remove hardcoded ATTEN_ constants**

Remove lines 10-16 (the `ATTEN_*` constants). They are now loaded from the preset file. The initial pool setup in `_ready()` line 98 calls `_configure_3d_player(player)` — this will now use the default preset from the JSON file.

- [ ] **Step 7: Verify manually**

Run the game (F5). Check console output for:
- `[AudioManager] Loaded 1 attenuation presets`
- `[AudioManager] Loaded attenuation assignments for 0 entities`
- All existing sounds play with the same attenuation behavior as before (default preset matches the old constants).

- [ ] **Step 8: Commit**

```bash
git add data/attenuation_presets.json data/entity_attenuation.json autoloads/audio_manager.gd
git commit -m "feat(audio): replace hardcoded attenuation with preset system"
```

---

## Task 2: Per-Cue Max Voices + Solo/Mute

**Files:**
- Modify: `autoloads/audio_manager.gd:8` (MAX_VOICES_PER_CUE usage), `:59` (state vars), `:315-347` (_acquire_3d_player), `:280-294` (_play_cue_data_2d), `:297-311` (_play_cue_data_3d)

- [ ] **Step 1: Add solo/mute state variables**

Add after the attenuation state vars:
```gdscript
# Solo/Mute: runtime-only, never saved. Keyed by entity_id or entity_id.cue_id
var _soloed: Dictionary = {}
var _muted: Dictionary = {}
```

- [ ] **Step 2: Add solo/mute check function**

```gdscript
func _is_cue_allowed(entity_id: String, cue_id: String) -> bool:
	var cue_key := entity_id + "." + cue_id
	# If anything is soloed, only allow soloed entries
	if not _soloed.is_empty():
		if not _soloed.has(entity_id) and not _soloed.has(cue_key):
			return false
	# Check mute
	if _muted.has(entity_id) or _muted.has(cue_key):
		return false
	return true
```

- [ ] **Step 3: Add per-cue max_voices to _acquire_3d_player**

Change `_acquire_3d_player` to accept an optional max_voices parameter:
```gdscript
func _acquire_3d_player(cue_key: String, max_voices: int = MAX_VOICES_PER_CUE) -> AudioStreamPlayer3D:
```

Replace `MAX_VOICES_PER_CUE` usage on line 331 with `max_voices`:
```gdscript
while voices.size() >= max_voices:
```

- [ ] **Step 4: Pass per-cue max_voices from cue_data**

In `_play_cue_data_3d`, read max_voices from cue_data and pass it:
```gdscript
var max_v: int = cue_data.get("max_voices", MAX_VOICES_PER_CUE)
var player := _acquire_3d_player(cue_key, max_v)
```

- [ ] **Step 5: Add solo/mute check to play paths**

In `_try_sfx_assignment_2d`, after resolving entity_id and action (around line 356), add:
```gdscript
var resolved_cue := action
if not entity_cues.has(action):
	resolved_cue = ACTION_TO_CUE.get(action, "")
if not _is_cue_allowed(entity_id, resolved_cue):
	return true  # Return true to prevent fallback to audio_hooks, but don't play
```

Same pattern in `_try_sfx_assignment_3d`.

- [ ] **Step 6: Verify manually**

Run the game (F5). Sounds play as before. Solo/mute dictionaries are empty so no change in behavior. The per-cue max_voices defaults to 3 (same as before) since no cue data has the field yet.

- [ ] **Step 7: Commit**

```bash
git add autoloads/audio_manager.gd
git commit -m "feat(audio): add per-cue voice limits and solo/mute support"
```

---

## Task 3: Looping Cue Playback

**Files:**
- Modify: `autoloads/audio_manager.gd` — add looping cue state tracking, playback chain logic, reserved player pool exclusion

- [ ] **Step 1: Add looping cue state variables**

```gdscript
# Looping cue tracking: "entity_id.cue_id" -> { player: AudioStreamPlayer3D, state: String, entity_id: String, cue_id: String }
var _looping_cues: Dictionary = {}
# Reserved players (looping): player instance ID -> true. Excluded from general pool.
var _reserved_players: Dictionary = {}
```

- [ ] **Step 2: Add reserved player exclusion to _acquire_3d_player**

In `_acquire_3d_player`, when finding a free player from the pool, skip reserved players:
```gdscript
# Find a free player from the pool
var player: AudioStreamPlayer3D = null
for p in _sfx_players_3d:
	if not p.playing and not _reserved_players.has(p.get_instance_id()):
		player = p
		break
```

- [ ] **Step 3: Add helper to resolve files from a specific array key**

```gdscript
func _resolve_stream_from_key(cue_data: Dictionary, key: String) -> AudioStream:
	var files: Array = cue_data.get(key, [])
	var valid: Array[String] = []
	for f in files:
		if f is String and not f.is_empty():
			valid.append(f)
	if valid.is_empty():
		return null
	var chosen: String = valid[randi() % valid.size()]
	return _get_or_load_stream(chosen)
```

- [ ] **Step 4: Implement looping cue start**

```gdscript
func _play_looping_cue_3d(cue_data: Dictionary, world_pos: Vector3, cue_key: String, entity_id: String) -> bool:
	# If this loop is already playing, don't start another
	if _looping_cues.has(cue_key):
		return true

	var max_v: int = cue_data.get("max_voices", MAX_VOICES_PER_CUE)
	var player := _acquire_3d_player(cue_key, max_v)
	if not player:
		return false

	# Reserve this player
	_reserved_players[player.get_instance_id()] = true

	var loop_entry := {
		"player": player,
		"state": "start",
		"cue_data": cue_data,
		"entity_id": entity_id,
		"cue_key": cue_key,
		"world_pos": world_pos,
	}
	_looping_cues[cue_key] = loop_entry

	# Try START files first
	var start_stream := _resolve_stream_from_key(cue_data, "files_start")
	if start_stream:
		player.stream = start_stream
		player.global_position = world_pos
		_apply_cue_params_3d(player, cue_data)
		if not player.finished.is_connected(_on_loop_start_finished):
			player.finished.connect(_on_loop_start_finished.bind(cue_key), CONNECT_ONE_SHOT)
		player.play()
	else:
		# No start files, go straight to loop
		loop_entry["state"] = "loop"
		_begin_loop_body(cue_key, world_pos)

	return true


func _begin_loop_body(cue_key: String, world_pos: Vector3) -> void:
	if not _looping_cues.has(cue_key):
		return
	var entry: Dictionary = _looping_cues[cue_key]
	var player: AudioStreamPlayer3D = entry["player"]
	var cue_data: Dictionary = entry["cue_data"]

	var loop_stream := _resolve_stream_from_key(cue_data, "files")
	if not loop_stream:
		_stop_looping_cue(cue_key)
		return

	# Duplicate stream to avoid mutating the cached version, then enable looping
	if loop_stream is AudioStreamWAV:
		loop_stream = loop_stream.duplicate() as AudioStreamWAV
		loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		# loop_begin defaults to 0, loop_end=0 means loop the entire file in Godot 4.x

	entry["state"] = "loop"
	player.stream = loop_stream
	player.global_position = world_pos
	_apply_cue_params_3d(player, cue_data)
	player.play()


func _on_loop_start_finished(cue_key: String) -> void:
	if not _looping_cues.has(cue_key):
		return
	var entry: Dictionary = _looping_cues[cue_key]
	_begin_loop_body(cue_key, entry["world_pos"])
```

- [ ] **Step 5: Implement looping cue stop**

```gdscript
func _stop_looping_cue(cue_key: String) -> void:
	if not _looping_cues.has(cue_key):
		return
	var entry: Dictionary = _looping_cues[cue_key]
	var player: AudioStreamPlayer3D = entry["player"]
	var cue_data: Dictionary = entry["cue_data"]

	player.stop()

	# Try END files
	var end_stream := _resolve_stream_from_key(cue_data, "files_end")
	if end_stream:
		entry["state"] = "end"
		player.stream = end_stream
		_apply_cue_params_3d(player, cue_data)
		if not player.finished.is_connected(_on_loop_end_finished):
			player.finished.connect(_on_loop_end_finished.bind(cue_key), CONNECT_ONE_SHOT)
		player.play()
	else:
		# No end files, just release immediately
		_release_looping_cue(cue_key)


func _on_loop_end_finished(cue_key: String) -> void:
	_release_looping_cue(cue_key)


func _release_looping_cue(cue_key: String) -> void:
	if not _looping_cues.has(cue_key):
		return
	var entry: Dictionary = _looping_cues[cue_key]
	var player: AudioStreamPlayer3D = entry["player"]
	_reserved_players.erase(player.get_instance_id())
	_looping_cues.erase(cue_key)
	if LIVE_TOOL_ENABLED:
		_ws_broadcast({"event": "cue_stopped", "entity": entry.get("entity_id", ""), "cue": cue_key})
```

- [ ] **Step 6: Integrate looping into the play/stop path**

In `_play_cue_data_3d`, before the existing playback logic, check for looping:
```gdscript
func _play_cue_data_3d(cue_data: Dictionary, world_pos: Vector3, cue_key: String, entity_id: String = "") -> bool:
	# Handle looping cues separately
	if cue_data.get("is_looping", false):
		return _play_looping_cue_3d(cue_data, world_pos, cue_key, entity_id)

	var stream := _resolve_cue_stream(cue_data)
	# ... rest of existing code
```

In `stop()`, add looping cue stop support:
```gdscript
func stop(hook_id: String) -> void:
	if hook_id.begins_with("music."):
		_music_player.stop()
	elif hook_id.begins_with("ambience."):
		_ambience_player.stop()
	else:
		# Check for looping cue stop
		var parts := hook_id.split(".")
		if parts.size() >= 3:
			var cue_key := parts[1] + "." + parts[2]
			if _looping_cues.has(cue_key):
				_stop_looping_cue(cue_key)
```

- [ ] **Step 7: Verify manually**

No looping cues exist yet in `sfx_assignments.json`, so existing behavior unchanged. Can manually add a test looping cue to verify:
```json
"inferno_tower": {
  "attack": {
    "is_looping": true,
    "files_start": [],
    "files": ["res://audio/sfx/Flame_longshot.wav"],
    "files_end": ["res://audio/sfx/Flame_end.wav"],
    "pitch_randomize": false,
    "pitch_cents": 50,
    "volume_db": 0.0,
    "max_voices": 3
  }
}
```

- [ ] **Step 8: Commit**

```bash
git add autoloads/audio_manager.gd
git commit -m "feat(audio): add looping cue playback (start/loop/end chain)"
```

---

## Task 4: WebSocket Server

**Files:**
- Modify: `autoloads/audio_manager.gd` — add TCPServer, WebSocketPeer management, command dispatch, event broadcasting, WAV scanning, save logic

- [ ] **Step 1: Add LIVE_TOOL_ENABLED flag and WebSocket state variables**

At the top of audio_manager.gd, add:
```gdscript
const LIVE_TOOL_ENABLED: bool = true
const LIVE_TOOL_PORT: int = 8090
```

Add state variables:
```gdscript
# Live tool WebSocket server
var _ws_server: TCPServer = null
var _ws_peers: Array = []  # Array of WebSocketPeer
var _ws_voice_timer: float = 0.0
var _wav_file_list: Array[String] = []
```

- [ ] **Step 2: Initialize WebSocket server in _ready()**

At the end of `_ready()`, add:
```gdscript
if LIVE_TOOL_ENABLED:
	_start_ws_server()
```

```gdscript
func _start_ws_server() -> void:
	_ws_server = TCPServer.new()
	var err := _ws_server.listen(LIVE_TOOL_PORT, "0.0.0.0")
	if err != OK:
		push_warning("[AudioManager] Failed to start WebSocket server on port %d" % LIVE_TOOL_PORT)
		_ws_server = null
		return
	_scan_wav_files()
	print("[AudioManager] Live tool server listening on port %d" % LIVE_TOOL_PORT)
```

- [ ] **Step 3: Add WAV file scanning**

```gdscript
func _scan_wav_files() -> void:
	_wav_file_list.clear()
	_scan_wav_dir("res://audio/sfx")
	_wav_file_list.sort()
	print("[AudioManager] Scanned %d WAV files for live tool" % _wav_file_list.size())


func _scan_wav_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_wav_dir(path.path_join(file_name))
		elif file_name.get_extension().to_lower() == "wav":
			_wav_file_list.append(path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
```

- [ ] **Step 4: Add _process() for WebSocket polling**

```gdscript
func _process(delta: float) -> void:
	if not LIVE_TOOL_ENABLED or _ws_server == null:
		return
	_ws_poll(delta)
```

```gdscript
func _ws_poll(delta: float) -> void:
	# Accept new connections
	while _ws_server.is_connection_available():
		var tcp := _ws_server.take_connection()
		if tcp:
			var ws := WebSocketPeer.new()
			ws.accept_stream(tcp)
			_ws_peers.append(ws)
			print("[AudioManager] Live tool client connected")

	# Poll existing peers
	var i := _ws_peers.size() - 1
	while i >= 0:
		var ws: WebSocketPeer = _ws_peers[i]
		ws.poll()
		var state := ws.get_ready_state()

		if state == WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				var pkt := ws.get_packet()
				_ws_handle_message(ws, pkt.get_string_from_utf8())
		elif state == WebSocketPeer.STATE_CLOSING:
			pass  # Wait for close to complete
		elif state == WebSocketPeer.STATE_CLOSED:
			_ws_peers.remove_at(i)
			print("[AudioManager] Live tool client disconnected")
		i -= 1

	# Broadcast voice counts at ~4Hz
	_ws_voice_timer += delta
	if _ws_voice_timer >= 0.25:
		_ws_voice_timer = 0.0
		_ws_broadcast_voice_counts()
```

- [ ] **Step 5: Add full state snapshot builder**

```gdscript
func _ws_build_state() -> Dictionary:
	return {
		"event": "state",
		"entities": _sfx_assignments,
		"attenuation_presets": _attenuation_presets,
		"entity_attenuation": _entity_attenuation,
		"bus_volumes": {
			"master": db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))),
			"music": db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))),
			"sfx": db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))),
		},
		"wav_files": _wav_file_list,
		"soloed": _soloed.keys(),
		"muted": _muted.keys(),
	}
```

- [ ] **Step 6: Add message handler with command dispatch**

```gdscript
func _ws_handle_message(ws: WebSocketPeer, text: String) -> void:
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var msg: Dictionary = json.data
	var cmd: String = msg.get("cmd", "")

	match cmd:
		"get_state":
			ws.send_text(JSON.stringify(_ws_build_state()))
		"set_cue_volume":
			_ws_cmd_set_cue_volume(msg)
		"set_cue_pitch":
			_ws_cmd_set_cue_pitch(msg)
		"set_cue_files":
			_ws_cmd_set_cue_files(msg)
		"set_cue_looping":
			_ws_cmd_set_cue_looping(msg)
		"set_cue_voices":
			_ws_cmd_set_cue_voices(msg)
		"set_bus_volume":
			_ws_cmd_set_bus_volume(msg)
		"set_attenuation_preset":
			_ws_cmd_set_attenuation_preset(msg)
		"assign_attenuation_preset":
			_ws_cmd_assign_attenuation_preset(msg)
		"delete_attenuation_preset":
			_ws_cmd_delete_attenuation_preset(msg)
		"solo":
			_ws_cmd_solo(msg)
		"mute":
			_ws_cmd_mute(msg)
		"test_play":
			_ws_cmd_test_play(msg)
		"save":
			_ws_cmd_save()
```

- [ ] **Step 7: Implement each command handler**

```gdscript
func _ws_cmd_set_cue_volume(msg: Dictionary) -> void:
	var entity: String = msg.get("entity", "")
	var cue: String = msg.get("cue", "")
	var value: float = msg.get("value", 0.0)
	if _sfx_assignments.has(entity) and _sfx_assignments[entity].has(cue):
		_sfx_assignments[entity][cue]["volume_db"] = value


func _ws_cmd_set_cue_pitch(msg: Dictionary) -> void:
	var entity: String = msg.get("entity", "")
	var cue: String = msg.get("cue", "")
	if _sfx_assignments.has(entity) and _sfx_assignments[entity].has(cue):
		if msg.has("enabled"):
			_sfx_assignments[entity][cue]["pitch_randomize"] = msg["enabled"]
		if msg.has("cents"):
			_sfx_assignments[entity][cue]["pitch_cents"] = int(msg["cents"])


func _ws_cmd_set_cue_files(msg: Dictionary) -> void:
	var entity: String = msg.get("entity", "")
	var cue: String = msg.get("cue", "")
	var slot: int = msg.get("slot", 0)
	var path: String = msg.get("path", "")
	var key: String = msg.get("key", "files")  # "files", "files_start", or "files_end"
	if _sfx_assignments.has(entity) and _sfx_assignments[entity].has(cue):
		var cue_data: Dictionary = _sfx_assignments[entity][cue]
		if not cue_data.has(key):
			cue_data[key] = ["", "", ""]
		var files: Array = cue_data[key]
		if slot >= 0 and slot < files.size():
			files[slot] = path


func _ws_cmd_set_cue_looping(msg: Dictionary) -> void:
	var entity: String = msg.get("entity", "")
	var cue: String = msg.get("cue", "")
	var is_looping: bool = msg.get("is_looping", false)
	if _sfx_assignments.has(entity) and _sfx_assignments[entity].has(cue):
		_sfx_assignments[entity][cue]["is_looping"] = is_looping
		if is_looping:
			var cue_data: Dictionary = _sfx_assignments[entity][cue]
			if not cue_data.has("files_start"):
				cue_data["files_start"] = ["", "", ""]
			if not cue_data.has("files_end"):
				cue_data["files_end"] = ["", "", ""]


func _ws_cmd_set_cue_voices(msg: Dictionary) -> void:
	var entity: String = msg.get("entity", "")
	var cue: String = msg.get("cue", "")
	var max_voices: int = msg.get("max_voices", MAX_VOICES_PER_CUE)
	if _sfx_assignments.has(entity) and _sfx_assignments[entity].has(cue):
		_sfx_assignments[entity][cue]["max_voices"] = max_voices


func _ws_cmd_set_bus_volume(msg: Dictionary) -> void:
	var bus: String = msg.get("bus", "")
	var value_linear: float = msg.get("value", 1.0)  # 0.0 to 1.0 linear scale
	var bus_name := ""
	match bus:
		"master": bus_name = "Master"
		"music": bus_name = "Music"
		"sfx": bus_name = "SFX"
	if bus_name.is_empty():
		return
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value_linear))
		AudioServer.set_bus_mute(idx, value_linear <= 0.0)


func _ws_cmd_set_attenuation_preset(msg: Dictionary) -> void:
	var preset_name: String = msg.get("preset_name", "")
	var settings: Dictionary = msg.get("settings", {})
	if preset_name.is_empty() or settings.is_empty():
		return
	_attenuation_presets[preset_name] = settings


func _ws_cmd_assign_attenuation_preset(msg: Dictionary) -> void:
	var entity: String = msg.get("entity", "")
	var preset_name: String = msg.get("preset_name", "")
	if entity.is_empty():
		return
	if preset_name == "default" or preset_name.is_empty():
		_entity_attenuation.erase(entity)
	else:
		_entity_attenuation[entity] = preset_name


func _ws_cmd_delete_attenuation_preset(msg: Dictionary) -> void:
	var preset_name: String = msg.get("preset_name", "")
	if preset_name.is_empty() or preset_name == "default":
		return
	_attenuation_presets.erase(preset_name)
	# Remove all entity assignments pointing to this preset
	var to_remove: Array[String] = []
	for entity in _entity_attenuation:
		if _entity_attenuation[entity] == preset_name:
			to_remove.append(entity)
	for entity in to_remove:
		_entity_attenuation.erase(entity)


func _ws_cmd_solo(msg: Dictionary) -> void:
	var target: String = msg.get("target", "")
	if target.is_empty():
		return
	if _soloed.has(target):
		_soloed.erase(target)
	else:
		_soloed[target] = true


func _ws_cmd_mute(msg: Dictionary) -> void:
	var target: String = msg.get("target", "")
	if target.is_empty():
		return
	if _muted.has(target):
		_muted.erase(target)
	else:
		_muted[target] = true


func _ws_cmd_test_play(msg: Dictionary) -> void:
	var entity: String = msg.get("entity", "")
	var cue: String = msg.get("cue", "")
	if not _sfx_assignments.has(entity):
		return
	var entity_cues: Dictionary = _sfx_assignments[entity]
	if not entity_cues.has(cue):
		return
	# Play through 2D at full volume regardless of bus settings
	var cue_data: Dictionary = entity_cues[cue].duplicate(true)
	cue_data["volume_db"] = 0.0
	_play_cue_data_2d(cue_data)


func _ws_cmd_save() -> void:
	# Save sfx_assignments.json
	var file := FileAccess.open("res://data/sfx_assignments.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_sfx_assignments, "\t"))
		file = null

	# Save attenuation_presets.json
	file = FileAccess.open("res://data/attenuation_presets.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_attenuation_presets, "\t"))
		file = null

	# Save entity_attenuation.json
	file = FileAccess.open("res://data/entity_attenuation.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_entity_attenuation, "\t"))
		file = null

	print("[AudioManager] Live tool: saved all audio data")
	_ws_broadcast({"event": "saved"})
```

- [ ] **Step 8: Add broadcast helpers and cue_fired event emission**

```gdscript
func _ws_broadcast(data: Dictionary) -> void:
	if _ws_peers.is_empty():
		return
	var text := JSON.stringify(data)
	for ws in _ws_peers:
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			ws.send_text(text)


func _ws_broadcast_voice_counts() -> void:
	if _ws_peers.is_empty():
		return
	var counts := {}
	for cue_key in _active_voices:
		var voices: Array = _active_voices[cue_key]
		var active := 0
		for v in voices:
			if is_instance_valid(v) and v.playing:
				active += 1
		if active > 0:
			counts[cue_key] = active
	# Include looping cues
	for cue_key in _looping_cues:
		counts[cue_key + " (loop)"] = 1
	_ws_broadcast({"event": "voice_count", "counts": counts})
```

Add `_ws_emit_cue_fired` helper and call it from the play paths:
```gdscript
func _ws_emit_cue_fired(entity_id: String, cue_key: String, file_path: String, world_pos: Variant = null) -> void:
	if not LIVE_TOOL_ENABLED or _ws_peers.is_empty():
		return
	var data := {"event": "cue_fired", "entity": entity_id, "cue": cue_key, "file": file_path.get_file()}
	if world_pos is Vector3:
		data["position"] = {"x": world_pos.x, "y": world_pos.y, "z": world_pos.z}
	_ws_broadcast(data)
```

Emit from `_try_sfx_assignment_3d` after each successful `_play_cue_data_3d` call:
```gdscript
# After: return _play_cue_data_3d(entity_cues[action], world_pos, cue_key, entity_id)
# Change to:
var result := _play_cue_data_3d(entity_cues[action], world_pos, cue_key, entity_id)
if result:
	_ws_emit_cue_fired(entity_id, cue_key, "", world_pos)
return result
```

Same pattern for the `_try_sfx_assignment_2d` path. For `_ws_cmd_test_play`, emit explicitly:
```gdscript
func _ws_cmd_test_play(msg: Dictionary) -> void:
	var entity: String = msg.get("entity", "")
	var cue: String = msg.get("cue", "")
	if not _sfx_assignments.has(entity):
		return
	var entity_cues: Dictionary = _sfx_assignments[entity]
	if not entity_cues.has(cue):
		return
	var cue_data: Dictionary = entity_cues[cue].duplicate(true)
	cue_data["volume_db"] = 0.0
	_play_cue_data_2d(cue_data)
	_ws_emit_cue_fired(entity, entity + "." + cue, "")
```

- [ ] **Step 9: Send state snapshot on new connection**

Add a tracking set for peers that haven't received their initial state yet:
```gdscript
var _ws_pending_state: Array = []  # WebSocketPeers waiting for STATE_OPEN to send initial state
```

In `_ws_poll`, after adding a new peer, add it to the pending set:
```gdscript
while _ws_server.is_connection_available():
	var tcp := _ws_server.take_connection()
	if tcp:
		var ws := WebSocketPeer.new()
		ws.accept_stream(tcp)
		_ws_peers.append(ws)
		_ws_pending_state.append(ws)
		print("[AudioManager] Live tool client connected")
```

In the poll loop, after checking `state == WebSocketPeer.STATE_OPEN`, send state to newly-opened peers:
```gdscript
if state == WebSocketPeer.STATE_OPEN:
	# Send initial state to newly connected peers
	if ws in _ws_pending_state:
		ws.send_text(JSON.stringify(_ws_build_state()))
		_ws_pending_state.erase(ws)
	while ws.get_available_packet_count() > 0:
		var pkt := ws.get_packet()
		_ws_handle_message(ws, pkt.get_string_from_utf8())
```

- [ ] **Step 10: Verify manually**

Run the game (F5). Check console for `[AudioManager] Live tool server listening on port 8090`. Open browser dev console and test:
```javascript
let ws = new WebSocket("ws://localhost:8090");
ws.onmessage = (e) => console.log(JSON.parse(e.data));
ws.onopen = () => ws.send(JSON.stringify({cmd: "get_state"}));
```
Should receive the full state snapshot in the console.

- [ ] **Step 11: Commit**

```bash
git add autoloads/audio_manager.gd
git commit -m "feat(audio): add WebSocket server for live tool connection"
```

---

## Task 5: Web UI — HTML Shell + Connection

**Files:**
- Create: `tools/live_audio_tool.html`

This task builds the web UI incrementally. First the HTML/CSS shell and WebSocket connection. The file is large so we build it in stages.

- [ ] **Step 1: Create HTML file with CSS theme, connection logic, and three-panel layout skeleton**

Create `tools/live_audio_tool.html` with:
- Full HTML document structure with inline CSS
- Dark theme CSS matching the mockup (colors: bg #0d1117, accent #4de680, etc.)
- CSS for slider tracks and knobs (`.slider-track`, `.slider-knob`)
- CSS for panels, cue cards, WAV slots, buttons
- Top bar with connection status badge and Save button
- Bus mixer strip with 3 sliders (Master/Music/SFX)
- Three-panel flexbox layout: left (entity tree), center (cue editor), right (live monitor + presets)
- JavaScript WebSocket connection logic:
  - `connect(host, port)` — creates WebSocket, sets up onmessage/onclose/onerror
  - Auto-connect to `ws://localhost:8090` on page load
  - Reconnect with 2-second retry on disconnect
  - Manual connect input field (hidden by default, shown via "Manual Connect" link)
  - Connection status indicator updates
  - `send(cmd, params)` helper that JSON.stringifies and sends
  - `onMessage(data)` dispatcher that routes events to handler functions

- [ ] **Step 2: Verify manually**

Open `tools/live_audio_tool.html` in a browser (double-click or `file://` URL). It should show the dark UI shell. Run the game — the connection badge should change to "CONNECTED". Open browser dev console — no errors. Click "Manual Connect" — input field appears.

- [ ] **Step 3: Commit**

```bash
git add tools/live_audio_tool.html
git commit -m "feat(live-tool): HTML shell with WebSocket connection"
```

---

## Task 6: Web UI — Entity Tree + Cue Editor

**Files:**
- Modify: `tools/live_audio_tool.html`

- [ ] **Step 1: Build entity tree from state snapshot**

JavaScript to handle the `state` event:
- Parse `data.entities` — build category groups from entity types (categories are derived from the entity data the same way the existing tools do — by reading the data JSON files. Since the web tool can't read those, the game server should send category info. For now, render a flat alphabetical list of entity IDs, grouped by type if the cue structure reveals it.)
- Render collapsible category headers + entity buttons in left panel
- Filter input filters entity list by name
- Click entity → highlight, load cue editor

- [ ] **Step 2: Build cue editor for selected entity**

When an entity is selected:
- Show entity name + type in header
- Entity-level Solo/Mute buttons (send `solo`/`mute` commands on click)
- Attenuation preset dropdown (populated from `data.attenuation_presets`, current selection from `data.entity_attenuation`)
- For each cue in the entity:
  - Render a cue card (expandable/collapsible)
  - Show cue name + badge (Standard or Looping based on `is_looping`)
  - Per-cue S/M/Test buttons
  - **Standard cue:** 3 WAV file slots (clickable), volume slider with knob, pitch checkbox + cents input, voices input
  - **Looping cue:** Start/Loop/End sections each with 3 WAV slots, plus volume/pitch/voices
  - All controls send their respective WebSocket command on change
  - Track dirty state (increment unsaved counter)

- [ ] **Step 3: Implement slider knob drag behavior**

JavaScript for interactive volume sliders:
- mousedown on knob → start drag
- mousemove → update fill width and knob position, calculate dB value, send `set_cue_volume` command
- mouseup → stop drag
- Click on track → snap knob to click position
- dB range: -60 to +6 (linear position mapped to dB)

- [ ] **Step 4: Implement WAV picker modal**

- Overlay + modal panel with search input and scrollable file list
- Populated from `state.wav_files`
- Filter list as user types
- Click file → select and close modal, send `set_cue_files` command
- Clear button → set slot to empty
- Cancel / Escape → close without change

- [ ] **Step 5: Implement Save button**

- Click Save → send `{cmd: "save"}` to WebSocket
- On receiving `{event: "saved"}` response → reset dirty counter, flash "Saved!" text
- Show unsaved change count in orange badge

- [ ] **Step 6: Verify manually**

Run game → open web tool → should see entity list populate. Click entity → cue editor shows. Adjust volume slider → hear volume change in-game. Assign WAV file via picker → plays new sound next trigger. Toggle pitch randomize → hear pitch variation change. Click Save → files written.

- [ ] **Step 7: Commit**

```bash
git add tools/live_audio_tool.html
git commit -m "feat(live-tool): entity tree, cue editor, WAV picker, save flow"
```

---

## Task 7: Web UI — Live Monitor + Preset Editor

**Files:**
- Modify: `tools/live_audio_tool.html`

- [ ] **Step 1: Build live activity feed**

Right panel top section:
- Listen for `cue_fired` events — add/update entry showing entity.cue name + fire count
- Green dot for recently-fired, fades after 2 seconds of inactivity
- Show "loop" indicator for entries in `_looping_cues`
- Listen for `voice_count` events — update counts in real-time
- Sort by most recently active

- [ ] **Step 2: Build attenuation preset editor**

Right panel bottom section:
- List all presets from state
- Click preset → expand to show editable fields (model dropdown, unit_size, max_distance, filter_cutoff_hz, filter_db, panning_strength)
- Each field sends `set_attenuation_preset` on change
- "Used by" line shows entities assigned to this preset
- "+ New" button → prompt for name, create with default values
- Delete button on non-default presets

- [ ] **Step 3: Verify manually**

Run game → open web tool → start a game round. Live activity feed should show cues firing with counts. Edit a preset → hear attenuation change on next sound trigger. Create a new preset → assign an entity to it.

- [ ] **Step 4: Commit**

```bash
git add tools/live_audio_tool.html
git commit -m "feat(live-tool): live activity monitor and attenuation preset editor"
```

---

## Task 8: Debug Overlay

**Files:**
- Create: `autoloads/audio_debug_overlay.gd`
- Modify: `project.godot` ([autoload] section)
- Modify: `autoloads/audio_manager.gd` (add accessor methods)

- [ ] **Step 1: Add accessor methods to AudioManager**

Add to `audio_manager.gd`:
```gdscript
## Returns array of { player: AudioStreamPlayer3D, file: String } for active 3D sounds.
func get_active_3d_emitters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for player in _sfx_players_3d:
		if player.playing:
			var file_name := ""
			if player.stream:
				file_name = player.stream.resource_path.get_file() if player.stream.resource_path else "unknown"
			result.append({"player": player, "file": file_name})
	return result


## Returns the attenuation preset for an entity (for debug radius visualization).
func get_entity_preset(entity_id: String) -> Dictionary:
	return _get_attenuation_for_entity(entity_id)
```

- [ ] **Step 2: Create audio_debug_overlay.gd**

Create `autoloads/audio_debug_overlay.gd`:
```gdscript
extends Node
## AudioDebugOverlay - Shows floating WAV filename labels at active 3D emitters.
## Toggle with F3. Attenuation radius toggle with Shift+F3.
## Only active when AudioManager.LIVE_TOOL_ENABLED is true.

var _enabled: bool = false
var _show_radius: bool = false
var _labels: Dictionary = {}  # player instance_id -> { label: Label3D, timer: float }
var _radius_meshes: Dictionary = {}  # player instance_id -> MeshInstance3D
const LINGER_TIME: float = 1.0


func _ready() -> void:
	if not AudioManager.LIVE_TOOL_ENABLED:
		set_process(false)
		set_process_input(false)
		return
	set_process(true)


func _input(event: InputEvent) -> void:
	if not AudioManager.LIVE_TOOL_ENABLED:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			if event.shift_pressed:
				_show_radius = not _show_radius
				_update_radius_visibility()
			else:
				_enabled = not _enabled
				if not _enabled:
					_clear_all()
				print("[AudioDebugOverlay] %s" % ("ON" if _enabled else "OFF"))


func _process(delta: float) -> void:
	if not _enabled:
		return

	var scene := get_tree().current_scene
	if not scene or not scene is Node3D:
		return

	var emitters := AudioManager.get_active_3d_emitters()
	var active_ids: Dictionary = {}

	for emitter in emitters:
		var player: AudioStreamPlayer3D = emitter["player"]
		var file: String = emitter["file"]
		var pid: int = player.get_instance_id()
		active_ids[pid] = true

		if _labels.has(pid):
			# Update position and reset timer
			var entry: Dictionary = _labels[pid]
			entry["label"].global_position = player.global_position + Vector3(0, 1.5, 0)
			entry["label"].text = file
			entry["timer"] = LINGER_TIME
			# Update radius mesh position if visible
			if _radius_meshes.has(pid):
				_radius_meshes[pid].global_position = player.global_position
		else:
			# Create new label
			var label := Label3D.new()
			label.text = file
			label.font_size = 32
			label.pixel_size = 0.01
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.modulate = Color(1, 1, 1, 0.9)
			label.global_position = player.global_position + Vector3(0, 1.5, 0)
			scene.add_child(label)
			_labels[pid] = {"label": label, "timer": LINGER_TIME}

			# Create radius mesh if enabled
			if _show_radius:
				_create_radius_mesh(pid, player)

	# Update linger timers for labels not currently active
	var to_remove: Array[int] = []
	for pid in _labels:
		if not active_ids.has(pid):
			_labels[pid]["timer"] -= delta
			if _labels[pid]["timer"] <= 0.0:
				to_remove.append(pid)
			else:
				# Fade out
				var t: float = _labels[pid]["timer"] / LINGER_TIME
				_labels[pid]["label"].modulate.a = t

	for pid in to_remove:
		_remove_label(pid)


func _create_radius_mesh(pid: int, player: AudioStreamPlayer3D) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = player.max_distance
	sphere.height = player.max_distance * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.3, 0.9, 0.5, 0.05)
	mat.cull_mode = BaseMaterial3D.CULL_FRONT  # See inside the sphere
	mat.no_depth_test = true
	mesh_instance.material_override = mat
	mesh_instance.global_position = player.global_position
	scene.add_child(mesh_instance)
	_radius_meshes[pid] = mesh_instance


func _update_radius_visibility() -> void:
	if _show_radius:
		# Create radius meshes for all current labels
		for pid in _labels:
			if not _radius_meshes.has(pid):
				# Need the player reference — check if it's still valid
				var obj := instance_from_id(pid)
				if obj and obj is AudioStreamPlayer3D:
					_create_radius_mesh(pid, obj)
	else:
		# Remove all radius meshes
		for pid in _radius_meshes:
			if is_instance_valid(_radius_meshes[pid]):
				_radius_meshes[pid].queue_free()
		_radius_meshes.clear()


func _remove_label(pid: int) -> void:
	if _labels.has(pid):
		if is_instance_valid(_labels[pid]["label"]):
			_labels[pid]["label"].queue_free()
		_labels.erase(pid)
	if _radius_meshes.has(pid):
		if is_instance_valid(_radius_meshes[pid]):
			_radius_meshes[pid].queue_free()
		_radius_meshes.erase(pid)


func _clear_all() -> void:
	for pid in _labels.keys():
		_remove_label(pid)
	_labels.clear()
	_radius_meshes.clear()
```

- [ ] **Step 3: Register autoload in project.godot**

Add to the `[autoload]` section:
```ini
AudioDebugOverlay="*res://autoloads/audio_debug_overlay.gd"
```

- [ ] **Step 4: Verify manually**

Run the game (F5). Start a round. Press F3 — floating WAV filenames should appear above entities when they fire sounds. Labels should linger for 1 second after the sound finishes. Press Shift+F3 — translucent spheres appear showing attenuation radius. Press F3 again — all labels disappear.

- [ ] **Step 5: Commit**

```bash
git add autoloads/audio_debug_overlay.gd autoloads/audio_manager.gd project.godot
git commit -m "feat(audio): add debug overlay with emitter labels and attenuation radius"
```

---

## Task 9: Integration Testing + Category Data

**Files:**
- Modify: `autoloads/audio_manager.gd` — add entity category info to state snapshot
- Modify: `tools/live_audio_tool.html` — use category data for entity tree grouping

- [ ] **Step 1: Add entity category/type data to WebSocket state**

The web UI needs to know entity categories (Towers-Offensive, Enemies, etc.) to build the tree. The game already has this data via `GameData`. Add to `_ws_build_state()`:

```gdscript
func _ws_build_entity_categories() -> Array:
	var categories: Array = []
	categories.append({"label": "CENTRAL TOWER", "entities": _wrap_ids(["central_tower"], "central_tower")})
	categories.append({"label": "TOWERS - Offensive", "entities": _wrap_ids(GameData.get_all_towers_offensive(), "tower")})
	categories.append({"label": "TOWERS - Resource", "entities": _wrap_ids(GameData.get_all_towers_resource(), "tower")})
	categories.append({"label": "TOWERS - Support", "entities": _wrap_ids(GameData.get_all_towers_support(), "tower")})
	categories.append({"label": "UNITS - Drone", "entities": _wrap_ids(GameData.get_all_units_drone(), "unit")})
	categories.append({"label": "UNITS - Mech", "entities": _wrap_ids(GameData.get_all_units_mech(), "unit")})
	categories.append({"label": "UNITS - Vehicle", "entities": _wrap_ids(GameData.get_all_units_war(), "unit")})
	categories.append({"label": "ENEMIES", "entities": _wrap_ids(GameData.get_all_enemies(), "enemy")})
	categories.append({"label": "PRODUCTION", "entities": _wrap_ids(GameData.get_all_production_buildings(), "production")})
	categories.append({"label": "BARRIERS", "entities": _wrap_ids(GameData.get_all_barriers(), "barrier")})
	# Remove empty categories
	return categories.filter(func(c): return not c["entities"].is_empty())


func _wrap_ids(ids, type: String) -> Array:
	var result: Array = []
	for id in ids:
		result.append({"id": id, "type": type})
	return result
```

Add `"categories": _ws_build_entity_categories()` to the `_ws_build_state()` return dictionary.

- [ ] **Step 2: Update web UI entity tree to use category data**

In the JavaScript `handleState(data)` function, use `data.categories` to build the tree with proper collapsible groups matching the mockup layout.

- [ ] **Step 3: Full end-to-end test**

Run the game → open `tools/live_audio_tool.html` in browser → verify:
1. Connection auto-establishes, badge shows "CONNECTED"
2. Entity tree shows categorized groups matching the game's data
3. Select an entity → cue editor populates with correct cues
4. Adjust volume slider → hear change in-game immediately
5. Toggle pitch randomize → hear variation change
6. Open WAV picker → search and assign a file → next trigger plays new file
7. Toggle solo on an entity → only that entity's sounds play
8. Toggle mute on a cue → that cue stops playing
9. Live monitor shows cues firing with counts
10. Create an attenuation preset → assign to entity → hear spatial change
11. Press F3 in-game → emitter labels appear
12. Click Save → files written, counter resets
13. Disconnect game → tool shows "Disconnected", auto-reconnects when game restarts

- [ ] **Step 4: Commit**

```bash
git add autoloads/audio_manager.gd tools/live_audio_tool.html
git commit -m "feat(live-tool): entity categories and integration polish"
```

---

## Summary

| Task | Component | Estimated Steps |
|------|-----------|----------------|
| 1 | Attenuation Presets | 8 steps |
| 2 | Per-Cue Voices + Solo/Mute | 7 steps |
| 3 | Looping Cue Playback | 8 steps |
| 4 | WebSocket Server | 11 steps |
| 5 | Web UI Shell + Connection | 3 steps |
| 6 | Web UI Entity Tree + Cue Editor | 7 steps |
| 7 | Web UI Live Monitor + Presets | 4 steps |
| 8 | Debug Overlay | 5 steps |
| 9 | Integration + Categories | 4 steps |

Tasks 1-4 modify `audio_manager.gd` sequentially (each builds on the previous). Tasks 5-7 build the web UI in stages. Task 8 adds the debug overlay. Task 9 ties everything together.
