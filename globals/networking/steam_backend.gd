class_name SteamBackend
extends MultiplayerBackend


const APP_ID := 480


var lobby_id: int
var joinable := true
var lobby_name: String


func _ready() -> void:
	# initialize Steam
	var steam_init_response := Steam.steamInitEx(APP_ID, false)
	var status_code: int = steam_init_response['status']
	if status_code == 0:
		print_debug("Initialized Steam.")
	else:
		var result_msg: String
		match status_code:
			2:
				result_msg = "Cannot connect to Steam. (is Steam client running?)"
			3:
				result_msg = "Steam client out of date."
			_:
				result_msg = "Failed to initialize Steam."
		push_error(result_msg)
	# connect Steam signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func host_game(options: HostOptions) -> void:
	print("Creating Steam Lobby...")
	lobby_name = options.lobby_name
	Steam.createLobby(options.lobby_type, options.max_players)


func join_game(address: Variant) -> void:
	print("Joining Steam Lobby with id: %d..." % address)
	Steam.joinLobby(address)


func leave_game() -> void:
	assert(multiplayer.has_multiplayer_peer())
	print("Leaving Steam Lobby with id %d" % lobby_id)
	Steam.leaveLobby(lobby_id)
	lobby_id = 0
	close_peer()


func fetch_lobby_list() -> void:
	Steam.requestLobbyList()


func set_joinable(j: bool) -> void:
	assert(multiplayer.is_server())
	assert(Steam.getLobbyOwner(lobby_id) == Steam.getSteamID())
	Steam.setLobbyJoinable(lobby_id, j)


func get_joinable() -> bool:
	return joinable


func get_uid(peer_id: int) -> int:
	return (multiplayer.get_multiplayer_peer() as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)


func get_username(peer_id: int) -> String:
	return Steam.getFriendPersonaName(get_uid(peer_id))


func _on_lobby_created(this_connect: int, this_lobby_id: int) -> void:
	if this_connect == 1:
		print("Lobby Created with id: %d." % this_lobby_id)
		Steam.setLobbyData(this_lobby_id, 'name', lobby_name)
		var peer := SteamMultiplayerPeer.new()
		peer.create_host(0)
		multiplayer.set_multiplayer_peer(peer)
	else:
		push_error("Failed to Create Steam Lobby.")
		# TODO create lobby failed


func _on_lobby_joined(this_lobby_id: int, _p: int, _l: int, response: Steam.ChatRoomEnterResponse) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("Joined Lobby with id: %d." % this_lobby_id)
		lobby_id = this_lobby_id
		if Steam.getLobbyOwner(this_lobby_id) != Steam.getSteamID():
			var peer := SteamMultiplayerPeer.new()
			peer.connect_to_lobby(this_lobby_id)
			multiplayer.set_multiplayer_peer(peer)
	else:
		var fail_message := "Failed to join lobby with id: %d. Reason: " % this_lobby_id
		var fail_reason: String
		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Something unexpected happened."
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."
		push_error(fail_message + fail_reason)
		join_lobby_failed.emit(fail_reason)


func _on_lobby_match_list(lobby_ids: Array) -> void:
	for this_lobby_id: int in lobby_ids:
		var this_lobby_name := Steam.getLobbyData(this_lobby_id, 'name')
		var cur_players := Steam.getNumLobbyMembers(this_lobby_id)
		var max_players := Steam.getLobbyMemberLimit(this_lobby_id)
		lobby_found.emit(this_lobby_name, this_lobby_id, cur_players, max_players)
