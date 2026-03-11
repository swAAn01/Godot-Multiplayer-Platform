class_name LevelLoader
extends Node


const LEVEL_ATLAS_PATH := "res://Meta/level_atlas.yaml"
const WAIT_INTERVAL := 0.1


var current_key: String
var proc_gen_events: Array[Callable]
var props_spawned := 0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	EventBus.level_events.level_started.connect(func(key: String) -> void: spawn_scene.rpc(key))
	EventBus.level_events.proc_gen_event_ready.connect(func(event: Callable) -> void: proc_gen_events.append(event))
	EventBus.level_events.prop_instantiated.connect(spawn_prop)
	EventBus.level_events.level_ended.connect(func() -> void: spawn_scene.rpc(Constants.BASE_KEY))
	EventBus.level_events.decal_instantiated.connect(func(decal: Decal) -> void: add_child(decal))


## When a peer joins, the authority shares the key so the joining peer can spawn the right level.
func _on_peer_connected(peer_id: int) -> void:
	if is_multiplayer_authority():
		spawn_scene.rpc_id(peer_id, current_key)


func spawn_prop(prop: RigidBody3D, pos: Vector3) -> void:
	prop.name = "Prop %d" % props_spawned
	props_spawned += 1
	prop.freeze = true
	add_child.call_deferred(prop)
	await prop.ready
	prop.global_position = pos
	prop.freeze = false


func get_uid_by_key(key: String) -> String:
	var level_atlas_file := FileAccess.open(LEVEL_ATLAS_PATH, FileAccess.READ)
	var level_atlas_text := level_atlas_file.get_as_text()
	var level_atlas_yaml := YAML.parse(level_atlas_text)
	if level_atlas_yaml.has_error():
		push_error(level_atlas_yaml.get_error())
		return ''
	var level_atlas: Dictionary = level_atlas_yaml.get_data()
	var level_dict: Dictionary = level_atlas[key]
	return level_dict['uid']


func clear_level() -> void:
	for child: Node in get_children():
		child.queue_free()
	props_spawned = 0


@rpc("authority", "call_local", "reliable", Constants.RPCChannel.INIT)
func spawn_scene(key: String) -> void:
	current_key = key
	# load level
	var uid := get_uid_by_key(key)
	ResourceLoader.load_threaded_request(uid, "PackedScene")
	# clear existing level
	clear_level()
	# wait for level to load
	while ResourceLoader.load_threaded_get_status(uid) != ResourceLoader.THREAD_LOAD_LOADED:
		await get_tree().create_timer(WAIT_INTERVAL).timeout
	# spawn level
	var level_packed: PackedScene = ResourceLoader.load_threaded_get(uid)
	var level: Node = level_packed.instantiate()
	add_child.call_deferred(level)
	await level.ready
	# do proc gen events
	while not proc_gen_events.is_empty():
		var event: Callable = proc_gen_events.pop_front()
		await event.call()
	EventBus.level_events.level_loaded.emit()
