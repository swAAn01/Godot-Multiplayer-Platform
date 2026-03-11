class_name GameMaster
extends Node


@onready var main_menu_scene: PackedScene = preload("uid://bw5mw614jt72i")
@onready var main_menu: MainMenu = $MainMenu
@onready var player_spawner: PlayerSpawner = $PlayerSpawner
@onready var voip_manager: VoipManager = $VOIPManager
@onready var level_loader: LevelLoader = $LevelLoader


var in_game := false


func _ready() -> void:
	multiplayer.server_disconnected.connect(exit_to_main)
	EventBus.meta_events.lobby_joined.connect(start_game)
	EventBus.global_events.game_exited.connect(exit_to_main)
	EventBus.level_events.level_started.connect(_on_level_started)
	if MultiplayerService.joining_from_cmd_line:
		_on_backend_selected(MultiplayerService.BackendType.STEAM)
		main_menu._on_joining_lobby()
	else:
		EventBus.meta_events.backend_selected.connect(_on_backend_selected)
	if OS.has_feature('steam'):
		Steam.join_requested.connect(_on_join_requested)


func start_game() -> void:
	MultiplayerService.kick_reason = ""
	MultiplayerService.banlist.clear()
	if multiplayer.is_server():
		EventBus.level_events.level_started.emit(Constants.BASE_KEY)
		await EventBus.level_events.level_loaded
		player_spawner.spawn_player(1)
	else:
		await multiplayer.connected_to_server
	main_menu.queue_free()
	in_game = true


func exit_to_main() -> void:
	MultiplayerService.leave_game()
	player_spawner.clear_players()
	level_loader.clear_level()
	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
	in_game = false


func _on_level_started(key: String) -> void:
	if multiplayer.is_server():
		MultiplayerService.set_joinable(key == Constants.BASE_KEY)


func _on_backend_selected(t: MultiplayerService.BackendType) -> void:
	mtp.queue_free()
	mtp = null
	main_menu.show()
	if t == MultiplayerService.BackendType.STEAM:
		Steam.join_requested.connect(_on_join_requested)


func _on_join_requested(lobby_id: int, _steam_id: int) -> void:
	if mtp:
		_on_backend_selected(MultiplayerService.BackendType.STEAM)
	if in_game:
		exit_to_main()
	MultiplayerService.replace_backend(MultiplayerService.BackendType.STEAM)
	MultiplayerService.join_game(lobby_id)
