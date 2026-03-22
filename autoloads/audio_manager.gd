extends Node
## AudioManager - Hook-based audio system with sequential music playlist,
## SFX assignment playback (random containers + pitch randomization),
## 3D positional audio with distance attenuation and voice limiting.

const MAX_CONCURRENT_SFX_2D: int = 8
const MAX_CONCURRENT_SFX_3D: int = 65
const MAX_VOICES_PER_CUE: int = 3

const LIVE_TOOL_ENABLED: bool = true
const LIVE_TOOL_PORT: int = 8090


const MUSIC_TRACKS: Array[String] = [
	"res://audio/music/Starcraft Protoss Theme 1.mp3",
	"res://audio/music/Starcraft Protoss Theme 2.mp3",
	"res://audio/music/Starcraft Protoss Theme 3.mp3",
]

# Maps hook action names to AudioSetup cue names for automatic bridging
const ACTION_TO_CUE := {
	# Common
	"fire": "attack",
	"attack": "attack",
	"build_complete": "placement",
	"destroyed": "death",
	"death": "death",
	"upgraded": "upgrade",
	"sold": "sell",
	"spawn": "spawn",
	# Tower main abilities → attack cue
	"harvest": "attack",
	"drain": "attack",
	"heal": "attack",
	"buff": "attack",
	# Unit abilities → generic slots
	"repair_beam": "ability_1",
	"shield_projection": "ability_1",
	"shield_activate": "ability_1",
	"disruption_field": "ability_1",
	"fortify": "ability_1",
	"overdrive": "ability_1",
	"deploy": "ability_1",
	"shatter_shell": "ability_2",
	"undeploy": "ability_2",
}

var _sfx_players_2d: Array[AudioStreamPlayer] = []
var _sfx_players_3d: Array[AudioStreamPlayer3D] = []
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _audio_cache: Dictionary = {}
var _current_track_index: int = 0
var _music_active: bool = false
var _sfx_assignments: Dictionary = {}
var _attenuation_presets: Dictionary = {}
var _entity_attenuation: Dictionary = {}  # entity_id -> preset_name

# Solo/Mute: runtime-only, never saved. Keyed by entity_id or entity_id.cue_id
var _soloed: Dictionary = {}
var _muted: Dictionary = {}

# Looping cue tracking: "entity_id.cue_id" -> { player, state, cue_data, entity_id, cue_key, world_pos }
var _looping_cues: Dictionary = {}
# Reserved players (looping): player instance ID -> true. Excluded from general pool.
var _reserved_players: Dictionary = {}

# Voice limiting: cue_key -> Array of AudioStreamPlayer3D currently playing that cue
var _active_voices: Dictionary = {}

# Node3D anchor for 3D players (sits at world origin; players are repositioned per-play)
var _sfx_3d_anchor: Node3D = null

# Live tool WebSocket server
var _ws_server: TCPServer = null
var _ws_peers: Array = []  # Array of WebSocketPeer
var _ws_pending_state: Array = []  # WebSocketPeers waiting for STATE_OPEN to send initial state
var _ws_voice_timer: float = 0.0
var _wav_file_list: Array[String] = []


func _ready() -> void:
	_setup_audio_buses()
	_load_sfx_assignments()
	_load_attenuation_presets()
	_load_entity_attenuation()

	# Create audio player pools
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -12.0
	add_child(_music_player)
	_music_player.finished.connect(_on_music_track_finished)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Master"
	add_child(_ambience_player)

	# 2D SFX pool for UI / non-positional sounds
	for i in MAX_CONCURRENT_SFX_2D:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players_2d.append(player)

	# 3D SFX pool for world / positional sounds
	_sfx_3d_anchor = Node3D.new()
	_sfx_3d_anchor.name = "SFX3DAnchor"
	add_child(_sfx_3d_anchor)

	for i in MAX_CONCURRENT_SFX_3D:
		var player := AudioStreamPlayer3D.new()
		player.bus = "SFX"
		_configure_3d_player(player)
		_sfx_3d_anchor.add_child(player)
		_sfx_players_3d.append(player)

	GameBus.audio_play.connect(_on_audio_play)
	GameBus.audio_play_3d.connect(_on_audio_play_3d)
	GameBus.audio_stop.connect(_on_audio_stop)
	GameBus.game_started.connect(_on_game_started)
	GameBus.game_over.connect(_on_game_over)

	# Auto-connect hover and click sounds to every BaseButton added to the scene tree
	get_tree().node_added.connect(_on_node_added_ui)

	if LIVE_TOOL_ENABLED:
		_start_ws_server()


func _start_ws_server() -> void:
	_ws_server = TCPServer.new()
	var err := _ws_server.listen(LIVE_TOOL_PORT, "0.0.0.0")
	if err != OK:
		push_warning("[AudioManager] Failed to start WebSocket server on port %d" % LIVE_TOOL_PORT)
		_ws_server = null
		return
	_scan_wav_files()
	print("[AudioManager] Live tool server listening on port %d" % LIVE_TOOL_PORT)


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


func _configure_3d_player(player: AudioStreamPlayer3D, preset: Dictionary = {}) -> void:
	if preset.is_empty() and _attenuation_presets.has("default"):
		preset = _attenuation_presets["default"]
	player.attenuation_model = _atten_model_from_string(preset.get("model", "inverse_square"))
	player.unit_size = preset.get("unit_size", 30.0)
	player.max_distance = preset.get("max_distance", 150.0)
	player.attenuation_filter_cutoff_hz = preset.get("filter_cutoff_hz", 10000.0)
	player.attenuation_filter_db = preset.get("filter_db", -18.0)
	player.panning_strength = preset.get("panning_strength", 0.8)
	player.max_db = 0.0
	player.max_polyphony = 1


func _setup_audio_buses() -> void:
	# Create Music bus under Master if it doesn't exist
	if AudioServer.get_bus_index("Music") == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")

	# Create SFX bus under Master if it doesn't exist
	if AudioServer.get_bus_index("SFX") == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

	apply_volume_settings()


func apply_volume_settings() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")

	if master_idx != -1:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(MetaProgress.master_volume))
		AudioServer.set_bus_mute(master_idx, MetaProgress.master_volume <= 0.0)
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(MetaProgress.music_volume))
		AudioServer.set_bus_mute(music_idx, MetaProgress.music_volume <= 0.0)
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(MetaProgress.sfx_volume) - 6.0)
		AudioServer.set_bus_mute(sfx_idx, MetaProgress.sfx_volume <= 0.0)


func _process(delta: float) -> void:
	if not LIVE_TOOL_ENABLED or _ws_server == null:
		return
	_ws_poll(delta)


func _ws_poll(delta: float) -> void:
	# Accept new connections
	while _ws_server.is_connection_available():
		var tcp := _ws_server.take_connection()
		if tcp:
			var ws := WebSocketPeer.new()
			ws.accept_stream(tcp)
			_ws_peers.append(ws)
			_ws_pending_state.append(ws)
			print("[AudioManager] Live tool client connected")

	# Poll existing peers
	var i := _ws_peers.size() - 1
	while i >= 0:
		var ws: WebSocketPeer = _ws_peers[i]
		ws.poll()
		var state := ws.get_ready_state()

		if state == WebSocketPeer.STATE_OPEN:
			# Send initial state to newly connected peers
			if ws in _ws_pending_state:
				ws.send_text(JSON.stringify(_ws_build_state()))
				_ws_pending_state.erase(ws)
			while ws.get_available_packet_count() > 0:
				var pkt := ws.get_packet()
				_ws_handle_message(ws, pkt.get_string_from_utf8())
		elif state == WebSocketPeer.STATE_CLOSING:
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			_ws_peers.remove_at(i)
			_ws_pending_state.erase(ws)
			print("[AudioManager] Live tool client disconnected")
		i -= 1

	# Broadcast voice counts at ~4Hz
	_ws_voice_timer += delta
	if _ws_voice_timer >= 0.25:
		_ws_voice_timer = 0.0
		_ws_broadcast_voice_counts()


# --- Music Playlist ---


func start_music() -> void:
	if MUSIC_TRACKS.is_empty():
		return
	_current_track_index = 0
	_music_active = true
	_play_current_track()


func stop_music() -> void:
	_music_active = false
	_music_player.stop()


func _play_current_track() -> void:
	if not _music_active or MUSIC_TRACKS.is_empty():
		return
	var path: String = MUSIC_TRACKS[_current_track_index]
	var stream := _get_or_load_stream(path)
	if not stream:
		push_warning("[AudioManager] Failed to load music track: %s" % path)
		return
	_music_player.stream = stream
	_music_player.play()
	print("[AudioManager] Playing track %d: %s" % [_current_track_index + 1, path.get_file()])


func _on_music_track_finished() -> void:
	if not _music_active:
		return
	_current_track_index = (_current_track_index + 1) % MUSIC_TRACKS.size()
	_play_current_track()


func _on_game_started() -> void:
	start_music()


func _on_game_over(_survival_time: float) -> void:
	stop_music()


# --- SFX Assignments ---


func _load_sfx_assignments() -> void:
	var path := "res://data/sfx_assignments.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_sfx_assignments = json.data
		print("[AudioManager] Loaded SFX assignments for %d entities" % _sfx_assignments.size())


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


func _get_attenuation_for_hook(entity_id: String, cue_key: String) -> Dictionary:
	# Try specific cue_key first (e.g. "autocannon.attack"), then entity_id, then default
	var preset_name: String = ""
	if _entity_attenuation.has(cue_key):
		preset_name = _entity_attenuation[cue_key]
	elif _entity_attenuation.has(entity_id):
		preset_name = _entity_attenuation[entity_id]
	else:
		preset_name = "default"
	if _attenuation_presets.has(preset_name):
		return _attenuation_presets[preset_name]
	if _attenuation_presets.has("default"):
		return _attenuation_presets["default"]
	return {
		"model": "inverse_square",
		"unit_size": 15.0,
		"max_distance": 120.0,
		"filter_cutoff_hz": 10000.0,
		"filter_db": -18.0,
		"panning_strength": 0.8,
	}


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


static func _atten_model_from_string(model_name: String) -> AudioStreamPlayer3D.AttenuationModel:
	match model_name:
		"inverse_distance": return AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		"inverse_square": return AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		"logarithmic": return AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
		"disabled": return AudioStreamPlayer3D.ATTENUATION_DISABLED
	return AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE


## Play a sound cue from the SFX assignment system directly (non-positional).
func play_entity_sfx(entity_id: String, cue: String) -> bool:
	if not _sfx_assignments.has(entity_id):
		return false
	var entity_cues: Dictionary = _sfx_assignments[entity_id]
	if not entity_cues.has(cue):
		return false
	return _play_cue_data_2d(entity_cues[cue])


## Get roar parameters for an enemy (used by AI scripts).
func get_roar_params(entity_id: String) -> Dictionary:
	if not _sfx_assignments.has(entity_id):
		return {}
	var entity_cues: Dictionary = _sfx_assignments[entity_id]
	if not entity_cues.has("roar"):
		return {}
	var roar: Dictionary = entity_cues["roar"]
	return {
		"chance": roar.get("roar_chance", 10),
		"interval": roar.get("roar_interval", 10.0),
		"has_files": _cue_has_files(roar),
	}


func _cue_has_files(cue_data: Dictionary) -> bool:
	var files: Array = cue_data.get("files", [])
	for f in files:
		if f is String and not f.is_empty():
			return true
	return false


## Resolve cue data into a stream. Returns the stream and applies pitch/volume to the dict.
func _resolve_cue_stream(cue_data: Dictionary) -> AudioStream:
	var files: Array = cue_data.get("files", [])
	var valid: Array[String] = []
	for f in files:
		if f is String and not f.is_empty():
			valid.append(f)
	if valid.is_empty():
		return null
	var chosen: String = valid[randi() % valid.size()]
	return _get_or_load_stream(chosen)


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


func _apply_cue_params_2d(player: AudioStreamPlayer, cue_data: Dictionary) -> void:
	player.volume_db = cue_data.get("volume_db", 0.0)
	if cue_data.get("pitch_randomize", false):
		var cents: float = cue_data.get("pitch_cents", 50)
		player.pitch_scale = pow(2.0, randf_range(-cents, cents) / 1200.0)
	else:
		player.pitch_scale = 1.0


func _apply_cue_params_3d(player: AudioStreamPlayer3D, cue_data: Dictionary) -> void:
	player.volume_db = cue_data.get("volume_db", 0.0)
	if cue_data.get("pitch_randomize", false):
		var cents: float = cue_data.get("pitch_cents", 50)
		player.pitch_scale = pow(2.0, randf_range(-cents, cents) / 1200.0)
	else:
		player.pitch_scale = 1.0


func _play_cue_data_2d(cue_data: Dictionary) -> bool:
	var stream := _resolve_cue_stream(cue_data)
	if not stream:
		return false
	var player: AudioStreamPlayer = null
	for p in _sfx_players_2d:
		if not p.playing:
			player = p
			break
	if not player:
		return false
	player.stream = stream
	_apply_cue_params_2d(player, cue_data)
	player.play()
	return true


func _play_cue_data_3d(cue_data: Dictionary, world_pos: Vector3, cue_key: String, entity_id: String = "") -> bool:
	# Handle looping cues separately
	if cue_data.get("is_looping", false):
		return _play_looping_cue_3d(cue_data, world_pos, cue_key, entity_id)

	var stream := _resolve_cue_stream(cue_data)
	if not stream:
		return false

	# Voice limiting: enforce per-cue voice limit
	var max_v: int = cue_data.get("max_voices", MAX_VOICES_PER_CUE)
	var player := _acquire_3d_player(cue_key, max_v)
	if not player:
		return false

	# Apply entity-specific attenuation preset
	if not entity_id.is_empty():
		_configure_3d_player(player, _get_attenuation_for_hook(entity_id, cue_key))
	player.stream = stream
	player.global_position = world_pos
	_apply_cue_params_3d(player, cue_data)
	player.play()
	return true


## Get a free 3D player, enforcing the per-cue voice limit.
func _acquire_3d_player(cue_key: String, max_voices: int = MAX_VOICES_PER_CUE) -> AudioStreamPlayer3D:
	# Clean up finished voices for this cue
	if _active_voices.has(cue_key):
		var voices: Array = _active_voices[cue_key]
		var i := voices.size() - 1
		while i >= 0:
			var v: AudioStreamPlayer3D = voices[i]
			if not is_instance_valid(v) or not v.playing:
				voices.remove_at(i)
			i -= 1
	else:
		_active_voices[cue_key] = []

	var voices: Array = _active_voices[cue_key]

	# If at voice limit, reject the new sound (let existing voices finish)
	if voices.size() >= max_voices:
		return null

	# Find a free player from the pool (skip reserved looping players)
	var player: AudioStreamPlayer3D = null
	for p in _sfx_players_3d:
		if not p.playing and not _reserved_players.has(p.get_instance_id()):
			player = p
			break
	if not player:
		return null

	voices.append(player)
	return player


# --- Looping Cue Playback ---


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


## Bridge: try to resolve a hook_id through SFX assignments (2D, non-positional).
func _try_sfx_assignment_2d(hook_id: String) -> bool:
	var parts := hook_id.split(".")
	if parts.size() < 3:
		return false
	var entity_id: String = parts[1]
	var action: String = parts[2]

	if not _sfx_assignments.has(entity_id):
		return false

	var entity_cues: Dictionary = _sfx_assignments[entity_id]

	# Solo/mute check before playing
	var resolved_cue := action
	if not entity_cues.has(action):
		resolved_cue = ACTION_TO_CUE.get(action, "")
	if not _is_cue_allowed(entity_id, resolved_cue):
		return true  # Return true to prevent fallback to audio_hooks, but don't play

	if entity_cues.has(action) and _cue_has_files(entity_cues[action]):
		return _play_cue_data_2d(entity_cues[action])

	var cue: String = ACTION_TO_CUE.get(action, "")
	if not cue.is_empty() and entity_cues.has(cue) and _cue_has_files(entity_cues[cue]):
		return _play_cue_data_2d(entity_cues[cue])

	return false


## Bridge: try to resolve a hook_id through SFX assignments (3D, positional).
func _try_sfx_assignment_3d(hook_id: String, world_pos: Vector3) -> bool:
	var parts := hook_id.split(".")
	if parts.size() < 3:
		return false
	var entity_id: String = parts[1]
	var action: String = parts[2]

	if not _sfx_assignments.has(entity_id):
		return false

	var entity_cues: Dictionary = _sfx_assignments[entity_id]
	var cue_key: String = entity_id + "." + action

	# Solo/mute check before playing
	var resolved_cue := action
	if not entity_cues.has(action):
		resolved_cue = ACTION_TO_CUE.get(action, "")
	if not _is_cue_allowed(entity_id, resolved_cue):
		return true  # Return true to prevent fallback to audio_hooks, but don't play

	if entity_cues.has(action) and _cue_has_files(entity_cues[action]):
		var result := _play_cue_data_3d(entity_cues[action], world_pos, cue_key, entity_id)
		if result:
			_ws_emit_cue_fired(entity_id, cue_key, "", world_pos)
		return result

	var cue: String = ACTION_TO_CUE.get(action, "")
	if not cue.is_empty() and entity_cues.has(cue) and _cue_has_files(entity_cues[cue]):
		cue_key = entity_id + "." + cue
		var result := _play_cue_data_3d(entity_cues[cue], world_pos, cue_key, entity_id)
		if result:
			_ws_emit_cue_fired(entity_id, cue_key, "", world_pos)
		return result

	return false


# --- Hook-based Audio ---


## Play a non-positional sound (UI, music, ambience).
func play(hook_id: String) -> void:
	# Try SFX assignments first (supports random containers + pitch)
	if _try_sfx_assignment_2d(hook_id):
		return

	# Fall back to audio_hooks.json single-file paths
	var path := GameData.get_audio_hook(hook_id)
	if path.is_empty():
		return

	var stream := _get_or_load_stream(path)
	if not stream:
		return

	if hook_id.begins_with("music."):
		_music_player.stream = stream
		_music_player.play()
	elif hook_id.begins_with("ambience."):
		_ambience_player.stream = stream
		_ambience_player.play()
	else:
		_play_sfx_2d(stream)


## Play a 3D positional sound at a world position.
func play_at(hook_id: String, world_pos: Vector3) -> void:
	# Try SFX assignments first (supports random containers + pitch)
	if _try_sfx_assignment_3d(hook_id, world_pos):
		return

	# Fall back to audio_hooks.json single-file paths
	var path := GameData.get_audio_hook(hook_id)
	if path.is_empty():
		return

	var stream := _get_or_load_stream(path)
	if not stream:
		return

	# Derive entity_id and cue key from the hook_id
	var cue_key: String = hook_id
	var entity_id: String = hook_id.get_slice(".", 0)
	var player := _acquire_3d_player(cue_key)
	if not player:
		return
	_configure_3d_player(player, _get_attenuation_for_hook(entity_id, cue_key))
	player.stream = stream
	player.global_position = world_pos
	player.volume_db = 0.0
	player.pitch_scale = 1.0
	player.play()


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


func _play_sfx_2d(stream: AudioStream) -> void:
	for player in _sfx_players_2d:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# All players busy - skip this sound


func _get_or_load_stream(path: String) -> AudioStream:
	if _audio_cache.has(path):
		return _audio_cache[path]
	if not FileAccess.file_exists(path):
		return null
	var stream := load(path) as AudioStream
	if not stream and path.ends_with(".wav"):
		stream = _load_wav_runtime(path)
	if stream:
		_audio_cache[path] = stream
	return stream


func _load_wav_runtime(path: String) -> AudioStreamWAV:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	# Validate RIFF/WAVE header
	if file.get_buffer(4).get_string_from_ascii() != "RIFF":
		return null
	file.get_32()  # file size
	if file.get_buffer(4).get_string_from_ascii() != "WAVE":
		return null

	var bits_per_sample := 16
	var mix_rate := 44100
	var stereo := false
	var raw_data := PackedByteArray()

	# Parse chunks
	while file.get_position() < file.get_length():
		var chunk_id := file.get_buffer(4).get_string_from_ascii()
		var chunk_size := file.get_32()

		if chunk_id == "fmt ":
			file.get_16()  # audio format (1 = PCM)
			var channels := file.get_16()
			mix_rate = file.get_32()
			file.get_32()  # byte rate
			file.get_16()  # block align
			bits_per_sample = file.get_16()
			stereo = channels == 2
			var fmt_extra := chunk_size - 16
			if fmt_extra > 0:
				file.get_buffer(fmt_extra)
		elif chunk_id == "data":
			raw_data = file.get_buffer(chunk_size)
		else:
			file.get_buffer(chunk_size)

		# Chunks are word-aligned
		if chunk_size % 2 != 0 and file.get_position() < file.get_length():
			file.get_8()

	var format := AudioStreamWAV.FORMAT_16_BITS
	var final_data := raw_data

	if bits_per_sample == 8:
		format = AudioStreamWAV.FORMAT_8_BITS
	elif bits_per_sample == 24:
		# Convert 24-bit to 16-bit by taking the upper 2 bytes of each 3-byte sample
		format = AudioStreamWAV.FORMAT_16_BITS
		var sample_count := raw_data.size() / 3
		final_data = PackedByteArray()
		final_data.resize(sample_count * 2)
		for i in sample_count:
			var src := i * 3
			var dst := i * 2
			# Take high 2 bytes of 24-bit LE sample (bytes [1] and [2])
			final_data[dst] = raw_data[src + 1]
			final_data[dst + 1] = raw_data[src + 2]
	elif bits_per_sample == 32:
		# Convert 32-bit to 16-bit by taking the upper 2 bytes of each 4-byte sample
		format = AudioStreamWAV.FORMAT_16_BITS
		var sample_count := raw_data.size() / 4
		final_data = PackedByteArray()
		final_data.resize(sample_count * 2)
		for i in sample_count:
			var src := i * 4
			var dst := i * 2
			final_data[dst] = raw_data[src + 2]
			final_data[dst + 1] = raw_data[src + 3]

	var stream := AudioStreamWAV.new()
	stream.format = format
	stream.mix_rate = mix_rate
	stream.stereo = stereo
	stream.data = final_data
	return stream


func _on_audio_play(hook_id: String) -> void:
	play(hook_id)


func _on_audio_play_3d(hook_id: String, world_pos: Vector3) -> void:
	play_at(hook_id, world_pos)


func _on_audio_stop(hook_id: String) -> void:
	stop(hook_id)


# --- WebSocket Server: State & Commands ---


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
		"categories": _ws_build_entity_categories(),
	}


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
	return categories.filter(func(c): return not c["entities"].is_empty())


func _wrap_ids(ids, type: String) -> Array:
	var result: Array = []
	for id in ids:
		result.append({"id": id, "type": type})
	return result


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
	var key: String = msg.get("key", "files")
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
	var value_linear: float = msg.get("value", 1.0)
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
	var cue_data: Dictionary = entity_cues[cue].duplicate(true)
	cue_data["volume_db"] = 0.0
	_play_cue_data_2d(cue_data)
	_ws_emit_cue_fired(entity, entity + "." + cue, "")


func _ws_cmd_save() -> void:
	var file := FileAccess.open("res://data/sfx_assignments.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_sfx_assignments, "\t"))
		file = null
	file = FileAccess.open("res://data/attenuation_presets.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_attenuation_presets, "\t"))
		file = null
	file = FileAccess.open("res://data/entity_attenuation.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_entity_attenuation, "\t"))
		file = null
	print("[AudioManager] Live tool: saved all audio data")
	_ws_broadcast({"event": "saved"})


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
	for cue_key in _looping_cues:
		counts[cue_key + " (loop)"] = 1
	_ws_broadcast({"event": "voice_count", "counts": counts})


func _ws_emit_cue_fired(entity_id: String, cue_key: String, file_path: String, world_pos: Variant = null) -> void:
	if not LIVE_TOOL_ENABLED or _ws_peers.is_empty():
		return
	var data := {"event": "cue_fired", "entity": entity_id, "cue": cue_key, "file": file_path.get_file()}
	if world_pos is Vector3:
		data["position"] = {"x": world_pos.x, "y": world_pos.y, "z": world_pos.z}
	_ws_broadcast(data)


# --- Auto UI Sounds ---


func _on_node_added_ui(node: Node) -> void:
	if node is BaseButton:
		node.mouse_entered.connect(_play_ui_hover)
		node.pressed.connect(_play_ui_click)


func _play_ui_hover() -> void:
	play("ui.button_hover")


func _play_ui_click() -> void:
	play("ui.button_click")


# --- Debug Overlay Accessors ---


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
	return _get_attenuation_for_hook(entity_id, "")
