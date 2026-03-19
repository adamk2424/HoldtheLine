extends Control
## SurgeAlert - Big warning text that appears on surge/boss events.
## "SURGE INCOMING!" on GameBus.surge_started, fades after 3 seconds.
## Boss alert on GameBus.boss_spawned.

var _alert_label: Label
var _sub_label: Label
var _fade_tween: Tween = null

const FADE_DURATION: float = 3.0


func _ready() -> void:
	_build_ui()
	_connect_signals()
	visible = false


func _build_ui() -> void:
	name = "SurgeAlert"
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	anchor_top = 0.15
	anchor_bottom = 0.15
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -300
	offset_right = 300
	offset_top = 0
	offset_bottom = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	_alert_label = Label.new()
	_alert_label.text = "SURGE INCOMING!"
	_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert_label.add_theme_font_size_override("font_size", 42)
	_alert_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	_alert_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_alert_label.add_theme_constant_override("shadow_offset_x", 2)
	_alert_label.add_theme_constant_override("shadow_offset_y", 2)
	_alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_alert_label)

	_sub_label = Label.new()
	_sub_label.text = "Prepare your defenses!"
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.add_theme_font_size_override("font_size", 20)
	_sub_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_sub_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_sub_label.add_theme_constant_override("shadow_offset_x", 1)
	_sub_label.add_theme_constant_override("shadow_offset_y", 1)
	_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_sub_label)


func _connect_signals() -> void:
	GameBus.surge_started.connect(_on_surge_started)
	GameBus.boss_spawned.connect(_on_boss_spawned)
	GameBus.surge_ended.connect(_on_surge_ended)


func _show_alert(main_text: String, sub_text: String, main_color: Color) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_alert_label.text = main_text
	_alert_label.add_theme_color_override("font_color", main_color)
	_sub_label.text = sub_text
	visible = true
	modulate.a = 1.0

	_fade_tween = create_tween()
	_fade_tween.tween_interval(1.5)
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION - 1.5)
	_fade_tween.tween_callback(func() -> void: visible = false)


func _on_surge_started() -> void:
	_show_alert("SURGE INCOMING!", "Prepare your defenses!", Color(1.0, 0.2, 0.2))
	GameBus.audio_play.emit("ui.alert_surge")


func _on_boss_spawned(_boss: Node) -> void:
	_show_alert("BOSS DETECTED!", "Massive hostile signature detected!", Color(1.0, 0.1, 0.5))
	GameBus.audio_play.emit("ui.alert_boss")


func _on_surge_ended() -> void:
	_show_alert("SURGE CLEARED", "Well defended!", Color(0.3, 1.0, 0.4))
