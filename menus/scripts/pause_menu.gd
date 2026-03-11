class_name PauseMenu
extends ColorRect


@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var players_container: VBoxContainer = $PlayersContainer


func _ready() -> void:
	
	for peer_id: int in multiplayer.get_peers():
		_add_player_to_list(peer_id)
	
	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	multiplayer.peer_connected.connect(_add_player_to_list)
	multiplayer.server_disconnected.connect(func() -> void: queue_free())


func _on_resume_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	queue_free()


func _add_player_to_list(peer_id: int) -> void:
	var label := Label.new()
	label.text = str(peer_id)
	players_container.add_child(label)


func _on_exit_pressed() -> void:
	queue_free()
	# TODO GameMaster.exit_to_main_menu()
