class_name VoipManager extends Node


const MIC_BUS_NAME := "Microphone"
const VOIP_BUS_NAME := &"ProxChat"
const NOISE_THRESHOLD := 0.0055


@onready var DEFAULT_NUM_BUSES := AudioServer.bus_count


## Audio effect to capture chunks from Record bus
var mic_chunked_effect: AudioEffectOpusChunked
## Buffers of received chunks from other peers
var received_buffers: Dictionary[int, Array]
## Audio streams to output audio chunks to
var voice_players: Dictionary[int, AudioStreamOpusChunked]
## Whether we should be sending and receiving chunks.
var disabled := true


func _ready() -> void:
	# connect signals
	EventBus.player_events.player_spawned.connect(_on_player_spawned)
	EventBus.player_events.player_despawning.connect(_on_player_despawning)
	EventBus.level_events.level_started.connect(_on_level_started)
	EventBus.level_events.level_loaded.connect(_on_level_loaded)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	# setup input audio config
	mic_chunked_effect = AudioEffectOpusChunked.new()
	mic_chunked_effect.audiosamplerate = int(AudioServer.get_input_mix_rate())
	mic_chunked_effect.audiosamplesize = int(AudioServer.get_input_mix_rate() / mic_chunked_effect.audiosamplechunks)
	AudioServer.add_bus_effect(AudioServer.get_bus_index(MIC_BUS_NAME), mic_chunked_effect)
	set_mic_enabled(false)


func _on_level_started(key: String) -> void:
	if key == Constants.BASE_KEY:
		clear_buffers()
		set_mic_enabled(true)
		disabled = false
	else:
		disabled = true
		set_mic_enabled(false)
		clear_buffers()


func _on_level_loaded() -> void:
	clear_buffers()
	set_mic_enabled(true)
	disabled = false


## When a Player enters, grab its voice player
func _on_player_spawned(player: Player) -> void:
	var peer_id := int(player.name)
	if peer_id != multiplayer.get_unique_id():
		var vp: RaytracedAudioPlayer3D = await player.voice_player_added
		voice_players[peer_id] = vp.stream
		create_voip_bus(peer_id)
		vp.bus = &"%d" % peer_id


## When a Player exits, erase its voice player and associated audio bus
func _on_player_despawning(player: Player) -> void:
	voice_players.erase(int(player.name))


## When we connect to a game, setup receive buffers for each connected peer
func _on_connected_to_server() -> void:
	for peer_id: int in multiplayer.get_peers():
		received_buffers[peer_id] = []
	set_mic_enabled(true)
	disabled = false


## When a peer connects, setup a receive buffer
func _on_peer_connected(peer_id: int) -> void:
	if not received_buffers.keys().has(peer_id):
		received_buffers[peer_id] = []


## When a peer disconnects, erase their receive buffer
func _on_peer_disconnected(peer_id: int) -> void:
	received_buffers.erase(peer_id)
	attempt_remove_bus(str(peer_id))


## When we disconnect from the server, clear all records
func _on_server_disconnected() -> void:
	for id: int in received_buffers.keys():
		_on_peer_disconnected(id)
	set_mic_enabled(false)
	disabled = true


func _physics_process(_delta: float) -> void:
	if not disabled:
		while mic_chunked_effect.chunk_available():
			var chunk_max := mic_chunked_effect.chunk_max(false, false)
			if chunk_max > NOISE_THRESHOLD:
				var chunk := mic_chunked_effect.read_opus_packet(PackedByteArray())
				send_voice_chunk.rpc(chunk)
			else:
				mic_chunked_effect.resetencoder(true)
			mic_chunked_effect.drop_chunk()
		push_received()


## Send voice data over network
@rpc("any_peer", "call_remote", "unreliable_ordered", Constants.RPCChannel.VOIP)
func send_voice_chunk(chunk: PackedByteArray) -> void:
	if not disabled:
		var peer_id := multiplayer.get_remote_sender_id()
		if received_buffers.keys().has(peer_id):
			received_buffers[peer_id].push_back(chunk)


## Add received chunks to playback
func push_received() -> void:
	for peer_id: int in voice_players.keys(): # for each connected peer
		var player := voice_players[peer_id]
		assert(received_buffers.keys().has(peer_id))
		var buffer := received_buffers[peer_id]
		# while we have data to write and we can write to the player
		while not buffer.is_empty() and player.chunk_space_available():
			player.push_opus_packet(buffer.pop_front(), 0, 0) # pop chunk from buffer


func clear_buffers() -> void:
	for arr: Array in received_buffers.values():
		arr.clear()
	while mic_chunked_effect.chunk_available():
		mic_chunked_effect.drop_chunk()


func create_voip_bus(player_id: int) -> void:
	var bus_ind := AudioServer.bus_count
	AudioServer.add_bus(bus_ind)
	AudioServer.set_bus_name(bus_ind, str(player_id))
	AudioServer.set_bus_send(bus_ind, VOIP_BUS_NAME)
	print_debug("Created Audio Bus: %d" % player_id)
	EventBus.global_events.audio_bus_created.emit(str(player_id))


static func get_voip_bus_volume_linear(player_id: int) -> float:
	var ind := AudioServer.get_bus_index(str(player_id))
	return AudioServer.get_bus_volume_linear(ind)


static func set_voip_bus_volume_linear(player_id: int, lin_vol: float) -> void:
	var ind := AudioServer.get_bus_index(str(player_id))
	assert(ind >= 0)
	AudioServer.set_bus_volume_linear(ind, lin_vol)
	print(AudioServer.get_bus_volume_db(ind))


static func set_mic_enabled(enabled: bool) -> void:
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(MIC_BUS_NAME), 1, enabled)


static func attempt_remove_bus(bus: String) -> void:
	var sn := StringName(bus)
	var idx := AudioServer.get_bus_index(sn)
	if idx > -1:
		AudioServer.remove_bus(idx)
