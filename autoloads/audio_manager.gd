extends Node
## AudioManager - Hook-based audio system with sequential music playlist,
## SFX assignment playback (random containers + pitch randomization),
## 3D positional audio with distance attenuation and voice limiting.

const MAX_CONCURRENT_SFX_2D: int = 8
const MAX_CONCURRENT_SFX_3D: int = 32
const MAX_VOICES_PER_CUE: int = 3


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

# Voice limiting: cue_key -> Array of AudioStreamPlayer3D currently playing that cue
var _active_voices: Dictionary = {}

# Node3D anchor for 3D players (sits at world origin; players are repositioned per-play)
var _sfx_3d_anchor: Node3D = null


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
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(MetaProgress.sfx_volume))
		AudioServer.set_bus_mute(sfx_idx, MetaProgress.sfx_volume <= 0.0)


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


func _get_attenuation_for_entity(entity_id: String) -> Dictionary:
	var preset_name: String = _entity_attenuation.get(entity_id, "default")
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
		_configure_3d_player(player, _get_attenuation_for_entity(entity_id))
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

	# If at voice limit, stop the oldest (first in array)
	while voices.size() >= max_voices:
		var oldest: AudioStreamPlayer3D = voices[0]
		voices.remove_at(0)
		if is_instance_valid(oldest) and oldest.playing:
			oldest.stop()

	# Find a free player from the pool
	var player: AudioStreamPlayer3D = null
	for p in _sfx_players_3d:
		if not p.playing:
			player = p
			break
	if not player:
		return null

	voices.append(player)
	return player


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
		return _play_cue_data_3d(entity_cues[action], world_pos, cue_key, entity_id)

	var cue: String = ACTION_TO_CUE.get(action, "")
	if not cue.is_empty() and entity_cues.has(cue) and _cue_has_files(entity_cues[cue]):
		cue_key = entity_id + "." + cue
		return _play_cue_data_3d(entity_cues[cue], world_pos, cue_key, entity_id)

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

	# Derive a cue key from the hook_id for voice limiting
	var cue_key: String = hook_id
	var player := _acquire_3d_player(cue_key)
	if not player:
		return
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


# --- Auto UI Sounds ---


func _on_node_added_ui(node: Node) -> void:
	if node is BaseButton:
		node.mouse_entered.connect(_play_ui_hover)
		node.pressed.connect(_play_ui_click)


func _play_ui_hover() -> void:
	play("ui.button_hover")


func _play_ui_click() -> void:
	play("ui.button_click")
