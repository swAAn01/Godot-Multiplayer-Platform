class_name JoinPopup
extends ColorRect


@onready var close_button: Button = $CloseButton
@onready var list_item_scene: PackedScene = preload("uid://cm6a2y0yichi8")
@onready var item_list: VBoxContainer = $ScrollContainer/ItemList
@onready var friend_label: Label = $FriendLabel
@onready var friend_toggle: CheckButton = $FriendToggle
@onready var friend_list: VBoxContainer = $FriendContainer/ItemList
@onready var refresh_button: Button = $RefreshButton
@onready var reg_container: ScrollContainer = $ScrollContainer
@onready var friend_container: ScrollContainer = $FriendContainer


func _ready() -> void:
	close_button.pressed.connect(func() -> void: queue_free())
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	friend_toggle.pressed.connect(_on_friend_toggle_pressed)
	EventBus.meta_events.lobby_found.connect(add_list_item.bind(item_list))
	MultiplayerService.fetch_lobby_list()
	if MultiplayerService.backend is SteamBackend:
		Steam.lobby_data_update.connect(_on_lobby_data_update)
		find_lobbies_with_friends()
	else:
		friend_toggle.hide()
		friend_label.hide()


func find_lobbies_with_friends() -> void:
	assert(MultiplayerService.backend is SteamBackend)
	for i: int in range(Steam.getFriendCount()):
		var friend_id := Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var friend_game_info: Dictionary = Steam.getFriendGamePlayed(friend_id)
		if friend_game_info.is_empty():
			continue
		var friend_game_app_id: int = friend_game_info['id']
		if friend_game_app_id != Steam.getAppID():
			continue
		var lobby_id: Variant = friend_game_info['lobby']
		if lobby_id is String:
			continue
		Steam.requestLobbyData(lobby_id as int)


func add_list_item(address: Variant, lobby_name: String, cur_players: int, max_players: int, list: VBoxContainer) -> void:
	var item: JoinListItem = list_item_scene.instantiate()
	item.address = address
	item.lobby_name = lobby_name
	item.cur_players = cur_players
	item.max_players = max_players
	list.add_child(item)


func _on_lobby_data_update(_success: int, lobby_id: int, _member_id: int) -> void:
	assert(MultiplayerService.backend is SteamBackend)
	for item: JoinListItem in friend_list.get_children():
		if item.address == lobby_id:
			return
	add_list_item(
		lobby_id,
		Steam.getLobbyData(lobby_id, 'name'),
		Steam.getNumLobbyMembers(lobby_id),
		Steam.getLobbyMemberLimit(lobby_id),
		friend_list
	)


func _on_refresh_button_pressed() -> void:
	for item: JoinListItem in item_list.get_children():
		item.queue_free()
	for item: JoinListItem in friend_list.get_children():
		item.queue_free()
	MultiplayerService.fetch_lobby_list()
	if MultiplayerService.backend is SteamBackend:
		find_lobbies_with_friends()


func _on_friend_toggle_pressed() -> void:
	assert(MultiplayerService.backend is SteamBackend)
	reg_container.visible = not friend_toggle.button_pressed
	friend_container.visible = friend_toggle.button_pressed
