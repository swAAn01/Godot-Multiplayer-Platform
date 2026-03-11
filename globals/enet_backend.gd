class_name ENetBackend
extends MultiplayerBackend


const GAME_PORT := 8404
const SEARCH_PORT := 2646
const BROADCAST_ADDRESS := "255.255.255.255"


var search_server := UDPServer.new()
var search_peer := PacketPeerUDP.new()
var max_players: int
var lobby_name: String


func _ready() -> void:
	search_peer.set_dest_address(BROADCAST_ADDRESS, SEARCH_PORT)
	search_peer.set_broadcast_enabled(true)


func _process(_delta: float) -> void:
	if search_server.is_listening():
		assert(multiplayer.is_server())
		search_server.poll()
		if search_server.is_connection_available():
			var ppeer := search_server.take_connection()
			var packet_str := "%s,%d,%d" % [lobby_name, multiplayer.get_peers().size() + 1, max_players]
			ppeer.put_packet(packet_str.to_utf8_buffer())
	while search_peer.get_available_packet_count() > 0:
		assert(not multiplayer.has_multiplayer_peer())
		assert(not search_server.is_listening())
		var ip := search_peer.get_packet_ip()
		var packet := search_peer.get_packet().get_string_from_utf8().split(',')
		EventBus.meta_events.lobby_found.emit(ip, packet[0], int(packet[1]), int(packet[2]))


func host_game(options: HostOptions) -> void:
	assert(not multiplayer.has_multiplayer_peer())
	print("Creating ENet lobby...")
	max_players = options.max_players
	lobby_name = options.lobby_name
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(GAME_PORT, max_players - 1)
	multiplayer.set_multiplayer_peer(peer)
	EventBus.meta_events.lobby_joined.emit()


func join_game(address: Variant) -> void:
	assert(not multiplayer.has_multiplayer_peer())
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(address as String, GAME_PORT)
	multiplayer.set_multiplayer_peer(peer)
	EventBus.meta_events.lobby_joined.emit()


func leave_game() -> void:
	assert(multiplayer.has_multiplayer_peer())
	close_peer()
	search_server.stop()


func fetch_lobby_list() -> void:
	assert(not multiplayer.has_multiplayer_peer())
	assert(not search_server.is_listening())
	print_debug("Searching For Games over LAN...")
	search_peer.put_packet("Anyone there?".to_utf8_buffer())


func set_joinable(joinable: bool) -> void:
	assert(multiplayer.is_server())
	print_debug("Setting ENet Lobby Joinable: " + str(joinable))
	if joinable:
		search_server.listen(SEARCH_PORT)
	else:
		search_server.stop()


func get_uid(pid: int) -> String:
	var peer := (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(pid)
	if peer:
		return peer.get_remote_address()
	else:
		return str(pid)


func get_username(peer_id: int) -> String:
	if SteamBackend.steam_initialized and peer_id == multiplayer.get_unique_id():
		return Steam.getPersonaName()
	return str(peer_id)
