class_name MainMenu
extends Control


const TIMEOUT_DUR := 10.0


@onready var host_button: Button = $Buttons/HostButton
@onready var join_button: Button = $Buttons/JoinButton
@onready var quit_button: Button = $Buttons/QuitButton
@onready var host_popup: PackedScene = preload("uid://d0yvjw3bvjxkq")
@onready var join_popup: PackedScene = preload("uid://bjugfndbiagm1")
@onready var joining_overlay: ColorRect = $JoiningOverlay
@onready var joining_label: Label = $JoiningOverlay/JoiningLabel
@onready var fail_label: Label = $JoiningOverlay/FailedLabel
@onready var fail_button: Button = $JoiningOverlay/FailedButton
@onready var hosting_overlay: ColorRect = $HostingOverlay
@onready var hosting_label: Label = $HostingOverlay/JoiningLabel
@onready var host_failed_label: Label = $HostingOverlay/FailedLabel
@onready var host_failed_button: Button = $HostingOverlay/FailedButton


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	host_button.grab_focus()
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	fail_button.pressed.connect(_on_fail_button_pressed)
	host_failed_button.pressed.connect(func() -> void: hosting_overlay.hide())
	#MultiplayerService.joining_lobby.connect(_on_joining_lobby) TODO setup these signals
	#MultiplayerService.creating_lobby.connect(_on_creating_lobby)
	#MultiplayerService.join_lobby_failed.connect(_on_join_failed)
	if not MultiplayerService.kick_reason.is_empty():
		_show_kick_reason(MultiplayerService.kick_reason)


func _on_host_button_pressed() -> void:
	var popup: HostOptionsPopup = host_popup.instantiate()
	add_child(popup)


func _on_join_button_pressed() -> void:
	var popup: JoinPopup = join_popup.instantiate()
	add_child(popup)


func _on_joining_lobby() -> void:
	joining_overlay.show()
	joining_label.show()
	joining_overlay.grab_focus()
	fail_label.hide()
	fail_button.hide()
	await get_tree().create_timer(TIMEOUT_DUR).timeout
	_on_join_failed("Timed out.")


func _on_creating_lobby() -> void:
	hosting_overlay.show()
	hosting_overlay.show()
	hosting_overlay.grab_focus()
	host_failed_label.hide()
	host_failed_button.hide()
	await get_tree().create_timer(TIMEOUT_DUR).timeout
	MultiplayerService.leave_game()
	hosting_label.hide()
	host_failed_label.show()
	host_failed_button.show()


func _on_join_failed(reason: String) -> void:
	MultiplayerService.leave_game()
	joining_label.hide()
	fail_label.text = "Failed to join game. Reason: %s" % reason
	fail_label.show()
	fail_button.show()
	fail_button.grab_focus()


func _on_fail_button_pressed() -> void:
	joining_overlay.hide()
	host_button.grab_focus()


func _show_kick_reason(reason: String) -> void:
	joining_overlay.show()
	joining_label.hide()
	fail_label.text = reason
	fail_label.show()
	fail_button.show()
	fail_button.grab_focus()
