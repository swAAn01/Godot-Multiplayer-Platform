class_name LevelLoader
extends Node
## Responsible for the loading and unloading of levels.


const WAIT_INTERVAL := 0.1
const LEVEL_DICT: Dictionary[String, String] = {
	'example': 'uid://dltcmsd3purl0'
}

var current_key: String


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)


## When a peer joins, the host shares the key so the joining peer can spawn the right level.
func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		spawn_level.rpc_id(peer_id, current_key)


func clear_level() -> void:
	for child: Node in get_children():
		child.queue_free()


@rpc("authority", "call_local", "reliable")
func spawn_level(key: String) -> void:
	current_key = key
	var uid := LEVEL_DICT[key]
	ResourceLoader.load_threaded_request(uid, "PackedScene")
	clear_level()
	while ResourceLoader.load_threaded_get_status(uid) != ResourceLoader.THREAD_LOAD_LOADED:
		await get_tree().create_timer(WAIT_INTERVAL).timeout
	var level_packed: PackedScene = ResourceLoader.load_threaded_get(uid)
	var level := level_packed.instantiate()
	add_child.call_deferred(level)
	await level.ready
