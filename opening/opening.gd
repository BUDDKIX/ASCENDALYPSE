extends Node2D

const CROP := Rect2(0, 125, 268, 99)
@onready var robot: CharacterBody2D = $Robot
@onready var camera: Camera2D = $BayCamera

func _ready() -> void:
	$Robot/Camera2D.enabled = false
	camera.make_current()
	$Robot/Sprite2D.texture = preload("res://opening/robot_off.png")
	$Menu/Play.pressed.connect(start)
	fit_camera()
	get_viewport().size_changed.connect(fit_camera)
	$Menu/Settings.pressed.connect(show_panel.bind($Menu/SettingsPanel))
	$Menu/Credits.pressed.connect(show_panel.bind($Menu/CreditsPanel))
	for panel in [$Menu/SettingsPanel, $Menu/CreditsPanel]:
		panel.get_node("Back").pressed.connect(show_panel.bind(null))
	$Menu/SettingsPanel/Fullscreen.toggled.connect(set_fullscreen)

func fit_camera() -> void:
	var ratio := get_viewport_rect().size / CROP.size
	camera.zoom = Vector2.ONE * minf(ratio.x, ratio.y)
	var viewport_size := get_viewport_rect().size
	$Prologue/Screen.position = (viewport_size * 0.5).round()
	var scale_fit := viewport_size / Vector2(240,135)
	$Prologue/Screen.scale = Vector2.ONE * minf(scale_fit.x,scale_fit.y)
	$Prologue/TitleCard.scale = $Prologue/Screen.scale
	$Prologue/TitleCard.position = $Prologue/Screen.position
	$Prologue/TitlePrompt.scale = $Prologue/Screen.scale
	$Prologue/TitlePrompt.position = ($Prologue/Screen.position + Vector2(0, 20 * $Prologue/Screen.scale.y)).round()

func show_panel(panel: Control) -> void:
	for child in $Menu.get_children():
		child.visible = child == panel if panel else child is Button
	if panel == $Menu/SettingsPanel:
		$Menu/SettingsPanel/Fullscreen.set_pressed_no_signal(get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN])

func set_fullscreen(enabled: bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED

func _unhandled_input(event: InputEvent) -> void:
	if $Menu.visible and not $Menu/Play.visible and event.is_action_pressed("ui_cancel"):
		show_panel(null)
		get_viewport().set_input_as_handled()

const FRAME_MS := [120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 190, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 820, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 120, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 90, 90, 90, 90, 90, 90, 100, 100, 100, 100, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 2500, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 240, 240, 240, 240, 240]
var film_time := 0.0
var film_frame := 0
var pull_count := 0
var held_triggers := 0.0
var title_armed := false

func start() -> void:
	if not $Menu.visible: return
	$Menu.hide()
	$Prologue.show()
	set_shot(0)

func set_shot(n: int) -> void:
	film_frame = n
	$Prologue/Screen.frame = n
	$Prologue/TitlePrompt.visible = n == 264
	$Prologue/TitleCard.visible = n == 264
	if n == 264: title_armed = false
	if n == 248:
		for pad in Input.get_connected_joypads(): Input.start_joy_vibration(pad,0.7,1.0,0.4)

func _physics_process(dt: float) -> void:
	if not $Prologue.visible: return
	if film_frame >= 222 and film_frame < 242:
		if Input.is_action_just_pressed("jump"): pull_count += 1
		var both := false
		for pad in Input.get_connected_joypads():
			both = both or (Input.get_joy_axis(pad,JOY_AXIS_TRIGGER_LEFT)>0.65 and Input.get_joy_axis(pad,JOY_AXIS_TRIGGER_RIGHT)>0.65)
		held_triggers = held_triggers + dt if both else 0.0
		if pull_count >= 8 or held_triggers >= 1.25: set_shot(242)
		else: set_shot(222 + maxi(pull_count*2,mini(19,int(held_triggers*15))))
		film_time = 0
		return
	if film_frame == 264:
		if not Input.is_action_pressed("jump"): title_armed = true
		if title_armed and Input.is_action_just_pressed("jump"):
			set_shot(265)
			film_time = 0
		return
	film_time += dt * 1000.0
	while film_time >= FRAME_MS[film_frame]:
		film_time -= FRAME_MS[film_frame]
		if film_frame == FRAME_MS.size()-1:
			$GeneratorOn.hide()
			$BurnedUnit.show()
			$Robot/Sprite2D.texture = robot.intact_pose
			$Pulse.hide()
			$Cable.points = PackedVector2Array([Vector2(71,197),Vector2(78,203),Vector2(82,210),Vector2(88,211),Vector2(94,205),Vector2(97,202)])
			$Prologue.hide()
			unlock()
			return
		set_shot(film_frame + 1)
		if film_frame == 222 or film_frame == 264: return

func unlock() -> void:
	$Letterbox.hide()
	$Integrity.show()
	robot.process_mode = Node.PROCESS_MODE_INHERIT
	$Robot/Camera2D.enabled = true
	$Robot/Camera2D.make_current()
