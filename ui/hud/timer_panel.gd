extends PanelContainer
## TimerPanel - Shows game time (MM:SS) and game speed buttons (0.75x, 1x, 1.25x).
## Speed buttons emit GameBus.game_speed_changed via GameState.set_game_speed().

var time_label: Label
var speed_slow_btn: Button
var speed_normal_btn: Button
var speed_fast_btn: Button
var speed_faster_btn: Button
var speed_fastest_btn: Button

var _current_speed: float = 1.0

const SPEED_SLOW: float = 0.75
const SPEED_NORMAL: float = 1.0
const SPEED_FAST: float = 1.25
const SPEED_FASTER: float = 1.5
const SPEED_FASTEST: float = 2.0


func _ready() -> void:
	_build_ui()
	_connect_signals()
	_update_speed_buttons()


func _build_ui() -> void:
	name = "TimerPanel"
	custom_minimum_size = Vector2(400, 40)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.border_color = Color(0.2, 0.5, 0.3, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	add_child(hbox)

	# Time display
	var time_container := HBoxContainer.new()
	time_container.add_theme_constant_override("separation", 4)
	hbox.add_child(time_container)

	var clock_icon := Label.new()
	clock_icon.text = "Time:"
	clock_icon.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	clock_icon.add_theme_font_size_override("font_size", 14)
	time_container.add_child(clock_icon)

	time_label = Label.new()
	time_label.text = "00:00"
	time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	time_label.add_theme_font_size_override("font_size", 16)
	time_container.add_child(time_label)

	# Separator
	var sep := VSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	hbox.add_child(sep)

	# Speed buttons
	var speed_container := HBoxContainer.new()
	speed_container.add_theme_constant_override("separation", 4)
	hbox.add_child(speed_container)

	speed_slow_btn = _create_speed_button("0.75x", SPEED_SLOW)
	speed_container.add_child(speed_slow_btn)

	speed_normal_btn = _create_speed_button("1x", SPEED_NORMAL)
	speed_container.add_child(speed_normal_btn)

	speed_fast_btn = _create_speed_button("1.25x", SPEED_FAST)
	speed_container.add_child(speed_fast_btn)

	speed_faster_btn = _create_speed_button("1.5x", SPEED_FASTER)
	speed_container.add_child(speed_faster_btn)

	speed_fastest_btn = _create_speed_button("2x", SPEED_FASTEST)
	speed_container.add_child(speed_fastest_btn)


func _create_speed_button(text: String, speed: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(50, 24)
	btn.add_theme_font_size_override("font_size", 12)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	normal_style.border_color = Color(0.3, 0.3, 0.4)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(3)
	normal_style.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.3, 0.2, 0.9)
	pressed_style.border_color = Color(0.2, 0.8, 0.4)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.pressed.connect(_on_speed_pressed.bind(speed))
	return btn


func _connect_signals() -> void:
	GameBus.game_speed_changed.connect(_on_game_speed_changed)


func _process(_delta: float) -> void:
	if GameState.is_game_active:
		time_label.text = GameState.get_game_time_formatted()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("speed_slow"):
		_on_speed_pressed(SPEED_SLOW)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("speed_normal"):
		_on_speed_pressed(SPEED_NORMAL)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("speed_fast"):
		_on_speed_pressed(SPEED_FAST)
		get_viewport().set_input_as_handled()


func _on_speed_pressed(speed: float) -> void:
	GameState.set_game_speed(speed)


func _on_game_speed_changed(speed: float) -> void:
	_current_speed = speed
	_update_speed_buttons()


func _update_speed_buttons() -> void:
	_set_button_active(speed_slow_btn, _current_speed == SPEED_SLOW)
	_set_button_active(speed_normal_btn, _current_speed == SPEED_NORMAL)
	_set_button_active(speed_fast_btn, _current_speed == SPEED_FAST)
	_set_button_active(speed_faster_btn, _current_speed == SPEED_FASTER)
	_set_button_active(speed_fastest_btn, _current_speed == SPEED_FASTEST)


func _set_button_active(btn: Button, active: bool) -> void:
	if active:
		var active_style := StyleBoxFlat.new()
		active_style.bg_color = Color(0.1, 0.35, 0.2, 0.95)
		active_style.border_color = Color(0.2, 0.8, 0.4)
		active_style.set_border_width_all(1)
		active_style.set_corner_radius_all(3)
		active_style.set_content_margin_all(4)
		btn.add_theme_stylebox_override("normal", active_style)
		btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		normal_style.border_color = Color(0.3, 0.3, 0.4)
		normal_style.set_border_width_all(1)
		normal_style.set_corner_radius_all(3)
		normal_style.set_content_margin_all(4)
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
