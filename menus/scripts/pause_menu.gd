class_name PauseMenu
extends ColorRect


@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var settings_popup: PackedScene = preload("uid://c5f2g0sg1jh4g")
@onready var voip_item_packed: PackedScene = preload("uid://chtyy4l0itwna")
@onready var voip_container: VBoxContainer = $VoipContainer
@onready var primary_tool_option: OptionButton = $DevToolContainer/FixingToolSelector/OptionButton
@onready var respawn_button: Button = $DevToolContainer/RespawnButton
@onready var mouth_slider: HSlider = $DevToolContainer/Mouth/HSlider
@onready var eyes_slider: HSlider = $DevToolContainer/Eyes/HSlider
@onready var brows_slider: HSlider = $DevToolContainer/Brows/HSlider
@onready var mouth_label: Label = $DevToolContainer/Mouth/IndexLabel
@onready var eyes_label: Label = $DevToolContainer/Eyes/IndexLabel
@onready var brows_label: Label = $DevToolContainer/Brows/IndexLabel
@onready var dev_tool_container: VBoxContainer = $DevToolContainer
@onready var color_button: ColorPickerButton = $DevToolContainer/ColorPicker/ColorPickerButton
@onready var invite_button: Button = $Invite


var local_player: Player


signal close_pressed


func _ready() -> void:
	
	if OS.is_debug_build():
		dev_tool_container.show()
		
		local_player = GlobalUtils.get_player_by_peer_id(multiplayer.get_unique_id())
		assert(local_player.is_multiplayer_authority())
		
		mouth_slider.max_value = PlayerBody.NUM_MOUTHS - 1
		mouth_slider.value = get_cosmetic_index(local_player.get_cosmetic_material(Constants.CosmeticType.MOUTH))
		mouth_label.text = str(int(mouth_slider.value))
		
		eyes_slider.max_value = PlayerBody.NUM_EYES - 1
		eyes_slider.value = get_cosmetic_index(local_player.get_cosmetic_material(Constants.CosmeticType.EYES))
		eyes_label.text = str(int(eyes_slider.value))
		
		brows_slider.max_value = PlayerBody.NUM_BROWS - 1
		brows_slider.value = get_cosmetic_index(local_player.get_cosmetic_material(Constants.CosmeticType.BROWS))
		brows_label.text = str(int(brows_slider.value))
		
		match local_player.get_primary_tool().name:
			'Hammer':
				primary_tool_option.selected = 0
			'Wrench':
				primary_tool_option.selected = 1
			'Torch':
				primary_tool_option.selected = 2
		
		var s_mat: ShaderMaterial = local_player.get_cosmetic_material(Constants.CosmeticType.BODY)
		color_button.color = s_mat.get_shader_parameter(Constants.CHARACTER_BODY_COLOR_PARAM_NAME)
		
		primary_tool_option.item_selected.connect(_on_primary_tool_selected)
		respawn_button.pressed.connect(_on_respawn_pressed)
		mouth_slider.value_changed.connect(_on_mouth_changed)
		eyes_slider.value_changed.connect(_on_eyes_changed)
		brows_slider.value_changed.connect(_on_brows_changed)
		color_button.color_changed.connect(_on_color_picked)
	
	for peer_id: int in multiplayer.get_peers():
		create_voip_item(peer_id)
	
	resume_button.pressed.connect(func() -> void: close_pressed.emit())
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(exit)
	EventBus.global_events.audio_bus_created.connect(_on_bus_created)
	multiplayer.server_disconnected.connect(func() -> void: queue_free())
	EventBus.global_events.game_exited.connect(func() -> void: queue_free())
	
	if MultiplayerService.backend is SteamBackend:
		invite_button.show()
		invite_button.pressed.connect(func() -> void: (MultiplayerService.backend as SteamBackend).activate_invite_overlay())


static func get_cosmetic_index(mat: StandardMaterial3D) -> float:
	var x := fmod(mat.uv1_offset.x, PlayerBody.COSMETIC_COLS * PlayerBody.COSMETIC_OFFSET_SCALE) / PlayerBody.COSMETIC_OFFSET_SCALE
	var y := mat.uv1_offset.y / PlayerBody.COSMETIC_OFFSET_SCALE
	return (y * PlayerBody.COSMETIC_COLS) + x


func _on_bus_created(bus_name: String) -> void:
	create_voip_item(int(bus_name))


func create_voip_item(peer_id: int) -> void:
	var voip_item: VoipSliderItem = voip_item_packed.instantiate()
	voip_container.add_child(voip_item)
	voip_item.setup(peer_id)


func _on_settings_button_pressed() -> void:
	var popup := settings_popup.instantiate()
	add_child(popup)


func exit() -> void:
	EventBus.global_events.game_exited.emit()
	queue_free()


func _on_primary_tool_selected(index: int) -> void:
	var player := GlobalUtils.get_player_by_peer_id(multiplayer.get_unique_id())
	var uid: String
	match index:
		0: uid = 'uid://bhcrxguxtk16i'
		1: uid = 'uid://5oy06g4vxggq'
		2: uid = 'uid://cvlnxuwgi3j88'
	player.set_primary_tool(uid)


func _on_respawn_pressed() -> void:
	var player := GlobalUtils.get_player_by_peer_id(multiplayer.get_unique_id())
	player.global_position = Vector3.ZERO
	player.velocity = Vector3.ZERO


func _on_mouth_changed(value: float) -> void:
	local_player.set_cosmetic.rpc(Constants.CosmeticType.MOUTH, int(value))
	mouth_label.text = str(int(value))


func _on_eyes_changed(value: float) -> void:
	local_player.set_cosmetic.rpc(Constants.CosmeticType.EYES, int(value))
	eyes_label.text = str(int(value))


func _on_brows_changed(value: float) -> void:
	local_player.set_cosmetic.rpc(Constants.CosmeticType.BROWS, int(value))
	brows_label.text = str(int(value))


func _on_color_picked(this_color: Color) -> void:
	local_player.set_body_color.rpc(this_color)
