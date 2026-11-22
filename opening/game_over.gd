extends CanvasLayer

signal respawn_requested

func present() -> void:
	if visible:
		return
	visible = true
	$GameOverSFX.play()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or (not event.is_action_pressed("jump") and not event.is_action_pressed("restart_run")):
		return
	if event is InputEventKey and event.echo:
		return
	get_viewport().set_input_as_handled()
	respawn_requested.emit()
