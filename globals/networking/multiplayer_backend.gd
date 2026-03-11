@abstract
class_name MultiplayerBackend
extends Node


@abstract
func host_game(options: HostOptions) -> void


@abstract
func join_game(address: Variant) -> void


@abstract
func leave_game() -> void


@abstract
func fetch_lobby_list() -> void


func close_peer() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.set_multiplayer_peer(null)


@abstract
func set_joinable(joinable: bool) -> void


@abstract
func get_uid(pid: int) -> Variant


@abstract
func get_username(peer_id: int) -> String
