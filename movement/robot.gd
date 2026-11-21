extends CharacterBody2D

signal parts_changed

const WALK_SHEET := preload("res://movement/robot_walk.png")
var walk_clock := 0.0
@export var air_speed := 125.0
@export var air_acceleration := 900.0
@export var air_braking := 750.0
@export var walk_speed := 55.0
@export var charge_time := 0.6
@export var gravity := 650.0
var charging := false
var held := 0.0

const CHARGE_POSE := preload("res://movement/robot_charge.png")
@onready var normal_pose: Texture2D = $Sprite2D.texture
@onready var spawn_position := global_position

@onready var intact_pose: Texture2D = $Sprite2D.texture
var missing: Array[int] = []
var parts_lost: int:
	get: return missing.size()
var current_walk := WALK_SHEET
var current_charge := CHARGE_POSE
const IDLES := [preload("res://movement/damage/stage2.png"), preload("res://movement/damage/stage3.png"), preload("res://movement/damage/stage4.png"), preload("res://movement/damage/stage5.png")]
const WALKS := [preload("res://movement/damage/stage2_walk.png"), preload("res://movement/damage/stage3_walk.png"), preload("res://movement/damage/stage4_walk.png"), preload("res://movement/damage/stage5_walk.png")]
const CHARGES := [preload("res://movement/damage/stage2_charge.png"), preload("res://movement/damage/stage3_charge.png"), preload("res://movement/damage/stage4_charge.png"), preload("res://movement/damage/stage5_charge.png")]

func next_part() -> int:
	for id in 5:
		if not missing.has(id): return id
	return -1

func refresh_stage() -> void:
	parts_changed.emit()
	if missing.is_empty():
		normal_pose = intact_pose
		current_walk = WALK_SHEET
		current_charge = CHARGE_POSE
		return
	var index := mini(parts_lost, 4) - 1
	normal_pose = IDLES[index]
	current_walk = WALKS[index]
	current_charge = CHARGES[index]

func recover_part(id: int) -> bool:
	if parts_lost == 5 or not missing.has(id): return false
	missing.erase(id)
	refresh_stage()
	return true

func lose_part() -> void:
	var id := next_part()
	if id < 0: return
	missing.append(id)
	refresh_stage()
	reset_to_spawn()
	if parts_lost == 5:
		$Sprite2D.modulate = Color(0.42, 0.42, 0.42)

func reset_to_spawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	charging = false
	held = 0.0
	walk_clock = 0.0
	$Sprite2D.hframes = 1
	$Sprite2D.texture = normal_pose
	$ChargeLine.hide()
	reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	if parts_lost >= 5:
		if Input.is_action_just_pressed("restart_run"):
			get_tree().call_deferred("reload_current_scene")
		return
	if Input.is_action_just_pressed("respawn"):
		reset_to_spawn()
		return
	if is_on_floor():
		var aim := Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("cancel_charge"):
			charging = false
			held = 0.0
		elif Input.is_action_just_pressed("jump"):
			charging = true
			held = 0.0
		velocity.x = 0.0 if charging or Input.is_action_pressed("jump") else aim * walk_speed
		if not is_zero_approx(aim):
			$Sprite2D.flip_h = aim < 0.0
		if charging:
			if Input.is_action_pressed("jump"):
				held = minf(held + delta, charge_time)
			else:
				var power := held / maxf(charge_time, 0.001)
				velocity = Vector2(aim * lerpf(45, 125, power), -lerpf(95, 275, power))
				charging = false
	else:
		var steer := Input.get_axis("move_left", "move_right")
		if is_zero_approx(steer):
			velocity.x = move_toward(velocity.x, 0.0, air_braking * delta)
		else:
			velocity.x = move_toward(velocity.x, steer * air_speed, air_acceleration * delta)
		velocity.y += gravity * delta
	if not is_zero_approx(velocity.x):
		$Sprite2D.flip_h = velocity.x < 0.0
	move_and_slide()
	if is_on_floor() and not charging and not is_zero_approx(velocity.x):
		$Sprite2D.texture = current_walk
		$Sprite2D.hframes = 4
		$Sprite2D.frame = int(walk_clock * 10.0) % 4
		walk_clock = fmod(walk_clock + delta, 0.4)
	else:
		walk_clock = 0.0
		$Sprite2D.hframes = 1
		$Sprite2D.texture = current_charge if charging else normal_pose
	$ChargeLine.visible = charging
	if charging:
		var pixels := 1 + floori(11.0 * clampf(held / maxf(charge_time, 0.001), 0.0, 1.0))
		$ChargeLine.offset_top = 6 - pixels
