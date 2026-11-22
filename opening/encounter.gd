extends Node2D

@onready var bot = $"../Robot"
@onready var dialogue_panel: PanelContainer = $DialogueLayer/Dialogue
@onready var dialogue_words: Label = $DialogueLayer/Dialogue/Layout/TextColumn/Words
const REMAINS_POSITION := Vector2(139, 200)
const REMAINS_INTERACTION_RANGE := Vector2(22, 28)
const MUTATION_SHAKE_DURATION := 0.33
const CAMERA_SHAKE_SPEED := Vector2(96.0, 77.0)
const CAMERA_SHAKE_STRENGTH := Vector2(1.6, 1.0)
const POST_DIALOGUE_INVULNERABILITY := 1.0
const SCAN_LINE := "Master...?"
const INTERNAL_CONFLICT_LINES: Array[String] = [
	"What has become of my master?",
	"He is trying to kill me!",
	"I was taught to defend myself but also to not harm other lives, specially my creator!",
	"What do I do?"
]
const BOUNCE_BACK_LINE := "I must... BOUNCE BACK!"
const FAREWELL_LINE := "Farewell... master."
const MONSTER_DISPLAY_NAME := "NATURE MONSTER"

var state := "sleep"
var elapsed := 0.0
var robot_flash := 0.0
var camera_base_offset := Vector2.ZERO
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var dialogue_context := ""
var dialogue_armed := false
var monster_hits_landed := 0
var hit_invulnerability := 0.0

func _physics_process(dt: float) -> void:
	if robot_flash > 0.0:
		robot_flash = maxf(0.0, robot_flash - dt)
		if is_zero_approx(robot_flash):
			robot_flash = 0.0
			bot.get_node("Sprite2D").self_modulate = Color.WHITE
	if state == "dialogue":
		if not Input.is_action_pressed("jump"):
			dialogue_armed = true
		if dialogue_armed and Input.is_action_just_pressed("jump"):
			dialogue_armed = false
			advance_dialogue()
		return
	elapsed += dt
	if hit_invulnerability > 0.0:
		hit_invulnerability = maxf(0.0, hit_invulnerability - dt)
	match state:
		"sleep":
			$Gate.visible = bot.can_process()
			$Dot.visible = bot.can_process() and absf(bot.position.x - REMAINS_POSITION.x) <= REMAINS_INTERACTION_RANGE.x and absf(bot.position.y - REMAINS_POSITION.y) < REMAINS_INTERACTION_RANGE.y
			if $Dot.visible and Input.is_action_just_pressed("interact"):
				begin_scan()
		"dialogue":
			pass
		"shake":
			bot.get_node("Camera2D").offset = camera_base_offset + Vector2(round(sin(elapsed * CAMERA_SHAKE_SPEED.x) * CAMERA_SHAKE_STRENGTH.x), round(cos(elapsed * CAMERA_SHAKE_SPEED.y) * CAMERA_SHAKE_STRENGTH.y))
			if elapsed >= MUTATION_SHAKE_DURATION:
				bot.get_node("Camera2D").offset = camera_base_offset
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
	if bot.can_process() and bot.is_physics_processing() and bot.parts_lost < 5:
		attack(dt, state in ["crawl","windup","delay","lunge"])
	elif $Slash.visible:
		$Slash.hide()

var facing := -1
var struck := false
const MAX_HEALTH := 8
var health := MAX_HEALTH
var strikes := 0
var swing_dir := 1
var swing_hit := false
var cooldown := 0.0
var flash := 0.0

func _ready():
	camera_base_offset = bot.get_node("Camera2D").offset
	$Maker.animation_finished.connect(finished)
	$Gate.animation_finished.connect(open_gate)
	$Slash.animation_finished.connect($Slash.hide)

func begin_scan() -> void:
	if state != "sleep": return
	bot.charging = false
	bot.get_node("ChargeLine").hide()
	$Dot.hide()
	play_sfx($ScanSFX)
	begin_dialogue([SCAN_LINE], "scan")

func begin_dialogue(lines: Array[String], context: String) -> void:
	if lines.is_empty(): return
	dialogue_lines = lines.duplicate()
	dialogue_index = 0
	dialogue_context = context
	dialogue_armed = false
	state = "dialogue"
	elapsed = 0.0
	bot.set_physics_process(false)
	$Maker.pause()
	$Slash.hide()
	dialogue_words.text = dialogue_lines[dialogue_index]
	dialogue_panel.show()

func advance_dialogue() -> void:
	if state != "dialogue": return
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		dialogue_words.text = dialogue_lines[dialogue_index]
		dialogue_armed = false
		return
	dialogue_panel.hide()
	var completed_context := dialogue_context
	dialogue_context = ""
	match completed_context:
		"scan": start_mutation()
		"internal_conflict", "bounce_back": resume_combat()
		"farewell": finish_farewell()

func start_mutation() -> void:
	state = "shake"
	elapsed = 0.0
	play_sfx($MonsterVocalSFX)
	play_sfx($MutationImpactSFX)

func resume_combat() -> void:
	hit_invulnerability = POST_DIALOGUE_INVULNERABILITY
	bot.set_physics_process(true)
	phase("crawl")

func finish_farewell() -> void:
	bot.set_physics_process(true)
	state = "opening"
	elapsed = 0.0
	$Gate.play("gate_open")

func play_sfx(player: AudioStreamPlayer) -> void:
	if player.stream != null:
		player.play()

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
			begin_dialogue([FAREWELL_LINE], "farewell")

func open_gate():
	state = "open"
	$"../RightWall/CollisionShape2D".set_deferred("disabled", true)

func hurt_robot():
	if bot.parts_lost >= 5 or hit_invulnerability > 0.0 or state == "dialogue": return
	bot.play_damage_feedback()
	monster_hits_landed += 1
	strikes += 1
	if strikes == 1:
		robot_flash = 0.15
		bot.get_node("Sprite2D").self_modulate = Color("ffad91")
	else:
		strikes = 0
		robot_flash = 0.0
		bot.get_node("Sprite2D").self_modulate = Color.WHITE
		var part = preload("res://opening/locked_part.gd").new()
		part.part = bot.next_part()
		part.bot = bot
		part.position = Vector2(clampf(bot.position.x,12,245),bot.position.y)
		bot.lose_part(false)
		$Drops.add_child(part)
	if monster_hits_landed == 1:
		begin_dialogue(INTERNAL_CONFLICT_LINES, "internal_conflict")
	elif monster_hits_landed == 2:
		begin_dialogue([BOUNCE_BACK_LINE], "bounce_back")

func attack(dt: float, can_hit_maker: bool):
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
		play_sfx($AttackSFX)
	if not $Slash.visible: return
	$Slash.position = bot.position + Vector2(14*swing_dir,0)
	var forward: float = ($Maker.position.x - bot.position.x)*swing_dir
	if can_hit_maker and not swing_hit and forward >= -3 and forward <= 34 and absf(bot.position.y - ($Maker.position.y-15)) <= 20:
		swing_hit = true
		flash = 0.12
		health -= 1
		bot.rumble_on_hit()
		$BossHUD/Bar.text = MONSTER_DISPLAY_NAME + "  " + "■ ".repeat(health) + "□ ".repeat(MAX_HEALTH-health)
		if health == 0:
			play_sfx($EnemyDeathSFX)
			bot.rumble_on_enemy_death()
			$Maker.modulate = Color.WHITE
			$BossHUD.hide()
			phase("collapse")
