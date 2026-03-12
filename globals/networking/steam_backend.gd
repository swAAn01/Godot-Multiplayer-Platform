class_name SteamBackend
extends MultiplayerBackend


func host_game(options: HostOptions) -> void:
	pass


func join_game(address: Variant) -> void:
	pass


func leave_game() -> void:
	pass


func fetch_lobby_list() -> void:
	pass


func set_joinable(joinable: bool) -> void:
	pass


func get_joinable() -> bool:
	return true # TODO


func get_uid(peer_id: int) -> int:
	return 0 # TODO


func get_username(peer_id: int) -> String:
	return "" # TODO
