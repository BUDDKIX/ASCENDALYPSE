extends CanvasLayer

signal play_requested

var input_armed := false
var title_ready := false

func _ready() -> void:
	var gameplay_stream := $GameplayMusic.stream as AudioStreamWAV
	gameplay_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	gameplay_stream.loop_begin = 0
	gameplay_stream.loop_end = roundi(gameplay_stream.get_length() * gameplay_stream.mix_rate)
	$GameplayMusic.play()
	$Wordmark.hide()
	$Prompt.hide()
	get_viewport().size_changed.connect(fit_content)
	fit_content()
	await get_tree().create_timer(2.0).timeout
	$Wordmark.show()
	$Prompt.show()
	title_ready = true

func fit_content() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_fit := viewport_size / Vector2(240, 135)
	var scale_value := minf(scale_fit.x, scale_fit.y)
	var center := (viewport_size * 0.5).round()
	$Wordmark.position = center
	$Wordmark.scale = Vector2.ONE * scale_value
	$Prompt.position = (center + Vector2(0, 20 * scale_value)).round()
	$Prompt.scale = Vector2.ONE * scale_value

func _physics_process(_delta: float) -> void:
	if not title_ready:
		return
	if not Input.is_action_pressed("jump"):
		input_armed = true
		return
	if input_armed and Input.is_action_just_pressed("jump"):
		set_physics_process(false)
		play_requested.emit()

func dismiss() -> void:
	$Black.hide()
	$Wordmark.hide()
	$Prompt.hide()
	set_physics_process(false)
