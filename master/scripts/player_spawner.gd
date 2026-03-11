class_name PlayerSpawner
extends MultiplayerSpawner


const WARN_MSG := "Tried to remove a player that doesn't exist."


@onready var player_scene: PackedScene = preload("uid://bxg4ne58ekov4")


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	EventBus.level_events.level_loaded.connect(_on_level_loaded)
	EventBus.level_events.level_ended.connect(func() -> void: reset_players.rpc())


func _on_child_entered(child: Node) -> void:
	EventBus.player_events.player_spawned.emit(child as Player)


func _on_level_loaded() -> void:
	for player: Player in get_tree().get_nodes_in_group(&'players'):
		if player.is_multiplayer_authority():
			for pid: int in multiplayer.get_peers():
				player.send_init(pid)
		else:
			player.request_init()


func _on_child_exiting(child: Node) -> void:
	EventBus.player_events.player_despawning.emit(child as Player)


func _on_peer_connected(peer_id: int) -> void:
	if is_multiplayer_authority():
		spawn_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if is_multiplayer_authority():
		remove_player(peer_id)


func spawn_player(id: int) -> void:
	var player: Player = player_scene.instantiate()
	player.name = str(id)
	add_child.call_deferred(player)


func remove_player(id: int) -> void:
	var player: Player = find_child(str(id), true, false)
	if player: player.queue_free()
	else: push_warning(WARN_MSG)


func clear_players() -> void:
	for child: Node in get_children():
		child.queue_free()


@rpc("authority", "call_local", "reliable", Constants.RPCChannel.INIT)
func reset_players() -> void:
	for child: Player in get_children():
		if child.is_multiplayer_authority():
			child.global_position = Vector3.ZERO
		child.set_secondary_tool('')
