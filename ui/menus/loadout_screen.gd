extends Control
## LoadoutScreen - Item management interface for unlocks, purchases, and loadout configuration.
## Provides browsing by rarity, purchase interface, and 3-slot loadout management.

signal loadout_screen_closed()

# --- UI Elements ---
var _main_container: HSplitContainer
var _item_browser: Control
var _loadout_panel: Control

# Item Browser
var _rarity_tabs: TabContainer
var _item_grids: Dictionary = {}  # rarity -> GridContainer
var _item_buttons: Dictionary = {}  # item_id -> ItemButton

# Loadout Panel
var _loadout_slots: Array[Control] = []
var _tech_points_label: Label
var _equipped_effects_list: RichTextLabel

# Item Details
var _details_panel: PanelContainer
var _item_icon: TextureRect
var _item_name: Label
var _item_description: Label
var _item_effects: RichTextLabel
var _item_cost: Label
var _purchase_button: Button
var _unlock_progress: RichTextLabel

var _selected_item_id: String = ""


func _ready() -> void:
	_build_ui()
	_connect_signals()
	_refresh_all()


func _build_ui() -> void:
	name = "LoadoutScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main container
	_main_container = HSplitContainer.new()
	_main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_container.add_theme_constant_override("separation", 20)
	add_child(_main_container)

	# Left side: Item browser
	_build_item_browser()
	
	# Right side: Loadout and details
	_build_loadout_panel()

	# Back button
	var back_button := Button.new()
	back_button.text = "< Back to Main Menu"
	back_button.position = Vector2(20, 20)
	back_button.size = Vector2(200, 40)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)


func _build_item_browser() -> void:
	var browser_container := VBoxContainer.new()
	browser_container.custom_minimum_size = Vector2(800, 600)
	_main_container.add_child(browser_container)

	# Title
	var title := Label.new()
	title.text = "Item Collection"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	browser_container.add_child(title)

	# Tech points display
	_tech_points_label = Label.new()
	_tech_points_label.text = "Tech Points: 0"
	_tech_points_label.add_theme_font_size_override("font_size", 18)
	_tech_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	browser_container.add_child(title)

	# Rarity tabs
	_rarity_tabs = TabContainer.new()
	_rarity_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	browser_container.add_child(_rarity_tabs)

	var rarities: Array[String] = ["common", "uncommon", "rare", "epic", "legendary"]
	for rarity: String in rarities:
		var tab_content := ScrollContainer.new()
		tab_content.name = rarity.capitalize()
		
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		tab_content.add_child(grid)
		
		_item_grids[rarity] = grid
		_rarity_tabs.add_child(tab_content)


func _build_loadout_panel() -> void:
	var right_container := VBoxContainer.new()
	right_container.custom_minimum_size = Vector2(400, 600)
	_main_container.add_child(right_container)

	# Loadout section
	var loadout_title := Label.new()
	loadout_title.text = "Active Loadout"
	loadout_title.add_theme_font_size_override("font_size", 20)
	loadout_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_container.add_child(loadout_title)

	var loadout_container := HBoxContainer.new()
	loadout_container.alignment = BoxContainer.ALIGNMENT_CENTER
	loadout_container.add_theme_constant_override("separation", 15)
	right_container.add_child(loadout_container)

	# Create 3 loadout slots
	for i in range(3):
		var slot := _create_loadout_slot(i)
		_loadout_slots.append(slot)
		loadout_container.add_child(slot)

	# Effects summary
	var effects_title := Label.new()
	effects_title.text = "Active Effects"
	effects_title.add_theme_font_size_override("font_size", 18)
	right_container.add_child(effects_title)

	_equipped_effects_list = RichTextLabel.new()
	_equipped_effects_list.custom_minimum_size = Vector2(380, 120)
	_equipped_effects_list.fit_content = true
	right_container.add_child(_equipped_effects_list)

	# Item details panel
	_build_details_panel(right_container)


func _create_loadout_slot(slot_index: int) -> Control:
	var slot_container := VBoxContainer.new()
	
	var slot_button := Button.new()
	slot_button.custom_minimum_size = Vector2(100, 100)
	slot_button.text = "Empty\nSlot %d" % (slot_index + 1)
	slot_button.pressed.connect(_on_loadout_slot_pressed.bind(slot_index))
	
	var unequip_button := Button.new()
	unequip_button.text = "Remove"
	unequip_button.custom_minimum_size = Vector2(100, 30)
	unequip_button.pressed.connect(_on_unequip_pressed.bind(slot_index))
	
	slot_container.add_child(slot_button)
	slot_container.add_child(unequip_button)
	
	return slot_container


func _build_details_panel(parent: VBoxContainer) -> void:
	_details_panel = PanelContainer.new()
	_details_panel.custom_minimum_size = Vector2(380, 300)
	parent.add_child(_details_panel)

	var details_content := VBoxContainer.new()
	_details_panel.add_child(details_content)

	# Item icon and name
	var header := HBoxContainer.new()
	details_content.add_child(header)

	_item_icon = TextureRect.new()
	_item_icon.custom_minimum_size = Vector2(64, 64)
	_item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	header.add_child(_item_icon)

	var name_container := VBoxContainer.new()
	name_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_container)

	_item_name = Label.new()
	_item_name.add_theme_font_size_override("font_size", 18)
	name_container.add_child(_item_name)

	_item_cost = Label.new()
	_item_cost.add_theme_font_size_override("font_size", 14)
	name_container.add_child(_item_cost)

	# Description
	_item_description = Label.new()
	_item_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_description.custom_minimum_size = Vector2(350, 60)
	details_content.add_child(_item_description)

	# Effects
	_item_effects = RichTextLabel.new()
	_item_effects.custom_minimum_size = Vector2(350, 100)
	_item_effects.fit_content = true
	details_content.add_child(_item_effects)

	# Unlock progress
	_unlock_progress = RichTextLabel.new()
	_unlock_progress.custom_minimum_size = Vector2(350, 60)
	_unlock_progress.fit_content = true
	details_content.add_child(_unlock_progress)

	# Purchase button
	_purchase_button = Button.new()
	_purchase_button.text = "Purchase"
	_purchase_button.pressed.connect(_on_purchase_pressed)
	details_content.add_child(_purchase_button)


func _connect_signals() -> void:
	ItemSystem.item_unlocked.connect(_on_item_unlocked)
	ItemSystem.loadout_changed.connect(_refresh_loadout)


func _refresh_all() -> void:
	_refresh_tech_points()
	_refresh_item_browser()
	_refresh_loadout()
	_refresh_equipped_effects()


func _refresh_tech_points() -> void:
	_tech_points_label.text = "Tech Points: %d" % MetaProgress.tech_points


func _refresh_item_browser() -> void:
	# Clear existing item buttons
	for grid: GridContainer in _item_grids.values():
		for child in grid.get_children():
			child.queue_free()
	_item_buttons.clear()

	# Populate items by rarity
	var all_items := ItemSystem.get_all_items()
	for item_id: String in all_items.keys():
		var item: Dictionary = all_items[item_id]
		var rarity: String = item.get("rarity", "common")
		
		if not _item_grids.has(rarity):
			continue
			
		var item_button := _create_item_button(item_id, item)
		_item_grids[rarity].add_child(item_button)
		_item_buttons[item_id] = item_button


func _create_item_button(item_id: String, item_data: Dictionary) -> Control:
	var container := VBoxContainer.new()
	
	var button := Button.new()
	button.custom_minimum_size = Vector2(120, 120)
	button.pressed.connect(_on_item_selected.bind(item_id))
	container.add_child(button)
	
	# Item state styling
	var is_unlocked := ItemSystem.is_item_unlocked(item_id)
	var is_owned := ItemSystem.is_item_owned(item_id)
	var rarity_data := ItemSystem.get_rarity_data(item_data.get("rarity", "common"))
	var rarity_color := Color.from_string(rarity_data.get("color", "#FFFFFF"), Color.WHITE)
	
	if not is_unlocked:
		button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		button.text = "LOCKED"
	elif not is_owned:
		button.modulate = rarity_color
		button.text = item_data.get("name", item_id)
	else:
		button.modulate = rarity_color
		button.text = "✓ " + item_data.get("name", item_id)
	
	# Item name label
	var name_label := Label.new()
	name_label.text = item_data.get("name", item_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	container.add_child(name_label)
	
	return container


func _refresh_loadout() -> void:
	var loadout := ItemSystem.active_loadout
	
	for i in range(_loadout_slots.size()):
		var slot := _loadout_slots[i]
		var slot_button: Button = slot.get_child(0)
		var item_id: String = loadout[i] if i < loadout.size() else ""
		
		if item_id == "":
			slot_button.text = "Empty\nSlot %d" % (i + 1)
			slot_button.modulate = Color.WHITE
		else:
			var item_data := ItemSystem.get_item_data(item_id)
			slot_button.text = item_data.get("name", item_id)
			var rarity_data := ItemSystem.get_rarity_data(item_data.get("rarity", "common"))
			var rarity_color := Color.from_string(rarity_data.get("color", "#FFFFFF"), Color.WHITE)
			slot_button.modulate = rarity_color


func _refresh_equipped_effects() -> void:
	var equipped_items := ItemSystem.get_equipped_items()
	var text := ""
	
	if equipped_items.is_empty():
		text = "[color=gray]No items equipped[/color]"
	else:
		for item_id: String in equipped_items:
			var item_data := ItemSystem.get_item_data(item_id)
			var effects: Dictionary = item_data.get("effects", {})
			var rarity_data: Dictionary = ItemSystem.get_rarity_data(item_data.get("rarity", "common"))
			var color: String = rarity_data.get("color", "#FFFFFF")
			
			text += "[color=%s]%s:[/color]\n" % [color, item_data.get("name", item_id)]
			for effect_name: String in effects.keys():
				var value = effects[effect_name]
				text += "  • %s: %s\n" % [_format_effect_name(effect_name), _format_effect_value(effect_name, value)]
			text += "\n"
	
	_equipped_effects_list.text = text


func _format_effect_name(effect_name: String) -> String:
	return effect_name.replace("_", " ").capitalize()


func _format_effect_value(effect_name: String, value) -> String:
	if effect_name.ends_with("_multiplier"):
		return "%.0f%%" % ((value - 1.0) * 100.0) if value > 1.0 else "%.0f%%" % ((1.0 - value) * -100.0)
	elif effect_name.ends_with("_bonus"):
		return "+%s" % str(value)
	elif effect_name.ends_with("_chance"):
		return "%.0f%%" % (value * 100.0)
	else:
		return str(value)


func _on_item_selected(item_id: String) -> void:
	_selected_item_id = item_id
	_show_item_details(item_id)


func _show_item_details(item_id: String) -> void:
	var item_data := ItemSystem.get_item_data(item_id)
	
	_item_name.text = item_data.get("name", item_id)
	_item_description.text = item_data.get("description", "No description available")
	
	# Cost
	var cost: Dictionary = item_data.get("cost", {})
	var tech_cost: int = cost.get("tech_points", 0)
	_item_cost.text = "Cost: %d Tech Points" % tech_cost
	
	# Effects
	var effects_text := ""
	var effects: Dictionary = item_data.get("effects", {})
	for effect_name: String in effects.keys():
		var value = effects[effect_name]
		effects_text += "• %s: %s\n" % [_format_effect_name(effect_name), _format_effect_value(effect_name, value)]
	_item_effects.text = effects_text
	
	# Purchase button state
	var is_unlocked := ItemSystem.is_item_unlocked(item_id)
	var is_owned := ItemSystem.is_item_owned(item_id)
	var can_purchase := ItemSystem.can_purchase_item(item_id)
	
	if is_owned:
		_purchase_button.text = "Owned"
		_purchase_button.disabled = true
	elif not is_unlocked:
		_purchase_button.text = "Locked"
		_purchase_button.disabled = true
	elif can_purchase:
		_purchase_button.text = "Purchase"
		_purchase_button.disabled = false
	else:
		_purchase_button.text = "Insufficient Tech Points"
		_purchase_button.disabled = true
	
	# Unlock progress
	var progress_data := ItemSystem.get_unlock_progress_for_item(item_id)
	var progress_text := ""
	
	if is_unlocked:
		progress_text = "[color=green]✓ Unlocked[/color]"
	else:
		progress_text = "Unlock Requirements:\n"
		for condition: String in progress_data.keys():
			var prog: Dictionary = progress_data[condition]
			var current: int = prog["current"]
			var required: int = prog["required"]
			var completed: bool = prog["completed"]
			var color := "green" if completed else "red"
			
			progress_text += "[color=%s]• %s: %d/%d[/color]\n" % [
				color, _format_condition_name(condition), current, required
			]
	
	_unlock_progress.text = progress_text


func _format_condition_name(condition: String) -> String:
	match condition:
		"enemies_killed": return "Enemies Killed"
		"buildings_built": return "Buildings Built"
		"buildings_lost": return "Buildings Lost"
		"survival_time": return "Survival Time (seconds)"
		"boss_kills": return "Boss Kills"
		"tech_points_earned": return "Tech Points Earned"
		"population_cap_reached": return "Population Cap Reached"
		"central_tower_upgrades": return "Central Tower Upgrades"
		"enemy_variety_killed": return "Enemy Types Killed"
		_: return condition.replace("_", " ").capitalize()


func _on_purchase_pressed() -> void:
	if _selected_item_id != "" and ItemSystem.purchase_item(_selected_item_id):
		_refresh_tech_points()
		_refresh_item_browser()
		_show_item_details(_selected_item_id)  # Refresh details


func _on_loadout_slot_pressed(slot_index: int) -> void:
	if _selected_item_id != "" and ItemSystem.is_item_owned(_selected_item_id):
		ItemSystem.equip_item(_selected_item_id, slot_index)


func _on_unequip_pressed(slot_index: int) -> void:
	ItemSystem.unequip_slot(slot_index)


func _on_item_unlocked(item_id: String) -> void:
	_refresh_item_browser()


func _on_back_pressed() -> void:
	loadout_screen_closed.emit()
	queue_free()