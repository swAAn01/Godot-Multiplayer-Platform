class_name GameMaster
extends Node
## [b]Responsible for driving and managing the global game state.[/b]


@onready var main_menu_scene: PackedScene = preload("uid://bw5mw614jt72i")
@onready var main_menu: MainMenu = $MainMenu
@onready var player_spawner: PlayerSpawner = $PlayerSpawner
@onready var voip_manager: VoipManager = $VOIPManager
@onready var level_loader: LevelLoader = $LevelLoader


func _ready() -> void:
	MultiplayerService.lobby_joined.connect(start_game)
	multiplayer.server_disconnected.connect(exit_to_main_menu)


func start_game() -> void:
	MultiplayerService.kick_reason = ""
	MultiplayerService.banlist.clear()
	if multiplayer.is_server():
		await level_loader.spawn_scene('base')
		player_spawner.spawn_player(1)
	else:
		await multiplayer.connected_to_server
	main_menu.queue_free()


func exit_to_main_menu() -> void:
	MultiplayerService.leave_game()
	player_spawner.clear_players()
	level_loader.clear_level()
	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
