extends Node2D

@onready var bot = $"../Robot"
var state := "sleep"
var elapsed := 0.0
var robot_flash := 0.0

func _physics_process(dt: float) -> void:
	elapsed += dt
	if robot_flash > 0.0:
		robot_flash = maxf(0.0, robot_flash - dt)
		if is_zero_approx(robot_flash):
			robot_flash = 0.0
			bot.get_node("Sprite2D").self_modulate = Color.WHITE
	match state:
		"sleep":
			$Gate.visible = bot.can_process()
			$Dot.visible = bot.can_process() and absf(bot.position.x - 139) <= 22 and absf(bot.position.y - 200) < 28
			if $Dot.visible and Input.is_action_just_pressed("interact"):
				bot.set_physics_process(false)
				bot.charging = false
				bot.get_node("ChargeLine").hide()
				$Dot.hide()
				$Dialogue.show()
				state = "dialogue"
		"dialogue":
			if Input.is_action_just_pressed("jump"):
				$Dialogue.hide()
				state = "shake"
				elapsed = 0
		"shake":
			bot.get_node("Camera2D").offset = Vector2(round(sin(elapsed*96)*1.6),round(cos(elapsed*77)))
			if elapsed >= 0.33:
				bot.get_node("Camera2D").offset = Vector2.ZERO
				bot.set_physics_process(true)
				$"../Bay".texture = preload("res://opening/fight_art/bay_empty.png")
				$Maker.show()
				$BossHUD.show()
				phase("wake")

		"wake", "collapse", "opening", "open": pass
		"crawl":
			var dx: float = bot.position.x - $Maker.position.x
			facing = -1 if dx < 0 else 1
			$Maker.flip_h = facing > 0
			$Maker.position.x = move_toward($Maker.position.x, clampf(bot.position.x, 12, 248), dt * 19)
			if absf(dx) < 48 and elapsed >= 0.65: phase("windup")
		"delay":
			if elapsed >= 0.28: phase("lunge")
		"windup": pass # The committed direction cannot track a dodge.
		"lunge":
			if elapsed <= 0.25:
				$Maker.position.x = clampf($Maker.position.x + dt * 150 * facing,12,248)
				if not struck and absf($Maker.position.x - bot.position.x) <= 16 and absf(bot.position.y - 210) <= 19:
					struck = true
					hurt_robot()
	if state in ["crawl","windup","delay","lunge"] and bot.parts_lost < 5:
		attack(dt)
	elif $Slash.visible:
		$Slash.hide()

var facing := -1
var struck := false
const MAX_HEALTH := 6
var health := MAX_HEALTH
var strikes := 0
var swing_dir := 1
var swing_hit := false
var cooldown := 0.0
var flash := 0.0

func _ready():
	$Maker.animation_finished.connect(finished)
	$Gate.animation_finished.connect(open_gate)
	$Slash.animation_finished.connect($Slash.hide)

func phase(next: String):
	state = next
	elapsed = 0
	struck = false
	$Maker.play("maker_" + state)

func finished():
	match state:
		"wake", "lunge": phase("crawl")
		"windup":
			if health < 3:
				state = "delay"
				elapsed = 0.0
			else: phase("lunge")
		"collapse":
			state = "opening"
			$Gate.play("gate_open")

func open_gate():
	state = "open"
	$"../RightWall/CollisionShape2D".set_deferred("disabled", true)

func hurt_robot():
	if bot.parts_lost >= 5: return
	strikes += 1
	if strikes == 1:
		robot_flash = 0.15
		bot.get_node("Sprite2D").self_modulate = Color("ffad91")
		return
	strikes = 0
	robot_flash = 0.0
	bot.get_node("Sprite2D").self_modulate = Color.WHITE
	var part = preload("res://opening/locked_part.gd").new()
	part.part = bot.next_part()
	part.bot = bot
	part.position = Vector2(clampf(bot.position.x,12,245),bot.position.y)
	bot.lose_part()
	$Drops.add_child(part)

func attack(dt: float):
	cooldown = maxf(0, cooldown - dt)
	flash = maxf(0,flash-dt)
	$Maker.modulate = Color.WHITE if flash == 0 else Color(1.5,0.7,0.7)
	if Input.is_action_just_pressed("attack") and cooldown <= 0:
		var aim := Input.get_axis("move_left","move_right")
		swing_dir = int(sign(aim)) if aim != 0 else (-1 if bot.get_node("Sprite2D").flip_h else 1)
		swing_hit = false
		cooldown = 0.5
		$Slash.flip_h = swing_dir < 0
		$Slash.show()
		$Slash.stop()
		$Slash.play("slash")
	if not $Slash.visible: return
	$Slash.position = bot.position + Vector2(14*swing_dir,0)
	var forward: float = ($Maker.position.x - bot.position.x)*swing_dir
	if not swing_hit and forward >= -3 and forward <= 34 and absf(bot.position.y - ($Maker.position.y-15)) <= 20:
		swing_hit = true
		flash = 0.12
		health -= 1
		$BossHUD/Bar.text = "MAKER  " + "■ ".repeat(health) + "□ ".repeat(MAX_HEALTH-health)
		if health == 0:
			$Maker.modulate = Color.WHITE
			$BossHUD.hide()
			phase("collapse")
