extends Node


enum BackendType {ENET, STEAM}


var backend: MultiplayerBackend
var joining_from_cmd_line: bool
var banlist: Array
var kick_reason: String


func _ready() -> void:
	multiplayer.set_multiplayer_peer(null)
	joining_from_cmd_line = check_command_line()
	if not joining_from_cmd_line:
		EventBus.meta_events.backend_selected.connect(init_backend)
	if OS.has_feature('steam'):
		SteamBackend.initialize_steam()
	multiplayer.peer_connected.connect(_on_peer_connected)


func check_command_line() -> bool:
	var args := OS.get_cmdline_args()
	if not args.is_empty():
		if args[0] == "+connect_lobby":
			var lobby_id := int(args[1])
			if lobby_id > 0:
				init_backend(BackendType.STEAM)
				join_game(lobby_id)
				return true
	return false


func init_backend(type: BackendType) -> void:
	match type:
		BackendType.STEAM:
			backend = SteamBackend.new()
		BackendType.ENET:
			backend = ENetBackend.new()
	add_child(backend)


func host_game(options: HostOptions) -> void:
	if options.max_players == 1:
		multiplayer.set_multiplayer_peer(OfflineMultiplayerPeer.new())
		EventBus.meta_events.lobby_joined.emit()
	else:
		backend.host_game(options)


func join_game(address: Variant) -> void:
	EventBus.meta_events.joining_lobby.emit()
	backend.join_game(address)


func leave_game() -> void:
	backend.leave_game()


func fetch_lobby_list() -> void:
	backend.fetch_lobby_list()


func set_joinable(joinable: bool) -> void:
	backend.set_joinable(joinable)


func kick_player(pid: int) -> void:
	kick_player_rpc.rpc_id(pid, backend.get_uid(pid) not in banlist)


@rpc("authority", "call_remote", "reliable", Constants.RPCChannel.INIT)
func kick_player_rpc(kicked: bool) -> void:
	if kicked:
		kick_reason = "You were kicked."
	else:
		kick_reason = "You are banned from this lobby."
	EventBus.global_events.game_exited.emit()


func ban_player(pid: int) -> void:
	banlist.append(backend.get_uid(pid))
	kick_player(pid)


func _on_peer_connected(pid: int) -> void:
	if banlist.has(backend.get_uid(pid)):
		kick_player(pid)


func get_username(peer_id: int) -> String:
	return backend.get_username(peer_id)


func replace_backend(with: BackendType) -> void:
	if not has_correct_backend(with):
		if backend:
			backend.queue_free()
		init_backend(with)


func has_correct_backend(type: BackendType) -> bool:
	if backend:
		match type:
			BackendType.ENET:
				return backend is ENetBackend
			BackendType.STEAM:
				return backend is SteamBackend
			_:
				return false
	return false
