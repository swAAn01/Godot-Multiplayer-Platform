class_name PauseMenu
extends ColorRect


@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var players_container: VBoxContainer = $PlayersContainer
@onready var player_list_item_packed: PackedScene = preload("uid://dlw62wt82uk2p")


func _ready() -> void:
	
	for peer_id: int in multiplayer.get_peers():
		_add_player_to_list(peer_id)
	
	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	multiplayer.peer_connected.connect(_add_player_to_list)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(func() -> void: queue_free())


func _on_resume_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	queue_free()


func _add_player_to_list(peer_id: int) -> void:
	var pli: PlayerListItem = player_list_item_packed.instantiate()
	pli.peer_id = peer_id
	players_container.add_child(pli)


func _on_peer_disconnected(peer_id: int) -> void:
	for pli: PlayerListItem in players_container.get_children():
		if pli.peer_id == peer_id:
			pli.queue_free()
			break


func _on_exit_pressed() -> void:
	MultiplayerService.leave_game()
	queue_free()
